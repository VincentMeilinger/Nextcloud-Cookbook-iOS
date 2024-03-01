//
//  RecipeDetailView.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 15.09.23.
//

import Foundation
import SwiftUI


struct RecipeView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appState: AppState
    @StateObject var viewModel: ViewModel
    @State var imageHeight: CGFloat = 350
    
    private enum CoordinateSpaces {
        case scrollView
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                ParallaxHeader(
                    coordinateSpace: CoordinateSpaces.scrollView,
                    defaultHeight: imageHeight
                ) {
                    if let recipeImage = viewModel.recipeImage {
                        Image(uiImage: recipeImage)
                            .resizable()
                            .scaledToFill()
                    }
                }
                
                VStack(alignment: .leading) {
                    HStack {
                        EditableText(text: $viewModel.observableRecipeDetail.name, editMode: $viewModel.editMode, titleKey: "Recipe Name")
                            .font(.title)
                            .bold()
                        
                        Spacer()
                        
                        if let isDownloaded = viewModel.isDownloaded {
                            Image(systemName: isDownloaded ? "checkmark.circle" : "icloud.and.arrow.down")
                                .foregroundColor(.secondary)
                        }
                    }.padding([.top, .horizontal])
                    
                    if viewModel.observableRecipeDetail.description != "" || viewModel.editMode {
                        EditableText(text: $viewModel.observableRecipeDetail.description, editMode: $viewModel.editMode, titleKey: "Description", lineLimit: 0...5, axis: .vertical)
                            .padding([.bottom, .horizontal])
                    }
                    
                    
                    // Recipe Body Section
                    RecipeDurationSection(viewModel: viewModel)

                    Divider()
                    
                    if viewModel.editMode {
                        RecipeMetadataSection(viewModel: viewModel)
                    }
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 400), alignment: .top)]) {
                        if(!viewModel.observableRecipeDetail.recipeIngredient.isEmpty || viewModel.editMode) {
                            RecipeIngredientSection(viewModel: viewModel)
                                .background(RoundedRectangle(cornerRadius: 20).foregroundStyle(.ultraThinMaterial))
                                .padding(5)
                        }
                        if(!viewModel.observableRecipeDetail.recipeInstructions.isEmpty || viewModel.editMode) {
                            RecipeInstructionSection(viewModel: viewModel)
                                .background(RoundedRectangle(cornerRadius: 20).foregroundStyle(.ultraThinMaterial))
                                .padding(5)
                        }
                        if(!viewModel.observableRecipeDetail.tool.isEmpty || viewModel.editMode) {
                            RecipeToolSection(viewModel: viewModel)
                        }
                        RecipeNutritionSection(viewModel: viewModel)
                        if !viewModel.editMode {
                            RecipeKeywordSection(viewModel: viewModel)
                        }
                        MoreInformationSection(viewModel: viewModel)
                    }
                }
                .padding(.horizontal, 5)
                .background(Rectangle().foregroundStyle(.background).shadow(radius: 5).mask(Rectangle().padding(.top, -20)))
            }
        }
        .coordinateSpace(name: CoordinateSpaces.scrollView)
        .ignoresSafeArea(.container, edges: .top)
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
                        if viewModel.newRecipe {
                            presentationMode.wrappedValue.dismiss()
                        } else {
                            viewModel.editMode = false
                        }
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
            ShareView(recipeDetail: viewModel.observableRecipeDetail.toRecipeDetail(),
                      recipeImage: viewModel.recipeImage,
                      presentShareSheet: $viewModel.presentShareSheet)
        }
        
        .task {
            // Load recipe detail
            if !viewModel.newRecipe {
                // For existing recipes, load the recipeDetail and image
                let recipeDetail = await appState.getRecipe(
                    id: viewModel.recipe.recipe_id,
                    fetchMode: UserSettings.shared.storeRecipes ? .preferLocal : .onlyServer
                ) ?? RecipeDetail.error
                viewModel.setupView(recipeDetail: recipeDetail)
                
                // Show download badge
                if viewModel.recipe.storedLocally == nil {
                    viewModel.recipe.storedLocally = appState.recipeDetailExists(recipeId: viewModel.recipe.recipe_id)
                }
                viewModel.isDownloaded = viewModel.recipe.storedLocally
                
                // Load recipe image
                viewModel.recipeImage = await appState.getImage(
                    id: viewModel.recipe.recipe_id,
                    size: .FULL,
                    fetchMode: UserSettings.shared.storeImages ? .preferLocal : .onlyServer
                )
                if let image = viewModel.recipeImage {
                    imageHeight = image.size.height < 350 ? image.size.height : 350
                } else {
                    imageHeight = 100
                }
            } else {
                // Prepare view for a new recipe
                viewModel.setupView(recipeDetail: RecipeDetail())
                viewModel.editMode = true
                viewModel.isDownloaded = false
            }
        }
        .onAppear {
            if UserSettings.shared.keepScreenAwake {
                UIApplication.shared.isIdleTimerDisabled = true
            }
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onChange(of: viewModel.editMode) { newValue in
            if newValue && appState.allKeywords.isEmpty {
                Task {
                    appState.allKeywords = await appState.getKeywords(fetchMode: .preferServer).sorted(by: { a, b in
                        a.recipe_count > b.recipe_count
                    })
                }
            }
        }
    }
    
    
    // MARK: - RecipeView ViewModel
    
    class ViewModel: ObservableObject {
        @Published var observableRecipeDetail: ObservableRecipeDetail = ObservableRecipeDetail()
        @Published var recipeDetail: RecipeDetail = RecipeDetail.error
        @Published var recipeImage: UIImage? = nil
        @Published var editMode: Bool = false
        @Published var presentShareSheet: Bool = false
        @Published var showTitle: Bool = false
        @Published var isDownloaded: Bool? = nil
        var newRecipe: Bool = false
        
        var recipe: Recipe
        var sharedURL: URL? = nil
        
        
        init(recipe: Recipe) {
            self.recipe = recipe
        }
        
        init() {
            self.newRecipe = true
            self.recipe = Recipe(
                name: String(localized: "New Recipe"),
                keywords: "",
                dateCreated: "",
                dateModified: "",
                imageUrl: "",
                imagePlaceholderUrl: "",
                recipe_id: 0)
        }
        
        func setupView(recipeDetail: RecipeDetail) {
            self.recipeDetail = recipeDetail
            self.observableRecipeDetail = ObservableRecipeDetail(recipeDetail)
        }
        
    }
}


// MARK: - Recipe Metadata Section

struct RecipeMetadataSection: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var viewModel: RecipeView.ViewModel
    
    @State var categories: [String] = []
    @State var keywords: [RecipeKeyword] = []
    @State var presentKeywordPopover: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            CategoryPickerView(items: $categories, input: $viewModel.observableRecipeDetail.recipeCategory, titleKey: "Category")
            
            SecondaryLabel(text: "Keywords")
                .padding()
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(viewModel.observableRecipeDetail.keywords, id: \.self) { keyword in
                        Text(keyword)
                    }
                }
            }.padding(.horizontal)
            
            Button {
                presentKeywordPopover.toggle()
            } label: {
                Text("Edit keywords")
                Image(systemName: "chevron.right")
            }
            .padding(.horizontal)
            
        }
        .task {
            categories = appState.categories.map({ category in category.name })
        }
        .sheet(isPresented: $presentKeywordPopover) {
            KeywordPickerView(title: "Keywords", searchSuggestions: appState.allKeywords, selection: $viewModel.observableRecipeDetail.keywords)
        }
    }
}



struct CategoryPickerView: View {
    @Binding var items: [String]
    @Binding var input: String
    @State private var pickerChoice: String = ""

    var titleKey: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading) {
            SecondaryLabel(text: "Category")
                .padding([.top, .horizontal])
            HStack {
                TextField(titleKey, text: $input)
                    .lineLimit(1)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                    .onSubmit {
                        pickerChoice = ""
                    }
                
                Picker("Select Item", selection: $pickerChoice) {
                    Text("").tag("")
                    ForEach(items, id: \.self) { item in
                        Text(item)
                    }
                }
                .pickerStyle(.menu)
                .padding()
                .onChange(of: pickerChoice) { newValue in
                    if pickerChoice != "" {
                        input = newValue
                    }
                }
            }
        }
        .onAppear {
            pickerChoice = input
        }
    }
}



// MARK: - Duration Section

fileprivate struct RecipeDurationSection: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var viewModel: RecipeView.ViewModel
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 200, maximum: .infinity), alignment: .leading)]) {
            DurationView(time: viewModel.observableRecipeDetail.prepTime.displayString, title: LocalizedStringKey("Preparation"))
            DurationView(time: viewModel.observableRecipeDetail.cookTime.displayString, title: LocalizedStringKey("Cooking"))
            DurationView(time: viewModel.observableRecipeDetail.totalTime.displayString, title: LocalizedStringKey("Total time"))
        }
        
    }
}

struct DurationView: View {
    @State var time: String
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
                Text(time)
                    .lineLimit(1)
            }
        }
        .padding()
    }
}



// MARK: - Nutrition Section

fileprivate struct RecipeNutritionSection: View {
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


// MARK: - Keyword Section

fileprivate struct RecipeKeywordSection: View {
    @ObservedObject var viewModel: RecipeView.ViewModel
    let columns: [GridItem] = [ GridItem(.flexible(minimum: 50, maximum: 200), spacing: 5) ]
    
    var body: some View {
        CollapsibleView(titleColor: .secondary, isCollapsed: !UserSettings.shared.expandKeywordSection) {
            Group {
                if !viewModel.observableRecipeDetail.keywords.isEmpty && !viewModel.editMode {
                    RecipeListSection(list: viewModel.observableRecipeDetail.keywords)
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
}


// MARK: - More Information Section

fileprivate struct MoreInformationSection: View {
    @ObservedObject var viewModel: RecipeView.ViewModel
    
    var body: some View {
        CollapsibleView(titleColor: .secondary, isCollapsed: !UserSettings.shared.expandInfoSection) {
            VStack(alignment: .leading) {
                Text("Created: \(Date.convertISOStringToLocalString(isoDateString: viewModel.recipeDetail.dateCreated) ?? "")")
                Text("Last modified: \(Date.convertISOStringToLocalString(isoDateString: viewModel.recipeDetail.dateModified) ?? "")")
                if viewModel.observableRecipeDetail.url != "", let url = URL(string: viewModel.observableRecipeDetail.url) {
                    HStack() {
                        Text("URL:")
                        Link(destination: url) {
                            Text(viewModel.observableRecipeDetail.url)
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
                                ReorderableItem.items(viewModel.observableRecipeDetail.recipeIngredient),
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
            
            EditableStringList(items: $viewModel.observableRecipeDetail.recipeIngredient, editMode: $viewModel.editMode, titleKey: "Ingredient", lineLimit: 0...1, axis: .horizontal) {
                ForEach(0..<viewModel.observableRecipeDetail.recipeIngredient.count, id: \.self) { ix in
                    IngredientListItem(ingredient: viewModel.observableRecipeDetail.recipeIngredient[ix], recipeId: viewModel.observableRecipeDetail.id) {
                        groceryList.addItem(
                            viewModel.observableRecipeDetail.recipeIngredient[ix].item,
                            toRecipe: viewModel.observableRecipeDetail.id,
                            recipeName: viewModel.observableRecipeDetail.name
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
    @State var ingredient: ReorderableItem<String>
    @State var recipeId: String
    let addToGroceryListAction: () -> Void
    @State var isSelected: Bool = false
    
    // Drag animation
    @State private var dragOffset: CGFloat = 0
    @State private var animationStartOffset: CGFloat = 0
    let maxDragDistance = 50.0
    
    var body: some View {
        HStack(alignment: .top) {
            if groceryList.containsItem(at: recipeId, item: ingredient.item) {
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
            
            Text("\(ingredient.item)")
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
                            if groceryList.containsItem(at: recipeId, item: ingredient.item) {
                                groceryList.deleteItem(ingredient.item, fromRecipe: recipeId)
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
            EditableStringList(items: $viewModel.observableRecipeDetail.recipeInstructions, editMode: $viewModel.editMode, titleKey: "Instruction", lineLimit: 0...15, axis: .vertical) {
                ForEach(0..<viewModel.observableRecipeDetail.recipeInstructions.count, id: \.self) { ix in
                    RecipeInstructionListItem(instruction: viewModel.observableRecipeDetail.recipeInstructions[ix], index: ix+1)
                }
            }
        }.padding()
    }
}

fileprivate struct RecipeInstructionListItem: View {
    @State var instruction: ReorderableItem<String>
    @State var index: Int
    @State var isSelected: Bool = false
    
    var body: some View {
        HStack(alignment: .top) {
            Text("\(index)")
                .monospaced()
            Text(instruction.item)
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
            EditableStringList(items: $viewModel.observableRecipeDetail.tool, editMode: $viewModel.editMode, titleKey: "Tool", lineLimit: 0...1, axis: .horizontal) {
                RecipeListSection(list: ReorderableItem.items(viewModel.observableRecipeDetail.tool))
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
    @Binding var items: [ReorderableItem<String>]
    @Binding var editMode: Bool
    @State var titleKey: LocalizedStringKey = ""
    @State var lineLimit: ClosedRange<Int> = 0...50
    @State var axis: Axis = .vertical
    
    var content: () -> Content
    
    var body: some View {
        if editMode {
            VStack {
                ReorderableForEach(items: $items, defaultItem: ReorderableItem(item: "")) { ix, item in
                    TextField("", text: $items[ix].item, axis: axis)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(lineLimit)
                }
            }
            .transition(.slide)
        } else {
            content()
        }
    }
}
