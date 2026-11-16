// ScrapedRecipe.swift
// RecipeScraperKit

import Foundation

/// A recipe read from a web page, already cleaned up: plain text without HTML,
/// times in minutes, one entry per ingredient and per instruction step.
public struct ScrapedRecipe: Equatable, Sendable {
    public var name: String
    public var description: String
    /// The page the recipe was read from.
    public var sourceURL: URL?
    public var imageURL: URL?
    public var category: String?
    public var keywords: [String]
    public var servings: Int?
    /// Times in minutes.
    public var prepTime: Int?
    public var cookTime: Int?
    public var totalTime: Int?
    public var ingredients: [String]
    public var instructions: [String]
    public var tools: [String]
    /// schema.org NutritionInformation keys (e.g. "calories", "fatContent") to display values.
    public var nutrition: [String: String]

    public init(
        name: String = "",
        description: String = "",
        sourceURL: URL? = nil,
        imageURL: URL? = nil,
        category: String? = nil,
        keywords: [String] = [],
        servings: Int? = nil,
        prepTime: Int? = nil,
        cookTime: Int? = nil,
        totalTime: Int? = nil,
        ingredients: [String] = [],
        instructions: [String] = [],
        tools: [String] = [],
        nutrition: [String: String] = [:]
    ) {
        self.name = name
        self.description = description
        self.sourceURL = sourceURL
        self.imageURL = imageURL
        self.category = category
        self.keywords = keywords
        self.servings = servings
        self.prepTime = prepTime
        self.cookTime = cookTime
        self.totalTime = totalTime
        self.ingredients = ingredients
        self.instructions = instructions
        self.tools = tools
        self.nutrition = nutrition
    }

    /// A recipe needs a name and at least ingredients or instructions to be useful.
    public var isUsable: Bool {
        !name.isEmpty && (!ingredients.isEmpty || !instructions.isEmpty)
    }
}


public enum RecipeScraperError: Error, Equatable {
    /// The text is not a web address.
    case invalidURL
    /// The page could not be loaded (offline, timeout, …).
    case network(String)
    /// The server answered with an error status, e.g. 404.
    case httpStatus(Int)
    /// The page loaded, but no recipe was found on it.
    case noRecipeFound
}
