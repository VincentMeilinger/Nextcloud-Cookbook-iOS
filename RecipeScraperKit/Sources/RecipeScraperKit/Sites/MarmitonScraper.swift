// MarmitonScraper.swift
// RecipeScraperKit

import Foundation

/// Marmiton.
final class MarmitonScraper: RecipeScraper {
    override class var hosts: [String] { ["marmiton.org"] }

    override func scrape(_ page: RecipePage) throws -> ScrapedRecipe? {
        try super.scrape(page)
    }
}
