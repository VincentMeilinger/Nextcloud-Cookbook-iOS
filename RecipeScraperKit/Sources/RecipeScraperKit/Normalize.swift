// Normalize.swift
// RecipeScraperKit
//
// Turns the many shapes schema.org values come in into clean Swift values.
// Site scrapers can use these helpers too.

import Foundation
import SwiftSoup

public enum Normalize {

    // MARK: - Text

    /// Plain text from a string (HTML tags removed, entities decoded, whitespace
    /// collapsed), a number, an object with "name"/"text"/"@value", or the first
    /// usable element of an array. Nil if empty.
    public static func text(_ value: Any?) -> String? {
        switch value {
        case let string as String:
            let cleaned = clean(string)
            return cleaned.isEmpty ? nil : cleaned
        case let number as NSNumber:
            return number.stringValue
        case let object as [String: Any]:
            return text(object["text"]) ?? text(object["name"]) ?? text(object["@value"])
        case let array as [Any]:
            return array.lazy.compactMap { text($0) }.first
        default:
            return nil
        }
    }

    /// Removes HTML tags, decodes entities (also double-encoded ones like
    /// `&amp;#39;`) and collapses whitespace.
    public static func clean(_ string: String) -> String {
        var result = string
        for _ in 0..<2 where result.contains("<") || result.contains("&") {
            guard let text = try? SwiftSoup.parseBodyFragment(result).text() else { break }
            result = text
        }
        return result
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    /// A list of plain strings: arrays (of strings or objects with a name), or one
    /// string with one entry per line.
    public static func lines(_ value: Any?) -> [String] {
        switch value {
        case let string as String:
            return string.components(separatedBy: .newlines).compactMap { text($0) }
        case let array as [Any]:
            return array.compactMap { text($0) }
        case let object as [String: Any]:
            return lines(object["itemListElement"] ?? object["name"])
        default:
            return []
        }
    }

    // MARK: - Instructions

    /// Instruction steps from any schema.org shape: a single string (split into
    /// paragraphs or list items), strings, HowToStep objects or HowToSection groups.
    /// A section's name is put in bold in front of its first step.
    public static func instructions(_ value: Any?) -> [String] {
        switch value {
        case let string as String:
            return splitInstructionText(string)
        case let object as [String: Any]:
            return instructions([object])
        case let array as [Any]:
            let hasSections = array.filter { SchemaOrg.isType($0, "HowToSection") }.count > 1
            return array.flatMap { item -> [String] in
                if let string = item as? String {
                    let steps = splitInstructionText(string)
                    // A list of strings is already one entry per step, unless an
                    // entry is an HTML list.
                    return string.contains("<li") ? steps : (text(string).map { [$0] } ?? [])
                }
                guard let object = item as? [String: Any] else { return [] }
                if let elements = object["itemListElement"] {
                    var steps = instructions(elements)
                    if hasSections, let name = text(object["name"]), !steps.isEmpty {
                        steps[0] = "**\(name):** " + steps[0]
                    }
                    return steps
                }
                return (text(object["text"]) ?? text(object["name"])).map { [$0] } ?? []
            }
        default:
            return []
        }
    }

    /// Splits one block of instruction text into steps: by `<li>` or `<p>` when it is
    /// HTML, otherwise by line breaks.
    public static func splitInstructionText(_ string: String) -> [String] {
        if string.range(of: "<(li|p)[\\s>]", options: [.regularExpression, .caseInsensitive]) != nil,
           let document = try? SwiftSoup.parseBodyFragment(string) {
            let items = (try? document.select("li").array()) ?? []
            let blocks = items.isEmpty ? ((try? document.select("p").array()) ?? []) : items
            let steps = blocks.compactMap { try? $0.text() }.compactMap { text($0) }
            if !steps.isEmpty { return steps }
        }
        let decoded = string.replacingOccurrences(of: "<br\\s*/?>", with: "\n", options: [.regularExpression, .caseInsensitive])
        return decoded.components(separatedBy: .newlines).compactMap { text($0) }
    }

    // MARK: - Numbers and times

    /// Minutes from an ISO 8601 duration ("PT1H30M", "P0DT1H30M0S", "PT90M") or
    /// text like "1 hour 20 minutes", "45 mins", "1 Std. 10 Min.".
    public static func minutes(_ value: Any?) -> Int? {
        guard let string = text(value) else { return nil }
        let upper = string.uppercased()
        let iso = "^P(?:(\\d+(?:\\.\\d+)?)D)?(?:T(?:(\\d+(?:\\.\\d+)?)H)?(?:(\\d+(?:\\.\\d+)?)M)?(?:(\\d+(?:\\.\\d+)?)S)?)?$"
        if let match = upper.firstMatch(of: try! Regex(iso)) {
            func part(_ index: Int) -> Double {
                guard let range = match.output[index].range else { return 0 }
                return Double(upper[range]) ?? 0
            }
            let total = Int((part(1) * 1440 + part(2) * 60 + part(3) + part(4) / 60).rounded())
            return total > 0 ? total : nil
        }
        // Free text: add up hours and minutes.
        let lower = string.lowercased()
        let hours = number(in: lower, before: "(?:h|hr|hrs|hour|hours|std|stunde|stunden|heure|heures)\\b")
        let mins = number(in: lower, before: "(?:m|min|mins|minute|minutes|minuten)\\b")
        if hours != nil || mins != nil {
            let total = Int(((hours ?? 0) * 60 + (mins ?? 0)).rounded())
            return total > 0 ? total : nil
        }
        if let plain = Double(lower.trimmingCharacters(in: .whitespaces)), plain > 0 {
            return Int(plain)
        }
        return nil
    }

    /// Servings from a number, text like "Serves 4", "Makes 12", "1 loaf, 10 serving(s)",
    /// or a list of such values. A number next to a word like "servings" or
    /// "Portionen" wins over other numbers.
    public static func servings(_ value: Any?) -> Int? {
        let candidates: [String]
        switch value {
        case let number as NSNumber: return number.intValue > 0 ? number.intValue : nil
        case let array as [Any]: candidates = array.compactMap { text($0) }
        default: candidates = text(value).map { [$0] } ?? []
        }
        let servingWords = "(?:serving|servings|portion|portions|person|persons|people|personen|portionen|pers\\.?)"
        for candidate in candidates {
            if let n = number(in: candidate.lowercased(), before: servingWords), n > 0 { return Int(n) }
        }
        for candidate in candidates {
            // "Makes about 3 dozen cookies"
            if let n = number(in: candidate.lowercased(), before: "dozen"), n > 0 { return Int(n * 12) }
        }
        for candidate in candidates {
            if let range = candidate.range(of: "\\d+", options: .regularExpression), let n = Int(candidate[range]), n > 0 { return n }
        }
        return nil
    }

    /// The number directly before a unit pattern, e.g. "1.5" in "1.5 hours".
    private static func number(in string: String, before unit: String) -> Double? {
        guard let match = string.firstMatch(of: try! Regex("(\\d+(?:[.,]\\d+)?)\\s*" + unit)),
              let range = match.output[1].range
        else { return nil }
        return Double(string[range].replacingOccurrences(of: ",", with: "."))
    }

    // MARK: - URLs

    public static func url(_ value: Any?, base: URL) -> URL? {
        guard let string = value as? String, !string.isEmpty else { return nil }
        return URL(string: string.trimmingCharacters(in: .whitespaces), relativeTo: base)?.absoluteURL
    }

    /// The first image URL from a string, an ImageObject (url/contentUrl) or a list of either.
    public static func imageURL(_ value: Any?, base: URL) -> URL? {
        switch value {
        case let string as String:
            return url(string, base: base)
        case let object as [String: Any]:
            return url(object["url"], base: base) ?? url(object["contentUrl"], base: base) ?? url(object["@id"], base: base)
        case let array as [Any]:
            return array.lazy.compactMap { imageURL($0, base: base) }.first
        default:
            return nil
        }
    }

    // MARK: - Categories, keywords, nutrition

    /// The first category: from a list, or the first entry of a comma-separated string.
    public static func category(_ value: Any?) -> String? {
        if let array = value as? [Any] { return array.lazy.compactMap { category($0) }.first }
        guard let string = text(value),
              let first = string.split(separator: ",").first?.trimmingCharacters(in: .whitespaces),
              !first.isEmpty
        else { return nil }
        // "dessert" → "Dessert"
        return first.prefix(1).uppercased() + first.dropFirst()
    }

    /// Keywords from a comma-separated string or a list; trimmed, without duplicates.
    public static func keywords(_ value: Any?) -> [String] {
        let raw: [String]
        switch value {
        case let array as [Any]: raw = array.compactMap { text($0) }.flatMap { $0.components(separatedBy: ",") }
        default: raw = text(value)?.components(separatedBy: ",") ?? []
        }
        var seen = Set<String>()
        return raw
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && seen.insert($0.lowercased()).inserted }
    }

    /// schema.org NutritionInformation keys the Cookbook app knows.
    public static let nutritionKeys = [
        "calories", "carbohydrateContent", "cholesterolContent", "fatContent",
        "fiberContent", "proteinContent", "saturatedFatContent", "servingSize",
        "sodiumContent", "sugarContent", "transFatContent", "unsaturatedFatContent",
    ]

    public static func nutrition(_ value: Any?) -> [String: String] {
        guard let object = value as? [String: Any] else { return [:] }
        var result: [String: String] = [:]
        for key in nutritionKeys {
            if let value = text(object[key]) { result[key] = value }
        }
        return result
    }
}
