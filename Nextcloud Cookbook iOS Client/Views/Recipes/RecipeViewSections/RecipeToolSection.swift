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
            
            RecipeListSection(list: viewModel.observableRecipeDetail.tool)
            
            if viewModel.editMode {
                Button {
                    viewModel.presentToolEditView.toggle()
                } label: {
                    Text("Edit")
                }
                .buttonStyle(.borderedProminent)
            }
        }.padding()
    }
    
    
}
