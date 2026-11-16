//
//  UserSettings.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 15.09.23.
//


import Foundation
import Combine
import Security

class UserSettings: ObservableObject {
    
    static let shared = UserSettings()
        
    @Published var username: String {
        didSet {
            UserDefaults.standard.set(username, forKey: "username")
        }
    }
    
    /// App password. Stored in the Keychain, never in UserDefaults.
    @Published var token: String {
        didSet {
            Keychain.set(token, forKey: "token")
        }
    }

    /// Base64-encoded "username:token" for HTTP Basic auth. Stored in the Keychain.
    @Published var authString: String {
        didSet {
            Keychain.set(authString, forKey: "authString")
        }
    }
    
    @Published var serverAddress: String {
        didSet {
            UserDefaults.standard.set(serverAddress, forKey: "serverAddress")
        }
    }
    
    @Published var serverProtocol: String {
        didSet {
            UserDefaults.standard.set(serverProtocol, forKey: "serverProtocol")
        }
    }
    
    @Published var onboarding: Bool {
        didSet {
            UserDefaults.standard.set(onboarding, forKey: "onboarding")
        }
    }
    
    @Published var defaultCategory: String {
        didSet {
            UserDefaults.standard.set(defaultCategory, forKey: "defaultCategory")
        }
    }
    
    @Published var language: String {
        didSet {
            UserDefaults.standard.set(language, forKey: "language")
        }
    }
    
    @Published var storeRecipes: Bool {
        didSet {
            UserDefaults.standard.set(storeRecipes, forKey: "storeRecipes")
        }
    }
    
    @Published var storeImages: Bool {
        didSet {
            UserDefaults.standard.set(storeImages, forKey: "storeImages")
        }
    }
    
    @Published var storeThumb: Bool {
        didSet {
            UserDefaults.standard.set(storeThumb, forKey: "storeThumb")
        }
    }
    
    @Published var lastUpdate: Date {
        didSet {
            UserDefaults.standard.set(lastUpdate, forKey: "lastUpdate")
        }
    }
    
    @Published var expandNutritionSection: Bool {
        didSet {
            UserDefaults.standard.set(expandNutritionSection, forKey: "expandNutritionSection")
        }
    }
    
    @Published var expandInfoSection: Bool {
        didSet {
            UserDefaults.standard.set(expandInfoSection, forKey: "expandInfoSection")
        }
    }
    
    @Published var keepScreenAwake: Bool {
        didSet {
            UserDefaults.standard.set(keepScreenAwake, forKey: "keepScreenAwake")
        }
    }
    
    @Published var decimalNumberSeparator: String {
        didSet {
            UserDefaults.standard.set(decimalNumberSeparator, forKey: "decimalNumberSeparator")
        }
    }

    /// True when valid Nextcloud credentials are stored.
    var isLoggedIn: Bool { !serverAddress.isEmpty && !authString.isEmpty }

    init() {
        self.username = UserDefaults.standard.object(forKey: "username") as? String ?? ""
        self.token = Self.loadSecret(forKey: "token")
        self.authString = Self.loadSecret(forKey: "authString")
        self.serverAddress = UserDefaults.standard.object(forKey: "serverAddress") as? String ?? ""
        self.serverProtocol = UserDefaults.standard.object(forKey: "serverProtocol") as? String ?? "https://"
        self.onboarding = UserDefaults.standard.object(forKey: "onboarding") as? Bool ?? true
        self.defaultCategory = UserDefaults.standard.object(forKey: "defaultCategory") as? String ?? ""
        self.language = UserDefaults.standard.object(forKey: "language") as? String ?? SupportedLanguage.DEVICE.rawValue
        self.storeRecipes = UserDefaults.standard.object(forKey: "storeRecipes") as? Bool ?? true
        self.storeImages = UserDefaults.standard.object(forKey: "storeImages") as? Bool ?? true
        self.storeThumb = UserDefaults.standard.object(forKey: "storeThumb") as? Bool ?? true
        self.lastUpdate = UserDefaults.standard.object(forKey: "lastUpdate") as? Date ?? Date.distantPast
        self.expandNutritionSection = UserDefaults.standard.object(forKey: "expandNutritionSection") as? Bool ?? false
        self.expandInfoSection = UserDefaults.standard.object(forKey: "expandInfoSection") as? Bool ?? false
        self.keepScreenAwake = UserDefaults.standard.object(forKey: "keepScreenAwake") as? Bool ?? true
        self.decimalNumberSeparator = UserDefaults.standard.object(forKey: "decimalNumberSeparator") as? String ?? "."

        if authString == "" {
            if token != "" && username != "" {
                let loginString = "\(self.username):\(self.token)"
                let loginData = loginString.data(using: String.Encoding.utf8)!
                authString = loginData.base64EncodedString()
            }
        }

    }
    
    func setAuthString() {
        if token != "" && username != "" {
            let loginString = "\(self.username):\(self.token)"
            let loginData = loginString.data(using: String.Encoding.utf8)!
            self.authString = loginData.base64EncodedString()
        }
    }

    /// Reads a secret from the Keychain. Values left in UserDefaults by older app
    /// versions are moved into the Keychain and removed from UserDefaults.
    private static func loadSecret(forKey key: String) -> String {
        if let legacy = UserDefaults.standard.string(forKey: key) {
            if !legacy.isEmpty { Keychain.set(legacy, forKey: key) }
            UserDefaults.standard.removeObject(forKey: key)
        }
        return Keychain.get(key) ?? ""
    }
}


/// Minimal generic-password Keychain wrapper for the app's credentials.
enum Keychain {
    private static let service = Bundle.main.bundleIdentifier ?? "NextcloudCookbook"

    private static func query(_ key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
    }

    static func get(_ key: String) -> String? {
        var q = query(key)
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        guard SecItemCopyMatching(q as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data
        else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Stores `value`, or deletes the item when `value` is empty.
    static func set(_ value: String, forKey key: String) {
        SecItemDelete(query(key) as CFDictionary)
        guard !value.isEmpty else { return }
        var q = query(key)
        q[kSecValueData as String] = Data(value.utf8)
        q[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(q as CFDictionary, nil)
    }
}
