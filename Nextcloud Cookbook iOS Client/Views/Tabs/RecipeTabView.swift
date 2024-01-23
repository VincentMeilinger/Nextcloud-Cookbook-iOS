//
//  RecipeTabView.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 23.01.24.
//

import Foundation
import SwiftUI


struct RecipeTabView: View {
    @Binding var selectedCategory: Category?
    @Binding var showLoadingIndicator: Bool
    
    @EnvironmentObject var viewModel: MainViewModel
    @StateObject var userSettings: UserSettings = UserSettings.shared
    
    @State private var showEditView: Bool = false
    @State private var serverConnection: Bool = false
    
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedCategory) {
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
            .toolbar {
                RecipeTabViewToolBar(
                    viewModel: viewModel,
                    showEditView: $showEditView,
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
            self.serverConnection = await viewModel.checkServerConnection()
        }
        .refreshable {
            self.serverConnection = await viewModel.checkServerConnection()
            await viewModel.getCategories()
        }
    }
}


fileprivate struct RecipeTabViewToolBar: ToolbarContent {
    @ObservedObject var viewModel: MainViewModel
    @Binding var showEditView: Bool
    @Binding var serverConnection: Bool
    @Binding var showLoadingIndicator: Bool
    @State private var presentPopover: Bool = false
    
    var body: some ToolbarContent {
        // Top left menu toolbar item
        ToolbarItem(placement: .topBarLeading) {
            Menu {
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
