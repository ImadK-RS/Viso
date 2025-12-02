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

  // MARK: - Initialization
  init() {
    // Check if credentials exist in Keychain on init
    checkExistingCredentials()
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

    // TODO: Implement actual XtreamService login
    // For now, simulate a login check
    do {
      // Validate URL format
      guard URL(string: url) != nil else {
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
      }

      // TODO: Call XtreamService to authenticate and fetch initial data
      // For now, simulate success
      try await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second delay

      await MainActor.run {
        self.isAuthenticated = true
        self.isAuthenticating = false
      }

      return true
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

    // TODO: Implement XtreamService data fetching
    // This will fetch Live TV, Movies, Series, Categories, EPG URL

    await MainActor.run {
      self.isLoadingData = false
    }
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
