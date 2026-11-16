// ChefkochScraper.swift
// RecipeScraperKit

import Foundation

/// Chefkoch.
final class ChefkochScraper: RecipeScraper {
    override class var hosts: [String] { ["chefkoch.de"] }

    override func scrape(_ page: RecipePage) throws -> ScrapedRecipe? {
        try super.scrape(page)
    }
}
