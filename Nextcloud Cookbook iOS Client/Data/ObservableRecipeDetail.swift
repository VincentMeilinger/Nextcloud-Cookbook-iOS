//
//  ObservableRecipeDetail.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 01.03.24.
//

import Foundation
import SwiftUI

class ObservableRecipeDetail: ObservableObject {
    // Cookbook recipe detail fields
    var id: String
    @Published var name: String
    @Published var keywords: [String]
    @Published var imageUrl: String
    @Published var prepTime: DurationComponents
    @Published var cookTime: DurationComponents
    @Published var totalTime: DurationComponents
    @Published var description: String
    @Published var url: String
    @Published var recipeYield: Int
    @Published var recipeCategory: String
    @Published var tool: [String]
    @Published var recipeIngredient: [String]
    @Published var recipeInstructions: [String]
    @Published var nutrition: [String:String]
    
    // Additional functionality
    @Published var ingredientMultiplier: Double
    
    
    
    init() {
        id = ""
        name = String(localized: "New Recipe")
        keywords = []
        imageUrl = ""
        prepTime = DurationComponents()
        cookTime = DurationComponents()
        totalTime = DurationComponents()
        description = ""
        url = ""
        recipeYield = 1
        recipeCategory = ""
        tool = []
        recipeIngredient = []
        recipeInstructions = []
        nutrition = [:]
        
        ingredientMultiplier = 1
    }
    
    init(_ recipeDetail: RecipeDetail) {
        id = recipeDetail.id
        name = recipeDetail.name
        keywords = recipeDetail.keywords.isEmpty ? [] : recipeDetail.keywords.components(separatedBy: ",")
        imageUrl = recipeDetail.imageUrl
        prepTime = DurationComponents.fromPTString(recipeDetail.prepTime ?? "")
        cookTime = DurationComponents.fromPTString(recipeDetail.cookTime ?? "")
        totalTime = DurationComponents.fromPTString(recipeDetail.totalTime ?? "")
        description = recipeDetail.description
        url = recipeDetail.url
        recipeYield = recipeDetail.recipeYield == 0 ? 1 : recipeDetail.recipeYield // Recipe yield should not be zero
        recipeCategory = recipeDetail.recipeCategory
        tool = recipeDetail.tool
        recipeIngredient = recipeDetail.recipeIngredient
        recipeInstructions = recipeDetail.recipeInstructions
        nutrition = recipeDetail.nutrition
        
        ingredientMultiplier = Double(recipeDetail.recipeYield == 0 ? 1 : recipeDetail.recipeYield)
    }
    
    func toRecipeDetail() -> RecipeDetail {
        return RecipeDetail(
            name: self.name,
            keywords: self.keywords.joined(separator: ","),
            dateCreated: "",
            dateModified: "",
            imageUrl: self.imageUrl,
            id: self.id,
            prepTime: self.prepTime.toPTString(),
            cookTime: self.cookTime.toPTString(),
            totalTime: self.totalTime.toPTString(),
            description: self.description,
            url: self.url,
            recipeYield: self.recipeYield,
            recipeCategory: self.recipeCategory,
            tool: self.tool,
            recipeIngredient: self.recipeIngredient,
            recipeInstructions: self.recipeInstructions,
            nutrition: self.nutrition
        )
    }
    
    static func adjustIngredient(_ ingredient: String, by factor: Double) -> AttributedString {
        if factor == 0 {
            return AttributedString(ingredient)
        }
        // Match mixed fractions first
        var matches = ObservableRecipeDetail.matchPatternAndMultiply(
            .mixedFraction,
            in: ingredient,
            multFactor: factor
        )
        // Then match fractions, exclude mixed fraction ranges
        matches.append(contentsOf:
            ObservableRecipeDetail.matchPatternAndMultiply(
                .fraction,
                in: ingredient,
                multFactor: factor,
                excludedRanges: matches.map({ tuple in tuple.1 })
            )
        )
        // Match numbers at last, exclude all prior matches
        matches.append(contentsOf:
            ObservableRecipeDetail.matchPatternAndMultiply(
                .number,
                in: ingredient,
                multFactor: factor,
                excludedRanges: matches.map({ tuple in tuple.1 })
            )
        )
        // Sort matches by match range lower bound, descending.
        matches.sort(by: { a, b in a.1.lowerBound > b.1.lowerBound})

        var attributedString = AttributedString(ingredient)
        for (newSubstring, matchRange) in matches {
            print(newSubstring, matchRange)
            guard let range = Range(matchRange, in: attributedString) else { continue }
            var attributedSubString = AttributedString(newSubstring)
            //attributedSubString.foregroundColor = .ncTextHighlight
            attributedSubString.font = .system(.body, weight: .bold)
            attributedString.replaceSubrange(range, with: attributedSubString)
            print("\n", attributedString)
        }
        
        return attributedString
    }
    
    static func matchPatternAndMultiply(_ expr: RegexPattern, in str: String, multFactor: Double, excludedRanges: [Range<String.Index>]? = nil) -> [(String, Range<String.Index>)] {
        var foundMatches: [(String, Range<String.Index>)] = []
        do {
            let regex = try NSRegularExpression(pattern: expr.pattern)
            let matches = regex.matches(in: str, range: NSRange(str.startIndex..., in: str))
            
            for match in matches {
                guard let matchRange = Range(match.range, in: str) else { continue }
                if let excludedRanges = excludedRanges,
                   excludedRanges.contains(where: { $0.overlaps(matchRange) }) {
                    // If there's an overlap, skip this match.
                    continue
                }
                
                let matchedString = String(str[matchRange])
                
                // Process each match based on its type
                var adjustedValue: Double = 0
                switch expr {
                case .number:
                    guard let number = numberFormatter.number(from: matchedString) else { continue }
                    adjustedValue = number.doubleValue
                case .fraction:
                    let fracComponents = matchedString.split(separator: "/")
                    guard fracComponents.count == 2 else { continue }
                    guard let nominator = Double(fracComponents[0]) else { continue }
                    guard let denominator = Double(fracComponents[1]), denominator > 0 else { continue }
                    adjustedValue = nominator/denominator
                case .mixedFraction:
                    guard match.numberOfRanges == 4 else { continue }
                    guard let intRange = Range(match.range(at: 1), in: str) else { continue }
                    guard let nomRange = Range(match.range(at: 2), in: str) else { continue }
                    guard let denomRange = Range(match.range(at: 3), in: str) else { continue }
                    guard let number = Double(str[intRange]),
                            let nominator = Double(str[nomRange]),
                            let denominator = Double(str[denomRange]), denominator > 0
                    else { continue }
                    adjustedValue = number + nominator/denominator
                }
                let formattedAdjustedValue = formatNumber(adjustedValue * multFactor)
                foundMatches.append((formattedAdjustedValue, matchRange))
            }
            return foundMatches
        } catch {
            print("Regex error: \(error.localizedDescription)")
        }
        return []
    }
    
    static func formatNumber(_ value: Double) -> String {
        if value <= 0.0001 {
            return "0"
        }
        let integerPart = value >= 1 ? Int(value) : 0
        let decimalPart = value - Double(integerPart)
        
        if integerPart >= 1 && decimalPart < 0.0001 {
            return String(format: "%.0f", value)
        }
        
        // Define known fractions and their decimal equivalents
        let knownFractions: [(fraction: String, value: Double)] = [
            ("1/8", 0.125), ("1/6", 0.167), ("1/4", 0.25), ("1/3", 0.33), ("1/2", 0.5), ("2/3", 0.66), ("3/4", 0.75)
        ]
        
        // Find the known fraction closest to the given value
        let closest = knownFractions.min(by: { abs($0.value - decimalPart) < abs($1.value - decimalPart) })!
                
        // Check if the value is close enough to a known fraction to be considered a match
        let threshold = 0.05
        if abs(closest.value - decimalPart) <= threshold && integerPart == 0 {
            return closest.fraction
        } else if abs(closest.value - decimalPart) <= threshold && integerPart > 0 {
            return "\(String(integerPart)) \(closest.fraction)"
        } else {
            // If no close match is found, return the original value as a string
            return numberFormatter.string(from: NSNumber(value: value)) ?? "0"//String(format: "%.2f", value)
        }
    }
    
    func ingredientUnitsToMetric() {
        // TODO: Convert imperial units in recipes to metric units
    }
}

enum RegexPattern: String, CaseIterable, Identifiable {
    case mixedFraction, fraction, number
    
    var id: String { self.rawValue }
    
    var pattern: String {
        switch self {
        case .mixedFraction:
            #"(\d+)\s+(\d+)/(\d+)"#
        case .fraction:
            #"(?:[1-9][0-9]*|0)\/([1-9][0-9]*)"#
        case .number:
            #"(\d+([.,]\d+)?)"#
        }
    }
    
    var localizedDescription: LocalizedStringKey {
        switch self {
        case .mixedFraction:
            "Mixed fraction"
        case .fraction:
            "Fraction"
        case .number:
            "Number"
        }
    }
}

