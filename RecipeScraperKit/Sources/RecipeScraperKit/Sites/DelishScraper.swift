// DelishScraper.swift
// RecipeScraperKit

import Foundation

/// Delish (Hearst).
final class DelishScraper: RecipeScraper {
    override class var hosts: [String] { ["delish.com"] }

    override func scrape(_ page: RecipePage) throws -> ScrapedRecipe? {
        try super.scrape(page)
    }
}
