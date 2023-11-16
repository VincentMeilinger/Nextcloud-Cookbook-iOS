//
//  CookbookApi.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 13.11.23.
//

import Foundation
import OSLog
import UIKit


protocol CookbookApi {
    /// Not implemented yet.
    static func importRecipe(
        from serverAdress: String,
        auth: String,
        data: Data
    ) async -> (NetworkError?)
    
    ///  Get either the full image or a thumbnail sized version.
    /// - Parameters:
    ///   - serverAdress: Server address in the format https://example.com.
    ///   - auth: Server authentication string.
    ///   - id: The according recipe id.
    ///   - size: The size of the image.
    /// - Returns: The image of the recipe with the specified id. A NetworkError if the request fails, otherwise nil.
    static func getImage(
        from serverAdress: String,
        auth: String,
        id: Int,
        size: RecipeImage.RecipeImageSize
    ) async -> (UIImage?, NetworkError?)
    
    /// Get all recipes.
    /// - Parameters:
    ///   - serverAdress: Server address in the format https://example.com.
    ///   - auth: Server authentication string.
    /// - Returns: A list of all recipes.
    static func getRecipes(
        from serverAdress: String,
        auth: String
    ) async -> ([Recipe]?, NetworkError?)
    
    /// Create a new recipe.
    /// - Parameters:
    ///   - serverAdress: Server address in the format https://example.com.
    ///   - auth: Server authentication string.
    /// - Returns: A NetworkError if the request fails. Nil otherwise.
    static func createRecipe(
        from serverAdress: String,
        auth: String
    ) async -> (NetworkError?)
    
    /// Get the recipe with the specified id.
    /// - Parameters:
    ///   - serverAdress: Server address in the format https://example.com.
    ///   - auth: Server authentication string.
    ///   - id: The recipe id.
    /// - Returns: The recipe if it exists. A NetworkError if the request fails.
    static func getRecipe(
        from serverAdress: String,
        auth: String, id: Int
    ) async -> (RecipeDetail?, NetworkError?)
    
    /// Update an existing recipe with new entries.
    /// - Parameters:
    ///   - serverAdress: Server address in the format https://example.com.
    ///   - auth: Server authentication string.
    ///   - id: The recipe id.
    /// - Returns: A NetworkError if the request fails. Nil otherwise.
    static func updateRecipe(
        from serverAdress: String,
        auth: String, id: Int
    ) async -> (NetworkError?)
    
    /// Delete the recipe with the specified id.
    /// - Parameters:
    ///   - serverAdress: Server address in the format https://example.com.
    ///   - auth: Server authentication string.
    ///   - id: The recipe id.
    /// - Returns: A NetworkError if the request fails. Nil otherwise.
    static func deleteRecipe(
        from serverAdress: String,
        auth: String,
        id: Int
    ) async -> (NetworkError?)
    
    /// Get all categories.
    /// - Parameters:
    ///   - serverAdress: Server address in the format https://example.com.
    ///   - auth: Server authentication string.
    /// - Returns: A list of categories. A NetworkError if the request fails.
    static func getCategories(
        from serverAdress: String,
        auth: String
    ) async -> ([String]?, NetworkError?)
    
    /// Get all recipes of a specified category.
    /// - Parameters:
    ///   - serverAdress: Server address in the format https://example.com.
    ///   - auth: Server authentication string.
    ///   - categoryName: The category name.
    /// - Returns: A list of recipes. A NetworkError if the request fails.
    static func getCategory(
        from serverAdress: String,
        auth: String,
        named categoryName: String
    ) async -> ([Recipe]?, NetworkError?)
    
    /// Rename an existing category.
    /// - Parameters:
    ///   - serverAdress: Server address in the format https://example.com.
    ///   - auth: Server authentication string.
    ///   - categoryName: The name of the category to be renamed.
    ///   - newName: The new category name.
    /// - Returns: A NetworkError if the request fails.
    static func renameCategory(
        from serverAdress: String,
        auth: String,
        named categoryName: String,
        newName: String
    ) async -> (NetworkError?)
    
    /// Get all keywords/tags.
    /// - Parameters:
    ///   - serverAdress: Server address in the format https://example.com.
    ///   - auth: Server authentication string.
    /// - Returns: A list of tag strings. A NetworkError if the request fails.
    static func getTags(
        from serverAdress: String,
        auth: String
    ) async -> ([String]?, NetworkError?)
    
    /// Get all recipes tagged with the specified keyword.
    /// - Parameters:
    ///   - serverAdress: Server address in the format https://example.com.
    ///   - auth: Server authentication string.
    ///   - keyword: The keyword.
    /// - Returns: A list of recipes tagged with the specified keyword. A NetworkError if the request fails.
    static func getRecipesTagged(
        from serverAdress: String,
        auth: String,
        keyword: String
    ) async -> ([Recipe]?, NetworkError?)
    
    /// Get the servers api version.
    /// - Parameters:
    ///   - serverAdress: Server address in the format https://example.com.
    ///   - auth: Server authentication string.
    /// - Returns: A NetworkError if the request fails.
    static func getApiVersion(
        from serverAdress: String,
        auth: String
    ) async -> (NetworkError?)
    
    /// Trigger a reindexing action on the server.
    /// - Parameters:
    ///   - serverAdress: Server address in the format. https://example.com
    ///   - auth: Server authentication string
    /// - Returns: A NetworkError if the request fails.
    static func postReindex(
        from serverAdress: String,
        auth: String
    ) async -> (NetworkError?)
    
    /// Get the current configuration of the Cookbook server application.
    /// - Parameters:
    ///   - serverAdress: Server address in the format. https://example.com
    ///   - auth: Server authentication string
    /// - Returns: A NetworkError if the request fails.
    static func getConfig(
        from serverAdress: String,
        auth: String
    ) async -> (NetworkError?)
    
    /// Set the current configuration of the Cookbook server application.
    /// - Parameters:
    ///   - serverAdress: Server address in the format. https://example.com
    ///   - auth: Server authentication string
    /// - Returns: A NetworkError if the request fails.
    static func postConfig(
        from serverAdress: String,
        auth: String
    ) async -> (NetworkError?)
}

