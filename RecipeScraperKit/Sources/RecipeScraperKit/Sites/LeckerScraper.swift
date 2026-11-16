// LeckerScraper.swift
// RecipeScraperKit

import Foundation

/// LECKER.
final class LeckerScraper: RecipeScraper {
    override class var hosts: [String] { ["lecker.de"] }

    /// Recipe names end in " Rezept" ("Einfacher Apfel-Crumble Rezept"); remove it.
    override func scrape(_ page: RecipePage) throws -> ScrapedRecipe? {
        guard var recipe = try super.scrape(page) else { return nil }
        recipe.name = recipe.name.replacingOccurrences(of: "\\s+Rezept$", with: "", options: .regularExpression)
        return recipe
    }
}
