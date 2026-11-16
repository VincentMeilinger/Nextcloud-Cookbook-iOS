// FoodNetworkScraper.swift
// RecipeScraperKit

import Foundation

/// Food Network (US and UK; non-US visitors are redirected to foodnetwork.co.uk).
final class FoodNetworkScraper: RecipeScraper {
    override class var hosts: [String] { ["foodnetwork.com", "foodnetwork.co.uk"] }

    /// All steps arrive as one HTML list (split by the generic scraper), and the
    /// ingredients contain group headings like "For the Filling:". Headings are
    /// shown in bold (the Cookbook app renders Markdown in ingredients).
    override func scrape(_ page: RecipePage) throws -> ScrapedRecipe? {
        guard var recipe = try super.scrape(page) else { return nil }
        recipe.ingredients = recipe.ingredients.map { ingredient in
            ingredient.hasSuffix(":") ? "**\(ingredient.dropLast())**" : ingredient
        }
        return recipe
    }
}
