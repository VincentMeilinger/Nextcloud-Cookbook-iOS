//
//  RecipeSectionStructureViews.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 01.03.24.
//

import Foundation
import SwiftUI

// MARK: - RecipeView Generic Editable View Elements


struct RecipeListSection: View {
    @State var list: [String]
    
    var body: some View {
        VStack(alignment: .leading) {
            ForEach(list, id: \.self) { item in
                HStack(alignment: .top) {
                    Text("\u{2022}")
                    Text("\(item)")
                        .multilineTextAlignment(.leading)
                }
                .padding(4)
            }
        }
    }
}


struct SecondaryLabel: View {
    let text: LocalizedStringKey
    var body: some View {
        Text(text)
            .foregroundColor(.secondary)
            .font(.headline)
            .padding(.vertical, 5)
    }
}


struct EditableText: View {
    @Binding var text: String
    @Binding var editMode: Bool
    @State var titleKey: LocalizedStringKey = ""
    @State var lineLimit: ClosedRange<Int> = 0...1
    @State var axis: Axis = .horizontal
    
    var body: some View {
        if editMode {
            TextField(titleKey, text: $text, axis: axis)
                .textFieldStyle(.roundedBorder)
                .lineLimit(lineLimit)
        } else {
            Text(text)
        }
    }
}


struct EditableListView: View {
    @Binding var isPresented: Bool
    @Binding var items: [String]
    @State var title: LocalizedStringKey
    @State var emptyListText: LocalizedStringKey
    @State var titleKey: LocalizedStringKey = ""
    @State var lineLimit: ClosedRange<Int> = 0...50
    @State var axis: Axis = .vertical
    
    var body: some View {
        NavigationView {
            ZStack {
                List {
                    if items.isEmpty {
                        Text(emptyListText)
                    }
                    
                    ForEach(items.indices, id: \.self) { ix in
                        TextField(titleKey, text: $items[ix], axis: axis)
                            .lineLimit(lineLimit)
                    }
                    .onDelete(perform: deleteItem)
                    .onMove(perform: moveItem)
                }
                VStack {
                    Spacer()
                    
                    Button {
                        addItem()
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(.white)
                            .bold()
                            .padding()
                            .background(Circle().fill(Color.nextcloudBlue))
                    }
                    .padding()
                }
            }
            .navigationBarTitle(title, displayMode: .inline)
            .navigationBarItems(
                trailing: Button(action: { isPresented = false }) {
                    Text("Done")
                }
            )
            .environment(\.editMode, .constant(.active)) // Bind edit mode to your state variable
        }
    }
    
    private func addItem() {
        withAnimation {
            items.append("")
        }
    }

    private func deleteItem(at offsets: IndexSet) {
        withAnimation {
            items.remove(atOffsets: offsets)
        }
    }

    private func moveItem(from source: IndexSet, to destination: Int) {
        withAnimation {
            items.move(fromOffsets: source, toOffset: destination)
        }
    }
}



// MARK: - Previews

struct EditableListView_Previews: PreviewProvider {
    // Sample keywords for preview
    @State static var sampleList: [String] = [
        /*"3 Eggs",
        "1 kg Potatos",
        "3 g Sugar",
        "1 ml Milk",
        "Salt, Pepper"*/
    ]
    
    static var previews: some View {
        Color.white
            .sheet(isPresented: .constant(true), content: {
                EditableListView(isPresented: .constant(true), items: $sampleList, title: "Ingredient", emptyListText: "Add cooking steps for fellow chefs to follow.")
            })
            
    }
}
