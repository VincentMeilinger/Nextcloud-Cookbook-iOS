// BudgetBytesScraper.swift
// RecipeScraperKit

import Foundation

/// Budget Bytes (WP Recipe Maker).
final class BudgetBytesScraper: RecipeScraper {
    override class var hosts: [String] { ["budgetbytes.com"] }

    /// Ingredients list their cost, e.g. "2 tsp smoked paprika ($0.20)"; remove it.
    override func scrape(_ page: RecipePage) throws -> ScrapedRecipe? {
        guard var recipe = try super.scrape(page) else { return nil }
        recipe.ingredients = recipe.ingredients.map { ingredient in
            Normalize.clean(ingredient.replacingOccurrences(of: "\\s*\\(\\$[0-9.,]+\\*?\\)", with: "", options: .regularExpression))
        }
        return recipe
    }
}
