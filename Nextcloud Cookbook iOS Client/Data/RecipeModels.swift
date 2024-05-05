//
//  RecipeModels.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 17.02.24.
//

import Foundation
import SwiftUI


struct Recipe: Codable {
    let name: String
    let keywords: String?
    let dateCreated: String?
    let dateModified: String?
    let imageUrl: String?
    let imagePlaceholderUrl: String?
    let recipe_id: Int
    
    // Properties excluded from Codable
    var storedLocally: Bool? = nil
    
    private enum CodingKeys: String, CodingKey {
        case name, keywords, dateCreated, dateModified, imageUrl, imagePlaceholderUrl, recipe_id
    }
}


extension Recipe: Identifiable, Hashable {
    var id: String { name }
}


struct RecipeDetail: Codable {
    var name: String
    var keywords: String
    var dateCreated: String?
    var dateModified: String?
    var imageUrl: String?
    var id: String
    var prepTime: String?
    var cookTime: String?
    var totalTime: String?
    var description: String
    var url: String?
    var recipeYield: Int
    var recipeCategory: String
    var tool: [String]
    var recipeIngredient: [String]
    var recipeInstructions: [String]
    var nutrition: [String:String]
    
    init(name: String, keywords: String, dateCreated: String, dateModified: String, imageUrl: String, id: String, prepTime: String? = nil, cookTime: String? = nil, totalTime: String? = nil, description: String, url: String, recipeYield: Int, recipeCategory: String, tool: [String], recipeIngredient: [String], recipeInstructions: [String], nutrition: [String:String]) {
        self.name = name
        self.keywords = keywords
        self.dateCreated = dateCreated
        self.dateModified = dateModified
        self.imageUrl = imageUrl
        self.id = id
        self.prepTime = prepTime
        self.cookTime = cookTime
        self.totalTime = totalTime
        self.description = description
        self.url = url
        self.recipeYield = recipeYield
        self.recipeCategory = recipeCategory
        self.tool = tool
        self.recipeIngredient = recipeIngredient
        self.recipeInstructions = recipeInstructions
        self.nutrition = nutrition
    }
    
    init() {
        name = ""
        keywords = ""
        dateCreated = ""
        dateModified = ""
        imageUrl = ""
        id = ""
        prepTime = ""
        cookTime = ""
        totalTime = ""
        description = ""
        url = ""
        recipeYield = 0
        recipeCategory = ""
        tool = []
        recipeIngredient = []
        recipeInstructions = []
        nutrition = [:]
    }
    
    // Custom decoder to handle value type ambiguity
    private enum CodingKeys: String, CodingKey {
        case name, keywords, dateCreated, dateModified, imageUrl, id, prepTime, cookTime, totalTime, description, url, recipeYield, recipeCategory, tool, recipeIngredient, recipeInstructions, nutrition
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        keywords = try container.decode(String.self, forKey: .keywords)
        dateCreated = try container.decodeIfPresent(String.self, forKey: .dateCreated)
        dateModified = try container.decodeIfPresent(String.self, forKey: .dateModified)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        id = try container.decode(String.self, forKey: .id)
        prepTime = try container.decodeIfPresent(String.self, forKey: .prepTime)
        cookTime = try container.decodeIfPresent(String.self, forKey: .cookTime)
        totalTime = try container.decodeIfPresent(String.self, forKey: .totalTime)
        description = try container.decode(String.self, forKey: .description)
        url = try container.decode(String.self, forKey: .url)
        recipeYield = try container.decode(Int.self, forKey: .recipeYield)
        recipeCategory = try container.decode(String.self, forKey: .recipeCategory)
        tool = try container.decode([String].self, forKey: .tool)
        recipeIngredient = try container.decode([String].self, forKey: .recipeIngredient)
        recipeInstructions = try container.decode([String].self, forKey: .recipeInstructions)

        nutrition = try container.decode(Dictionary<String, JSONAny>.self, forKey: .nutrition).mapValues { String(describing: $0.value) }
    }
}


extension RecipeDetail {
    static var error: RecipeDetail {
         return RecipeDetail(
             name: "Error: Unable to load recipe.",
             keywords: "",
             dateCreated: "",
             dateModified: "",
             imageUrl: "",
             id: "",
             prepTime: "",
             cookTime: "",
             totalTime: "",
             description: "",
             url: "",
             recipeYield: 0,
             recipeCategory: "",
             tool: [],
             recipeIngredient: [],
             recipeInstructions: [],
             nutrition: [:]
         )
    }
    
    func getKeywordsArray() -> [String] {
        if keywords == "" { return [] }
        return keywords.components(separatedBy: ",")
    }
    
    mutating func setKeywordsFromArray(_ keywordsArray: [String]) {
        if !keywordsArray.isEmpty {
            self.keywords = keywordsArray.joined(separator: ",")
        }
    }
}


struct RecipeImage {
    enum RecipeImageSize: String {
        case THUMB="thumb", FULL="full"
    }
    var imageExists: Bool = true
    var thumb: UIImage?
    var full: UIImage?
}


struct RecipeKeyword: Codable {
    let name: String
    let recipe_count: Int
}


enum Nutrition: CaseIterable {
    case servingSize,
         calories,
         carbohydrateContent,
         cholesterolContent,
         fatContent,
         saturatedFatContent,
         unsaturatedFatContent,
         transFatContent,
         fiberContent,
         proteinContent,
         sodiumContent,
         sugarContent
    
    var localizedDescription: String {
        switch self {
        case .servingSize:
            return NSLocalizedString("Serving size", comment: "Serving size")
        case .calories:
            return NSLocalizedString("Calories", comment: "Calories")
        case .carbohydrateContent:
            return NSLocalizedString("Carbohydrate content", comment: "Carbohydrate content")
        case .cholesterolContent:
            return NSLocalizedString("Cholesterol content", comment: "Cholesterol content")
        case .fatContent:
            return NSLocalizedString("Fat content", comment: "Fat content")
        case .saturatedFatContent:
            return NSLocalizedString("Saturated fat content", comment: "Saturated fat content")
        case .unsaturatedFatContent:
            return NSLocalizedString("Unsaturated fat content", comment: "Unsaturated fat content")
        case .transFatContent:
            return NSLocalizedString("Trans fat content", comment: "Trans fat content")
        case .fiberContent:
            return NSLocalizedString("Fiber content", comment: "Fiber content")
        case .proteinContent:
            return NSLocalizedString("Protein content", comment: "Protein content")
        case .sodiumContent:
            return NSLocalizedString("Sodium content", comment: "Sodium content")
        case .sugarContent:
            return NSLocalizedString("Sugar content", comment: "Sugar content")
        }
    }
    
    var dictKey: String {
        switch self {
        case .servingSize:
            "servingSize"
        case .calories:
            "calories"
        case .carbohydrateContent:
            "carbohydrateContent"
        case .cholesterolContent:
            "cholesterolContent"
        case .fatContent:
            "fatContent"
        case .saturatedFatContent:
            "saturatedFatContent"
        case .unsaturatedFatContent:
            "unsaturatedFatContent"
        case .transFatContent:
            "transFatContent"
        case .fiberContent:
            "fiberContent"
        case .proteinContent:
            "proteinContent"
        case .sodiumContent:
            "sodiumContent"
        case .sugarContent:
            "sugarContent"
        }
    }
}
