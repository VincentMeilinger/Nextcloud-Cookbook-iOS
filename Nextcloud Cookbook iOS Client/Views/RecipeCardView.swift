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
    var body: some View {
        HStack {
            Image(uiImage: recipeThumb ?? UIImage(named: "CookBook")!)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 80)
                .clipped()
            Text(recipe.name)
                .font(.headline)
                
            Spacer()
        }
        .background(.ultraThickMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
        .task {
            recipeThumb = await viewModel.loadImage(recipeId: recipe.recipe_id, full: false)
        }
        .refreshable {
            recipeThumb = await viewModel.loadImage(recipeId: recipe.recipe_id, full: false, needsUpdate: true)
        }
    }
}
