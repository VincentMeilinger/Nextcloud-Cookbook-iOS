//
//  RecipeNutritionSection.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 01.03.24.
//

import Foundation
import SwiftUI

// MARK: - RecipeView Nutrition Section

struct RecipeNutritionSection: View {
    @ObservedObject var viewModel: RecipeView.ViewModel
    
    var body: some View {
        CollapsibleView(titleColor: .secondary, isCollapsed: !UserSettings.shared.expandNutritionSection) {
            VStack(alignment: .leading) {
                if viewModel.editMode {
                    ForEach(Nutrition.allCases, id: \.self) { nutrition in
                        HStack {
                            Text(nutrition.localizedDescription)
                            TextField("", text: binding(for: nutrition.dictKey), axis: .horizontal)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(1)
                        }
                    }
                } else if !nutritionEmpty() {
                    VStack(alignment: .leading) {
                        ForEach(Nutrition.allCases, id: \.self) { nutrition in
                            if let value = viewModel.observableRecipeDetail.nutrition[nutrition.dictKey], nutrition.dictKey != Nutrition.servingSize.dictKey {
                                HStack(alignment: .top) {
                                    Text("\(nutrition.localizedDescription): \(value)")
                                        .multilineTextAlignment(.leading)
                                }
                                .padding(4)
                            }
                        }
                    }
                } else {
                    Text(LocalizedStringKey("No nutritional information."))
                }
            }
        } title: {
            HStack {
                if let servingSize = viewModel.observableRecipeDetail.nutrition["servingSize"] {
                    SecondaryLabel(text: "Nutrition (\(servingSize))")
                } else {
                    SecondaryLabel(text: LocalizedStringKey("Nutrition"))
                }
                Spacer()
            }
        }
        .padding()
    }
    
    func binding(for key: String) -> Binding<String> {
        Binding(
            get: { viewModel.observableRecipeDetail.nutrition[key, default: ""] },
            set: { viewModel.observableRecipeDetail.nutrition[key] = $0 }
        )
    }
    
    func nutritionEmpty() -> Bool {
        for nutrition in Nutrition.allCases {
            if let value = viewModel.observableRecipeDetail.nutrition[nutrition.dictKey] {
                return false
            }
        }
        return true
    }
}
