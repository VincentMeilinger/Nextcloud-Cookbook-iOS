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
    @State private var presentShareSheet: Bool = false
    @State private var sharedURL: URL? = nil
    
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
                        
                        RecipeDurationSection(viewModel: viewModel, recipeDetail: recipeDetail)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 400), alignment: .top)]) {
                            if(!recipeDetail.recipeIngredient.isEmpty) {
                                RecipeIngredientSection(recipeDetail: recipeDetail)
                            }
                            if(!recipeDetail.recipeInstructions.isEmpty) {
                                RecipeInstructionSection(recipeDetail: recipeDetail)
                            }
                            if(!recipeDetail.tool.isEmpty) {
                                RecipeToolSection(recipeDetail: recipeDetail)
                            }
                            RecipeNutritionSection(recipeDetail: recipeDetail)
                            RecipeKeywordSection(recipeDetail: recipeDetail)
                            MoreInformationSection(recipeDetail: recipeDetail)
                        }
                        
                    }.padding(.horizontal, 5)
                    
                }
            }.animation(.easeInOut, value: recipeImage)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(showTitle ? recipe.name : "")
        .toolbar {
            if recipeDetail != nil {
                Menu {
                    Button {
                        presentEditView = true
                    } label: {
                        HStack {
                            Text("Edit")
                            Image(systemName: "pencil")
                        }
                    }
                    
                    Button {
                        print("Sharing recipe ...")
                        self.presentShareSheet = true
                    } label: {
                        Text("Share recipe")
                        Image(systemName: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $presentEditView) {
            if let recipeDetail = recipeDetail {
                RecipeEditView(
                    viewModel:
                        RecipeEditViewModel(
                            mainViewModel: viewModel,
                            recipeDetail: recipeDetail,
                            uploadNew: false
                        ),
                    isPresented: $presentEditView
                )
            }
        }
        .sheet(isPresented: $presentShareSheet) {
            if let recipeDetail = recipeDetail {
                ShareView(recipeDetail: recipeDetail,
                          recipeImage: recipeImage,
                          presentShareSheet: $presentShareSheet)
            }
        }
        
        .task {
            recipeDetail = await viewModel.getRecipe(
                id: recipe.recipe_id,
                fetchMode: UserSettings.shared.storeRecipes ? .preferLocal : .onlyServer
            )
            recipeImage = await viewModel.getImage(
                id: recipe.recipe_id,
                size: .FULL,
                fetchMode: UserSettings.shared.storeImages ? .preferLocal : .onlyServer
            )
            if recipe.storedLocally == nil {
                recipe.storedLocally = viewModel.recipeDetailExists(recipeId: recipe.recipe_id)
            }
            self.isDownloaded = recipe.storedLocally
        }
        .refreshable {
            recipeDetail = await viewModel.getRecipe(
                id: recipe.recipe_id,
                fetchMode: UserSettings.shared.storeRecipes ? .preferServer : .onlyServer
            )
            recipeImage = await viewModel.getImage(
                id: recipe.recipe_id,
                size: .FULL,
                fetchMode: UserSettings.shared.storeImages ? .preferServer : .onlyServer
            )
        }
        .onAppear {
            if UserSettings.shared.keepScreenAwake {
                UIApplication.shared.isIdleTimerDisabled = true
            }
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
}

fileprivate struct ShareView: View {
    @State var recipeDetail: RecipeDetail
    @State var recipeImage: UIImage?
    @Binding var presentShareSheet: Bool
    
    @State var exporter = RecipeExporter()
    @State var sharedURL: URL? = nil
    
    var body: some View {
        VStack(alignment: .leading) {
            if let url = sharedURL {
                ShareLink(item: url, subject: Text("PDF Document")) {
                    Image(systemName: "doc")
                    Text("Share as PDF")
                }
                .foregroundStyle(.primary)
                .bold()
                .padding()
            }
            
            ShareLink(item: exporter.createText(recipe: recipeDetail), subject: Text("Recipe")) {
                Image(systemName: "ellipsis.message")
                Text("Share as text")
            }
            .foregroundStyle(.primary)
            .bold()
            .padding()
            
            /*ShareLink(item: exporter.createJson(recipe: recipeDetail), subject: Text("Recipe")) {
                Image(systemName: "doc.badge.gearshape")
                Text("Share as JSON")
            }
            .foregroundStyle(.primary)
            .bold()
            .padding()
            */
        }
        .task {
            self.sharedURL = exporter.createPDF(recipe: recipeDetail, image: recipeImage)
        }
        
    }
}


fileprivate struct RecipeDurationSection: View {
    @ObservedObject var viewModel: MainViewModel
    @State var recipeDetail: RecipeDetail
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 250), alignment: .leading)]) {
            if let prepTime = recipeDetail.prepTime, let time = DurationComponents.ptToText(prepTime) {
                VStack(alignment: .leading) {
                    HStack {
                        SecondaryLabel(text: LocalizedStringKey("Preparation"))
                        Spacer()
                    }
                    Text(time)
                        .lineLimit(1)
                }.padding()
            }
            
            if let cookTime = recipeDetail.cookTime, let time = DurationComponents.ptToText(cookTime) {
                TimerView(timer: viewModel.getTimer(forRecipe: recipeDetail.id, duration: DurationComponents.fromPTString(cookTime)))
                    .padding()
            }
            
            /*
            if let cookTime = recipeDetail.cookTime, let time = DurationComponents.ptToText(cookTime) {
                VStack(alignment: .leading) {
                    HStack {
                        SecondaryLabel(text: LocalizedStringKey("Cooking"))
                        Spacer()
                    }
                    Text(time)
                        .lineLimit(1)
                }.padding()
            }*/
            
            if let totalTime = recipeDetail.totalTime, let time = DurationComponents.ptToText(totalTime) {
                VStack(alignment: .leading) {
                    HStack {
                        SecondaryLabel(text: LocalizedStringKey("Total time"))
                        Spacer()
                    }
                    Text(time)
                        .lineLimit(1)
                }.padding()
            }
        }
    }
}



fileprivate struct RecipeNutritionSection: View {
    @State var recipeDetail: RecipeDetail
    
    var body: some View {
        HStack() {
            CollapsibleView(titleColor: .secondary, isCollapsed: !UserSettings.shared.expandNutritionSection) {
                Group {
                    if let nutritionList = recipeDetail.getNutritionList() {
                        RecipeListSection(list: nutritionList)
                    } else {
                        Text(LocalizedStringKey("No nutritional information."))
                    }
                }
            } title: {
                HStack {
                    if let servingSize = recipeDetail.nutrition["servingSize"] {
                        SecondaryLabel(text: "Nutrition (\(servingSize))")
                    } else {
                        SecondaryLabel(text: LocalizedStringKey("Nutrition"))
                    }
                    Spacer()
                }
            }
            .padding()
        }
    }
}



fileprivate struct RecipeKeywordSection: View {
    @State var recipeDetail: RecipeDetail
    
    var body: some View {
        CollapsibleView(titleColor: .secondary, isCollapsed: !UserSettings.shared.expandKeywordSection) {
            Group {
                if let keywords = getKeywords() {
                    RecipeListSection(list: keywords)
                } else {
                    Text(LocalizedStringKey("No keywords."))
                }
            }
        } title: {
            HStack {
                SecondaryLabel(text: LocalizedStringKey("Keywords"))
                Spacer()
            }
        }
        .padding()
    }
    
    func getKeywords() -> [String]? {
        let keywords = recipeDetail.keywords.components(separatedBy: ",")
        return keywords.isEmpty ? nil : keywords
    }
}


fileprivate struct MoreInformationSection: View {
    let recipeDetail: RecipeDetail
    
    var body: some View {
        CollapsibleView(titleColor: .secondary, isCollapsed: !UserSettings.shared.expandInfoSection) {
            VStack(alignment: .leading) {
                Text("Created: \(Date.convertISOStringToLocalString(isoDateString: recipeDetail.dateCreated) ?? "")")
                Text("Last modified: \(Date.convertISOStringToLocalString(isoDateString: recipeDetail.dateModified) ?? "")")
                if recipeDetail.url != "", let url = URL(string: recipeDetail.url) {
                    HStack() {
                        Text("URL:")
                        Link(destination: url) {
                            Text(recipeDetail.url)
                        }
                    }
                }
            }
            .font(.caption)
            .foregroundStyle(Color.secondary)
        } title: {
            HStack {
                SecondaryLabel(text: "More information")
                Spacer()
            }
        }
        .padding()
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
                Button {
                    GroceryList.shared.addItems(recipeDetail.recipeIngredient)
                } label: {
                    Image(systemName: "storefront")
                }
            }
            
            ForEach(recipeDetail.recipeIngredient, id: \.self) { ingredient in
                IngredientListItem(ingredient: ingredient)
                .padding(4)
                
            }
        }.padding()
    }
}


fileprivate struct RecipeToolSection: View {
    @State var recipeDetail: RecipeDetail
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                SecondaryLabel(text: "Tools")
                Spacer()
            }
            RecipeListSection(list: recipeDetail.tool)
        }.padding()
    }
}


fileprivate struct IngredientListItem: View {
    @State var ingredient: String
    @State var isSelected: Bool = false
    @State private var dragOffset: CGFloat = 0
    let maxDragDistance = 30.0
    
    var body: some View {
        HStack(alignment: .top) {
            if dragOffset > 0 {
                Image(systemName: "storefront")
                    .padding(2)
                    .background(Color.green)
                    .opacity((dragOffset - 10)/(maxDragDistance-10))
            }
            if isSelected {
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
        .animation(.easeInOut, value: isSelected)
        .offset(x: dragOffset, y: 0)
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    // Update drag offset as the user drags
                    let dragAmount = gesture.translation.width
                    self.dragOffset = min(dragAmount, maxDragDistance + pow(dragAmount - maxDragDistance, 0.7))
                }
                .onEnded { gesture in
                    if gesture.translation.width > maxDragDistance * 0.8 { // Swipe right threshold
                        GroceryList.shared.addItem(ingredient)
                    }
                    // Animate back to original position
                    withAnimation {
                        self.dragOffset = 0
                    }
                }
        )
    }
}



fileprivate struct RecipeListSection: View {
    @State var list: [String]
    
    var body: some View {
        VStack(alignment: .leading) {
            ForEach(list, id: \.self) { item in
                HStack(alignment: .top) {
                    Text("\u{2022}")
                    Text("\(item)")
                        .multilineTextAlignment(.leading)
                }
                .padding(4)
            }
        }
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
