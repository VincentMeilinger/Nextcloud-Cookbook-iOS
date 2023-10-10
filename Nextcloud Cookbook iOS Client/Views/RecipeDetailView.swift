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
    @State var isDownloaded: Bool? = nil
    @State private var presentEditView: Bool = false
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading) {
                if let recipeImage = recipeImage {
                    Image(uiImage: recipeImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxHeight: 300)
                        .clipped()
                }
                
                if let recipeDetail = recipeDetail {
                    LazyVStack (alignment: .leading) {
                        Divider()
                        HStack {
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
                            
                            if let isDownloaded = isDownloaded {
                                Spacer()
                                Image(systemName: isDownloaded ? "checkmark.circle" : "icloud.and.arrow.down")
                                    .foregroundColor(.secondary)
                                    .padding()
                            }
                        }
                        Divider()
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
            }.animation(.easeInOut, value: recipeImage)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(showTitle ? recipe.name : "")
        .toolbar {
            if let recipeDetail = recipeDetail {
                Button {
                    presentEditView = true
                } label: {
                    HStack {
                        Text("Edit")
                    }
                }
            }
        }
        .sheet(isPresented: $presentEditView) {
            if let recipeDetail = recipeDetail {
                RecipeEditView(viewModel: viewModel, recipe: recipeDetail, isPresented: $presentEditView, uploadNew: false)
            }
        }
        .task {
            recipeDetail = await viewModel.loadRecipeDetail(recipeId: recipe.recipe_id)
            recipeImage = await viewModel.loadImage(recipeId: recipe.recipe_id, thumb: false)
            self.isDownloaded = viewModel.recipeDetailExists(recipeId: recipe.recipe_id)
        }
        .refreshable {
            recipeDetail = await viewModel.loadRecipeDetail(recipeId: recipe.recipe_id, needsUpdate: true)
            recipeImage = await viewModel.loadImage(recipeId: recipe.recipe_id, thumb: false, needsUpdate: true)
        }
    }
}


struct RecipeDurationSection: View {
    @State var recipeDetail: RecipeDetail
    
    var body: some View {
        HStack(alignment: .center) {
            if let prepTime = recipeDetail.prepTime {
                VStack {
                    SecondaryLabel(text: String(localized: "Prep time"))
                    Text(DateFormatter.formatDate(duration: prepTime))
                        .lineLimit(1)
                }.padding()
            }
            
            if let cookTime = recipeDetail.cookTime {
                VStack {
                    SecondaryLabel(text: String(localized: "Cook time"))
                    Text(DateFormatter.formatDate(duration: cookTime))
                        .lineLimit(1)
                }.padding()
            }
            
            if let totalTime = recipeDetail.totalTime {
                VStack {
                    SecondaryLabel(text: String(localized: "Total time"))
                    Text(DateFormatter.formatDate(duration: totalTime))
                        .lineLimit(1)
                }.padding()
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
                if recipeDetail.recipeYield == 0 {
                    SecondaryLabel(text: String(localized: "Ingredients"))
                } else if recipeDetail.recipeYield == 1 {
                    SecondaryLabel(text: String(localized: "Ingredients per serving"))
                } else {
                    SecondaryLabel(text: String(localized: "Ingredients for \(recipeDetail.recipeYield) servings"))
                }
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
                SecondaryLabel(text: String(localized: "Tools"))
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
                SecondaryLabel(text: String(localized: "Instructions"))
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
