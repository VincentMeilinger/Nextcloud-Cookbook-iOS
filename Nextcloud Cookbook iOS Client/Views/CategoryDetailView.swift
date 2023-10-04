//
//  CategoryDetailView.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 15.09.23.
//

import Foundation
import SwiftUI



struct CategoryDetailView: View {
    @State var categoryName: String
    @State var searchText: String = ""
    @ObservedObject var viewModel: MainViewModel
        
    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack {
                ForEach(recipesFiltered(), id: \.recipe_id) { recipe in
                    NavigationLink() {
                        RecipeDetailView(viewModel: viewModel, recipe: recipe).id(recipe.recipe_id)
                    } label: {
                        RecipeCardView(viewModel: viewModel, recipe: recipe)
                    }
                    .buttonStyle(.plain)
                    
                }
            }
        }
        .navigationTitle(categoryName == "*" ? "Other" : categoryName)
        .toolbar {
            Menu {
                Button {
                    print("Downloading all recipes in category \(categoryName) ...")
                    downloadRecipes()
                } label: {
                    HStack {
                        Text("Download recipes")
                        Image(systemName: "icloud.and.arrow.down")
                    }
                }
                
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
        .searchable(text: $searchText, prompt: "Search recipes")
        .task {
            await viewModel.loadRecipeList(categoryName: categoryName)
        }
        .refreshable {
            await viewModel.loadRecipeList(categoryName: categoryName, needsUpdate: true)
        }
    }
    
    func recipesFiltered() -> [Recipe] {
        guard let recipes = viewModel.recipes[categoryName] else { return [] }
        guard searchText != "" else { return recipes }
        return recipes.filter { recipe in
            recipe.name.lowercased().contains(searchText.lowercased())
        }
    }

    
    func downloadRecipes() {
        if let recipes = viewModel.recipes[categoryName] {
            let dispatchQueue = DispatchQueue(label: "RecipeDownload", qos: .background)
            dispatchQueue.async {
                for recipe in recipes {
                    Task {
                        let _ = await viewModel.loadRecipeDetail(recipeId: recipe.recipe_id)
                        let _ = await viewModel.loadImage(recipeId: recipe.recipe_id, thumb: false)
                    }
                }
            }
        }
    }
}
