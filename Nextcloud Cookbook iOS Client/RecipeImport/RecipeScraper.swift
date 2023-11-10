//
//  RecipeScraper.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 09.11.23.
//

import Foundation
import SwiftSoup

class RecipeScraper {
    func scrape(url: String) async throws -> RecipeDetail? {
        var contents: String? = nil
        if let url = URL(string: url) {
            do {
                contents = try String(contentsOf: url)
            } catch {
                print("ERROR: Could not load url content.")
            }
            
        } else {
            print("ERROR: Bad url.")
            return nil
        }

        guard let html = contents else {
            print("ERROR: no contents")
            return nil
        }
        let doc = try SwiftSoup.parse(html)
        
        let elements: Elements = try doc.select("script")
        for elem in elements.array() {
            for attr in elem.getAttributes()!.asList() {
                if attr.getValue() == "application/ld+json" {
                    guard let dict = toDict(elem) else { continue }
                    return getRecipe(fromDict: dict)
                }
            }
        }
        return nil
    }
    
    
    private func toDict(_ elem: Element) -> [String: Any]? {
        var recipeDict: [String: Any]? = nil
        do {
            let jsonString = try elem.html()
            //print(json)
            let json = try JSONSerialization.jsonObject(with: jsonString.data(using: .utf8)!, options: .fragmentsAllowed)
            if let recipe = json as? [String : Any] {
                recipeDict = recipe
            } else if let recipe = (json as! [Any])[0] as? [String : Any] {
                recipeDict = recipe
            }
        } catch {
            print("Unable to decode json")
            return nil
        }
        
        guard let recipeDict = recipeDict else {
            print("Json is not a dict")
            return nil
        }
        
        if recipeDict["@type"] as? String ?? "" == "Recipe" {
            return recipeDict
        } else if (recipeDict["@type"] as? [String] ?? []).contains("Recipe") {
            return recipeDict
        } else {
            print("Json dict is not a recipe ...")
            return nil
        }
    }
    
    private func getRecipe(fromDict recipe: Dictionary<String, Any>) -> RecipeDetail? {
        
        var recipeDetail = RecipeDetail()
        recipeDetail.name = recipe["name"] as? String ?? "New Recipe"
        recipeDetail.recipeCategory = recipe["recipeCategory"] as? String ?? ""
        recipeDetail.keywords = recipe["keywords"] as? String ?? ""
        recipeDetail.description = recipe["description"] as? String ?? ""
        recipeDetail.dateCreated = recipe["dateCreated"] as? String ?? ""
        recipeDetail.dateModified = recipe["dateModified"] as? String ?? ""
        recipeDetail.imageUrl = recipe["imageUrl"] as? String ?? ""
        recipeDetail.url = recipe["url"] as? String ?? ""
        recipeDetail.cookTime = recipe["cookTime"] as? String ?? ""
        recipeDetail.prepTime = recipe["prepTime"] as? String ?? ""
        recipeDetail.totalTime = recipe["totalTime"] as? String ?? ""
        recipeDetail.recipeInstructions = stringArrayForKey("recipeInstructions", dict: recipe)
        recipeDetail.recipeYield = recipe["recipeYield"] as? Int ?? 0
        recipeDetail.recipeIngredient = recipe["recipeIngredient"] as? [String] ?? []
        recipeDetail.tool = recipe["tool"] as? [String] ?? []
        recipeDetail.nutrition = recipe["nutrition"] as? [String:String] ?? [:]
        
        return recipeDetail
    }
    
    private func stringArrayForKey(_ key: String, dict: Dictionary<String, Any>) -> [String] {
        if let value = dict[key] as? [String] {
            return value
        } else if let orderedList = dict[key] as? [Any] {
            var entries: [String] = []
            for dict in orderedList {
                guard let dict = dict as? [String: Any] else { continue }
                guard let text = dict["text"] as? String else { continue }
                entries.append(text)
            }
            return entries
        } else if let text = dict[key] as? String {
            return [text]
        }
        return []
    }
    
    private func joinedStringForKey(_ key: String, dict: Dictionary<String, Any>) -> String {
        if let value = dict[key] as? [String] {
            return value.joined(separator: ",")
        } else if let value = dict[key] as? String {
            return value
        }
        return ""
    }
}
