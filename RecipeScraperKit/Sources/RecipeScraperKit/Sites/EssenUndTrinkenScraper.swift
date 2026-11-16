// EssenUndTrinkenScraper.swift
// RecipeScraperKit

import Foundation

/// essen & trinken.
final class EssenUndTrinkenScraper: RecipeScraper {
    override class var hosts: [String] { ["essen-und-trinken.de"] }

    /// Recipe names end in " Rezept" ("Einfacher Apfel-Crumble Rezept"); remove it.
    override func scrape(_ page: RecipePage) throws -> ScrapedRecipe? {
        guard var recipe = try super.scrape(page) else { return nil }
        recipe.name = recipe.name.replacingOccurrences(of: "\\s+Rezept$", with: "", options: .regularExpression)
        return recipe
    }
}
