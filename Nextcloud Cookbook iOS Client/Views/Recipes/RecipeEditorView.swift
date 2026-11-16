//
//  RecipeEditorView.swift
//  Nextcloud Cookbook iOS Client
//
//  Form for creating or editing a recipe: optional import from a website (new
//  recipes), then name, details, times, ingredients, instructions, tools and
//  nutrition.
//

import PhotosUI
import SwiftUI


// MARK: - Draft

/// Editable copy of a recipe. A value type, so the form edits it through
/// plain bindings and nothing is saved until the user taps Save.
struct RecipeDraft: Equatable {
    /// A list entry (ingredient, step, tool) with a stable identity, so text
    /// fields keep focus while typing and rows can be deleted safely.
    struct Line: Identifiable, Equatable {
        let id = UUID()
        var text: String
    }

    /// App-internal id; `nil` for a recipe that hasn't been saved yet.
    var id: Int?
    /// Nextcloud id; set when the recipe exists on the server (also after a server import).
    var externalSourceId: String?
    var name = ""
    var description = ""
    var category = ""
    var servings = 1
    var keywords: [String] = []
    var imageURL = ""
    var sourceURL = ""
    var prepMinutes = 0
    var cookMinutes = 0
    var totalMinutes = 0
    var ingredients: [Line] = []
    var instructions: [Line] = []
    var tools: [Line] = []
    var nutrition: [String: String] = [:]

    init(category: String = "") {
        self.category = category
    }

    init(_ detail: RecipeDetail) {
        id = detail.id
        externalSourceId = detail.externalSourceId
        name = detail.name
        description = detail.description
        category = detail.recipeCategory
        servings = max(1, detail.recipeYield)
        keywords = detail.keywords.isEmpty ? [] : detail.keywords.components(separatedBy: ",")
        imageURL = detail.image ?? ""
        sourceURL = detail.url ?? ""
        prepMinutes = Self.minutes(fromISO8601: detail.prepTime)
        cookMinutes = Self.minutes(fromISO8601: detail.cookTime)
        totalMinutes = Self.minutes(fromISO8601: detail.totalTime)
        ingredients = detail.recipeIngredient.map { Line(text: $0) }
        instructions = detail.recipeInstructions.map { Line(text: $0) }
        tools = detail.tool.map { Line(text: $0) }
        nutrition = detail.nutrition
    }

    func toRecipeDetail() -> RecipeDetail {
        func clean(_ lines: [Line]) -> [String] {
            lines.map(\.text.trimmed).filter { !$0.isEmpty }
        }
        return RecipeDetail(
            name: name.trimmed,
            keywords: keywords.joined(separator: ","),
            dateCreated: "",
            dateModified: "",
            image: imageURL.trimmed,
            imageUrl: "",
            id: id,
            externalSourceId: externalSourceId,
            prepTime: Self.iso8601(minutes: prepMinutes),
            cookTime: Self.iso8601(minutes: cookMinutes),
            totalTime: Self.iso8601(minutes: totalMinutes),
            description: description.trimmed,
            url: sourceURL.trimmed,
            recipeYield: servings,
            recipeCategory: category.trimmed,
            tool: clean(tools),
            recipeIngredient: clean(ingredients),
            recipeInstructions: clean(instructions),
            nutrition: nutrition.filter { !$0.value.trimmed.isEmpty }
        )
    }

    // Recipe times use ISO 8601 durations, e.g. "PT01H30M00S".
    private static func minutes(fromISO8601 string: String?) -> Int {
        let duration = DurationComponents.fromPTString(string ?? "")
        return duration.hourComponent * 60 + duration.minuteComponent
    }

    private static func iso8601(minutes: Int) -> String {
        String(format: "PT%02dH%02dM00S", minutes / 60, minutes % 60)
    }
}


private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}


/// What happens to the recipe photo when saving.
enum PhotoChange: Equatable {
    case unchanged
    case new(UIImage)
    case removed
}


// MARK: - Editor

/// Sheet for creating or editing a recipe. Calls `onSave` with the saved recipe
/// (so the presenting screen can show it) and `onDelete` after a deletion.
struct RecipeEditorView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(LibraryModel.self) private var library
    @Environment(\.dismiss) private var dismiss

    /// The draft as it was when the sheet opened; used to detect unsaved changes.
    private let original: RecipeDraft
    private let isEditing: Bool
    @State private var draft: RecipeDraft
    @State private var location: RecipeOrigin
    @State private var isSaving = false
    @State private var alert: (any UserAlert)?
    @State private var showDiscardConfirmation = false
    @State private var showDeleteConfirmation = false
    @State private var showKeywordPicker = false
    @State private var photo: PhotoChange = .unchanged
    /// The recipe's current photo (when editing), shown until it is replaced.
    @State private var existingPhoto: UIImage?
    @State private var showCamera = false
    @State private var showPhotoNotSupported = false
    /// Set when the server's import already created the recipe on Nextcloud.
    @State private var importedToServer = false

    private let onSave: (Recipe) -> Void
    private let onDelete: () -> Void

    /// Create a new recipe, optionally starting in `category`.
    init(category: String = "", onSave: @escaping (Recipe) -> Void) {
        let draft = RecipeDraft(category: category)
        original = draft
        isEditing = false
        _draft = State(initialValue: draft)
        _location = State(initialValue: UserSettings.shared.isLoggedIn ? .nextcloud : .local)
        self.onSave = onSave
        self.onDelete = {}
    }

    /// Edit an existing recipe. It stays where it is stored (`origin`).
    init(editing detail: RecipeDetail, origin: RecipeOrigin, onSave: @escaping (Recipe) -> Void, onDelete: @escaping () -> Void) {
        let draft = RecipeDraft(detail)
        original = draft
        isEditing = true
        _draft = State(initialValue: draft)
        _location = State(initialValue: origin)
        self.onSave = onSave
        self.onDelete = onDelete
    }

    private var hasChanges: Bool { draft != original || photo != .unchanged }

    var body: some View {
        NavigationStack {
            Form {
                if !isEditing {
                    EditorImportSection(draft: $draft, importedToServer: $importedToServer, alert: $alert)
                }

                RecipePhotoSection(
                    photo: $photo,
                    existingPhoto: existingPhoto,
                    imageURL: draft.imageURL,
                    savesToNextcloud: location == .nextcloud,
                    takePhoto: { showCamera = true }
                )

                Section {
                    TextField("Recipe Name", text: $draft.name)
                        .font(.headline)
                    TextField("Description", text: $draft.description, axis: .vertical)
                        .lineLimit(2...6)
                } footer: {
                    if isDuplicateName {
                        Text("A recipe with this name already exists. Please choose a different name.")
                            .foregroundStyle(.red)
                    }
                }

                RecipeDetailsSection(
                    draft: $draft,
                    location: $location,
                    canChooseLocation: !isEditing && !importedToServer,
                    isNew: !isEditing,
                    editKeywords: { showKeywordPicker = true }
                )
                RecipeTimesSection(draft: $draft)

                EditableLinesSection(
                    title: "Ingredients",
                    lines: $draft.ingredients,
                    addPrompt: "Add ingredient"
                )
                EditableLinesSection(
                    title: "Instructions",
                    lines: $draft.instructions,
                    addPrompt: "Add step",
                    isNumbered: true
                )
                EditableLinesSection(
                    title: "Tools",
                    lines: $draft.tools,
                    addPrompt: "Add tool"
                )

                RecipeNutritionFormSection(nutrition: $draft.nutrition)

                if isEditing {
                    Section {
                        Button("Delete Recipe", role: .destructive) {
                            showDeleteConfirmation = true
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(isEditing ? "Edit Recipe" : "New Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if hasChanges { showDiscardConfirmation = true } else { dismiss() }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") { Task { await saveOrWarn() } }
                            .disabled(!canSave || (isEditing && !hasChanges))
                    }
                }
            }
            .confirmationDialog(
                isEditing ? "Discard your changes?" : "Discard this recipe?",
                isPresented: $showDiscardConfirmation,
                titleVisibility: .visible
            ) {
                Button(isEditing ? "Discard Changes" : "Discard Recipe", role: .destructive) { dismiss() }
            }
            .alert("Photo upload not supported yet", isPresented: $showPhotoNotSupported) {
                Button("Save Without Photo") { Task { await save() } }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("The Nextcloud Cookbook API does not support uploading photos yet. The recipe will be saved to Nextcloud without the new photo.")
            }
            .confirmationDialog("Delete this recipe?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete Recipe", role: .destructive) { Task { await delete() } }
            } message: {
                Text(location == .local
                     ? "The recipe will be deleted from this device."
                     : "The recipe will be deleted from your Nextcloud cookbooks.")
            }
            .alert(
                alert?.localizedTitle ?? "",
                isPresented: Binding(get: { alert != nil }, set: { if !$0 { alert = nil } }),
                presenting: alert
            ) { _ in
                Button("Ok", role: .cancel) {}
            } message: { alert in
                Text(alert.localizedDescription)
            }
            // Attached to the form, not to a Section: modifiers on a Section apply
            // to each of its rows, and several competing sheet presentations
            // dismissed the editor on iPad.
            .fullScreenCover(isPresented: $showCamera) {
                CameraView { photo = .new($0) }
                    .ignoresSafeArea()
            }
            .sheet(isPresented: $showKeywordPicker) {
                KeywordPickerView(title: String(localized: "Keywords"), searchSuggestions: appState.allKeywords, selection: $draft.keywords)
            }
            .interactiveDismissDisabled(hasChanges)
            .presentationSizing(.page) // full-size sheet on iPad; a long form needs the room
            .disabled(isSaving)
            .task {
                if isEditing, let id = draft.id {
                    existingPhoto = await appState.getImage(id: id, size: .FULL, fetchMode: .preferLocal)
                }
                if appState.allKeywords.isEmpty {
                    appState.allKeywords = await appState.getKeywords(fetchMode: .preferServer)
                        .sorted { $0.recipe_count > $1.recipe_count }
                }
            }
        }
    }

    // MARK: Validation

    private var isDuplicateName: Bool {
        let name = draft.name.trimmed
        guard !name.isEmpty else { return false }
        let known = Array(appState.recipes.values.joined()) + library.allRecipes
        return known.contains { recipe in
            recipe.name.compare(name, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
                && recipe.id != draft.id
        }
    }

    private var canSave: Bool {
        !draft.name.trimmed.isEmpty && !isDuplicateName
    }

    // MARK: Saving

    /// Photos can't be uploaded to Nextcloud yet; warn before saving without it.
    private func saveOrWarn() async {
        if location == .nextcloud, case .new = photo {
            showPhotoNotSupported = true
        } else {
            await save()
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        var detail = draft.toRecipeDetail()

        switch location {
        case .local:
            let (saved, error) = await appState.saveLocalRecipe(recipeDetail: detail)
            if let error { alert = error; return }
            guard let saved, let id = saved.id else { return }
            switch photo {
            case .new(let image): await appState.setLocalRecipePhoto(image, recipeId: id)
            case .removed: await appState.setLocalRecipePhoto(nil, recipeId: id)
            case .unchanged: break
            }
            finish(Recipe(
                id: id, externalSourceId: nil,
                name: saved.name, keywords: saved.keywords,
                dateCreated: nil, dateModified: nil, imageUrl: nil, imagePlaceholderUrl: nil
            ))

        case .nextcloud:
            // A server import already created the recipe; update it instead of
            // creating a second copy.
            // The Cookbook API can't receive photos yet (the user confirmed saving
            // without it); removing the photo is supported.
            if photo == .removed { detail.image = "" }

            let createNew = detail.externalSourceId == nil
            let (recipeId, error) = await appState.uploadRecipe(recipeDetail: detail, createNew: createNew)
            if let error { alert = error; return }
            guard let recipeId else { return }
            if photo == .removed { await appState.invalidateImages(for: recipeId) }

            let category = AppState.categoryKey(for: detail.recipeCategory, origin: .nextcloud)
            let previousCategory = AppState.categoryKey(for: original.category.trimmed, origin: .nextcloud)
            await appState.getCategories()
            await appState.getCategory(named: category, fetchMode: .preferServer)
            if isEditing && previousCategory != category {
                // The recipe moved; refresh the cookbook it left as well
                await appState.getCategory(named: previousCategory, fetchMode: .preferServer)
            }
            _ = await appState.getRecipe(id: recipeId, fetchMode: .onlyServer, save: true)

            let recipe: Recipe
            if let listed = appState.recipes[category]?.first(where: { $0.id == recipeId }) {
                recipe = listed
            } else {
                recipe = Recipe(
                    id: recipeId, externalSourceId: await appState.externalSourceId(forRecipe: recipeId),
                    name: detail.name, keywords: detail.keywords,
                    dateCreated: nil, dateModified: nil, imageUrl: nil, imagePlaceholderUrl: nil
                )
            }
            finish(recipe)
        }
    }

    private func finish(_ recipe: Recipe) {
        onSave(recipe)
        dismiss()
    }

    // MARK: Deleting

    private func delete() async {
        guard let id = draft.id else { return }
        isSaving = true
        defer { isSaving = false }
        if let error = await appState.deleteRecipe(withId: id) {
            alert = error
            return
        }
        if location == .nextcloud {
            await appState.getCategories()
            let category = AppState.categoryKey(for: original.category.trimmed, origin: .nextcloud)
            await appState.getCategory(named: category, fetchMode: .preferServer)
        }
        dismiss()
        onDelete()
    }
}


// MARK: - Import

private struct EditorImportSection: View {
    @EnvironmentObject private var appState: AppState
    @Binding var draft: RecipeDraft
    @Binding var importedToServer: Bool
    @Binding var alert: (any UserAlert)?
    @State private var urlString = ""
    @State private var isImporting = false

    var body: some View {
        Section {
            HStack {
                TextField("Recipe website", text: $urlString)
                    .keyboardType(.URL)
                    .textContentType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.go)
                    .onSubmit { Task { await importRecipe() } }

                if isImporting {
                    ProgressView()
                } else {
                    Button("Import") { Task { await importRecipe() } }
                        .disabled(urlString.trimmed.isEmpty)
                }
            }
        } header: {
            Text("Import from Website")
        } footer: {
            if importedToServer {
                Text("The recipe was imported into your Nextcloud cookbooks. Review it and tap Save.")
            } else {
                Text("Paste a link and the form is filled in for you. Not every website is supported.")
            }
        }
    }

    private func importRecipe() async {
        let url = urlString.trimmed
        guard !url.isEmpty, !isImporting else { return }
        isImporting = true
        defer { isImporting = false }

        // The Nextcloud Cookbook server imports (and stores) the recipe itself.
        if UserSettings.shared.isLoggedIn {
            let (detail, _) = await appState.importRecipe(url: url)
            if let detail {
                apply(detail)
                importedToServer = detail.externalSourceId != nil
                return
            }
        }
        // Otherwise read the website on the device.
        let (detail, error) = await WebRecipeImport.importRecipe(from: url)
        if let detail {
            var detail = detail
            detail.id = nil
            detail.externalSourceId = nil
            apply(detail)
        } else if let error {
            alert = error
        }
    }

    private func apply(_ detail: RecipeDetail) {
        let category = draft.category
        draft = RecipeDraft(detail)
        if draft.category.isEmpty { draft.category = category }
        if draft.sourceURL.isEmpty { draft.sourceURL = urlString.trimmed }
    }
}


// MARK: - Details

private struct RecipeDetailsSection: View {
    @EnvironmentObject private var appState: AppState
    @Binding var draft: RecipeDraft
    @Binding var location: RecipeOrigin
    /// Only new recipes can choose where they are saved.
    let canChooseLocation: Bool
    let isNew: Bool
    let editKeywords: () -> Void

    private var existingCategories: [String] {
        appState.categories.map(\.name).filter { $0 != "*" }
    }

    var body: some View {
        Section {
            if UserSettings.shared.isLoggedIn && canChooseLocation {
                Picker("Save to", selection: $location) {
                    Text("Nextcloud").tag(RecipeOrigin.nextcloud)
                    Text("This Device").tag(RecipeOrigin.local)
                }
            }

            HStack {
                TextField("Category", text: $draft.category)
                if !existingCategories.isEmpty {
                    Menu {
                        ForEach(existingCategories, id: \.self) { name in
                            Button(name) { draft.category = name }
                        }
                    } label: {
                        Image(systemName: "chevron.up.chevron.down")
                    }
                    .accessibilityLabel("Choose a category")
                }
            }

            Stepper(value: $draft.servings, in: 1...99) {
                LabeledContent("Servings", value: draft.servings, format: .number)
            }

            Button(action: editKeywords) {
                LabeledContent("Keywords") {
                    Text(draft.keywords.isEmpty ? String(localized: "None") : draft.keywords.joined(separator: ", "))
                        .lineLimit(1)
                }
            }
            .tint(.primary)
        } header: {
            Text("Details")
        } footer: {
            if isNew && !UserSettings.shared.isLoggedIn {
                Text("The recipe is saved on this device. Sign in to Nextcloud in Settings to sync recipes.")
            }
        }
    }
}


// MARK: - Photo

private struct RecipePhotoSection: View {
    @Binding var photo: PhotoChange
    let existingPhoto: UIImage?
    /// Image URL found by an import; previewed until a photo is chosen.
    let imageURL: String
    let savesToNextcloud: Bool
    let takePhoto: () -> Void
    @State private var pickerItem: PhotosPickerItem?

    private var importedImageURL: URL? {
        imageURL.hasPrefix("http") ? URL(string: imageURL) : nil
    }

    private var hasPhoto: Bool {
        switch photo {
        case .new: true
        case .removed: false
        case .unchanged: existingPhoto != nil || importedImageURL != nil
        }
    }

    var body: some View {
        Section {
            preview

            PhotosPicker(selection: $pickerItem, matching: .images) {
                Label(hasPhoto ? "Choose Another Photo" : "Choose from Photos", systemImage: "photo.on.rectangle")
            }
            .onChange(of: pickerItem) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        photo = .new(image)
                    }
                    pickerItem = nil
                }
            }

            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Take Photo", systemImage: "camera", action: takePhoto)
            }

            if hasPhoto {
                Button("Remove Photo", systemImage: "trash", role: .destructive) {
                    photo = .removed
                }
            }
        } header: {
            Text("Photo")
        } footer: {
            if savesToNextcloud {
                Label("Uploading photos to Nextcloud is not supported yet. Photos are only saved for recipes stored on this device.", systemImage: "exclamationmark.triangle")
            }
        }
    }

    @ViewBuilder
    private var preview: some View {
        switch photo {
        case .new(let image):
            PhotoPreview(image: Image(uiImage: image))
        case .removed:
            EmptyView()
        case .unchanged:
            if let existingPhoto {
                PhotoPreview(image: Image(uiImage: existingPhoto))
            } else if let importedImageURL {
                AsyncImage(url: importedImageURL) { image in
                    PhotoPreview(image: image)
                } placeholder: {
                    ProgressView().frame(maxWidth: .infinity, minHeight: 200)
                }
            }
        }
    }
}

private struct PhotoPreview: View {
    let image: Image

    var body: some View {
        Color.clear
            .frame(height: 200)
            .overlay { image.resizable().scaledToFill() }
            .clipped()
            .listRowInsets(EdgeInsets())
    }
}

/// The system camera, for taking a recipe photo.
private struct CameraView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        init(_ parent: CameraView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onCapture(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}


// MARK: - Times

private struct RecipeTimesSection: View {
    @Binding var draft: RecipeDraft
    /// Total time follows preparation + cooking until the user sets it directly.
    @State private var totalIsManual = false
    @State private var previousSum: Int

    init(draft: Binding<RecipeDraft>) {
        _draft = draft
        _previousSum = State(initialValue: draft.wrappedValue.prepMinutes + draft.wrappedValue.cookMinutes)
    }

    var body: some View {
        Section("Time") {
            DurationRow(title: "Preparation", minutes: Binding(
                get: { draft.prepMinutes },
                set: { draft.prepMinutes = $0; updateTotal() }
            ))
            DurationRow(title: "Cooking", minutes: Binding(
                get: { draft.cookMinutes },
                set: { draft.cookMinutes = $0; updateTotal() }
            ))
            DurationRow(title: "Total time", minutes: Binding(
                get: { draft.totalMinutes },
                set: { draft.totalMinutes = $0; totalIsManual = true }
            ))
        }
    }

    private func updateTotal() {
        // A total that differs from prep + cook was set by hand (or imported); keep it.
        let wasAutomatic = !totalIsManual
            && (draft.totalMinutes == 0 || draft.totalMinutes == previousSum)
        previousSum = draft.prepMinutes + draft.cookMinutes
        if wasAutomatic { draft.totalMinutes = previousSum }
    }
}

private struct DurationRow: View {
    let title: LocalizedStringKey
    @Binding var minutes: Int

    private var hours: Binding<Int> {
        Binding(get: { minutes / 60 }, set: { minutes = $0 * 60 + minutes % 60 })
    }
    private var minutePart: Binding<Int> {
        Binding(get: { minutes % 60 }, set: { minutes = (minutes / 60) * 60 + $0 })
    }

    var body: some View {
        LabeledContent(title) {
            HStack(spacing: 0) {
                Picker("Hours", selection: hours) {
                    ForEach(0...max(48, minutes / 60), id: \.self) { Text("\($0) h").tag($0) }
                }
                Picker("Minutes", selection: minutePart) {
                    ForEach(0..<60, id: \.self) { Text("\($0) min").tag($0) }
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
        }
    }
}


// MARK: - Lists

/// Inline-editable list: edit rows in place, swipe to delete, drag to reorder,
/// and type into the last row + Return to add the next item quickly.
private struct EditableLinesSection: View {
    let title: LocalizedStringKey
    @Binding var lines: [RecipeDraft.Line]
    let addPrompt: LocalizedStringKey
    var isNumbered = false

    @State private var newText = ""
    @FocusState private var isAddFieldFocused: Bool

    var body: some View {
        Section {
            ForEach($lines) { $line in
                HStack(alignment: .firstTextBaseline) {
                    if isNumbered, let index = lines.firstIndex(where: { $0.id == line.id }) {
                        Text("\(index + 1).")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    TextField(addPrompt, text: $line.text, axis: .vertical)
                }
            }
            .onDelete { lines.remove(atOffsets: $0) }
            .onMove { lines.move(fromOffsets: $0, toOffset: $1) }

            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(.tint)
                TextField(addPrompt, text: $newText)
                    .focused($isAddFieldFocused)
                    .submitLabel(.next)
                    .onSubmit(add)
            }
        } header: {
            Text(title)
        }
    }

    /// Adds the typed text (one item per line when several lines were pasted)
    /// and keeps the keyboard up for the next item.
    private func add() {
        let items = newText
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        guard !items.isEmpty else { return }
        withAnimation {
            lines.append(contentsOf: items.map { RecipeDraft.Line(text: $0) })
        }
        newText = ""
        isAddFieldFocused = true
    }
}


// MARK: - Nutrition

private struct RecipeNutritionFormSection: View {
    @Binding var nutrition: [String: String]

    var body: some View {
        Section {
            DisclosureGroup("Nutrition (optional)") {
                ForEach(Nutrition.allCases, id: \.dictKey) { item in
                    LabeledContent(item.localizedDescription) {
                        TextField(item.localizedDescription, text: Binding(
                            get: { nutrition[item.dictKey] ?? "" },
                            set: { nutrition[item.dictKey] = $0 }
                        ))
                        .multilineTextAlignment(.trailing)
                    }
                }
            }
        }
    }
}
