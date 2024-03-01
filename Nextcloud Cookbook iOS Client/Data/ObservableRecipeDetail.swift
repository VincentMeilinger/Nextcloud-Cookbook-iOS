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
    @Published var tool: [ReorderableItem<String>]
    @Published var recipeIngredient: [ReorderableItem<String>]
    @Published var recipeInstructions: [ReorderableItem<String>]
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
        tool = ReorderableItem.list(items: recipeDetail.tool)
        recipeIngredient = ReorderableItem.list(items: recipeDetail.recipeIngredient)
        recipeInstructions = ReorderableItem.list(items: recipeDetail.recipeInstructions)
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
            tool: ReorderableItem.items(self.tool),
            recipeIngredient: ReorderableItem.items(self.recipeIngredient),
            recipeInstructions: ReorderableItem.items(self.recipeInstructions),
            nutrition: self.nutrition
        )
    }
}



