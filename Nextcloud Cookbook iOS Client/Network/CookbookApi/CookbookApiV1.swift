//
//  CookbookApiV1.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 16.11.23.
//

import Foundation
import UIKit


class CookbookApiV1: CookbookApi {
    static let basePath: String = "/index.php/apps/cookbook/api/v1"
    
    static func importRecipe(auth: String, data: Data) async -> (RecipeDetail?, NetworkError?) {
        let request = ApiRequest(
            path: basePath + "/import",
            method: .POST,
            authString: auth,
            headerFields: [HeaderField.ocsRequest(value: true), HeaderField.accept(value: .JSON), HeaderField.contentType(value: .JSON)]
        )
        
        let (data, error) = await request.send()
        guard let data = data else { return (nil, error) }
        return (JSONDecoder.safeDecode(data), nil)
    }
    
    static func getImage(auth: String, id: Int, size: RecipeImage.RecipeImageSize) async -> (UIImage?, NetworkError?) {
        let imageSize = (size == .FULL ? "full" : "thumb")
        let request = ApiRequest(
            path: basePath + "/recipes/\(id)/image?size=\(imageSize)",
            method: .GET,
            authString: auth,
            headerFields: [HeaderField.ocsRequest(value: true), HeaderField.accept(value: .IMAGE)]
        )
        
        let (data, error) = await request.send()
        guard let data = data else { return (nil, error) }
        return (UIImage(data: data), error)
    }
    
    static func getRecipes(auth: String) async -> ([Recipe]?, NetworkError?) {
        let request = ApiRequest(
            path: basePath + "/recipes",
            method: .GET,
            authString: auth,
            headerFields: [HeaderField.ocsRequest(value: true), HeaderField.accept(value: .JSON)]
        )
        
        let (data, error) = await request.send()
        guard let data = data else { return (nil, error) }
        return (JSONDecoder.safeDecode(data), nil)
    }
    
    static func createRecipe(auth: String, recipe: RecipeDetail) async -> (NetworkError?) {
        guard let recipeData = JSONEncoder.safeEncode(recipe) else {
            return .dataError
        }
        
        let request = ApiRequest(
            path: basePath + "/recipes",
            method: .POST,
            authString: auth,
            headerFields: [HeaderField.ocsRequest(value: true), HeaderField.accept(value: .JSON), HeaderField.contentType(value: .JSON)],
            body: recipeData
        )
        
        let (data, error) = await request.send()
        guard let data = data else { return (error) }
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
            if let id = json as? Int {
                return nil
            } else if let dict = json as? [String: Any] {
                return .serverError
            }
        } catch {
            return .decodingFailed
        }
        return nil
    }
    
    static func getRecipe(auth: String, id: Int) async -> (RecipeDetail?, NetworkError?) {
        let request = ApiRequest(
            path: basePath + "/recipes/\(id)",
            method: .GET,
            authString: auth,
            headerFields: [HeaderField.ocsRequest(value: true), HeaderField.accept(value: .JSON)]
        )
        
        let (data, error) = await request.send()
        guard let data = data else { return (nil, error) }
        return (JSONDecoder.safeDecode(data), nil)
    }
    
    static func updateRecipe(auth: String, recipe: RecipeDetail) async -> (NetworkError?) {
        guard let recipeData = JSONEncoder.safeEncode(recipe) else {
            return .dataError
        }
        let request = ApiRequest(
            path: basePath + "/recipes/\(recipe.id)",
            method: .PUT,
            authString: auth,
            headerFields: [HeaderField.ocsRequest(value: true), HeaderField.accept(value: .JSON), HeaderField.contentType(value: .JSON)],
            body: recipeData
        )
        
        let (data, error) = await request.send()
        guard let data = data else { return (error) }
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
            if let id = json as? Int {
                return nil
            } else if let dict = json as? [String: Any] {
                return .serverError
            }
        } catch {
            return .decodingFailed
        }
        return nil
    }
    
    static func deleteRecipe(auth: String, id: Int) async -> (NetworkError?) {
        let request = ApiRequest(
            path: basePath + "/recipes/\(id)",
            method: .DELETE,
            authString: auth,
            headerFields: [HeaderField.ocsRequest(value: true), HeaderField.accept(value: .JSON)]
        )
        
        let (data, error) = await request.send()
        guard let data = data else { return (error) }
        return nil
    }
    
    static func getCategories(auth: String) async -> ([Category]?, NetworkError?) {
        let request = ApiRequest(
            path: basePath + "/categories",
            method: .GET,
            authString: auth,
            headerFields: [HeaderField.ocsRequest(value: true), HeaderField.accept(value: .JSON)]
        )
        
        let (data, error) = await request.send()
        guard let data = data else { return (nil, error) }
        return (JSONDecoder.safeDecode(data), nil)
    }
    
    static func getCategory(auth: String, named categoryName: String) async -> ([Recipe]?, NetworkError?) {
        let request = ApiRequest(
            path: basePath + "/category/\(categoryName)",
            method: .GET,
            authString: auth,
            headerFields: [HeaderField.ocsRequest(value: true), HeaderField.accept(value: .JSON)]
        )
        
        let (data, error) = await request.send()
        guard let data = data else { return (nil, error) }
        return (JSONDecoder.safeDecode(data), nil)
    }
    
    static func renameCategory(auth: String, named categoryName: String, newName: String) async -> (NetworkError?) {
        let request = ApiRequest(
            path: basePath + "/category/\(categoryName)",
            method: .PUT,
            authString: auth,
            headerFields: [HeaderField.ocsRequest(value: true), HeaderField.accept(value: .JSON)]
        )
        
        let (data, error) = await request.send()
        guard let data = data else { return (error) }
        return nil
    }
    
    static func getTags(auth: String) async -> ([RecipeKeyword]?, NetworkError?) {
        let request = ApiRequest(
            path: basePath + "/keywords",
            method: .GET,
            authString: auth,
            headerFields: [HeaderField.ocsRequest(value: true), HeaderField.accept(value: .JSON)]
        )
        
        let (data, error) = await request.send()
        guard let data = data else { return (nil, error) }
        return (JSONDecoder.safeDecode(data), nil)
    }
    
    static func getRecipesTagged(auth: String, keyword: String) async -> ([Recipe]?, NetworkError?) {
        let request = ApiRequest(
            path: basePath + "/tags/\(keyword)",
            method: .GET,
            authString: auth,
            headerFields: [HeaderField.ocsRequest(value: true), HeaderField.accept(value: .JSON)]
        )
        
        let (data, error) = await request.send()
        guard let data = data else { return (nil, error) }
        return (JSONDecoder.safeDecode(data), nil)
    }
    
    static func getApiVersion(auth: String) async -> (NetworkError?) {
        return .none
    }
    
    static func postReindex(auth: String) async -> (NetworkError?) {
        return .none
    }
    
    static func getConfig(auth: String) async -> (NetworkError?) {
        return .none
    }
    
    static func postConfig(auth: String) async -> (NetworkError?) {
        return .none
    }
}
