// FoodComScraper.swift
// RecipeScraperKit

import Foundation

/// Food.com.
final class FoodComScraper: RecipeScraper {
    override class var hosts: [String] { ["food.com"] }

    override func scrape(_ page: RecipePage) throws -> ScrapedRecipe? {
        try super.scrape(page)
    }
}
