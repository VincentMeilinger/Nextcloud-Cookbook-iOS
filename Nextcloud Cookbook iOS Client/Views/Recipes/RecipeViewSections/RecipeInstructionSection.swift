//
//  RecipeInstructionSection.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 01.03.24.
//

import Foundation
import SwiftUI

// MARK: - RecipeView Instructions Section

struct RecipeInstructionSection: View {
    @ObservedObject var viewModel: RecipeView.ViewModel

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                SecondaryLabel(text: LocalizedStringKey("Instructions"))
                Spacer()
            }
            EditableStringList(items: $viewModel.observableRecipeDetail.recipeInstructions, editMode: $viewModel.editMode, titleKey: "Instruction", lineLimit: 0...15, axis: .vertical) {
                ForEach(0..<viewModel.observableRecipeDetail.recipeInstructions.count, id: \.self) { ix in
                    RecipeInstructionListItem(instruction: viewModel.observableRecipeDetail.recipeInstructions[ix], index: ix+1)
                }
            }
        }.padding()
    }
}



fileprivate struct RecipeInstructionListItem: View {
    @State var instruction: ReorderableItem<String>
    @State var index: Int
    @State var isSelected: Bool = false
    
    var body: some View {
        HStack(alignment: .top) {
            Text("\(index)")
                .monospaced()
            Text(instruction.item)
        }.padding(4)
        .foregroundStyle(isSelected ? Color.secondary : Color.primary)
        .onTapGesture {
            isSelected.toggle()
        }
        .animation(.easeInOut, value: isSelected)
    }
}

