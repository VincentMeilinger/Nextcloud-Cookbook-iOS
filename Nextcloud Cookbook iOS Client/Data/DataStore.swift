//
//  DataStore.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 15.09.23.
//

import Foundation
import SwiftData
import UIKit

// Single shared container, created once, used by the actor and the SwiftUI environment.
let sharedModelContainer: ModelContainer = {
    let schema = Schema([
        StoredRecipeIdentity.self,
        StoredRecipeDetail.self,
        StoredRecipe.self,
        StoredCategory.self,
        StoredKeyword.self,
        StoredRecipeImage.self,
        StoredGroceryList.self,
    ])
    // SwiftData does not create Application Support itself on first launch; without it
    // Core Data logs "Failed to create file" errors and has to recover.
    if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
        try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
    }
    // Named store ("Cookbook.store"). Pre-release builds used "default.store" with an
    // incompatible schema (string recipe ids); that file is left untouched rather than
    // migrated. Released versions up to 1.10.x kept their data in files instead
    // (see `migrateLegacyFiles()`).
    let configuration = ModelConfiguration("Cookbook", schema: schema)
    do {
        return try ModelContainer(for: schema, configurations: configuration)
    } catch {
        fatalError("Failed to create SwiftData ModelContainer: \(error)")
    }
}()

/// Shared background persistence actor, created once at module scope.
let sharedDataStore = DataStore(modelContainer: sharedModelContainer)

/// Background persistence actor. All methods run off the main thread via `@ModelActor`.
@ModelActor
actor DataStore {

    // MARK: - Recipe ids

    private static let nextRecipeIdKey = "nextRecipeId"

    /// Returns the app-internal id for each Nextcloud recipe id, registering ids for
    /// recipes seen for the first time.
    func recipeIds(forExternalIds externalIds: [String]) -> [String: Int] {
        var ids: [String: Int] = [:]
        for identity in fetchAll(StoredRecipeIdentity.self, predicate: #Predicate { $0.externalSourceId != nil }) {
            if let externalId = identity.externalSourceId { ids[externalId] = identity.id }
        }
        var inserted = false
        for externalId in externalIds where ids[externalId] == nil {
            ids[externalId] = allocateRecipeId(externalSourceId: externalId)
            inserted = true
        }
        if inserted { save() }
        let requested = Set(externalIds)
        return ids.filter { requested.contains($0.key) }
    }

    /// Registers a new local recipe and returns its id.
    func newLocalRecipeId() -> Int {
        let id = allocateRecipeId(externalSourceId: nil)
        save()
        return id
    }

    /// The Nextcloud id of a recipe, or `nil` for local (or unknown) recipes.
    func externalSourceId(forRecipe id: Int) -> String? {
        fetchOne(StoredRecipeIdentity.self, predicate: #Predicate { $0.id == id })?.externalSourceId
    }

    /// Inserts a new identity (without saving). Ids come from a counter that only
    /// grows, so an id is never handed out twice, even after its recipe was deleted.
    private func allocateRecipeId(externalSourceId: String?) -> Int {
        var highest = FetchDescriptor<StoredRecipeIdentity>(sortBy: [SortDescriptor(\.id, order: .reverse)])
        highest.fetchLimit = 1
        let highestId = (try? modelContext.fetch(highest))?.first?.id ?? 0
        let defaults = UserDefaults.standard
        let id = max(defaults.integer(forKey: Self.nextRecipeIdKey), highestId + 1, 1)
        defaults.set(id + 1, forKey: Self.nextRecipeIdKey)
        modelContext.insert(StoredRecipeIdentity(id: id, externalSourceId: externalSourceId))
        return id
    }

    // MARK: - RecipeDetail

    /// Stores a recipe detail. Its `id` must be set.
    func saveRecipeDetail(_ detail: RecipeDetail) {
        guard let recipeId = detail.id else {
            assertionFailure("Recipe detail without an id cannot be stored.")
            return
        }
        if let existing = fetchOne(StoredRecipeDetail.self, predicate: #Predicate { $0.recipeId == recipeId }) {
            existing.update(from: detail)
        } else {
            modelContext.insert(StoredRecipeDetail(recipeId: recipeId, from: detail))
        }
        save()
    }

    func loadRecipeDetail(id: Int) -> RecipeDetail? {
        fetchOne(StoredRecipeDetail.self, predicate: #Predicate { $0.recipeId == id })?.toRecipeDetail()
    }

    /// Deletes everything stored for a recipe: its detail, list entry, images and id.
    func deleteRecipe(id: Int) {
        fetchAll(StoredRecipeDetail.self, predicate: #Predicate { $0.recipeId == id })
            .forEach { modelContext.delete($0) }
        fetchAll(StoredRecipe.self, predicate: #Predicate { $0.recipeId == id })
            .forEach { modelContext.delete($0) }
        fetchAll(StoredRecipeImage.self, predicate: #Predicate { $0.recipeId == id })
            .forEach { modelContext.delete($0) }
        fetchAll(StoredRecipeIdentity.self, predicate: #Predicate { $0.id == id })
            .forEach { modelContext.delete($0) }
        save()
    }

    func recipeDetailExists(recipeId: Int) -> Bool {
        fetchOne(StoredRecipeDetail.self, predicate: #Predicate { $0.recipeId == recipeId }) != nil
    }

    // MARK: - Recipes (category lists)

    /// Replaces only the Nextcloud recipe list for a category, preserving local recipes.
    func saveRecipes(_ recipes: [Recipe], forCategory category: String) {
        fetchAll(StoredRecipe.self, predicate: #Predicate { $0.categoryName == category && $0.externalSourceId != nil })
            .forEach { modelContext.delete($0) }
        for recipe in recipes {
            modelContext.insert(StoredRecipe(from: recipe, categoryName: category))
        }
        save()
    }

    /// Returns the number of local recipes stored for the given category.
    func countLocalRecipes(forCategory category: String) -> Int {
        (try? modelContext.fetchCount(FetchDescriptor<StoredRecipe>(
            predicate: #Predicate { $0.categoryName == category && $0.externalSourceId == nil }
        ))) ?? 0
    }

    /// Returns the local recipe summaries stored for the given category.
    func loadLocalRecipes(forCategory category: String) -> [Recipe] {
        fetchAll(StoredRecipe.self, predicate: #Predicate { $0.categoryName == category && $0.externalSourceId == nil })
            .map { $0.toRecipe() }
    }

    func loadRecipes(forCategory category: String) -> [Recipe]? {
        let stored = fetchAll(StoredRecipe.self, predicate: #Predicate { $0.categoryName == category })
        return stored.isEmpty ? nil : stored.map { $0.toRecipe() }
    }

    /// Upserts a single local recipe summary (does not touch Nextcloud entries).
    func saveLocalRecipeSummary(_ recipe: Recipe, forCategory category: String) {
        let recipeId = recipe.id
        if let existing = fetchOne(StoredRecipe.self, predicate: #Predicate { $0.recipeId == recipeId }) {
            existing.name = recipe.name
            existing.keywords = recipe.keywords
            existing.categoryName = category
        } else {
            modelContext.insert(StoredRecipe(from: recipe, categoryName: category))
        }
        save()
    }

    /// Returns all local recipe summaries grouped with their category name.
    func loadAllLocalStoredRecipes() -> [(recipe: Recipe, category: String)] {
        fetchAll(StoredRecipe.self, predicate: #Predicate { $0.externalSourceId == nil })
            .map { ($0.toRecipe(), $0.categoryName) }
    }

    // MARK: - Categories

    func saveCategories(_ categories: [Category]) {
        fetchAll(StoredCategory.self).forEach { modelContext.delete($0) }
        categories.forEach { modelContext.insert(StoredCategory(from: $0)) }
        save()
    }

    func loadCategories() -> [Category]? {
        let stored = fetchAll(StoredCategory.self)
        return stored.isEmpty ? nil : stored.map { $0.toCategory() }
    }

    // MARK: - Keywords

    func saveKeywords(_ keywords: [RecipeKeyword]) {
        fetchAll(StoredKeyword.self).forEach { modelContext.delete($0) }
        keywords.forEach { modelContext.insert(StoredKeyword(from: $0)) }
        save()
    }

    func loadKeywords() -> [RecipeKeyword]? {
        let stored = fetchAll(StoredKeyword.self)
        return stored.isEmpty ? nil : stored.map { $0.toKeyword() }
    }

    // MARK: - Images

    func saveImage(_ data: Data, forRecipe id: Int, size: RecipeImage.RecipeImageSize) {
        let recipeId = id
        let sizeStr = size.rawValue
        if let existing = fetchOne(StoredRecipeImage.self, predicate: #Predicate { $0.recipeId == recipeId && $0.size == sizeStr }) {
            existing.imageData = data
        } else {
            modelContext.insert(StoredRecipeImage(recipeId: id, size: size.rawValue, imageData: data))
        }
        save()
    }

    func deleteImages(forRecipe id: Int) {
        let recipeId = id
        fetchAll(StoredRecipeImage.self, predicate: #Predicate { $0.recipeId == recipeId })
            .forEach { modelContext.delete($0) }
        save()
    }

    func loadImage(forRecipe id: Int, size: RecipeImage.RecipeImageSize) -> Data? {
        let recipeId = id
        let sizeStr = size.rawValue
        return fetchOne(StoredRecipeImage.self, predicate: #Predicate { $0.recipeId == recipeId && $0.size == sizeStr })?.imageData
    }

    // MARK: - Grocery List

    func saveGroceryList(_ dict: [String: GroceryRecipe]) {
        guard let data = try? JSONEncoder().encode(dict) else { return }
        if let existing = fetchAll(StoredGroceryList.self).first {
            existing.data = data
        } else {
            modelContext.insert(StoredGroceryList(data: data))
        }
        save()
    }

    func loadGroceryList() -> [String: GroceryRecipe]? {
        guard let data = fetchAll(StoredGroceryList.self).first?.data else { return nil }
        return try? JSONDecoder().decode([String: GroceryRecipe].self, from: data)
    }

    // MARK: - Clearing

    /// Deletes all recipe data, including local recipes. The grocery list is kept.
    func clearAll() {
        try? modelContext.delete(model: StoredRecipeIdentity.self)
        try? modelContext.delete(model: StoredRecipeDetail.self)
        try? modelContext.delete(model: StoredRecipe.self)
        try? modelContext.delete(model: StoredCategory.self)
        try? modelContext.delete(model: StoredKeyword.self)
        try? modelContext.delete(model: StoredRecipeImage.self)
        save()
    }

    /// Deletes only data cached from Nextcloud. Local recipes (and their images)
    /// and the grocery list are kept.
    func clearNextcloudData() {
        let nextcloudIdentities = fetchAll(StoredRecipeIdentity.self, predicate: #Predicate { $0.externalSourceId != nil })
        let nextcloudIds = nextcloudIdentities.map(\.id)
        fetchAll(StoredRecipeDetail.self, predicate: #Predicate { $0.externalSourceId != nil })
            .forEach { modelContext.delete($0) }
        fetchAll(StoredRecipe.self, predicate: #Predicate { $0.externalSourceId != nil })
            .forEach { modelContext.delete($0) }
        fetchAll(StoredRecipeImage.self, predicate: #Predicate { nextcloudIds.contains($0.recipeId) })
            .forEach { modelContext.delete($0) }
        nextcloudIdentities.forEach { modelContext.delete($0) }
        try? modelContext.delete(model: StoredCategory.self)
        try? modelContext.delete(model: StoredKeyword.self)
        save()
    }

    // MARK: - Legacy file store migration

    /// Versions up to 1.10.x stored data as files in the Documents directory.
    /// Moves the grocery list into SwiftData and deletes the old cache files
    /// (everything else in them was a server cache and gets re-downloaded).
    func migrateLegacyFiles() {
        let fm = FileManager.default
        guard let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first,
              let files = try? fm.contentsOfDirectory(atPath: docs.path())
        else { return }

        let groceryFile = docs.appending(path: "grocery_list.data")
        if fm.fileExists(atPath: groceryFile.path()) {
            guard let data = try? Data(contentsOf: groceryFile),
                  let dict = try? JSONDecoder().decode([String: GroceryRecipe].self, from: data)
            else {
                // Keep the file rather than destroy data we could not read.
                print("Legacy grocery list could not be decoded; leaving it in place.")
                return
            }
            if fetchAll(StoredGroceryList.self).isEmpty {
                saveGroceryList(rekeyedLegacyGroceryList(dict))
            }
            try? fm.removeItem(at: groceryFile)
        }

        for name in files where Self.isLegacyCacheFile(name) {
            try? fm.removeItem(at: docs.appending(path: name))
        }
    }

    /// Grocery lists up to 1.10.x are keyed by Nextcloud recipe id; they are keyed by
    /// app-internal id now. Other keys (the manually added items) stay as they are.
    private func rekeyedLegacyGroceryList(_ dict: [String: GroceryRecipe]) -> [String: GroceryRecipe] {
        let serverKeys = dict.keys.filter { Int($0) != nil }
        let ids = recipeIds(forExternalIds: serverKeys)
        var rekeyed: [String: GroceryRecipe] = [:]
        for (key, recipe) in dict {
            rekeyed[ids[key].map(String.init) ?? key] = recipe
        }
        return rekeyed
    }

    private static func isLegacyCacheFile(_ name: String) -> Bool {
        name == "categories.data"
            || name == "keywords.data"
            || (name.hasPrefix("category_") && name.hasSuffix(".data"))
            || (name.hasPrefix("recipe") && name.hasSuffix(".data"))
            || (name.hasPrefix("image") && (name.hasSuffix("_thumb") || name.hasSuffix("_full")))
    }

    // MARK: - Private helpers

    private func fetchAll<T: PersistentModel>(_ type: T.Type, predicate: Predicate<T>? = nil) -> [T] {
        var descriptor = FetchDescriptor<T>()
        descriptor.predicate = predicate
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func fetchOne<T: PersistentModel>(_ type: T.Type, predicate: Predicate<T>) -> T? {
        var descriptor = FetchDescriptor<T>(predicate: predicate)
        descriptor.fetchLimit = 1
        return (try? modelContext.fetch(descriptor))?.first
    }

    private func save() {
        do {
            try modelContext.save()
        } catch {
            print("DataStore save error: \(error)")
        }
    }
}
