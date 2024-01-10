//
//  ContentView.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 06.09.23.
//

import SwiftUI


struct MainView: View {
    @ObservedObject var viewModel: MainViewModel
    @StateObject var userSettings: UserSettings = UserSettings.shared
    
    @State private var selectedCategory: Category? = nil
    @State private var showEditView: Bool = false
    @State private var showSearchView: Bool = false
    @State private var showSettingsView: Bool = false
    @State private var serverConnection: Bool = false
    @State private var showLoadingIndicator: Bool = false
    
    
    var columns: [GridItem] = [GridItem(.adaptive(minimum: 150), spacing: 0)]
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedCategory) {
                // All recipes
                NavigationLink {
                    RecipeSearchView(viewModel: viewModel)
                } label: {
                    HStack(alignment: .center) {
                        Image(systemName: "magnifyingglass")
                        Text("Search")
                            .font(.system(size: 20, weight: .medium, design: .default))
                    }
                    .padding(7)
                }
                
                // Categories
                ForEach(viewModel.categories) { category in
                    if category.recipe_count != 0 {
                        NavigationLink(value: category) {
                            HStack(alignment: .center) {
                                if selectedCategory != nil && category.name == selectedCategory!.name {
                                    Image(systemName: "book")
                                } else {
                                    Image(systemName: "book.closed.fill")
                                }
                                Text(category.name == "*" ? String(localized: "Other") : category.name)
                                    .font(.system(size: 20, weight: .medium, design: .default))
                                Spacer()
                                Text("\(category.recipe_count)")
                                    .font(.system(size: 15, weight: .bold, design: .default))
                                    .foregroundStyle(Color.background)
                                    .frame(width: 25, height: 25, alignment: .center)
                                    .minimumScaleFactor(0.5)
                                    .background {
                                        Circle()
                                            .foregroundStyle(Color.secondary)
                                    }
                            }.padding(7)
                        }
                    }
                }
            }
            .navigationTitle("Cookbooks")
            .navigationDestination(isPresented: $showSettingsView) {
                SettingsView(viewModel: viewModel)
            }
            .navigationDestination(isPresented: $showSearchView) {
                RecipeSearchView(viewModel: viewModel)
            }
            .toolbar {
                MainViewToolBar(
                    viewModel: viewModel,
                    showEditView: $showEditView,
                    showSettingsView: $showSettingsView,
                    serverConnection: $serverConnection,
                    showLoadingIndicator: $showLoadingIndicator
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
                RecipeEditView(
                    viewModel:
                        RecipeEditViewModel(
                            mainViewModel: viewModel,
                            uploadNew: true
                        ),
                    isPresented: $showEditView
                )
            }
            .task {
                showLoadingIndicator = true
                self.serverConnection = await viewModel.checkServerConnection()
                await viewModel.getCategories()
                await viewModel.updateAllRecipeDetails()
                
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
                showLoadingIndicator = false
            }
            .refreshable {
                self.serverConnection = await viewModel.checkServerConnection()
                await viewModel.getCategories()
            }
            
        }
    }
    
    
    
    
    struct MainViewToolBar: ToolbarContent {
        @ObservedObject var viewModel: MainViewModel
        @Binding var showEditView: Bool
        @Binding var showSettingsView: Bool
        @Binding var serverConnection: Bool
        @Binding var showLoadingIndicator: Bool
        @State private var presentPopover: Bool = false
        
        var body: some ToolbarContent {
            // Top left menu toolbar item
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Button {
                        self.showSettingsView = true
                    } label: {
                        Text("Settings")
                        Image(systemName: "gearshape")
                    }
                    Button {
                        Task {
                            showLoadingIndicator = true
                            UserSettings.shared.lastUpdate = Date.distantPast
                            await viewModel.getCategories()
                            for category in viewModel.categories {
                                await viewModel.getCategory(named: category.name, fetchMode: .preferServer)
                            }
                            await viewModel.updateAllRecipeDetails()
                            showLoadingIndicator = false
                        }
                    } label: {
                        Text("Refresh all")
                        Image(systemName: "icloud.and.arrow.down")
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
                    if showLoadingIndicator {
                        ProgressView()
                    } else if serverConnection {
                        Image(systemName: "checkmark.icloud")
                    } else {
                        Image(systemName: "xmark.icloud")
                    }
                }.popover(isPresented: $presentPopover) {
                    VStack(alignment: .leading) {
                        Text(serverConnection ? LocalizedStringKey("Connected to server.") : LocalizedStringKey("Unable to connect to server."))
                            .bold()
                            
                        Text("Last updated: \(DateFormatter.utcToString(date: UserSettings.shared.lastUpdate))")
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                    }
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

