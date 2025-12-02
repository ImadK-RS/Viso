//
//  LiveTVView.swift
//  ProFlix
//
//  Created for Xtream API integration
//

import SwiftUI

struct LiveTVView: View {

  @EnvironmentObject var appState: AppState
  @EnvironmentObject var router: NavRouter
  @State private var searchText: String = ""
  @State private var selectedCategory: String? = nil

  private var filteredChannels: [XtreamChannel] {
    var channels = appState.liveTVChannels

    // Filter by category
    if let categoryId = selectedCategory {
      channels = channels.filter { $0.categoryId == categoryId }
    }

    // Filter by search text
    if !searchText.isEmpty {
      channels = channels.filter { channel in
        channel.name.localizedCaseInsensitiveContains(searchText)
      }
    }

    return channels
  }

  private var categories: [XtreamCategory] {
    appState.categories.filter { $0.type == .liveTV }
  }

  var body: some View {
    Group {
      if appState.isLoadingData && appState.liveTVChannels.isEmpty {
        VStack(spacing: 20) {
          ProgressView()
            .controlSize(.large)
          Text("Loading Live TV channels...")
            .foregroundColor(.secondary)
        }
      } else if filteredChannels.isEmpty {
        VStack(spacing: 20) {
          Image(systemName: "tv.slash")
            .font(.system(size: 60))
            .foregroundColor(.secondary)
          Text("No channels available")
            .font(.title2)
            .foregroundColor(.secondary)
          if appState.liveTVChannels.isEmpty {
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

          // Channels List
          ForEach(filteredChannels) { channel in
            NavigationLink(
              value: NavDestination.VideoPlayerView(
                buildStreamURL(for: channel),
                channel.name
              )
            ) {
              StreamCardView(
                title: channel.name,
                subtitle: channel.categoryId ?? "Live TV",
                url: nil,
                icon: channel.logo
              )
            }
          }
        }
      }
    }
    .navigationTitle("Live TV")
    .searchable(text: $searchText, prompt: "Search channels")
    .refreshable {
      await appState.refreshData()
    }
  }

  // TODO: Replace with actual PlaybackURLBuilder
  private func buildStreamURL(for channel: XtreamChannel) -> URL {
    // Placeholder - will be replaced with actual Xtream URL building logic
    return URL(string: "https://example.com/stream/\(channel.streamId)") ?? URL(
      string: "https://example.com")!
  }
}

// MARK: - Category Chip View

struct CategoryChip: View {
  let title: String
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Text(title)
        .font(.subheadline)
        .fontWeight(isSelected ? .semibold : .regular)
        .foregroundColor(isSelected ? .white : .primary)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
          isSelected
            ? LinearGradient(
              colors: [Color(hex: "#667eea") ?? .blue, Color(hex: "#764ba2") ?? .purple],
              startPoint: .leading,
              endPoint: .trailing
            )
            : LinearGradient(
              colors: [Color.systemGrayColor5], startPoint: .leading, endPoint: .trailing)
        )
        .cornerRadius(20)
    }
  }
}

// MARK: - Preview

struct LiveTVView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      LiveTVView()
        .environmentObject(
          {
            let state = AppState()
            state.liveTVChannels = [
              XtreamChannel(
                id: "1", name: "Channel 1", logo: nil, categoryId: "cat1", streamId: "1"),
              XtreamChannel(
                id: "2", name: "Channel 2", logo: nil, categoryId: "cat1", streamId: "2"),
            ]
            state.categories = [
              XtreamCategory(id: "cat1", name: "Entertainment", type: .liveTV)
            ]
            return state
          }()
        )
        .environmentObject(NavRouter())
    }
  }
}
