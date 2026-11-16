// CookbookAPIClientV1.swift
// NextcloudCookbookKit
//
// Nextcloud Cookbook API v1 implementation (API versions 0.1.x).
// Base path: /index.php/apps/cookbook/api/v1

import Foundation

public final class CookbookAPIClientV1: CookbookAPIClient {

    private static let basePath = "/index.php/apps/cookbook/api/v1"

    private let http: NCKHTTPClient

    public let apiVersion: NCKAPIVersion

    /// Prefer ``CookbookAPI/connect(serverURL:credentials:)``, which reads `apiVersion`
    /// from the server. Use this initializer only when the version is already known.
    /// - Parameters:
    ///   - baseURL: The root URL of the Nextcloud server (e.g. `https://cloud.example.com`).
    ///   - credentials: Base64-encoded `"username:appPassword"` for Basic authentication.
    ///   - apiVersion: The server's API version; its major version must be 1.
    public init(baseURL: URL, credentials: String, apiVersion: NCKAPIVersion) {
        self.http = NCKHTTPClient(baseURL: baseURL, credentials: credentials)
        self.apiVersion = apiVersion
    }

    // MARK: - Recipes

    public func getRecipes() async throws -> [NCKRecipe] {
        try await http.get(path: Self.basePath + "/recipes")
    }

    public func getRecipe(id: String) async throws -> NCKRecipeDetail {
        try await http.get(path: Self.basePath + "/recipes/\(pathEncoded(id))")
    }

    public func createRecipe(_ recipe: NCKRecipeDetail) async throws -> String {
        let body = try encode(recipe)
        let data = try await http.send(
            path: Self.basePath + "/recipes",
            method: .POST,
            headers: jsonHeaders(contentType: true),
            body: body
        )
        // The server returns the new id as a bare JSON integer; accept a string as
        // well, since the API is moving to string ids.
        if let id = try? JSONDecoder().decode(Int.self, from: data) {
            return String(id)
        }
        if let id = try? JSONDecoder().decode(String.self, from: data), !id.isEmpty {
            return id
        }
        throw NCKError.decodingFailed(underlying: DecodingError.dataCorrupted(
            .init(codingPath: [], debugDescription: "Expected a recipe id in the response.")
        ))
    }

    public func updateRecipe(_ recipe: NCKRecipeDetail) async throws {
        guard !recipe.id.isEmpty else {
            throw NCKError.clientError(statusCode: 400)
        }
        let body = try encode(recipe)
        _ = try await http.send(
            path: Self.basePath + "/recipes/\(pathEncoded(recipe.id))",
            method: .PUT,
            headers: jsonHeaders(contentType: true),
            body: body
        )
    }

    public func deleteRecipe(id: String) async throws {
        try await http.delete(path: Self.basePath + "/recipes/\(pathEncoded(id))")
    }

    public func importRecipe(from url: URL) async throws -> NCKRecipeDetail {
        let importBody = try encode(["url": url.absoluteString])
        return try await http.post(
            path: Self.basePath + "/import",
            body: importBody,
            headers: jsonHeaders(contentType: true)
        )
    }

    // MARK: - Images

    public func getImage(recipeId: String, size: NCKImageSize) async throws -> Data {
        try await http.getData(
            path: Self.basePath + "/recipes/\(pathEncoded(recipeId))/image?size=\(size.rawValue)",
            headers: ["OCS-APIRequest": "true", "Accept": "image/jpeg"]
        )
    }

    // MARK: - Categories

    public func getCategories() async throws -> [NCKCategory] {
        try await http.get(path: Self.basePath + "/categories")
    }

    public func getRecipes(inCategory name: String) async throws -> [NCKRecipe] {
        try await http.get(path: Self.basePath + "/category/\(pathEncoded(name))")
    }

    public func renameCategory(named name: String, to newName: String) async throws {
        let body = try encode(["name": newName])
        _ = try await http.send(
            path: Self.basePath + "/category/\(pathEncoded(name))",
            method: .PUT,
            headers: jsonHeaders(contentType: true),
            body: body
        )
    }

    // MARK: - Keywords / Tags

    public func getKeywords() async throws -> [NCKKeyword] {
        try await http.get(path: Self.basePath + "/keywords")
    }

    public func getRecipes(taggedWith keyword: String) async throws -> [NCKRecipe] {
        try await http.get(path: Self.basePath + "/tags/\(pathEncoded(keyword))")
    }

    // MARK: - Server management

    public func reindex() async throws {
        _ = try await http.send(path: Self.basePath + "/reindex", method: .POST, headers: jsonHeaders())
    }

    public func getConfig() async throws -> Data {
        try await http.getData(path: Self.basePath + "/config", headers: jsonHeaders())
    }

    public func setConfig(_ config: Data) async throws {
        _ = try await http.send(
            path: Self.basePath + "/config",
            method: .POST,
            headers: jsonHeaders(contentType: true),
            body: config
        )
    }

    // MARK: - Private helpers

    /// Percent-encodes a string for use as a single URL path segment.
    /// `.urlPathAllowed` encodes spaces but leaves `/` intact; subtract it so
    /// a segment with an embedded `/` doesn't silently split the path.
    private func pathEncoded(_ segment: String) -> String {
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove(charactersIn: "/")
        return segment.addingPercentEncoding(withAllowedCharacters: allowed) ?? segment
    }

    private func encode<T: Encodable>(_ value: T) throws -> Data {
        do {
            return try JSONEncoder().encode(value)
        } catch {
            throw NCKError.encodingFailed(underlying: error)
        }
    }

    private func jsonHeaders(contentType: Bool = false) -> [String: String] {
        var h = ["OCS-APIRequest": "true", "Accept": "application/json"]
        if contentType { h["Content-Type"] = "application/json" }
        return h
    }
}
