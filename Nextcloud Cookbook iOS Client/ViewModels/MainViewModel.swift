//
//  MainViewModel.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 06.09.23.
//

import Foundation
import UIKit

@MainActor class MainViewModel: ObservableObject {
    @Published var categories: [Category] = []
    @Published var recipes: [String: [Recipe]] = [:]
    private var recipeDetails: [Int: RecipeDetail] = [:]
    private var imageCache: [Int: RecipeImage] = [:]
    
    let dataStore: DataStore
    let networkController: NetworkController
    
    /// The path of an image in storage
    private var localImagePath: (Int, Bool) -> (String) = { recipeId, full in
        return "image\(recipeId)_\(full ? "full" : "thumb")"
    }
    
    /// The path of an image on the server
    private var networkImagePath: (Int, Bool) -> (String) = { recipeId, full in
        return "recipes/\(recipeId)/image?size=\(full ? "full" : "thumb")"
    }
    
    init() {
        self.networkController = NetworkController()
        self.dataStore = DataStore()
    }
    
    /// Try to load the category list from store or the server.
    /// - Parameters
    ///     - needsUpdate: If true, the recipe will be loaded from the server directly, otherwise it will be loaded from store first.
    func loadCategoryList(needsUpdate: Bool = false) async {
        if let categoryList: [Category] = await load(localPath: "categories.data", networkPath: "categories", needsUpdate: needsUpdate) {
            self.categories = categoryList
        }
    }
    
    /// Try to load the recipe list from store or the server.
    /// - Parameters
    ///     - categoryName: The name of the category containing the requested list of recipes.
    ///     - needsUpdate: If true, the recipe will be loaded from the server directly, otherwise it will be loaded from store first.
    func loadRecipeList(categoryName: String, needsUpdate: Bool = false) async {
        if let recipeList: [Recipe] = await load(localPath: "category_\(categoryName).data", networkPath: "category/\(categoryName)", needsUpdate: needsUpdate) {
            recipes[categoryName] = recipeList
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
        if let recipeDetail: RecipeDetail = await load(localPath: "recipe\(recipeId).data", networkPath: "recipes/\(recipeId)", needsUpdate: needsUpdate) {
            recipeDetails[recipeId] = recipeDetail
            return recipeDetail
        }
        return RecipeDetail.error()
    }
    
    
    /// Try to load the recipe image from cache. If not found, try to load from store or the server.
    /// - Parameters
    ///     - recipeId: The id of a recipe.
    ///     - full: If true, load the full resolution image. Otherwise, load a thumbnail-sized image.
    ///     - needsUpdate: Determines wether the image should be loaded directly from the server, or if it should be loaded from cache/store first.
    /// - Returns: The image if found locally or on the server, otherwise nil.
    func loadImage(recipeId: Int, full: Bool, needsUpdate: Bool = false) async -> UIImage? {
        print("loadImage(recipeId: \(recipeId), full: \(full), needsUpdate: \(needsUpdate)")
        // If the image needs an update, request it from the server and overwrite the stored image
        if needsUpdate {
            if let data = await imageDataFromServer(recipeId: recipeId, full: full) {
                guard let image = UIImage(data: data) else { return nil }
                await dataStore.save(data: data.base64EncodedString(), toPath: localImagePath(recipeId, full))
                imageToCache(image: image, recipeId: recipeId, full: full)
                return image
            }
        }
        // Try to load image from cache
        print("Attempting to load image from cache ...")
        if imageCache[recipeId] != nil {
            print("Image found in cache.")
            return imageFromCache(recipeId: recipeId, full: full)
        }
        // Try to load from store
        print("Attempting to load image from local storage ...")
        if let image = await imageFromStore(recipeId: recipeId, full: full) {
            print("Image found in local storage.")
            imageToCache(image: image, recipeId: recipeId, full: full)
            return image
        }
        // Try to load from the server. Store if successfull.
        print("Attempting to load image from server ...")
        if let data = await imageDataFromServer(recipeId: recipeId, full: full) {
            print("Image data received.")
            imageCache[recipeId] = RecipeImage() // Create empty RecipeImage for each recipe even if no image found, so that further server requests are only sent if explicitly requested.
            guard let image = UIImage(data: data) else { return nil }
            await dataStore.save(data: data.base64EncodedString(), toPath: localImagePath(recipeId, full))
            imageToCache(image: image, recipeId: recipeId, full: full)
            return image
        }
        return nil
    }
}




extension MainViewModel {
    private func load<D: Codable>(localPath: String, networkPath: String, needsUpdate: Bool = false) async -> D? {
        do {
            if !needsUpdate, let data: D = try await dataStore.load(fromPath: localPath) {
                print("Data found locally.")
                return data
            } else {
                let request = RequestWrapper(method: .GET, path: networkPath)
                let (data, error): (D?, Error?) = await networkController.sendDataRequest(request)
                print(error as Any)
                if let data = data {
                    try await dataStore.save(data: data, toPath: localPath)
                }
                return data
            }
        }catch {
           print("An unknown error occurred.")
        }
        return nil
    }
    
    private func imageToCache(image: UIImage, recipeId: Int, full: Bool) {
        if imageCache[recipeId] == nil {
            imageCache[recipeId] = RecipeImage()
        }
        if full {
            imageCache[recipeId]!.full = image
        } else {
            imageCache[recipeId]!.thumb = image
        }
    }
    
    private func imageFromCache(recipeId: Int, full: Bool) -> UIImage? {
        if imageCache[recipeId] != nil {
            if full {
                return imageCache[recipeId]!.full
            } else {
                return imageCache[recipeId]!.thumb
            }
        }
        return nil
    }
    
    private func imageFromStore(recipeId: Int, full: Bool) async -> UIImage? {
        do {
            let localPath = localImagePath(recipeId, full)
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
    
    private func imageDataFromServer(recipeId: Int, full: Bool) async -> Data? {
        do {
            let networkPath = networkImagePath(recipeId, full)
            let request = RequestWrapper(method: .GET, path: networkPath, accept: .IMAGE)
            let (data, _): (Data?, Error?) = try await networkController.sendHTTPRequest(path: request.path, request)
            guard let data = data else {
                print("Error receiving or decoding data.")
                return nil
            }
            return data
        } catch {
            print("Could not load image from server.")
        }
        return nil
    }
}


