// SeriousEatsScraper.swift
// RecipeScraperKit

import Foundation

/// Serious Eats (Dotdash Meredith).
final class SeriousEatsScraper: RecipeScraper {
    override class var hosts: [String] { ["seriouseats.com"] }

    override func scrape(_ page: RecipePage) throws -> ScrapedRecipe? {
        try super.scrape(page)
    }
}
