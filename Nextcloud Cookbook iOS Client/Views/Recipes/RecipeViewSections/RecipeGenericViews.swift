//
//  RecipeSectionStructureViews.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 01.03.24.
//

import Foundation
import SwiftUI

// MARK: - RecipeView Generic Editable View Elements


struct RecipeListSection: View {
    @Binding var list: [String]
    
    var body: some View {
        VStack(alignment: .leading) {
            ForEach(list, id: \.self) { item in
                HStack(alignment: .top) {
                    Text("\u{2022}")
                    Text(ObservableRecipeDetail.applyMarkdownStyling(item))
                        .multilineTextAlignment(.leading)
                }
                .padding(4)
            }
        }
    }
}


struct SecondaryLabel: View {
    let text: LocalizedStringKey
    var body: some View {
        Text(text)
            .foregroundColor(.secondary)
            .font(.headline)
            .padding(.vertical, 5)
    }
}


/// Arranges its subviews in as many equal columns of at least `minColumnWidth` as fit,
/// filled row by row; each row is as tall as its tallest item.
///
/// A non-lazy stand-in for `LazyVGrid(columns: [GridItem(.adaptive(minimum:))])`. The
/// recipe sections are few but can be very tall (e.g. 100+ ingredients). A lazy grid only
/// estimates the height of rows it hasn't laid out yet, so scrolling a long recipe jumped
/// around and later sections overlapped earlier ones (GitHub issue #36).
struct AdaptiveColumnsLayout: Layout {
    var minColumnWidth: CGFloat
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = availableWidth(proposal)
        let columns = columnCount(for: width)
        let heights = rowHeights(subviews, columns: columns, columnWidth: columnWidth(width, columns))
        let height = heights.reduce(0, +) + spacing * CGFloat(max(heights.count - 1, 0))
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let columns = columnCount(for: bounds.width)
        let width = columnWidth(bounds.width, columns)
        var y = bounds.minY
        for (row, height) in rowHeights(subviews, columns: columns, columnWidth: width).enumerated() {
            for column in 0..<columns {
                let index = row * columns + column
                guard index < subviews.count else { break }
                subviews[index].place(
                    at: CGPoint(x: bounds.minX + CGFloat(column) * (width + spacing), y: y),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(width: width, height: nil)
                )
            }
            y += height + spacing
        }
    }

    private func availableWidth(_ proposal: ProposedViewSize) -> CGFloat {
        guard let width = proposal.width, width.isFinite else { return minColumnWidth }
        return width
    }

    private func columnCount(for width: CGFloat) -> Int {
        max(1, Int((width + spacing) / (minColumnWidth + spacing)))
    }

    private func columnWidth(_ width: CGFloat, _ columns: Int) -> CGFloat {
        (width - spacing * CGFloat(columns - 1)) / CGFloat(columns)
    }

    private func rowHeights(_ subviews: Subviews, columns: Int, columnWidth: CGFloat) -> [CGFloat] {
        stride(from: 0, to: subviews.count, by: columns).map { start in
            subviews[start..<min(start + columns, subviews.count)]
                .map { $0.sizeThatFits(ProposedViewSize(width: columnWidth, height: nil)).height }
                .max() ?? 0
        }
    }
}
