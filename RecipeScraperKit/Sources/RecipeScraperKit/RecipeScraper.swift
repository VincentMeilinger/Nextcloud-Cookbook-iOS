// RecipeScraper.swift
// RecipeScraperKit
//
// Generic recipe scraper. Most recipe sites publish their recipes as schema.org
// "Recipe" data (JSON-LD, sometimes microdata) for search engines; this class
// reads that. Sites with quirks get a subclass in Sites/ that overrides
// `scrape(_:)`, and is picked automatically by the page's domain.

import Foundation
import SwiftSoup

open class RecipeScraper {

    public required init() {}

    /// Domains this scraper is made for, e.g. `["chefkoch.de"]`. Subdomains match
    /// as well (www.chefkoch.de). Empty for the generic scraper.
    open class var hosts: [String] { [] }

    /// Site scrapers, chosen by domain. Add new site scrapers here.
    public static let siteScrapers: [RecipeScraper.Type] = [
        AllrecipesScraper.self,
        BBCFoodScraper.self,
        BBCGoodFoodScraper.self,
        BonAppetitScraper.self,
        BudgetBytesScraper.self,
        ChefkochScraper.self,
        CookieAndKateScraper.self,
        DelishScraper.self,
        EatSmarterScraper.self,
        EpicuriousScraper.self,
        EssenUndTrinkenScraper.self,
        FoobyScraper.self,
        FoodComScraper.self,
        FoodNetworkScraper.self,
        HelloFreshScraper.self,
        JamieOliverScraper.self,
        KitchenStoriesScraper.self,
        LeckerScraper.self,
        MarmitonScraper.self,
        NYTCookingScraper.self,
        RecipeTinEatsScraper.self,
        SeriousEatsScraper.self,
        SimplyRecipesScraper.self,
        SmittenKitchenScraper.self,
        TastyScraper.self,
    ]

    /// The scraper for a URL: the site scraper whose domain matches, otherwise
    /// the generic scraper.
    public static func scraper(for url: URL) -> RecipeScraper {
        let type = siteScraperType(for: url) ?? RecipeScraper.self
        return type.init()
    }

    static func siteScraperType(for url: URL) -> RecipeScraper.Type? {
        guard let host = url.host?.lowercased() else { return nil }
        return siteScrapers.first { scraper in
            scraper.hosts.contains { host == $0 || host.hasSuffix("." + $0) }
        }
    }

    /// Downloads `url` and reads the recipe on it.
    public static func scrape(url: URL, session: URLSession = .shared) async throws -> ScrapedRecipe {
        guard let scheme = url.scheme?.lowercased(), ["http", "https"].contains(scheme), url.host != nil else {
            throw RecipeScraperError.invalidURL
        }
        let page = try await RecipePage.download(url, session: session)
        // Choose by the final address: some sites redirect (e.g. by country).
        let scraper = scraper(for: page.url)
        guard let recipe = try scraper.scrape(page), recipe.isUsable else {
            throw RecipeScraperError.noRecipeFound
        }
        return recipe
    }

    /// Reads the recipe from a downloaded page, or returns nil if there is none.
    ///
    /// The default implementation reads schema.org JSON-LD, then microdata, and
    /// falls back to the page's preview image. Site scrapers override this,
    /// usually calling `super.scrape(page)` and then fixing what the site gets wrong.
    open func scrape(_ page: RecipePage) throws -> ScrapedRecipe? {
        guard var recipe = SchemaOrg.recipeFromJSONLD(in: page) ?? SchemaOrg.recipeFromMicrodata(in: page) else {
            return nil
        }
        if recipe.sourceURL == nil { recipe.sourceURL = page.url }
        if recipe.totalTime == nil, recipe.prepTime != nil || recipe.cookTime != nil {
            recipe.totalTime = (recipe.prepTime ?? 0) + (recipe.cookTime ?? 0)
        }
        if recipe.imageURL == nil, let image = page.meta("og:image") {
            recipe.imageURL = URL(string: image, relativeTo: page.url)?.absoluteURL
        }
        return recipe
    }
}
