//
//  XtreamService.swift
//  ProFlix
//
//  Service for interacting with Xtream Codes API
//

import Foundation

/// Service for fetching data from Xtream Codes API
final class XtreamService {

  let baseURL: URL
  let username: String
  let password: String

  private let session: URLSession

  init(baseURL: URL, username: String, password: String) {
    self.baseURL = baseURL
    self.username = username
    self.password = password

    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 30
    config.timeoutIntervalForResource = 60
    self.session = URLSession(configuration: config)
  }

  // MARK: - Authentication

  /// Authenticate with Xtream API and get basic info (username and optional EPG URL)
  func authenticate() async throws -> (username: String, epgURL: String?) {
    let url = buildAPIURL(action: "get_user_info")
    let (data, response) = try await session.data(from: url)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw XtreamError.invalidResponse
    }

    guard httpResponse.statusCode == 200 else {
      throw XtreamError.httpError(statusCode: httpResponse.statusCode)
    }

    // Xtream returns { "user_info": {...}, "server_info": {...} }
    do {
      let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
      guard let root = json else {
        throw XtreamError.decodingError(
          NSError(
            domain: "Xtream",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Invalid JSON"]
          )
        )
      }

      guard let userInfo = root["user_info"] as? [String: Any],
        let username = userInfo["username"] as? String
      else {
        throw XtreamError.decodingError(
          NSError(
            domain: "Xtream",
            code: -2,
            userInfo: [NSLocalizedDescriptionKey: "Missing user_info.username"]
          )
        )
      }

      var epgURL: String? = nil
      if let serverInfo = root["server_info"] as? [String: Any],
        let epg = serverInfo["epg_url"] as? String
      {
        epgURL = epg
      }

      return (username, epgURL)
    } catch let error as XtreamError {
      throw error
    } catch {
      // Try to decode error response if available
      if let errorResponse = try? JSONDecoder().decode(XtreamErrorResponse.self, from: data) {
        throw XtreamError.apiError(message: errorResponse.message ?? "Unknown error")
      }
      print("Failed to parse auth response: \(error)")
      throw XtreamError.decodingError(error)
    }
  }

  // MARK: - Categories

  /// Fetch Live TV categories
  func getLiveCategories() async throws -> [XtreamCategoryResponse] {
    try await fetchCategories(action: "get_live_categories")
  }

  /// Fetch Movie (VOD) categories
  func getVODCategories() async throws -> [XtreamCategoryResponse] {
    try await fetchCategories(action: "get_vod_categories")
  }

  /// Fetch Series categories
  func getSeriesCategories() async throws -> [XtreamCategoryResponse] {
    try await fetchCategories(action: "get_series_categories")
  }

  private func fetchCategories(action: String) async throws -> [XtreamCategoryResponse] {
    let url = buildAPIURL(action: action)
    let (data, _) = try await session.data(from: url)

    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase

    do {
      return try decoder.decode([XtreamCategoryResponse].self, from: data)
    } catch {
      print("Failed to decode categories as [XtreamCategoryResponse]: \(error)")

      // Fallback: try to parse a more generic shape and map manually
      do {
        let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])

        // Case 1: Array of dictionaries [[String: Any]]
        if let array = jsonObject as? [[String: Any]] {
          var results: [XtreamCategoryResponse] = []
          for (index, item) in array.enumerated() {
            let id = item["category_id"] as? String ?? String(index)
            let name = item["category_name"] as? String ?? "Unknown"
            let parentId = item["parent_id"] as? Int
            let cat = XtreamCategoryResponse(categoryId: id, categoryName: name, parentId: parentId)
            results.append(cat)
          }
          return results
        }

        // Case 2: Dictionary keyed by id: { "1": {..}, "2": {..} }
        if let dict = jsonObject as? [String: Any] {
          var results: [XtreamCategoryResponse] = []
          for (key, value) in dict {
            guard let item = value as? [String: Any] else { continue }
            let id = item["category_id"] as? String ?? key
            let name = item["category_name"] as? String ?? "Unknown"
            let parentId = item["parent_id"] as? Int
            let cat = XtreamCategoryResponse(categoryId: id, categoryName: name, parentId: parentId)
            results.append(cat)
          }
          return results
        }

        // If we get here, we don't recognize the shape
        throw XtreamError.decodingError(error)
      } catch {
        print("Failed fallback category parsing: \(error)")
        throw XtreamError.decodingError(error)
      }
    }
  }

  // MARK: - Streams

  /// Fetch Live TV streams
  func getLiveStreams(categoryId: String? = nil) async throws -> [XtreamStreamResponse] {
    var action = "get_live_streams"
    if let categoryId = categoryId {
      action += "&category_id=\(categoryId)"
    }
    return try await fetchStreams(action: action)
  }

  /// Fetch Movie (VOD) streams
  func getVODStreams(categoryId: String? = nil) async throws -> [XtreamStreamResponse] {
    var action = "get_vod_streams"
    if let categoryId = categoryId {
      action += "&category_id=\(categoryId)"
    }
    return try await fetchStreams(action: action)
  }

  /// Fetch Series
  func getSeries(categoryId: String? = nil) async throws -> [XtreamSeriesResponse] {
    var action = "get_series"
    if let categoryId = categoryId {
      action += "&category_id=\(categoryId)"
    }

    let url = buildAPIURL(action: action)
    let (data, _) = try await session.data(from: url)

    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase

    do {
      return try decoder.decode([XtreamSeriesResponse].self, from: data)
    } catch {
      print("Failed to decode series: \(error)")
      throw XtreamError.decodingError(error)
    }
  }

  /// Fetch episodes for a series
  func getSeriesInfo(seriesId: String) async throws -> XtreamSeriesInfoResponse {
    let url = buildAPIURL(action: "get_series_info&series_id=\(seriesId)")
    let (data, _) = try await session.data(from: url)

    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase

    do {
      return try decoder.decode(XtreamSeriesInfoResponse.self, from: data)
    } catch {
      print("Failed to decode series info: \(error)")
      throw XtreamError.decodingError(error)
    }
  }

  private func fetchStreams(action: String) async throws -> [XtreamStreamResponse] {
    let url = buildAPIURL(action: action)
    let (data, _) = try await session.data(from: url)

    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase

    do {
      return try decoder.decode([XtreamStreamResponse].self, from: data)
    } catch {
      print("Failed to decode streams: \(error)")
      throw XtreamError.decodingError(error)
    }
  }

  // MARK: - EPG

  /// Get EPG URL from user info (usually in user_info response)
  func getEPGURL() async throws -> String? {
    let auth = try await authenticate()
    return auth.epgURL
  }

  // MARK: - Helper Methods

  private func buildAPIURL(action: String) -> URL {
    var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
    components.path = "/player_api.php"
    components.queryItems = [
      URLQueryItem(name: "username", value: username),
      URLQueryItem(name: "password", value: password),
    ]

    // Handle action (might be in query string format already)
    if action.contains("&") {
      // Action already has query params
      let parts = action.split(separator: "&")
      if let firstPart = parts.first {
        components.queryItems?.append(URLQueryItem(name: "action", value: String(firstPart)))
        for part in parts.dropFirst() {
          let keyValue = part.split(separator: "=", maxSplits: 1)
          if keyValue.count == 2 {
            components.queryItems?.append(
              URLQueryItem(name: String(keyValue[0]), value: String(keyValue[1]))
            )
          }
        }
      }
    } else {
      components.queryItems?.append(URLQueryItem(name: "action", value: action))
    }

    guard let url = components.url else {
      fatalError("Invalid URL construction")
    }
    return url
  }
}

// MARK: - Errors

enum XtreamError: LocalizedError {
  case invalidResponse
  case httpError(statusCode: Int)
  case apiError(message: String)
  case decodingError(Error)
  case networkError(Error)

  var errorDescription: String? {
    switch self {
    case .invalidResponse:
      return "Invalid response from server"
    case .httpError(let code):
      return "HTTP error: \(code)"
    case .apiError(let message):
      return message
    case .decodingError(let error):
      return "Failed to parse response: \(error.localizedDescription)"
    case .networkError(let error):
      return "Network error: \(error.localizedDescription)"
    }
  }
}

// MARK: - Error Response Model

struct XtreamErrorResponse: Codable {
  let message: String?
}
