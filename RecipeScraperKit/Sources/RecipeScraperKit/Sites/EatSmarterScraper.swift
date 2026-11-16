// EatSmarterScraper.swift
// RecipeScraperKit

import Foundation

/// EAT SMARTER.
final class EatSmarterScraper: RecipeScraper {
    override class var hosts: [String] { ["eatsmarter.de", "eatsmarter.com"] }

    override func scrape(_ page: RecipePage) throws -> ScrapedRecipe? {
        try super.scrape(page)
    }
}
