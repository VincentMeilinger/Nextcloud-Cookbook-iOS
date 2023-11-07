import SwiftSoup
import Foundation



//let url = "https://www.chefkoch.de/rezepte/1385981243676608/Knusprige-Entenbrust.html"
let url = "https://www.allrecipes.com/recipe/234620/mascarpone-mashed-potatoes/"
var contents: String? = nil
if let url = URL(string: url) {
    do {
        contents = try String(contentsOf: url)
        //print(contents)
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
        //print(attr.getValue())
        if attr.getValue() == "application/ld+json" {
            
            do {
                let jsonString = try elem.html()
                //print(json)
                let json = try JSONSerialization.jsonObject(with: jsonString.data(using: .utf8)!, options: .fragmentsAllowed)
                if let recipe = json as? [String : Any] {
                    print("1")
                    getRecipe(fromDict: recipe)
                } else if let recipe = (json as! [Any])[0] as? [String : Any] {
                    print("2")
                    getRecipe(fromDict: recipe)
                }
                
                
            } catch {
                print("COULD NOT DECODE")
            }
        }
    }
}


func getRecipe(fromDict recipe: Dictionary<String, Any>) {
    
    if recipe["@type"] as? String ?? "" == "Recipe" {
        print(recipe["name"] ?? "No name")
        print(recipe["recipeIngredient"] ?? "No ingredients")
        print(recipe["recipeInstruction"] ?? "No instruction")
    } else if (recipe["@type"] as? [String] ?? []).contains("Recipe") {
        print(recipe["name"] ?? "No name")
    }
}
