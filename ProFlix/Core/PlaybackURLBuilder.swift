//
//  PlaybackURLBuilder.swift
//  ProFlix
//
//  Builds Xtream-compatible playback URLs for Live TV, Movies, and Series.
//

import Foundation

/// Helper for building Xtream playback URLs from base URL, username, and password.
struct PlaybackURLBuilder {

  let baseURL: URL
  let username: String
  let password: String

  /// Initialize from string base URL. Returns nil if the URL is invalid.
  init?(baseURLString: String, username: String, password: String) {
    guard let url = URL(string: baseURLString) else {
      return nil
    }
    self.baseURL = url
    self.username = username
    self.password = password
  }

  // MARK: - Public helpers

  /// Build Live TV stream URL: base/live/username/password/streamId.[ext]
  func liveURL(streamId: String, fileExtension: String = "ts") -> URL {
    endpoint(pathComponent: "live", streamId: streamId, fileExtension: fileExtension)
  }

  /// Build Movie (VOD) stream URL: base/movie/username/password/streamId.[ext]
  func movieURL(streamId: String, fileExtension: String = "mp4") -> URL {
    endpoint(pathComponent: "movie", streamId: streamId, fileExtension: fileExtension)
  }

  /// Build Series episode stream URL: base/series/username/password/streamId.[ext]
  func seriesURL(streamId: String, fileExtension: String = "mp4") -> URL {
    endpoint(pathComponent: "series", streamId: streamId, fileExtension: fileExtension)
  }

  // MARK: - Internal

  private func endpoint(
    pathComponent: String,
    streamId: String,
    fileExtension: String
  ) -> URL {
    var url = baseURL
    // Ensure we do not duplicate slashes
    url.appendPathComponent(pathComponent)
    url.appendPathComponent(username)
    url.appendPathComponent(password)
    url.appendPathComponent("\(streamId).\(fileExtension)")
    return url
  }
}
