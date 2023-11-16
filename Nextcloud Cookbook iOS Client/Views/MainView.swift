//
//  ContentView.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 06.09.23.
//

import SwiftUI


struct MainView: View {
    @ObservedObject var userSettings: UserSettings
    @StateObject var viewModel = MainViewModel()
    
    @State private var selectedCategory: Category? = nil
    @State private var showEditView: Bool = false
    @State private var showSearchView: Bool = false
    @State private var showSettingsView: Bool = false
    @State private var serverConnection: Bool = false
    
    
    var columns: [GridItem] = [GridItem(.adaptive(minimum: 150), spacing: 0)]
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedCategory) {
                // All recipes
                NavigationLink {
                    RecipeSearchView(viewModel: viewModel)
                } label: {
                    HStack(alignment: .center) {
                        Image(systemName: "book.closed.fill")
                        Text("All")
                            .font(.system(size: 20, weight: .light, design: .serif))
                            .italic()
                    }
                    .padding(7)
                }
                
                // Categories
                ForEach(viewModel.categories) { category in
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
            }
            .navigationTitle("Cookbooks")
            .navigationDestination(isPresented: $showSettingsView) {
                SettingsView(userSettings: userSettings, viewModel: viewModel)
            }
            .navigationDestination(isPresented: $showSearchView) {
                RecipeSearchView(viewModel: viewModel)
            }
            .toolbar {
                MainViewToolBar(
                    viewModel: viewModel,
                    showEditView: $showEditView,
                    showSettingsView: $showSettingsView,
                    serverConnection: $serverConnection
                )
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
                RecipeEditView(viewModel:
                    RecipeEditViewModel(
                        mainViewModel: viewModel,
                        isPresented: $showEditView,
                        uploadNew: true
                    )
                )
            }
            .task {
                self.serverConnection = await viewModel.checkServerConnection()
                await viewModel.loadCategories()//viewModel.loadCategoryList()
                // Open detail view for default category
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
                self.serverConnection = await viewModel.checkServerConnection()
                await viewModel.loadCategories()//loadCategoryList(needsUpdate: true)
            }
            
        }
    }
    
    
    
    
    struct MainViewToolBar: ToolbarContent {
        @ObservedObject var viewModel: MainViewModel
        @Binding var showEditView: Bool
        @Binding var showSettingsView: Bool
        @Binding var serverConnection: Bool
        @State private var presentPopover: Bool = false
        
        var body: some ToolbarContent {
            // Top left menu toolbar item
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
            
            // Server connection indicator
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    print("Check server connection")
                    presentPopover = true
                } label: {
                    if serverConnection {
                        Image(systemName: "checkmark.icloud")
                    } else {
                        Image(systemName: "xmark.icloud")
                    }
                }.popover(isPresented: $presentPopover) {
                    Text(serverConnection ? LocalizedStringKey("Connected to server.") : LocalizedStringKey("Unable to connect to server."))
                        .bold()
                        .padding()
                        .presentationCompactAdaptation(.popover)
                }
            }
            
            // Create new recipes
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    print("Add new recipe")
                    showEditView = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
        
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
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .navigationDestination(for: Recipe.self) { recipe in
                    RecipeDetailView(viewModel: viewModel, recipe: recipe)
                }
                .searchable(text: $searchText, prompt: "Search recipes")
            }
            .navigationTitle("Search recipe")
        }
        .task {
            allRecipes = await viewModel.getRecipes()//.getAllRecipes()
        }
    }
    
    func recipesFiltered() -> [Recipe] {
        guard searchText != "" else { return allRecipes }
        return allRecipes.filter { recipe in
            recipe.name.lowercased().contains(searchText.lowercased())
        }
    }
}
