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
    
    @State var categories: [String] = []
    @State var keywords: [RecipeKeyword] = []
    @State var presentKeywordPopover: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            CategoryPickerView(items: $categories, input: $viewModel.observableRecipeDetail.recipeCategory, titleKey: "Category")
            
            SecondaryLabel(text: "Keywords")
                .padding()
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(viewModel.observableRecipeDetail.keywords, id: \.self) { keyword in
                        Text(keyword)
                    }
                }
            }.padding(.horizontal)
            
            Button {
                presentKeywordPopover.toggle()
            } label: {
                Text("Edit keywords")
                Image(systemName: "chevron.right")
            }
            .padding(.horizontal)
            
        }
        .task {
            categories = appState.categories.map({ category in category.name })
        }
        .sheet(isPresented: $presentKeywordPopover) {
            KeywordPickerView(title: "Keywords", searchSuggestions: appState.allKeywords, selection: $viewModel.observableRecipeDetail.keywords)
        }
    }
}



struct CategoryPickerView: View {
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
