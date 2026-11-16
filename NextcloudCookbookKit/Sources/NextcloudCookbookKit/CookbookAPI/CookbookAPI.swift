// CookbookAPI.swift
// NextcloudCookbookKit
//
// Entry point: detects the server's Cookbook API version and returns a client for it.

import Foundation

/// Creates Cookbook API clients that match the server's API version.
///
/// A Nextcloud Cookbook server exposes a single REST API whose version depends on the
/// installed Cookbook app. ``connect(serverURL:credentials:)`` asks the server for that
/// version once and returns the client implementation for its major version. Features
/// added in later minor versions can be gated on ``CookbookAPIClient/apiVersion``.
public enum CookbookAPI {

    /// Detects the server's API version and returns a matching client.
    ///
    /// - Parameters:
    ///   - serverURL: The root URL of the Nextcloud server (e.g. `https://cloud.example.com`).
    ///   - credentials: Base64-encoded `"username:appPassword"` for Basic authentication.
    /// - Throws: ``NCKError/unsupportedAPIVersion(_:)`` when no client in this library
    ///   implements the server's major version, ``NCKError/cookbookUnavailable`` when
    ///   the Cookbook app isn't installed or enabled, or a network error.
    public static func connect(serverURL: URL, credentials: String) async throws -> any CookbookAPIClient {
        let version = try await fetchAPIVersion(serverURL: serverURL, credentials: credentials)
        switch (version.epoch, version.major) {
        case (0, 1):
            return CookbookAPIClientV1(baseURL: serverURL, credentials: credentials, apiVersion: version)
        default:
            throw NCKError.unsupportedAPIVersion(version)
        }
    }

    /// Returns the Cookbook API version the server implements.
    ///
    /// Reads the OCS capabilities (API 0.1.3+, `cookbook.api_version`). Servers older
    /// than Cookbook 0.11.5 don't publish that capability, so this falls back to the
    /// deprecated `/apps/cookbook/api/version` endpoint.
    public static func fetchAPIVersion(serverURL: URL, credentials: String) async throws -> NCKAPIVersion {
        let http = NCKHTTPClient(baseURL: serverURL, credentials: credentials)
        let headers = ["OCS-APIRequest": "true", "Accept": "application/json"]

        let capabilities = try await http.getData(
            path: "/ocs/v2.php/cloud/capabilities?format=json",
            headers: headers
        )
        if let version = NCKAPIVersion.fromCapabilities(capabilities) {
            return version
        }

        let legacy: Data
        do {
            legacy = try await http.getData(path: "/index.php/apps/cookbook/api/version", headers: headers)
        } catch NCKError.clientError(statusCode: 404) {
            throw NCKError.cookbookUnavailable
        }
        return try NCKAPIVersion.fromVersionEndpoint(legacy)
    }
}
