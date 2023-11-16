//
//  RecipeEditViewModel.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 11.11.23.
//

import Foundation
import SwiftUI

@MainActor class RecipeEditViewModel: ObservableObject {
    @ObservedObject var mainViewModel: MainViewModel
    @Published var isPresented: Binding<Bool>
    @Published var recipe: RecipeDetail = RecipeDetail()
    
    @Published var prepDuration: DurationComponents = DurationComponents()
    @Published var cookDuration: DurationComponents = DurationComponents()
    @Published var totalDuration: DurationComponents = DurationComponents()
    
    @Published var searchText: String = ""
    @Published var keywords: [String] = []
    @Published var keywordSuggestions: [String] = []
    
    @Published var showImportSection: Bool = false
    @Published var importURL: String = ""
    
    @Published var presentAlert = false
    var alertType: UserAlert = RecipeCreationError.GENERIC
    var alertAction: @MainActor () async -> (RequestAlert) = { return .REQUEST_DROPPED }
    
    var uploadNew: Bool = true
    var waitingForUpload: Bool = false
    
    
    init(mainViewModel: MainViewModel, isPresented: Binding<Bool>, uploadNew: Bool) {
        self.mainViewModel = mainViewModel
        self.isPresented = isPresented
        self.uploadNew = uploadNew
    }
    
    init(mainViewModel: MainViewModel, recipeDetail: RecipeDetail, isPresented: Binding<Bool>, uploadNew: Bool) {
        self.mainViewModel = mainViewModel
        self.recipe = recipeDetail
        self.isPresented = isPresented
        self.uploadNew = uploadNew
    }
    
    
    func createRecipe() {
        self.recipe.prepTime = prepDuration.toPTString()
        self.recipe.cookTime = cookDuration.toPTString()
        self.recipe.totalTime = totalDuration.toPTString()
        self.recipe.setKeywordsFromArray(keywords)
    }
    
    func recipeValid() -> Bool {
        // Check if the recipe has a name
        if recipe.name.replacingOccurrences(of: " ", with: "") == "" {
            alertType = RecipeCreationError.NO_TITLE
            alertAction = {return .REQUEST_DROPPED}
            presentAlert = true
            return false
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
                    alertType = RecipeCreationError.DUPLICATE
                    alertAction = {return .REQUEST_DROPPED}
                    presentAlert = true
                    return false
                }
            }
        }
        
        return true
    }
    
    func uploadNewRecipe() async -> RequestAlert {
        print("Uploading new recipe.")
        waitingForUpload = true
        createRecipe()
        guard recipeValid() else { return .REQUEST_DROPPED }
        
        return await mainViewModel.uploadRecipe(recipeDetail: self.recipe, createNew: true)
    }
    
    func uploadEditedRecipe() async -> RequestAlert {
        waitingForUpload = true
        print("Uploading changed recipe.")
        guard let recipeId = Int(recipe.id) else { return .REQUEST_DROPPED }
        createRecipe()
        
        return await mainViewModel.uploadRecipe(recipeDetail: self.recipe, createNew: false)
    }
    
    func deleteRecipe() async -> RequestAlert {
        guard let id = Int(recipe.id) else {
            return .REQUEST_DROPPED
        }
        return await mainViewModel.deleteRecipe(withId: id, categoryName: recipe.recipeCategory)
    }
    
    
    
    func dismissEditView() {
        Task {
            await mainViewModel.loadCategories() //loadCategoryList(needsUpdate: true)
            await mainViewModel.getCategory(named: recipe.recipeCategory)//.loadRecipeList(categoryName: recipe.recipeCategory, needsUpdate: true)
        }
        isPresented.wrappedValue = false
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
    
    func importRecipe() {
        Task {
            do {
                let (scrapedRecipe, error) = try await RecipeScraper().scrape(url: importURL)
                if let scrapedRecipe = scrapedRecipe {
                    self.recipe = scrapedRecipe
                    prepareView()
                }
                if let error = error {
                    self.alertType = error
                    self.alertAction = {return .REQUEST_DROPPED}
                    self.presentAlert = true
                }
            } catch {
                print("Error")
            }
        }
    }
}
