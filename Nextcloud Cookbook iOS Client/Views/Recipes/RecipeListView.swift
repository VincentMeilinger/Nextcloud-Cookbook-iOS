//
//  RecipeListView.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 15.09.23.
//

import Foundation
import SwiftUI



/// Recipes of one cookbook. Used as a pushed screen on iPhone and as the
/// root of a cookbook's sidebar entry on iPad.
struct RecipeListView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(LibraryModel.self) private var library
    let categoryName: String
    @State private var searchText = ""
    @State private var showNewRecipe = false
    @State private var createdRecipe: Recipe?

    var body: some View {
        List(filteredRecipes) { recipe in
            RecipeRow(recipe: recipe)
        }
        .listStyle(.plain)
        .overlay {
            if appState.recipes[categoryName, default: []].isEmpty {
                ContentUnavailableView {
                    Label("There are no recipes in this cookbook!", systemImage: "book.closed")
                } actions: {
                    Button("Refresh") {
                        Task {
                            await appState.getCategories()
                            await appState.getCategory(named: categoryName, fetchMode: .preferServer)
                        }
                    }
                    .buttonStyle(.bordered)
                }
            } else if filteredRecipes.isEmpty {
                ContentUnavailableView.search(text: searchText)
            }
        }
        .searchable(text: $searchText, prompt: "Search recipes/keywords")
        .navigationTitle(categoryName == "*" ? String(localized: "Other") : categoryName)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("New Recipe", systemImage: "plus") { showNewRecipe = true }
            }
        }
        .sheet(isPresented: $showNewRecipe) {
            // New recipes created here start in this cookbook
            RecipeEditorView(category: categoryName == "*" ? "" : categoryName) { createdRecipe = $0 }
                .environmentObject(appState)
                .environment(library)
        }
        .navigationDestination(item: $createdRecipe) { recipe in
            RecipeView(viewModel: RecipeView.ViewModel(recipe: recipe))
        }
        .task {
            await appState.getCategory(
                named: categoryName,
                fetchMode: UserSettings.shared.storeRecipes ? .preferLocal : .onlyServer
            )
        }
        .refreshable {
            await appState.getCategory(
                named: categoryName,
                fetchMode: UserSettings.shared.storeRecipes ? .preferServer : .onlyServer
            )
        }
    }

    private var filteredRecipes: [Recipe] {
        let recipes = appState.recipes[categoryName, default: []]
        guard !searchText.isEmpty else { return recipes }
        return recipes.filter { recipe in
            recipe.name.localizedCaseInsensitiveContains(searchText)
                || (recipe.keywords?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
}
