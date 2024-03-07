//
//  CategoryDetailView.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 15.09.23.
//

import Foundation
import SwiftUI



struct RecipeListView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var groceryList: GroceryList
    @State var categoryName: String
    @State var searchText: String = ""
    @Binding var showEditView: Bool
    @State var selectedRecipe: Recipe? = nil
    @State var presentRecipeView: Bool = false
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack {
                ForEach(recipesFiltered(), id: \.recipe_id) { recipe in
                    NavigationLink(value: recipe) {
                        RecipeCardView(recipe: recipe)
                            .shadow(radius: 2)
                            
                    }
                    .buttonStyle(.plain)
                    .onTapGesture {
                        selectedRecipe = recipe
                        presentRecipeView = true
                    }
                }
            }
        }
        .navigationDestination(for: Recipe.self) { recipe in
            RecipeView(isPresented: .constant(true), viewModel: RecipeView.ViewModel(recipe: recipe))
                .environmentObject(appState)
                .environmentObject(groceryList)
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
    
    func recipesFiltered() -> [Recipe] {
        guard let recipes = appState.recipes[categoryName] else { return [] }
        guard searchText != "" else { return recipes }
        return recipes.filter { recipe in
            recipe.name.lowercased().contains(searchText.lowercased()) || // check name for occurence of search term
            (recipe.keywords != nil && recipe.keywords!.lowercased().contains(searchText.lowercased())) // check keywords for search term
        }
    }
}
