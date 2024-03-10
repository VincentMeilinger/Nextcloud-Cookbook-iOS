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
            ForEach(viewModel.observableRecipeDetail.recipeInstructions.indices, id: \.self) { ix in
                RecipeInstructionListItem(instruction: $viewModel.observableRecipeDetail.recipeInstructions[ix], index: ix+1)
            }
            if viewModel.editMode {
                Button {
                    viewModel.presentInstructionEditView.toggle()
                } label: {
                    Text("Edit")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        
    }
}



fileprivate struct RecipeInstructionListItem: View {
    @Binding var instruction: String
    @State var index: Int
    @State var isSelected: Bool = false
    
    var body: some View {
        HStack(alignment: .top) {
            Text("\(index)")
                .monospaced()
            Text(instruction)
        }.padding(4)
        .foregroundStyle(isSelected ? Color.secondary : Color.primary)
        .onTapGesture {
            isSelected.toggle()
        }
        .animation(.easeInOut, value: isSelected)
    }
}

