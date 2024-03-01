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


