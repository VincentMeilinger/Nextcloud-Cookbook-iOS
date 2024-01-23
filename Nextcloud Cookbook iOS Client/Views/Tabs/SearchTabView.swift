//
//  SearchTabView.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 23.01.24.
//

import Foundation
import SwiftUI


struct SearchTabView: View {
    @EnvironmentObject var viewModel: MainViewModel
    
    var body: some View {
        RecipeSearchView(viewModel: viewModel)
    }
}

struct RecipeSearchView: View {
    @ObservedObject var viewModel: MainViewModel
    @State var searchText: String = ""
    @State var allRecipes: [Recipe] = []
    
    var body: some View {
        NavigationStack {
            VStack {
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
                .searchable(text: $searchText, prompt: "Search recipes/keywords")
            }
            .navigationTitle("Search recipe")
        }
        .task {
            allRecipes = await viewModel.getRecipes()
        }
    }
    
    func recipesFiltered() -> [Recipe] {
        guard searchText != "" else { return allRecipes }
        return allRecipes.filter { recipe in
            recipe.name.lowercased().contains(searchText.lowercased()) || // check name for occurence of search term
            (recipe.keywords != nil && recipe.keywords!.lowercased().contains(searchText.lowercased())) // check keywords for search term
        }
    }
}
