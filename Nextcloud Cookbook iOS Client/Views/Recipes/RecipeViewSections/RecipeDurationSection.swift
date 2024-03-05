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
        VStack(alignment: .leading) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200, maximum: .infinity), alignment: .leading)]) {
                DurationView(time: viewModel.observableRecipeDetail.prepTime, title: LocalizedStringKey("Preparation"))
                DurationView(time: viewModel.observableRecipeDetail.cookTime, title: LocalizedStringKey("Cooking"))
                DurationView(time: viewModel.observableRecipeDetail.totalTime, title: LocalizedStringKey("Total time"))
            }
            if viewModel.editMode {
                Button {
                    presentPopover.toggle()
                } label: {
                    Text("Edit")
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 5)
            }
        }
        .padding()
        .popover(isPresented: $presentPopover) {
            EditableDurationView(
                prepTime: viewModel.observableRecipeDetail.prepTime,
                cookTime: viewModel.observableRecipeDetail.cookTime,
                totalTime: viewModel.observableRecipeDetail.totalTime
            )
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
                    .bold()
                    .foregroundStyle(.secondary)
                Text(time.displayString)
                    .lineLimit(1)
            }
        }
    }
}

fileprivate struct EditableDurationView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var prepTime: DurationComponents
    @ObservedObject var cookTime: DurationComponents
    @ObservedObject var totalTime: DurationComponents
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center) {
                HStack {
                    SecondaryLabel(text: "Preparation")
                    Spacer()
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                TimePickerView(selectedHour: $prepTime.hourComponent, selectedMinute: $prepTime.minuteComponent)
                
                HStack {
                    SecondaryLabel(text: "Cooking")
                    Spacer()
                }
                TimePickerView(selectedHour: $cookTime.hourComponent, selectedMinute: $cookTime.minuteComponent)
                
                HStack {
                    SecondaryLabel(text: "Total time")
                    Spacer()
                }
                TimePickerView(selectedHour: $totalTime.hourComponent, selectedMinute: $totalTime.minuteComponent)
            }
            .padding()
            .onChange(of: prepTime.hourComponent) { _ in updateTotalTime() }
            .onChange(of: prepTime.minuteComponent) { _ in updateTotalTime() }
            .onChange(of: cookTime.hourComponent) { _ in updateTotalTime() }
            .onChange(of: cookTime.minuteComponent) { _ in updateTotalTime() }
        }
    }
    
    private func updateTotalTime() {
        var hourComponent = prepTime.hourComponent + cookTime.hourComponent
        var minuteComponent = prepTime.minuteComponent + cookTime.minuteComponent
        // Handle potential overflow from minutes to hours
        if minuteComponent >= 60 {
            hourComponent += minuteComponent / 60
            minuteComponent %= 60
        }
        totalTime.hourComponent = hourComponent
        totalTime.minuteComponent = minuteComponent
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
