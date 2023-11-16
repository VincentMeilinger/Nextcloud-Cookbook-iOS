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
            if let recipeThumb = recipeThumb {
                Image(uiImage: recipeThumb)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipped()
            } else {
                ZStack {
                    Image(systemName: "square.text.square")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundStyle(Color.white)
                        .padding(10)
                        
                }
                .background(Color("ncblue"))
                .frame(width: 80, height: 80)
            }
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
            recipeThumb = await viewModel.getImage(id: recipe.recipe_id, size: .THUMB, needsUpdate: false)//loadImage(recipeId: recipe.recipe_id, thumb: true)
            self.isDownloaded = viewModel.recipeDetailExists(recipeId: recipe.recipe_id)
        }
        .refreshable {
            recipeThumb = await viewModel.getImage(id: recipe.recipe_id, size: .THUMB, needsUpdate: true)//.loadImage(recipeId: recipe.recipe_id, thumb: true, needsUpdate: true)
        }
    }
}
