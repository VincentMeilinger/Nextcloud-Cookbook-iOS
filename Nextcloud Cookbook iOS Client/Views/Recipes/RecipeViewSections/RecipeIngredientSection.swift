//
//  RecipeIngredientSection.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 01.03.24.
//

import Foundation
import SwiftUI

// MARK: - RecipeView Ingredients Section

struct RecipeIngredientSection: View {
    @EnvironmentObject var groceryList: GroceryList
    @ObservedObject var viewModel: RecipeView.ViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                if viewModel.observableRecipeDetail.recipeYield == 0 {
                    SecondaryLabel(text: LocalizedStringKey("Ingredients"))
                } else if viewModel.observableRecipeDetail.recipeYield == 1 {
                    SecondaryLabel(text: LocalizedStringKey("Ingredients per serving"))
                } else {
                    SecondaryLabel(text: LocalizedStringKey("Ingredients for \(viewModel.observableRecipeDetail.recipeYield) servings"))
                }
                Spacer()
                Button {
                    withAnimation {
                        if groceryList.containsRecipe(viewModel.observableRecipeDetail.id) {
                            groceryList.deleteGroceryRecipe(viewModel.observableRecipeDetail.id)
                        } else {
                            groceryList.addItems(
                                viewModel.observableRecipeDetail.recipeIngredient,
                                toRecipe: viewModel.observableRecipeDetail.id,
                                recipeName: viewModel.observableRecipeDetail.name
                            )
                        }
                    }
                } label: {
                    if #available(iOS 17.0, *) {
                        Image(systemName: "storefront")
                    } else {
                        Image(systemName: "heart.text.square")
                    }
                }
            }
            
            ForEach(0..<viewModel.observableRecipeDetail.recipeIngredient.count, id: \.self) { ix in
                IngredientListItem(ingredient: $viewModel.observableRecipeDetail.recipeIngredient[ix], recipeId: viewModel.observableRecipeDetail.id) {
                    groceryList.addItem(
                        viewModel.observableRecipeDetail.recipeIngredient[ix],
                        toRecipe: viewModel.observableRecipeDetail.id,
                        recipeName: viewModel.observableRecipeDetail.name
                    )
                }
                .padding(4)
            }
            if viewModel.editMode {
                Button {
                    viewModel.presentIngredientEditView.toggle()
                } label: {
                    Text("Edit")
                }
                .buttonStyle(.borderedProminent)
            }
        }.padding()
    }
}

// MARK: - RecipeIngredientSection List Item

fileprivate struct IngredientListItem: View {
    @EnvironmentObject var groceryList: GroceryList
    @Binding var ingredient: String
    @State var recipeId: String
    let addToGroceryListAction: () -> Void
    @State var isSelected: Bool = false
    
    // Drag animation
    @State private var dragOffset: CGFloat = 0
    @State private var animationStartOffset: CGFloat = 0
    let maxDragDistance = 50.0
    
    var body: some View {
        HStack(alignment: .top) {
            if groceryList.containsItem(at: recipeId, item: ingredient) {
                if #available(iOS 17.0, *) {
                    Image(systemName: "storefront")
                        .foregroundStyle(Color.green)
                } else {
                    Image(systemName: "heart.text.square")
                        .foregroundStyle(Color.green)
                }
                    
            } else if isSelected {
                Image(systemName: "checkmark.circle")
            } else {
                Image(systemName: "circle")
            }
            
            Text("\(ingredient)")
                .multilineTextAlignment(.leading)
                .lineLimit(5)
            Spacer()
        }
        .foregroundStyle(isSelected ? Color.secondary : Color.primary)
        .onTapGesture {
            isSelected.toggle()
        }
        .offset(x: dragOffset, y: 0)
        .animation(.easeInOut, value: isSelected)
        
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    // Update drag offset as the user drags
                    if animationStartOffset == 0 {
                        animationStartOffset = gesture.translation.width
                    }
                    let dragAmount = gesture.translation.width
                    let offset = min(dragAmount, maxDragDistance + pow(dragAmount - maxDragDistance, 0.7)) - animationStartOffset
                    self.dragOffset = max(0, offset)
                }
                .onEnded { gesture in
                    withAnimation {
                        if dragOffset > maxDragDistance * 0.3 { // Swipe threshold
                            if groceryList.containsItem(at: recipeId, item: ingredient) {
                                groceryList.deleteItem(ingredient, fromRecipe: recipeId)
                                } else {
                                    addToGroceryListAction()
                                }
                        }
                        // Animate back to original position
                        self.dragOffset = 0
                        self.animationStartOffset = 0
                    }
                }
        )
    }
}
