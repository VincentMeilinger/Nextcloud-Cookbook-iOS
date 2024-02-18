//
//  RecipeDetailView.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 15.09.23.
//

import Foundation
import SwiftUI


struct RecipeView: View {
    @ObservedObject var appState: AppState
    @StateObject var viewModel: ViewModel
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading) {
                ZStack {
                    if let recipeImage = viewModel.recipeImage {
                        Image(uiImage: recipeImage)
                            .resizable()
                            .scaledToFill()
                            .frame(maxHeight: 300)
                            .clipped()
                    }
                }.animation(.easeInOut, value: viewModel.recipeImage)
                
                
                LazyVStack (alignment: .leading) {
                    HStack {
                        EditableText(text: $viewModel.recipeDetail.name, editMode: $viewModel.editMode)
                            .font(.title)
                            .bold()
                            .padding()
                            .onDisappear {
                                viewModel.showTitle = true
                            }
                            .onAppear {
                                viewModel.showTitle = false
                            }
                        
                        if let isDownloaded = viewModel.isDownloaded {
                            Spacer()
                            Image(systemName: isDownloaded ? "checkmark.circle" : "icloud.and.arrow.down")
                                .foregroundColor(.secondary)
                                .padding()
                        }
                    }
                    
                    if viewModel.recipeDetail.description != "" || viewModel.editMode {
                        EditableText(text: $viewModel.recipeDetail.description, editMode: $viewModel.editMode, lineLimit: 0...10, axis: .vertical)
                            .padding([.bottom, .horizontal])
                    }
                    
                    Divider()
                    
                    RecipeDurationSection(viewModel: appState, recipeDetail: viewModel.recipeDetail)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 400), alignment: .top)]) {
                        if(!viewModel.recipeDetail.recipeIngredient.isEmpty || viewModel.editMode) {
                            RecipeIngredientSection(viewModel: viewModel)
                        }
                        if(!viewModel.recipeDetail.recipeInstructions.isEmpty || viewModel.editMode) {
                            RecipeInstructionSection(viewModel: viewModel)
                        }
                        if(!viewModel.recipeDetail.tool.isEmpty || viewModel.editMode) {
                            RecipeToolSection(viewModel: viewModel)
                        }
                        RecipeNutritionSection(viewModel: viewModel)
                        RecipeKeywordSection(viewModel: viewModel)
                        MoreInformationSection(recipeDetail: viewModel.recipeDetail)
                    }
                    
                }.padding(.horizontal, 5)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(viewModel.showTitle ? viewModel.recipe.name : "")
        .toolbar {
            if viewModel.editMode {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        viewModel.editMode = false
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        // TODO: POST edited recipe
                        viewModel.editMode = false
                    }
                }
            } else {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            viewModel.editMode = true
                        } label: {
                            HStack {
                                Text("Edit")
                                Image(systemName: "pencil")
                            }
                        }
                        
                        Button {
                            print("Sharing recipe ...")
                            viewModel.presentShareSheet = true
                        } label: {
                            Text("Share recipe")
                            Image(systemName: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.presentShareSheet) {
            ShareView(recipeDetail: viewModel.recipeDetail,
                      recipeImage: viewModel.recipeImage,
                      presentShareSheet: $viewModel.presentShareSheet)
        }
        
        .task {
            viewModel.recipeDetail = await appState.getRecipe(
                id: viewModel.recipe.recipe_id,
                fetchMode: UserSettings.shared.storeRecipes ? .preferLocal : .onlyServer
            ) ?? RecipeDetail.error
            viewModel.recipeImage = await appState.getImage(
                id: viewModel.recipe.recipe_id,
                size: .FULL,
                fetchMode: UserSettings.shared.storeImages ? .preferLocal : .onlyServer
            )
            if viewModel.recipe.storedLocally == nil {
                viewModel.recipe.storedLocally = appState.recipeDetailExists(recipeId: viewModel.recipe.recipe_id)
            }
            viewModel.isDownloaded = viewModel.recipe.storedLocally
        }
        .refreshable {
            viewModel.recipeDetail = await appState.getRecipe(
                id: viewModel.recipe.recipe_id,
                fetchMode: UserSettings.shared.storeRecipes ? .preferServer : .onlyServer
            ) ?? RecipeDetail.error
            viewModel.recipeImage = await appState.getImage(
                id: viewModel.recipe.recipe_id,
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
    
    
    // MARK: - RecipeView ViewModel
    
    class ViewModel: ObservableObject {
        @Published var recipeDetail: RecipeDetail = RecipeDetail.error
        @Published var recipeImage: UIImage? = nil
        @Published var editMode: Bool = false
        @Published var presentShareSheet: Bool = false
        @Published var showTitle: Bool = false
        @Published var isDownloaded: Bool? = nil
        
        @Published var keywords: [String] = []
        @Published var nutrition: [String] = []
        
        var recipe: Recipe
        var sharedURL: URL? = nil
        
        
        init(recipe: Recipe) {
            self.recipe = recipe
        }
        
        func setupView(recipeDetail: RecipeDetail) {
            self.keywords = recipeDetail.keywords.components(separatedBy: ",")
        }
    }
}


// MARK: - Duration  Section

fileprivate struct RecipeDurationSection: View {
    @ObservedObject var viewModel: AppState
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
            /*
            if let cookTime = recipeDetail.cookTime, let time = DurationComponents.ptToText(cookTime) {
                TimerView(timer: viewModel.getTimer(forRecipe: recipeDetail.id, duration: DurationComponents.fromPTString(cookTime)))
                    .padding()
            }
            */
            
            if let cookTime = recipeDetail.cookTime, let time = DurationComponents.ptToText(cookTime) {
                VStack(alignment: .leading) {
                    HStack {
                        SecondaryLabel(text: LocalizedStringKey("Cooking"))
                        Spacer()
                    }
                    Text(time)
                        .lineLimit(1)
                }.padding()
            }
            
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


// MARK: - Nutrition Section

fileprivate struct RecipeNutritionSection: View {
    @ObservedObject var viewModel: RecipeView.ViewModel
    
    var body: some View {
        CollapsibleView(titleColor: .secondary, isCollapsed: !UserSettings.shared.expandNutritionSection) {
            Group {
                if viewModel.editMode {
                    ForEach(Nutrition.allCases, id: \.self) { nutrition in
                        HStack {
                            Text(nutrition.localizedDescription)
                            TextField("", text: binding(for: nutrition.dictKey), axis: .horizontal)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(1)
                        }
                    }
                } else {
                    if !viewModel.recipeDetail.nutrition.isEmpty {
                        VStack(alignment: .leading) {
                            ForEach(Nutrition.allCases, id: \.self) { nutrition in
                                if let value = viewModel.recipeDetail.nutrition[nutrition.dictKey] {
                                    HStack(alignment: .top) {
                                        Text(nutrition.localizedDescription)
                                        Text(":")
                                        Text(value)
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
            }
        } title: {
            HStack {
                if let servingSize = viewModel.recipeDetail.nutrition["servingSize"] {
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
            get: { viewModel.recipeDetail.nutrition[key, default: ""] },
            set: { viewModel.recipeDetail.nutrition[key] = $0 }
        )
    }
}


// MARK: - Keyword Section

fileprivate struct RecipeKeywordSection: View {
    @ObservedObject var viewModel: RecipeView.ViewModel
    @State var keywords: [String] = []
    
    var body: some View {
        CollapsibleView(titleColor: .secondary, isCollapsed: !UserSettings.shared.expandKeywordSection) {
            Group {
                if !keywords.isEmpty || viewModel.editMode {
                    //RecipeListSection(list: keywords)
                    EditableStringList(items: $keywords, editMode: $viewModel.editMode, titleKey: "Keyword", lineLimit: 0...1, axis: .horizontal) {
                        RecipeListSection(list: keywords)
                    }
                } else {
                    Text(LocalizedStringKey("No keywords."))
                }
            }
            .onAppear {
                self.keywords = viewModel.recipeDetail.keywords.components(separatedBy: ",")
            }
            .onDisappear {
                viewModel.recipeDetail.keywords = keywords.joined(separator: ",")
            }
        } title: {
            HStack {
                SecondaryLabel(text: LocalizedStringKey("Keywords"))
                Spacer()
            }
        }
        .padding()
    }
}


// MARK: - More Information Section

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

fileprivate struct SecondaryLabel: View {
    let text: LocalizedStringKey
    var body: some View {
        Text(text)
            .foregroundColor(.secondary)
            .font(.headline)
            .padding(.vertical, 5)
    }
}





// MARK: - Ingredients Section

fileprivate struct RecipeIngredientSection: View {
    @EnvironmentObject var groceryList: GroceryList
    @ObservedObject var viewModel: RecipeView.ViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                if viewModel.recipeDetail.recipeYield == 0 {
                    SecondaryLabel(text: LocalizedStringKey("Ingredients"))
                } else if viewModel.recipeDetail.recipeYield == 1 {
                    SecondaryLabel(text: LocalizedStringKey("Ingredients per serving"))
                } else {
                    SecondaryLabel(text: LocalizedStringKey("Ingredients for \(viewModel.recipeDetail.recipeYield) servings"))
                }
                Spacer()
                Button {
                    withAnimation {
                        if groceryList.containsRecipe(viewModel.recipeDetail.id) {
                            groceryList.deleteGroceryRecipe(viewModel.recipeDetail.id)
                        } else {
                            groceryList.addItems(
                                viewModel.recipeDetail.recipeIngredient,
                                toRecipe: viewModel.recipeDetail.id,
                                recipeName: viewModel.recipeDetail.name
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
            
            EditableStringList(items: $viewModel.recipeDetail.recipeIngredient, editMode: $viewModel.editMode, titleKey: "Ingredient", lineLimit: 0...1, axis: .horizontal) {
                ForEach(0..<viewModel.recipeDetail.recipeIngredient.count, id: \.self) { ix in
                    IngredientListItem(ingredient: viewModel.recipeDetail.recipeIngredient[ix], recipeId: viewModel.recipeDetail.id) {
                        groceryList.addItem(
                            viewModel.recipeDetail.recipeIngredient[ix],
                            toRecipe: viewModel.recipeDetail.id,
                            recipeName: viewModel.recipeDetail.name
                        )
                    }
                    .padding(4)
                }
            }
        }.padding()
    }
}

fileprivate struct IngredientListItem: View {
    @EnvironmentObject var groceryList: GroceryList
    @State var ingredient: String
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


// MARK: - Instructions Section

fileprivate struct RecipeInstructionSection: View {
    @ObservedObject var viewModel: RecipeView.ViewModel

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                SecondaryLabel(text: LocalizedStringKey("Instructions"))
                Spacer()
            }
            EditableStringList(items: $viewModel.recipeDetail.recipeInstructions, editMode: $viewModel.editMode, titleKey: "Instruction", lineLimit: 0...15, axis: .vertical) {
                ForEach(0..<viewModel.recipeDetail.recipeInstructions.count, id: \.self) { ix in
                    RecipeInstructionListItem(instruction: viewModel.recipeDetail.recipeInstructions[ix], index: ix+1)
                }
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


// MARK: - Tool Section

fileprivate struct RecipeToolSection: View {
    @ObservedObject var viewModel: RecipeView.ViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                SecondaryLabel(text: "Tools")
                Spacer()
            }
            EditableStringList(items: $viewModel.recipeDetail.tool, editMode: $viewModel.editMode, titleKey: "Tool", lineLimit: 0...1, axis: .horizontal) {
                RecipeListSection(list: viewModel.recipeDetail.tool)
            }
        }.padding()
    }
}


// MARK: - Generic Editable View Elements

fileprivate struct EditableText: View {
    @Binding var text: String
    @Binding var editMode: Bool
    @State var titleKey: LocalizedStringKey = ""
    @State var lineLimit: ClosedRange<Int> = 0...1
    @State var axis: Axis = .horizontal
    
    var body: some View {
        if editMode {
            TextField(titleKey, text: $text, axis: axis)
                .textFieldStyle(.roundedBorder)
                .lineLimit(lineLimit)
        } else {
            Text(text)
        }
    }
}


fileprivate struct EditableStringList<Content: View>: View {
    @Binding var items: [String]
    @Binding var editMode: Bool
    @State var titleKey: LocalizedStringKey = ""
    @State var lineLimit: ClosedRange<Int> = 0...50
    @State var axis: Axis = .vertical
    
    @State var editableItems: [ReorderableItem<String>] = []
    
    var content: () -> Content
    
    var body: some View {
        if editMode {
            VStack {
                ReorderableForEach(items: $editableItems, defaultItem: ReorderableItem(item: "")) { ix, item in
                    TextField("", text: $editableItems[ix].item, axis: axis)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(lineLimit)
                }
            }
            .onAppear {
                editableItems = ReorderableItem.list(items: items)
            }
            .onDisappear {
                items = ReorderableItem.items(editableItems)
            }
        } else {
            content()
        }
    }
}
