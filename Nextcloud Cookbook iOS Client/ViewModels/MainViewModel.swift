//
//  MainViewModel.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 06.09.23.
//

import Foundation
import SwiftUI
import UIKit


@MainActor class MainViewModel: ObservableObject {
    @AppStorage("authString") var authString = ""
    @AppStorage("serverAddress") var serverAdress = ""
    let api: CookbookApi.Type
    
    @Published var categories: [Category] = []
    @Published var recipes: [String: [Recipe]] = [:]
    @Published var recipeDetails: [Int: RecipeDetail] = [:]
    private var imageCache: [Int: RecipeImage] = [:]
    private var requestQueue: [RequestWrapper] = []
    private var serverConnection: Bool = false
    
    let dataStore: DataStore
    
    
    init(apiVersion api: CookbookApi.Type = CookbookApiV1.self) {
        print("Created MainViewModel")
        self.api = api
        self.dataStore = DataStore()
    }
    
    /// Try to load the category list from store or the server.
    /// - Parameters
    ///     - needsUpdate: If true, the recipe will be loaded from the server directly, otherwise it will be loaded from store first.
    /*func loadCategoryList(needsUpdate: Bool = false) async {
        if let categoryList: [Category] = await loadObject(
            localPath: "categories.data",
            networkPath: .CATEGORIES,
            needsUpdate: needsUpdate
        ) {
            self.categories = categoryList
        }
        print(self.categories)
    }*/
    
    func loadCategories() async {
        let (categories, _) = await api.getCategories(
            from: serverAdress,
            auth: authString
        )
        if let categories = categories {
            self.categories = categories
            await saveLocal(categories, path: "categories.data")
            serverConnection = true
        } else {
            if let categories: [Category] = await loadLocal(path: "categories.data") {
                self.categories = categories
            }
            serverConnection = false
        }
    }
    
    /// Try to load the recipe list from store or the server.
    /// - Warning: The category named '\*' is translated into '\_' for network calls and storage requests in this function. This is necessary for the nextcloud cookbook api.
    /// - Parameters
    ///     - categoryName: The name of the category containing the requested list of recipes.
    ///     - needsUpdate: If true, the recipe will be loaded from the server directly, otherwise it will be loaded from store first.
    /*func loadRecipeList(categoryName: String, needsUpdate: Bool = false) async {
        let categoryString = categoryName == "*" ? "_" : categoryName
        if let recipeList: [Recipe] = await loadObject(
            localPath: "category_\(categoryString).data",
            networkPath: .RECIPE_LIST(categoryName: categoryString),
            needsUpdate: needsUpdate
        ) {
            recipes[categoryName] = recipeList
            print(recipeList)
        }
        
    }*/
    func getCategory(named name: String) async {
        let categoryString = name == "*" ? "_" : name
        let (recipes, _) = await api.getCategory(
            from: serverAdress,
            auth: authString,
            named: name
        )
        if let recipes = recipes {
            self.recipes[name] = recipes
        } else {
            if let recipes: [Recipe] = await loadLocal(path: "category_\(categoryString).data") {
                self.recipes[name] = recipes
            }
        }
    }
    
    /*func getAllRecipes() async -> [Recipe] {
        var allRecipes: [Recipe] = []
        for category in categories {
            await loadRecipeList(categoryName: category.name)
            if let recipeArray = recipes[category.name] {
                allRecipes.append(contentsOf: recipeArray)
            }
        }
        return allRecipes.sorted(by: {
            $0.name < $1.name
        })
    }*/
    func getRecipes() async -> [Recipe] {
        let (recipes, error) = await api.getRecipes(
            from: serverAdress,
            auth: authString
        )
        if let recipes = recipes {
            return recipes
        } else if let error = error {
            print(error)
        }
        var allRecipes: [Recipe] = []
        for category in categories {
            if let recipeArray = self.recipes[category.name] {
                allRecipes.append(contentsOf: recipeArray)
            }
        }
        return allRecipes.sorted(by: {
            $0.name < $1.name
        })
    }
    
    /// Try to load the recipe details from cache. If not found, try to load from store or the server.
    /// - Parameters
    ///     - recipeId: The id of the recipe.
    ///     - needsUpdate: If true, the recipe will be loaded from the server directly, otherwise it will be loaded from cache/store first.
    /// - Returns: RecipeDetail struct. If not found locally, and unable to load from server, a RecipeDetail struct containing an error message.
    /*func loadRecipeDetail(recipeId: Int, needsUpdate: Bool = false) async -> RecipeDetail {
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
        return RecipeDetail.error
    }*/
    func getRecipe(id: Int) async -> RecipeDetail {
        let (recipe, error) = await api.getRecipe(
            from: serverAdress,
            auth: authString,
            id: id
        )
        if let recipe = recipe {
            return recipe
        } else if let error = error {
            print(error)
        }
        guard let recipe: RecipeDetail = await loadLocal(path: "recipe\(id).data") else {
            return RecipeDetail.error
        }
        return recipe
    }
    
    func downloadAllRecipes() async {
        for category in categories {
            await getCategory(named: category.name)
            guard let recipeList = recipes[category.name] else { continue }
            for recipe in recipeList {
                let recipeDetail = await getRecipe(id: recipe.recipe_id)
                await saveLocal(recipeDetail, path: "recipe\(recipe.recipe_id).data")
                
                let thumbnail = await getImage(id: recipe.recipe_id, size: .THUMB, needsUpdate: true)
                guard let thumbnail = thumbnail else { continue }
                guard let thumbnailData = thumbnail.pngData() else { continue }
                await saveLocal(thumbnailData.base64EncodedString(), path: "image\(recipe.recipe_id)_thumb")
                
                let image = await getImage(id: recipe.recipe_id, size: .FULL, needsUpdate: true)
                guard let image = image else { continue }
                guard let imageData = image.pngData() else { continue }
                await saveLocal(imageData.base64EncodedString(), path: "image\(recipe.recipe_id)_full")
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
    /*func loadImage(recipeId: Int, thumb: Bool, needsUpdate: Bool = false) async -> UIImage? {
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
    }*/
    func getImage(id: Int, size: RecipeImage.RecipeImageSize, needsUpdate: Bool) async -> UIImage? {
        if !needsUpdate, let image = await imageFromStore(id: id, size: size) {
            return image
        }
        let (image, _) = await api.getImage(
            from: serverAdress,
            auth: authString,
            id: id,
            size: size
        )
        if let image = image { return image }
        return await imageFromStore(id: id, size: size)
    }
    
    /*func getKeywords() async -> [String] {
        if let keywords: [RecipeKeyword] = await self.loadObject(
            localPath: "keywords.data",
            networkPath: .KEYWORDS,
            needsUpdate: true
        ) {
            return keywords.map { $0.name }
        }
        return []
    }*/
    func getKeywords() async -> [String] {
        let (tags, error) = await api.getTags(
            from: serverAdress,
            auth: authString
        )
        if let tags = tags {
            return tags
        } else if let error = error {
            print(error)
        }
        if let keywords: [String] = await loadLocal(path: "keywords.data") {
            return keywords
        }
        return []
    }
    
    func deleteAllData() {
        if dataStore.clearAll() {
            self.categories = []
            self.recipes = [:]
            self.imageCache = [:]
            self.recipeDetails = [:]
            self.requestQueue = []
        }
    }
    
    /*func deleteRecipe(withId id: Int, categoryName: String) async -> RequestAlert {
        let request = RequestWrapper.customRequest(
            method: .DELETE,
            path: .RECIPE_DETAIL(recipeId: id),
            headerFields: [
                HeaderField.accept(value: .JSON),
                HeaderField.ocsRequest(value: true)
            ]
        )
        
        let path = "recipe\(id).data"
        dataStore.delete(path: path)
        if recipes[categoryName] != nil {
            recipes[categoryName]!.removeAll(where: { recipe in
                recipe.recipe_id == id ? true : false
            })
            recipeDetails.removeValue(forKey: id)
        }
        if await sendRequest(request) {
            return .REQUEST_SUCCESS
        } else {
            requestQueue.append(request)
            return .REQUEST_DELAYED
        }
    }*/
    func deleteRecipe(withId id: Int, categoryName: String) async -> RequestAlert {
        let (error) = await api.deleteRecipe(
            from: serverAdress,
            auth: authString,
            id: id
        )
        
        if let error = error {
            return .REQUEST_DROPPED
        }
        let path = "recipe\(id).data"
        dataStore.delete(path: path)
        if recipes[categoryName] != nil {
            recipes[categoryName]!.removeAll(where: { recipe in
                recipe.recipe_id == id ? true : false
            })
            recipeDetails.removeValue(forKey: id)
        }
        return .REQUEST_SUCCESS
    }
    
    /*func checkServerConnection() async -> Bool {
        guard let apiController = apiController else { return false }
        let req = RequestWrapper.customRequest(
            method: .GET,
            path: .CONFIG,
            headerFields: [
                .ocsRequest(value: true),
                .accept(value: .JSON)
            ]
        )
        if let error = await apiController.sendRequest(req) {
            return false
        }
        return true
    }*/
    func checkServerConnection() async -> Bool {
        let (categories, _) = await api.getCategories(
            from: serverAdress,
            auth: authString
        )
        if let categories = categories {
            self.categories = categories
            await saveLocal(categories, path: "categories.data")
            return true
        }
        return false
    }
    
    /*func uploadRecipe(recipeDetail: RecipeDetail, createNew: Bool) async -> RequestAlert {
        var path: RequestPath? = nil
        if createNew {
            path = .NEW_RECIPE
        } else if let recipeId = Int(recipeDetail.id) {
            path = .RECIPE_DETAIL(recipeId: recipeId)
        }
        
        guard let path = path else { return .REQUEST_DROPPED }
        
        let request = RequestWrapper.customRequest(
            method: createNew ? .POST : .PUT,
            path: path,
            headerFields: [
                HeaderField.accept(value: .JSON),
                HeaderField.ocsRequest(value: true),
                HeaderField.contentType(value: .JSON)
            ],
            body: JSONEncoder.safeEncode(recipeDetail)
        )
        
        if await sendRequest(request) {
            return .REQUEST_SUCCESS
        } else {
            requestQueue.append(request)
            return .REQUEST_DELAYED
        }
    }*/
    func uploadRecipe(recipeDetail: RecipeDetail, createNew: Bool) async -> RequestAlert {
        let error = await api.createRecipe(
            from: serverAdress,
            auth: authString,
            recipe: recipeDetail
        )
        
        if let error = error {
            return .REQUEST_DROPPED
        }
        return .REQUEST_SUCCESS
    }
    
    /*func sendRequest(_ request: RequestWrapper) async -> Bool {
        guard let apiController = apiController else { return false }
        let (data, _): (Data?, Error?) = await apiController.sendDataRequest(request)
        guard let data = data else { return false }
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
            if let recipeId = json as? Int {
                return true
            } else if let message = json as? [String : Any] {
                print("Server message: ", message["msg"] ?? "-")
                return false
            }
            // TODO: Better error handling (Show error to user!)
        } catch {
            print("Could not decode server response")
        }
        return false
    }*/
}




extension MainViewModel {
    func loadLocal<T: Codable>(path: String) async -> T? {
        do {
            return try await dataStore.load(fromPath: path)
        } catch (let error) {
            print(error)
            return nil
        }
    }
    
    func saveLocal<T: Codable>(_ object: T, path: String) async {
        guard let data = JSONEncoder.safeEncode(object) else { return }
        await dataStore.save(data: data, toPath: path)
    }
    /*private func loadObject<T: Codable>(localPath: String, networkPath: RequestPath, needsUpdate: Bool = false) async -> T? {
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
        } catch {
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
    */
    private func imageFromStore(id: Int, size: RecipeImage.RecipeImageSize) async -> UIImage? {
        do {
            let localPath = "image\(id)_\(size == .FULL ? "full" : "thumb")"
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


