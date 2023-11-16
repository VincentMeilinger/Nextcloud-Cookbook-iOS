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
    @State private var presentNutritionPopover: Bool = false
    @State private var presentKeywordPopover: Bool = false
    
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
                        
                        if recipeDetail.description != "" {
                            Text(recipeDetail.description)
                                .padding([.bottom, .horizontal])
                        }
                        
                        Divider()
                        
                        RecipeDurationSection(recipeDetail: recipeDetail)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 400), alignment: .top)]) {
                            if(!recipeDetail.recipeIngredient.isEmpty) {
                                RecipeIngredientSection(recipeDetail: recipeDetail)
                            }
                            if(!recipeDetail.tool.isEmpty) {
                                RecipeListSection(title: "Tools", list: recipeDetail.tool)
                            }
                            if(!recipeDetail.recipeInstructions.isEmpty) {
                                RecipeInstructionSection(recipeDetail: recipeDetail)
                            }
                            RecipeNutritionSection(recipeDetail: recipeDetail, presentNutritionPopover: $presentNutritionPopover)
                            RecipeKeywordSection(recipeDetail: recipeDetail, presentKeywordPopover: $presentKeywordPopover)
                        }
                    }.padding(.horizontal, 5)
                    
                }
            }.animation(.easeInOut, value: recipeImage)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(showTitle ? recipe.name : "")
        .toolbar {
            if recipeDetail != nil {
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
                RecipeEditView(viewModel:
                    RecipeEditViewModel(
                        mainViewModel: viewModel,
                        recipeDetail: recipeDetail,
                        isPresented: $presentEditView,
                        uploadNew: false
                    )
                )
            }
        }
        .task {
            recipeDetail = await viewModel.getRecipe(id: recipe.recipe_id)//loadRecipeDetail(recipeId: recipe.recipe_id)
            recipeImage = await viewModel.getImage(id: recipe.recipe_id, size: .FULL, needsUpdate: false)//.loadImage(recipeId: recipe.recipe_id, thumb: false)
            self.isDownloaded = viewModel.recipeDetailExists(recipeId: recipe.recipe_id)
        }
        .refreshable {
            recipeDetail = await viewModel.getRecipe(id: recipe.recipe_id)//.loadRecipeDetail(recipeId: recipe.recipe_id, needsUpdate: true)
            recipeImage = await viewModel.getImage(id: recipe.recipe_id, size: .FULL, needsUpdate: true)//.loadImage(recipeId: recipe.recipe_id, thumb: false, needsUpdate: true)
        }
    }
}


fileprivate struct RecipeDurationSection: View {
    @State var recipeDetail: RecipeDetail
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), alignment: .leading)]) {
            if let prepTime = recipeDetail.prepTime, let time = DurationComponents.ptToText(prepTime) {
                VStack(alignment: .leading) {
                    SecondaryLabel(text: LocalizedStringKey("Preparation"))
                    Text(time)
                        .lineLimit(1)
                }.padding()
            }
            
            if let cookTime = recipeDetail.cookTime, let time = DurationComponents.ptToText(cookTime) {
                VStack(alignment: .leading) {
                    SecondaryLabel(text: LocalizedStringKey("Cooking"))
                    Text(time)
                        .lineLimit(1)
                }.padding()
            }
            
            if let totalTime = recipeDetail.totalTime, let time = DurationComponents.ptToText(totalTime) {
                VStack(alignment: .leading) {
                    SecondaryLabel(text: LocalizedStringKey("Total time"))
                    Text(time)
                        .lineLimit(1)
                }.padding()
            }
        }
    }
}



fileprivate struct RecipeNutritionSection: View {
    @State var recipeDetail: RecipeDetail
    @Binding var presentNutritionPopover: Bool
    
    var body: some View {
        Button {
            presentNutritionPopover.toggle()
        } label: {
            HStack {
                SecondaryLabel(text: "Nutrition")
                Image(systemName: "chevron.right")
                    .foregroundStyle(Color.secondary)
                    .bold()
                Spacer()
            }.padding()
        }
        .buttonStyle(.plain)
        .popover(isPresented: $presentNutritionPopover) {
            if let nutritionList = recipeDetail.getNutritionList() {
                ScrollView(showsIndicators: false) {
                    if let servingSize = recipeDetail.nutrition["servingSize"] {
                        RecipeListSection(title: "Nutrition (\(servingSize))", list: nutritionList)
                            .presentationCompactAdaptation(.popover)
                    } else {
                        RecipeListSection(title: "Nutrition", list: nutritionList)
                            .presentationCompactAdaptation(.popover)
                    }
                }
            } else {
                Text(LocalizedStringKey("No nutritional information."))
                    .foregroundStyle(Color.secondary)
                    .bold()
                    .padding()
                    .presentationCompactAdaptation(.popover)
            }
        }
    }
}


fileprivate struct RecipeKeywordSection: View {
    @State var recipeDetail: RecipeDetail
    @Binding var presentKeywordPopover: Bool
    
    var body: some View {
        Button {
            presentKeywordPopover.toggle()
        } label: {
            HStack {
                SecondaryLabel(text: "Keywords")
                Image(systemName: "chevron.right")
                    .foregroundStyle(Color.secondary)
                    .bold()
                Spacer()
            }.padding()
        }
        .buttonStyle(.plain)
        .popover(isPresented: $presentKeywordPopover) {
            if let keywords = getKeywords() {
                ScrollView(showsIndicators: false) {
                    RecipeListSection(title: "Keywords", list: keywords)
                        .presentationCompactAdaptation(.popover)
                }
            } else {
                Text(LocalizedStringKey("No keywords."))
                    .foregroundStyle(Color.secondary)
                    .bold()
                    .padding()
                    .presentationCompactAdaptation(.popover)
            }
            
        }
    }
    
    func getKeywords() -> [String]? {
        let keywords = recipeDetail.keywords.components(separatedBy: ",")
        return keywords.isEmpty ? nil : keywords
    }
}



fileprivate struct RecipeIngredientSection: View {
    @State var recipeDetail: RecipeDetail
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                if recipeDetail.recipeYield == 0 {
                    SecondaryLabel(text: LocalizedStringKey("Ingredients"))
                } else if recipeDetail.recipeYield == 1 {
                    SecondaryLabel(text: LocalizedStringKey("Ingredients per serving"))
                } else {
                    SecondaryLabel(text: LocalizedStringKey("Ingredients for \(recipeDetail.recipeYield) servings"))
                }
                Spacer()
            }
            ForEach(recipeDetail.recipeIngredient, id: \.self) { ingredient in
                IngredientListItem(ingredient: ingredient)
                .padding(4)
            }
        }.padding()
    }
}



fileprivate struct IngredientListItem: View {
    @State var ingredient: String
    @State var isSelected: Bool = false
    
    var body: some View {
        HStack(alignment: .top) {
            if isSelected {
                Image(systemName: "checkmark.circle")
            } else {
                Image(systemName: "circle")
            }
            
            Text("\(ingredient)")
                .multilineTextAlignment(.leading)
                .lineLimit(5)
        }
        .foregroundStyle(isSelected ? Color.secondary : Color.primary)
        .onTapGesture {
            isSelected.toggle()
        }
        .animation(.easeInOut, value: isSelected)
    }
}



fileprivate struct RecipeListSection: View {
    @State var title: LocalizedStringKey
    @State var list: [String]
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                SecondaryLabel(text: title)
                Spacer()
            }
            ForEach(list, id: \.self) { item in
                HStack(alignment: .top) {
                    Text("\u{2022}")
                    Text("\(item)")
                        .multilineTextAlignment(.leading)
                }
                .padding(4)
            }
        }.padding()
    }
}



fileprivate struct RecipeInstructionSection: View {
    @State var recipeDetail: RecipeDetail
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                SecondaryLabel(text: LocalizedStringKey("Instructions"))
                Spacer()
            }
            ForEach(0..<recipeDetail.recipeInstructions.count) { ix in
                RecipeInstructionListItem(instruction: recipeDetail.recipeInstructions[ix], index: ix+1)
            }
        }.padding()
    }
}



fileprivate struct RecipeInstructionListItem: View {
    @State var instruction: String
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



fileprivate struct SecondaryLabel: View {
    let text: LocalizedStringKey
    var body: some View {
        Text(text)
            .foregroundColor(.secondary)
            .font(.headline)
            .padding(.vertical, 5)
    }
}
