//
//  RecipeCardView.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 15.09.23.
//

import Foundation
import SwiftUI

struct RecipeCardView: View {
    @State var viewModel: MainViewModel
    @State var recipe: Recipe
    @State var recipeThumb: UIImage?
    @State var isDownloaded: Bool? = nil
    
    var body: some View {
        HStack {
            Image(uiImage: recipeThumb ?? UIImage(named: "cookbook-recipe")!)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 80)
                .clipped()
            Text(recipe.name)
                .font(.headline)
                
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
            recipeThumb = await viewModel.loadImage(recipeId: recipe.recipe_id, thumb: true)
            self.isDownloaded = viewModel.recipeDetailExists(recipeId: recipe.recipe_id)
        }
        .refreshable {
            recipeThumb = await viewModel.loadImage(recipeId: recipe.recipe_id, thumb: true, needsUpdate: true)
        }
    }
}
