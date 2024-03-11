//
//  ObservableRecipeDetail.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 01.03.24.
//

import Foundation
import SwiftUI

class ObservableRecipeDetail: ObservableObject {
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
        recipeYield = 0
        recipeCategory = ""
        tool = []
        recipeIngredient = []
        recipeInstructions = []
        nutrition = [:]
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
        recipeYield = recipeDetail.recipeYield
        recipeCategory = recipeDetail.recipeCategory
        tool = recipeDetail.tool
        recipeIngredient = recipeDetail.recipeIngredient
        recipeInstructions = recipeDetail.recipeInstructions
        nutrition = recipeDetail.nutrition
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
    
    /*static func modifyIngredientAmounts(in ingredient: String, withFactor factor: Double) -> String {
        // Regular expression to match numbers, including integers and decimals
        // Patterns:
        // "\\b\\d+(\\.\\d+)?\\b" works only if there is a space following
        let regex = try! NSRegularExpression(pattern: "\\b\\d+(\\.\\d+)?\\b", options: [])
        let matches = regex.matches(in: ingredient, options: [], range: NSRange(ingredient.startIndex..., in: ingredient))
        
        // Reverse the matches to replace from the end to avoid affecting indices of unprocessed matches
        let reversedMatches = matches.reversed()
        
        var modifiedIngredient = ingredient
        
        for match in reversedMatches {
            guard let range = Range(match.range, in: modifiedIngredient) else { continue }
            let originalNumberString = String(modifiedIngredient[range])
            if let originalNumber = Double(originalNumberString) {
                let modifiedNumber = originalNumber * factor
                // Format the number to remove trailing zeros if it's an integer after multiplication
                let formattedNumber = formatNumber(modifiedNumber)
                modifiedIngredient.replaceSubrange(range, with: formattedNumber)
            }
        }
        
        return modifiedIngredient
    }*/
    static func modifyIngredientAmounts(in ingredient: String, withFactor factor: Double) -> String {
            // Regular expression to match numbers (including integers and decimals) and fractions
            let regexPattern = "\\b(\\d+(\\.\\d+)?)\\b|\\b(\\d+/\\d+)\\b"
            let regex = try! NSRegularExpression(pattern: regexPattern, options: [])
            let matches = regex.matches(in: ingredient, options: [], range: NSRange(ingredient.startIndex..., in: ingredient))
            
            var modifiedIngredient = ingredient
            
            // Reverse the matches to replace from the end to avoid affecting indices of unprocessed matches
            let reversedMatches = matches.reversed()
            
            for match in reversedMatches {
                let fullMatchRange = match.range(at: 0)
                
                // Check for a fractional match
                if match.range(at: 3).location != NSNotFound, let fractionRange = Range(match.range(at: 3), in: modifiedIngredient) {
                    let fractionString = String(modifiedIngredient[fractionRange])
                    let fractionParts = fractionString.split(separator: "/").compactMap { Double($0) }
                    if fractionParts.count == 2, let numerator = fractionParts.first, let denominator = fractionParts.last, denominator != 0 {
                        let fractionValue = numerator / denominator
                        let modifiedNumber = fractionValue * factor
                        let formattedNumber = formatNumber(modifiedNumber)
                        modifiedIngredient.replaceSubrange(fractionRange, with: formattedNumber)
                    }
                }
                // Check for an integer or decimal match
                else if let numberRange = Range(fullMatchRange, in: modifiedIngredient) {
                    let numberString = String(modifiedIngredient[numberRange])
                    if let number = Double(numberString) {
                        let modifiedNumber = number * factor
                        let formattedNumber = formatNumber(modifiedNumber)
                        modifiedIngredient.replaceSubrange(numberRange, with: formattedNumber)
                    }
                }
            }
            
            return modifiedIngredient
        }
    
    static func formatNumber(_ value: Double) -> String {
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
            return String(format: "%.2f", value)
        }
    }
    
    func ingredientUnitsToMetric() {
        // TODO: Convert imperial units in recipes to metric units
    }
}



