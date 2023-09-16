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
        ScrollView {
            LazyVStack {
                if let recipes = viewModel.recipes[categoryName] {
                    ForEach(recipes, id: \.recipe_id) { recipe in
                        NavigationLink(destination: RecipeDetailView(viewModel: viewModel, recipe: recipe)) {
                            RecipeCardView(viewModel: viewModel, recipe: recipe)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .navigationTitle(categoryName)
        .task {
            await viewModel.loadRecipeList(categoryName: categoryName)
        }
        .refreshable {
            await viewModel.loadRecipeList(categoryName: categoryName, needsUpdate: true)
        }
    }
}
