//
//  RecipeKeywordSection.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 03.10.23.
//

import Foundation
import SwiftUI

// MARK: - RecipeView Keyword Section

struct RecipeKeywordSection: View {
    @ObservedObject var viewModel: RecipeView.ViewModel
    let columns: [GridItem] = [ GridItem(.flexible(minimum: 50, maximum: 200), spacing: 5) ]
    
    var body: some View {
        CollapsibleView(titleColor: .secondary, isCollapsed: !UserSettings.shared.expandKeywordSection) {
            Group {
                if !viewModel.observableRecipeDetail.keywords.isEmpty && !viewModel.editMode {
                    RecipeListSection(list: viewModel.observableRecipeDetail.keywords)
                } else {
                    Text(LocalizedStringKey("No keywords."))
                }
            }
        } title: {
            HStack {
                SecondaryLabel(text: LocalizedStringKey("Keywords"))
                Spacer()
            }
        }
        .padding()
    }
}

// MARK: - RecipeView Keyword Sheet View

struct KeywordPickerView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var title: String
    @State var searchSuggestions: [RecipeKeyword]
    @Binding var selection: [String]
    @State var searchText: String = ""
    
    var columns: [GridItem] = [GridItem(.adaptive(minimum: 150), spacing: 5)]
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Spacer()
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("Done")
                }.padding()
            }
            TextField(title, text: $searchText)
                .textFieldStyle(.roundedBorder)
                
            ScrollView {
                LazyVGrid(columns: columns, spacing: 5) {
                    if searchText != "" {
                        KeywordItemView(
                            keyword: searchText,
                            isSelected: selection.contains(searchText)
                        ) { keyword in
                            if selection.contains(keyword) {
                                selection.removeAll(where: { s in
                                    s == keyword ? true : false
                                })
                                searchSuggestions.removeAll(where: { s in
                                    s.name == keyword ? true : false
                                })
                            } else {
                                selection.append(keyword)
                            }
                        }
                    }
                    ForEach(suggestionsFiltered(), id: \.name) { suggestion in
                        KeywordItemView(
                            keyword: suggestion.name,
                            count: suggestion.recipe_count,
                            isSelected: selection.contains(suggestion.name)
                        ) { keyword in
                            if selection.contains(keyword) {
                                selection.removeAll(where: { s in
                                    s == keyword ? true : false
                                })
                            } else {
                                selection.append(keyword)
                            }
                        }
                    }
                }
                Divider().padding()
                HStack {
                    Text("Selected keywords:")
                        .font(.headline)
                        .padding()
                    Spacer()
                }
                LazyVGrid(columns: columns, spacing: 5) {
                    ForEach(selection, id: \.self) { suggestion in
                        KeywordItemView(
                            keyword: suggestion,
                            isSelected: true
                        ) { keyword in
                            if selection.contains(keyword) {
                                selection.removeAll(where: { s in
                                    s == keyword ? true : false
                                })
                            } else {
                                selection.append(keyword)
                            }
                        }
                    }
                }
                Spacer()
            }
        }
        .navigationTitle(title)
        .padding()
        
    }
    
    func suggestionsFiltered() -> [RecipeKeyword] {
        guard searchText != "" else { return searchSuggestions }
        return searchSuggestions.filter { suggestion in
            suggestion.name.lowercased().contains(searchText.lowercased())
        }.sorted(by: { a, b in
            a.recipe_count > b.recipe_count
        })
    }
}



struct KeywordItemView: View {
    var keyword: String
    var count: Int? = nil
    var isSelected: Bool
    var tapped: (String) -> ()
    
    var body: some View {
        HStack {
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
            }
            Text(keyword)
                .lineLimit(2)
            Spacer()
            if let count = count {
                Text("(\(count))")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .foregroundStyle(.tertiary)
        )
        .onTapGesture {
            tapped(keyword)
        }
    }
}


// MARK: - Previews

struct KeywordPickerView_Previews: PreviewProvider {
    // Sample keywords for preview
    static var sampleKeywords = [
        RecipeKeyword(name: "Vegan", recipe_count: 10),
        RecipeKeyword(name: "Meat", recipe_count: 5),
        RecipeKeyword(name: "Gluten-Free", recipe_count: 8),
        RecipeKeyword(name: "Difficult", recipe_count: 7),
        RecipeKeyword(name: "Chinese", recipe_count: 3),
        RecipeKeyword(name: "European", recipe_count: 5),
        RecipeKeyword(name: "Easy", recipe_count: 1)
  
    ]
    
    // Sample selection for preview
    @State static var selection: [String] = ["Vegan"]
    
    static var previews: some View {
        KeywordPickerView(title: "Select Keywords", searchSuggestions: sampleKeywords, selection: $selection)
            
    }
}

