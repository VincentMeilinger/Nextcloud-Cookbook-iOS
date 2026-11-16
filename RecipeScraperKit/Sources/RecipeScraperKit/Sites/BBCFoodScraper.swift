// BBCFoodScraper.swift
// RecipeScraperKit

import Foundation

/// BBC Food (bbc.co.uk/food).
final class BBCFoodScraper: RecipeScraper {
    override class var hosts: [String] { ["bbc.co.uk", "bbc.com"] }

    override func scrape(_ page: RecipePage) throws -> ScrapedRecipe? {
        try super.scrape(page)
    }
}
