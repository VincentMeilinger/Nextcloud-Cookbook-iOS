//
//  RecipeMetadataSection.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 01.03.24.
//

import Foundation
import SwiftUI

// MARK: - RecipeView More Information Section

struct MoreInformationSection: View {
    @ObservedObject var viewModel: RecipeView.ViewModel
    
    var body: some View {
        CollapsibleView(titleColor: .secondary, isCollapsed: !UserSettings.shared.expandInfoSection) {
            VStack(alignment: .leading) {
                if let dateCreated = viewModel.recipeDetail.dateCreated {
                    Text("Created: \(Date.convertISOStringToLocalString(isoDateString: dateCreated) ?? "")")
                }
                if let dateModified = viewModel.recipeDetail.dateModified {
                    Text("Last modified: \(Date.convertISOStringToLocalString(isoDateString: dateModified) ?? "")")
                }
                if viewModel.observableRecipeDetail.url != "", let url = URL(string: viewModel.observableRecipeDetail.url) {
                    HStack(alignment: .top) {
                        Text("URL:")
                        Link(destination: url) {
                            Text(viewModel.observableRecipeDetail.url)
                        }
                    }
                }
            }
            .font(.caption)
            .foregroundStyle(Color.secondary)
        } title: {
            HStack {
                SecondaryLabel(text: "More information")
                Spacer()
            }
        }
        .padding()
    }
}
