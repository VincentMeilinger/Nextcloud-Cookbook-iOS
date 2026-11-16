// SmittenKitchenScraper.swift
// RecipeScraperKit

import Foundation

/// Smitten Kitchen.
final class SmittenKitchenScraper: RecipeScraper {
    override class var hosts: [String] { ["smittenkitchen.com"] }

    /// Uses the WordPress Jetpack recipe block. Name, ingredients, yield and time
    /// come from its microdata; the directions have none, so they are read here:
    /// the text before the first paragraph plus each paragraph, up to "Notes:".
    override func scrape(_ page: RecipePage) throws -> ScrapedRecipe? {
        guard var recipe = try super.scrape(page) else { return nil }
        if let directions = try page.document.select(".jetpack-recipe-directions").first() {
            var steps = [Normalize.text(directions.ownText())].compactMap { $0 }
            for paragraph in try directions.select("p").array() {
                guard let text = Normalize.text(try paragraph.text()) else { continue }
                if text.lowercased().hasPrefix("notes") { break }
                steps.append(text)
            }
            recipe.instructions = steps
        }
        if recipe.description.isEmpty, let notes = try page.document.select(".jetpack-recipe-notes").first() {
            recipe.description = Normalize.text(try notes.text()) ?? ""
        }
        return recipe
    }
}
