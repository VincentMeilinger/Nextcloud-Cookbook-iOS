//
//  CategoryPickerView.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 03.10.23.
//

import Foundation
import SwiftUI


/*
struct CategoryPickerViewOld: View {
    @State var title: String
    @State var searchSuggestions: [String]
    @Binding var selection: String
    @State var searchText: String = ""
    
    var body: some View {
        VStack {
            TextField(title, text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding()
            List {
                if searchText != "" {
                    HStack {
                        if selection.contains(searchText) {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        Text(searchText)
                        Spacer()
                    }
                    .padding()
                    .onTapGesture {
                        selection = searchText
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
                    .onTapGesture {
                        selection = suggestion
                    }
                }
            }
            Spacer()
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

*/
