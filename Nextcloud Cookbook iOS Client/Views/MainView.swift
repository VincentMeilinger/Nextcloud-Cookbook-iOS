//
//  ContentView.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 06.09.23.
//

import SwiftUI

struct MainView: View {
    @StateObject var appState = AppState()
    @StateObject var groceryList = GroceryList()
    
    // Tab ViewModels
    @StateObject var recipeViewModel = RecipeTabView.ViewModel()
    @StateObject var searchViewModel = SearchTabView.ViewModel()
    
    enum Tab {
        case recipes, search, groceryList
    }
    
    var body: some View {
        TabView {
            RecipeTabView()
                .environmentObject(recipeViewModel)
                .environmentObject(appState)
                .environmentObject(groceryList)
                .tabItem {
                    Label("Recipes", systemImage: "book.closed.fill")
                }
                .tag(Tab.recipes)
            
            SearchTabView()
                .environmentObject(searchViewModel)
                .environmentObject(appState)
                .environmentObject(groceryList)
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(Tab.search)
            
            GroceryListTabView()
                .environmentObject(groceryList)
                .tabItem {
                    if #available(iOS 17.0, *) {
                        Label("Grocery List", systemImage: "storefront")
                    } else {
                        Label("Grocery List", systemImage: "heart.text.square")
                    }
                }
                .tag(Tab.groceryList)
        }
        .task {
            recipeViewModel.presentLoadingIndicator = true
            await appState.getCategories()
            await appState.updateAllRecipeDetails()
            
            // Open detail view for default category
            if UserSettings.shared.defaultCategory != "" {
                if let cat = appState.categories.first(where: { c in
                    if c.name == UserSettings.shared.defaultCategory {
                        return true
                    }
                    return false
                }) {
                    recipeViewModel.selectedCategory = cat
                }
            }
            await groceryList.load()
            recipeViewModel.presentLoadingIndicator = false
        }
    }
}
