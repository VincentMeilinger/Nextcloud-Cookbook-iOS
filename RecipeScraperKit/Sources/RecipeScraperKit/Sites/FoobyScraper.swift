// FoobyScraper.swift
// RecipeScraperKit

import Foundation

/// FOOBY.
final class FoobyScraper: RecipeScraper {
    override class var hosts: [String] { ["fooby.ch"] }

    override func scrape(_ page: RecipePage) throws -> ScrapedRecipe? {
        try super.scrape(page)
    }
}
