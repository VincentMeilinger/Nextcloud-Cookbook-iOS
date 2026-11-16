// RecipeTinEatsScraper.swift
// RecipeScraperKit

import Foundation

/// RecipeTin Eats (WP Recipe Maker).
final class RecipeTinEatsScraper: RecipeScraper {
    override class var hosts: [String] { ["recipetineats.com"] }

    /// WP Recipe Maker with two quirks: an "Abbreviated Recipe" section repeats the
    /// method in one step before the full steps, and ingredients carry note
    /// references in double brackets: "4 chicken thighs ((~250g each) (Note 1))".
    override func scrape(_ page: RecipePage) throws -> ScrapedRecipe? {
        guard var recipe = try super.scrape(page) else { return nil }
        if let object = SchemaOrg.recipeObject(in: page),
           let sections = object["recipeInstructions"] as? [Any] {
            let fullMethod = sections.filter { section in
                let name = Normalize.text((section as? [String: Any])?["name"]) ?? ""
                return !name.localizedCaseInsensitiveContains("abbreviated")
            }
            recipe.instructions = Normalize.instructions(fullMethod)
        }
        recipe.ingredients = recipe.ingredients.map(Self.removingNoteReferences)
        return recipe
    }

    static func removingNoteReferences(_ ingredient: String) -> String {
        var text = ingredient.replacingOccurrences(of: "\\s*\\(Notes? [0-9, &and]+\\)", with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: "((", with: "(").replacingOccurrences(of: "))", with: ")")
        text = text.replacingOccurrences(of: "\\(\\s*\\)", with: "", options: .regularExpression)
        return Normalize.clean(text)
    }
}
