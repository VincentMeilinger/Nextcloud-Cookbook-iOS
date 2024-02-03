//
//  CookbookApi.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 13.11.23.
//

import Foundation
import OSLog
import UIKit


/// The Cookbook API class used for requests to the Nextcloud Cookbook service.
let cookbookApi: CookbookApi.Type = getApi()

func getApi() -> CookbookApi.Type {
    switch UserSettings.shared.cookbookApiVersion {
    case .v1:
        return CookbookApiV1.self
    }
}

/// The Cookbook API version.
enum CookbookApiVersion: String {
    case v1 = "v1"
}


/// A protocol defining common API endpoints that are likely to remain the same over future Cookbook API versions.
protocol CookbookApi {
    static var basePath: String { get }
    
    /// Not implemented yet.
    static func importRecipe(
        auth: String,
        data: Data
    ) async -> (RecipeDetail?, NetworkError?)
    
    ///  Get either the full image or a thumbnail sized version.
    /// - Parameters:
    ///   - auth: Server authentication string.
    ///   - id: The according recipe id.
    ///   - size: The size of the image.
    /// - Returns: The image of the recipe with the specified id. A NetworkError if the request fails, otherwise nil.
    static func getImage(
        auth: String,
        id: Int,
        size: RecipeImage.RecipeImageSize
    ) async -> (UIImage?, NetworkError?)
    
    /// Get all recipes.
    /// - Parameters:
    ///   - auth: Server authentication string.
    /// - Returns: A list of all recipes.
    static func getRecipes(
        auth: String
    ) async -> ([Recipe]?, NetworkError?)
    
    /// Create a new recipe.
    /// - Parameters:
    ///   - auth: Server authentication string.
    /// - Returns: A NetworkError if the request fails. Nil otherwise.
    static func createRecipe(
        auth: String,
        recipe: RecipeDetail
    ) async -> (NetworkError?)
    
    /// Get the recipe with the specified id.
    /// - Parameters:
    ///   - auth: Server authentication string.
    ///   - id: The recipe id.
    /// - Returns: The recipe if it exists. A NetworkError if the request fails.
    static func getRecipe(
        auth: String, id: Int
    ) async -> (RecipeDetail?, NetworkError?)
    
    /// Update an existing recipe with new entries.
    /// - Parameters:
    ///   - auth: Server authentication string.
    ///   - id: The recipe id.
    /// - Returns: A NetworkError if the request fails. Nil otherwise.
    static func updateRecipe(
        auth: String,
        recipe: RecipeDetail
    ) async -> (NetworkError?)
    
    /// Delete the recipe with the specified id.
    /// - Parameters:
    ///   - auth: Server authentication string.
    ///   - id: The recipe id.
    /// - Returns: A NetworkError if the request fails. Nil otherwise.
    static func deleteRecipe(
        auth: String,
        id: Int
    ) async -> (NetworkError?)
    
    /// Get all categories.
    /// - Parameters:
    ///   - auth: Server authentication string.
    /// - Returns: A list of categories. A NetworkError if the request fails.
    static func getCategories(
        auth: String
    ) async -> ([Category]?, NetworkError?)
    
    /// Get all recipes of a specified category.
    /// - Parameters:
    ///   - auth: Server authentication string.
    ///   - categoryName: The category name.
    /// - Returns: A list of recipes. A NetworkError if the request fails.
    static func getCategory(
        auth: String,
        named categoryName: String
    ) async -> ([Recipe]?, NetworkError?)
    
    /// Rename an existing category.
    /// - Parameters:
    ///   - auth: Server authentication string.
    ///   - categoryName: The name of the category to be renamed.
    ///   - newName: The new category name.
    /// - Returns: A NetworkError if the request fails.
    static func renameCategory(
        auth: String,
        named categoryName: String,
        newName: String
    ) async -> (NetworkError?)
    
    /// Get all keywords/tags.
    /// - Parameters:
    ///   - auth: Server authentication string.
    /// - Returns: A list of tag strings. A NetworkError if the request fails.
    static func getTags(
        auth: String
    ) async -> ([RecipeKeyword]?, NetworkError?)
    
    /// Get all recipes tagged with the specified keyword.
    /// - Parameters:
    ///   - auth: Server authentication string.
    ///   - keyword: The keyword.
    /// - Returns: A list of recipes tagged with the specified keyword. A NetworkError if the request fails.
    static func getRecipesTagged(
        auth: String,
        keyword: String
    ) async -> ([Recipe]?, NetworkError?)
    
    /// Get the servers api version.
    /// - Parameters:
    ///   - auth: Server authentication string.
    /// - Returns: A NetworkError if the request fails.
    static func getApiVersion(
        auth: String
    ) async -> (NetworkError?)
    
    /// Trigger a reindexing action on the server.
    /// - Parameters:
    ///   - auth: Server authentication string
    /// - Returns: A NetworkError if the request fails.
    static func postReindex(
        auth: String
    ) async -> (NetworkError?)
    
    /// Get the current configuration of the Cookbook server application.
    /// - Parameters:
    ///   - auth: Server authentication string
    /// - Returns: A NetworkError if the request fails.
    static func getConfig(
        auth: String
    ) async -> (NetworkError?)
    
    /// Set the current configuration of the Cookbook server application.
    /// - Parameters:
    ///   - auth: Server authentication string
    /// - Returns: A NetworkError if the request fails.
    static func postConfig(
        auth: String
    ) async -> (NetworkError?)
}




