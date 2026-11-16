// BonAppetitScraper.swift
// RecipeScraperKit

import Foundation

/// Bon Appétit (Condé Nast).
final class BonAppetitScraper: RecipeScraper {
    override class var hosts: [String] { ["bonappetit.com"] }

    override func scrape(_ page: RecipePage) throws -> ScrapedRecipe? {
        try super.scrape(page)
    }
}
