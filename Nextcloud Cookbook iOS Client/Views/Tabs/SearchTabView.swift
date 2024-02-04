//
//  SearchTabView.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 23.01.24.
//

import Foundation
import SwiftUI
import SimilaritySearchKit

struct SearchTabView: View {
    @EnvironmentObject var viewModel: SearchTabView.ViewModel
    @EnvironmentObject var mainViewModel: AppState
    
    var body: some View {
        NavigationStack {
            VStack {
                ScrollView(showsIndicators: false) {
                    /*
                    Picker("Topping", selection: $viewModel.searchMode) {
                        ForEach(ViewModel.SearchMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue)
                        }
                    }.pickerStyle(.segmented)
                     */
                    LazyVStack {
                        ForEach(viewModel.recipesFiltered(), id: \.recipe_id) { recipe in
                            NavigationLink(value: recipe) {
                                RecipeCardView(viewModel: mainViewModel, recipe: recipe)
                                    .shadow(radius: 2)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .navigationDestination(for: Recipe.self) { recipe in
                    RecipeDetailView(viewModel: mainViewModel, recipe: recipe)
                }
                .searchable(text: $viewModel.searchText, prompt: "Search recipes/keywords")
            }
            .navigationTitle("Search recipe")
        }
        .task {
            if viewModel.allRecipes.isEmpty {
                viewModel.allRecipes = await mainViewModel.getRecipes()
            }
        }
        .refreshable {
            viewModel.allRecipes = await mainViewModel.getRecipes()
        }
    }
    
    class ViewModel: ObservableObject {
        @Published var allRecipes: [Recipe] = []
        @Published var searchText: String = ""
        @Published var searchMode: SearchMode = .name
        
        var similarityIndex: SimilarityIndex? = nil
        var similaritySearchResults: [SearchResult] = []

        enum SearchMode: String, CaseIterable {
            case name = "Name & Keywords", ingredient = "Ingredients"
        }
        
        func recipesFiltered() -> [Recipe] {
            if searchMode == .name {
                guard searchText != "" else { return allRecipes }
                return allRecipes.filter { recipe in
                    recipe.name.lowercased().contains(searchText.lowercased()) || // check name for occurence of search term
                    (recipe.keywords != nil && recipe.keywords!.lowercased().contains(searchText.lowercased())) // check keywords for search term
                }
            } else if searchMode == .ingredient {
                // TODO: Fuzzy ingredient search
            }
            return []
        }
    }
}
