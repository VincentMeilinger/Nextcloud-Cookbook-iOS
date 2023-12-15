//
//  CookbookApiV1.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 16.11.23.
//

import Foundation
import UIKit


class CookbookApiV1: CookbookApi {
    static func importRecipe(from serverAdress: String, auth: String, data: Data) async -> (RecipeDetail?, NetworkError?) {
        let request = ApiRequest(
            serverAdress: serverAdress,
            path: "/api/v1/import",
            method: .POST,
            authString: auth,
            headerFields: [HeaderField.ocsRequest(value: true), HeaderField.accept(value: .JSON), HeaderField.contentType(value: .JSON)]
        )
        
        let (data, error) = await request.send()
        guard let data = data else { return (nil, error) }
        return (JSONDecoder.safeDecode(data), nil)
    }
    
    static func getImage(from serverAdress: String, auth: String, id: Int, size: RecipeImage.RecipeImageSize) async -> (UIImage?, NetworkError?) {
        let imageSize = (size == .FULL ? "full" : "thumb")
        let request = ApiRequest(
            serverAdress: serverAdress,
            path: "/api/v1/recipes/\(id)/image?size=\(imageSize)",
            method: .GET,
            authString: auth,
            headerFields: [HeaderField.ocsRequest(value: true), HeaderField.accept(value: .IMAGE)]
        )
        
        let (data, error) = await request.send()
        guard let data = data else { return (nil, error) }
        return (UIImage(data: data), error)
    }
    
    static func getRecipes(from serverAdress: String, auth: String) async -> ([Recipe]?, NetworkError?) {
        let request = ApiRequest(
            serverAdress: serverAdress,
            path: "/api/v1/recipes",
            method: .GET,
            authString: auth,
            headerFields: [HeaderField.ocsRequest(value: true), HeaderField.accept(value: .JSON)]
        )
        
        let (data, error) = await request.send()
        guard let data = data else { return (nil, error) }
        return (JSONDecoder.safeDecode(data), nil)
    }
    
    static func createRecipe(from serverAdress: String, auth: String, recipe: RecipeDetail) async -> (NetworkError?) {
        guard let recipeData = JSONEncoder.safeEncode(recipe) else {
            return .dataError
        }
        
        let request = ApiRequest(
            serverAdress: serverAdress,
            path: "/api/v1/recipes",
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
    
    static func getRecipe(from serverAdress: String, auth: String, id: Int) async -> (RecipeDetail?, NetworkError?) {
        let request = ApiRequest(
            serverAdress: serverAdress,
            path: "/api/v1/recipes/\(id)",
            method: .GET,
            authString: auth,
            headerFields: [HeaderField.ocsRequest(value: true), HeaderField.accept(value: .JSON)]
        )
        
        let (data, error) = await request.send()
        guard let data = data else { return (nil, error) }
        return (JSONDecoder.safeDecode(data), nil)
    }
    
    static func updateRecipe(from serverAdress: String, auth: String, recipe: RecipeDetail) async -> (NetworkError?) {
        guard let recipeData = JSONEncoder.safeEncode(recipe) else {
            return .dataError
        }
        let request = ApiRequest(
            serverAdress: serverAdress,
            path: "/api/v1/recipes/\(recipe.id)",
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
    
    static func deleteRecipe(from serverAdress: String, auth: String, id: Int) async -> (NetworkError?) {
        let request = ApiRequest(
            serverAdress: serverAdress,
            path: "/api/v1/recipes/\(id)",
            method: .DELETE,
            authString: auth,
            headerFields: [HeaderField.ocsRequest(value: true), HeaderField.accept(value: .JSON)]
        )
        
        let (data, error) = await request.send()
        guard let data = data else { return (error) }
        return nil
    }
    
    static func getCategories(from serverAdress: String, auth: String) async -> ([Category]?, NetworkError?) {
        let request = ApiRequest(
            serverAdress: serverAdress,
            path: "/api/v1/categories",
            method: .GET,
            authString: auth,
            headerFields: [HeaderField.ocsRequest(value: true), HeaderField.accept(value: .JSON)]
        )
        
        let (data, error) = await request.send()
        guard let data = data else { return (nil, error) }
        return (JSONDecoder.safeDecode(data), nil)
    }
    
    static func getCategory(from serverAdress: String, auth: String, named categoryName: String) async -> ([Recipe]?, NetworkError?) {
        let request = ApiRequest(
            serverAdress: serverAdress,
            path: "/api/v1/category/\(categoryName)",
            method: .GET,
            authString: auth,
            headerFields: [HeaderField.ocsRequest(value: true), HeaderField.accept(value: .JSON)]
        )
        
        let (data, error) = await request.send()
        guard let data = data else { return (nil, error) }
        return (JSONDecoder.safeDecode(data), nil)
    }
    
    static func renameCategory(from serverAdress: String, auth: String, named categoryName: String, newName: String) async -> (NetworkError?) {
        let request = ApiRequest(
            serverAdress: serverAdress,
            path: "/api/v1/category/\(categoryName)",
            method: .PUT,
            authString: auth,
            headerFields: [HeaderField.ocsRequest(value: true), HeaderField.accept(value: .JSON)]
        )
        
        let (data, error) = await request.send()
        guard let data = data else { return (error) }
        return nil
    }
    
    static func getTags(from serverAdress: String, auth: String) async -> ([RecipeKeyword]?, NetworkError?) {
        let request = ApiRequest(
            serverAdress: serverAdress,
            path: "/api/v1/keywords",
            method: .GET,
            authString: auth,
            headerFields: [HeaderField.ocsRequest(value: true), HeaderField.accept(value: .JSON)]
        )
        
        let (data, error) = await request.send()
        guard let data = data else { return (nil, error) }
        return (JSONDecoder.safeDecode(data), nil)
    }
    
    static func getRecipesTagged(from serverAdress: String, auth: String, keyword: String) async -> ([Recipe]?, NetworkError?) {
        let request = ApiRequest(
            serverAdress: serverAdress,
            path: "/api/v1/tags/\(keyword)",
            method: .GET,
            authString: auth,
            headerFields: [HeaderField.ocsRequest(value: true), HeaderField.accept(value: .JSON)]
        )
        
        let (data, error) = await request.send()
        guard let data = data else { return (nil, error) }
        return (JSONDecoder.safeDecode(data), nil)
    }
    
    static func getApiVersion(from serverAdress: String, auth: String) async -> (NetworkError?) {
        return .none
    }
    
    static func postReindex(from serverAdress: String, auth: String) async -> (NetworkError?) {
        return .none
    }
    
    static func getConfig(from serverAdress: String, auth: String) async -> (NetworkError?) {
        return .none
    }
    
    static func postConfig(from serverAdress: String, auth: String) async -> (NetworkError?) {
        return .none
    }
}
