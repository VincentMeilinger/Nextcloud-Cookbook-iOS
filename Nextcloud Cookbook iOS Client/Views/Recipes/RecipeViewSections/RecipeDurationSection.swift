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
    
    var body: some View {
        if viewModel.editMode {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200, maximum: .infinity), alignment: .leading)]) {
                EditableDurationView(time: viewModel.observableRecipeDetail.prepTime, title: LocalizedStringKey("Preparation"))
                EditableDurationView(time: viewModel.observableRecipeDetail.cookTime, title: LocalizedStringKey("Cooking"))
                EditableDurationView(time: viewModel.observableRecipeDetail.totalTime, title: LocalizedStringKey("Total time"))
            }
        } else {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200, maximum: .infinity), alignment: .leading)]) {
                DurationView(time: viewModel.observableRecipeDetail.prepTime, title: LocalizedStringKey("Preparation"))
                DurationView(time: viewModel.observableRecipeDetail.cookTime, title: LocalizedStringKey("Cooking"))
                DurationView(time: viewModel.observableRecipeDetail.totalTime, title: LocalizedStringKey("Total time"))
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
    @ObservedObject var time: DurationComponents
    @State var title: LocalizedStringKey
    @State var presentPopoverView: Bool = false
    @State var hour: Int = 0
    @State var minute: Int = 0
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                SecondaryLabel(text: title)
                Spacer()
            }
            Button {
                presentPopoverView.toggle()
            } label: {
                HStack {
                    Image(systemName: "clock")
                        .foregroundStyle(.secondary)
                    Text(time.displayString)
                        .lineLimit(1)
                }
            }
        }
        .padding()
        .popover(isPresented: $presentPopoverView) {
            TimePickerPopoverView(selectedHour: $hour, selectedMinute: $minute)
        }
        .onChange(of: presentPopoverView) { presentPopover in
            if !presentPopover {
                time.hourComponent = String(hour)
                time.minuteComponent = String(minute)
            }
        }
        .onAppear {
            minute = Int(time.minuteComponent) ?? 0
            hour = Int(time.hourComponent) ?? 0
        }
    }
}


fileprivate struct TimePickerPopoverView: View {
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
