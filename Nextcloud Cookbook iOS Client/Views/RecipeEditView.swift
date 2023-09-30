//
//  RecipeEditView.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 29.09.23.
//

import Foundation
import SwiftUI


struct RecipeEditView: View {
    @State var recipe: RecipeDetail
    
    @State var times = [Date.zero, Date.zero, Date.zero]
    
    init(recipe: RecipeDetail? = nil) {
        
        self.recipe = recipe ?? RecipeDetail()
    }
    
    var body: some View {
        Form {
            TextField("Title", text: $recipe.name)
            Section() {
                DatePicker("Prep time:", selection: $times[0], displayedComponents: .hourAndMinute)
                DatePicker("Cook time:", selection: $times[1], displayedComponents: .hourAndMinute)
                DatePicker("Total time:", selection: $times[2], displayedComponents: .hourAndMinute)
            }
            
            Section() {
                
                List {
                    ForEach(recipe.recipeInstructions.indices, id: \.self) { ix in
                        HStack(alignment: .top) {
                            Text("\(ix+1).")
                            TextEditor(text: $recipe.recipeInstructions[ix])
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .onMove { indexSet, offset in
                        recipe.recipeInstructions.move(fromOffsets: indexSet, toOffset: offset)
                    }
                    .onDelete { indexSet in
                        recipe.recipeInstructions.remove(atOffsets: indexSet)
                    }
                }
                HStack {
                    Spacer()
                    Text("Add instruction")
                    Button() {
                        recipe.recipeInstructions.append("")
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            } header: {
                HStack {
                    Text("Ingredients")
                    Spacer()
                    EditButton()
                }
            }
        }
    }
}


struct TimePicker: View {
    @Binding var hours: Int
    @Binding var minutes: Int

    var body: some View {
        HStack {
            Picker("", selection: $hours){
                ForEach(0..<99, id: \.self) { i in
                    Text("\(i) hours").tag(i)
                }
            }.pickerStyle(.wheel)
            Picker("", selection: $minutes){
                ForEach(0..<60, id: \.self) { i in
                    Text("\(i) min").tag(i)
                }
            }.pickerStyle(.wheel)
        }
        .padding(.horizontal)
    }
}
