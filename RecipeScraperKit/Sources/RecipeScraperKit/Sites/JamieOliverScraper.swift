// JamieOliverScraper.swift
// RecipeScraperKit

import Foundation

/// Jamie Oliver.
final class JamieOliverScraper: RecipeScraper {
    override class var hosts: [String] { ["jamieoliver.com"] }

    override func scrape(_ page: RecipePage) throws -> ScrapedRecipe? {
        try super.scrape(page)
    }
}
