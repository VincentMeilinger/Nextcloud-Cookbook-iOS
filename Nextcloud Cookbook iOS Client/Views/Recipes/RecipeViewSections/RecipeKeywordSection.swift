//
//  RecipeKeywordSection.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 03.10.23.
//

import Foundation
import SwiftUI

// MARK: - RecipeView Keyword Pills

/// The recipe's keywords as small capsules that wrap onto further lines.
/// Shows nothing when the recipe has no keywords.
struct RecipeKeywordPills: View {
    let keywords: [String]

    private var visibleKeywords: [String] {
        keywords
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var body: some View {
        if !visibleKeywords.isEmpty {
            FlowLayout(spacing: 6) {
                ForEach(Array(visibleKeywords.enumerated()), id: \.offset) { _, keyword in
                    Text(keyword)
                        .font(.footnote)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(.quaternary))
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Text("Keywords: \(visibleKeywords.joined(separator: ", "))"))
        }
    }
}

/// Lays out its subviews left to right, starting a new line when the next one
/// doesn't fit the available width.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(subviews, maxWidth: proposal.width ?? .infinity)
        let width = rows.map(\.width).max() ?? 0
        let height = rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(rows.count - 1, 0))
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(subviews, maxWidth: bounds.width) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(
                    at: CGPoint(x: x, y: y + (row.height - size.height) / 2),
                    proposal: ProposedViewSize(size)
                )
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(_ subviews: Subviews, maxWidth: CGFloat) -> [Row] {
        var rows: [Row] = []
        var row = Row()
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let widthWithItem = row.indices.isEmpty ? size.width : row.width + spacing + size.width
            if !row.indices.isEmpty && widthWithItem > maxWidth {
                rows.append(row)
                row = Row(indices: [index], width: size.width, height: size.height)
            } else {
                row.indices.append(index)
                row.width = widthWithItem
                row.height = max(row.height, size.height)
            }
        }
        if !row.indices.isEmpty { rows.append(row) }
        return rows
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

