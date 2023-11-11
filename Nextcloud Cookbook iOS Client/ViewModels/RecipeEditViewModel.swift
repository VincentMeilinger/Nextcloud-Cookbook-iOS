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
    var alertAction: @MainActor () -> () = {}
    
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
            alertAction = {}
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
                    alertAction = {}
                    presentAlert = true
                    return false
                }
            }
        }
        
        return true
    }
    
    func uploadNewRecipe() {
        print("Uploading new recipe.")
        waitingForUpload = true
        createRecipe()
        guard recipeValid() else { return }
        let request = RequestWrapper.customRequest(
            method: .POST,
            path: .NEW_RECIPE,
            headerFields: [
                HeaderField.accept(value: .JSON),
                HeaderField.ocsRequest(value: true),
                HeaderField.contentType(value: .JSON)
            ],
            body: JSONEncoder.safeEncode(self.recipe)
        )
        sendRequest(request)
        dismissEditView()
    }
    
    func uploadEditedRecipe() {
        waitingForUpload = true
        print("Uploading changed recipe.")
        guard let recipeId = Int(recipe.id) else { return }
        createRecipe()
        let request = RequestWrapper.customRequest(
            method: .PUT,
            path: .RECIPE_DETAIL(recipeId: recipeId),
            headerFields: [
                HeaderField.accept(value: .JSON),
                HeaderField.ocsRequest(value: true),
                HeaderField.contentType(value: .JSON)
            ],
            body: JSONEncoder.safeEncode(self.recipe)
        )
        sendRequest(request)
        dismissEditView()
    }
    
    func deleteRecipe() {
        guard let recipeId = Int(recipe.id) else { return }
        let request = RequestWrapper.customRequest(
            method: .DELETE,
            path: .RECIPE_DETAIL(recipeId: recipeId),
            headerFields: [
                HeaderField.accept(value: .JSON),
                HeaderField.ocsRequest(value: true)
            ]
        )
        sendRequest(request)
        if let recipeIdInt = Int(recipe.id) {
            mainViewModel.deleteRecipe(withId: recipeIdInt, categoryName: recipe.recipeCategory)
        }
        dismissEditView()
    }
    
    func sendRequest(_ request: RequestWrapper) {
        Task {
            guard let apiController = mainViewModel.apiController else { return }
            let (data, _): (Data?, Error?) = await apiController.sendDataRequest(request)
            guard let data = data else { return }
            do {
                let error = try JSONDecoder().decode(ServerMessage.self, from: data)
                // TODO: Better error handling (Show error to user!)
            } catch {
                
            }
        }
    }
    
    func dismissEditView() {
        Task {
            await mainViewModel.loadCategoryList(needsUpdate: true)
            await mainViewModel.loadRecipeList(categoryName: recipe.recipeCategory, needsUpdate: true)
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
                    self.alertAction = {}
                    self.presentAlert = true
                }
            } catch {
                print("Error")
            }
        }
    }
}
