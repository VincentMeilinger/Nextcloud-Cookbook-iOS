//
//  RecipeEditViewModel.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 11.11.23.
//

import Foundation
import SwiftUI

@MainActor class RecipeEditViewModel: ObservableObject {
    @ObservedObject var mainViewModel: AppState
    @Published var recipe: RecipeDetail = RecipeDetail()
    
    @Published var prepDuration: DurationComponents = DurationComponents()
    @Published var cookDuration: DurationComponents = DurationComponents()
    @Published var totalDuration: DurationComponents = DurationComponents()
    
    @Published var searchText: String = ""
    @Published var keywords: [String] = []
    @Published var keywordSuggestions: [RecipeKeyword] = []
    
    @Published var showImportSection: Bool = false
    @Published var importURL: String = ""
    
    
    
    var uploadNew: Bool = true
    var waitingForUpload: Bool = false
    
    
    init(mainViewModel: AppState, uploadNew: Bool) {
        self.mainViewModel = mainViewModel
        self.uploadNew = uploadNew
    }
    
    init(mainViewModel: AppState, recipeDetail: RecipeDetail, uploadNew: Bool) {
        self.mainViewModel = mainViewModel
        self.recipe = recipeDetail
        self.uploadNew = uploadNew
    }
    
    
    func createRecipe() {
        self.recipe.prepTime = prepDuration.toPTString()
        self.recipe.cookTime = cookDuration.toPTString()
        self.recipe.totalTime = totalDuration.toPTString()
        self.recipe.setKeywordsFromArray(keywords)
    }
    
    func recipeValid() -> RecipeAlert? {
        // Check if the recipe has a name
        if recipe.name.replacingOccurrences(of: " ", with: "") == "" {
            return RecipeAlert.NO_TITLE
        }
        // Check if the recipe has a unique name
        for recipeList in mainViewModel.recipes.values {
            for r in recipeList {
                if r.name
                    .replacingOccurrences(of: " ", with: "")
                    .lowercased() ==
                    recipe.name
                    .replacingOccurrences(of: " ", with: "")
                    .lowercased()
                {
                    return RecipeAlert.DUPLICATE
                }
            }
        }
        
        return nil
    }
    
    func uploadNewRecipe() async -> UserAlert? {
        print("Uploading new recipe.")
        waitingForUpload = true
        createRecipe()
        if let recipeValidationError = recipeValid() {
            return recipeValidationError
        }
        
        return await mainViewModel.uploadRecipe(recipeDetail: self.recipe, createNew: true)
    }
    
    func uploadEditedRecipe() async -> UserAlert? {
        waitingForUpload = true
        print("Uploading changed recipe.")
        guard let recipeId = Int(recipe.id) else { return RequestAlert.REQUEST_DROPPED }
        createRecipe()
        
        return await mainViewModel.uploadRecipe(recipeDetail: self.recipe, createNew: false)
    }
    
    func deleteRecipe() async -> RequestAlert? {
        guard let id = Int(recipe.id) else {
            return .REQUEST_DROPPED
        }
        return await mainViewModel.deleteRecipe(withId: id, categoryName: recipe.recipeCategory)
    }
    
    func prepareView() {
        if let prepTime = recipe.prepTime {
            prepDuration.fromPTString(prepTime)
        }
        if let cookTime = recipe.cookTime {
            cookDuration.fromPTString(cookTime)
        }
        if let totalTime = recipe.totalTime {
            totalDuration.fromPTString(totalTime)
        }
        self.keywords = recipe.getKeywordsArray()
    }
    
    func importRecipe() async -> UserAlert? {
        let (scrapedRecipe, error) = await mainViewModel.importRecipe(url: importURL)
        if let scrapedRecipe = scrapedRecipe {
            self.recipe = scrapedRecipe
            prepareView()
            return nil
        }
        
        do {
            let (scrapedRecipe, error) = try await RecipeScraper().scrape(url: importURL)
            if let scrapedRecipe = scrapedRecipe {
                self.recipe = scrapedRecipe
                prepareView()
            }
            if let error = error {
                return error
            }
        } catch {
            print("Error")
        }
        return nil
         
    }
}
