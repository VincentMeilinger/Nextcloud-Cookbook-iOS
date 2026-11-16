// AllrecipesScraper.swift
// RecipeScraperKit

import Foundation

/// Allrecipes (Dotdash Meredith).
final class AllrecipesScraper: RecipeScraper {
    override class var hosts: [String] { ["allrecipes.com"] }

    override func scrape(_ page: RecipePage) throws -> ScrapedRecipe? {
        try super.scrape(page)
    }
}
