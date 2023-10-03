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
    var columns: [GridItem] = [GridItem(.adaptive(minimum: 120), spacing: 0)]
    
    var body: some View {
        VStack {
            TextField(title, text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding()
            LazyVGrid(columns: columns, spacing: 5) {
                if searchText != "" {
                    HStack {
                        if selection.contains(searchText) {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        Text(searchText)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .foregroundStyle(Color("backgroundHighlight"))
                    )
                    .onTapGesture {
                        if selection.contains(searchText) {
                            selection.removeAll(where: { s in
                                s == searchText ? true : false
                            })
                        } else {
                            selection.append(searchText)
                            searchSuggestions.append(searchText)
                        }
                    }
                }
                ForEach(suggestionsFiltered(), id: \.self) { suggestion in
                    HStack {
                        if selection.contains(suggestion) {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        Text(suggestion)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .foregroundStyle(Color("backgroundHighlight"))
                    )
                    .onTapGesture {
                        if selection.contains(suggestion) {
                            selection.removeAll(where: { s in
                                s == suggestion ? true : false
                            })
                        } else {
                            selection.append(suggestion)
                        }
                    }
                }
            }
            Spacer()
        }
    }
    
    func suggestionsFiltered() -> [String] {
        guard searchText != "" else { return searchSuggestions }
        return searchSuggestions.filter { suggestion in
            suggestion.lowercased().contains(searchText.lowercased())
        }
    }
}
