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
    @Binding var showEditView: Bool
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack {
                ForEach(recipesFiltered(), id: \.recipe_id) { recipe in
                    NavigationLink(value: recipe) {
                        RecipeCardView(viewModel: viewModel, recipe: recipe)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationDestination(for: Recipe.self) { recipe in
            RecipeDetailView(viewModel: viewModel, recipe: recipe)
        }
        .navigationTitle(categoryName == "*" ? "Other" : categoryName)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
            
                Menu {
                    Button {
                        print("Add new recipe")
                        showEditView = true
                    } label: {
                        HStack {
                            Text("Add new recipe")
                            Image(systemName: "plus.circle.fill")
                        }
                    }
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
        }
        .searchable(text: $searchText, prompt: "Search recipes")
        .task {
            await viewModel.getCategory(named: categoryName, fetchMode: .preferLocal)
        }
        .refreshable {
            await viewModel.getCategory(named: categoryName, fetchMode: .preferServer)
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
            Task {
                for recipe in recipes {
                    let recipeDetail = await viewModel.getRecipe(id: recipe.recipe_id, fetchMode: .onlyServer)
                    await viewModel.saveLocal(recipeDetail, path: "recipe\(recipe.recipe_id).data")
                    
                    let thumbnail = await viewModel.getImage(id: recipe.recipe_id, size: .THUMB, fetchMode: .onlyServer)
                    guard let thumbnail = thumbnail else { continue }
                    guard let thumbnailData = thumbnail.pngData() else { continue }
                    await viewModel.saveLocal(thumbnailData.base64EncodedString(), path: "image\(recipe.recipe_id)_thumb")
                    
                    let image = await viewModel.getImage(id: recipe.recipe_id, size: .FULL, fetchMode: .onlyServer)
                    guard let image = image else { continue }
                    guard let imageData = image.pngData() else { continue }
                    await viewModel.saveLocal(imageData.base64EncodedString(), path: "image\(recipe.recipe_id)_full")
                }
            }
        }
    }
}
