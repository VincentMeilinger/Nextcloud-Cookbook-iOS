//
//  MainView.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 06.09.23.
//

import SwiftUI

/// Top-level destinations.
enum AppTab: Hashable {
    /// iPhone: the cookbook list. On iPad it is hidden from the sidebar.
    case cookbooks
    case groceryList
    /// iPad only: search across all recipes.
    case search
    /// iPad only: one sidebar entry per cookbook (category name).
    case cookbook(String)
}

/// One TabView for every device. On iPhone it shows a tab bar with Recipes and
/// Grocery List. On iPad (`.sidebarAdaptable`) it becomes a sidebar with Search,
/// Grocery List and a "Cookbooks" section listing each cookbook.
struct MainView: View {
    @StateObject private var appState = AppState()
    @StateObject private var groceryList = GroceryList()
    @State private var library = LibraryModel()
    @ObservedObject private var settings = UserSettings.shared
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var selection: AppTab = .cookbooks
    private let quickActions = QuickActions.shared

    private var isWide: Bool { sizeClass == .regular }

    var body: some View {
        TabView(selection: $selection) {
            Tab("Recipes", systemImage: "book.closed.fill", value: AppTab.cookbooks) {
                CookbooksView()
            }
            .defaultVisibility(.hidden, for: .sidebar)

            Tab("Grocery List", systemImage: "cart", value: AppTab.groceryList) {
                GroceryListTabView()
            }
            .badge(groceryList.remainingCount)

            // The tab bar would show every cookbook as its own tab, so these
            // entries only exist when there is room for the sidebar.
            if isWide {
                Tab(value: AppTab.search, role: .search) {
                    RecipeSearchTab()
                }

                TabSection("Cookbooks") {
                    ForEach(appState.categories) { category in
                        // The selected cookbook is shown as an open book
                        Tab(
                            category.displayName,
                            systemImage: selection == .cookbook(category.name) ? "book" : "book.closed.fill",
                            value: AppTab.cookbook(category.name)
                        ) {
                            CookbookTab(category: category)
                        }
                        .badge(category.recipe_count)
                    }
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .tint(.nextcloudBlue)
        .environmentObject(appState)
        .environmentObject(groceryList)
        .environment(library)
        .sheet(isPresented: $library.showSettings) {
            SettingsSheet()
                .environmentObject(appState)
        }
        .sheet(isPresented: $library.showLogin) {
            LoginView()
        }
        .alert("Sign In Required", isPresented: $library.showSignInRequired) {
            Button("Sign In") { library.showLogin = true }
            Button("Not Now", role: .cancel) {}
        } message: {
            Text("Nextcloud no longer accepts this app's sign-in, for example because the app password was revoked. Sign in again to sync your recipes.")
        }
        .task {
            QuickActions.registerShortcuts()
            // Load the grocery list before anything can modify it; saving an
            // unloaded list would overwrite the stored one.
            await sharedDataStore.migrateLegacyFiles()
            await groceryList.load()
            await loadLibrary()
            openDefaultCookbook()
        }
        // When the user signs in while the app is running, reload from the server
        .onChange(of: settings.authString) {
            guard settings.isLoggedIn else { return }
            Task { await loadLibrary() }
        }
        .onChange(of: sizeClass) { adaptSelectionToSizeClass() }
        .onChange(of: appState.categories) { keepSelectionValid() }
        .onChange(of: quickActions.requestedTab, initial: true) {
            guard let tab = quickActions.requestedTab else { return }
            selection = tab
            quickActions.requestedTab = nil
        }
    }

    // MARK: - Loading

    private func loadLibrary() async {
        library.isLoading = true
        await library.checkConnection(appState)
        await appState.getCategories()
        await appState.updateAllRecipeDetails()
        library.isLoading = false
    }

    /// Opens the cookbook chosen in Settings → "Select a default cookbook".
    private func openDefaultCookbook() {
        let name = settings.defaultCategory
        guard !name.isEmpty, selection == .cookbooks,
              let category = appState.categories.first(where: { $0.name == name })
        else { return }
        if isWide {
            selection = .cookbook(category.name)
        } else {
            library.cookbookPath.append(category)
        }
    }

    // MARK: - Selection

    /// The iPad-only entries disappear in compact width (iPhone, Slide Over,
    /// narrow Split View). Move the selection to the equivalent place.
    private func adaptSelectionToSizeClass() {
        if isWide {
            if selection == .cookbooks, let first = appState.categories.first {
                selection = .cookbook(first.name)
                library.cookbookPath = NavigationPath()
            }
        } else {
            switch selection {
            case .cookbook(let name):
                selection = .cookbooks
                var path = NavigationPath()
                if let category = appState.categories.first(where: { $0.name == name }) {
                    path.append(category)
                }
                library.cookbookPath = path
            case .search:
                selection = .cookbooks
            case .cookbooks, .groceryList:
                break
            }
        }
    }

    /// Leaves a cookbook entry that no longer exists (deleted, signed out).
    private func keepSelectionValid() {
        guard case .cookbook(let name) = selection,
              !appState.categories.contains(where: { $0.name == name })
        else { return }
        selection = appState.categories.first.map { .cookbook($0.name) } ?? .cookbooks
    }
}


/// Settings presented as a sheet so it can be opened from any screen.
private struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            SettingsView()
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}
