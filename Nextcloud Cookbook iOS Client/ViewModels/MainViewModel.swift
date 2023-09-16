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
    
    init() {
        self.networkController = NetworkController()
        self.dataStore = DataStore()
    }
    
    func loadCategoryList(needsUpdate: Bool = false) async {
        if let categoryList: [Category] = await load(localPath: "categories.data", networkPath: "categories", needsUpdate: needsUpdate) {
            self.categories = categoryList
        }
    }
    
    func loadRecipeList(categoryName: String, needsUpdate: Bool = false) async {
        if let recipeList: [Recipe] = await load(localPath: "category_\(categoryName).data", networkPath: "category/\(categoryName)", needsUpdate: needsUpdate) {
            recipes[categoryName] = recipeList
        }
    }
    
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
    
    func loadImage(recipeId: Int, full: Bool, needsUpdate: Bool = false) async -> UIImage? {
        print("loadImage(recipeId: \(recipeId), full: \(full)")
        
        // Check if image is in image cache
        if !needsUpdate, let recipeImage = imageCache[recipeId] {
            if full {
                if let fullImage = recipeImage.full {
                    return recipeImage.full
                }
            } else {
                return recipeImage.thumb
            }
        }
        
        // If image is not in image cache, request from local storage
        do {
            let localPath = "image\(recipeId)_\(full ? "full" : "thumb")"
            if !needsUpdate, let data: String = try await dataStore.load(fromPath: localPath) {
                print("Image data found locally. Decoding ...")
                guard let dataDecoded = Data(base64Encoded: data) else { return nil }
                print("Data to UIImage ...")
                let image = UIImage(data: dataDecoded)
                print("Done.")
                return image
            } else {
                // If image is not in local storage, request from server
                let networkPath = "recipes/\(recipeId)/image?size=full"
                let request = RequestWrapper(method: .GET, path: networkPath, accept: .IMAGE)
                let (data, error): (Data?, Error?) = try await networkController.sendHTTPRequest(path: request.path, request)
                guard let data = data else {
                    print("Error receiving or decoding data.")
                    print("Error Message: \n", error)
                    return nil
                }
                let image = UIImage(data: data)
                if image != nil {
                    print("Saving image loaclly ...")
                    try await dataStore.save(data: data.base64EncodedString(), toPath: localPath)
                }
                print("Done.")
                return image
            }
        }catch {
           print("An unknown error occurred.")
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
                print(error)
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
}


