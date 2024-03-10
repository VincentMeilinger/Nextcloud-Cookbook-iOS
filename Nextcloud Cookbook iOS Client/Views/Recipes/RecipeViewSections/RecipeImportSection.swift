//
//  RecipeImportSection.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 07.03.24.
//

import Foundation
import SwiftUI


// MARK: - RecipeView Import Section

struct RecipeImportSection: View {
    @ObservedObject var viewModel: RecipeView.ViewModel
    var importRecipe: (String) async -> UserAlert?
    
    var body: some View {
        VStack(alignment: .leading) {
            SecondaryLabel(text: "Import Recipe")
                
            Text(LocalizedStringKey("Paste the url of a recipe you would like to import in the above, and we will try to fill in the fields for you. This feature does not work with every website. If your favourite website is not supported, feel free to reach out for help. You can find the contact details in the app settings."))
                .font(.caption)
                .foregroundStyle(.secondary)
            
            
                TextField(LocalizedStringKey("URL (e.g. example.com/recipe)"), text: $viewModel.importUrl)
                    .textFieldStyle(.roundedBorder)
                    .padding(.top, 5)
            Button {
                Task {
                    if let res = await importRecipe(viewModel.importUrl) {
                        viewModel.presentAlert(
                            RecipeAlert.CUSTOM(
                                title: res.localizedTitle,
                                description: res.localizedDescription
                            )
                        )
                    }
                }
            } label: {
                Text(LocalizedStringKey("Import"))
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).foregroundStyle(Color.primary.opacity(0.1)))
        .padding(5)
        .padding(.top, 5)
    }
}

