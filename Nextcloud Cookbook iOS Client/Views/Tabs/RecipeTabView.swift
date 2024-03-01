//
//  RecipeTabView.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 23.01.24.
//

import Foundation
import SwiftUI


struct RecipeTabView: View {
    @EnvironmentObject var viewModel: RecipeTabView.ViewModel
    @EnvironmentObject var mainViewModel: AppState
    
    var body: some View {
        NavigationSplitView {
            List(selection: $viewModel.selectedCategory) {
                // Categories
                ForEach(mainViewModel.categories) { category in
                    if category.recipe_count != 0 {
                        NavigationLink(value: category) {
                            HStack(alignment: .center) {
                                if viewModel.selectedCategory != nil && category.name == viewModel.selectedCategory!.name {
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
            .toolbar {
                RecipeTabViewToolBar()
            }
            .navigationDestination(isPresented: $viewModel.presentSettingsView) {
                SettingsView()
            }
            .navigationDestination(isPresented: $viewModel.presentEditView) {
                RecipeView(viewModel: RecipeView.ViewModel())
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
        
        /*.sheet(isPresented: $viewModel.presentEditView) {
            RecipeEditView(
                viewModel:
                    RecipeEditViewModel(
                        mainViewModel: mainViewModel,
                        uploadNew: true
                    ),
                isPresented: $viewModel.presentEditView
            )
        }*/
        .task {
            viewModel.serverConnection = await mainViewModel.checkServerConnection()
        }
        .refreshable {
            viewModel.serverConnection = await mainViewModel.checkServerConnection()
            await mainViewModel.getCategories()
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
    @EnvironmentObject var mainViewModel: AppState
    @EnvironmentObject var viewModel: RecipeTabView.ViewModel
    
    var body: some ToolbarContent {
        // Top left menu toolbar item
        ToolbarItem(placement: .topBarLeading) {
            Menu {
                Button {
                    Task {
                        viewModel.presentLoadingIndicator = true
                        UserSettings.shared.lastUpdate = Date.distantPast
                        await mainViewModel.getCategories()
                        for category in mainViewModel.categories {
                            await mainViewModel.getCategory(named: category.name, fetchMode: .preferServer)
                        }
                        await mainViewModel.updateAllRecipeDetails()
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
