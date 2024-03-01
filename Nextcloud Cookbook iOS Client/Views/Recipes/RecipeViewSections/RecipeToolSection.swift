//
//  RecipeToolSection.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 01.03.24.
//

import Foundation
import SwiftUI

// MARK: - RecipeView Tool Section

struct RecipeToolSection: View {
    @ObservedObject var viewModel: RecipeView.ViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                SecondaryLabel(text: "Tools")
                Spacer()
            }
            EditableStringList(items: $viewModel.observableRecipeDetail.tool, editMode: $viewModel.editMode, titleKey: "Tool", lineLimit: 0...1, axis: .horizontal) {
                RecipeListSection(list: ReorderableItem.items(viewModel.observableRecipeDetail.tool))
            }
        }.padding()
    }
}
