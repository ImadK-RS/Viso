//
//  SeriesView.swift
//  ProFlix
//
//  Created for Xtream API integration
//

import SDWebImageSwiftUI
import SwiftUI

struct SeriesView: View {

  @EnvironmentObject var appState: AppState
  @EnvironmentObject var router: NavRouter
  @State private var searchText: String = ""
  @State private var selectedCategory: String? = nil
  @State private var expandedSeries: Set<String> = []

  private var filteredSeries: [XtreamSeries] {
    var series = appState.series

    // Filter by category
    if let categoryId = selectedCategory {
      series = series.filter { $0.categoryId == categoryId }
    }

    // Filter by search text
    if !searchText.isEmpty {
      series = series.filter { seriesItem in
        seriesItem.name.localizedCaseInsensitiveContains(searchText)
      }
    }

    return series
  }

  private var categories: [XtreamCategory] {
    appState.categories.filter { $0.type == .series }
  }

  var body: some View {
    Group {
      if appState.isLoadingData && appState.series.isEmpty {
        VStack(spacing: 20) {
          ProgressView()
            .controlSize(.large)
          Text("Loading series...")
            .foregroundColor(.secondary)
        }
      } else if filteredSeries.isEmpty {
        VStack(spacing: 20) {
          Image(systemName: "tv.inset.filled")
            .font(.system(size: 60))
            .foregroundColor(.secondary)
          Text("No series available")
            .font(.title2)
            .foregroundColor(.secondary)
          if appState.series.isEmpty {
            Text("Pull down to refresh or check your connection")
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        List {
          // Category Filter Section
          if !categories.isEmpty {
            Section {
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
                .padding(.horizontal)
              }
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
          }

          // Series List with Episodes
          ForEach(filteredSeries) { series in
            Section {
              // Series Header
              HStack {
                // Series Cover
                WebImage(url: URL(string: series.cover ?? ""))
                  .resizable()
                  .placeholder {
                    ZStack {
                      Color.systemGrayColor5
                      Image(systemName: "tv.inset.filled")
                        .font(.system(size: 30))
                        .foregroundColor(.secondary)
                    }
                  }
                  .transition(.fade(duration: 0.3))
                  .aspectRatio(contentMode: .fill)
                  .frame(width: 80, height: 120)
                  .cornerRadius(8)
                  .clipped()

                VStack(alignment: .leading, spacing: 8) {
                  Text(series.name)
                    .font(.title3)
                    .fontWeight(.semibold)

                  Text("\(series.episodes.count) episodes")
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: {
                  if expandedSeries.contains(series.id) {
                    expandedSeries.remove(series.id)
                  } else {
                    expandedSeries.insert(series.id)
                  }
                }) {
                  Image(
                    systemName: expandedSeries.contains(series.id) ? "chevron.up" : "chevron.down"
                  )
                  .foregroundColor(.secondary)
                }
              }
              .padding(.vertical, 8)

              // Episodes (shown when expanded)
              if expandedSeries.contains(series.id) {
                ForEach(series.episodes) { episode in
                  NavigationLink(
                    value: NavDestination.VideoPlayerView(
                      buildStreamURL(for: episode),
                      "\(series.name) - S\(episode.seasonNumber)E\(episode.episodeNumber)"
                    )
                  ) {
                    HStack {
                      VStack(alignment: .leading, spacing: 4) {
                        Text(episode.title)
                          .font(.subheadline)
                          .fontWeight(.medium)

                        Text("S\(episode.seasonNumber)E\(episode.episodeNumber)")
                          .font(.caption)
                          .foregroundColor(.secondary)
                      }

                      Spacer()

                      Image(systemName: "play.circle.fill")
                        .foregroundColor(.blue)
                    }
                    .padding(.vertical, 4)
                  }
                }
              }
            }
          }
        }
      }
    }
    .navigationTitle("Series")
    .searchable(text: $searchText, prompt: "Search series")
    .refreshable {
      await appState.refreshData()
    }
  }

  // TODO: Replace with actual PlaybackURLBuilder
  private func buildStreamURL(for episode: XtreamEpisode) -> URL {
    // Placeholder - will be replaced with actual Xtream URL building logic
    return URL(string: "https://example.com/series/\(episode.streamId)") ?? URL(
      string: "https://example.com")!
  }
}

// MARK: - Preview

struct SeriesView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      SeriesView()
        .environmentObject(
          {
            let state = AppState()
            state.series = [
              XtreamSeries(
                id: "1",
                name: "Test Series",
                cover: nil,
                categoryId: "cat1",
                episodes: [
                  XtreamEpisode(
                    id: "e1", title: "Episode 1", seasonNumber: 1, episodeNumber: 1, streamId: "1"),
                  XtreamEpisode(
                    id: "e2", title: "Episode 2", seasonNumber: 1, episodeNumber: 2, streamId: "2"),
                ]
              )
            ]
            state.categories = [
              XtreamCategory(id: "cat1", name: "Drama", type: .series)
            ]
            return state
          }()
        )
        .environmentObject(NavRouter())
    }
  }
}
