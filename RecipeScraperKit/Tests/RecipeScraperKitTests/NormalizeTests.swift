// NormalizeTests.swift
// Offline tests for value normalisation, JSON-LD/microdata reading and scraper selection.

import XCTest
@testable import RecipeScraperKit

final class NormalizeTests: XCTestCase {

    // MARK: Times

    func testISODurations() {
        XCTAssertEqual(Normalize.minutes("PT1H30M"), 90)
        XCTAssertEqual(Normalize.minutes("P0DT1H30M0S"), 90)
        XCTAssertEqual(Normalize.minutes("PT120M"), 120)
        XCTAssertEqual(Normalize.minutes("PT45M30S"), 46)
        XCTAssertEqual(Normalize.minutes("P1D"), 1440)
        XCTAssertNil(Normalize.minutes("PT0S"))
        XCTAssertNil(Normalize.minutes(nil))
    }

    func testTextDurations() {
        XCTAssertEqual(Normalize.minutes("20 minutes"), 20)
        XCTAssertEqual(Normalize.minutes("1 hour 20 minutes"), 80)
        XCTAssertEqual(Normalize.minutes("1 hr 5 mins"), 65)
        XCTAssertEqual(Normalize.minutes("1 Std. 10 Min."), 70)
        XCTAssertEqual(Normalize.minutes("1.5 hours"), 90)
        XCTAssertEqual(Normalize.minutes("35"), 35)
    }

    // MARK: Servings

    func testServings() {
        XCTAssertEqual(Normalize.servings(4), 4)
        XCTAssertEqual(Normalize.servings("Serves 12"), 12)
        XCTAssertEqual(Normalize.servings("Makes 16"), 16)
        XCTAssertEqual(Normalize.servings("1 loaf, 10 serving(s)"), 10)
        XCTAssertEqual(Normalize.servings(["8", "1 9x13-inch dish"]), 8)
        XCTAssertEqual(Normalize.servings(["1", "1 Portionen"]), 1)
        XCTAssertEqual(Normalize.servings("4 Portionen"), 4)
        XCTAssertNil(Normalize.servings("a few"))
    }

    // MARK: Text

    func testCleanRemovesHTMLAndEntities() {
        XCTAssertEqual(Normalize.clean("Salt &amp; pepper"), "Salt & pepper")
        XCTAssertEqual(Normalize.clean("Don&amp;#39;t <b>stir</b>\n  too   much"), "Don't stir too much")
        XCTAssertEqual(Normalize.clean("200&nbsp;g flour"), "200 g flour")
    }

    func testKeywordsAndCategory() {
        XCTAssertEqual(Normalize.keywords("pasta, quick ,Pasta, ,dinner"), ["pasta", "quick", "dinner"])
        XCTAssertEqual(Normalize.keywords(["vegan", "Vegan", "easy"]), ["vegan", "easy"])
        XCTAssertEqual(Normalize.category(["Dinner", "Side Dish"]), "Dinner")
        XCTAssertEqual(Normalize.category("Breakfast, Brunch"), "Breakfast")
    }

    func testImageURL() {
        let base = URL(string: "https://example.com/recipes/1")!
        XCTAssertEqual(Normalize.imageURL("https://img.example.com/a.jpg", base: base)?.absoluteString, "https://img.example.com/a.jpg")
        XCTAssertEqual(Normalize.imageURL(["/a.jpg", "/b.jpg"], base: base)?.absoluteString, "https://example.com/a.jpg")
        XCTAssertEqual(Normalize.imageURL(["@type": "ImageObject", "url": "https://x.org/c.jpg"], base: base)?.absoluteString, "https://x.org/c.jpg")
        XCTAssertEqual(Normalize.imageURL([["url": "https://x.org/d.jpg"]], base: base)?.absoluteString, "https://x.org/d.jpg")
    }

    // MARK: Instructions

    func testInstructionShapes() {
        XCTAssertEqual(Normalize.instructions("Mix.\nBake.\n\nServe."), ["Mix.", "Bake.", "Serve."])
        XCTAssertEqual(Normalize.instructions("<ol><li>Mix.</li><li>Bake &amp; serve.</li></ol>"), ["Mix.", "Bake & serve."])
        XCTAssertEqual(Normalize.instructions(["Mix.", "Bake."]), ["Mix.", "Bake."])
        XCTAssertEqual(Normalize.instructions([
            ["@type": "HowToStep", "text": "Mix."],
            ["@type": "HowToStep", "name": "Bake."],
        ]), ["Mix.", "Bake."])
    }

    func testInstructionSectionsGetBoldNames() {
        let sections: [Any] = [
            ["@type": "HowToSection", "name": "Dough", "itemListElement": [
                ["@type": "HowToStep", "text": "Knead."],
                ["@type": "HowToStep", "text": "Rest."],
            ]],
            ["@type": "HowToSection", "name": "Sauce", "itemListElement": [
                ["@type": "HowToStep", "text": "Simmer."],
            ]],
        ]
        XCTAssertEqual(Normalize.instructions(sections), ["**Dough:** Knead.", "Rest.", "**Sauce:** Simmer."])
        // A single unnamed section is just a list of steps.
        XCTAssertEqual(Normalize.instructions([["@type": "HowToSection", "itemListElement": [["text": "Go."]]]]), ["Go."])
    }

    // MARK: Pages

    func testJSONLDInGraph() throws {
        let html = """
        <html><head><script type="application/ld+json">
        {"@context":"https://schema.org","@graph":[
          {"@type":"WebPage","name":"Page"},
          {"@type":["Recipe","NewsArticle"],"name":"Test Soup","recipeYield":["4","4 servings"],
           "recipeIngredient":["1 onion","2 carrots"],"recipeInstructions":[{"@type":"HowToStep","text":"Cook."}],
           "totalTime":"PT30M","image":{"@type":"ImageObject","url":"/soup.jpg"},
           "nutrition":{"@type":"NutritionInformation","calories":"200 kcal","foo":"bar"}}
        ]}
        </script></head><body></body></html>
        """
        let page = try RecipePage(url: URL(string: "https://example.com/soup")!, html: html)
        let recipe = try XCTUnwrap(RecipeScraper().scrape(page))
        XCTAssertEqual(recipe.name, "Test Soup")
        XCTAssertEqual(recipe.servings, 4)
        XCTAssertEqual(recipe.ingredients, ["1 onion", "2 carrots"])
        XCTAssertEqual(recipe.instructions, ["Cook."])
        XCTAssertEqual(recipe.totalTime, 30)
        XCTAssertEqual(recipe.imageURL?.absoluteString, "https://example.com/soup.jpg")
        XCTAssertEqual(recipe.nutrition, ["calories": "200 kcal"])
        XCTAssertEqual(recipe.sourceURL?.absoluteString, "https://example.com/soup")
    }

    func testInvalidJSONWithRawLineBreaksIsRepaired() throws {
        let html = "<script type=\"application/ld+json\">{\"@type\":\"Recipe\",\"name\":\"Line\nBreak\",\"recipeIngredient\":[\"x\"]}</script>"
        let page = try RecipePage(url: URL(string: "https://example.com")!, html: html)
        XCTAssertEqual(try RecipeScraper().scrape(page)?.name, "Line Break")
    }

    func testMicrodataFallback() throws {
        let html = """
        <div itemscope itemtype="https://schema.org/Recipe">
          <h1 itemprop="name">Bread</h1>
          <span itemprop="recipeYield">Servings: 8</span>
          <time itemprop="totalTime" datetime="P0DT1H30M0S">1 hour 30</time>
          <ul><li itemprop="recipeIngredient">Flour</li><li itemprop="recipeIngredient">Water</li></ul>
          <div itemprop="recipeInstructions"><p>Mix.</p><p>Bake.</p></div>
        </div>
        """
        let page = try RecipePage(url: URL(string: "https://example.com/bread")!, html: html)
        let recipe = try XCTUnwrap(RecipeScraper().scrape(page))
        XCTAssertEqual(recipe.name, "Bread")
        XCTAssertEqual(recipe.servings, 8)
        XCTAssertEqual(recipe.totalTime, 90)
        XCTAssertEqual(recipe.ingredients, ["Flour", "Water"])
        XCTAssertEqual(recipe.instructions, ["Mix.", "Bake."])
    }

    func testPageWithoutRecipe() throws {
        let page = try RecipePage(url: URL(string: "https://example.com")!, html: "<html><body>Hello</body></html>")
        XCTAssertNil(try RecipeScraper().scrape(page))
    }

    // MARK: Scraper selection

    func testScraperSelectionByDomain() {
        func type(_ url: String) -> String {
            String(describing: Swift.type(of: RecipeScraper.scraper(for: URL(string: url)!)))
        }
        XCTAssertEqual(type("https://www.chefkoch.de/rezepte/1/x.html"), "ChefkochScraper")
        XCTAssertEqual(type("https://chefkoch.de/rezepte/1/x.html"), "ChefkochScraper")
        XCTAssertEqual(type("https://www.hellofresh.de/recipes/x"), "HelloFreshScraper")
        XCTAssertEqual(type("https://foodnetwork.co.uk/recipes/x"), "FoodNetworkScraper")
        XCTAssertEqual(type("https://cooking.nytimes.com/recipes/1"), "NYTCookingScraper")
        // Unknown sites and look-alike domains use the generic scraper.
        XCTAssertEqual(type("https://www.nytimes.com/2024/article"), "RecipeScraper")
        XCTAssertEqual(type("https://notchefkoch.de/x"), "RecipeScraper")
        XCTAssertEqual(type("https://example.com/recipe"), "RecipeScraper")
    }

    func testEverySiteScraperHasDistinctDomains() {
        let hosts = RecipeScraper.siteScrapers.flatMap(\.hosts)
        XCTAssertEqual(hosts.count, Set(hosts).count, "A domain is claimed by two site scrapers")
        XCTAssertFalse(RecipeScraper.siteScrapers.contains { $0.hosts.isEmpty })
    }

    func testInvalidURL() async {
        do {
            _ = try await RecipeScraper.scrape(url: URL(string: "mailto:chef@example.com")!)
            XCTFail("Expected invalidURL")
        } catch {
            XCTAssertEqual(error as? RecipeScraperError, .invalidURL)
        }
    }
}
