//
//  CookbookApiWebDAV.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Kofi Mandel on 29.10.26.
//

import Foundation
import UIKit


/// A Cookbook API implementation working directly on recipe files stored on a plain WebDAV server.
///
/// Recipes are expected in the Nextcloud Cookbook folder layout, so that they stay compatible with the Cookbook server app:
/// `<root>/<recipe folder>/recipe.json`, plus the optional images `full.jpg` and `thumb.jpg`.
class CookbookApiWebDAV: CookbookApi {
    static let basePath: String = ""
    static let recipeFileName = "recipe.json"
    static let thumbnailSize: CGFloat = 256

    /// Check that the configured address points to a WebDAV folder and the credentials are valid.
    static func validate(auth: String) async -> NetworkError? {
        guard let client = WebDAVClient.current(auth: auth) else { return .missingUrl }
        let (resources, error) = await client.propfind(client.rootURL, depth: 0)
        if let error = error { return error }
        guard let root = resources?.first, root.isCollection else { return .notFound }
        return nil
    }

    /// Clear the in-memory recipe index, e.g. after logging out.
    static func reset() {
        Task {
            await WebDAVRecipeStore.shared.reset()
        }
    }

    static func importRecipe(auth: String, data: Data) async -> (RecipeDetail?, NetworkError?) {
        // Importing is done by the Cookbook server app. Callers fall back to the local RecipeScraper.
        return (nil, .invalidRequest)
    }

    static func getImage(auth: String, id: Int, size: RecipeImage.RecipeImageSize) async -> (UIImage?, NetworkError?) {
        guard let client = WebDAVClient.current(auth: auth) else { return (nil, .missingUrl) }
        let (entry, error) = await WebDAVRecipeStore.shared.entry(id: id, client: client)
        guard let entry = entry else { return (nil, error) }

        func download(_ fileName: String) async -> (UIImage?, NetworkError?) {
            let (result, error) = await client.get(entry.folderURL.appendingPathComponent(fileName))
            guard case .file(let file) = result else { return (nil, error) }
            return (UIImage(data: file.data), nil)
        }

        switch size {
        case .FULL:
            return await download("full.jpg")
        case .THUMB:
            let (thumb, error) = await download("thumb.jpg")
            if thumb != nil || error != .notFound {
                return (thumb, error)
            }
            // Recipes not created by the Cookbook server app might come without a thumbnail
            let (image, fullError) = await download("full.jpg")
            return (image?.scaledDown(toFit: thumbnailSize), fullError)
        }
    }

    static func getRecipes(auth: String) async -> ([Recipe]?, NetworkError?) {
        let (entries, error) = await allEntries(auth: auth)
        guard let entries = entries else { return (nil, error) }
        return (recipeList(entries), nil)
    }

    static func createRecipe(auth: String, recipe: RecipeDetail) async -> (NetworkError?) {
        guard let client = WebDAVClient.current(auth: auth) else { return .missingUrl }
        return await WebDAVRecipeStore.shared.createRecipe(recipe, client: client)
    }

    static func getRecipe(auth: String, id: Int) async -> (RecipeDetail?, NetworkError?) {
        guard let client = WebDAVClient.current(auth: auth) else { return (nil, .missingUrl) }
        return await WebDAVRecipeStore.shared.recipe(id: id, client: client)
    }

    static func updateRecipe(auth: String, recipe: RecipeDetail) async -> (NetworkError?) {
        guard let client = WebDAVClient.current(auth: auth) else { return .missingUrl }
        return await WebDAVRecipeStore.shared.updateRecipe(recipe, client: client)
    }

    static func deleteRecipe(auth: String, id: Int) async -> (NetworkError?) {
        guard let client = WebDAVClient.current(auth: auth) else { return .missingUrl }
        return await WebDAVRecipeStore.shared.deleteRecipe(id: id, client: client)
    }

    static func getCategories(auth: String) async -> ([Category]?, NetworkError?) {
        let (entries, error) = await allEntries(auth: auth)
        guard let entries = entries else { return (nil, error) }
        return (categories(entries.map(\.recipe)), nil)
    }

    static func getCategory(auth: String, named categoryName: String) async -> ([Recipe]?, NetworkError?) {
        let (entries, error) = await allEntries(auth: auth)
        guard let entries = entries else { return (nil, error) }
        // The Cookbook API uses "_" for recipes without a category
        let category = categoryName == "_" ? "*" : categoryName
        return (recipeList(entries.filter { Self.category(of: $0.recipe) == category }), nil)
    }

    static func renameCategory(auth: String, named categoryName: String, newName: String) async -> (NetworkError?) {
        guard let client = WebDAVClient.current(auth: auth) else { return .missingUrl }
        let (entries, error) = await WebDAVRecipeStore.shared.allEntries(client: client)
        guard let entries = entries else { return error }
        for entry in entries where category(of: entry.recipe) == categoryName {
            var recipe = entry.recipe
            recipe.recipeCategory = newName
            if let error = await WebDAVRecipeStore.shared.updateRecipe(recipe, client: client) {
                return error
            }
        }
        return nil
    }

    static func getTags(auth: String) async -> ([RecipeKeyword]?, NetworkError?) {
        let (entries, error) = await allEntries(auth: auth)
        guard let entries = entries else { return (nil, error) }
        return (keywords(entries.map(\.recipe)), nil)
    }

    static func getRecipesTagged(auth: String, keyword: String) async -> ([Recipe]?, NetworkError?) {
        let (entries, error) = await allEntries(auth: auth)
        guard let entries = entries else { return (nil, error) }
        let tagged = entries.filter { entry in
            keywordList(of: entry.recipe).contains { $0.caseInsensitiveCompare(keyword) == .orderedSame }
        }
        return (recipeList(tagged), nil)
    }

    static func getApiVersion(auth: String) async -> (NetworkError?) {
        return .none
    }

    static func postReindex(auth: String) async -> (NetworkError?) {
        return .none
    }

    static func getConfig(auth: String) async -> (NetworkError?) {
        return .none
    }

    static func postConfig(auth: String) async -> (NetworkError?) {
        return .none
    }

    private static func allEntries(auth: String) async -> ([WebDAVRecipeStore.Entry]?, NetworkError?) {
        guard let client = WebDAVClient.current(auth: auth) else { return (nil, .missingUrl) }
        return await WebDAVRecipeStore.shared.allEntries(client: client)
    }
}



// MARK: - Recipe index

/// Keeps track of the recipe folders found on the WebDAV server and their parsed recipe.json files.
actor WebDAVRecipeStore {
    static let shared = WebDAVRecipeStore()

    struct Entry {
        let id: Int
        let folderURL: URL
        var folderEtag: String?
        var recipeEtag: String?
        var lastModified: Date?
        var recipe: RecipeDetail

        var folderName: String { folderURL.lastPathComponent }
        var recipeURL: URL { folderURL.appendingPathComponent(CookbookApiWebDAV.recipeFileName) }
    }

    /// Do not list the root folder again if it was listed less than `maxAge` seconds ago.
    /// This avoids rescanning all recipes for each of the requests sent when the app launches.
    private let maxAge: TimeInterval = 10
    private let maxConcurrentDownloads = 6
    private let maxFolderNameAttempts = 50

    private var recipes: [Int: Entry] = [:]
    private var rootKey: String? = nil
    private var lastRefresh: Date = .distantPast
    private var lastRefreshError: NetworkError? = nil
    private var refreshTask: Task<NetworkError?, Never>? = nil

    func reset() {
        recipes = [:]
        rootKey = nil
        lastRefresh = .distantPast
        lastRefreshError = nil
        refreshTask = nil
    }

    /// All recipes, after updating the index from the server if necessary.
    func allEntries(client: WebDAVClient) async -> ([Entry]?, NetworkError?) {
        if let error = await refreshIfNeeded(client: client) {
            return (nil, error)
        }
        return (Array(recipes.values), nil)
    }

    /// The recipe with the specified id. Updates the index from the server if the id is unknown.
    func entry(id: Int, client: WebDAVClient) async -> (Entry?, NetworkError?) {
        prepare(for: client)
        if let entry = recipes[id] {
            return (entry, nil)
        }
        if let error = await refreshIfNeeded(client: client) {
            return (nil, error)
        }
        guard let entry = recipes[id] else { return (nil, .notFound) }
        return (entry, nil)
    }

    /// The recipe detail with the specified id. Downloads the recipe again if it has changed since the last refresh.
    func recipe(id: Int, client: WebDAVClient) async -> (RecipeDetail?, NetworkError?) {
        let (entry, error) = await entry(id: id, client: client)
        guard let entry = entry else { return (nil, error) }
        if isFresh {
            return (entry.recipe, nil)
        }

        let (result, getError) = await client.get(entry.recipeURL, ifNoneMatch: entry.recipeEtag)
        switch result {
        case .notModified:
            return (entry.recipe, nil)
        case .file(let file):
            guard let updated = Self.makeEntry(id: id, folderURL: entry.folderURL, folderEtag: entry.folderEtag, file: file) else {
                return (nil, .decodingFailed)
            }
            recipes[id] = updated
            return (updated.recipe, nil)
        case nil:
            if getError == .notFound {
                recipes[id] = nil
            }
            return (nil, getError)
        }
    }

    func createRecipe(_ recipe: RecipeDetail, client: WebDAVClient) async -> NetworkError? {
        if let error = await refreshIfNeeded(client: client) {
            return error
        }
        guard let data = CookbookApiWebDAV.recipeJSON(existing: nil, recipe: recipe) else {
            return .encodingFailed
        }
        let takenNames = Set(recipes.values.map { $0.folderName.lowercased() })

        for attempt in 1...maxFolderNameAttempts {
            let name = CookbookApiWebDAV.folderName(for: recipe.name, attempt: attempt)
            if takenNames.contains(name.lowercased()) { continue }

            let folderURL = client.folderURL(named: name)
            // Not all servers reject MKCOL for existing folders, so check whether the folder exists first
            let (existingFolder, propfindError) = await client.propfind(folderURL, depth: 0)
            if existingFolder != nil { continue }
            if propfindError != .notFound { return propfindError ?? .unknownError }

            let mkcolError = await client.mkcol(folderURL)
            if mkcolError == .alreadyExists { continue }
            if let error = mkcolError { return error }

            if let error = await client.put(folderURL.appendingPathComponent(CookbookApiWebDAV.recipeFileName), data: data, contentType: .JSON) {
                // Don't leave an empty recipe folder behind
                _ = await client.delete(folderURL)
                return error
            }
            return await reloadFolder(folderURL, client: client)
        }
        return .alreadyExists
    }

    /// Updates the recipe.json file of an existing recipe, keeping all fields not managed by this app.
    /// The recipe folder is not renamed, so that recipe ids stay stable.
    func updateRecipe(_ recipe: RecipeDetail, client: WebDAVClient) async -> NetworkError? {
        guard let id = Int(recipe.id) else { return .parametersNil }
        let (entry, error) = await entry(id: id, client: client)
        guard let entry = entry else { return error }

        // Merge into the latest version of the file on the server
        var existing: [String: Any]? = nil
        let (result, getError) = await client.get(entry.recipeURL)
        if case .file(let file) = result {
            existing = Self.jsonObject(file.data)
        } else if getError != .notFound {
            return getError
        }

        guard let data = CookbookApiWebDAV.recipeJSON(existing: existing, recipe: recipe) else {
            return .encodingFailed
        }
        if let error = await client.put(entry.recipeURL, data: data, contentType: .JSON) {
            return error
        }
        return await reloadFolder(entry.folderURL, client: client)
    }

    func deleteRecipe(id: Int, client: WebDAVClient) async -> NetworkError? {
        let (entry, error) = await entry(id: id, client: client)
        guard let entry = entry else { return error }
        if let error = await client.delete(entry.folderURL), error != .notFound {
            return error
        }
        recipes[id] = nil
        return nil
    }


    // MARK: Index updates

    private var isFresh: Bool {
        lastRefreshError == nil && Date().timeIntervalSince(lastRefresh) < maxAge
    }

    /// Clears the index if it was built for a different folder or user.
    private func prepare(for client: WebDAVClient) {
        let key = client.rootURL.absoluteString + "|" + client.authString
        if key != rootKey {
            reset()
            rootKey = key
        }
    }

    private func refreshIfNeeded(client: WebDAVClient) async -> NetworkError? {
        prepare(for: client)
        if Date().timeIntervalSince(lastRefresh) < maxAge {
            return lastRefreshError
        }
        if let refreshTask = refreshTask {
            return await refreshTask.value
        }

        let task = Task { await self.refresh(client: client) }
        refreshTask = task
        let error = await task.value
        if refreshTask == task {
            refreshTask = nil
        }
        return error
    }

    /// Lists the recipe folders and downloads all recipe.json files that changed since the last refresh.
    private func refresh(client: WebDAVClient) async -> NetworkError? {
        let key = rootKey
        let (resources, error) = await client.propfind(client.rootURL, depth: 1)
        guard key == rootKey else { return .unknownError }
        guard let resources = resources else {
            lastRefresh = Date()
            lastRefreshError = error ?? .unknownError
            return lastRefreshError
        }

        let folders = Self.recipeFolders(in: resources, rootURL: client.rootURL)
        let cached = recipes
        var updated: [Int: Entry] = [:]

        await withTaskGroup(of: Entry?.self) { group in
            var next = 0
            func addTask() {
                let folder = folders[next]
                let cachedEntry = cached[Self.recipeId(for: folder)]
                group.addTask {
                    await Self.loadEntry(folder: folder, cached: cachedEntry, client: client)
                }
                next += 1
            }

            while next < min(maxConcurrentDownloads, folders.count) {
                addTask()
            }
            for await entry in group {
                if let entry = entry {
                    updated[entry.id] = entry
                }
                if next < folders.count {
                    addTask()
                }
            }
        }

        guard key == rootKey else { return .unknownError }
        recipes = updated
        lastRefresh = Date()
        lastRefreshError = nil
        return nil
    }

    /// Reloads a single recipe folder, e.g. after it was changed by this app.
    private func reloadFolder(_ folderURL: URL, client: WebDAVClient) async -> NetworkError? {
        let (resources, error) = await client.propfind(folderURL, depth: 0)
        guard let folder = resources?.first else { return error ?? .dataError }
        let id = Self.recipeId(for: folder)
        let entryURL = client.folderURL(named: folder.name)

        let (result, getError) = await client.get(entryURL.appendingPathComponent(CookbookApiWebDAV.recipeFileName))
        guard case .file(let file) = result else { return getError ?? .dataError }
        guard let entry = Self.makeEntry(id: id, folderURL: entryURL, folderEtag: folder.etag, file: file) else {
            return .decodingFailed
        }
        recipes[id] = entry
        return nil
    }

    /// Downloads the recipe.json file of a recipe folder, unless it is known to be unchanged.
    /// - Returns: The updated entry, or nil if the folder does not contain a recipe.
    private static func loadEntry(folder: WebDAVResource, cached: Entry?, client: WebDAVClient) async -> Entry? {
        // Nextcloud and ownCloud (the servers reporting file ids) change a folder's etag whenever its contents change.
        // Other servers do not guarantee that, so their recipe.json files are always checked.
        if let cached = cached, folder.fileId != nil, folder.etag != nil, folder.etag == cached.folderEtag {
            return cached
        }

        let id = recipeId(for: folder)
        let folderURL = client.folderURL(named: folder.name)
        let (result, error) = await client.get(
            folderURL.appendingPathComponent(CookbookApiWebDAV.recipeFileName),
            ifNoneMatch: cached?.recipeEtag
        )
        switch result {
        case .file(let file):
            return makeEntry(id: id, folderURL: folderURL, folderEtag: folder.etag, file: file)
        case .notModified:
            guard var entry = cached else { return nil }
            entry.folderEtag = folder.etag
            return entry
        case nil:
            // Keep the cached recipe if the request failed for a reason other than the file missing
            return error == .notFound ? nil : cached
        }
    }

    private static func makeEntry(id: Int, folderURL: URL, folderEtag: String?, file: WebDAVFile) -> Entry? {
        guard let json = jsonObject(file.data) else { return nil }
        var recipe = RecipeDetail(schemaDict: json, id: id)
        if recipe.name.isEmpty {
            recipe.name = folderURL.lastPathComponent
        }
        return Entry(
            id: id,
            folderURL: folderURL,
            folderEtag: folderEtag,
            recipeEtag: file.etag,
            lastModified: file.lastModified,
            recipe: recipe
        )
    }

    private static func jsonObject(_ data: Data) -> [String: Any]? {
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }

    /// The sub folders of the root folder, excluding the root folder itself and hidden folders.
    static func recipeFolders(in resources: [WebDAVResource], rootURL: URL) -> [WebDAVResource] {
        let rootPath = rootURL.standardized.path
        var children = resources.filter { $0.url.standardized.path != rootPath }
        if children.count == resources.count, !children.isEmpty {
            // The root folder could not be identified by its path (e.g. behind a rewriting proxy).
            // Servers list the requested folder first.
            children.removeFirst()
        }
        return children.filter { $0.isCollection && !$0.name.hasPrefix(".") }
    }

    static func recipeId(for folder: WebDAVResource) -> Int {
        return folder.fileId ?? stableId(forFolderNamed: folder.name)
    }

    /// A recipe id derived from the folder name, for servers that do not report file ids.
    ///
    /// Uses the 64 bit FNV-1a hash, since Swift's `Hasher` is seeded randomly on each launch.
    /// The result is limited to 53 bits, so that it is exactly representable in JSON numbers.
    static func stableId(forFolderNamed name: String) -> Int {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in name.precomposedStringWithCanonicalMapping.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        let id = Int(hash & 0x1F_FFFF_FFFF_FFFF)
        return id == 0 ? 1 : id
    }
}



// MARK: - Recipe mapping

extension CookbookApiWebDAV {
    static func recipeList(_ entries: [WebDAVRecipeStore.Entry]) -> [Recipe] {
        return entries
            .map { entry in
                Recipe(
                    name: entry.recipe.name,
                    keywords: entry.recipe.keywords,
                    dateCreated: entry.recipe.dateCreated,
                    dateModified: entry.lastModified.map { DateFormatter.utcToString(date: $0) },
                    imageUrl: nil,
                    imagePlaceholderUrl: nil,
                    recipe_id: entry.id
                )
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// The category name of a recipe. Recipes without a category are listed in the "*" category.
    static func category(of recipe: RecipeDetail) -> String {
        let name = recipe.recipeCategory.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "*" : name
    }

    static func categories(_ recipes: [RecipeDetail]) -> [Category] {
        var counts: [String: Int] = [:]
        for recipe in recipes {
            counts[category(of: recipe), default: 0] += 1
        }
        return counts
            .map { Category(name: $0.key, recipe_count: $0.value) }
            .sorted { a, b in
                if a.name == "*" || b.name == "*" {
                    return b.name == "*" && a.name != "*"
                }
                return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            }
    }

    static func keywordList(of recipe: RecipeDetail) -> [String] {
        return recipe.keywords
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    static func keywords(_ recipes: [RecipeDetail]) -> [RecipeKeyword] {
        var counts: [String: Int] = [:]
        for recipe in recipes {
            for keyword in Set(keywordList(of: recipe)) {
                counts[keyword, default: 0] += 1
            }
        }
        return counts
            .map { RecipeKeyword(name: $0.key, recipe_count: $0.value) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// The folder name for a new recipe. Attempts after the first one get a counter suffix, e.g. "Pancakes (2)".
    static func folderName(for recipeName: String, attempt: Int = 1) -> String {
        var name = String(recipeName.unicodeScalars.filter { scalar in
            !CharacterSet.controlCharacters.contains(scalar) && scalar != "/" && scalar != "\\"
        })
        name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        while name.hasPrefix(".") {
            name.removeFirst()
        }
        if name.isEmpty {
            name = "Recipe"
        }
        return attempt > 1 ? "\(name) (\(attempt))" : name
    }

    /// Encodes a recipe as recipe.json file contents.
    /// - Parameters:
    ///   - existing: The current contents of the recipe.json file, if the recipe already exists.
    static func recipeJSON(existing: [String: Any]?, recipe: RecipeDetail, now: Date = Date()) -> Data? {
        let json = mergedRecipeJSON(existing: existing, recipe: recipe, now: now)
        return try? JSONSerialization.data(withJSONObject: json, options: [.withoutEscapingSlashes])
    }

    /// Writes the fields editable in this app into an existing recipe.json dictionary.
    /// All other fields (e.g. id, image, imageUrl and fields unknown to this app) are kept as they are.
    static func mergedRecipeJSON(existing: [String: Any]?, recipe: RecipeDetail, now: Date) -> [String: Any] {
        var json = existing ?? [
            "@context": "http://schema.org",
            "@type": "Recipe"
        ]
        let timestamp = ISO8601DateFormatter().string(from: now)

        json["name"] = recipe.name
        json["description"] = recipe.description
        json["url"] = recipe.url ?? ""
        json["keywords"] = recipe.keywords
        json["recipeCategory"] = recipe.recipeCategory
        json["recipeYield"] = recipe.recipeYield
        if let prepTime = recipe.prepTime { json["prepTime"] = prepTime }
        if let cookTime = recipe.cookTime { json["cookTime"] = cookTime }
        if let totalTime = recipe.totalTime { json["totalTime"] = totalTime }
        json["tool"] = recipe.tool
        json["recipeIngredient"] = recipe.recipeIngredient
        json["recipeInstructions"] = recipe.recipeInstructions

        var nutrition: [String: Any] = recipe.nutrition
        if nutrition["@type"] == nil {
            nutrition["@type"] = "NutritionInformation"
        }
        json["nutrition"] = nutrition

        json["dateModified"] = timestamp
        if (json["dateCreated"] as? String ?? "").isEmpty {
            json["dateCreated"] = timestamp
        }
        return json
    }
}


extension RecipeDetail {
    /// Leniently creates a recipe from a schema.org recipe dictionary, e.g. a recipe.json file.
    ///
    /// Unlike the Decodable initializer, this accepts the different value types used by recipes that were not created by the Cookbook server app.
    init(schemaDict dict: [String: Any], id: Int) {
        self.init()
        self.id = String(id)
        name = SchemaValue.string(dict["name"]) ?? ""
        keywords = SchemaValue.stringList(dict["keywords"], separator: ",").joined(separator: ",")
        dateCreated = SchemaValue.string(dict["dateCreated"])
        dateModified = SchemaValue.string(dict["dateModified"])
        prepTime = SchemaValue.string(dict["prepTime"])
        cookTime = SchemaValue.string(dict["cookTime"])
        totalTime = SchemaValue.string(dict["totalTime"])
        description = SchemaValue.string(dict["description"]) ?? ""
        url = SchemaValue.string(dict["url"]) ?? ""
        recipeYield = SchemaValue.integer(dict["recipeYield"]) ?? 0
        recipeCategory = SchemaValue.string(dict["recipeCategory"]) ?? ""
        tool = SchemaValue.stringList(dict["tool"])
        recipeIngredient = SchemaValue.stringList(dict["recipeIngredient"])
        recipeInstructions = SchemaValue.stringList(dict["recipeInstructions"])
        if let nutritionDict = dict["nutrition"] as? [String: Any] {
            nutrition = nutritionDict.compactMapValues { SchemaValue.string($0) }
        }
    }
}


/// Helpers for reading the loosely typed values of schema.org JSON dictionaries.
fileprivate enum SchemaValue {
    static func string(_ value: Any?) -> String? {
        switch value {
        case let string as String:
            return string
        case let number as NSNumber:
            return number.stringValue
        case let array as [Any]:
            return array.lazy.compactMap { string($0) }.first
        case let dict as [String: Any]:
            return string(dict["name"] ?? dict["text"])
        default:
            return nil
        }
    }

    /// Reads a list of strings, given as a string, an array of strings, or an array of objects with a text or name
    /// (e.g. HowToStep). Nested lists (e.g. HowToSection) are flattened.
    static func stringList(_ value: Any?, separator: Character? = nil) -> [String] {
        let list: [String]
        switch value {
        case let string as String:
            if let separator = separator {
                list = string.split(separator: separator).map(String.init)
            } else {
                list = [string]
            }
        case let number as NSNumber:
            list = [number.stringValue]
        case let array as [Any]:
            list = array.flatMap { stringList($0, separator: separator) }
        case let dict as [String: Any]:
            if let elements = dict["itemListElement"] {
                list = stringList(elements, separator: separator)
            } else {
                list = string(dict["text"] ?? dict["name"]).map { [$0] } ?? []
            }
        default:
            list = []
        }
        return list
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    /// Reads an integer, given as a number or a string starting with a number (e.g. "4 servings").
    static func integer(_ value: Any?) -> Int? {
        switch value {
        case let number as NSNumber:
            return number.intValue
        case let string as String:
            let digits = string.drop { !$0.isNumber }.prefix { $0.isNumber }
            return Int(digits)
        case let array as [Any]:
            return array.lazy.compactMap { integer($0) }.first
        default:
            return nil
        }
    }
}


fileprivate extension UIImage {
    func scaledDown(toFit maxSize: CGFloat) -> UIImage {
        let scale = maxSize / max(size.width, size.height)
        guard scale < 1 else { return self }
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
