//
//  GroceryListTabView.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 23.01.24.
//

import Foundation
import SwiftUI


struct GroceryListTabView: View {
    var body: some View {
        NavigationStack {
            if GroceryList.shared.listItems.isEmpty {
                List {
                    Text("You're all set for cooking 🍓")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("Add groceries to this list by either using the button next to an ingredient list in a recipe, or by swiping right on individual ingredients of a recipe.")
                        
                        .foregroundStyle(.secondary)
                }
                .padding()
                .navigationTitle("Grocery List")
            } else {
                List(GroceryList.shared.listItems) { item in
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
                    .foregroundStyle(item.isChecked ? Color.secondary : Color.primary)
                    .onTapGesture {
                        item.isChecked.toggle()
                    }
                    .animation(.easeInOut, value: item.isChecked)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button {
                            GroceryList.shared.removeItem(item.name)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(.red)
                    }
                }
                .padding()
                .navigationTitle("Grocery List")
            }
            
        }
    }
}



class GroceryListItem: ObservableObject, Identifiable, Codable {
    var name: String
    var isChecked: Bool
    
    init(_ name: String, isChecked: Bool = false) {
        self.name = name
        self.isChecked = isChecked
    }
}



class GroceryList: ObservableObject {
    static let shared: GroceryList = GroceryList()
    
    let dataStore: DataStore = DataStore()
    @Published var listItems: [GroceryListItem] = []
    
    
    func addItem(_ name: String) {
        listItems.append(GroceryListItem(name))
        save()
    }
    
    func addItems(_ items: [String]) {
        for item in items {
            addItem(item)
        }
        save()
    }
    
    func removeItem(_ name: String) {
        guard let ix = listItems.firstIndex(where: { item in
            item.name == name
        }) else { return }
        listItems.remove(at: ix)
        save()
    }
    
    func save() {
        Task {
            await dataStore.save(data: listItems, toPath: "grocery_list.data")
        }
    }
    
    func load() async {
        do {
            guard let listItems: [GroceryListItem] = try await dataStore.load(
                fromPath: "grocery_list.data"
            ) else { return }
            self.listItems = listItems
        } catch {
            print("Unable to load grocery list")
        }
    }
}
