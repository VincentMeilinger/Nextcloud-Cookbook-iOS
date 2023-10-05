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
    
    @State private var selectedCategory: Category? = nil
    @State private var showEditView: Bool = false
    var columns: [GridItem] = [GridItem(.adaptive(minimum: 150), spacing: 0)]
    
    var body: some View {
        NavigationSplitView {
            List(viewModel.categories, selection: $selectedCategory) { category in
                if category.recipe_count != 0 {
                    NavigationLink(value: category) {
                        HStack(alignment: .center) {
                            Image(systemName: "book.closed.fill")
                            Text(category.name == "*" ? "Other" : category.name)
                                .font(.system(size: 20, weight: .light, design: .serif))
                                .italic()
                        }.padding(7)
                    }
                }
            }
            .navigationTitle("Cookbooks")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
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
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink( destination: SettingsView(userSettings: userSettings, viewModel: viewModel)) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            
            
        } detail: {
            NavigationStack {
                if let category = selectedCategory {
                    CategoryDetailView(
                        categoryName: category.name,
                        viewModel: viewModel
                    )
                    .id(category.id) // Workaround: This is needed to update the detail view when the selection changes
                }
            }
            
        }
        .tint(.nextcloudBlue)
        .sheet(isPresented: $showEditView) {
            RecipeEditView(viewModel: viewModel, isPresented: $showEditView)
        }
        .task {
            await viewModel.loadCategoryList()
        }
        .refreshable {
            await viewModel.loadCategoryList(needsUpdate: true)
        }
        
        // TODO: SET DEFAULT CATEGORY
    }
}









