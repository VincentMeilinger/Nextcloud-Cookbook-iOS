// CookbookAPIClient.swift
// NextcloudCookbookKit
//
// Protocol that all versioned Cookbook API implementations must conform to.
// Each method is async and throws NCKError on failure.

import Foundation

/// A client for one major version of the Nextcloud Cookbook REST API.
///
/// Obtain one with ``CookbookAPI/connect(serverURL:credentials:)``, which picks the
/// implementation matching the server's major version (e.g. ``CookbookAPIClientV1`` for
/// `/api/v1`). The same instance can be used for the lifetime of a logged-in session.
///
/// Minor API versions only add to a major version; check ``apiVersion`` before using a
/// feature that older servers lack. A new major version (e.g. `/api/v2`) gets its own
/// conforming type.
///
/// Recipe ids are the server's identifiers, passed as strings: the Cookbook API is
/// moving from integer to string ids (deprecation in API 0.1.2).
public protocol CookbookAPIClient: Sendable {

    /// The API version the server reported when this client was created.
    var apiVersion: NCKAPIVersion { get }

    // MARK: - Recipes

    /// Returns all recipes across all categories.
    func getRecipes() async throws -> [NCKRecipe]

    /// Returns the full detail of a single recipe.
    func getRecipe(id: String) async throws -> NCKRecipeDetail

    /// Creates a new recipe and returns its server-assigned id.
    @discardableResult
    func createRecipe(_ recipe: NCKRecipeDetail) async throws -> String

    /// Replaces an existing recipe (identified by `recipe.id`) with the supplied detail.
    func updateRecipe(_ recipe: NCKRecipeDetail) async throws

    /// Permanently deletes a recipe.
    func deleteRecipe(id: String) async throws

    /// Imports a recipe from an external URL and returns the resulting detail.
    func importRecipe(from url: URL) async throws -> NCKRecipeDetail

    // MARK: - Images

    /// Returns raw image data for a recipe.  The caller is responsible for
    /// converting to a platform image type (e.g. `UIImage(data:)`).
    func getImage(recipeId: String, size: NCKImageSize) async throws -> Data

    // MARK: - Categories

    /// Returns all categories on the server.
    func getCategories() async throws -> [NCKCategory]

    /// Returns all recipes inside a specific category.
    func getRecipes(inCategory name: String) async throws -> [NCKRecipe]

    /// Renames a category.
    func renameCategory(named name: String, to newName: String) async throws

    // MARK: - Keywords / Tags

    /// Returns all keywords defined on the server.
    func getKeywords() async throws -> [NCKKeyword]

    /// Returns all recipes tagged with the supplied keyword.
    func getRecipes(taggedWith keyword: String) async throws -> [NCKRecipe]

    // MARK: - Server management

    /// Triggers a recipe re-index on the server.
    func reindex() async throws

    /// Retrieves the current server configuration as raw JSON data.
    func getConfig() async throws -> Data

    /// Sends a new configuration to the server.
    func setConfig(_ config: Data) async throws
}
