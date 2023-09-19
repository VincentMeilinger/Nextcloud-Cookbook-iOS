//
//  CategoryDetailView.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 15.09.23.
//

import Foundation
import SwiftUI



struct RecipeBookView: View {
    @State var categoryName: String
    @ObservedObject var viewModel: MainViewModel
        
    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack {
                if let recipes = viewModel.recipes[categoryName] {
                    ForEach(recipes, id: \.recipe_id) { recipe in
                        NavigationLink(destination: RecipeDetailView(viewModel: viewModel, recipe: recipe)) {
                            RecipeCardView(viewModel: viewModel, recipe: recipe, isDownloaded: viewModel.recipeDetailExists(recipeId: recipe.recipe_id))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .navigationTitle(categoryName)
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
        .task {
            await viewModel.loadRecipeList(categoryName: categoryName)
        }
        .refreshable {
            await viewModel.loadRecipeList(categoryName: categoryName, needsUpdate: true)
        }
    }
    
    func downloadRecipes() {
        if let recipes = viewModel.recipes[categoryName] {
            let dispatchQueue = DispatchQueue(label: "RecipeDownload", qos: .background)
            dispatchQueue.async {
                for recipe in recipes {
                    Task {
                        let _ = await viewModel.loadRecipeDetail(recipeId: recipe.recipe_id)
                        let _ = await viewModel.loadImage(recipeId: recipe.recipe_id, full: true)
                    }
                }
            }
        }
    }
}
