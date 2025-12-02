//
//  MoviesView.swift
//  ProFlix
//
//  Created for Xtream API integration
//

import SDWebImageSwiftUI
import SwiftUI

struct MoviesView: View {

  @EnvironmentObject var appState: AppState
  @EnvironmentObject var router: NavRouter
  @State private var searchText: String = ""
  @State private var selectedCategory: String? = nil
  @State private var viewMode: ViewMode = .grid

  enum ViewMode {
    case grid
    case list
  }

  private var filteredMovies: [XtreamMovie] {
    var movies = appState.movies

    // Filter by category
    if let categoryId = selectedCategory {
      movies = movies.filter { $0.categoryId == categoryId }
    }

    // Filter by search text
    if !searchText.isEmpty {
      movies = movies.filter { movie in
        movie.title.localizedCaseInsensitiveContains(searchText)
      }
    }

    return movies
  }

  private var categories: [XtreamCategory] {
    appState.categories.filter { $0.type == .movies }
  }

  private let gridColumns = [
    GridItem(.flexible(), spacing: 15),
    GridItem(.flexible(), spacing: 15),
    GridItem(.flexible(), spacing: 15),
  ]

  var body: some View {
    Group {
      if appState.isLoadingData && appState.movies.isEmpty {
        VStack(spacing: 20) {
          ProgressView()
            .controlSize(.large)
          Text("Loading movies...")
            .foregroundColor(.secondary)
        }
      } else if filteredMovies.isEmpty {
        VStack(spacing: 20) {
          Image(systemName: "film.slash")
            .font(.system(size: 60))
            .foregroundColor(.secondary)
          Text("No movies available")
            .font(.title2)
            .foregroundColor(.secondary)
          if appState.movies.isEmpty {
            Text("Pull down to refresh or check your connection")
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        List {
          // View Mode & Category Filter Section
          Section {
            VStack(spacing: 12) {
              // View Mode Toggle
              HStack {
                Text("View Mode")
                  .font(.headline)
                Spacer()
                Picker("View Mode", selection: $viewMode) {
                  Label("Grid", systemImage: "square.grid.2x2").tag(ViewMode.grid)
                  Label("List", systemImage: "list.bullet").tag(ViewMode.list)
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
              }

              // Category Filter
              if !categories.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                  HStack(spacing: 12) {
                    CategoryChip(
                      title: "All",
                      isSelected: selectedCategory == nil,
                      action: { selectedCategory = nil }
                    )

                    ForEach(categories) { category in
                      CategoryChip(
                        title: category.name,
                        isSelected: selectedCategory == category.id,
                        action: { selectedCategory = category.id }
                      )
                    }
                  }
                }
              }
            }
            .padding(.vertical, 8)
          }
          .listRowInsets(EdgeInsets())
          .listRowBackground(Color.clear)

          // Movies Content
          if viewMode == .grid {
            Section {
              LazyVGrid(columns: gridColumns, spacing: 15) {
                ForEach(filteredMovies) { movie in
                  NavigationLink(
                    value: NavDestination.VideoPlayerView(
                      buildStreamURL(for: movie),
                      movie.title
                    )
                  ) {
                    MovieCardView(movie: movie)
                  }
                  .buttonStyle(.plain)
                }
              }
              .padding(.horizontal)
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
          } else {
            Section {
              ForEach(filteredMovies) { movie in
                NavigationLink(
                  value: NavDestination.VideoPlayerView(
                    buildStreamURL(for: movie),
                    movie.title
                  )
                ) {
                  StreamCardView(
                    title: movie.title,
                    subtitle: movie.categoryId ?? "Movie",
                    url: nil,
                    icon: movie.cover
                  )
                }
              }
            }
          }
        }
      }
    }
    .navigationTitle("Movies")
    .searchable(text: $searchText, prompt: "Search movies")
    .refreshable {
      await appState.refreshData()
    }
  }

  // TODO: Replace with actual PlaybackURLBuilder
  private func buildStreamURL(for movie: XtreamMovie) -> URL {
    // Placeholder - will be replaced with actual Xtream URL building logic
    return URL(string: "https://example.com/movie/\(movie.streamId)") ?? URL(
      string: "https://example.com")!
  }
}

// MARK: - Movie Card View

struct MovieCardView: View {
  let movie: XtreamMovie

  var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Movie Poster/Cover
            WebImage(url: URL(string: movie.cover ?? ""))
                .resizable()
                .placeholder {
                    ZStack {
                        Color.systemGrayColor5
                        Image(systemName: "film.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                    }
                }
                .transition(.fade(duration: 0.3))
                .aspectRatio(contentMode: .fill)
                .frame(height: 200)
                .cornerRadius(12)
                .clipped()
            
            // Movie Title
            Text(movie.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
  }
}

// MARK: - Preview

struct MoviesView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      MoviesView()
        .environmentObject(
          {
            let state = AppState()
            state.movies = [
              XtreamMovie(id: "1", title: "Movie 1", cover: nil, categoryId: "cat1", streamId: "1"),
              XtreamMovie(id: "2", title: "Movie 2", cover: nil, categoryId: "cat1", streamId: "2"),
            ]
            state.categories = [
              XtreamCategory(id: "cat1", name: "Action", type: .movies)
            ]
            return state
          }()
        )
        .environmentObject(NavRouter())
    }
  }
}
