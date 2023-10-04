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
    @ObservedObject var viewModel: MainViewModel
    @State var recipe: RecipeDetail = RecipeDetail()
    @Binding var isPresented: Bool
    
    @State var image: PhotosPickerItem? = nil
    @State var times = [Date.zero, Date.zero, Date.zero]
    @State var uploadNew: Bool = true
    @State var searchText: String = ""
    @State var keywords: [String] = []
    
    @State private var alertMessage: String = ""
    @State private var presentAlert: Bool = false
    
    var body: some View {
        Form {
            TextField("Title", text: $recipe.name)
            Section {
                TextEditor(text: $recipe.description)
            } header: {
                Text("Description")
            }
            /*
            PhotosPicker(selection: $image, matching: .images, photoLibrary: .shared()) {
                Image(systemName: "photo")
                    .symbolRenderingMode(.multicolor)
            }
            .buttonStyle(.borderless)
            */
            Section() {
                NavigationLink(recipe.recipeCategory == "" ? "Category" : "Category: \(recipe.recipeCategory)") {
                    CategoryPickerView(title: "Category", searchSuggestions: [], selection: $recipe.recipeCategory)
                }
                NavigationLink("Keywords") {
                    KeywordPickerView(
                        title: "Keywords",
                        searchSuggestions: [
                            Keyword("Hauptspeisen"),
                            Keyword("Lecker"),
                            Keyword("Trinken"),
                            Keyword("Essen"),
                            Keyword("Nachspeisen"),
                            Keyword("Futter"),
                            Keyword("Apfel"),
                            Keyword("test")
                        ],
                        selection: $keywords
                    )
                }
            } header: {
                Text("Discoverability")
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
        }.navigationTitle("Edit your recipe")
        .toolbar {
            Menu {
                Button {
                    print("Delete recipe.")
                    deleteRecipe()
                    self.isPresented = false
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                    Text("Delete recipe")
                        .foregroundStyle(.red)
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            Button() {
                if uploadNew {
                    uploadNewRecipe()
                } else {
                    uploadEditedRecipe()
                }
            } label: {
                Image(systemName: "icloud.and.arrow.up")
                Text(uploadNew ? "Upload" : "Update")
                    .bold()
            }
        }
        .onAppear {
            if uploadNew { return }
            if let prepTime = recipe.prepTime {
                self.times[0] = Date.fromPTRepresentation(prepTime)
            }
            if let cookTime = recipe.cookTime {
                self.times[1] = Date.fromPTRepresentation(cookTime)
            }
            if let totalTime = recipe.totalTime {
                self.times[2] = Date.fromPTRepresentation(totalTime)
            }
            
            for keyword in recipe.keywords.components(separatedBy: ",") {
                keywords.append(keyword)
            }
        }
        .alert(alertMessage, isPresented: $presentAlert) {
            Button("Ok", role: .cancel) {
                self.isPresented = false
            }
        }
    }
    
    func createRecipe() {
        print(self.recipe.name)
        if let date = Date.toPTRepresentation(date: times[0]) {
            self.recipe.prepTime = date
        }
        if let date = Date.toPTRepresentation(date: times[1]) {
            self.recipe.cookTime = date
        }
        if let date = Date.toPTRepresentation(date: times[2]) {
            self.recipe.totalTime = date
        }
        self.recipe.keywords = self.keywords.joined(separator: ",")
    }
    
    func uploadNewRecipe() {
        print("Uploading new recipe.")
        createRecipe()
        let request = RequestWrapper.customRequest(
            method: .POST,
            path: .NEW_RECIPE,
            headerFields: [
                HeaderField.accept(value: .JSON),
                HeaderField.ocsRequest(value: true),
                HeaderField.contentType(value: .JSON)
            ],
            body: JSONEncoder.safeEncode(self.recipe)
        )
        sendRequest(request)
    }
    
    func uploadEditedRecipe() {
        print("Uploading changed recipe.")
        guard let recipeId = Int(recipe.id) else { return }
        createRecipe()
        let request = RequestWrapper.customRequest(
            method: .PUT,
            path: .RECIPE_DETAIL(recipeId: recipeId),
            headerFields: [
                HeaderField.accept(value: .JSON),
                HeaderField.ocsRequest(value: true),
                HeaderField.contentType(value: .JSON)
            ],
            body: JSONEncoder.safeEncode(self.recipe)
        )
        sendRequest(request)
    }
    
    func deleteRecipe() {
        guard let recipeId = Int(recipe.id) else { return }
        let request = RequestWrapper.customRequest(
            method: .DELETE,
            path: .RECIPE_DETAIL(recipeId: recipeId),
            headerFields: [
                HeaderField.accept(value: .JSON),
                HeaderField.ocsRequest(value: true)
            ]
        )
        sendRequest(request)
    }
    
    func sendRequest(_ request: RequestWrapper) {
        Task {
            guard let apiController = viewModel.apiController else { return }
            let (data, _): (Data?, Error?) = await apiController.sendDataRequest(request)
            guard let data = data else { return }
            do {
                let error = try JSONDecoder().decode(ServerMessage.self, from: data)
                alertMessage = error.msg
                presentAlert = true
            } catch {
                self.isPresented = false
                await self.viewModel.loadRecipeList(categoryName: self.recipe.recipeCategory, needsUpdate: true)
            }
        }
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

