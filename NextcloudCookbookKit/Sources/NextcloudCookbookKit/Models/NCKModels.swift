// NCKModels.swift
// NextcloudCookbookKit
//
// Codable models that map directly to the Nextcloud Cookbook REST API's JSON shapes.

import Foundation

// MARK: - Recipe list item

public struct NCKRecipe: Codable, Identifiable, Hashable, Sendable {
    /// The server's recipe id.
    ///
    /// API 0.1.2 deprecated the integer `recipe_id` in favour of the string `id`.
    /// Both are decoded (`id` preferred) so older and future servers work.
    public let id: String
    public let name: String
    public let keywords: String?
    public let dateCreated: String?
    public let dateModified: String?
    public let imageUrl: String?
    public let imagePlaceholderUrl: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case recipeId = "recipe_id"
        case name, keywords, dateCreated, dateModified, imageUrl, imagePlaceholderUrl
    }

    public init(
        id: String,
        name: String,
        keywords: String? = nil,
        dateCreated: String? = nil,
        dateModified: String? = nil,
        imageUrl: String? = nil,
        imagePlaceholderUrl: String? = nil
    ) {
        self.id = id
        self.name = name
        self.keywords = keywords
        self.dateCreated = dateCreated
        self.dateModified = dateModified
        self.imageUrl = imageUrl
        self.imagePlaceholderUrl = imagePlaceholderUrl
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let id = try? c.decode(JSONScalar.self, forKey: .id), !id.stringValue.isEmpty {
            self.id = id.stringValue
        } else {
            self.id = String(try c.decode(Int.self, forKey: .recipeId))
        }
        name = try c.decode(String.self, forKey: .name)
        keywords = try c.decodeIfPresent(String.self, forKey: .keywords)
        dateCreated = try c.decodeIfPresent(String.self, forKey: .dateCreated)
        dateModified = try c.decodeIfPresent(String.self, forKey: .dateModified)
        imageUrl = try c.decodeIfPresent(String.self, forKey: .imageUrl)
        imagePlaceholderUrl = try c.decodeIfPresent(String.self, forKey: .imagePlaceholderUrl)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        if let legacyId = Int(id) { try c.encode(legacyId, forKey: .recipeId) }
        try c.encode(name, forKey: .name)
        try c.encodeIfPresent(keywords, forKey: .keywords)
        try c.encodeIfPresent(dateCreated, forKey: .dateCreated)
        try c.encodeIfPresent(dateModified, forKey: .dateModified)
        try c.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try c.encodeIfPresent(imagePlaceholderUrl, forKey: .imagePlaceholderUrl)
    }
}

// MARK: - Recipe detail

public struct NCKRecipeDetail: Codable, Sendable {
    public var name: String
    public var keywords: String
    public var dateCreated: String?
    public var dateModified: String?
    public var imageUrl: String?
    public var image: String?
    public var id: String
    public var prepTime: String?
    public var cookTime: String?
    public var totalTime: String?
    public var description: String
    public var url: String?
    public var recipeYield: Int
    public var recipeCategory: String
    public var tool: [String]
    public var recipeIngredient: [String]
    public var recipeInstructions: [String]
    public var nutrition: [String: String]

    private enum CodingKeys: String, CodingKey {
        case name, keywords, dateCreated, dateModified, image, imageUrl, id,
             prepTime, cookTime, totalTime, description, url,
             recipeYield, recipeCategory, tool, recipeIngredient,
             recipeInstructions, nutrition
    }

    public init(
        name: String,
        keywords: String = "",
        dateCreated: String? = nil,
        dateModified: String? = nil,
        imageUrl: String? = nil,
        image: String? = nil,
        id: String = "",
        prepTime: String? = nil,
        cookTime: String? = nil,
        totalTime: String? = nil,
        description: String = "",
        url: String? = nil,
        recipeYield: Int = 1,
        recipeCategory: String = "",
        tool: [String] = [],
        recipeIngredient: [String] = [],
        recipeInstructions: [String] = [],
        nutrition: [String: String] = [:]
    ) {
        self.name = name
        self.keywords = keywords
        self.dateCreated = dateCreated
        self.dateModified = dateModified
        self.imageUrl = imageUrl
        self.image = image
        self.id = id
        self.prepTime = prepTime
        self.cookTime = cookTime
        self.totalTime = totalTime
        self.description = description
        self.url = url
        self.recipeYield = recipeYield
        self.recipeCategory = recipeCategory
        self.tool = tool
        self.recipeIngredient = recipeIngredient
        self.recipeInstructions = recipeInstructions
        self.nutrition = nutrition
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decode(String.self, forKey: .name)
        keywords = try c.decode(String.self, forKey: .keywords)
        dateCreated = try c.decodeIfPresent(String.self, forKey: .dateCreated)
        dateModified = try c.decodeIfPresent(String.self, forKey: .dateModified)
        image = try c.decodeIfPresent(String.self, forKey: .image)
        imageUrl = try c.decodeIfPresent(String.self, forKey: .imageUrl)
        id = try c.decode(String.self, forKey: .id)
        prepTime = try c.decodeIfPresent(String.self, forKey: .prepTime)
        cookTime = try c.decodeIfPresent(String.self, forKey: .cookTime)
        totalTime = try c.decodeIfPresent(String.self, forKey: .totalTime)
        description = try c.decode(String.self, forKey: .description)
        url = try c.decodeIfPresent(String.self, forKey: .url)
        recipeYield = (try? c.decode(Int?.self, forKey: .recipeYield)) ?? 1
        recipeCategory = try c.decode(String.self, forKey: .recipeCategory)
        tool = try c.decode([String].self, forKey: .tool)
        recipeIngredient = try c.decode([String].self, forKey: .recipeIngredient)
        recipeInstructions = try c.decode([String].self, forKey: .recipeInstructions)
        // nutrition values may arrive as strings or numbers — coerce to String
        let raw = try c.decode([String: JSONScalar].self, forKey: .nutrition)
        nutrition = raw.mapValues { $0.stringValue }
    }
}

// MARK: - Category

public struct NCKCategory: Codable, Identifiable, Hashable, Sendable {
    public let name: String
    public let recipeCount: Int

    public var id: String { name }

    private enum CodingKeys: String, CodingKey {
        case name
        case recipeCount = "recipe_count"
    }

    public init(name: String, recipeCount: Int) {
        self.name = name
        self.recipeCount = recipeCount
    }
}

// MARK: - Keyword / Tag

public struct NCKKeyword: Codable, Identifiable, Hashable, Sendable {
    public let name: String
    public let recipeCount: Int

    public var id: String { name }

    private enum CodingKeys: String, CodingKey {
        case name
        case recipeCount = "recipe_count"
    }

    public init(name: String, recipeCount: Int) {
        self.name = name
        self.recipeCount = recipeCount
    }
}

// MARK: - Image size

public enum NCKImageSize: String, Sendable {
    case thumb = "thumb"
    case full = "full"
}

// MARK: - Auth models

public struct NCKLoginV2Request: Codable, Sendable {
    public let poll: NCKLoginV2Poll
    public let login: String
}

public struct NCKLoginV2Poll: Codable, Sendable {
    public let token: String
    public let endpoint: String
}

public struct NCKLoginV2Response: Codable, Sendable {
    public let server: String
    public let loginName: String
    public let appPassword: String
}

public struct NCKUserData: Sendable {
    public let userId: String
    public let displayName: String

    public init(userId: String, displayName: String) {
        self.userId = userId
        self.displayName = displayName
    }
}

// MARK: - Internal helpers

/// Decodes a JSON value that may be a String, Bool, Int, or Double, coercing it to String.
struct JSONScalar: Decodable {
    let stringValue: String

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let v = try? c.decode(String.self) {
            stringValue = v
        } else if let v = try? c.decode(Int.self) {
            stringValue = "\(v)"
        } else if let v = try? c.decode(Double.self) {
            stringValue = "\(v)"
        } else if let v = try? c.decode(Bool.self) {
            stringValue = "\(v)"
        } else {
            stringValue = ""
        }
    }
}
