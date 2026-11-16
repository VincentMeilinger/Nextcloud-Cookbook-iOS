// SimplyRecipesScraper.swift
// RecipeScraperKit

import Foundation

/// Simply Recipes (Dotdash Meredith).
final class SimplyRecipesScraper: RecipeScraper {
    override class var hosts: [String] { ["simplyrecipes.com"] }

    override func scrape(_ page: RecipePage) throws -> ScrapedRecipe? {
        try super.scrape(page)
    }
}
