// NYTCookingScraper.swift
// RecipeScraperKit

import Foundation

/// NYT Cooking.
final class NYTCookingScraper: RecipeScraper {
    override class var hosts: [String] { ["cooking.nytimes.com"] }

    override func scrape(_ page: RecipePage) throws -> ScrapedRecipe? {
        try super.scrape(page)
    }
}
