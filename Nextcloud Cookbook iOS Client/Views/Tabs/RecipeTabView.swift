//
//  RecipeTabView.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 23.01.24.
//

import Foundation
import SwiftUI


struct RecipeTabView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var groceryList: GroceryList
    @EnvironmentObject var viewModel: RecipeTabView.ViewModel
    
    var body: some View {
        NavigationSplitView {
            List(selection: $viewModel.selectedCategory) {
                // Categories
                ForEach(appState.categories) { category in
                    NavigationLink(value: category) {
                        HStack(alignment: .center) {
                            if viewModel.selectedCategory != nil &&
                                category.name == viewModel.selectedCategory!.name {
                                Image(systemName: "book")
                            } else {
                                Image(systemName: "book.closed.fill")
                            }
                            
                            if category.name == "*" {
                                Text("Other")
                                    .font(.system(size: 20, weight: .medium, design: .default))
                            } else {
                                Text(category.name)
                                    .font(.system(size: 20, weight: .medium, design: .default))
                            }
                                
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
            .navigationTitle("Cookbooks")
            .toolbar {
                RecipeTabViewToolBar()
            }
            .navigationDestination(isPresented: $viewModel.presentSettingsView) {
                SettingsView()
                    .environmentObject(appState)
            }
            .navigationDestination(isPresented: $viewModel.presentEditView) {
                RecipeView(viewModel: RecipeView.ViewModel())
                    .environmentObject(appState)
                    .environmentObject(groceryList)
            }
        } detail: {
            NavigationStack {
                if let category = viewModel.selectedCategory {
                    RecipeListView(
                        categoryName: category.name,
                        showEditView: $viewModel.presentEditView
                    )
                    .id(category.id) // Workaround: This is needed to update the detail view when the selection changes
                }
                
            }
        }
        .tint(.nextcloudBlue)
        .task {
            let connection = await appState.checkServerConnection()
            DispatchQueue.main.async {
                viewModel.serverConnection = connection
            }
        }
        .refreshable {
            let connection = await appState.checkServerConnection()
            DispatchQueue.main.async {
                viewModel.serverConnection = connection
            }
            await appState.getCategories()
        }
    }
    
    class ViewModel: ObservableObject {
        @Published var presentEditView: Bool = false
        @Published var presentSettingsView: Bool = false
        
        @Published var presentLoadingIndicator: Bool = false
        @Published var presentConnectionPopover: Bool = false
        @Published var serverConnection: Bool = false
        
        @Published var selectedCategory: Category? = nil
    }
}



fileprivate struct RecipeTabViewToolBar: ToolbarContent {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewModel: RecipeTabView.ViewModel
    
    var body: some ToolbarContent {
        // Top left menu toolbar item
        ToolbarItem(placement: .topBarLeading) {
            Menu {
                Button {
                    Task {
                        viewModel.presentLoadingIndicator = true
                        UserSettings.shared.lastUpdate = Date.distantPast
                        await appState.getCategories()
                        for category in appState.categories {
                            await appState.getCategory(named: category.name, fetchMode: .preferServer)
                        }
                        await appState.updateAllRecipeDetails()
                        viewModel.presentLoadingIndicator = false
                    }
                } label: {
                    Text("Refresh all")
                    Image(systemName: "icloud.and.arrow.down")
                }
                
                Button {
                    viewModel.presentSettingsView = true
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
                viewModel.presentConnectionPopover = true
            } label: {
                if viewModel.presentLoadingIndicator {
                    ProgressView()
                } else if viewModel.serverConnection {
                    Image(systemName: "checkmark.icloud")
                } else {
                    Image(systemName: "xmark.icloud")
                }
            }.popover(isPresented: $viewModel.presentConnectionPopover) {
                VStack(alignment: .leading) {
                    Text(viewModel.serverConnection ? LocalizedStringKey("Connected to server.") : LocalizedStringKey("Unable to connect to server."))
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
                viewModel.presentEditView = true
            } label: {
                Image(systemName: "plus.circle.fill")
            }
        }
    
    }
}
