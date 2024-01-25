//
//  RecipeCardView.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 15.09.23.
//

import Foundation
import SwiftUI

struct RecipeCardView: View {
    @State var viewModel: AppState
    @State var recipe: Recipe
    @State var recipeThumb: UIImage?
    @State var isDownloaded: Bool? = nil
    
    var body: some View {
        HStack {
            if let recipeThumb = recipeThumb {
                Image(uiImage: recipeThumb)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 17))
            } else {
                Image(systemName: "square.text.square")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(Color.white)
                    .padding(10)
                    .background(Color("ncblue"))
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 17))
            }
            Text(recipe.name)
                .font(.headline)
                .padding(.leading, 4)
                
            Spacer()
            if let isDownloaded = isDownloaded {
                VStack {
                    Image(systemName: isDownloaded ? "checkmark.circle" : "icloud.and.arrow.down")
                        .foregroundColor(.secondary)
                        .padding()
                    Spacer()
                }
            }
        }
        .background(Color.backgroundHighlight)
        .clipShape(RoundedRectangle(cornerRadius: 17))
        .padding(.horizontal)
        .task {
            recipeThumb = await viewModel.getImage(
                id: recipe.recipe_id,
                size: .THUMB,
                fetchMode: UserSettings.shared.storeThumb ? .preferLocal : .onlyServer
            )
            if recipe.storedLocally == nil {
                recipe.storedLocally = viewModel.recipeDetailExists(recipeId: recipe.recipe_id)
            }
            isDownloaded = recipe.storedLocally
        }
        .refreshable {
            recipeThumb = await viewModel.getImage(
                id: recipe.recipe_id,
                size: .THUMB,
                fetchMode: UserSettings.shared.storeThumb ? .preferServer : .onlyServer
            )
        }
    }
}
