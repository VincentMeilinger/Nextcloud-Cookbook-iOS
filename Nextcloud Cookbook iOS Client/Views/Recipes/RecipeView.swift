//
//  RecipeDetailView.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 15.09.23.
//

import Foundation
import SwiftUI


struct RecipeView: View {
    @EnvironmentObject var appState: AppState
    @Binding var isPresented: Bool
    @StateObject var viewModel: ViewModel
    var imageHeight: CGFloat {
        if let image = viewModel.recipeImage {
            return image.size.height < 350 ? image.size.height : 350
        }
        return 200
    }
    
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
                            .frame(maxHeight: imageHeight + 200)
                            .clipped()
                    } else {
                        Rectangle()
                            .frame(height: 400)
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [.ncGradientDark, .ncGradientLight]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
                
                VStack(alignment: .leading) {
                    if viewModel.editMode {
                        RecipeImportSection(viewModel: viewModel, importRecipe: importRecipe)
                    }
                    
                    if viewModel.editMode {
                        RecipeMetadataSection(viewModel: viewModel)
                    }
                    
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
                            .fontWeight(.medium)
                            .padding(.horizontal)
                            .padding(.top, 2)
                    }
                    
                    // Recipe Body Section
                    RecipeDurationSection(viewModel: viewModel)

                    Divider()
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 400), alignment: .top)]) {
                        if(!viewModel.observableRecipeDetail.recipeIngredient.isEmpty || viewModel.editMode) {
                            RecipeIngredientSection(viewModel: viewModel)
                        }
                        if(!viewModel.observableRecipeDetail.recipeInstructions.isEmpty || viewModel.editMode) {
                            RecipeInstructionSection(viewModel: viewModel)
                        }
                        if(!viewModel.observableRecipeDetail.tool.isEmpty || viewModel.editMode) {
                            RecipeToolSection(viewModel: viewModel)
                        }
                        RecipeNutritionSection(viewModel: viewModel)
                    }
                    
                    if !viewModel.editMode {
                        Divider()
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 400), alignment: .top)]) {
                            RecipeKeywordSection(viewModel: viewModel)
                            MoreInformationSection(viewModel: viewModel)
                        }
                    }
                }
                .padding(.horizontal, 5)
                .background(Rectangle().foregroundStyle(.background).shadow(radius: 5).mask(Rectangle().padding(.top, -20)))
            }
        }
        .coordinateSpace(name: CoordinateSpaces.scrollView)
        .ignoresSafeArea(.container, edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        //.toolbarTitleDisplayMode(.inline)
        .navigationTitle(viewModel.showTitle ? viewModel.recipe.name : "")
        .toolbar {
            RecipeViewToolBar(isPresented: $isPresented, viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.presentShareSheet) {
            ShareView(recipeDetail: viewModel.observableRecipeDetail.toRecipeDetail(),
                      recipeImage: viewModel.recipeImage,
                      presentShareSheet: $viewModel.presentShareSheet)
        }
        .sheet(isPresented: $viewModel.presentInstructionEditView) {
            EditableListView(
                isPresented: $viewModel.presentInstructionEditView,
                items: $viewModel.observableRecipeDetail.recipeInstructions,
                title: "Instructions",
                emptyListText: "Add cooking steps for fellow chefs to follow.",
                titleKey: "Instruction",
                lineLimit: 0...10,
                axis: .vertical)
        }
        .sheet(isPresented: $viewModel.presentIngredientEditView) {
            EditableListView(
                isPresented: $viewModel.presentIngredientEditView,
                items: $viewModel.observableRecipeDetail.recipeIngredient,
                title: "Ingredients",
                emptyListText: "Start by adding your first ingredient! 🥬",
                titleKey: "Ingredient",
                lineLimit: 0...1,
                axis: .horizontal)
        }
        .sheet(isPresented: $viewModel.presentToolEditView) {
            EditableListView(
                isPresented: $viewModel.presentToolEditView,
                items: $viewModel.observableRecipeDetail.tool,
                title: "Tools",
                emptyListText: "List your tools here. 🍴",
                titleKey: "Tool",
                lineLimit: 0...1,
                axis: .horizontal)
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
                
            } else {
                // Prepare view for a new recipe
                viewModel.setupView(recipeDetail: RecipeDetail())
                viewModel.editMode = true
                viewModel.isDownloaded = false
            }
        }
        .alert(viewModel.alertType.localizedTitle, isPresented: $viewModel.presentAlert) {
            ForEach(viewModel.alertType.alertButtons) { buttonType in
                if buttonType == .OK {
                    Button(AlertButton.OK.rawValue, role: .cancel) {
                        Task {
                            await viewModel.alertAction()
                        }
                    }
                } else if buttonType == .CANCEL {
                    Button(AlertButton.CANCEL.rawValue, role: .cancel) { }
                } else if buttonType == .DELETE {
                    Button(AlertButton.DELETE.rawValue, role: .destructive) {
                        Task {
                            await viewModel.alertAction()
                        }
                    }
                }
            }
        } message: {
            Text(viewModel.alertType.localizedDescription)
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
        @Published var showTitle: Bool = false
        @Published var isDownloaded: Bool? = nil
        @Published var importUrl: String = ""
        
        @Published var presentShareSheet: Bool = false
        @Published var presentInstructionEditView: Bool = false
        @Published var presentIngredientEditView: Bool = false
        @Published var presentToolEditView: Bool = false
        
        var recipe: Recipe
        var sharedURL: URL? = nil
        var newRecipe: Bool = false
        
        // Alerts
        @Published var presentAlert = false
        var alertType: UserAlert = RecipeAlert.GENERIC
        var alertAction: () async -> () = { }
        
        // Initializers
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
        
        // View setup
        func setupView(recipeDetail: RecipeDetail) {
            self.recipeDetail = recipeDetail
            self.observableRecipeDetail = ObservableRecipeDetail(recipeDetail)
        }
        
        func presentAlert(_ type: UserAlert, action: @escaping () async -> () = {}) {
            alertType = type
            alertAction = action
            presentAlert = true
        }
    }
}



extension RecipeView {
    func importRecipe(from url: String) async -> UserAlert? {
        let (scrapedRecipe, error) = await appState.importRecipe(url: url)
        if let scrapedRecipe = scrapedRecipe {
            viewModel.setupView(recipeDetail: scrapedRecipe)
            return nil
        }
        
        do {
            let (scrapedRecipe, error) = try await RecipeScraper().scrape(url: url)
            if let scrapedRecipe = scrapedRecipe {
                viewModel.setupView(recipeDetail: scrapedRecipe)
            }
            if let error = error {
                return error
            }
        } catch {
            print("Error")
            
        }
        return nil
    }
}


// MARK: - Tool Bar


struct RecipeViewToolBar: ToolbarContent {
    @EnvironmentObject var appState: AppState
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: RecipeView.ViewModel
    

    var body: some ToolbarContent {
        if viewModel.editMode {
            ToolbarItemGroup(placement: .topBarLeading){
                Button("Cancel") {
                    viewModel.editMode = false
                    isPresented = false
                }
                
                if !viewModel.newRecipe {
                    Menu {
                        Button(role: .destructive) {
                            viewModel.presentAlert(
                                RecipeAlert.CONFIRM_DELETE,
                                action: {
                                    await handleDelete()
                                }
                            )
                        } label: {
                            Label("Delete Recipe", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        await handleUpload()
                    }
                } label: {
                    if viewModel.newRecipe {
                        Text("Upload Recipe")
                    } else {
                        Text("Upload Changes")
                    }
                }
            }
        } else {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        viewModel.editMode = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button {
                        print("Sharing recipe ...")
                        viewModel.presentShareSheet = true
                    } label: {
                        Label("Share Recipe", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                
            }
        }
    }
    
    func handleUpload() async {
        if viewModel.newRecipe {
            print("Uploading new recipe.")
            if let recipeValidationError = recipeValid() {
                viewModel.presentAlert(recipeValidationError)
                return
            }
            
            if let alert = await appState.uploadRecipe(recipeDetail: viewModel.observableRecipeDetail.toRecipeDetail(), createNew: true) {
                viewModel.presentAlert(alert)
                return
            }
        } else {
            print("Uploading changed recipe.")
            
            guard let _ = Int(viewModel.observableRecipeDetail.id) else {
                viewModel.presentAlert(RequestAlert.REQUEST_DROPPED)
                return
            }
            
            if let alert = await appState.uploadRecipe(recipeDetail: viewModel.observableRecipeDetail.toRecipeDetail(), createNew: false) {
                viewModel.presentAlert(alert)
                return
            }
        }
        await appState.getCategories()
        await appState.getCategory(named: viewModel.observableRecipeDetail.recipeCategory, fetchMode: .preferServer)
        if let id = Int(viewModel.observableRecipeDetail.id) {
            await appState.getRecipe(id: id, fetchMode: .onlyServer, save: true)
        }
        viewModel.editMode = false
    }
    
    func handleDelete() async {
        let category = viewModel.observableRecipeDetail.recipeCategory
        guard let id = Int(viewModel.observableRecipeDetail.id) else {
            viewModel.presentAlert(RequestAlert.REQUEST_DROPPED)
            return
        }
        if let alert = await appState.deleteRecipe(withId: id, categoryName: viewModel.observableRecipeDetail.recipeCategory) {
            viewModel.presentAlert(alert)
            return
        }
        await appState.getCategories()
        await appState.getCategory(named: category, fetchMode: .preferServer)
        self.isPresented = false
    }
    
    func recipeValid() -> RecipeAlert? {
        // Check if the recipe has a name
        if viewModel.observableRecipeDetail.name.replacingOccurrences(of: " ", with: "") == "" {
            return RecipeAlert.NO_TITLE
        }
        
        // Check if the recipe has a unique name
        for recipeList in appState.recipes.values {
            for r in recipeList {
                if r.name
                    .replacingOccurrences(of: " ", with: "")
                    .lowercased() ==
                    viewModel.observableRecipeDetail.name
                    .replacingOccurrences(of: " ", with: "")
                    .lowercased()
                {
                    return RecipeAlert.DUPLICATE
                }
            }
        }
        return nil
    }
}


