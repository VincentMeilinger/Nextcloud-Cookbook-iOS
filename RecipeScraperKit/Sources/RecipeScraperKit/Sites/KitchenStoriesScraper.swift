// KitchenStoriesScraper.swift
// RecipeScraperKit

import Foundation

/// Kitchen Stories.
final class KitchenStoriesScraper: RecipeScraper {
    override class var hosts: [String] { ["kitchenstories.com"] }

    override func scrape(_ page: RecipePage) throws -> ScrapedRecipe? {
        try super.scrape(page)
    }
}
