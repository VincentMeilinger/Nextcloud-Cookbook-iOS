//
//  GroceryListTabView.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 23.01.24.
//

import Foundation
import SwiftUI


// MARK: - Grocery list tab

struct GroceryListTabView: View {
    @EnvironmentObject var groceryList: GroceryList
    @State private var showClearConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(groceryList.sectionKeys, id: \.self) { key in
                    if let recipe = groceryList.groceryDict[key] {
                        GrocerySection(recipeKey: key, recipe: recipe)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollDismissesKeyboard(.interactively)
            .overlay {
                if groceryList.groceryDict.isEmpty {
                    ContentUnavailableView {
                        VStack(spacing: 12) {
                            Text(verbatim: "🍓")
                                .font(.system(size: 56))
                            // Reuses the existing translated title; the emoji is shown above instead.
                            Text(String(localized: "You're all set for cooking 🍓")
                                .replacingOccurrences(of: "🍓", with: "")
                                .trimmingCharacters(in: .whitespaces))
                                .font(.title2.bold())
                        }
                    } description: {
                        VStack(spacing: 8) {
                            Text("Add groceries to this list by either using the button next to an ingredient list in a recipe, or by swiping right on individual ingredients of a recipe.")
                            Text("Your grocery list is stored locally and therefore not synchronized across your devices.")
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                GroceryQuickAddBar()
            }
            .navigationTitle("Grocery List")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Remove Checked Items", systemImage: "checkmark.circle.badge.xmark") {
                            withAnimation { groceryList.removeCheckedItems() }
                        }
                        .disabled(!groceryList.hasCheckedItems)

                        Button("Uncheck All", systemImage: "arrow.uturn.backward.circle") {
                            withAnimation { groceryList.uncheckAll() }
                        }
                        .disabled(!groceryList.hasCheckedItems)

                        Divider()

                        Button("Clear List", systemImage: "trash", role: .destructive) {
                            showClearConfirmation = true
                        }
                    } label: {
                        Label("More", systemImage: "ellipsis.circle")
                    }
                    .disabled(groceryList.groceryDict.isEmpty)
                }
            }
            .confirmationDialog(
                "Clear the whole grocery list?",
                isPresented: $showClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("Clear List", role: .destructive) {
                    withAnimation { groceryList.deleteAll() }
                }
            }
        }
    }
}


// MARK: - Section per recipe

private struct GrocerySection: View {
    @EnvironmentObject var groceryList: GroceryList
    let recipeKey: String
    let recipe: GroceryRecipe

    /// Unchecked items first so the remaining shopping stays at the top.
    private var sortedItems: [GroceryRecipeItem] {
        recipe.items.filter { !$0.isChecked } + recipe.items.filter(\.isChecked)
    }

    private var checkedCount: Int { recipe.items.filter(\.isChecked).count }

    var body: some View {
        Section {
            ForEach(sortedItems) { item in
                GroceryItemRow(item: item) {
                    withAnimation { groceryList.toggleItem(id: item.id, inRecipe: recipeKey) }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        withAnimation { groceryList.deleteItem(id: item.id, fromRecipe: recipeKey) }
                    } label: {
                        // Icon only: a title under the icon shifts it off the row's center.
                        // VoiceOver still reads "Delete".
                        Label("Delete", systemImage: "trash")
                            .labelStyle(.iconOnly)
                    }
                }
            }
        } header: {
            HStack {
                Text(recipe.name)
                Text(verbatim: "\(checkedCount)/\(recipe.items.count)")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                Spacer()
                Menu {
                    Button("Check All", systemImage: "checkmark.circle") {
                        withAnimation { groceryList.setAllChecked(true, inRecipe: recipeKey) }
                    }
                    Button("Remove from List", systemImage: "trash", role: .destructive) {
                        withAnimation { groceryList.deleteGroceryRecipe(recipeKey) }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .imageScale(.large)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(.rect)
                }
                .accessibilityLabel("Options for \(recipe.name)")
            }
        }
    }
}


// MARK: - Item row

private struct GroceryItemRow: View {
    let item: GroceryRecipeItem
    let toggle: () -> Void

    var body: some View {
        // The whole row is the tap target, not just the checkmark.
        Button(action: toggle) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .imageScale(.large)
                    .foregroundStyle(item.isChecked ? Color.nextcloudBlue : Color.secondary)
                    .contentTransition(.symbolEffect(.replace))
                Text(item.name)
                    .strikethrough(item.isChecked)
                    .foregroundStyle(item.isChecked ? .secondary : .primary)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 4)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: item.isChecked)
        .accessibilityAddTraits(item.isChecked ? .isSelected : [])
    }
}


// MARK: - Quick add bar

/// Text field pinned above the tab bar so items can be added with one hand.
/// Return adds the item and keeps the keyboard up for the next one; pasting
/// several lines adds one item per line.
///
/// The field is multi-line so Return arrives as a newline instead of a submit:
/// a submit ends editing, and re-focusing afterwards dropped the first character
/// typed for the next item.
private struct GroceryQuickAddBar: View {
    @EnvironmentObject var groceryList: GroceryList
    @State private var text = ""
    @FocusState private var isFocused: Bool

    private var trimmed: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        HStack(spacing: 8) {
            TextField("Add an item", text: $text, axis: .vertical)
                .lineLimit(1...4)
                .focused($isFocused)
                .onChange(of: text) {
                    if text.contains(where: \.isNewline) { add() }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.background, in: .capsule)
                .overlay(Capsule().strokeBorder(.quaternary))

            Button(action: add) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(trimmed.isEmpty ? Color.secondary : Color.nextcloudBlue)
            }
            .disabled(trimmed.isEmpty)
            .accessibilityLabel("Add item")
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private func add() {
        let items = text
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        text = ""
        guard !items.isEmpty else { return }
        withAnimation {
            groceryList.addItems(items, toRecipe: GroceryList.manualItemsKey, recipeName: String(localized: "Other"))
        }
    }
}


// MARK: - Model

/// Persisted as JSON; keep the coded keys (`name`, `items`) stable.
struct GroceryRecipe: Codable {
    var name: String
    var items: [GroceryRecipeItem]

    init(name: String, items: [GroceryRecipeItem]) {
        self.name = name
        self.items = items
    }
}

/// Persisted as JSON; keep the coded keys (`name`, `isChecked`) stable.
/// `id` is only for SwiftUI identity and is regenerated on load.
struct GroceryRecipeItem: Identifiable, Codable {
    var id = UUID()
    var name: String
    var isChecked: Bool

    init(_ name: String, isChecked: Bool = false) {
        self.name = name
        self.isChecked = isChecked
    }

    private enum CodingKeys: String, CodingKey {
        case name, isChecked
    }
}


@MainActor class GroceryList: ObservableObject {
    /// Section key for items typed in manually rather than added from a recipe.
    static let manualItemsKey = "Other"

    @Published var groceryDict: [String: GroceryRecipe] = [:]

    /// Manually added items first, then recipes sorted by name.
    var sectionKeys: [String] {
        let recipeKeys = groceryDict.keys
            .filter { $0 != Self.manualItemsKey }
            .sorted { (groceryDict[$0]?.name ?? "").localizedStandardCompare(groceryDict[$1]?.name ?? "") == .orderedAscending }
        return groceryDict[Self.manualItemsKey] == nil ? recipeKeys : [Self.manualItemsKey] + recipeKeys
    }

    /// Number of items not checked off yet (shown as the tab badge).
    var remainingCount: Int {
        groceryDict.values.reduce(0) { $0 + $1.items.filter { !$0.isChecked }.count }
    }

    var hasCheckedItems: Bool {
        groceryDict.values.contains { $0.items.contains(where: \.isChecked) }
    }

    // MARK: Adding

    func addItem(_ itemName: String, toRecipe recipeId: String, recipeName: String? = nil, saveGroceryDict: Bool = true) {
        groceryDict[recipeId, default: GroceryRecipe(name: recipeName ?? "-", items: [])]
            .items.append(GroceryRecipeItem(itemName))
        if saveGroceryDict { save() }
    }

    func addItems(_ items: [String], toRecipe recipeId: String, recipeName: String? = nil) {
        for item in items {
            addItem(item, toRecipe: recipeId, recipeName: recipeName, saveGroceryDict: false)
        }
        save()
    }

    // MARK: Removing

    /// Removes the first item with this name (used by the recipe ingredient list).
    func deleteItem(_ itemName: String, fromRecipe recipeId: String) {
        guard let index = groceryDict[recipeId]?.items.firstIndex(where: { $0.name == itemName }) else { return }
        groceryDict[recipeId]?.items.remove(at: index)
        removeRecipeIfEmpty(recipeId)
        save()
    }

    func deleteItem(id: GroceryRecipeItem.ID, fromRecipe recipeId: String) {
        groceryDict[recipeId]?.items.removeAll { $0.id == id }
        removeRecipeIfEmpty(recipeId)
        save()
    }

    func deleteGroceryRecipe(_ recipeId: String) {
        groceryDict.removeValue(forKey: recipeId)
        save()
    }

    func deleteAll() {
        groceryDict = [:]
        save()
    }

    func removeCheckedItems() {
        for key in groceryDict.keys {
            groceryDict[key]?.items.removeAll(where: \.isChecked)
            removeRecipeIfEmpty(key)
        }
        save()
    }

    private func removeRecipeIfEmpty(_ recipeId: String) {
        if groceryDict[recipeId]?.items.isEmpty == true {
            groceryDict.removeValue(forKey: recipeId)
        }
    }

    // MARK: Checking

    func toggleItem(id: GroceryRecipeItem.ID, inRecipe recipeId: String) {
        guard let index = groceryDict[recipeId]?.items.firstIndex(where: { $0.id == id }) else { return }
        groceryDict[recipeId]?.items[index].isChecked.toggle()
        save()
    }

    func setAllChecked(_ checked: Bool, inRecipe recipeId: String) {
        guard var recipe = groceryDict[recipeId] else { return }
        for index in recipe.items.indices { recipe.items[index].isChecked = checked }
        groceryDict[recipeId] = recipe
        save()
    }

    func uncheckAll() {
        for key in groceryDict.keys { setAllChecked(false, inRecipe: key) }
    }

    // MARK: Queries

    func containsItem(at recipeId: String, item: String) -> Bool {
        groceryDict[recipeId]?.items.contains(where: { $0.name == item }) ?? false
    }

    func containsRecipe(_ recipeId: String) -> Bool {
        groceryDict[recipeId] != nil
    }

    // MARK: Persistence

    func save() {
        let dict = groceryDict
        Task { await sharedDataStore.saveGroceryList(dict) }
    }

    func load() async {
        guard let stored = await sharedDataStore.loadGroceryList() else { return }
        // Keep anything added before loading finished instead of dropping it.
        let addedBeforeLoad = groceryDict
        groceryDict = stored.merging(addedBeforeLoad) { _, new in new }
        if !addedBeforeLoad.isEmpty { save() }
    }
}
