//
//  KeywordPickerView.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 03.10.23.
//

import Foundation
import SwiftUI

struct Keyword: Identifiable {
    let id = UUID()
    let name: String
    
    init(_ name: String) {
        self.name = name
    }
}

struct KeywordPickerView: View {
    @State var title: String
    @State var searchSuggestions: [Keyword]
    @Binding var selection: [String]
    @State var searchText: String = ""
    var columns: [GridItem] = [GridItem(.adaptive(minimum: 150), spacing: 5)]
    
    var body: some View {
        VStack(alignment: .leading) {
            TextField(title, text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding()
            ScrollView {
                LazyVGrid(columns: columns, spacing: 5) {
                    if searchText != "" {
                        KeywordItemView(
                            keyword: Keyword(searchText),
                            isSelected: selection.contains(searchText)
                        ) { keyword in
                            if selection.contains(keyword.name) {
                                selection.removeAll(where: { s in
                                    s == keyword.name ? true : false
                                })
                                searchSuggestions.removeAll(where: { s in
                                    s.name == keyword.name ? true : false
                                })
                            } else {
                                selection.append(keyword.name)
                            }
                        }
                    }
                    ForEach(suggestionsFiltered(), id: \.id) { suggestion in
                        KeywordItemView(
                            keyword: suggestion,
                            isSelected: selection.contains(suggestion.name)
                        ) { keyword in
                            if selection.contains(keyword.name) {
                                selection.removeAll(where: { s in
                                    s == keyword.name ? true : false
                                })
                            } else {
                                selection.append(keyword.name)
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
                            keyword: Keyword(suggestion),
                            isSelected: true
                        ) { keyword in
                            if selection.contains(keyword.name) {
                                selection.removeAll(where: { s in
                                    s == keyword.name ? true : false
                                })
                            } else {
                                selection.append(keyword.name)
                            }
                        }
                    }
                }
                Spacer()
            }
        }
        .navigationTitle(title)
    }
    
    func suggestionsFiltered() -> [Keyword] {
        guard searchText != "" else { return searchSuggestions }
        return searchSuggestions.filter { suggestion in
            suggestion.name.lowercased().contains(searchText.lowercased())
        }
    }
}



struct KeywordItemView: View {
    var keyword: Keyword
    var isSelected: Bool
    var tapped: (Keyword) -> ()
    var body: some View {
        HStack {
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
            }
            Text(keyword.name)
                .lineLimit(2)
            
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .foregroundStyle(Color("backgroundHighlight"))
        )
        .onTapGesture {
            tapped(keyword)
        }
    }
}
