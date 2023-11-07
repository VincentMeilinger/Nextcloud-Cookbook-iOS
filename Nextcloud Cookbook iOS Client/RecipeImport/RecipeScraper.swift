//
//  RecipeScraper.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 05.11.23.
//

import Foundation
import SwiftSoup

class RecipeScraper {
    func scrape(url: String) -> RecipeDetail? {
        var contents: String? = nil
        if let url = URL(string: url) {
            do {
                contents = try String(contentsOf: url)
            } catch {
                print("ERROR: Could not load url content.")
            }
            
        } else {
            print("ERROR: Bad url.")
        }

        guard let html = contents else {
            print("ERROR: no contents")
            exit(1)
        }
        
        let doc: Document = try SwiftSoup.parse(html)
        let elements: Elements = try doc.select("script")
        for elem in elements.array() {
            for attr in elem.getAttributes()!.asList() {
                if attr.getValue() == "application/ld+json" {
                    toDict(elem)
                }
            }
        }
    }
    
    
    private func toDict(_ elem: Element) -> [String: Any] {
        do {
            let jsonString = try elem.html()
            //print(json)
            let json = try JSONSerialization.jsonObject(with: jsonString.data(using: .utf8)!, options: .fragmentsAllowed)
            if let recipe = json as? [String : Any] {
                return recipe
            } else if let recipe = (json as! [Any])[0] as? [String : Any] {
                return recipe
            }            
        } catch {
            print("COULD NOT DECODE")
        }
    }
    
    private func getRecipe(fromDict recipe: Dictionary<String, Any>) {
        if recipe["@type"] as? String ?? "" == "Recipe" {
            print(recipe["name"] ?? "No name")
            print(recipe["recipeIngredient"] ?? "No ingredients")
            print(recipe["recipeInstruction"] ?? "No instruction")
        } else if (recipe["@type"] as? [String] ?? []).contains("Recipe") {
            print(recipe["name"] ?? "No name")
        }
    }
    
}
