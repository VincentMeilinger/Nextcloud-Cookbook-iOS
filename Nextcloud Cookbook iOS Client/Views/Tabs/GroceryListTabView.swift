//
//  GroceryListTabView.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 23.01.24.
//

import Foundation
import SwiftUI


struct GroceryListTabView: View {
    @EnvironmentObject var groceryList: GroceryList
    @State var newGroceries: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            if groceryList.groceryDict.isEmpty {
                EmptyGroceryListView(newGroceries: $newGroceries)
            } else {
                List {
                    HStack(alignment: .top) {
                        TextEditor(text: $newGroceries)
                            .padding(4)
                            .overlay(RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary).opacity(0.5))
                            .focused($isFocused)
                        Button {
                            if !newGroceries.isEmpty {
                                let items = newGroceries
                                    .split(separator: "\n")
                                    .compactMap { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                    .filter { !$0.isEmpty }
                                groceryList.addItems(items, toRecipe: "Other", recipeName: String(localized: "Other"))
                            }
                            newGroceries = ""
                            
                        } label: {
                            Text("Add")
                        }
                        .disabled(newGroceries.isEmpty)
                        .buttonStyle(.borderedProminent)
                    }
                    
                    ForEach(groceryList.groceryDict.keys.sorted(), id: \.self) { key in
                        Section {
                            ForEach(groceryList.groceryDict[key]!.items) { item in
                                GroceryListItemView(item: item, toggleAction: {
                                    groceryList.toggleItemChecked(item)
                                }, deleteAction: {
                                    withAnimation {
                                        groceryList.deleteItem(item.name, fromRecipe: key)
                                    }
                                })
                            }
                        } header: {
                            HStack {
                                Text(groceryList.groceryDict[key]!.name)
                                    .foregroundStyle(Color.nextcloudBlue)
                                Spacer()
                                Button {
                                    groceryList.deleteGroceryRecipe(key)
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(Color.nextcloudBlue)
                                }
                            }
                        }
                    }
                }
                
                .listStyle(.plain)
                .navigationTitle("Grocery List")
                .toolbar {
                    Button {
                        groceryList.deleteAll()
                    } label: {
                        Text("Delete")
                            .foregroundStyle(Color.nextcloudBlue)
                    }
                }
                .onTapGesture {
                    isFocused = false
                }
            }
        }
    }
}



fileprivate struct GroceryListItemView: View {
    let item: GroceryRecipeItem
    let toggleAction: () -> Void
    let deleteAction: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            if item.isChecked {
                Image(systemName: "checkmark.circle")
            } else {
                Image(systemName: "circle")
            }

            Text("\(item.name)")
                .multilineTextAlignment(.leading)
                .lineLimit(5)
        }
        .padding(5)
        .foregroundStyle(item.isChecked ? Color.secondary : Color.primary)
        .onTapGesture(perform: toggleAction)
        .animation(.easeInOut, value: item.isChecked)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(action: deleteAction) {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)
        }
    }
}



fileprivate struct EmptyGroceryListView: View {
    @EnvironmentObject var groceryList: GroceryList
    @Binding var newGroceries: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        List {
            Text("You're all set for cooking 🍓")
                .font(.headline)
            Text("Add groceries to this list by either using the button next to an ingredient list in a recipe, or by swiping right on individual ingredients of a recipe.")
                .foregroundStyle(.secondary)
            Text("Your grocery list is stored locally and therefore not synchronized across your devices.")
                .foregroundStyle(.secondary)
            Text("To add grocieries manually, type them in the box below and press the button. To add multiple items at once, separate them by a new line.")
                .foregroundStyle(.secondary)
            HStack(alignment: .top) {
                TextEditor(text: $newGroceries)
                    .padding(4)
                    .overlay(RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary).opacity(0.5))
                    .focused($isFocused)
                Button {
                    if !newGroceries.isEmpty {
                        let items = newGroceries
                            .split(separator: "\n")
                            .compactMap { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }
                        groceryList.addItems(items, toRecipe: "Other", recipeName: String(localized: "Other"))
                    }
                    newGroceries = ""
                } label: {
                    Text("Add")
                }
                .disabled(newGroceries.isEmpty)
                .buttonStyle(.borderedProminent)
            }
            .padding(.bottom, 4)
        }
        .navigationTitle("Grocery List")
        .onTapGesture {
            isFocused = false
        }
    }
}


// Grocery List Logic


class GroceryRecipe: Identifiable, Codable {
    let name: String
    var items: [GroceryRecipeItem]
    
    init(name: String, items: [GroceryRecipeItem]) {
        self.name = name
        self.items = items
    }
    
    init(name: String, item: GroceryRecipeItem) {
        self.name = name
        self.items = [item]
    }
}



class GroceryRecipeItem: Identifiable, Codable {
    let name: String
    var isChecked: Bool
    
    init(_ name: String, isChecked: Bool = false) {
        self.name = name
        self.isChecked = isChecked
    }
}



@MainActor class GroceryList: ObservableObject {
    let dataStore: DataStore = DataStore()
    @Published var groceryDict: [String: GroceryRecipe] = [:]
    @Published var sortBySimilarity: Bool = false
    
    
    func addItem(_ itemName: String, toRecipe recipeId: String, recipeName: String? = nil, saveGroceryDict: Bool = true) {
        print("Adding item of recipe \(String(describing: recipeName))")
        DispatchQueue.main.async {
            
            
            if self.groceryDict[recipeId] != nil {
                self.groceryDict[recipeId]?.items.append(GroceryRecipeItem(itemName))
            } else {
                let newRecipe = GroceryRecipe(name: recipeName ?? "-", items: [GroceryRecipeItem(itemName)])
                self.groceryDict[recipeId] = newRecipe
            }
            if saveGroceryDict {
                self.save()
                
            }
            self.objectWillChange.send()
        }
    }
    
    func addItems(_ items: [String], toRecipe recipeId: String, recipeName: String? = nil) {
        for item in items {
            addItem(item, toRecipe: recipeId, recipeName: recipeName, saveGroceryDict: false)
        }
        self.save()
        self.objectWillChange.send()
    }
    
    func deleteItem(_ itemName: String, fromRecipe recipeId: String) {
        print("Deleting item \(itemName)")
        guard let recipe = groceryDict[recipeId] else { return }
        guard let itemIndex = groceryDict[recipeId]?.items.firstIndex(where: { $0.name == itemName }) else { return }
        groceryDict[recipeId]?.items.remove(at: itemIndex)
        if groceryDict[recipeId]!.items.isEmpty {
            groceryDict.removeValue(forKey: recipeId)
        }
        save()
        self.objectWillChange.send()
    }
    
    func deleteGroceryRecipe(_ recipeId: String) {
        print("Deleting grocery recipe with id \(recipeId)")
        groceryDict.removeValue(forKey: recipeId)
        save()
        self.objectWillChange.send()
    }
    
    func deleteAll() {
        print("Deleting all grocery items")
        groceryDict = [:]
        save()
        self.objectWillChange.send()
    }
    
    func toggleItemChecked(_ groceryItem: GroceryRecipeItem) {
        print("Item checked: \(groceryItem.name)")
        groceryItem.isChecked.toggle()
        save()
        self.objectWillChange.send()
    }
    
    func containsItem(at recipeId: String, item: String) -> Bool {
        guard let recipe = groceryDict[recipeId] else { return false }
        if recipe.items.contains(where: { $0.name == item }) {
            return true
        }
        return false
    }
    
    func containsRecipe(_ recipeId: String) -> Bool {
        return groceryDict[recipeId] != nil
    }
    
    func save() {
        Task {
            await dataStore.save(data: groceryDict, toPath: "grocery_list.data")
        }
    }
    
    func load() async {
        do {
            guard let groceryDict: [String: GroceryRecipe] = try await dataStore.load(
                fromPath: "grocery_list.data"
            ) else { return }
            self.groceryDict = groceryDict
        } catch {
            print("Unable to load grocery list")
        }
    }
}


