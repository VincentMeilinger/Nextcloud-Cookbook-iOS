// NextcloudCookbookKitTests.swift
// NextcloudCookbookKitTests

import XCTest
@testable import NextcloudCookbookKit

final class NCKModelsTests: XCTestCase {

    // MARK: - NCKRecipe

    func testNCKRecipeDecodingPrefersStringId() throws {
        let json = """
        {
            "recipe_id": 42,
            "id": "42",
            "name": "Pasta",
            "keywords": "italian,quick",
            "dateCreated": "2024-01-01",
            "dateModified": "2024-06-01",
            "imageUrl": "https://example.com/image.jpg",
            "imagePlaceholderUrl": null
        }
        """
        let recipe = try JSONDecoder().decode(NCKRecipe.self, from: Data(json.utf8))
        XCTAssertEqual(recipe.id, "42")
        XCTAssertEqual(recipe.name, "Pasta")
        XCTAssertEqual(recipe.keywords, "italian,quick")
        XCTAssertNil(recipe.imagePlaceholderUrl)
    }

    func testNCKRecipeDecodingFallsBackToLegacyRecipeId() throws {
        // Servers before API 0.1.2 only send the integer recipe_id.
        let json = #"{"recipe_id": 7, "name": "Soup"}"#
        let recipe = try JSONDecoder().decode(NCKRecipe.self, from: Data(json.utf8))
        XCTAssertEqual(recipe.id, "7")
    }

    func testNCKRecipeDecodingWithoutLegacyRecipeId() throws {
        // Once upstream drops recipe_id, only the string id remains.
        let json = #"{"id": "abc", "name": "Soup"}"#
        let recipe = try JSONDecoder().decode(NCKRecipe.self, from: Data(json.utf8))
        XCTAssertEqual(recipe.id, "abc")
    }

    func testNCKRecipeDecodingNumericId() throws {
        let json = #"{"id": 9, "name": "Soup"}"#
        let recipe = try JSONDecoder().decode(NCKRecipe.self, from: Data(json.utf8))
        XCTAssertEqual(recipe.id, "9")
    }

    func testNCKRecipeDecodingWithoutAnyIdFails() {
        let json = #"{"name": "Soup"}"#
        XCTAssertThrowsError(try JSONDecoder().decode(NCKRecipe.self, from: Data(json.utf8)))
    }

    func testNCKRecipeRoundTrip() throws {
        let recipe = NCKRecipe(id: "12", name: "Bread")
        let decoded = try JSONDecoder().decode(NCKRecipe.self, from: JSONEncoder().encode(recipe))
        XCTAssertEqual(decoded, recipe)
    }

    // MARK: - NCKRecipeDetail

    func testNCKRecipeDetailDecoding() throws {
        let json = """
        {
            "name": "Pizza",
            "keywords": "italian",
            "id": "7",
            "description": "Classic pizza",
            "url": "https://example.com",
            "recipeYield": 4,
            "recipeCategory": "Main",
            "tool": ["rolling pin"],
            "recipeIngredient": ["flour", "water"],
            "recipeInstructions": ["Mix", "Bake"],
            "nutrition": {"calories": "200", "fat": 5}
        }
        """
        let detail = try JSONDecoder().decode(NCKRecipeDetail.self, from: Data(json.utf8))
        XCTAssertEqual(detail.name, "Pizza")
        XCTAssertEqual(detail.id, "7")
        XCTAssertEqual(detail.recipeYield, 4)
        XCTAssertEqual(detail.tool, ["rolling pin"])
        XCTAssertEqual(detail.recipeIngredient, ["flour", "water"])
        // numeric nutrition value coerced to String
        XCTAssertEqual(detail.nutrition["fat"], "5")
    }

    // MARK: - NCKCategory

    func testNCKCategoryDecoding() throws {
        let json = #"{"name":"Soups","recipe_count":5}"#
        let cat = try JSONDecoder().decode(NCKCategory.self, from: Data(json.utf8))
        XCTAssertEqual(cat.name, "Soups")
        XCTAssertEqual(cat.recipeCount, 5)
    }

    // MARK: - NCKKeyword

    func testNCKKeywordDecoding() throws {
        let json = #"{"name":"vegan","recipe_count":12}"#
        let kw = try JSONDecoder().decode(NCKKeyword.self, from: Data(json.utf8))
        XCTAssertEqual(kw.name, "vegan")
        XCTAssertEqual(kw.recipeCount, 12)
    }

    // MARK: - Login flow models

    func testNCKLoginV2RequestDecoding() throws {
        let json = """
        {
            "poll": {"token": "abc123", "endpoint": "https://nc.example.com/poll"},
            "login": "https://nc.example.com/login"
        }
        """
        let req = try JSONDecoder().decode(NCKLoginV2Request.self, from: Data(json.utf8))
        XCTAssertEqual(req.poll.token, "abc123")
        XCTAssertEqual(req.login, "https://nc.example.com/login")
    }
}

final class NCKAPIVersionTests: XCTestCase {

    func testOrdering() {
        let v012 = NCKAPIVersion(epoch: 0, major: 1, minor: 2)
        let v013 = NCKAPIVersion(epoch: 0, major: 1, minor: 3)
        let v020 = NCKAPIVersion(epoch: 0, major: 2, minor: 0)
        let v100 = NCKAPIVersion(epoch: 1, major: 0, minor: 0)
        XCTAssertLessThan(v012, v013)
        XCTAssertLessThan(v013, v020)
        XCTAssertLessThan(v020, v100)
        XCTAssertEqual(v013.description, "0.1.3")
    }

    func testParsesCapabilities() {
        let json = """
        {"ocs": {"meta": {"status": "ok"}, "data": {
            "version": {"major": 31},
            "capabilities": {
                "core": {"pollinterval": 60},
                "cookbook": {"api_version": {"epoch": 0, "major": 1, "minor": 3}, "version": [0, 11, 12]}
            }
        }}}
        """
        XCTAssertEqual(
            NCKAPIVersion.fromCapabilities(Data(json.utf8)),
            NCKAPIVersion(epoch: 0, major: 1, minor: 3)
        )
    }

    func testCapabilitiesWithoutCookbook() {
        let json = #"{"ocs": {"meta": {}, "data": {"capabilities": {"core": {}}}}}"#
        XCTAssertNil(NCKAPIVersion.fromCapabilities(Data(json.utf8)))
    }

    func testCapabilitiesAsEmptyPHPArray() {
        let json = #"{"ocs": {"meta": {}, "data": {"capabilities": []}}}"#
        XCTAssertNil(NCKAPIVersion.fromCapabilities(Data(json.utf8)))
    }

    func testParsesLegacyVersionEndpoint() throws {
        let json = #"{"cookbook_version": [0, 10, 5], "api_version": {"epoch": 0, "major": 1, "minor": 2}}"#
        XCTAssertEqual(
            try NCKAPIVersion.fromVersionEndpoint(Data(json.utf8)),
            NCKAPIVersion(epoch: 0, major: 1, minor: 2)
        )
    }
}
