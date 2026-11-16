//
//  RecipeScraper.swift
//  Nextcloud Cookbook iOS Client
//
//  Imports a recipe from a website on the device, using RecipeScraperKit (a site
//  scraper chosen by the URL's domain, or the generic schema.org scraper).
//

import Foundation
import RecipeScraperKit


enum WebRecipeImport {

    /// Downloads the page at `urlString` and returns its recipe, or an alert
    /// explaining why that wasn't possible.
    static func importRecipe(from urlString: String) async -> (RecipeDetail?, RecipeImportAlert?) {
        var text = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.contains("://") { text = "https://" + text }
        guard let url = URL(string: text), url.host != nil else {
            return (nil, .BAD_URL)
        }
        do {
            let recipe = try await RecipeScraperKit.RecipeScraper.scrape(url: url)
            return (recipe.toRecipeDetail(fallbackURL: url), nil)
        } catch RecipeScraperError.invalidURL {
            return (nil, .BAD_URL)
        } catch RecipeScraperError.network, RecipeScraperError.httpStatus {
            return (nil, .CHECK_CONNECTION)
        } catch {
            return (nil, .WEBSITE_NOT_SUPPORTED)
        }
    }
}


extension ScrapedRecipe {
    func toRecipeDetail(fallbackURL: URL) -> RecipeDetail {
        RecipeDetail(
            name: name,
            keywords: keywords.joined(separator: ","),
            dateCreated: "",
            dateModified: "",
            image: imageURL?.absoluteString ?? "",
            imageUrl: "",
            id: nil,
            externalSourceId: nil,
            prepTime: Self.iso8601(minutes: prepTime),
            cookTime: Self.iso8601(minutes: cookTime),
            totalTime: Self.iso8601(minutes: totalTime),
            description: description,
            url: (sourceURL ?? fallbackURL).absoluteString,
            recipeYield: servings ?? 1,
            recipeCategory: category ?? "",
            tool: tools,
            recipeIngredient: ingredients,
            recipeInstructions: instructions,
            nutrition: nutrition
        )
    }

    /// Recipe times are ISO 8601 durations, e.g. "PT01H30M00S".
    private static func iso8601(minutes: Int?) -> String? {
        guard let minutes, minutes > 0 else { return nil }
        return String(format: "PT%02dH%02dM00S", minutes / 60, minutes % 60)
    }
}
