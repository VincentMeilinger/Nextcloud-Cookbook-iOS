// CookieAndKateScraper.swift
// RecipeScraperKit

import Foundation

/// Cookie and Kate (WP Recipe Maker).
final class CookieAndKateScraper: RecipeScraper {
    override class var hosts: [String] { ["cookieandkate.com"] }

    override func scrape(_ page: RecipePage) throws -> ScrapedRecipe? {
        try super.scrape(page)
    }
}
