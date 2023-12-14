//
//  DataModels.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 15.09.23.
//

import Foundation
import SwiftUI

struct Category: Codable {
    let name: String
    let recipe_count: Int
    
    private enum CodingKeys: String, CodingKey {
        case name, recipe_count
    }
}

extension Category: Identifiable, Hashable {
    var id: String { name }
}

struct Recipe: Codable {
    let name: String
    let keywords: String?
    let dateCreated: String
    let dateModified: String
    let imageUrl: String
    let imagePlaceholderUrl: String
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
    var dateCreated: String
    var dateModified: String
    var imageUrl: String
    var id: String
    var prepTime: String?
    var cookTime: String?
    var totalTime: String?
    var description: String
    var url: String
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
    
    func getNutritionList() -> [String]? {
        var stringList: [String] = []
        if let value = nutrition["calories"] { stringList.append("Calories: \(value)") }
        if let value = nutrition["carbohydrateContent"] { stringList.append("Carbohydrates: \(value)") }
        if let value = nutrition["cholesterolContent"] { stringList.append("Cholesterol: \(value)") }
        if let value = nutrition["fatContent"] { stringList.append("Fat: \(value)") }
        if let value = nutrition["saturatedFatContent"] { stringList.append("Saturated fat: \(value)") }
        if let value = nutrition["unsaturatedFatContent"] { stringList.append("Unsaturated fat: \(value)") }
        if let value = nutrition["transFatContent"] { stringList.append("Trans fat: \(value)") }
        if let value = nutrition["fiberContent"] { stringList.append("Fibers: \(value)") }
        if let value = nutrition["proteinContent"] { stringList.append("Protein: \(value)") }
        if let value = nutrition["sodiumContent"] { stringList.append("Sodium: \(value)") }
        if let value = nutrition["sugarContent"] { stringList.append("Sugar: \(value)") }
        return stringList.isEmpty ? nil : stringList
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




// Login flow

struct LoginV2Request: Codable {
    let poll: LoginV2Poll
    let login: String
}

struct LoginV2Poll: Codable {
    let token: String
    let endpoint: String
}

struct LoginV2Response: Codable {
    let server: String
    let loginName: String
    let appPassword: String
}

struct LoginValidation: Codable {
    let ocs: Ocs
}

struct Ocs: Codable {
    let meta: MetaData
}

struct MetaData: Codable {
    let status: String
    let statuscode: Int
}



