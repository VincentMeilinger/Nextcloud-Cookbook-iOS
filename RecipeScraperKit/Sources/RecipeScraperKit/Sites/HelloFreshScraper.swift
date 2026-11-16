// HelloFreshScraper.swift
// RecipeScraperKit

import Foundation

/// HelloFresh.
final class HelloFreshScraper: RecipeScraper {
    override class var hosts: [String] { ["hellofresh.com", "hellofresh.de", "hellofresh.co.uk", "hellofresh.at", "hellofresh.ch", "hellofresh.fr", "hellofresh.nl"] }

    /// Each step is a bullet list ("• Halve potatoes … • Roast …") with hard line
    /// breaks. Line breaks are already joined; this removes the bullet characters.
    override func scrape(_ page: RecipePage) throws -> ScrapedRecipe? {
        guard var recipe = try super.scrape(page) else { return nil }
        recipe.instructions = recipe.instructions.compactMap { step in
            Normalize.text(step.replacingOccurrences(of: "•", with: " "))
        }
        return recipe
    }
}
