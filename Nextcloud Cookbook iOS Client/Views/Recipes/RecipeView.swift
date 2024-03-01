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
                            .frame(maxHeight: imageHeight + 200)
                            .clipped()
                    }
                }
                
                VStack(alignment: .leading) {
                    if viewModel.editMode {
                        RecipeImportSection(viewModel: viewModel, importRecipe: importRecipe)
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
                    
                    if viewModel.editMode {
                        RecipeMetadataSection(viewModel: viewModel)
                    }
                    
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
                    
                    Divider()
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 400), alignment: .top)]) {
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
                    Button {
                        // TODO: POST edited recipe
                        if viewModel.newRecipe {
                            presentationMode.wrappedValue.dismiss()
                        } else {
                            viewModel.editMode = false
                        }
                    } label: {
                        if viewModel.newRecipe {
                            Text("Upload Recipe")
                        } else {
                            Text("Upload Changes")
                        }
                    }
                }
                if !viewModel.newRecipe {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button {
                                print("Delete recipe.")
                                viewModel.alertType = RecipeAlert.CONFIRM_DELETE
                                viewModel.alertAction = {
                                    if let res = await deleteRecipe() {
                                        viewModel.alertType = res
                                        viewModel.alertAction = { }
                                        viewModel.presentAlert = true
                                    } else {
                                        presentationMode.wrappedValue.dismiss()
                                    }
                                }
                                viewModel.presentAlert = true
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                                Text("Delete recipe")
                                    .foregroundStyle(.red)
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.title3)
                                .padding()
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
        @Published var presentShareSheet: Bool = false
        @Published var showTitle: Bool = false
        @Published var isDownloaded: Bool? = nil
        @Published var importUrl: String = ""
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
    
    func uploadNewRecipe() async -> UserAlert? {
        print("Uploading new recipe.")
        if let recipeValidationError = recipeValid() {
            return recipeValidationError
        }
        
        return await appState.uploadRecipe(recipeDetail: viewModel.observableRecipeDetail.toRecipeDetail(), createNew: true)
    }
    
    func uploadEditedRecipe() async -> UserAlert? {
        print("Uploading changed recipe.")
        
        guard let recipeId = Int(viewModel.observableRecipeDetail.id) else { return RequestAlert.REQUEST_DROPPED }
        
        return await appState.uploadRecipe(recipeDetail: viewModel.observableRecipeDetail.toRecipeDetail(), createNew: false)
    }
    
    func deleteRecipe() async -> RequestAlert? {
        guard let id = Int(viewModel.observableRecipeDetail.id) else {
            return .REQUEST_DROPPED
        }
        return await appState.deleteRecipe(withId: id, categoryName: viewModel.observableRecipeDetail.recipeCategory)
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


// MARK: - Recipe Import Section

fileprivate struct RecipeImportSection: View {
    @ObservedObject var viewModel: RecipeView.ViewModel
    var importRecipe: (String) async -> UserAlert?
    
    var body: some View {
        VStack(alignment: .leading) {
            SecondaryLabel(text: "Import Recipe")
                
            Text(LocalizedStringKey("Paste the url of a recipe you would like to import in the above, and we will try to fill in the fields for you. This feature does not work with every website. If your favourite website is not supported, feel free to reach out for help. You can find the contact details in the app settings."))
                .font(.caption)
                .foregroundStyle(.secondary)
            
            HStack {
                TextField(LocalizedStringKey("URL (e.g. example.com/recipe)"), text: $viewModel.importUrl)
                    .textFieldStyle(.roundedBorder)
                Button {
                    Task {
                        if let res = await importRecipe(viewModel.importUrl) {
                            viewModel.alertType = RecipeAlert.CUSTOM(
                                title: res.localizedTitle,
                                description: res.localizedDescription
                            )
                            viewModel.alertAction = { }
                            viewModel.presentAlert = true
                        }
                    }
                } label: {
                    Text(LocalizedStringKey("Import"))
                }
            }.padding(.top, 5)
        }
        .padding()
        .background(Rectangle().foregroundStyle(Color.white.opacity(0.1)))
    }
}
