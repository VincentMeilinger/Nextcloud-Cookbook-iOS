//
//  RecipeDurationSection.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 01.03.24.
//

import Foundation
import SwiftUI

// MARK: - RecipeView Duration Section

struct RecipeDurationSection: View {
    @ObservedObject var viewModel: RecipeView.ViewModel

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 200, maximum: .infinity), alignment: .leading)]) {
            DurationView(time: viewModel.observableRecipeDetail.prepTime, title: LocalizedStringKey("Preparation"))
            DurationView(time: viewModel.observableRecipeDetail.cookTime, title: LocalizedStringKey("Cooking"))
            DurationView(time: viewModel.observableRecipeDetail.totalTime, title: LocalizedStringKey("Total time"))
        }
        .padding()
    }
}

fileprivate struct DurationView: View {
    @ObservedObject var time: DurationComponents
    @State var title: LocalizedStringKey
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                SecondaryLabel(text: title)
                Spacer()
            }
            HStack {
                Image(systemName: "clock")
                    .bold()
                    .foregroundStyle(.secondary)
                Text(time.displayString)
                    .lineLimit(1)
            }
        }
    }
}
