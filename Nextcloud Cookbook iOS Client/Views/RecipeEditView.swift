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
    @State var uploadNew: Bool = true
    
    @State private var presentAlert = false
    @State private var alertType: UserAlert = RecipeCreationError.GENERIC
    @State private var alertAction: () -> () = {}

    @StateObject private var prepDuration: DurationComponents = DurationComponents()
    @StateObject private var cookDuration: DurationComponents = DurationComponents()
    @StateObject private var totalDuration: DurationComponents = DurationComponents()
    @State private var searchText: String = ""
    @State private var keywords: [String] = []
    @State private var keywordSuggestions: [String] = []
    
    @State private var importURL: String = ""
    @State private var showImportSection: Bool = false
    @State private var waitingForUpload: Bool = false
    
    var body: some View {
        NavigationStack {
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
                                alertType = RecipeCreationError.CONFIRM_DELETE
                                alertAction = deleteRecipe
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
                    Text(recipe.name == "" ? LocalizedStringKey("New recipe") : LocalizedStringKey(recipe.name))
                        .font(.title)
                        .bold()
                        .padding()
                    Spacer()
                }
                Form {
                    if showImportSection {
                        Section {
                            TextField("URL (e.g. example.com/recipe)", text: $importURL)
                                .onSubmit {
                                    Task {
                                        do {
                                            let (scrapedRecipe, error) = try await RecipeScraper().scrape(url: importURL)
                                            if let scrapedRecipe = scrapedRecipe {
                                                self.recipe = scrapedRecipe
                                                prepareView()
                                            }
                                            if let error = error {
                                                self.alertType = error
                                                self.alertAction = {}
                                                self.presentAlert = true
                                            }
                                        } catch {
                                            print("Error")
                                        }
                                    }
                                }
                        } header: {
                            Text("Import Recipe")
                        } footer: {
                            Text("Paste the url of a recipe you would like to import in the above, and we will try to fill in the fields for you. This feature does not work with every website. If your favourite website is not supported, feel free to reach out for help. You can find the contact details in the app settings.")
                        }
                        
                    } else {
                        Section {
                            Button() {
                                withAnimation{
                                    showImportSection = true
                                }
                            } label: {
                                Text("Import recipe from a website")
                            }
                        }
                    }
                    
                    TextField("Title", text: $recipe.name)
                    Section {
                        TextEditor(text: $recipe.description)
                    } header: {
                        Text("Description")
                    }
                    
                    Section() {
                        NavigationLink(recipe.recipeCategory == "" ? "Category" : "Category: \(recipe.recipeCategory)") {
                            CategoryPickerView(
                                title: "Category",
                                searchSuggestions: viewModel.categories.map({ category in
                                    category.name == "*" ? "Other" : category.name
                                }),
                                selection: $recipe.recipeCategory)
                        }
                        NavigationLink("Keywords") {
                            KeywordPickerView(
                                title: "Keywords",
                                searchSuggestions: keywordSuggestions,
                                selection: $keywords
                            )
                        }
                    } footer: {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(keywords, id: \.self) { keyword in
                                    Text(keyword)
                                }
                            }
                        }
                    }
                    
                    Section() {
                        Picker("Servings:", selection: $recipe.recipeYield) {
                            ForEach(0..<99, id: \.self) { i in
                                Text("\(i)").tag(i)
                            }
                        }
                        .pickerStyle(.menu)
                        DurationPicker(title: LocalizedStringKey("Preparation duration:"), duration: prepDuration)
                        DurationPicker(title: LocalizedStringKey("Cooking duration:"), duration: cookDuration)
                        DurationPicker(title: LocalizedStringKey("Total duration:"), duration: totalDuration)
                    }
                    
                    EditableListSection(title: LocalizedStringKey("Ingredients"), items: $recipe.recipeIngredient)
                    EditableListSection(title: LocalizedStringKey("Tools"), items: $recipe.tool)
                    EditableListSection(title: LocalizedStringKey("Instructions"), items: $recipe.recipeInstructions)
                }
            }
        }
        .task {
            self.keywordSuggestions = await viewModel.getKeywords()
        }
        .onAppear {
            prepareView()
        }
        .alert(alertType.localizedTitle, isPresented: $presentAlert) {
            ForEach(alertType.alertButtons) { buttonType in
                if buttonType == .OK {
                    Button(AlertButton.OK.rawValue, role: .cancel) {
                        alertAction()
                    }
                } else if buttonType == .CANCEL {
                    Button(AlertButton.CANCEL.rawValue, role: .cancel) { }
                } else if buttonType == .DELETE {
                    Button(AlertButton.DELETE.rawValue, role: .destructive) {
                        alertAction()
                    }
                }
            }
        } message: {
            Text(alertType.localizedDescription)
        }
    }
    
    func createRecipe() {
        self.recipe.prepTime = prepDuration.toPTString()
        self.recipe.cookTime = cookDuration.toPTString()
        self.recipe.totalTime = totalDuration.toPTString()
        self.recipe.setKeywordsFromArray(keywords)
    }
    
    func recipeValid() -> Bool {
        // Check if the recipe has a name
        if recipe.name.replacingOccurrences(of: " ", with: "") == "" {
            alertType = RecipeCreationError.NO_TITLE
            alertAction = {}
            presentAlert = true
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
                    alertType = RecipeCreationError.DUPLICATE
                    alertAction = {}
                    presentAlert = true
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
        if let recipeIdInt = Int(recipe.id) {
            viewModel.deleteRecipe(withId: recipeIdInt, categoryName: recipe.recipeCategory)
        }
        dismissEditView()
    }
    
    func sendRequest(_ request: RequestWrapper) {
        Task {
            guard let apiController = viewModel.apiController else { return }
            let (data, _): (Data?, Error?) = await apiController.sendDataRequest(request)
            guard let data = data else { return }
            do {
                let error = try JSONDecoder().decode(ServerMessage.self, from: data)
                // TODO: Better error handling (Show error to user!)
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
    
    func prepareView() {
        if let prepTime = recipe.prepTime {
            prepDuration.fromPTString(prepTime)
        }
        if let cookTime = recipe.cookTime {
            cookDuration.fromPTString(cookTime)
        }
        if let totalTime = recipe.totalTime {
            totalDuration.fromPTString(totalTime)
        }
        self.keywords = recipe.getKeywordsArray()
    }
}



fileprivate struct EditableListSection: View {
    @State var title: LocalizedStringKey
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


fileprivate struct DurationPicker: View {
    @State var title: LocalizedStringKey
    @ObservedObject var duration: DurationComponents

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            TextField("00", text: $duration.hourComponent)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 40)
            Text(":")
            TextField("00", text: $duration.minuteComponent)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 40)
        }
        .frame(maxHeight: 40)
        .clipped()
    }
}







