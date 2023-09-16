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

struct Recipe: Codable {
    let name: String
    let keywords: String
    let dateCreated: String
    let dateModified: String
    let imageUrl: String
    let imagePlaceholderUrl: String
    let recipe_id: Int
}

struct RecipeDetail: Codable {
    let name: String
    let keywords: String
    let dateCreated: String
    let dateModified: String
    let imageUrl: String
    let id: String
    let prepTime: String?
    let cookTime: String?
    let totalTime: String?
    let description: String
    let url: String
    let recipeYield: Int
    let recipeCategory: String
    let tool: [String]
    let recipeIngredient: [String]
    let recipeInstructions: [String]
   
    static func error() -> RecipeDetail {
        return RecipeDetail(
            name: "Error: Unable to load recipe.",
            keywords: "",
            dateCreated: "",
            dateModified: "",
            imageUrl: "", id: "",
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
    let thumb: UIImage
    let full: UIImage?
}
