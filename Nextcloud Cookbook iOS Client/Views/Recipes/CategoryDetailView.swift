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
    @ObservedObject var viewModel: AppState
    @Binding var showEditView: Bool
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack {
                ForEach(recipesFiltered(), id: \.recipe_id) { recipe in
                    NavigationLink(value: recipe) {
                        RecipeCardView(viewModel: viewModel, recipe: recipe)
                            .shadow(radius: 2)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationDestination(for: Recipe.self) { recipe in
            RecipeDetailView(viewModel: viewModel, recipe: recipe)
        }
        .navigationTitle(categoryName == "*" ? String(localized: "Other") : categoryName)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    print("Add new recipe")
                    showEditView = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search recipes/keywords")
        .task {
            await viewModel.getCategory(
                named: categoryName,
                fetchMode: UserSettings.shared.storeRecipes ? .preferLocal : .onlyServer
            )
        }
        .refreshable {
            await viewModel.getCategory(
                named: categoryName,
                fetchMode: UserSettings.shared.storeRecipes ? .preferServer : .onlyServer
            )
        }
    }
    
    func recipesFiltered() -> [Recipe] {
        guard let recipes = viewModel.recipes[categoryName] else { return [] }
        guard searchText != "" else { return recipes }
        return recipes.filter { recipe in
            recipe.name.lowercased().contains(searchText.lowercased()) || // check name for occurence of search term
            (recipe.keywords != nil && recipe.keywords!.lowercased().contains(searchText.lowercased())) // check keywords for search term
        }
    }
}
