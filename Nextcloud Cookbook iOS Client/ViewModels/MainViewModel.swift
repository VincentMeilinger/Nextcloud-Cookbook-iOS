//
//  MainViewModel.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 06.09.23.
//

import Foundation
import UIKit
import SwiftUI

@MainActor class MainViewModel: ObservableObject {
    @Published var categories: [Category] = []
    @Published var recipes: [String: [Recipe]] = [:]
    private var recipeDetails: [Int: RecipeDetail] = [:]
    private var imageCache: [Int: RecipeImage] = [:]
    
    let dataStore: DataStore
    var apiController: APIController? = nil
    
    /// The path of an image in storage
    private var localImagePath: (Int, Bool) -> (String) = { recipeId, thumb in
        return "image\(recipeId)_\(thumb ? "thumb" : "full")"
    }
    
    /// The path of an image on the server
    private var networkImagePath: (Int, Bool) -> (String) = { recipeId, thumb in
        return "recipes/\(recipeId)/image?size=\(thumb ? "thumb" : "full")"
    }
    
    init() {
        self.dataStore = DataStore()
    }
    
    /// Try to load the category list from store or the server.
    /// - Parameters
    ///     - needsUpdate: If true, the recipe will be loaded from the server directly, otherwise it will be loaded from store first.
    func loadCategoryList(needsUpdate: Bool = false) async {
        if let categoryList: [Category] = await loadObject(
            localPath: "categories.data",
            networkPath: .CATEGORIES,
            needsUpdate: needsUpdate
        ) {
            self.categories = categoryList
        }
        print(self.categories)
    }
    
    /// Try to load the recipe list from store or the server.
    /// - Warning: The category named '\*' is translated into '\_' for network calls and storage requests in this function. This is necessary for the nextcloud cookbook api.
    /// - Parameters
    ///     - categoryName: The name of the category containing the requested list of recipes.
    ///     - needsUpdate: If true, the recipe will be loaded from the server directly, otherwise it will be loaded from store first.
    func loadRecipeList(categoryName: String, needsUpdate: Bool = false) async {
        let categoryString = categoryName == "*" ? "_" : categoryName
        if let recipeList: [Recipe] = await loadObject(
            localPath: "category_\(categoryString).data",
            networkPath: .RECIPE_LIST(categoryName: categoryString),
            needsUpdate: needsUpdate
        ) {
            recipes[categoryName] = recipeList
            print(recipeList)
        }
        
    }
    
    /// Try to load the recipe details from cache. If not found, try to load from store or the server.
    /// - Parameters
    ///     - recipeId: The id of the recipe.
    ///     - needsUpdate: If true, the recipe will be loaded from the server directly, otherwise it will be loaded from cache/store first.
    /// - Returns: RecipeDetail struct. If not found locally, and unable to load from server, a RecipeDetail struct containing an error message.
    func loadRecipeDetail(recipeId: Int, needsUpdate: Bool = false) async -> RecipeDetail {
        if !needsUpdate {
            if let recipeDetail = recipeDetails[recipeId] {
                return recipeDetail
            }
        }
        if let recipeDetail: RecipeDetail = await loadObject(
            localPath: "recipe\(recipeId).data",
            networkPath: .RECIPE_DETAIL(recipeId: recipeId),
            needsUpdate: needsUpdate
        ) {
            recipeDetails[recipeId] = recipeDetail
            return recipeDetail
        }
        return RecipeDetail.error()
    }
    
    func downloadAllRecipes() async {
        for category in categories {
            await loadRecipeList(categoryName: category.name, needsUpdate: true)
            guard let recipeList = recipes[category.name] else { continue }
            for recipe in recipeList {
                let _ = await loadRecipeDetail(recipeId: recipe.recipe_id, needsUpdate: true)
                let _ = await loadImage(recipeId: recipe.recipe_id, thumb: true)
            }
        }
    }
    
    /// Check if recipeDetail is stored locally, either in cache or on disk
    /// - Parameters
    ///     - recipeId: The id of a recipe.
    /// - Returns: True if the recipeDetail is stored, otherwise false
    func recipeDetailExists(recipeId: Int) -> Bool {
        if recipeDetails[recipeId] != nil {
            return true
        } else if (dataStore.recipeDetailExists(recipeId: recipeId)) {
            return true
        }
        return false
    }
    
    
    /// Try to load the recipe image from cache. If not found, try to load from store or the server.
    /// - Parameters
    ///     - recipeId: The id of a recipe.
    ///     - full: If true, load the full resolution image. Otherwise, load a thumbnail-sized image.
    ///     - needsUpdate: Determines wether the image should be loaded directly from the server, or if it should be loaded from cache/store first.
    /// - Returns: The image if found locally or on the server, otherwise nil.
    func loadImage(recipeId: Int, thumb: Bool, needsUpdate: Bool = false) async -> UIImage? {
        print("loadImage(recipeId: \(recipeId), thumb: \(thumb), needsUpdate: \(needsUpdate))")
        // If the image needs an update, request it from the server and overwrite the stored image
        if needsUpdate {
            guard let apiController = apiController else { return nil }
            if let data = await apiController.imageDataFromServer(recipeId: recipeId, thumb: thumb) {
                guard let image = UIImage(data: data) else {
                    imageCache[recipeId] = RecipeImage(imageExists: false)
                    return nil
                }
                await dataStore.save(data: data.base64EncodedString(), toPath: localImagePath(recipeId, thumb))
                imageToCache(image: image, recipeId: recipeId, thumb: thumb)
                return image
            } else {
                imageCache[recipeId] = RecipeImage(imageExists: false)
                return nil
            }
        }
        
        // Check imageExists flag to detect if we attempted to load a non-existing image before.
        // This allows us to avoid sending requests to the server if we already know the recipe has no image.
        if imageCache[recipeId] != nil {
            guard imageCache[recipeId]!.imageExists else { return nil }
        }
        
        // Try to load image from cache
        print("Attempting to load image from cache ...")
        if let image = imageFromCache(recipeId: recipeId, thumb: thumb) {
            print("Image found in cache.")
            return image
        }
        
        // Try to load from store
        print("Attempting to load image from local storage ...")
        if let image = await imageFromStore(recipeId: recipeId, thumb: thumb) {
            print("Image found in local storage.")
            imageToCache(image: image, recipeId: recipeId, thumb: thumb)
            return image
        }
        
        // Try to load from the server. Store if successfull.
        print("Attempting to load image from server ...")
        guard let apiController = apiController else { return nil }
        if let data = await apiController.imageDataFromServer(recipeId: recipeId, thumb: thumb) {
            print("Image data received.")
            // Create empty RecipeImage for each recipe even if no image found, so that further server requests are only sent if explicitly requested.
            guard let image = UIImage(data: data) else {
                imageCache[recipeId] = RecipeImage(imageExists: false)
                return nil
            }
            await dataStore.save(data: data.base64EncodedString(), toPath: localImagePath(recipeId, thumb))
            imageToCache(image: image, recipeId: recipeId, thumb: thumb)
            return image
        }
        imageCache[recipeId] = RecipeImage(imageExists: false)
        return nil
    }
    
    func getKeywords() async -> [String] {
        if let keywords: [RecipeKeyword] = await self.loadObject(
            localPath: "keywords.data",
            networkPath: .KEYWORDS,
            needsUpdate: true
        ) {
            return keywords.map { $0.name }
        }
        return []
    }
    
    func deleteAllData() {
        if dataStore.clearAll() {
            self.categories = []
            self.recipes = [:]
            self.imageCache = [:]
            self.recipeDetails = [:]
        }
    }
    
    func deleteRecipe(withId id: Int, categoryName: String) {
        let path = "recipe\(id).data"
        dataStore.delete(path: path)
        guard recipes[categoryName] != nil else { return }
        recipes[categoryName]!.removeAll(where: { recipe in
            recipe.recipe_id == id ? true : false
        })
        recipeDetails.removeValue(forKey: id)
    }
}




extension MainViewModel {
    private func loadObject<T: Codable>(localPath: String, networkPath: RequestPath, needsUpdate: Bool = false) async -> T? {
        do {
            if !needsUpdate, let data: T = try await dataStore.load(fromPath: localPath) {
                print("Data found locally.")
                return data
            } else {
                guard let apiController = apiController else { return nil }
                let request = RequestWrapper.jsonGetRequest(path: networkPath)
                let (data, error): (T?, Error?) = await apiController.sendDataRequest(request)
                print(error as Any)
                if let data = data {
                    await dataStore.save(data: data, toPath: localPath)
                }
                return data
            }
        }catch {
           print("An unknown error occurred.")
        }
        return nil
    }
    
    private func imageToCache(image: UIImage, recipeId: Int, thumb: Bool) {
        if imageCache[recipeId] == nil {
            imageCache[recipeId] = RecipeImage(imageExists: true)
        }
        if thumb {
            imageCache[recipeId]!.imageExists = true
            imageCache[recipeId]!.thumb = image
        } else {
            imageCache[recipeId]!.imageExists = true
            imageCache[recipeId]!.full = image
        }
    }
    
    private func imageFromCache(recipeId: Int, thumb: Bool) -> UIImage? {
        if imageCache[recipeId] != nil {
            if thumb {
                return imageCache[recipeId]!.thumb
            } else {
                return imageCache[recipeId]!.full
            }
        }
        return nil
    }
    
    private func imageFromStore(recipeId: Int, thumb: Bool) async -> UIImage? {
        do {
            let localPath = localImagePath(recipeId, thumb)
            if let data: String = try await dataStore.load(fromPath: localPath) {
                guard let dataDecoded = Data(base64Encoded: data) else { return nil }
                let image = UIImage(data: dataDecoded)
                return image
            }
        } catch {
            print("Could not find image in local storage.")
            return nil
        }
        return nil
    }
}


