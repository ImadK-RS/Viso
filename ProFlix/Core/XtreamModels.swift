//
//  XtreamModels.swift
//  ProFlix
//
//  JSON response models for Xtream Codes API
//

import Foundation

// MARK: - User Info

struct XtreamUserInfo: Codable {
  let username: String
  let password: String
  let message: String?
  let auth: Int?
  let status: String?
  let expDate: String?
  let isTrial: String?
  let activeCons: String?
  let createdAt: String?
  let maxConnections: String?
  let allowedOutputFormats: [String]?
  let serverInfo: XtreamServerInfo?

  enum CodingKeys: String, CodingKey {
    case username, password, message, auth, status
    case expDate = "exp_date"
    case isTrial = "is_trial"
    case activeCons = "active_cons"
    case createdAt = "created_at"
    case maxConnections = "max_connections"
    case allowedOutputFormats = "allowed_output_formats"
    case serverInfo = "server_info"
  }
}

struct XtreamServerInfo: Codable {
  let url: String?
  let port: String?
  let httpsPort: String?
  let serverProtocol: String?
  let rtmpPort: String?
  let timezone: String?
  let timestampNow: String?
  let time: String?
  let epgUrl: String?

  enum CodingKeys: String, CodingKey {
    case url, port
    case httpsPort = "https_port"
    case serverProtocol = "server_protocol"
    case rtmpPort = "rtmp_port"
    case timezone
    case timestampNow = "timestamp_now"
    case time
    case epgUrl = "epg_url"
  }
}

// MARK: - Categories

struct XtreamCategoryResponse: Codable, Identifiable {
  let categoryId: String
  let categoryName: String
  let parentId: Int?

  var id: String { categoryId }

  enum CodingKeys: String, CodingKey {
    case categoryId = "category_id"
    case categoryName = "category_name"
    case parentId = "parent_id"
  }
}

// MARK: - Streams

struct XtreamStreamResponse: Codable {
  let num: Int?
  let name: String
  let streamType: String?  // some servers omit this
  let streamId: Int?  // some servers omit or vary this
  let streamIcon: String?
  let epgChannelId: String?
  let added: String?
  let categoryId: String?
  let categoryName: String?
  let containerExtension: String?
  let customSid: String?
  let tvArchive: Int?
  let directSource: String?
  let tvArchiveDuration: Int?

  enum CodingKeys: String, CodingKey {
    case num, name, added
    case streamType = "stream_type"
    case streamId = "stream_id"
    case streamIcon = "stream_icon"
    case epgChannelId = "epg_channel_id"
    case categoryId = "category_id"
    case categoryName = "category_name"
    case containerExtension = "container_extension"
    case customSid = "custom_sid"
    case tvArchive = "tv_archive"
    case directSource = "direct_source"
    case tvArchiveDuration = "tv_archive_duration"
  }
}

// MARK: - Series

struct XtreamSeriesResponse: Codable {
  let num: Int?
  let name: String
  let seriesId: Int?
  let cover: String?
  let plot: String?
  let cast: String?
  let director: String?
  let genre: String?
  let releaseDate: String?
  let rating: String?
  let rating5: String?
  let categoryId: String?
  let categoryName: String?
  let youtubeTrailer: String?
  let backdropPath: [String]?

  enum CodingKeys: String, CodingKey {
    case num, name, plot, cast, director, genre, rating
    case seriesId = "series_id"
    case cover
    case releaseDate = "release_date"
    case rating5 = "rating_5"
    case categoryId = "category_id"
    case categoryName = "category_name"
    case youtubeTrailer = "youtube_trailer"
    case backdropPath = "backdrop_path"
  }
}

struct XtreamSeriesInfoResponse: Codable {
  let info: XtreamSeriesResponse
  let episodes: [XtreamEpisodeResponse]
}

struct XtreamEpisodeResponse: Codable {
  let id: Int
  let episodeNum: String?
  let title: String
  let containerExtension: String?
  let info: XtreamEpisodeInfo?
  let subtitles: [XtreamSubtitle]?
  let season: Int?
  let airDate: String?

  enum CodingKeys: String, CodingKey {
    case id, title, subtitles, season
    case episodeNum = "episode_num"
    case containerExtension = "container_extension"
    case info
    case airDate = "air_date"
  }
}

struct XtreamEpisodeInfo: Codable {
  let plot: String?
  let releaseDate: String?
  let duration: String?
  let movieImage: String?
  let rating: String?
  let tmdbId: String?

  enum CodingKeys: String, CodingKey {
    case plot
    case releaseDate = "release_date"
    case duration
    case movieImage = "movie_image"
    case rating
    case tmdbId = "tmdb_id"
  }
}

struct XtreamSubtitle: Codable {
  let url: String
  let lang: String
}
