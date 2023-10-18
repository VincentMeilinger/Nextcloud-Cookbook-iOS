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
    @State private var showSettingsView: Bool = false
    
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
            .navigationDestination(isPresented: $showSettingsView) {
                SettingsView(userSettings: userSettings, viewModel: viewModel)
            }
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
                            self.showSettingsView = true
                        } label: {
                            Text("Settings")
                            Image(systemName: "gearshape")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        print("Add new recipe")
                        showEditView = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                        }
                    }
                }
            }
        } detail: {
            NavigationStack {
                if let category = selectedCategory {
                    CategoryDetailView(
                        categoryName: category.name,
                        viewModel: viewModel,
                        showEditView: $showEditView
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
            if userSettings.defaultCategory != "" {
                if let cat = viewModel.categories.first(where: { c in
                    if c.name == userSettings.defaultCategory {
                        return true
                    }
                    return false
                }) {
                    self.selectedCategory = cat
                }
            }
        }
        .refreshable {
            await viewModel.loadCategoryList(needsUpdate: true)
        }
    }
}









