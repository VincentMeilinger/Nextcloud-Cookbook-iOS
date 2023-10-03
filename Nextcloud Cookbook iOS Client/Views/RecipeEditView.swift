//
//  RecipeEditView.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 29.09.23.
//

import Foundation
import SwiftUI
import PhotosUI


struct RecipeEditView: View {
    @State var recipe: RecipeDetail = RecipeDetail()
    
    @State var image: PhotosPickerItem? = nil
    @State var times = [Date.zero, Date.zero, Date.zero]
    @State var searchText: String = ""
    @State var keywords: [String] = []
    
    init(recipe: RecipeDetail? = nil) {
        self.recipe = recipe ?? RecipeDetail()
    }
    
    var body: some View {
        Form {
            TextField("Title", text: $recipe.name)
            TextField("Description", text: $recipe.description)
            PhotosPicker(selection: $image, matching: .images, photoLibrary: .shared()) {
                Image(systemName: "photo")
                    .symbolRenderingMode(.multicolor)
            }
            .buttonStyle(.borderless)
            
            Section() {
                NavigationLink("Keywords") {
                    KeywordPickerView(title: "Keyword", searchSuggestions: [], selection: $keywords)
                }
            } header: {
                Text("Keywords")
            } footer: {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(keywords, id: \.self) { keyword in
                            Text(keyword)
                        }
                    }
                }
            }
            
            Section() {
                Picker("Yield/Portions:", selection: $recipe.recipeYield) {
                    ForEach(0..<99, id: \.self) { i in
                        Text("\(i)").tag(i)
                    }
                }
                .pickerStyle(.menu)
                DatePicker("Prep time:", selection: $times[0], displayedComponents: .hourAndMinute)
                DatePicker("Cook time:", selection: $times[1], displayedComponents: .hourAndMinute)
                DatePicker("Total time:", selection: $times[2], displayedComponents: .hourAndMinute)
            }
            
            EditableListSection(title: "Ingredients", items: $recipe.recipeIngredient)
            EditableListSection(title: "Tools", items: $recipe.tool)
            EditableListSection(title: "Instructions", items: $recipe.recipeInstructions)
        }.navigationTitle("New Recipe")
    }
}



struct SearchField: View {
    @State var title: String
    @State var text: String
    @State var searchSuggestions: [String]
    
    var body: some View {
        TextField(title, text: $text)
            .searchSuggestions {
                ForEach(searchSuggestions, id: \.self) { suggestion in
                    Text(suggestion).searchCompletion(suggestion)
                }
            }
    }
}


struct EditableListSection: View {
    @State var title: String
    @Binding var items: [String]
        
    var body: some View {
        Section() {
            List {
                ForEach(items.indices, id: \.self) { ix in
                    HStack(alignment: .top) {
                        Text("\(ix+1).")
                            .padding(.vertical, 10)
                        TextEditor(text: $items[ix])
                            .multilineTextAlignment(.leading)
                            .textFieldStyle(.plain)
                            .padding(.vertical, 1)
                    }
                }
                .onMove { indexSet, offset in
                    items.move(fromOffsets: indexSet, toOffset: offset)
                }
                .onDelete { indexSet in
                    items.remove(atOffsets: indexSet)
                }
            }
            
            HStack {
                Spacer()
                Text("Add")
                Button() {
                    items.append("")
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
        } header: {
            HStack {
                Text(title)
                Spacer()
                EditButton()
            }
        }
    }
}


struct TimePicker: View {
    @Binding var hours: Int
    @Binding var minutes: Int

    var body: some View {
        HStack {
            Picker("", selection: $hours) {
                ForEach(0..<99, id: \.self) { i in
                    Text("\(i) hours").tag(i)
                }
            }.pickerStyle(.wheel)
            Picker("", selection: $minutes) {
                ForEach(0..<60, id: \.self) { i in
                    Text("\(i) min").tag(i)
                }
            }.pickerStyle(.wheel)
        }
        .padding(.horizontal)
    }
}

