// BBCGoodFoodScraper.swift
// RecipeScraperKit

import Foundation

/// BBC Good Food.
final class BBCGoodFoodScraper: RecipeScraper {
    override class var hosts: [String] { ["bbcgoodfood.com"] }

    override func scrape(_ page: RecipePage) throws -> ScrapedRecipe? {
        try super.scrape(page)
    }
}
