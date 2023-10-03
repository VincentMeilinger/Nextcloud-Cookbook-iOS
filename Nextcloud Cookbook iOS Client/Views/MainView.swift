//
//  ContentView.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 06.09.23.
//

import SwiftUI

struct MainView: View {
    @ObservedObject var viewModel: MainViewModel
    @ObservedObject var userSettings: UserSettings
    
    @State private var showEditView: Bool = false
    var columns: [GridItem] = [GridItem(.adaptive(minimum: 150), spacing: 0)]
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 0) {
                    ForEach(viewModel.categories, id: \.name) { category in
                        if category.recipe_count != 0 {
                            NavigationLink(
                                destination: RecipeBookView(
                                    categoryName: category.name,
                                    viewModel: viewModel
                                )
                            ) {
                                CategoryCardView(category: category)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            /*.navigationDestination(isPresented: $showEditView) {
                RecipeEditView()
            }*/
            .navigationTitle("Cookbooks")
            .toolbar {
                Menu {
                    Button {
                        print("Downloading all recipes ...")
                        Task {
                            await viewModel.downloadAllRecipes()
                        }
                    } label: {
                        HStack {
                            Text("Download all recipes")
                            Image(systemName: "icloud.and.arrow.down")
                        }
                    }
                    
                    Button {
                        print("Create recipe")
                        showEditView = true
                    } label: {
                        HStack {
                            Text("Create new recipe")
                            Image(systemName: "plus.circle")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                
                NavigationLink( destination: SettingsView(userSettings: userSettings, viewModel: viewModel)) {
                    Image(systemName: "gearshape")
                }
            }
            .background(
                NavigationLink(destination: RecipeEditView(), isActive: $showEditView) { EmptyView() }
            )
            
        }
        .tint(.nextcloudBlue)
        .task {
            await viewModel.loadCategoryList()
        }
        .refreshable {
            await viewModel.loadCategoryList(needsUpdate: true)
        }
    }
}









