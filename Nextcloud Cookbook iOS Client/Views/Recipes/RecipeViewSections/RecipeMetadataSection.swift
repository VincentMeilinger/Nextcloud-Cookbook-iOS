//
//  RecipeMetadataSection.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 01.03.24.
//

import Foundation
import SwiftUI

// MARK: - Recipe Metadata Section

struct RecipeMetadataSection: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var viewModel: RecipeView.ViewModel
    
    @State var keywords: [RecipeKeyword] = []
    var categories: [String] {
        appState.categories.map({ category in category.name })
    }
    
    
    @State var presentKeywordSheet: Bool = false
    @State var presentServingsPopover: Bool = false
    @State var presentCategoryPopover: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            // Category
            //CategoryPickerView(items: $categories, input: $viewModel.observableRecipeDetail.recipeCategory, titleKey: "Category")
            SecondaryLabel(text: "Category")
            HStack {
                TextField("Category", text: $viewModel.observableRecipeDetail.recipeCategory)
                    .lineLimit(1)
                    .textFieldStyle(.roundedBorder)
                    
                Picker("Choose", selection: $viewModel.observableRecipeDetail.recipeCategory) {
                    Text("").tag("")
                    ForEach(categories, id: \.self) { item in
                        Text(item)
                    }
                }
                .pickerStyle(.menu)
            }
            
            // Keywords
            SecondaryLabel(text: "Keywords")
            
            if !viewModel.observableRecipeDetail.keywords.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(viewModel.observableRecipeDetail.keywords, id: \.self) { keyword in
                            Text(keyword)
                        }
                    }
                }
            }
            Button {
                presentKeywordSheet.toggle()
            } label: {
                Text("Select Keywords")
                Image(systemName: "chevron.right")
            }
            
            // Servings / Yield
            VStack(alignment: .leading) {
                SecondaryLabel(text: "Servings")
                Button {
                    presentServingsPopover.toggle()
                } label: {
                    Text("\(viewModel.observableRecipeDetail.recipeYield) serving(s)")
                        .lineLimit(1)
                }
                .popover(isPresented: $presentServingsPopover) {
                    PickerPopoverView(value: $viewModel.observableRecipeDetail.recipeYield, items: 0..<99, titleKey: "Servings")
                }
            }
        }
        .padding()
        .background(Rectangle().foregroundStyle(Color.white.opacity(0.1)))
        .sheet(isPresented: $presentKeywordSheet) {
            KeywordPickerView(title: "Keywords", searchSuggestions: appState.allKeywords, selection: $viewModel.observableRecipeDetail.keywords)
        }
    }
}

fileprivate struct PickerPopoverView<Item: Hashable & CustomStringConvertible, Collection: Sequence>: View where Collection.Element == Item {
    @Binding var value: Item
    @State var items: Collection
    var titleKey: LocalizedStringKey = ""
    
    var body: some View {
        HStack {
            Picker(selection: $value, label: Text(titleKey)) {
                ForEach(Array(items), id: \.self) { item in
                    Text(item.description).tag(item)
                }
            }
            .pickerStyle(WheelPickerStyle())
            .frame(width: 150, height: 150)
            .clipped()
        }
        .padding()
    }
}

fileprivate struct CategoryPickerView: View {
    @Binding var items: [String]
    @Binding var input: String
    @State private var pickerChoice: String = ""

    var titleKey: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading) {
            SecondaryLabel(text: "Category")
                .padding([.top, .horizontal])
            HStack {
                TextField(titleKey, text: $input)
                    .lineLimit(1)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                    .onSubmit {
                        pickerChoice = ""
                    }
                
                Picker("Select Item", selection: $pickerChoice) {
                    Text("").tag("")
                    ForEach(items, id: \.self) { item in
                        Text(item)
                    }
                }
                .pickerStyle(.menu)
                .padding()
                .onChange(of: pickerChoice) { newValue in
                    if pickerChoice != "" {
                        input = newValue
                    }
                }
            }
        }
        .onAppear {
            pickerChoice = input
        }
    }
}


// MARK: - RecipeView More Information Section

struct MoreInformationSection: View {
    @ObservedObject var viewModel: RecipeView.ViewModel
    
    var body: some View {
        CollapsibleView(titleColor: .secondary, isCollapsed: !UserSettings.shared.expandInfoSection) {
            VStack(alignment: .leading) {
                Text("Created: \(Date.convertISOStringToLocalString(isoDateString: viewModel.recipeDetail.dateCreated) ?? "")")
                Text("Last modified: \(Date.convertISOStringToLocalString(isoDateString: viewModel.recipeDetail.dateModified) ?? "")")
                if viewModel.observableRecipeDetail.url != "", let url = URL(string: viewModel.observableRecipeDetail.url) {
                    HStack(alignment: .top) {
                        Text("URL:")
                        Link(destination: url) {
                            Text(viewModel.observableRecipeDetail.url)
                        }
                    }
                }
            }
            .font(.caption)
            .foregroundStyle(Color.secondary)
        } title: {
            HStack {
                SecondaryLabel(text: "More information")
                Spacer()
            }
        }
        .padding()
    }
}
