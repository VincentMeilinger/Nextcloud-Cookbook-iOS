//
//  MainViewModel.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 06.09.23.
//

import Foundation
import SwiftUI
import UIKit
import NextcloudCookbookKit


@MainActor class AppState: ObservableObject {
    @Published var categories: [Category] = []
    @Published var recipes: [String: [Recipe]] = [:]
    @Published var recipeDetails: [Int: RecipeDetail] = [:]
    @Published var timers: [String: RecipeTimer] = [:]
    var recipeImages: [Int: [String: UIImage]] = [:]
    var imagesNeedUpdate: [Int: [String: Bool]] = [:]
    var allKeywords: [RecipeKeyword] = []

    /// Recipe counts per category as reported by the server (excludes local recipes).
    private var serverCategoryCounts: [String: Int] = [:]

    private let dataStore = sharedDataStore

    /// Category name used for recipes without a category.
    /// The server lists them under "*"; local ones are grouped under "Local".
    static func categoryKey(for category: String, origin: RecipeOrigin) -> String {
        guard category.isEmpty else { return category }
        return origin == .local ? String(localized: "Local") : "*"
    }

    enum FetchMode {
        case preferLocal, preferServer, onlyLocal, onlyServer
    }

    // MARK: - Cookbook API client

    /// Connection to the signed-in server, shared by all requests. Connecting asks the
    /// server for its API version, so it happens once per server and credentials.
    private var cookbookClientTask: (key: String, task: Task<any CookbookAPIClient, Error>)?

    /// Returns a client matching the server's Cookbook API version.
    private func cookbookClient() async throws -> any CookbookAPIClient {
        let settings = UserSettings.shared
        let urlString = settings.serverProtocol + settings.serverAddress
        let credentials = settings.authString
        let key = urlString + "\n" + credentials

        let task: Task<any CookbookAPIClient, Error>
        if let cached = cookbookClientTask, cached.key == key {
            task = cached.task
        } else {
            guard let serverURL = URL(string: urlString) else { throw NCKError.invalidURL }
            task = Task { try await CookbookAPI.connect(serverURL: serverURL, credentials: credentials) }
            cookbookClientTask = (key, task)
        }
        do {
            return try await task.value
        } catch {
            // Don't keep a failed connection (e.g. while offline); the next request retries.
            if cookbookClientTask?.task == task { cookbookClientTask = nil }
            throw error
        }
    }

    /// Converts server recipes to app recipes, registering internal ids for new ones.
    private func appRecipes(from serverRecipes: [NCKRecipe]) async -> [Recipe] {
        let ids = await dataStore.recipeIds(forExternalIds: serverRecipes.map(\.id))
        return serverRecipes.compactMap { recipe in ids[recipe.id].map { recipe.toRecipe(id: $0) } }
    }

    // MARK: - Categories

    func getCategories() async {
        do {
            let categories = try await cookbookClient().getCategories().map { $0.toCategory() }
            await dataStore.saveCategories(categories)
            applyServerCategories(categories)
        } catch {
            print("Server fetch failed, loading categories from store: \(error)")
            if let categories = await dataStore.loadCategories() {
                applyServerCategories(categories)
            }
        }

        // Merge categories and recipes from locally-stored recipes
        await mergeLocalRecipes()
        await recomputeCategoryCounts()
    }

    private func applyServerCategories(_ serverCategories: [Category]) {
        categories = serverCategories
        serverCategoryCounts = Dictionary(
            serverCategories.map { ($0.name, $0.recipe_count) },
            uniquingKeysWith: +
        )
    }

    /// Sets every category's recipe_count to the server count plus the number of
    /// local recipes, and drops categories that no longer contain any recipe.
    /// Called after any operation that may change the recipe set.
    private func recomputeCategoryCounts() async {
        var counts: [String: Int] = [:]
        for name in categories.map(\.name) {
            counts[name] = serverCategoryCounts[name, default: 0]
                + (await dataStore.countLocalRecipes(forCategory: name))
        }
        for i in categories.indices {
            if let count = counts[categories[i].name] {
                categories[i].recipe_count = count
            }
        }
        categories.removeAll { $0.recipe_count == 0 && serverCategoryCounts[$0.name] == nil }
    }

    /// Loads all local-origin recipes from DataStore and merges them into
    /// the in-memory categories and recipes dictionaries.
    private func mergeLocalRecipes() async {
        let localEntries = await dataStore.loadAllLocalStoredRecipes()
        for (recipe, category) in localEntries {
            if !categories.contains(where: { $0.name == category }) {
                categories.append(Category(name: category, recipe_count: 0))
            }
            let existingIds = Set(recipes[category]?.map(\.id) ?? [])
            if !existingIds.contains(recipe.id) {
                recipes[category, default: []].append(recipe)
            }
        }
    }

    // MARK: - Recipes per category

    func getCategory(named name: String, fetchMode: FetchMode) async {
        print("getCategory(\(name), fetchMode: \(fetchMode))")

        func getLocal() async -> Bool {
            if let recipes = await dataStore.loadRecipes(forCategory: name) {
                self.recipes[name] = recipes
                return true
            }
            return false
        }

        func getServer(store: Bool = false) async -> Bool {
            let categoryString = name == "*" ? "_" : name
            do {
                let serverRecipes = try await appRecipes(from: cookbookClient().getRecipes(inCategory: categoryString))
                if store { await dataStore.saveRecipes(serverRecipes, forCategory: name) }
                // The server only knows its own recipes; keep local ones in the list.
                let localRecipes = await dataStore.loadLocalRecipes(forCategory: name)
                self.recipes[name] = serverRecipes + localRecipes
                return true
            } catch { return false }
        }

        switch fetchMode {
        case .preferLocal:
            if await getLocal() { return }
            if await getServer(store: true) { return }
        case .preferServer:
            if await getServer(store: true) { return }
            if await getLocal() { return }
        case .onlyLocal:
            if await getLocal() { return }
        case .onlyServer:
            if await getServer() { return }
        }
    }

    func updateAllRecipeDetails() async {
        // Recipes changed on the server while this sync runs must count as
        // changed next time, so remember when the sync started.
        let syncStart = Date()
        for category in self.categories {
            await updateRecipeDetails(in: category.name)
        }
        UserSettings.shared.lastUpdate = syncStart
    }

    func updateRecipeDetails(in category: String) async {
        guard UserSettings.shared.storeRecipes else { return }
        guard let recipes = self.recipes[category] else { return }
        for recipe in recipes {
            // Local recipes are always up to date — no server to sync with
            guard recipe.origin == .nextcloud else { continue }
            guard await needsUpdate(recipe) else { continue }
            await updateRecipeDetail(id: recipe.id, withThumb: UserSettings.shared.storeThumb, withImage: UserSettings.shared.storeImages)
        }
    }

    // MARK: - All recipes

    func getRecipes() async -> [Recipe] {
        do {
            let serverRecipes = try await appRecipes(from: cookbookClient().getRecipes())
            let localRecipes = await dataStore.loadAllLocalStoredRecipes().map(\.recipe)
            return (serverRecipes + localRecipes).sorted { $0.name < $1.name }
        } catch {
            print("Server fetch failed, aggregating from local store: \(error)")
        }
        var allRecipes: [Recipe] = []
        for category in categories {
            if self.recipes[category.name] == nil {
                await getCategory(named: category.name, fetchMode: .preferLocal)
            }
            if let recipeArray = self.recipes[category.name] {
                allRecipes.append(contentsOf: recipeArray)
            }
        }
        return allRecipes.sorted { $0.name < $1.name }
    }

    // MARK: - Recipe detail

    func getRecipe(id: Int, fetchMode: FetchMode, save: Bool = false) async -> RecipeDetail? {
        // Local recipes live only in DataStore — never hit the server
        guard let externalId = await dataStore.externalSourceId(forRecipe: id) else {
            return await dataStore.loadRecipeDetail(id: id)
        }

        func getLocal() async -> RecipeDetail? {
            await dataStore.loadRecipeDetail(id: id)
        }

        func getServer() async -> RecipeDetail? {
            do {
                let detail = try await cookbookClient().getRecipe(id: externalId).toRecipeDetail(id: id)
                if save {
                    self.recipeDetails[id] = detail
                    await dataStore.saveRecipeDetail(detail)
                }
                return detail
            } catch { return nil }
        }

        switch fetchMode {
        case .preferLocal:
            if let recipe = await getLocal() { return recipe }
            if let recipe = await getServer() { return recipe }
        case .preferServer:
            if let recipe = await getServer() { return recipe }
            if let recipe = await getLocal() { return recipe }
        case .onlyLocal:
            if let recipe = await getLocal() { return recipe }
        case .onlyServer:
            if let recipe = await getServer() { return recipe }
        }
        return nil
    }

    func updateRecipeDetail(id: Int, withThumb: Bool, withImage: Bool) async {
        if let recipeDetail = await getRecipe(id: id, fetchMode: .onlyServer) {
            await dataStore.saveRecipeDetail(recipeDetail)
        }

        if withThumb {
            let thumbnail = await getImage(id: id, size: .THUMB, fetchMode: .onlyServer)
            if let thumbnail, let data = await encodeToPNG(thumbnail) {
                await dataStore.saveImage(data, forRecipe: id, size: .THUMB)
            }
        }

        if withImage {
            let image = await getImage(id: id, size: .FULL, fetchMode: .onlyServer)
            if let image, let data = await encodeToPNG(image) {
                await dataStore.saveImage(data, forRecipe: id, size: .FULL)
            }
        }
    }

    func recipeDetailExists(recipeId: Int) async -> Bool {
        await dataStore.recipeDetailExists(recipeId: recipeId)
    }

    /// The Nextcloud id of a recipe, or `nil` for local recipes.
    func externalSourceId(forRecipe id: Int) async -> String? {
        await dataStore.externalSourceId(forRecipe: id)
    }

    // MARK: - Images

    func getImage(id: Int, size: RecipeImage.RecipeImageSize, fetchMode: FetchMode) async -> UIImage? {
        // Local recipes have no server image — only check the local store
        guard let externalId = await dataStore.externalSourceId(forRecipe: id) else {
            return await imageFromStore(id: id, size: size)
        }

        func getLocal() async -> UIImage? {
            await imageFromStore(id: id, size: size)
        }

        func getServer() async -> UIImage? {
            do {
                let data = try await cookbookClient().getImage(recipeId: externalId, size: size.nckImageSize)
                return UIImage(data: data)
            } catch { return nil }
        }

        switch fetchMode {
        case .preferLocal:
            if let image = imageFromCache(id: id, size: size) { return image }
            if !imageUpdateNeeded(id: id, size: size) { return nil }
            if let image = await getLocal() {
                imageToCache(id: id, size: size, image: image)
                return image
            }
            if let image = await getServer() {
                await imageToStore(id: id, size: size, image: image)
                imageToCache(id: id, size: size, image: image)
                return image
            }
        case .preferServer:
            if let image = await getServer() {
                await imageToStore(id: id, size: size, image: image)
                imageToCache(id: id, size: size, image: image)
                return image
            }
            if let image = imageFromCache(id: id, size: size) { return image }
            if let image = await getLocal() {
                imageToCache(id: id, size: size, image: image)
                return image
            }
        case .onlyLocal:
            if let image = imageFromCache(id: id, size: size) { return image }
            if !imageUpdateNeeded(id: id, size: size) { return nil }
            if let image = await getLocal() {
                imageToCache(id: id, size: size, image: image)
                return image
            }
        case .onlyServer:
            if let image = imageFromCache(id: id, size: size) { return image }
            if let image = await getServer() {
                imageToCache(id: id, size: size, image: image)
                return image
            }
        }
        // Remember that neither the store nor the server has this image, so list
        // cells stop retrying. Single-source modes must not set this, or a failed
        // server-only fetch would hide an image that exists in the local store.
        if fetchMode == .preferLocal || fetchMode == .preferServer {
            imagesNeedUpdate[id, default: [:]][size.rawValue] = false
        }
        return nil
    }

    // MARK: - Keywords

    func getKeywords(fetchMode: FetchMode) async -> [RecipeKeyword] {
        func getLocal() async -> [RecipeKeyword]? {
            await dataStore.loadKeywords()
        }

        func getServer() async -> [RecipeKeyword]? {
            do {
                return try await cookbookClient().getKeywords().map { $0.toKeyword() }
            } catch { return nil }
        }

        switch fetchMode {
        case .preferLocal:
            if let keywords = await getLocal() { return keywords }
            if let keywords = await getServer() {
                await dataStore.saveKeywords(keywords)
                return keywords
            }
        case .preferServer:
            if let keywords = await getServer() {
                await dataStore.saveKeywords(keywords)
                return keywords
            }
            if let keywords = await getLocal() { return keywords }
        case .onlyLocal:
            if let keywords = await getLocal() { return keywords }
        case .onlyServer:
            if let keywords = await getServer() { return keywords }
        }
        return []
    }

    // MARK: - Delete / upload

    /// Deletes all stored data, including local recipes.
    func deleteAllData() async {
        await dataStore.clearAll()
        self.categories = []
        self.recipes = [:]
        self.recipeDetails = [:]
        self.recipeImages = [:]
        self.imagesNeedUpdate = [:]
        self.serverCategoryCounts = [:]
    }

    /// Deletes everything cached from Nextcloud (used when signing out).
    /// Local recipes stay on the device and in the recipe list.
    func deleteNextcloudData() async {
        await dataStore.clearNextcloudData()
        self.cookbookClientTask = nil
        self.categories = []
        self.recipes = [:]
        self.recipeDetails = [:]
        self.recipeImages = [:]
        self.imagesNeedUpdate = [:]
        self.serverCategoryCounts = [:]
        self.allKeywords = []
        await mergeLocalRecipes()
        await recomputeCategoryCounts()
    }

    func deleteRecipe(withId id: Int) async -> RequestAlert? {
        let externalId = await dataStore.externalSourceId(forRecipe: id)
        if let externalId {
            // Nextcloud recipe — delete on the server first
            do {
                try await cookbookClient().deleteRecipe(id: externalId)
            } catch {
                return .REQUEST_DROPPED
            }
        }

        await dataStore.deleteRecipe(id: id)
        recipeDetails.removeValue(forKey: id)
        recipeImages.removeValue(forKey: id)
        imagesNeedUpdate.removeValue(forKey: id)
        // Remove the recipe from whichever category list holds it
        for category in recipes.keys {
            let before = recipes[category]?.count ?? 0
            recipes[category]?.removeAll(where: { $0.id == id })
            if externalId != nil, (recipes[category]?.count ?? 0) < before, let count = serverCategoryCounts[category] {
                serverCategoryCounts[category] = max(0, count - 1)
            }
        }
        await recomputeCategoryCounts()
        return nil
    }

    /// Saves a recipe locally (no server upload). Assigns a new id if the recipe is new.
    /// Returns the saved RecipeDetail (with ID filled in) and an optional error alert.
    func saveLocalRecipe(recipeDetail: RecipeDetail) async -> (RecipeDetail?, RequestAlert?) {
        var detail = recipeDetail

        // A recipe without an id, or one that belongs to Nextcloud, is saved as a new local recipe
        let localId: Int
        if let id = detail.id, detail.externalSourceId == nil {
            localId = id
        } else {
            localId = await dataStore.newLocalRecipeId()
            detail.id = localId
            detail.externalSourceId = nil
        }
        let category = Self.categoryKey(for: detail.recipeCategory, origin: .local)

        // Persist detail
        await dataStore.saveRecipeDetail(detail)

        // Build lightweight Recipe summary
        let recipe = Recipe(
            id: localId,
            externalSourceId: nil,
            name: detail.name,
            keywords: detail.keywords,
            dateCreated: detail.dateCreated,
            dateModified: detail.dateModified,
            imageUrl: nil,
            imagePlaceholderUrl: nil
        )

        // Persist summary
        await dataStore.saveLocalRecipeSummary(recipe, forCategory: category)

        // Update in-memory state; drop the entry from its previous category if it moved
        for key in recipes.keys where key != category {
            recipes[key]?.removeAll(where: { $0.id == localId })
        }
        if let idx = recipes[category]?.firstIndex(where: { $0.id == localId }) {
            recipes[category]![idx] = recipe
        } else {
            recipes[category, default: []].append(recipe)
        }
        if !categories.contains(where: { $0.name == category }) {
            categories.append(Category(name: category, recipe_count: 0))
        }
        await recomputeCategoryCounts()

        return (detail, nil)
    }

    enum ServerStatus {
        case connected
        case unreachable
        /// The server rejected the stored credentials (e.g. the app password was revoked).
        case signInRequired
    }

    func checkServerConnection() async -> ServerStatus {
        guard UserSettings.shared.isLoggedIn else { return .unreachable }
        do {
            _ = try await cookbookClient().getCategories()
            return .connected
        } catch NCKError.clientError(statusCode: 401) {
            return .signInRequired
        } catch {
            return .unreachable
        }
    }

    /// Uploads a recipe. Creates it on the server when `createNew` is true, otherwise
    /// updates the server recipe `recipeDetail.externalSourceId`. Returns the recipe's
    /// internal id or an alert when the request failed.
    func uploadRecipe(recipeDetail: RecipeDetail, createNew: Bool) async -> (Int?, RequestAlert?) {
        let nckDetail = recipeDetail.toNCKRecipeDetail()
        do {
            let client = try await cookbookClient()
            let externalId: String
            if createNew {
                externalId = try await client.createRecipe(nckDetail)
            } else {
                guard let id = recipeDetail.externalSourceId else { return (nil, .REQUEST_DROPPED) }
                try await client.updateRecipe(nckDetail)
                externalId = id
            }
            let ids = await dataStore.recipeIds(forExternalIds: [externalId])
            return (ids[externalId], nil)
        } catch { return (nil, .REQUEST_DROPPED) }
    }

    // MARK: - Recipe photos

    /// Stores (or with `nil`, removes) the photo of a local recipe.
    func setLocalRecipePhoto(_ image: UIImage?, recipeId: Int) async {
        await dataStore.deleteImages(forRecipe: recipeId)
        if let image,
           let full = image.resized(maxDimension: 2048).jpegData(compressionQuality: 0.85),
           let thumb = image.resized(maxDimension: 400).jpegData(compressionQuality: 0.8) {
            await dataStore.saveImage(full, forRecipe: recipeId, size: .FULL)
            await dataStore.saveImage(thumb, forRecipe: recipeId, size: .THUMB)
        }
        forgetCachedImages(for: recipeId)
    }

    /// Drops cached and stored images of a recipe so the next request fetches
    /// the current ones (e.g. after its photo changed on the server).
    func invalidateImages(for recipeId: Int) async {
        // Only Nextcloud recipes: a local recipe's stored photo is its only copy
        if await dataStore.externalSourceId(forRecipe: recipeId) != nil {
            await dataStore.deleteImages(forRecipe: recipeId)
        }
        forgetCachedImages(for: recipeId)
    }

    private func forgetCachedImages(for recipeId: Int) {
        recipeImages.removeValue(forKey: recipeId)
        imagesNeedUpdate.removeValue(forKey: recipeId)
    }

    func importRecipe(url: String) async -> (RecipeDetail?, RequestAlert?) {
        guard let urlObj = URL(string: url) else { return (nil, .REQUEST_DROPPED) }
        do {
            // The server already stored the imported recipe, so register its id now;
            // saving the editor then updates that recipe instead of creating a copy.
            let imported = try await cookbookClient().importRecipe(from: urlObj)
            let ids = await dataStore.recipeIds(forExternalIds: imported.id.isEmpty ? [] : [imported.id])
            return (imported.toRecipeDetail(id: ids[imported.id]), nil)
        } catch { return (nil, .REQUEST_DROPPED) }
    }
}


// MARK: - Image helpers

extension AppState {
    private func imageFromStore(id: Int, size: RecipeImage.RecipeImageSize) async -> UIImage? {
        guard let data = await dataStore.loadImage(forRecipe: id, size: size) else { return nil }
        return UIImage(data: data)
    }

    /// Encode off the main actor — pngData() is CPU-intensive and must not block the UI.
    private nonisolated func encodeToPNG(_ image: UIImage) async -> Data? {
        image.pngData()
    }

    private func imageToStore(id: Int, size: RecipeImage.RecipeImageSize, image: UIImage) async {
        guard let data = await encodeToPNG(image) else { return }
        await dataStore.saveImage(data, forRecipe: id, size: size)
    }

    private func imageToCache(id: Int, size: RecipeImage.RecipeImageSize, image: UIImage) {
        recipeImages[id, default: [:]][size.rawValue] = image
        imagesNeedUpdate[id, default: [:]][size.rawValue] = false
    }

    private func imageFromCache(id: Int, size: RecipeImage.RecipeImageSize) -> UIImage? {
        recipeImages[id]?[size.rawValue]
    }

    private func imageUpdateNeeded(id: Int, size: RecipeImage.RecipeImageSize) -> Bool {
        imagesNeedUpdate[id]?[size.rawValue] ?? true
    }

    /// A Nextcloud recipe needs syncing when it isn't stored yet, or when it was
    /// modified on the server since the last completed sync.
    private func needsUpdate(_ recipe: Recipe) async -> Bool {
        guard await dataStore.recipeDetailExists(recipeId: recipe.id) else { return true }
        guard let dateString = recipe.dateModified,
              let modified = Self.parseServerDate(dateString)
        else { return true }
        return modified >= UserSettings.shared.lastUpdate
    }

    private static let serverDateFormatters: [DateFormatter] = [
        "yyyy-MM-dd'T'HH:mm:ssZ",
        "yyyy-MM-dd'T'HH:mm:ssZZZZZ",
        "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ",
        "yyyy-MM-dd HH:mm:ss",
    ].map { format in
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = format
        return formatter
    }

    private static func parseServerDate(_ string: String) -> Date? {
        for formatter in serverDateFormatters {
            if let date = formatter.date(from: string) { return date }
        }
        return nil
    }
}


extension UIImage {
    /// Scales the image down so its longer side is at most `maxDimension` points
    /// (never up). Also bakes in the orientation, which camera photos carry as metadata.
    func resized(maxDimension: CGFloat) -> UIImage {
        let scale = min(1, maxDimension / max(size.width, size.height))
        let target = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: target))
        }
    }
}


// MARK: - Timer logic

extension AppState {
    func createTimer(forRecipe recipeId: String, duration: DurationComponents) -> RecipeTimer {
        let timer = RecipeTimer(duration: duration)
        timers[recipeId] = timer
        return timer
    }

    func getTimer(forRecipe recipeId: String, duration: DurationComponents) -> RecipeTimer {
        return timers[recipeId] ?? createTimer(forRecipe: recipeId, duration: duration)
    }

    func deleteTimer(forRecipe recipeId: String) {
        timers.removeValue(forKey: recipeId)
    }
}
