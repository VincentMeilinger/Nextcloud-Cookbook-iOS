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


struct EditableStringList<Content: View>: View {
    @Binding var items: [ReorderableItem<String>]
    @Binding var editMode: Bool
    @State var titleKey: LocalizedStringKey = ""
    @State var lineLimit: ClosedRange<Int> = 0...50
    @State var axis: Axis = .vertical
    
    var content: () -> Content
    
    var body: some View {
        if editMode {
            VStack {
                ReorderableForEach(items: $items, defaultItem: ReorderableItem(item: "")) { ix, item in
                    TextField("", text: $items[ix].item, axis: axis)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(lineLimit)
                }
            }
            .transition(.slide)
        } else {
            content()
        }
    }
}
