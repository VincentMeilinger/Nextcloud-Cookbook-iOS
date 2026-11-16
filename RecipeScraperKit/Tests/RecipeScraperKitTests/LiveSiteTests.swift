// LiveSiteTests.swift
// Downloads one real recipe per supported site and checks the result. These
// tests need internet access; sites change their pages over time, so a failure
// here usually means a site scraper needs an update.
//
// Skip them with: SKIP_LIVE_SCRAPER_TESTS=1 swift test

import XCTest
@testable import RecipeScraperKit

final class LiveSiteTests: XCTestCase {

    override func setUpWithError() throws {
        try XCTSkipIf(ProcessInfo.processInfo.environment["SKIP_LIVE_SCRAPER_TESTS"] == "1", "Live site tests disabled")
    }

    /// Scrapes `url`, checks that `scraper` handled it and that the recipe looks complete.
    private func check(
        _ url: String,
        scraper: RecipeScraper.Type,
        minIngredients: Int = 3,
        minSteps: Int = 2,
        expectServings: Bool = true,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let pageURL = try XCTUnwrap(URL(string: url))
        let recipe: ScrapedRecipe
        do {
            recipe = try await RecipeScraper.scrape(url: pageURL)
        } catch RecipeScraperError.network(let message) {
            throw XCTSkip("Network unavailable: \(message)")
        }

        let page = try await RecipePage.download(pageURL)
        XCTAssertTrue(type(of: RecipeScraper.scraper(for: page.url)) == scraper,
                      "Expected \(scraper) for \(page.url)", file: file, line: line)

        XCTAssertFalse(recipe.name.isEmpty, "name", file: file, line: line)
        XCTAssertGreaterThanOrEqual(recipe.ingredients.count, minIngredients, "ingredients", file: file, line: line)
        XCTAssertGreaterThanOrEqual(recipe.instructions.count, minSteps, "instructions", file: file, line: line)
        XCTAssertNotNil(recipe.imageURL, "image", file: file, line: line)
        if expectServings {
            XCTAssertNotNil(recipe.servings, "servings", file: file, line: line)
        }
        let texts = [recipe.name, recipe.description] + recipe.ingredients + recipe.instructions
        for text in texts {
            XCTAssertNil(text.range(of: "<[a-zA-Z/][^>]*>", options: .regularExpression), "HTML left in: \(text)", file: file, line: line)
            XCTAssertNil(text.range(of: "&(#[0-9]+|[a-z]+);", options: .regularExpression), "Entity left in: \(text)", file: file, line: line)
            XCTAssertFalse(text.contains("\n"), "Line break left in: \(text)", file: file, line: line)
        }

        print("""
        ✅ \(scraper): \(recipe.name)
           servings=\(recipe.servings.map(String.init) ?? "-") prep/cook/total=\(recipe.prepTime ?? 0)/\(recipe.cookTime ?? 0)/\(recipe.totalTime ?? 0) min \
        category=\(recipe.category ?? "-") keywords=\(recipe.keywords.count) nutrition=\(recipe.nutrition.count)
           \(recipe.ingredients.count) ingredients, first: \(recipe.ingredients.first ?? "")
           \(recipe.instructions.count) steps, first: \(String((recipe.instructions.first ?? "").prefix(90)))
        """)
    }

    func testAllrecipes() async throws {
        try await check("https://www.allrecipes.com/recipe/234620/mascarpone-mashed-potatoes/", scraper: AllrecipesScraper.self)
    }
    func testBBCFood() async throws {
        try await check("https://www.bbc.co.uk/food/recipes/easy_chocolate_cake_31070", scraper: BBCFoodScraper.self)
    }
    func testBBCGoodFood() async throws {
        try await check("https://www.bbcgoodfood.com/recipes/easy-pancakes", scraper: BBCGoodFoodScraper.self)
    }
    func testBonAppetit() async throws {
        try await check("https://www.bonappetit.com/recipe/bas-best-chocolate-chip-cookies", scraper: BonAppetitScraper.self)
    }
    func testBudgetBytes() async throws {
        try await check("https://www.budgetbytes.com/one-pot-creamy-cajun-chicken-pasta/", scraper: BudgetBytesScraper.self)
    }
    func testChefkoch() async throws {
        try await check("https://www.chefkoch.de/rezepte/1385981243676608/Knusprige-Entenbrust.html", scraper: ChefkochScraper.self)
    }
    func testCookieAndKate() async throws {
        try await check("https://cookieandkate.com/best-lentil-soup-recipe/", scraper: CookieAndKateScraper.self)
    }
    func testDelish() async throws {
        try await check("https://www.delish.com/cooking/recipe-ideas/a20157382/best-creamy-grape-salad-recipe/", scraper: DelishScraper.self)
    }
    func testEatSmarter() async throws {
        try await check("https://eatsmarter.de/rezepte/blumenkohlsuppe-mit-curry", scraper: EatSmarterScraper.self)
    }
    func testEpicurious() async throws {
        try await check("https://www.epicurious.com/recipes/food/views/our-favorite-chocolate-chip-cookies", scraper: EpicuriousScraper.self)
    }
    func testEssenUndTrinken() async throws {
        try await check("https://www.essen-und-trinken.de/rezepte/44236-rzpt-kuerbis-lasagne", scraper: EssenUndTrinkenScraper.self)
    }
    func testFooby() async throws {
        try await check("https://fooby.ch/de/rezepte/14229/lasagne-al-forno", scraper: FoobyScraper.self)
    }
    func testFoodCom() async throws {
        try await check("https://www.food.com/recipe/best-banana-bread-2886", scraper: FoodComScraper.self)
    }
    func testFoodNetwork() async throws {
        try await check("https://foodnetwork.co.uk/recipes/andrew-wongs-har-gao-prawn-dumplings", scraper: FoodNetworkScraper.self)
    }
    func testHelloFresh() async throws {
        try await check("https://www.hellofresh.com/recipes/beef-with-cheddar-gouda-fondue-61f051cc17c4db690168e112", scraper: HelloFreshScraper.self)
    }
    func testJamieOliver() async throws {
        try await check("https://www.jamieoliver.com/recipes/pasta/beautiful-courgette-carbonara/", scraper: JamieOliverScraper.self)
    }
    func testKitchenStories() async throws {
        try await check("https://www.kitchenstories.com/lauchpuffer/154857", scraper: KitchenStoriesScraper.self)
    }
    func testLecker() async throws {
        try await check("https://www.lecker.de/apfel-crumble-15969.html", scraper: LeckerScraper.self)
    }
    func testMarmiton() async throws {
        try await check("https://www.marmiton.org/recettes/recette_crepes-faciles_12372.aspx", scraper: MarmitonScraper.self)
    }
    func testNYTCooking() async throws {
        try await check("https://cooking.nytimes.com/recipes/1015819-chocolate-chip-cookies", scraper: NYTCookingScraper.self)
    }
    func testRecipeTinEats() async throws {
        try await check("https://www.recipetineats.com/chicken-chasseur/", scraper: RecipeTinEatsScraper.self)
    }
    func testSeriousEats() async throws {
        try await check("https://www.seriouseats.com/the-food-lab-best-chocolate-chip-cookie-recipe", scraper: SeriousEatsScraper.self)
    }
    func testSimplyRecipes() async throws {
        try await check("https://www.simplyrecipes.com/recipes/homemade_pizza/", scraper: SimplyRecipesScraper.self)
    }
    func testSmittenKitchen() async throws {
        try await check("https://smittenkitchen.com/2016/10/pumpkin-bread/", scraper: SmittenKitchenScraper.self)
    }
    func testTasty() async throws {
        try await check("https://tasty.co/recipe/the-best-chewy-chocolate-chip-cookies", scraper: TastyScraper.self)
    }

    /// Sites without their own scraper go through the generic one.
    func testAmericasTestKitchenUsesGenericScraper() async throws {
        try await check("https://www.americastestkitchen.com/recipes/11534-classic-sloppy-joes", scraper: RecipeScraper.self)
    }

    func testUnknownSiteUsesGenericScraper() async throws {
        try await check("https://www.loveandlemons.com/dinner-rolls-recipe/", scraper: RecipeScraper.self, minSteps: 1, expectServings: false)
    }
}
