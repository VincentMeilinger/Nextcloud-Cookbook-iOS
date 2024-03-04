//
//  RecipeDurationSection.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 01.03.24.
//

import Foundation
import SwiftUI

// MARK: - RecipeView Duration Section

struct RecipeDurationSection: View {
    @ObservedObject var viewModel: RecipeView.ViewModel
    @State var presentPopover: Bool = false
    
    var body: some View {
        if !viewModel.editMode {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200, maximum: .infinity), alignment: .leading)]) {
                DurationView(time: viewModel.observableRecipeDetail.prepTime, title: LocalizedStringKey("Preparation"))
                DurationView(time: viewModel.observableRecipeDetail.cookTime, title: LocalizedStringKey("Cooking"))
                DurationView(time: viewModel.observableRecipeDetail.totalTime, title: LocalizedStringKey("Total time"))
            }
        } else {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200, maximum: .infinity), alignment: .leading)]) {
                Button {
                    presentPopover.toggle()
                } label: {
                    DurationView(time: viewModel.observableRecipeDetail.prepTime, title: LocalizedStringKey("Preparation"))
                }
                Button {
                    presentPopover.toggle()
                } label: {
                    DurationView(time: viewModel.observableRecipeDetail.cookTime, title: LocalizedStringKey("Cooking"))
                }
                Button {
                    presentPopover.toggle()
                } label: {
                    DurationView(time: viewModel.observableRecipeDetail.totalTime, title: LocalizedStringKey("Total time"))
                }
            }
            .popover(isPresented: $presentPopover) {
                EditableDurationView(
                    prepTime: viewModel.observableRecipeDetail.prepTime,
                    cookTime: viewModel.observableRecipeDetail.cookTime,
                    totalTime: viewModel.observableRecipeDetail.totalTime
                )
            }
        }
        
        
    }
}

fileprivate struct DurationView: View {
    @ObservedObject var time: DurationComponents
    @State var title: LocalizedStringKey
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                SecondaryLabel(text: title)
                Spacer()
            }
            HStack {
                Image(systemName: "clock")
                    .foregroundStyle(.secondary)
                Text(time.displayString)
                    .lineLimit(1)
            }
        }
        .padding()
    }
}

fileprivate struct EditableDurationView: View {
    @ObservedObject var prepTime: DurationComponents
    @ObservedObject var cookTime: DurationComponents
    @ObservedObject var totalTime: DurationComponents
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                HStack {
                    SecondaryLabel(text: "Preparation")
                    Spacer()
                }
                TimePickerView(selectedHour: $prepTime.hourComponent, selectedMinute: $prepTime.minuteComponent)
                SecondaryLabel(text: "Cooking")
                TimePickerView(selectedHour: $cookTime.hourComponent, selectedMinute: $cookTime.minuteComponent)
                SecondaryLabel(text: "Total")
                TimePickerView(selectedHour: $totalTime.hourComponent, selectedMinute: $totalTime.minuteComponent)
            }
            .padding()
        }
    }
}


fileprivate struct TimePickerView: View {
    @Binding var selectedHour: Int
    @Binding var selectedMinute: Int
    
    var body: some View {
        HStack {
            Picker(selection: $selectedHour, label: Text("Hours")) {
                ForEach(0..<99, id: \.self) { hour in
                    Text("\(hour) h").tag(hour)
                }
            }
            .pickerStyle(WheelPickerStyle())
            .frame(width: 100, height: 150)
            .clipped()

            Picker(selection: $selectedMinute, label: Text("Minutes")) {
                ForEach(0..<60, id: \.self) { minute in
                    Text("\(minute) min").tag(minute)
                }
            }
            .pickerStyle(WheelPickerStyle())
            .frame(width: 100, height: 150)
            .clipped()
        }
        .padding()
    }
}
