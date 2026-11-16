//
//  CookbooksView.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 23.01.24.
//

import Foundation
import SwiftUI


// MARK: - Library state

/// State shared by every screen that shows recipes: sync status, the phone's
/// cookbook navigation path, the Settings sheet and the all-recipes search index.
@MainActor @Observable
final class LibraryModel {
    var isLoading = false
    var serverStatus: AppState.ServerStatus = .unreachable
    var serverConnection: Bool { serverStatus == .connected }
    var showSettings = false
    /// Asks the user to sign in again after the server rejected the stored credentials.
    var showSignInRequired = false
    var showLogin = false
    /// Navigation path of the phone's Recipes tab (cookbooks, then recipes).
    var cookbookPath = NavigationPath()
    /// Every recipe across all cookbooks, used by "Search all recipes".
    var allRecipes: [Recipe] = []

    func checkConnection(_ appState: AppState) async {
        let status = await appState.checkServerConnection()
        // Ask once when it happens, not again on every refresh while it persists
        if status == .signInRequired && serverStatus != .signInRequired {
            showSignInRequired = true
        }
        serverStatus = status
    }

    func loadAllRecipes(_ appState: AppState) async {
        allRecipes = await appState.getRecipes()
    }

    /// Re-downloads cookbooks, recipe lists and (when enabled) recipe details.
    func refreshAll(_ appState: AppState) async {
        isLoading = true
        defer { isLoading = false }
        UserSettings.shared.lastUpdate = .distantPast
        await checkConnection(appState)
        await appState.getCategories()
        for category in appState.categories {
            await appState.getCategory(named: category.name, fetchMode: .preferServer)
        }
        await appState.updateAllRecipeDetails()
    }
}


extension Category {
    /// Recipes without a category are listed under "*" by the server.
    var displayName: String {
        name == "*" ? String(localized: "Other") : name
    }
}


extension View {
    /// Registers the recipe detail screen for `NavigationLink(value: recipe)`.
    /// Apply once at the root of each NavigationStack.
    func recipeDestination() -> some View {
        navigationDestination(for: Recipe.self) { recipe in
            RecipeView(viewModel: RecipeView.ViewModel(recipe: recipe))
        }
    }
}


// MARK: - Phone: Recipes tab

/// Cookbook list with "Search all recipes". Shown as the Recipes tab on iPhone;
/// on iPad the sidebar lists the cookbooks instead.
struct CookbooksView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(LibraryModel.self) private var library
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var searchText = ""
    @State private var showNewRecipe = false
    @State private var createdRecipe: Recipe?

    var body: some View {
        @Bindable var library = library
        NavigationStack(path: $library.cookbookPath) {
            List {
                if searchText.isEmpty {
                    ForEach(appState.categories) { category in
                        NavigationLink(value: category) {
                            CookbookRow(category: category)
                        }
                    }
                } else {
                    RecipeSearchResults(query: searchText)
                }
            }
            .overlay {
                if appState.categories.isEmpty && searchText.isEmpty && !library.isLoading {
                    ContentUnavailableView {
                        Label("No Cookbooks", systemImage: "book.closed")
                    } description: {
                        Text("Sign in to Nextcloud in Settings, or create a recipe with the + button.")
                    }
                }
            }
            .navigationTitle("Cookbooks")
            // On iPad the sidebar has its own Search entry; avoid a second search field.
            .modifier(AllRecipesSearch(text: $searchText, isEnabled: sizeClass != .regular))
            .onChange(of: searchText.isEmpty) { _, isEmpty in
                // Reload when a new search starts so results include recent changes
                if !isEmpty { Task { await library.loadAllRecipes(appState) } }
            }
            .refreshable {
                await library.checkConnection(appState)
                await appState.getCategories()
                if !searchText.isEmpty { await library.loadAllRecipes(appState) }
            }
            .toolbar {
                LibraryToolbar()
                ToolbarItem(placement: .topBarTrailing) {
                    Button("New Recipe", systemImage: "plus") { showNewRecipe = true }
                }
            }
            .navigationDestination(for: Category.self) { category in
                RecipeListView(categoryName: category.name)
            }
            .sheet(isPresented: $showNewRecipe) {
                RecipeEditorView { createdRecipe = $0 }
                    .environmentObject(appState)
                    .environment(library)
            }
            .navigationDestination(item: $createdRecipe) { recipe in
                RecipeView(viewModel: RecipeView.ViewModel(recipe: recipe))
            }
            .recipeDestination()
        }
    }
}


private struct AllRecipesSearch: ViewModifier {
    @Binding var text: String
    let isEnabled: Bool

    func body(content: Content) -> some View {
        if isEnabled {
            content.searchable(text: $text, prompt: "Search all recipes")
        } else {
            content
        }
    }
}


private struct CookbookRow: View {
    let category: Category

    var body: some View {
        Label {
            HStack {
                Text(category.displayName)
                Spacer()
                Text(category.recipe_count, format: .number)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: "book.closed.fill")
        }
    }
}


// MARK: - iPad: one cookbook per sidebar entry

/// Root of a cookbook entry in the iPad sidebar.
struct CookbookTab: View {
    let category: Category

    var body: some View {
        NavigationStack {
            RecipeListView(categoryName: category.name)
                .toolbar { LibraryToolbar() }
                .recipeDestination()
        }
    }
}


// MARK: - iPad: Search sidebar entry

/// Root of the Search entry in the iPad sidebar. Lists every recipe and filters
/// as you type.
struct RecipeSearchTab: View {
    @EnvironmentObject private var appState: AppState
    @Environment(LibraryModel.self) private var library
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            List {
                RecipeSearchResults(query: searchText)
            }
            .listStyle(.plain)
            .navigationTitle("All Recipes")
            .searchable(text: $searchText, prompt: "Search all recipes")
            .task { await library.loadAllRecipes(appState) }
            .refreshable { await library.loadAllRecipes(appState) }
            .toolbar { LibraryToolbar() }
            .recipeDestination()
        }
    }
}


// MARK: - Shared pieces

/// Recipes from every cookbook whose name or keywords match `query`
/// (all recipes when `query` is empty). Place inside a List.
struct RecipeSearchResults: View {
    @Environment(LibraryModel.self) private var library
    let query: String

    private var matches: [Recipe] {
        guard !query.isEmpty else { return library.allRecipes }
        return library.allRecipes.filter { recipe in
            recipe.name.localizedCaseInsensitiveContains(query)
                || (recipe.keywords?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    var body: some View {
        if matches.isEmpty && !query.isEmpty {
            ContentUnavailableView.search(text: query)
                .listRowSeparator(.hidden)
        } else {
            ForEach(matches) { recipe in
                RecipeRow(recipe: recipe)
            }
        }
    }
}


/// A recipe card that opens the recipe. Place inside a List whose stack
/// applies `.recipeDestination()`.
struct RecipeRow: View {
    let recipe: Recipe

    var body: some View {
        RecipeCardView(recipe: recipe)
            .shadow(radius: 2)
            .background(
                // Invisible link: keeps the card's look without a disclosure chevron
                NavigationLink(value: recipe) { EmptyView() }
                    .opacity(0)
            )
            .frame(height: 85)
            .listRowInsets(EdgeInsets(top: 5, leading: 15, bottom: 5, trailing: 15))
            .listRowSeparator(.hidden)
    }
}


/// ⋯ menu (Refresh all, Settings) and the server status button, shown on
/// every recipe library screen.
struct LibraryToolbar: ToolbarContent {
    @EnvironmentObject private var appState: AppState
    @Environment(LibraryModel.self) private var library
    @State private var showStatus = false

    private var statusSymbol: String {
        if library.isLoading { return "arrow.clockwise.icloud" }
        switch library.serverStatus {
        case .connected: return "checkmark.icloud"
        case .unreachable: return "xmark.icloud"
        case .signInRequired: return "exclamationmark.icloud"
        }
    }

    private var statusText: LocalizedStringKey {
        switch library.serverStatus {
        case .connected: return "Connected to server."
        case .unreachable: return "Unable to connect to server."
        case .signInRequired: return "Your Nextcloud sign-in is no longer valid. Sign out and sign in again in Settings."
        }
    }

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Menu {
                Button("Refresh all", systemImage: "icloud.and.arrow.down") {
                    Task { await library.refreshAll(appState) }
                }
                .disabled(library.isLoading)

                Button("Settings", systemImage: "gearshape") {
                    library.showSettings = true
                }
            } label: {
                Label("More", systemImage: "ellipsis.circle")
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showStatus = true
            } label: {
                // Always a single Image: swapping in a different view (e.g. a ProgressView)
                // replaces the view that iOS 26 animates menus and popovers from, which
                // crashes UIKit if it happens mid-animation (e.g. after "Refresh all").
                Image(systemName: statusSymbol)
                    .symbolEffect(.pulse, isActive: library.isLoading)
                    .contentTransition(.symbolEffect(.replace))
            }
            .accessibilityLabel(statusText)
            .popover(isPresented: $showStatus) {
                VStack(alignment: .leading) {
                    Text(statusText)
                        .bold()
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Last updated: \(lastUpdateText)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: 300, alignment: .leading)
                .padding()
                .presentationCompactAdaptation(.popover)
            }
        }
    }

    private var lastUpdateText: String {
        let date = UserSettings.shared.lastUpdate
        return date == .distantPast ? String(localized: "Never") : date.formatted(date: .abbreviated, time: .shortened)
    }
}
