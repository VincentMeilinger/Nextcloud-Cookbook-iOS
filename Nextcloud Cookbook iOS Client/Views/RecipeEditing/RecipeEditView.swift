//
//  RecipeEditView.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 29.09.23.
//

import Foundation
import SwiftUI
import PhotosUI


/*
struct RecipeEditView: View {
    @ObservedObject var viewModel: RecipeEditViewModel
    @Binding var isPresented: Bool
    
    @State var presentAlert = false
    @State var alertType: UserAlert = RecipeAlert.GENERIC
    @State var alertAction: @MainActor () async -> () = { }
    
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
                    if !viewModel.uploadNew {
                        Menu {
                            Button {
                                print("Delete recipe.")
                                alertType = RecipeAlert.CONFIRM_DELETE
                                alertAction = {
                                    if let res = await viewModel.deleteRecipe() {
                                        alertType = res
                                        alertAction = { }
                                        presentAlert = true
                                    } else {
                                        self.dismissEditView()
                                    }
                                }
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
                        Task {
                            if viewModel.uploadNew {
                                if let res = await viewModel.uploadNewRecipe() {
                                    alertType = res
                                    presentAlert = true
                                } else {
                                    dismissEditView()
                                }
                            } else {
                                if let res = await viewModel.uploadEditedRecipe() {
                                    alertType = res
                                    presentAlert = true
                                } else {
                                    dismissEditView()
                                }
                            }
                        }
                    } label: {
                        Text("Upload")
                            .bold()
                    }
                }.padding()
                HStack {
                    Text(viewModel.recipe.name == "" ? String(localized: "New recipe") : viewModel.recipe.name)
                        .font(.title)
                        .bold()
                        .padding()
                    Spacer()
                }
                Form {
                    if viewModel.showImportSection {
                        Section {
                            TextField(LocalizedStringKey("URL (e.g. example.com/recipe)"), text: $viewModel.importURL)
                            Button {
                                Task {
                                    if let res = await viewModel.importRecipe() {
                                        alertType = RecipeAlert.CUSTOM(
                                            title: res.localizedTitle,
                                            description: res.localizedDescription
                                        )
                                        alertAction = { }
                                        presentAlert = true
                                    }
                                }
                            } label: {
                                Text(LocalizedStringKey("Import"))
                            }
                        } header: {
                            Text(LocalizedStringKey("Import Recipe"))
                        } footer: {
                            Text(LocalizedStringKey("Paste the url of a recipe you would like to import in the above, and we will try to fill in the fields for you. This feature does not work with every website. If your favourite website is not supported, feel free to reach out for help. You can find the contact details in the app settings."))
                        }
                        
                    } else {
                        Section {
                            Button() {
                                withAnimation{
                                    viewModel.showImportSection = true
                                }
                            } label: {
                                Text("Import recipe from a website")
                            }
                        }
                    }
                    
                    TextField("Title", text: $viewModel.recipe.name)
                    Section {
                        TextEditor(text: $viewModel.recipe.description)
                    } header: {
                        Text("Description")
                    }
                    
                    Section() {
                        NavigationLink(viewModel.recipe.recipeCategory == "" ? "Category" : "Category: \(viewModel.recipe.recipeCategory)") {
                            CategoryPickerViewOld(
                                title: "Category",
                                searchSuggestions: viewModel.mainViewModel.categories.map({ category in
                                    category.name == "*" ? "Other" : category.name
                                }),
                                selection: $viewModel.recipe.recipeCategory)
                        }
                        NavigationLink("Keywords") {
                            KeywordPickerView(
                                title: "Keywords",
                                searchSuggestions: viewModel.keywordSuggestions,
                                selection: $viewModel.keywords
                            )
                        }
                    } footer: {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(viewModel.keywords, id: \.self) { keyword in
                                    Text(keyword)
                                }
                            }
                        }
                    }
                    
                    Section() {
                        Picker("Servings:", selection: $viewModel.recipe.recipeYield) {
                            ForEach(0..<99, id: \.self) { i in
                                Text("\(i)").tag(i)
                            }
                        }
                        .pickerStyle(.menu)
                        DurationPicker(title: LocalizedStringKey("Preparation duration:"), duration: viewModel.prepDuration)
                        DurationPicker(title: LocalizedStringKey("Cooking duration:"), duration: viewModel.cookDuration)
                        DurationPicker(title: LocalizedStringKey("Total duration:"), duration: viewModel.totalDuration)
                    }
                    
                    EditableListSection(title: LocalizedStringKey("Ingredients"), items: $viewModel.recipe.recipeIngredient)
                    EditableListSection(title: LocalizedStringKey("Tools"), items: $viewModel.recipe.tool)
                    EditableListSection(title: LocalizedStringKey("Instructions"), items: $viewModel.recipe.recipeInstructions)
                }
            }
        }
        .task {
            viewModel.keywordSuggestions = await viewModel.mainViewModel.getKeywords(fetchMode: .preferServer)
        }
        .onAppear {
            viewModel.prepareView()
        }
        .alert(alertType.localizedTitle, isPresented: $presentAlert) {
            ForEach(alertType.alertButtons) { buttonType in
                if buttonType == .OK {
                    Button(AlertButton.OK.rawValue, role: .cancel) {
                        Task {
                            await alertAction()
                        }
                    }
                } else if buttonType == .CANCEL {
                    Button(AlertButton.CANCEL.rawValue, role: .cancel) { }
                } else if buttonType == .DELETE {
                    Button(AlertButton.DELETE.rawValue, role: .destructive) {
                        Task {
                            await alertAction()
                        }
                    }
                }
            }
        } message: {
            Text(alertType.localizedDescription)
        }
    }
    
    func dismissEditView() {
        Task {
            await viewModel.mainViewModel.getCategories()
            await viewModel.mainViewModel.getCategory(named: viewModel.recipe.recipeCategory, fetchMode: .preferServer)
            await viewModel.mainViewModel.updateRecipeDetails(in: viewModel.recipe.recipeCategory)
        }
        self.isPresented = false
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
            
        }
        .frame(maxHeight: 40)
        .clipped()
    }
}






*/
