// NCKError.swift
// NextcloudCookbookKit

import Foundation

/// Errors thrown by NextcloudCookbookKit network calls.
public enum NCKError: Error, Sendable {
    /// The URL could not be constructed from the provided base URL and path.
    case invalidURL
    /// The server returned a 3xx redirect response.
    case redirectionError(statusCode: Int)
    /// The server returned a 4xx client error response.
    case clientError(statusCode: Int)
    /// The server returned a 5xx server error response.
    case serverError(statusCode: Int)
    /// The network layer returned no data and no error.
    case noData
    /// JSON decoding of the response body failed.
    case decodingFailed(underlying: Error)
    /// JSON encoding of the request body failed.
    case encodingFailed(underlying: Error)
    /// An underlying URLSession error.
    case transportError(underlying: Error)
    /// The Cookbook app is not installed or not enabled for this user on the server.
    case cookbookUnavailable
    /// The server's Cookbook API version is not implemented by this library.
    case unsupportedAPIVersion(NCKAPIVersion)
    /// Catch-all for unexpected situations.
    case unknown(statusCode: Int?)
}

extension NCKError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The request URL is invalid."
        case .redirectionError(let code):
            return "Redirection error (HTTP \(code))."
        case .clientError(let code):
            return "Client error (HTTP \(code))."
        case .serverError(let code):
            return "Server error (HTTP \(code))."
        case .noData:
            return "The server returned an empty response."
        case .decodingFailed(let err):
            return "Failed to decode response: \(err.localizedDescription)"
        case .encodingFailed(let err):
            return "Failed to encode request body: \(err.localizedDescription)"
        case .transportError(let err):
            return "Network transport error: \(err.localizedDescription)"
        case .cookbookUnavailable:
            return "The Cookbook app is not available on this server."
        case .unsupportedAPIVersion(let version):
            return "Cookbook API version \(version) is not supported."
        case .unknown(let code):
            let suffix = code.map { " (HTTP \($0))" } ?? ""
            return "Unknown error\(suffix)."
        }
    }
}
