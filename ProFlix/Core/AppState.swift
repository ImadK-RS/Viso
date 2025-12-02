//
//  AppState.swift
//  ProFlix
//
//  Created for Xtream API integration
//

import Foundation
import SwiftUI

/// Manages application-wide state including Xtream authentication and session
final class AppState: ObservableObject {

  // MARK: - Authentication State
  @Published var isAuthenticated: Bool = false
  @Published var isAuthenticating: Bool = false
  @Published var authenticationError: String?

  // MARK: - Xtream Credentials (stored in Keychain, accessed via KeychainManager)
  var xtreamURL: String?
  var xtreamUsername: String?
  var xtreamPassword: String?

  // MARK: - Data State
  @Published var isLoadingData: Bool = false
  @Published var dataLoadError: String?

  // MARK: - Content Data (will be populated by XtreamService)
  @Published var liveTVChannels: [XtreamChannel] = []
  @Published var movies: [XtreamMovie] = []
  @Published var series: [XtreamSeries] = []
  @Published var categories: [XtreamCategory] = []
  @Published var epgURL: String?

  // MARK: - Helpers

  /// Convenience builder for Xtream playback URLs, derived from stored credentials.
  var playbackURLBuilder: PlaybackURLBuilder? {
    guard
      let base = xtreamURL,
      let user = xtreamUsername,
      let pass = xtreamPassword
    else {
      return nil
    }
    return PlaybackURLBuilder(baseURLString: base, username: user, password: pass)
  }

  /// XtreamService instance, created when credentials are available
  private var xtreamService: XtreamService? {
    guard
      let urlString = xtreamURL,
      let url = URL(string: urlString),
      let username = xtreamUsername,
      let password = xtreamPassword
    else {
      return nil
    }
    return XtreamService(baseURL: url, username: username, password: password)
  }

  // MARK: - Initialization
  init() {
    // Check if credentials exist in Keychain on init
    checkExistingCredentials()
    // For now, we always start unauthenticated and use demo data after login
  }

  // MARK: - Authentication Methods

  /// Check if credentials exist in Keychain
  private func checkExistingCredentials() {
    // TODO: Implement KeychainManager to check for existing credentials
    // For now, default to false
    self.isAuthenticated = false
  }

  /// Login with Xtream credentials
  func login(url: String, username: String, password: String) async -> Bool {
    await MainActor.run {
      self.isAuthenticating = true
      self.authenticationError = nil
    }

    do {
      // Validate URL format
      guard let baseURL = URL(string: url) else {
        await MainActor.run {
          self.authenticationError = "Invalid URL format"
          self.isAuthenticating = false
        }
        return false
      }

      // Store credentials (will be moved to Keychain)
      await MainActor.run {
        self.xtreamURL = url
        self.xtreamUsername = username
        self.xtreamPassword = password
        print("Xtream login: username=\(username), baseURL=\(url)")
      }

      // Create service and authenticate
      let service = XtreamService(baseURL: baseURL, username: username, password: password)

      do {
        // Authenticate
        let authResult = try await service.authenticate()
        print("Authentication successful for user: \(authResult.username)")

        // Fetch EPG URL if available
        if let epgURL = authResult.epgURL {
          await MainActor.run {
            self.epgURL = epgURL
          }
        }

        // Fetch initial data
        await fetchAllData(service: service)

        await MainActor.run {
          self.isAuthenticated = true
          self.isAuthenticating = false
        }

        return true
      } catch let error as XtreamError {
        await MainActor.run {
          self.authenticationError = error.localizedDescription
          self.isAuthenticating = false
        }
        return false
      } catch {
        await MainActor.run {
          self.authenticationError = "Login failed: \(error.localizedDescription)"
          self.isAuthenticating = false
        }
        return false
      }
    } catch {
      await MainActor.run {
        self.authenticationError = error.localizedDescription
        self.isAuthenticating = false
      }
      return false
    }
  }

  /// Logout and clear credentials
  func logout() {
    // TODO: Clear Keychain credentials
    self.isAuthenticated = false
    self.xtreamURL = nil
    self.xtreamUsername = nil
    self.xtreamPassword = nil
    self.liveTVChannels = []
    self.movies = []
    self.series = []
    self.categories = []
    self.epgURL = nil
  }

  // MARK: - Data Loading Methods

  /// Refresh all data from Xtream API
  func refreshData() async {
    await MainActor.run {
      self.isLoadingData = true
      self.dataLoadError = nil
    }

    guard let service = xtreamService else {
      await MainActor.run {
        self.dataLoadError = "No active session"
        self.isLoadingData = false
      }
      return
    }

    await fetchAllData(service: service)

    await MainActor.run {
      self.isLoadingData = false
    }
  }

  /// Fetch all data from Xtream API
  private func fetchAllData(service: XtreamService) async {
    do {
      // Fetch all categories and streams in parallel
      async let liveCategories = service.getLiveCategories()
      async let vodCategories = service.getVODCategories()
      async let seriesCategories = service.getSeriesCategories()
      async let liveStreams = service.getLiveStreams()
      async let vodStreams = service.getVODStreams()
      async let seriesList = service.getSeries()

      let (liveCats, vodCats, serCats, live, vod, series) = try await (
        liveCategories, vodCategories, seriesCategories, liveStreams, vodStreams, seriesList
      )

      // Map categories
      var allCategories: [XtreamCategory] = []
      allCategories.append(
        contentsOf: liveCats.map {
          XtreamCategory(id: $0.categoryId, name: $0.categoryName, type: .liveTV)
        })
      allCategories.append(
        contentsOf: vodCats.map {
          XtreamCategory(id: $0.categoryId, name: $0.categoryName, type: .movies)
        })
      allCategories.append(
        contentsOf: serCats.map {
          XtreamCategory(id: $0.categoryId, name: $0.categoryName, type: .series)
        })

      // Map Live TV channels
      let channels = live.map { stream in
        let idString = stream.streamId.map { String($0) } ?? UUID().uuidString
        return XtreamChannel(
          id: idString,
          name: stream.name,
          logo: stream.streamIcon,
          categoryId: stream.categoryId,
          streamId: idString
        )
      }

      // Map Movies
      let movies = vod.map { stream in
        let idString = stream.streamId.map { String($0) } ?? UUID().uuidString
        return XtreamMovie(
          id: idString,
          title: stream.name,
          cover: stream.streamIcon,
          categoryId: stream.categoryId,
          streamId: idString
        )
      }

      // Map Series (no episodes yet – just basic info)
      let mappedSeries: [XtreamSeries] = series.map { seriesItem in
        let seriesIdString = seriesItem.seriesId.map { String($0) } ?? UUID().uuidString
        return XtreamSeries(
          id: seriesIdString,
          name: seriesItem.name,
          cover: seriesItem.cover,
          categoryId: seriesItem.categoryId,
          episodes: []  // placeholder for future episode support
        )
      }

      await MainActor.run {
        self.categories = allCategories
        self.liveTVChannels = channels
        self.movies = movies
        self.series = mappedSeries
      }

      print(
        "Loaded \(channels.count) channels, \(movies.count) movies, \(mappedSeries.count) series")
    } catch {
      await MainActor.run {
        self.dataLoadError = "Failed to load data: \(error.localizedDescription)"
      }
      print("Error fetching data: \(error)")
    }
  }

  // MARK: - Demo Data

  /// Temporary demo data so the UI can be exercised without a real Xtream backend.
  private func loadDemoData() {
    // Categories
    let liveCategory = XtreamCategory(id: "live-ent", name: "Entertainment", type: .liveTV)
    let liveNewsCategory = XtreamCategory(id: "live-news", name: "News", type: .liveTV)
    let moviesCategory = XtreamCategory(id: "mov-action", name: "Action", type: .movies)
    let seriesCategory = XtreamCategory(id: "ser-drama", name: "Drama", type: .series)

    self.categories = [liveCategory, liveNewsCategory, moviesCategory, seriesCategory]

    // Live TV
    self.liveTVChannels = [
      XtreamChannel(
        id: "ch1",
        name: "ProFlix Live 1",
        logo: "https://i.imgur.com/XgejLKw.png",
        categoryId: liveCategory.id,
        streamId: "live1"
      ),
      XtreamChannel(
        id: "ch2",
        name: "World News HD",
        logo: "https://i.imgur.com/bcHP3Vg.png",
        categoryId: liveNewsCategory.id,
        streamId: "live2"
      ),
    ]

    // Movies
    self.movies = [
      XtreamMovie(
        id: "m1",
        title: "Demo Movie: The Beginning",
        cover: "https://image.tmdb.org/t/p/w500/8YFL5QQVPy3AgrEQxNYVSgiPEbe.jpg",
        categoryId: moviesCategory.id,
        streamId: "mov1"
      ),
      XtreamMovie(
        id: "m2",
        title: "Demo Movie: The Sequel",
        cover: "https://image.tmdb.org/t/p/w500/5P8SmMzSNYikXpxil6BYzJ16611.jpg",
        categoryId: moviesCategory.id,
        streamId: "mov2"
      ),
    ]

    // Series
    let demoEpisodes = [
      XtreamEpisode(
        id: "e1",
        title: "Pilot",
        seasonNumber: 1,
        episodeNumber: 1,
        streamId: "ser1e1"
      ),
      XtreamEpisode(
        id: "e2",
        title: "Second Wind",
        seasonNumber: 1,
        episodeNumber: 2,
        streamId: "ser1e2"
      ),
    ]

    self.series = [
      XtreamSeries(
        id: "s1",
        name: "Demo Series",
        cover: "https://image.tmdb.org/t/p/w500/7yx20ZQwF7C0JgWY1e7Agk4D9mu.jpg",
        categoryId: seriesCategory.id,
        episodes: demoEpisodes
      )
    ]

    // EPG URL placeholder
    self.epgURL = "https://example.com/demo-epg.xml"
  }
}

// MARK: - Placeholder Models (will be replaced by XtreamModels.swift)

struct XtreamChannel: Identifiable {
  let id: String
  let name: String
  let logo: String?
  let categoryId: String?
  let streamId: String
}

struct XtreamMovie: Identifiable {
  let id: String
  let title: String
  let cover: String?
  let categoryId: String?
  let streamId: String
}

struct XtreamSeries: Identifiable {
  let id: String
  let name: String
  let cover: String?
  let categoryId: String?
  let episodes: [XtreamEpisode]
}

struct XtreamEpisode: Identifiable {
  let id: String
  let title: String
  let seasonNumber: Int
  let episodeNumber: Int
  let streamId: String
}

struct XtreamCategory: Identifiable {
  let id: String
  let name: String
  let type: CategoryType
}

enum CategoryType {
  case liveTV
  case movies
  case series
}
