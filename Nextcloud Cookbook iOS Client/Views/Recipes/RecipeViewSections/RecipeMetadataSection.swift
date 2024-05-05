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
            .padding(.bottom)
            
            // Keywords
            SecondaryLabel(text: "Keywords")
            
            if !viewModel.observableRecipeDetail.keywords.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(viewModel.observableRecipeDetail.keywords, id: \.self) { keyword in
                            Text(keyword)
                                .padding(5)
                                .background(RoundedRectangle(cornerRadius: 20).foregroundStyle(Color.primary.opacity(0.1)))
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
            .padding(.bottom)
            
            // Servings / Yield
            VStack(alignment: .leading) {
                SecondaryLabel(text: "Servings")
                Button {
                    presentServingsPopover.toggle()
                } label: {
                    Text("\(viewModel.observableRecipeDetail.recipeYield) Serving(s)")
                        .lineLimit(1)
                }
                .popover(isPresented: $presentServingsPopover) {
                    PickerPopoverView(isPresented: $presentServingsPopover, value: $viewModel.observableRecipeDetail.recipeYield, items: 1..<99, title: "Servings", titleKey: "Servings")
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).foregroundStyle(Color.primary.opacity(0.1)))
        .padding([.horizontal, .bottom], 5)
        .sheet(isPresented: $presentKeywordSheet) {
            KeywordPickerView(title: "Keywords", searchSuggestions: appState.allKeywords, selection: $viewModel.observableRecipeDetail.keywords)
        }
    }
}

fileprivate struct PickerPopoverView<Item: Hashable & CustomStringConvertible, Collection: Sequence>: View where Collection.Element == Item {
    @Binding var isPresented: Bool
    @Binding var value: Item
    @State var items: Collection
    var title: LocalizedStringKey
    var titleKey: LocalizedStringKey = ""
    
    var body: some View {
        VStack {
            HStack {
                SecondaryLabel(text: title)
                Spacer()
                Button {
                    isPresented = false
                } label: {
                    Text("Done")
                }
            }
            Spacer()
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
            Spacer()
        }
        .padding()
    }
}


// MARK: - RecipeView More Information Section

struct MoreInformationSection: View {
    @ObservedObject var viewModel: RecipeView.ViewModel
    
    var body: some View {
        CollapsibleView(titleColor: .secondary, isCollapsed: !UserSettings.shared.expandInfoSection) {
            VStack(alignment: .leading) {
                if let dateCreated = viewModel.recipeDetail.dateCreated {
                    Text("Created: \(Date.convertISOStringToLocalString(isoDateString: dateCreated) ?? "")")
                }
                if let dateModified = viewModel.recipeDetail.dateModified {
                    Text("Last modified: \(Date.convertISOStringToLocalString(isoDateString: dateModified) ?? "")")
                }
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
