//
//  KeywordPickerView.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 03.10.23.
//

import Foundation
import SwiftUI



struct KeywordPickerView: View {
    @State var title: String
    @State var searchSuggestions: [String]
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
                            keyword: searchText,
                            isSelected: selection.contains(searchText)
                        ) { keyword in
                            if selection.contains(keyword) {
                                selection.removeAll(where: { s in
                                    s == keyword ? true : false
                                })
                                searchSuggestions.removeAll(where: { s in
                                    s == keyword ? true : false
                                })
                            } else {
                                selection.append(keyword)
                            }
                        }
                    }
                    ForEach(suggestionsFiltered(), id: \.self) { suggestion in
                        KeywordItemView(
                            keyword: suggestion,
                            isSelected: selection.contains(suggestion)
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
        
    }
    
    func suggestionsFiltered() -> [String] {
        guard searchText != "" else { return searchSuggestions }
        return searchSuggestions.filter { suggestion in
            suggestion.lowercased().contains(searchText.lowercased())
        }
    }
}



struct KeywordItemView: View {
    var keyword: String
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
