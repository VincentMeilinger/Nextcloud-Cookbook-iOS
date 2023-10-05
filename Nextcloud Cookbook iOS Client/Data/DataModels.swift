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
    
    init(name: String, keywords: String, dateCreated: String, dateModified: String, imageUrl: String, id: String, prepTime: String? = nil, cookTime: String? = nil, totalTime: String? = nil, description: String, url: String, recipeYield: Int, recipeCategory: String, tool: [String], recipeIngredient: [String], recipeInstructions: [String]) {
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
    }
   
    static func error() -> RecipeDetail {
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
            recipeInstructions: []
        )
    }
}

struct RecipeImage {
    var imageExists: Bool = true
    var thumb: UIImage?
    var full: UIImage?
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


// Networking
struct ServerMessage: Decodable {
    let msg: String
}
