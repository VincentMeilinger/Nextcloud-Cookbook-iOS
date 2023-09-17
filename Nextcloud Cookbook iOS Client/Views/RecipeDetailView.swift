//
//  RecipeDetailView.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 15.09.23.
//

import Foundation
import SwiftUI


struct RecipeDetailView: View {
    @ObservedObject var viewModel: MainViewModel
    @State var recipe: Recipe
    @State var recipeDetail: RecipeDetail?
    @State var recipeImage: UIImage?
    @State var showTitle: Bool = false
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading) {
                if let recipeImage = recipeImage {
                    Image(uiImage: recipeImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 300)
                        .clipped()
                } else {
                    Color("ncblue")
                        .frame(height: 150)
                }
                
                if let recipeDetail = recipeDetail {
                    LazyVStack (alignment: .leading) {
                        Divider()
                        Text(recipeDetail.name)
                            .font(.title)
                            .bold()
                            .padding()
                            .onDisappear {
                                showTitle = true
                            }
                            .onAppear {
                                showTitle = false
                            }
                        Divider()
                        RecipeYieldSection(recipeDetail: recipeDetail)
                        RecipeDurationSection(recipeDetail: recipeDetail)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 400), alignment: .top)]) {
                            if(!recipeDetail.recipeIngredient.isEmpty) {
                                RecipeIngredientSection(recipeDetail: recipeDetail)
                            }
                            if(!recipeDetail.tool.isEmpty) {
                                RecipeToolSection(recipeDetail: recipeDetail)
                            }
                            if(!recipeDetail.recipeInstructions.isEmpty) {
                                RecipeInstructionSection(recipeDetail: recipeDetail)
                            }
                        }
                    }.padding(.horizontal, 5)
                    
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(showTitle ? recipe.name : "")
        .task {
            recipeDetail = await viewModel.loadRecipeDetail(recipeId: recipe.recipe_id)
            recipeImage = await viewModel.loadImage(recipeId: recipe.recipe_id, full: true)
        }
        .refreshable {
            recipeDetail = await viewModel.loadRecipeDetail(recipeId: recipe.recipe_id, needsUpdate: true)
            recipeImage = await viewModel.loadImage(recipeId: recipe.recipe_id, full: true, needsUpdate: true)
        }
        
    }
}

struct RecipeYieldSection: View {
    @State var recipeDetail: RecipeDetail
    var body: some View {
        HStack {
            Text("Servings: \(recipeDetail.recipeYield)")
            Spacer()
        }.padding()
            
    }
}

struct RecipeDurationSection: View {
    @State var recipeDetail: RecipeDetail
    
    var body: some View {
        HStack {
            if let prepTime = recipeDetail.prepTime {
                VStack {
                    SecondaryLabel(text: "Prep time")
                    Text(formatDate(duration: prepTime))
                        .lineLimit(1)
                }.padding()
                .frame(maxWidth: .infinity)
                .background(Color("accent"))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            if let cookTime = recipeDetail.cookTime {
                VStack {
                    SecondaryLabel(text: "Cook time")
                    Text(formatDate(duration: cookTime))
                        .lineLimit(1)
                }.padding()
                .frame(maxWidth: .infinity)
                .background(Color("accent"))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            if let totalTime = recipeDetail.totalTime {
                VStack {
                    SecondaryLabel(text: "Total time")
                    Text(formatDate(duration: totalTime))
                        .lineLimit(1)
                }.padding()
                .frame(maxWidth: .infinity)
                .background(Color("accent"))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}


struct RecipeIngredientSection: View {
    @State var recipeDetail: RecipeDetail
    var body: some View {
        VStack(alignment: .leading) {
            Divider()
            HStack {
                SecondaryLabel(text: "Ingredients")
                Spacer()
            }
            ForEach(recipeDetail.recipeIngredient, id: \.self) { ingredient in
                HStack(alignment: .top) {
                    Text("\u{2022}")
                    Text("\(ingredient)")
                        .multilineTextAlignment(.leading)
                }
                .padding(4)
            }
        }.padding()
    }
}

struct RecipeToolSection: View {
    @State var recipeDetail: RecipeDetail
    var body: some View {
        VStack(alignment: .leading) {
            Divider()
            HStack {
                SecondaryLabel(text: "Tools")
                Spacer()
            }
            ForEach(recipeDetail.tool, id: \.self) { tool in
                HStack(alignment: .top) {
                    Text("\u{2022}")
                    Text("\(tool)")
                        .multilineTextAlignment(.leading)
                }
                .padding(4)
            }
        }.padding()
    }
}

struct RecipeInstructionSection: View {
    @State var recipeDetail: RecipeDetail
    var body: some View {
        VStack(alignment: .leading) {
            Divider()
            HStack {
                SecondaryLabel(text: "Instructions")
                Spacer()
            }
            ForEach(0..<recipeDetail.recipeInstructions.count) { ix in
                HStack(alignment: .top) {
                    Text("\(ix+1).")
                    Text("\(recipeDetail.recipeInstructions[ix])")
                }.padding(4)
            }
        }.padding()
    }
}




struct SecondaryLabel: View {
    let text: String
    var body: some View {
        Text(text)
            .foregroundColor(.secondary)
            .font(.headline)
            .padding(.vertical, 5)
    }
}
