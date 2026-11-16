// EpicuriousScraper.swift
// RecipeScraperKit

import Foundation

/// Epicurious (Condé Nast).
final class EpicuriousScraper: RecipeScraper {
    override class var hosts: [String] { ["epicurious.com"] }

    override func scrape(_ page: RecipePage) throws -> ScrapedRecipe? {
        try super.scrape(page)
    }
}
