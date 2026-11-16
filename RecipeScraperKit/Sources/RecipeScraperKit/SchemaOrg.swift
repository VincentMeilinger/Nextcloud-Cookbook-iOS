// SchemaOrg.swift
// RecipeScraperKit
//
// Reads schema.org Recipe data from a page: JSON-LD first, microdata as a fallback.

import Foundation
import SwiftSoup

enum SchemaOrg {

    // MARK: - JSON-LD

    static func recipeFromJSONLD(in page: RecipePage) -> ScrapedRecipe? {
        guard let object = recipeObject(in: page) else { return nil }
        return recipe(fromJSONLD: object, baseURL: page.url)
    }

    /// The first JSON object of type Recipe in any `<script type="application/ld+json">`.
    static func recipeObject(in page: RecipePage) -> [String: Any]? {
        let scripts = (try? page.document.select("script[type=\"application/ld+json\"]").array()) ?? []
        for script in scripts {
            guard let json = parseJSON(script.data()), let recipe = findRecipe(in: json) else { continue }
            return recipe
        }
        return nil
    }

    static func parseJSON(_ text: String) -> Any? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let data = trimmed.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) {
            return json
        }
        // Some sites put raw line breaks or tabs inside strings, which is invalid JSON.
        let repaired = trimmed.replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
        guard let data = repaired.data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
    }

    /// Searches arrays, `@graph` and `mainEntity` for an object whose `@type` is Recipe.
    static func findRecipe(in json: Any) -> [String: Any]? {
        if let array = json as? [Any] {
            for item in array {
                if let recipe = findRecipe(in: item) { return recipe }
            }
        } else if let object = json as? [String: Any] {
            if isType(object, "Recipe") { return object }
            for key in ["@graph", "mainEntity", "mainEntityOfPage"] {
                if let nested = object[key], let recipe = findRecipe(in: nested) { return recipe }
            }
        }
        return nil
    }

    /// True if `@type` is (or contains) `type`, also with a schema.org prefix.
    static func isType(_ value: Any?, _ type: String) -> Bool {
        guard let object = value as? [String: Any] else { return false }
        let types: [String]
        switch object["@type"] {
        case let single as String: types = [single]
        case let many as [Any]: types = many.compactMap { $0 as? String }
        default: types = []
        }
        return types.contains { $0 == type || $0.hasSuffix("/" + type) || $0.hasSuffix(":" + type) }
    }

    static func recipe(fromJSONLD object: [String: Any], baseURL: URL) -> ScrapedRecipe {
        ScrapedRecipe(
            name: Normalize.text(object["name"]) ?? "",
            description: Normalize.text(object["description"]) ?? "",
            sourceURL: Normalize.url(object["url"], base: baseURL),
            imageURL: Normalize.imageURL(object["image"], base: baseURL)
                ?? Normalize.imageURL(object["thumbnailUrl"], base: baseURL),
            category: Normalize.category(object["recipeCategory"]),
            keywords: Normalize.keywords(object["keywords"]),
            servings: Normalize.servings(object["recipeYield"] ?? object["yield"]),
            prepTime: Normalize.minutes(object["prepTime"]),
            cookTime: Normalize.minutes(object["cookTime"]),
            totalTime: Normalize.minutes(object["totalTime"]),
            ingredients: Normalize.lines(object["recipeIngredient"] ?? object["ingredients"]),
            instructions: Normalize.instructions(object["recipeInstructions"]),
            tools: Normalize.lines(object["tool"]),
            nutrition: Normalize.nutrition(object["nutrition"])
        )
    }

    // MARK: - Microdata

    /// Reads `itemprop` attributes inside an element with `itemtype` schema.org/Recipe.
    static func recipeFromMicrodata(in page: RecipePage) -> ScrapedRecipe? {
        guard let root = try? page.document.select("[itemtype~=(?i)schema\\.org/Recipe$]").first() else {
            return nil
        }
        func elements(_ prop: String) -> [Element] {
            (try? root.select("[itemprop=\(prop)]").array()) ?? []
        }
        /// Machine-readable value (content/datetime attributes) or the element's text.
        func value(_ element: Element) -> String {
            for attribute in ["content", "datetime"] {
                if let value = try? element.attr(attribute), !value.isEmpty { return value }
            }
            return (try? element.text()) ?? ""
        }
        func first(_ prop: String) -> String? {
            elements(prop).first.map(value)
        }

        let instructionElements = elements("recipeInstructions")
        var instructions = instructionElements.flatMap { element -> [String] in
            let html = (try? element.html()) ?? ""
            return Normalize.splitInstructionText(html)
        }
        if instructionElements.count > 1 {
            // One element per step: keep each as one step.
            instructions = instructionElements.compactMap { Normalize.text((try? $0.text()) ?? "") }
        }

        let imageElement = elements("image").first
        let image = imageElement.flatMap { element -> String? in
            for attribute in ["src", "content", "href"] {
                if let value = try? element.attr(attribute), !value.isEmpty { return value }
            }
            return nil
        }

        return ScrapedRecipe(
            name: Normalize.text(first("name")) ?? "",
            description: Normalize.text(first("description")) ?? "",
            imageURL: Normalize.imageURL(image, base: page.url),
            category: Normalize.category(first("recipeCategory")),
            keywords: Normalize.keywords(first("keywords")),
            servings: Normalize.servings(first("recipeYield")),
            prepTime: Normalize.minutes(first("prepTime")),
            cookTime: Normalize.minutes(first("cookTime")),
            totalTime: Normalize.minutes(first("totalTime")),
            ingredients: (elements("recipeIngredient") + elements("ingredients"))
                .compactMap { Normalize.text(value($0)) },
            instructions: instructions
        )
    }
}
