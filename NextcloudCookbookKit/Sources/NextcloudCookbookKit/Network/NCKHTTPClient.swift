// NCKHTTPClient.swift
// NextcloudCookbookKit
//
// Internal HTTP plumbing. All public API clients build on top of this.

import Foundation

enum HTTPMethod: String {
    case GET, POST, PUT, DELETE
}

enum NCKContentType: String {
    case json = "application/json"
    case image = "image/jpeg"
    case form = "application/x-www-form-urlencoded"
}

/// A minimal, dependency-injection-friendly HTTP client used internally by the library.
/// It is not part of the public API surface.
struct NCKHTTPClient: Sendable {
    let baseURL: URL
    /// Base64-encoded "username:password" or app-password token for Basic auth.
    /// Pass `nil` for unauthenticated requests (e.g., the login-flow initiation).
    let credentials: String?

    // MARK: - Core send

    func send(
        path: String,
        method: HTTPMethod,
        headers: [String: String] = [:],
        body: Data? = nil,
        absolutePath: Bool = false
    ) async throws -> Data {
        let url: URL
        if absolutePath {
            guard let u = URL(string: path) else { throw NCKError.invalidURL }
            url = u
        } else {
            // Normalise: strip trailing slash from base, ensure path starts with one
            let cleanBase = baseURL.absoluteString.hasSuffix("/")
                ? String(baseURL.absoluteString.dropLast())
                : baseURL.absoluteString
            let cleanPath = path.hasPrefix("/") ? path : "/\(path)"
            guard let u = URL(string: cleanBase + cleanPath) else {
                throw NCKError.invalidURL
            }
            url = u
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        if let credentials {
            request.setValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")
        }

        for (field, value) in headers {
            request.setValue(value, forHTTPHeaderField: field)
        }

        if let body {
            request.httpBody = body
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw NCKError.transportError(underlying: error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw NCKError.unknown(statusCode: nil)
        }
        switch http.statusCode {
        case 200...299: break
        case 300...399: throw NCKError.redirectionError(statusCode: http.statusCode)
        case 400...499: throw NCKError.clientError(statusCode: http.statusCode)
        case 500...599: throw NCKError.serverError(statusCode: http.statusCode)
        default: throw NCKError.unknown(statusCode: http.statusCode)
        }

        return data
    }

    // MARK: - Convenience: JSON decode

    func get<T: Decodable>(
        path: String,
        headers: [String: String] = [:]
    ) async throws -> T {
        let data = try await send(path: path, method: .GET, headers: jsonHeaders(merging: headers))
        return try decode(T.self, from: data)
    }

    func post<T: Decodable>(
        path: String,
        body: Data,
        headers: [String: String] = [:]
    ) async throws -> T {
        let data = try await send(
            path: path,
            method: .POST,
            headers: jsonHeaders(merging: headers, contentType: .json),
            body: body
        )
        return try decode(T.self, from: data)
    }

    func put<T: Decodable>(
        path: String,
        body: Data,
        headers: [String: String] = [:]
    ) async throws -> T {
        let data = try await send(
            path: path,
            method: .PUT,
            headers: jsonHeaders(merging: headers, contentType: .json),
            body: body
        )
        return try decode(T.self, from: data)
    }

    func delete(path: String, headers: [String: String] = [:]) async throws {
        _ = try await send(path: path, method: .DELETE, headers: jsonHeaders(merging: headers))
    }

    // MARK: - Raw data (images)

    func getData(path: String, headers: [String: String] = [:]) async throws -> Data {
        try await send(path: path, method: .GET, headers: headers)
    }

    // MARK: - Helpers

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw NCKError.decodingFailed(underlying: error)
        }
    }

    private func jsonHeaders(
        merging extra: [String: String] = [:],
        contentType: NCKContentType? = nil
    ) -> [String: String] {
        var h: [String: String] = [
            "OCS-APIRequest": "true",
            "Accept": NCKContentType.json.rawValue,
        ]
        if let contentType {
            h["Content-Type"] = contentType.rawValue
        }
        h.merge(extra) { _, new in new }
        return h
    }
}
