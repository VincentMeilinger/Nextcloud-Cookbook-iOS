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
    @AppStorage("username") var userName = ""
    @AppStorage("token") var appToken = ""
    @AppStorage("serverAddress") var serverAdress = ""
    
    
    @Published var categories: [Category] = []
    @Published var recipes: [String: [Recipe]] = [:]
    @Published var recipeDetails: [Int: RecipeDetail] = [:]
    private var requestQueue: [RequestWrapper] = []
    
    private let api: CookbookApi.Type
    private let dataStore: DataStore
    
    init(apiVersion api: CookbookApi.Type = CookbookApiV1.self) {
        print("Created MainViewModel")
        self.api = api
        self.dataStore = DataStore()
        
        if authString == "" {
            let loginString = "\(userName):\(appToken)"
            let loginData = loginString.data(using: String.Encoding.utf8)!
            authString = loginData.base64EncodedString()
        }
    }
    
    enum FetchMode {
        case preferLocal, preferServer, onlyLocal, onlyServer
    }
    
    
    /**
     Asynchronously loads and updates the list of categories.

     This function attempts to fetch the list of categories from the server. If the server connection is successful, it updates the `categories` property in the `MainViewModel` instance and saves the categories locally. If the server connection fails, it attempts to load the categories from local storage.

     - Important: This function assumes that the server address, authentication string, and API have been properly configured in the `MainViewModel` instance.
    */
    func getCategories() async {
        let (categories, _) = await api.getCategories(
            from: serverAdress,
            auth: authString
        )
        if let categories = categories {
            self.categories = categories
            await saveLocal(categories, path: "categories.data")
        } else {
            // If there's no server connection, try loading categories from local storage
            if let categories: [Category] = await loadLocal(path: "categories.data") {
                self.categories = categories
            }
        }
    }
    
    
    /**
     Fetches recipes for a specified category from either the server or local storage.

     - Parameters:
       - name: The name of the category. Use "*" to fetch recipes without assigned categories.
       - needsUpdate: If true, recipes will be loaded from the server directly; otherwise, they will be loaded from local storage first.

     This function asynchronously retrieves recipes for the specified category from the server or local storage based on the provided parameters. If `needsUpdate` is true, the function fetches recipes from the server and updates the local storage. If `needsUpdate` is false, it attempts to load recipes from local storage.

     - Note: The category name "*" is used for all uncategorized recipes.

     - Important: This function assumes that the server address, authentication string, and API have been properly configured in the `MainViewModel` instance.
    */
    func getCategory(named name: String, fetchMode: FetchMode) async {
        func getLocal() async -> Bool {
            if let recipes: [Recipe] = await loadLocal(path: "category_\(categoryString).data") {
                self.recipes[name] = recipes
                return true
            }
            return false
        }
        
        func getServer() async -> Bool {
            let (recipes, _) = await api.getCategory(
                from: serverAdress,
                auth: authString,
                named: name
            )
            if let recipes = recipes {
                self.recipes[name] = recipes
                return true
            }
            return false
        }
        
        let categoryString = name == "*" ? "_" : name
        switch fetchMode {
        case .preferLocal:
            if await getLocal() { return }
            if await getServer() { return }
        case .preferServer:
            if await getServer() { return }
            if await getLocal() { return }
        case .onlyLocal:
            if await getLocal() { return }
        case .onlyServer:
            if await getServer() { return }
        }
    }
    
    /**
     Asynchronously retrieves all recipes either from the server or the locally cached data.

     This function attempts to fetch all recipes from the server using the provided `api`. If the server connection is successful, it returns the fetched recipes. If the server connection fails, it falls back to combining locally cached recipes from different categories.

     - Important: This function assumes that the server address, authentication string, and API have been properly configured in the `MainViewModel` instance, and categories have been previously loaded.

     Example usage:
     ```swift
     let recipes = await mainViewModel.getRecipes()
    */
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
    
    /**
     Asynchronously retrieves a recipe detail either from the server or locally cached data.

     This function attempts to fetch a recipe detail with the specified `id` from the server using the provided `api`. If the server connection is successful, it returns the fetched recipe detail. If the server connection fails, it falls back to loading the recipe detail from local storage.

     - Important: This function assumes that the server address, authentication string, and API have been properly configured in the `MainViewModel` instance.

     - Parameters:
       - id: The identifier of the recipe to retrieve.

     Example usage:
     ```swift
     let recipeDetail = await mainViewModel.getRecipe(id: 123)
    */
    func getRecipe(id: Int, fetchMode: FetchMode) async -> RecipeDetail {
        func getLocal() async -> RecipeDetail? {
            if let recipe: RecipeDetail = await loadLocal(path: "recipe\(id).data") {
                return recipe
            }
            return nil
        }
        
        func getServer() async -> RecipeDetail? {
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
            return nil
        }
        
        switch fetchMode {
        case .preferLocal:
            if let recipe = await getLocal() { return recipe }
            if let recipe = await getServer() { return recipe }
        case .preferServer:
            if let recipe = await getServer() { return recipe }
            if let recipe = await getLocal() { return recipe }
        case .onlyLocal:
            if let recipe = await getLocal() { return recipe }
        case .onlyServer:
            if let recipe = await getServer() { return recipe }
        }
        return .error
    }
    
    
    
    
    /**
     Asynchronously downloads and saves details, thumbnails, and full images for all recipes.

     This function iterates through all loaded categories, fetches and updates the recipes from the server, and then downloads and saves details, thumbnails, and full images for each recipe.

     - Important: This function assumes that the server address, authentication string, and API have been properly configured in the `MainViewModel` instance.

     Example usage:
     ```swift
     await mainViewModel.downloadAllRecipes()
    */
    func downloadAllRecipes() async {
        for category in categories {
            await getCategory(named: category.name, fetchMode: .onlyServer)
            guard let recipeList = recipes[category.name] else { continue }
            for recipe in recipeList {
                let recipeDetail = await getRecipe(id: recipe.recipe_id, fetchMode: .onlyServer)
                await saveLocal(recipeDetail, path: "recipe\(recipe.recipe_id).data")
                
                let thumbnail = await getImage(id: recipe.recipe_id, size: .THUMB, fetchMode: .onlyServer)
                guard let thumbnail = thumbnail else { continue }
                guard let thumbnailData = thumbnail.pngData() else { continue }
                await saveLocal(thumbnailData.base64EncodedString(), path: "image\(recipe.recipe_id)_thumb")
                
                let image = await getImage(id: recipe.recipe_id, size: .FULL, fetchMode: .onlyServer)
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
    
    /**
     Asynchronously retrieves and returns an image for a recipe with the specified ID and size.

     This function attempts to fetch an image for a recipe with the specified `id` and `size` from the server using the provided `api`. If the server connection is successful, it returns the fetched image. If the server connection fails or `needsUpdate` is false, it attempts to load the image from local storage.

     - Important: This function assumes that the server address, authentication string, and API have been properly configured in the `MainViewModel` instance.

     - Parameters:
       - id: The identifier of the recipe associated with the image.
       - size: The size of the desired image (thumbnail or full).
       - needsUpdate: If true, the image will be loaded from the server directly; otherwise, it will be loaded from local storage.

     Example usage:
     ```swift
     let thumbnail = await mainViewModel.getImage(id: 123, size: .THUMB, needsUpdate: true)
    */
    func getImage(id: Int, size: RecipeImage.RecipeImageSize, fetchMode: FetchMode) async -> UIImage? {
        func getLocal() async -> UIImage? {
            return await imageFromStore(id: id, size: size)
        }
        
        func getServer() async -> UIImage? {
            let (image, _) = await api.getImage(
                from: serverAdress,
                auth: authString,
                id: id,
                size: size
            )
            if let image = image { return image }
            return nil
        }
        
        switch fetchMode {
        case .preferLocal:
            if let image = await getLocal() { return image }
            if let image = await getServer() { return image }
        case .preferServer:
            if let image = await getServer() { return image }
            if let image = await getLocal() { return image }
        case .onlyLocal:
            if let image = await getLocal() { return image }
        case .onlyServer:
            if let image = await getServer() { return image }
        }
        return nil
    }
    
    /**
     Asynchronously retrieves and returns a list of keywords (tags).

     This function attempts to fetch a list of keywords from the server using the provided `api`. If the server connection is successful, it returns the fetched keywords. If the server connection fails, it attempts to load the keywords from local storage.

     - Important: This function assumes that the server address, authentication string, and API have been properly configured in the `MainViewModel` instance.

     Example usage:
     ```swift
     let keywords = await mainViewModel.getKeywords()
    */
    func getKeywords(fetchMode: FetchMode) async -> [String] {
        func getLocal() async -> [String]? {
            return await loadLocal(path: "keywords.data")
        }
        
        func getServer() async -> [String]? {
            let (tags, _) = await api.getTags(
                from: serverAdress,
                auth: authString
            )
            return tags
        }

        switch fetchMode {
        case .preferLocal:
            if let keywords = await getLocal() { return keywords }
            if let keywords = await getServer() { return keywords }
        case .preferServer:
            if let keywords = await getServer() { return keywords }
            if let keywords = await getLocal() { return keywords }
        case .onlyLocal:
            if let keywords = await getLocal() { return keywords }
        case .onlyServer:
            if let keywords = await getServer() { return keywords }
        }
        return []
    }
    
    func deleteAllData() {
        if dataStore.clearAll() {
            self.categories = []
            self.recipes = [:]
            self.recipeDetails = [:]
            self.requestQueue = []
        }
    }
    
    /**
     Asynchronously deletes a recipe with the specified ID from the server and local storage.

     This function attempts to delete a recipe with the specified `id` from the server using the provided `api`. If the server connection is successful, it proceeds to delete the local copy of the recipe and its details. If the server connection fails, it returns `RequestAlert.REQUEST_DROPPED`.

     - Important: This function assumes that the server address, authentication string, and API have been properly configured in the `MainViewModel` instance.

     - Parameters:
       - id: The identifier of the recipe to delete.
       - categoryName: The name of the category to which the recipe belongs.

     Example usage:
     ```swift
     let requestResult = await mainViewModel.deleteRecipe(withId: 123, categoryName: "Desserts")
    */
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
    
    /**
     Asynchronously checks the server connection by attempting to fetch categories.

     This function attempts to fetch categories from the server using the provided `api` to check the server connection status. If the server connection is successful, it updates the `categories` property in the `MainViewModel` instance and saves the categories locally. If the server connection fails, it returns `false`.

     - Important: This function assumes that the server address, authentication string, and API have been properly configured in the `MainViewModel` instance.

     Example usage:
     ```swift
     let isConnected = await mainViewModel.checkServerConnection()
    */
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
    
    /**
     Asynchronously uploads a recipe to the server.

     This function attempts to create or update a recipe on the server using the provided `api`. If the server connection is successful, it uploads the provided `recipeDetail`. If the server connection fails, it returns `RequestAlert.REQUEST_DROPPED`.

     - Important: This function assumes that the server address, authentication string, and API have been properly configured in the `MainViewModel` instance.

     - Parameters:
       - recipeDetail: The detailed information of the recipe to upload.
       - createNew: If true, creates a new recipe on the server; otherwise, updates an existing one.

     Example usage:
     ```swift
     let uploadResult = await mainViewModel.uploadRecipe(recipeDetail: myRecipeDetail, createNew: true)
    */
    func uploadRecipe(recipeDetail: RecipeDetail, createNew: Bool) async -> RequestAlert {
        var error: NetworkError? = nil
        if createNew {
            error = await api.createRecipe(
                from: serverAdress,
                auth: authString,
                recipe: recipeDetail
            )
        } else {
            error = await api.updateRecipe(
                from: serverAdress,
                auth: authString,
                recipe: recipeDetail
            )
        }
        if let error = error {
            return .REQUEST_DROPPED
        }
        return .REQUEST_SUCCESS
    }
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


