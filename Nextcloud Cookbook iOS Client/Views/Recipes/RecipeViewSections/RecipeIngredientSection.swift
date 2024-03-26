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
                }.disabled(viewModel.editMode)
                
                SecondaryLabel(text: LocalizedStringKey("Ingredients"))
                
                Spacer()
                
                Image(systemName: "person.2")
                    .foregroundStyle(.secondary)
                    .bold()
                
                ServingPickerView(selectedServingSize: $viewModel.observableRecipeDetail.ingredientMultiplier)
            }
            
            ForEach(0..<viewModel.observableRecipeDetail.recipeIngredient.count, id: \.self) { ix in
                IngredientListItem(
                    ingredient: $viewModel.observableRecipeDetail.recipeIngredient[ix],
                    servings: $viewModel.observableRecipeDetail.ingredientMultiplier,
                    recipeYield: Double(viewModel.observableRecipeDetail.recipeYield),
                    recipeId: viewModel.observableRecipeDetail.id
                ) {
                    groceryList.addItem(
                        viewModel.observableRecipeDetail.recipeIngredient[ix],
                        toRecipe: viewModel.observableRecipeDetail.id,
                        recipeName: viewModel.observableRecipeDetail.name
                    )
                }
                .padding(4)
            }
            
            if viewModel.observableRecipeDetail.ingredientMultiplier != Double(viewModel.observableRecipeDetail.recipeYield) {
                HStack() {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.secondary)
                    Text("Marked ingredients could not be adjusted!")
                        .foregroundStyle(.secondary)
                }.padding(.top)
            }
            
            if viewModel.editMode {
                Button {
                    viewModel.presentIngredientEditView.toggle()
                } label: {
                    Text("Edit")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .animation(.easeInOut, value: viewModel.observableRecipeDetail.ingredientMultiplier)
    }
}

// MARK: - RecipeIngredientSection List Item

fileprivate struct IngredientListItem: View {
    @EnvironmentObject var groceryList: GroceryList
    @Binding var ingredient: String
    @Binding var servings: Double
    @State var recipeYield: Double
    @State var recipeId: String
    let addToGroceryListAction: () -> Void
    
    @State var modifiedIngredient: AttributedString = ""
    @State var isSelected: Bool = false
    var unmodified: Bool {
        servings == Double(recipeYield) || servings == 0
    }
    
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
            if !unmodified && String(modifiedIngredient.characters) == ingredient {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            }
            if unmodified {
                Text(ingredient)
                    .multilineTextAlignment(.leading)
                    .lineLimit(5)
            } else {
                Text(modifiedIngredient)
                    .multilineTextAlignment(.leading)
                    .lineLimit(5)
                    //.foregroundStyle(String(modifiedIngredient.characters) == ingredient ? .red : .primary)
            }
            Spacer()
        }
        .onChange(of: servings) { newServings in
            if recipeYield == 0 {
                modifiedIngredient = ObservableRecipeDetail.adjustIngredient(ingredient, by: newServings)
            } else {
                modifiedIngredient = ObservableRecipeDetail.adjustIngredient(ingredient, by: newServings/recipeYield)
            }
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



struct ServingPickerView: View {
    @Binding var selectedServingSize: Double

    // Computed property to handle the text field input and update the selectedServingSize
    var body: some View {
        HStack {
            Button {
                selectedServingSize -= 1
            } label: {
                Image(systemName: "minus.square.fill")
                    .bold()
            }
            TextField("", value: $selectedServingSize, formatter: numberFormatter)
                .keyboardType(.numbersAndPunctuation)
                .lineLimit(1)
                .multilineTextAlignment(.center)
                .frame(width: 40)
            Button {
                selectedServingSize += 1
            } label: {
                Image(systemName: "plus.square.fill")
                    .bold()
            }
        }
        .onChange(of: selectedServingSize) { newValue in
            if newValue < 0 { selectedServingSize = 0 }
            else if newValue > 100 { selectedServingSize = 100 }
        }
    }
}
