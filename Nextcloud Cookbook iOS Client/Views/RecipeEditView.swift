//
//  RecipeEditView.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 29.09.23.
//

import Foundation
import SwiftUI
import PhotosUI


fileprivate enum ErrorMessages: Error {
    
    case NO_TITLE,
         DUPLICATE,
         UPLOAD_ERROR,
         CONFIRM_DELETE,
         GENERIC,
         CUSTOM(title: LocalizedStringKey, description: LocalizedStringKey)
    
    var localizedDescription: LocalizedStringKey {
        switch self {
        case .NO_TITLE:
            return "Please enter a recipe name."
        case .DUPLICATE:
            return "A recipe with that name already exists."
        case .UPLOAD_ERROR:
            return "Unable to upload your recipe. Please check your internet connection."
        case .CONFIRM_DELETE:
            return "This action is not reversible!"
        case .CUSTOM(title: _, description: let description):
            return description
        default:
            return "An unknown error occured."
        }
    }
    
    var localizedTitle: LocalizedStringKey {
        switch self {
        case .NO_TITLE:
            return "Missing recipe name."
        case .DUPLICATE:
            return "Duplicate recipe."
        case .UPLOAD_ERROR:
            return "Network error."
        case .CONFIRM_DELETE:
            return "Delete recipe?"
        case .CUSTOM(title: let title, description: _):
            return title
        default:
            return "Error."
        }
    }
}


struct RecipeEditView: View {
    @ObservedObject var viewModel: MainViewModel
    @State var recipe: RecipeDetail = RecipeDetail()
    @Binding var isPresented: Bool
    @State var uploadNew: Bool = true

    @State private var image: PhotosPickerItem? = nil
    @State private var times = [Date.zero, Date.zero, Date.zero]
    @State private var searchText: String = ""
    @State private var keywords: [String] = []
    
    @State private var alertMessage: ErrorMessages = .GENERIC
    @State private var presentAlert: Bool = false
    @State private var waitingForUpload: Bool = false
    
    var body: some View {
        VStack {
            HStack {
                Button() {
                    isPresented = false
                } label: {
                    Text("Cancel")
                        .bold()
                }
                if !uploadNew {
                    Menu {
                        Button {
                            print("Delete recipe.")
                            alertMessage = .CONFIRM_DELETE
                            presentAlert = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                            Text("Delete recipe")
                                .foregroundStyle(.red)
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                            .padding()
                    }
                }
                Spacer()
                Button() {
                    if uploadNew {
                        uploadNewRecipe()
                    } else {
                        uploadEditedRecipe()
                    }
                } label: {
                    Text("Upload")
                        .bold()
                }
            }.padding()
            HStack {
                Text(recipe.name == "" ? "New recipe" : recipe.name)
                    .font(.title)
                    .bold()
                    .padding()
                Spacer()
            }
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
        .alert(alertMessage.localizedTitle, isPresented: $presentAlert) {
            switch alertMessage {
            case .CONFIRM_DELETE:
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteRecipe()
                }
            default:
                Button("Ok", role: .cancel) { }
            }
        } message: {
            Text(alertMessage.localizedDescription)
        }
    }
    
    func createRecipe() {
        if let date = Date.toPTRepresentation(date: times[0]) {
            self.recipe.prepTime = date
        }
        if let date = Date.toPTRepresentation(date: times[1]) {
            self.recipe.cookTime = date
        }
        if let date = Date.toPTRepresentation(date: times[2]) {
            self.recipe.totalTime = date
        }
        if !self.keywords.isEmpty {
            self.recipe.keywords = self.keywords.joined(separator: ",")
        }
    }
    
    func recipeValid() -> Bool {
        // Check if the recipe has a name
        if recipe.name == "" {
            self.alertMessage = .NO_TITLE
            self.presentAlert = true
            return false
        }
        // Check if the recipe has a unique name
        for recipeList in viewModel.recipes.values {
            for r in recipeList {
                if r.name
                    .replacingOccurrences(of: " ", with: "")
                    .lowercased() ==
                    recipe.name
                    .replacingOccurrences(of: " ", with: "")
                    .lowercased()
                {
                    self.alertMessage = .DUPLICATE
                    self.presentAlert = true
                    return false
                }
            }
        }
        
        return true
    }
    
    func uploadNewRecipe() {
        print("Uploading new recipe.")
        waitingForUpload = true
        createRecipe()
        guard recipeValid() else { return }
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
        dismissEditView()
    }
    
    func uploadEditedRecipe() {
        waitingForUpload = true
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
        dismissEditView()
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
        dismissEditView()
    }
    
    func sendRequest(_ request: RequestWrapper) {
        Task {
            guard let apiController = viewModel.apiController else { return }
            let (data, _): (Data?, Error?) = await apiController.sendDataRequest(request)
            guard let data = data else { return }
            do {
                let error = try JSONDecoder().decode(ServerMessage.self, from: data)
                DispatchQueue.main.sync {
                    alertMessage = .CUSTOM(title: "Error.", description: LocalizedStringKey(stringLiteral: error.msg))
                    presentAlert = true
                    return
                }
            } catch {
                
            }
        }
    }
    
    func dismissEditView() {
        Task {
            await self.viewModel.loadCategoryList(needsUpdate: true)
            await self.viewModel.loadRecipeList(categoryName: self.recipe.recipeCategory, needsUpdate: true)
        }
        self.isPresented = false
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

