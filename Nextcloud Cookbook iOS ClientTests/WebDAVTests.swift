//
//  WebDAVTests.swift
//  Nextcloud Cookbook iOS ClientTests
//
//  Created by Kofi Mandel on 29.10.26.
//

import XCTest
@testable import Nextcloud_Cookbook_iOS_Client

final class WebDAVTests: XCTestCase {

    // MARK: - PROPFIND parsing

    func testParsesNextcloudMultiStatus() throws {
        let rootURL = try XCTUnwrap(URL(string: "https://cloud.example.com/remote.php/dav/files/alice/Recipes/"))
        let xml = """
            <?xml version="1.0"?>
            <d:multistatus xmlns:d="DAV:" xmlns:s="http://sabredav.org/ns" xmlns:oc="http://owncloud.org/ns">
              <d:response>
                <d:href>/remote.php/dav/files/alice/Recipes/</d:href>
                <d:propstat><d:prop>
                  <d:resourcetype><d:collection/></d:resourcetype>
                  <d:getetag>"root"</d:getetag>
                  <d:getlastmodified>Sun, 05 May 2024 10:33:33 GMT</d:getlastmodified>
                  <oc:fileid>100</oc:fileid>
                </d:prop><d:status>HTTP/1.1 200 OK</d:status></d:propstat>
              </d:response>
              <d:response>
                <d:href>/remote.php/dav/files/alice/Recipes/Mac%20%26%20Cheese/</d:href>
                <d:propstat><d:prop>
                  <d:resourcetype><d:collection/></d:resourcetype>
                  <d:getetag>"6637a1"</d:getetag>
                  <d:getlastmodified>Sun, 05 May 2024 10:33:33 GMT</d:getlastmodified>
                  <oc:fileid>1234</oc:fileid>
                </d:prop><d:status>HTTP/1.1 200 OK</d:status></d:propstat>
              </d:response>
              <d:response>
                <d:href>/remote.php/dav/files/alice/Recipes/Pancakes/</d:href>
                <d:propstat><d:prop>
                  <d:resourcetype><d:collection/></d:resourcetype>
                  <d:getetag>"6637a2"</d:getetag>
                  <oc:fileid>1235</oc:fileid>
                </d:prop><d:status>HTTP/1.1 200 OK</d:status></d:propstat>
              </d:response>
            </d:multistatus>
            """
        let resources = WebDAVMultiStatusParser.parse(Data(xml.utf8), baseURL: rootURL)
        XCTAssertEqual(resources.count, 3)

        let folders = WebDAVRecipeStore.recipeFolders(in: resources, rootURL: rootURL)
        XCTAssertEqual(folders.map(\.name), ["Mac & Cheese", "Pancakes"])
        XCTAssertEqual(folders.map(\.fileId), [1234, 1235])
        XCTAssertEqual(folders.map { WebDAVRecipeStore.recipeId(for: $0) }, [1234, 1235])
        XCTAssertEqual(folders[0].etag, "\"6637a1\"")
        XCTAssertEqual(folders[0].lastModified, Date(timeIntervalSince1970: 1714905213))
        XCTAssertEqual(folders[0].url.absoluteString, "https://cloud.example.com/remote.php/dav/files/alice/Recipes/Mac%20%26%20Cheese/")
    }

    func testParsesGenericMultiStatus() throws {
        let rootURL = try XCTUnwrap(URL(string: "http://127.0.0.1:8080/cookbook/"))
        // Default namespace, full URLs as hrefs, a file next to the recipe folders and no file ids
        let xml = """
            <?xml version="1.0" encoding="utf-8"?>
            <multistatus xmlns="DAV:">
              <response>
                <href>http://127.0.0.1:8080/cookbook</href>
                <propstat><prop><resourcetype><collection/></resourcetype></prop><status>HTTP/1.1 200 OK</status></propstat>
              </response>
              <response>
                <href>http://127.0.0.1:8080/cookbook/K%C3%A4sesp%C3%A4tzle/</href>
                <propstat><prop>
                  <resourcetype><collection/></resourcetype>
                  <getetag>W/"abc"</getetag>
                </prop><status>HTTP/1.1 200 OK</status></propstat>
                <propstat><prop><fileid xmlns="http://owncloud.org/ns"/></prop><status>HTTP/1.1 404 Not Found</status></propstat>
              </response>
              <response>
                <href>http://127.0.0.1:8080/cookbook/notes.txt</href>
                <propstat><prop><resourcetype/></prop><status>HTTP/1.1 200 OK</status></propstat>
              </response>
              <response>
                <href>http://127.0.0.1:8080/cookbook/.trash/</href>
                <propstat><prop><resourcetype><collection/></resourcetype></prop><status>HTTP/1.1 200 OK</status></propstat>
              </response>
            </multistatus>
            """
        let resources = WebDAVMultiStatusParser.parse(Data(xml.utf8), baseURL: rootURL)
        XCTAssertEqual(resources.count, 4)
        XCTAssertFalse(resources[2].isCollection)

        let folders = WebDAVRecipeStore.recipeFolders(in: resources, rootURL: rootURL)
        XCTAssertEqual(folders.map(\.name), ["Käsespätzle"])
        XCTAssertNil(folders[0].fileId)
        XCTAssertEqual(folders[0].etag, "W/\"abc\"")
        XCTAssertEqual(WebDAVRecipeStore.recipeId(for: folders[0]), WebDAVRecipeStore.stableId(forFolderNamed: "Käsespätzle"))
    }


    // MARK: - Recipe ids and folder names

    func testStableIdIsFNV1a() {
        XCTAssertEqual(WebDAVRecipeStore.stableId(forFolderNamed: "a"), 1086646154030220)
        XCTAssertEqual(WebDAVRecipeStore.stableId(forFolderNamed: "Pancakes"), 5306124846574161)
        // Composed and decomposed umlauts result in the same id
        XCTAssertEqual(
            WebDAVRecipeStore.stableId(forFolderNamed: "K\u{00E4}se"),
            WebDAVRecipeStore.stableId(forFolderNamed: "Ka\u{0308}se")
        )
    }

    func testFolderNames() {
        XCTAssertEqual(CookbookApiWebDAV.folderName(for: "  Pan/cakes\\ "), "Pancakes")
        XCTAssertEqual(CookbookApiWebDAV.folderName(for: "..hidden"), "hidden")
        XCTAssertEqual(CookbookApiWebDAV.folderName(for: "Tab\tbed"), "Tabbed")
        XCTAssertEqual(CookbookApiWebDAV.folderName(for: " / "), "Recipe")
        XCTAssertEqual(CookbookApiWebDAV.folderName(for: "Pancakes", attempt: 2), "Pancakes (2)")
    }

    func testFolderURLEncoding() throws {
        let rootURL = try XCTUnwrap(WebDAVClient.rootURL(from: "https://example.com/dav/My Recipes"))
        XCTAssertEqual(rootURL.absoluteString, "https://example.com/dav/My%20Recipes/")

        let client = WebDAVClient(rootURL: rootURL, authString: "")
        let folderURL = client.folderURL(named: "What? #1 & more")
        XCTAssertEqual(folderURL.lastPathComponent, "What? #1 & more")
        XCTAssertNil(folderURL.query)
        XCTAssertNil(folderURL.fragment)
        XCTAssertTrue(folderURL.absoluteString.hasPrefix("https://example.com/dav/My%20Recipes/What"))
        XCTAssertTrue(folderURL.absoluteString.hasSuffix("/"))
    }


    // MARK: - recipe.json mapping

    func testParsesCookbookRecipe() throws {
        let json = """
            {"id":"98","name":"Pancakes","description":"Fluffy","url":"https://example.com/pancakes",
             "image":"https://example.com/pancakes.jpg","prepTime":"PT0H10M0S","cookTime":"PT0H20M0S","totalTime":"PT0H30M0S",
             "recipeCategory":"Breakfast","keywords":"sweet,quick","recipeYield":4,"tool":["Pan"],
             "recipeIngredient":["2 eggs","200 g flour"],"recipeInstructions":["Mix","Fry"],
             "nutrition":{"@type":"NutritionInformation","calories":"350 kcal"},
             "@context":"http://schema.org","@type":"Recipe","dateModified":"2024-05-05T10:33:33+0000","dateCreated":"2024-01-01T00:00:00+0000"}
            """
        let dict = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any])
        let recipe = RecipeDetail(schemaDict: dict, id: 1234)

        XCTAssertEqual(recipe.id, "1234")
        XCTAssertEqual(recipe.name, "Pancakes")
        XCTAssertEqual(recipe.description, "Fluffy")
        XCTAssertEqual(recipe.url, "https://example.com/pancakes")
        XCTAssertEqual(recipe.prepTime, "PT0H10M0S")
        XCTAssertEqual(recipe.recipeCategory, "Breakfast")
        XCTAssertEqual(recipe.keywords, "sweet,quick")
        XCTAssertEqual(recipe.recipeYield, 4)
        XCTAssertEqual(recipe.tool, ["Pan"])
        XCTAssertEqual(recipe.recipeIngredient, ["2 eggs", "200 g flour"])
        XCTAssertEqual(recipe.recipeInstructions, ["Mix", "Fry"])
        XCTAssertEqual(recipe.nutrition["calories"], "350 kcal")
        XCTAssertEqual(recipe.dateCreated, "2024-01-01T00:00:00+0000")
    }

    func testParsesLooselyTypedRecipe() {
        let dict: [String: Any] = [
            "name": "Stew",
            "keywords": ["hearty", " winter "],
            "recipeYield": "6 servings",
            "recipeCategory": ["Dinner", "Main"],
            "tool": "Pot",
            "recipeIngredient": "1 onion",
            "recipeInstructions": [
                ["@type": "HowToSection", "name": "Prep", "itemListElement": [
                    ["@type": "HowToStep", "text": "Chop"],
                    ["@type": "HowToStep", "text": "Peel"]
                ]],
                ["@type": "HowToStep", "text": "Cook"],
                "Serve"
            ],
            "nutrition": ["calories": 420, "fatContent": "12 g"]
        ]
        let recipe = RecipeDetail(schemaDict: dict, id: 7)

        XCTAssertEqual(recipe.keywords, "hearty,winter")
        XCTAssertEqual(recipe.recipeYield, 6)
        XCTAssertEqual(recipe.recipeCategory, "Dinner")
        XCTAssertEqual(recipe.tool, ["Pot"])
        XCTAssertEqual(recipe.recipeIngredient, ["1 onion"])
        XCTAssertEqual(recipe.recipeInstructions, ["Chop", "Peel", "Cook", "Serve"])
        XCTAssertEqual(recipe.nutrition["calories"], "420")
        XCTAssertEqual(recipe.nutrition["fatContent"], "12 g")
        XCTAssertEqual(recipe.url, "")
        XCTAssertEqual(recipe.description, "")
    }

    func testMergeKeepsUnknownFields() {
        let existing: [String: Any] = [
            "@context": "http://schema.org",
            "@type": "Recipe",
            "id": "98",
            "name": "Old name",
            "image": "https://example.com/pancakes.jpg",
            "imageUrl": "/apps/cookbook/recipes/98/image?size=full",
            "printImage": true,
            "custom": ["a": 1],
            "dateCreated": "2024-01-01T00:00:00+0000"
        ]
        var recipe = RecipeDetail()
        recipe.id = "1234"
        recipe.name = "New name"
        recipe.recipeYield = 2
        recipe.recipeIngredient = ["1 egg"]
        recipe.nutrition = ["calories": "100 kcal"]
        let now = Date(timeIntervalSince1970: 1714905213)

        let json = CookbookApiWebDAV.mergedRecipeJSON(existing: existing, recipe: recipe, now: now)

        XCTAssertEqual(json["name"] as? String, "New name")
        XCTAssertEqual(json["recipeYield"] as? Int, 2)
        XCTAssertEqual(json["recipeIngredient"] as? [String], ["1 egg"])
        XCTAssertEqual(json["id"] as? String, "98")
        XCTAssertEqual(json["image"] as? String, "https://example.com/pancakes.jpg")
        XCTAssertEqual(json["imageUrl"] as? String, "/apps/cookbook/recipes/98/image?size=full")
        XCTAssertEqual(json["printImage"] as? Bool, true)
        XCTAssertNotNil(json["custom"])
        XCTAssertEqual(json["dateCreated"] as? String, "2024-01-01T00:00:00+0000")
        XCTAssertEqual(json["dateModified"] as? String, "2024-05-05T10:33:33Z")
        let nutrition = json["nutrition"] as? [String: Any]
        XCTAssertEqual(nutrition?["@type"] as? String, "NutritionInformation")
        XCTAssertEqual(nutrition?["calories"] as? String, "100 kcal")

        // Encodes to valid JSON, which parses back into the same recipe
        let data = CookbookApiWebDAV.recipeJSON(existing: existing, recipe: recipe, now: now)
        XCTAssertNotNil(data)
        let reparsed = data.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
        XCTAssertEqual(reparsed.map { RecipeDetail(schemaDict: $0, id: 1234).name }, "New name")
    }

    func testMergeNewRecipe() {
        var recipe = RecipeDetail()
        recipe.name = "Soup"
        let json = CookbookApiWebDAV.mergedRecipeJSON(existing: nil, recipe: recipe, now: Date(timeIntervalSince1970: 0))

        XCTAssertEqual(json["@context"] as? String, "http://schema.org")
        XCTAssertEqual(json["@type"] as? String, "Recipe")
        XCTAssertEqual(json["dateCreated"] as? String, "1970-01-01T00:00:00Z")
        XCTAssertEqual(json["dateModified"] as? String, "1970-01-01T00:00:00Z")
        XCTAssertNil(json["id"])
    }


    // MARK: - Categories and keywords

    func testCategoriesAndKeywords() {
        func recipe(_ category: String, _ keywords: String) -> RecipeDetail {
            var recipe = RecipeDetail()
            recipe.recipeCategory = category
            recipe.keywords = keywords
            return recipe
        }
        let recipes = [
            recipe("dinner", "quick, cheap"),
            recipe("", "quick"),
            recipe(" Breakfast ", ""),
            recipe("dinner", "quick,quick")
        ]

        let categories = CookbookApiWebDAV.categories(recipes)
        XCTAssertEqual(categories.map(\.name), ["Breakfast", "dinner", "*"])
        XCTAssertEqual(categories.map(\.recipe_count), [1, 2, 1])

        let keywords = CookbookApiWebDAV.keywords(recipes)
        XCTAssertEqual(keywords.map(\.name), ["cheap", "quick"])
        XCTAssertEqual(keywords.map(\.recipe_count), [1, 3])
    }
}
