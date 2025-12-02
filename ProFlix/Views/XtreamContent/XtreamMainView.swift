//
//  XtreamMainView.swift
//  ProFlix
//
//  Created for Xtream API integration
//

import SwiftUI

struct XtreamMainView: View {

  @EnvironmentObject var appState: AppState
  @EnvironmentObject var router: NavRouter
  @State private var selectedTab: ContentTab = .liveTV
  @State private var liveTVPath = NavigationPath()
  @State private var moviesPath = NavigationPath()
  @State private var seriesPath = NavigationPath()

  enum ContentTab: String, CaseIterable {
    case liveTV = "Live TV"
    case movies = "Movies"
    case series = "Series"

    var systemImage: String {
      switch self {
      case .liveTV:
        return "tv.fill"
      case .movies:
        return "film.fill"
      case .series:
        return "tv.inset.filled"
      }
    }
  }

  var body: some View {
    TabView(selection: $selectedTab) {
      NavigationStack(path: $liveTVPath) {
        LiveTVView()
          .navigationDestination(for: NavDestination.self) { destination in
            switch destination {
            case .AllPlaylistView:
              AllPlaylistView()
            case .AllQuickListView:
              AllQuickPlayListView()
            case .StreamListView(let library):
              StreamListView(library: library)
            case .VideoPlayerView(let url, let title):
              VideoPlayerView(url: url, title: title)
            }
          }
      }
      .tabItem {
        Label(ContentTab.liveTV.rawValue, systemImage: ContentTab.liveTV.systemImage)
      }
      .tag(ContentTab.liveTV)

      NavigationStack(path: $moviesPath) {
        MoviesView()
          .navigationDestination(for: NavDestination.self) { destination in
            switch destination {
            case .AllPlaylistView:
              AllPlaylistView()
            case .AllQuickListView:
              AllQuickPlayListView()
            case .StreamListView(let library):
              StreamListView(library: library)
            case .VideoPlayerView(let url, let title):
              VideoPlayerView(url: url, title: title)
            }
          }
      }
      .tabItem {
        Label(ContentTab.movies.rawValue, systemImage: ContentTab.movies.systemImage)
      }
      .tag(ContentTab.movies)

      NavigationStack(path: $seriesPath) {
        SeriesView()
          .navigationDestination(for: NavDestination.self) { destination in
            switch destination {
            case .AllPlaylistView:
              AllPlaylistView()
            case .AllQuickListView:
              AllQuickPlayListView()
            case .StreamListView(let library):
              StreamListView(library: library)
            case .VideoPlayerView(let url, let title):
              VideoPlayerView(url: url, title: title)
            }
          }
      }
      .tabItem {
        Label(ContentTab.series.rawValue, systemImage: ContentTab.series.systemImage)
      }
      .tag(ContentTab.series)
    }
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        Menu {
          Button(action: refreshData) {
            Label("Refresh Library", systemImage: "arrow.clockwise")
          }

          Divider()

          Button(role: .destructive, action: logout) {
            Label("Logout", systemImage: "arrow.right.square")
          }
        } label: {
          Image(systemName: "ellipsis.circle")
            .imageScale(.large)
        }
      }
    }
  }

  private func refreshData() {
    Task {
      await appState.refreshData()
    }
  }

  private func logout() {
    appState.logout()
  }
}

// MARK: - Preview

struct XtreamMainView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      XtreamMainView()
        .environmentObject(AppState())
        .environmentObject(NavRouter())
    }
  }
}
