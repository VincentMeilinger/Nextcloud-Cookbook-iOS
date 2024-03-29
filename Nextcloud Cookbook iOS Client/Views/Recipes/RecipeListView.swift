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
    
    var body: some View {
        Group {
            let recipes = recipesFiltered()
            if !recipes.isEmpty {
                List(recipesFiltered(), id: \.recipe_id) { recipe in
                    RecipeCardView(recipe: recipe)
                        .shadow(radius: 2)
                        .background(
                            NavigationLink(value: recipe) {
                                EmptyView()
                            }
                                .buttonStyle(.plain)
                                .opacity(0)
                        )
                        .frame(height: 85)
                        .listRowInsets(EdgeInsets(top: 5, leading: 15, bottom: 5, trailing: 15))
                        .listRowSeparatorTint(.clear)
                }
                .listStyle(.plain)
            } else {
                VStack {
                    Text("There are no recipes in this cookbook!")
                    Button {
                        Task {
                            await appState.getCategories()
                            await appState.getCategory(named: categoryName, fetchMode: .preferServer)
                        }
                    } label: {
                        Text("Refresh")
                            .bold()
                    }
                    .buttonStyle(.bordered)
                }.padding()
            }
        }
        .searchable(text: $searchText, prompt: "Search recipes/keywords")
        .navigationTitle(categoryName == "*" ? String(localized: "Other") : categoryName)
        
        .navigationDestination(for: Recipe.self) { recipe in
            RecipeView(viewModel: RecipeView.ViewModel(recipe: recipe))
                .environmentObject(appState)
                .environmentObject(groceryList)
        }
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
