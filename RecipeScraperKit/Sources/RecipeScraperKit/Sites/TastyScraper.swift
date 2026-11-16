// TastyScraper.swift
// RecipeScraperKit

import Foundation

/// Tasty.
final class TastyScraper: RecipeScraper {
    override class var hosts: [String] { ["tasty.co"] }

    /// Recipe names end in " Recipe by Tasty"; remove it.
    override func scrape(_ page: RecipePage) throws -> ScrapedRecipe? {
        guard var recipe = try super.scrape(page) else { return nil }
        recipe.name = recipe.name.replacingOccurrences(of: "\\s+Recipe by Tasty$", with: "", options: .regularExpression)
        return recipe
    }
}
