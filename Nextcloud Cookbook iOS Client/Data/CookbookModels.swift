//
//  CookbookModels.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 08.04.26.
//

import Foundation
import SwiftData

// MARK: - StoredRecipeIdentity

/// Registry of app-internal recipe ids. Each recipe, local or from Nextcloud, gets an
/// id here once; Nextcloud recipes keep theirs across fetches by looking it up through
/// `externalSourceId`. Ids are never reused (see `DataStore.allocateRecipeId()`), so
/// stale references such as grocery list entries can't point at a different recipe.
@Model
final class StoredRecipeIdentity {
    @Attribute(.unique) var id: Int
    /// The recipe's id at its source (the Nextcloud recipe id); `nil` for local recipes.
    var externalSourceId: String?

    init(id: Int, externalSourceId: String?) {
        self.id = id
        self.externalSourceId = externalSourceId
    }
}

// MARK: - StoredRecipeDetail

@Model
final class StoredRecipeDetail {
    @Attribute(.unique) var recipeId: Int
    /// The Nextcloud recipe id; `nil` for local recipes.
    var externalSourceId: String?
    var name: String
    var keywords: String
    var dateCreated: String?
    var dateModified: String?
    var imageUrl: String?
    var image: String?
    var prepTime: String?
    var cookTime: String?
    var totalTime: String?
    var recipeDescription: String
    var url: String?
    var recipeYield: Int
    var recipeCategory: String
    /// JSON-encoded [String] (as [String] arrays aren't directly persistable in SwiftData)
    var toolData: Data
    /// JSON-encoded [String ]
    var ingredientData: Data
    /// JSON-encoded [String ]
    var instructionData: Data
    /// JSON-encoded [String: String]
    var nutritionData: Data

    init(recipeId: Int, from detail: RecipeDetail) {
        self.recipeId = recipeId
        self.externalSourceId = detail.externalSourceId
        self.name = detail.name
        self.keywords = detail.keywords
        self.dateCreated = detail.dateCreated
        self.dateModified = detail.dateModified
        self.imageUrl = detail.imageUrl
        self.image = detail.image
        self.prepTime = detail.prepTime
        self.cookTime = detail.cookTime
        self.totalTime = detail.totalTime
        self.recipeDescription = detail.description
        self.url = detail.url
        self.recipeYield = detail.recipeYield
        self.recipeCategory = detail.recipeCategory
        self.toolData = (try? JSONEncoder().encode(detail.tool)) ?? Data()
        self.ingredientData = (try? JSONEncoder().encode(detail.recipeIngredient)) ?? Data()
        self.instructionData = (try? JSONEncoder().encode(detail.recipeInstructions)) ?? Data()
        self.nutritionData = (try? JSONEncoder().encode(detail.nutrition)) ?? Data()
    }

    func update(from detail: RecipeDetail) {
        externalSourceId = detail.externalSourceId
        name = detail.name
        keywords = detail.keywords
        dateCreated = detail.dateCreated
        dateModified = detail.dateModified
        imageUrl = detail.imageUrl
        image = detail.image
        prepTime = detail.prepTime
        cookTime = detail.cookTime
        totalTime = detail.totalTime
        recipeDescription = detail.description
        url = detail.url
        recipeYield = detail.recipeYield
        recipeCategory = detail.recipeCategory
        toolData = (try? JSONEncoder().encode(detail.tool)) ?? Data()
        ingredientData = (try? JSONEncoder().encode(detail.recipeIngredient)) ?? Data()
        instructionData = (try? JSONEncoder().encode(detail.recipeInstructions)) ?? Data()
        nutritionData = (try? JSONEncoder().encode(detail.nutrition)) ?? Data()
    }

    func toRecipeDetail() -> RecipeDetail {
        let tool = (try? JSONDecoder().decode([String].self, from: toolData)) ?? []
        let ingredients = (try? JSONDecoder().decode([String].self, from: ingredientData)) ?? []
        let instructions = (try? JSONDecoder().decode([String].self, from: instructionData)) ?? []
        let nutrition = (try? JSONDecoder().decode([String: String].self, from: nutritionData)) ?? [:]
        return RecipeDetail(
            name: name,
            keywords: keywords,
            dateCreated: dateCreated ?? "",
            dateModified: dateModified ?? "",
            image: image ?? "",
            imageUrl: imageUrl ?? "",
            id: recipeId,
            externalSourceId: externalSourceId,
            prepTime: prepTime,
            cookTime: cookTime,
            totalTime: totalTime,
            description: recipeDescription,
            url: url ?? "",
            recipeYield: recipeYield,
            recipeCategory: recipeCategory,
            tool: tool,
            recipeIngredient: ingredients,
            recipeInstructions: instructions,
            nutrition: nutrition
        )
    }
}

// MARK: - StoredRecipe

@Model
final class StoredRecipe {
    var recipeId: Int
    /// The Nextcloud recipe id; `nil` for local recipes.
    var externalSourceId: String?
    var name: String
    var keywords: String?
    var dateCreated: String?
    var dateModified: String?
    var imageUrl: String?
    var imagePlaceholderUrl: String?
    var categoryName: String

    init(from recipe: Recipe, categoryName: String) {
        self.recipeId = recipe.id
        self.externalSourceId = recipe.externalSourceId
        self.name = recipe.name
        self.keywords = recipe.keywords
        self.dateCreated = recipe.dateCreated
        self.dateModified = recipe.dateModified
        self.imageUrl = recipe.imageUrl
        self.imagePlaceholderUrl = recipe.imagePlaceholderUrl
        self.categoryName = categoryName
    }

    func toRecipe() -> Recipe {
        Recipe(
            id: recipeId,
            externalSourceId: externalSourceId,
            name: name,
            keywords: keywords,
            dateCreated: dateCreated,
            dateModified: dateModified,
            imageUrl: imageUrl,
            imagePlaceholderUrl: imagePlaceholderUrl
        )
    }
}

// MARK: - StoredCategory

@Model
final class StoredCategory {
    @Attribute(.unique) var name: String
    var recipeCount: Int

    init(from category: Category) {
        self.name = category.name
        self.recipeCount = category.recipe_count
    }

    func toCategory() -> Category {
        Category(name: name, recipe_count: recipeCount)
    }
}

// MARK: - StoredKeyword

@Model
final class StoredKeyword {
    var name: String
    var recipeCount: Int

    init(from keyword: RecipeKeyword) {
        self.name = keyword.name
        self.recipeCount = keyword.recipe_count
    }

    func toKeyword() -> RecipeKeyword {
        RecipeKeyword(name: name, recipe_count: recipeCount)
    }
}

// MARK: - StoredGroceryList

/// Single-record store for the entire grocery list dictionary (JSON-encoded).
@Model
final class StoredGroceryList {
    var data: Data

    init(data: Data) {
        self.data = data
    }
}

// MARK: - StoredRecipeImage

@Model
final class StoredRecipeImage {
    var recipeId: Int
    var size: String
    @Attribute(.externalStorage) var imageData: Data?

    init(recipeId: Int, size: String, imageData: Data) {
        self.recipeId = recipeId
        self.size = size
        self.imageData = imageData
    }
}
