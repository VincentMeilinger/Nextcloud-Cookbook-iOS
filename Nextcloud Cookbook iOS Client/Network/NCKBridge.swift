//
//  NCKBridge.swift
//  Nextcloud Cookbook iOS Client
//
//  Converts between app model types and NextcloudCookbookKit types.
//

import Foundation
import NextcloudCookbookKit

// MARK: - NCKRecipe → Recipe

// The Kit carries Nextcloud's recipe ids; the app identifies recipes by its own
// internal ids and keeps the Nextcloud id as `externalSourceId`. Callers look up the
// internal id with `DataStore.recipeIds(forExternalIds:)`.

extension NCKRecipe {
    func toRecipe(id: Int) -> Recipe {
        Recipe(
            id: id,
            externalSourceId: self.id,
            name: name,
            keywords: keywords,
            dateCreated: dateCreated,
            dateModified: dateModified,
            imageUrl: imageUrl,
            imagePlaceholderUrl: imagePlaceholderUrl
        )
    }
}

// MARK: - NCKCategory → Category

extension NCKCategory {
    func toCategory() -> Category {
        Category(name: name, recipe_count: recipeCount)
    }
}

// MARK: - NCKKeyword → RecipeKeyword

extension NCKKeyword {
    func toKeyword() -> RecipeKeyword {
        RecipeKeyword(name: name, recipe_count: recipeCount)
    }
}

// MARK: - NCKRecipeDetail ↔ RecipeDetail

extension NCKRecipeDetail {
    /// - Parameter id: The app-internal id, or `nil` when the recipe has none yet.
    func toRecipeDetail(id: Int?) -> RecipeDetail {
        RecipeDetail(
            name: name,
            keywords: keywords,
            dateCreated: dateCreated ?? "",
            dateModified: dateModified ?? "",
            image: image ?? "",
            imageUrl: imageUrl ?? "",
            id: id,
            externalSourceId: self.id.isEmpty ? nil : self.id,
            prepTime: prepTime,
            cookTime: cookTime,
            totalTime: totalTime,
            description: description,
            url: url ?? "",
            recipeYield: recipeYield,
            recipeCategory: recipeCategory,
            tool: tool,
            recipeIngredient: recipeIngredient,
            recipeInstructions: recipeInstructions,
            nutrition: nutrition
        )
    }
}

extension RecipeDetail {
    func toNCKRecipeDetail() -> NCKRecipeDetail {
        NCKRecipeDetail(
            name: name,
            keywords: keywords,
            dateCreated: dateCreated,
            dateModified: dateModified,
            imageUrl: imageUrl,
            image: image,
            id: externalSourceId ?? "",
            prepTime: prepTime,
            cookTime: cookTime,
            totalTime: totalTime,
            description: description,
            url: url,
            recipeYield: recipeYield,
            recipeCategory: recipeCategory,
            tool: tool,
            recipeIngredient: recipeIngredient,
            recipeInstructions: recipeInstructions,
            nutrition: nutrition
        )
    }
}

// MARK: - RecipeImage.RecipeImageSize → NCKImageSize

extension RecipeImage.RecipeImageSize {
    var nckImageSize: NCKImageSize {
        switch self {
        case .THUMB: return .thumb
        case .FULL: return .full
        }
    }
}
