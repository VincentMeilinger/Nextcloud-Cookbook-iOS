//
//  RecipeView.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 15.09.23.
//

import Foundation
import SwiftUI


/// Read-only recipe page. Editing happens in `RecipeEditorView`, opened with the
/// Edit button.
struct RecipeView: View {
    @EnvironmentObject var appState: AppState
    @Environment(LibraryModel.self) private var library
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: ViewModel
    @State private var showEditor = false

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
                        // Color.clear takes exactly the header's size; the image fills it
                        // and is clipped to it, so wide images can't spill sideways.
                        Color.clear
                            .overlay {
                                Image(uiImage: recipeImage)
                                    .resizable()
                                    .scaledToFill()
                            }
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
                    HStack {
                        Text(ObservableRecipeDetail.applyMarkdownStyling(viewModel.observableRecipeDetail.name))
                            .font(.title)
                            .bold()

                        Spacer()

                        originBadge
                    }.padding([.top, .horizontal])

                    if !viewModel.observableRecipeDetail.description.isEmpty {
                        Text(ObservableRecipeDetail.applyMarkdownStyling(viewModel.observableRecipeDetail.description))
                            .fontWeight(.medium)
                            .padding(.horizontal)
                            .padding(.top, 2)
                    }

                    RecipeKeywordPills(keywords: viewModel.observableRecipeDetail.keywords)
                        .padding(.horizontal)
                        .padding(.top, 6)

                    RecipeDurationSection(viewModel: viewModel)

                    Divider()

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 400), alignment: .top)]) {
                        if !viewModel.observableRecipeDetail.recipeIngredient.isEmpty {
                            RecipeIngredientSection(viewModel: viewModel)
                        }
                        if !viewModel.observableRecipeDetail.recipeInstructions.isEmpty {
                            RecipeInstructionSection(viewModel: viewModel)
                        }
                        if !viewModel.observableRecipeDetail.tool.isEmpty {
                            RecipeToolSection(viewModel: viewModel)
                        }
                        RecipeNutritionSection(viewModel: viewModel)
                    }

                    Divider()
                    MoreInformationSection(viewModel: viewModel)
                }
                .padding(.horizontal, 5)
                .background(Rectangle().foregroundStyle(.background).shadow(radius: 5).mask(Rectangle().padding(.top, -20)))
            }
        }
        .coordinateSpace(name: CoordinateSpaces.scrollView)
        .ignoresSafeArea(.container, edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                exportMenu
                    // Nothing to export until the recipe has loaded
                    .disabled(viewModel.recipeDetail.id == nil)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showEditor = true }
                    // Nothing to edit until the recipe has loaded
                    .disabled(viewModel.recipeDetail.id == nil)
            }
        }
        .sheet(isPresented: $showEditor) {
            RecipeEditorView(
                editing: viewModel.recipeDetail,
                origin: viewModel.recipe.origin,
                onSave: { recipe in
                    viewModel.recipe = recipe
                    Task { await loadRecipe(refreshImage: true) }
                },
                onDelete: { dismiss() }
            )
            .environmentObject(appState)
            .environment(library)
        }
        .task {
            await loadRecipe()
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

    /// Loads the recipe detail and image. After an edit, `refreshImage` fetches
    /// the image again because its URL may have changed.
    private func loadRecipe(refreshImage: Bool = false) async {
        let recipeDetail = await appState.getRecipe(
            id: viewModel.recipe.id,
            fetchMode: UserSettings.shared.storeRecipes ? .preferLocal : .onlyServer
        ) ?? RecipeDetail.error
        viewModel.setupView(recipeDetail: recipeDetail)

        // Show download/origin badge for Nextcloud recipes
        if viewModel.recipe.origin == .nextcloud && viewModel.recipe.storedLocally == nil {
            viewModel.recipe.storedLocally = await appState.recipeDetailExists(recipeId: viewModel.recipe.id)
            viewModel.isDownloaded = viewModel.recipe.storedLocally
        }

        let imageFetchMode: AppState.FetchMode = refreshImage
            ? .preferServer
            : (UserSettings.shared.storeImages ? .preferLocal : .onlyServer)
        viewModel.recipeImage = await appState.getImage(
            id: viewModel.recipe.id,
            size: .FULL,
            fetchMode: imageFetchMode
        )
    }


    // MARK: - Export

    /// Export button: a menu of formats. Each entry opens the share sheet, and the
    /// file is only created once a format is chosen.
    private var exportMenu: some View {
        let recipe = viewModel.recipeDetail
        let preview = SharePreview(recipe.name, image: viewModel.recipeImage.map { Image(uiImage: $0) } ?? Image(systemName: "fork.knife"))
        return Menu {
            ShareLink(item: RecipePDFExport(recipe: recipe, image: viewModel.recipeImage), preview: preview) {
                Label("PDF", systemImage: "doc.richtext")
            }
            ShareLink(item: RecipeExporter.text(recipe: recipe), subject: Text(recipe.name), preview: preview) {
                Label("Text", systemImage: "text.alignleft")
            }
            ShareLink(item: RecipeMarkdownExport(recipe: recipe), preview: preview) {
                Label("Markdown", systemImage: "number")
            }
            ShareLink(item: RecipeJSONExport(recipe: recipe), preview: preview) {
                Label("JSON (schema.org)", systemImage: "curlybraces")
            }
        } label: {
            Label("Export", systemImage: "square.and.arrow.up")
        }
    }


    // MARK: - Origin badge

    @ViewBuilder
    private var originBadge: some View {
        switch viewModel.recipe.origin {
        case .local:
            Image(systemName: "internaldrive")
                .foregroundColor(.secondary)
        case .nextcloud:
            if let cached = viewModel.isDownloaded {
                Image(systemName: cached ? "checkmark.icloud" : "icloud.and.arrow.down")
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - RecipeView ViewModel

    class ViewModel: ObservableObject {
        @Published var observableRecipeDetail: ObservableRecipeDetail = ObservableRecipeDetail()
        @Published var recipeDetail: RecipeDetail = RecipeDetail.error
        @Published var recipeImage: UIImage? = nil
        @Published var isDownloaded: Bool? = nil

        var recipe: Recipe

        init(recipe: Recipe) {
            self.recipe = recipe
        }

        func setupView(recipeDetail: RecipeDetail) {
            self.recipeDetail = recipeDetail
            self.observableRecipeDetail = ObservableRecipeDetail(recipeDetail)
        }
    }
}
