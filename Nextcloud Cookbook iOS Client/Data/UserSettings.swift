//
//  UserSettings.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 15.09.23.
//


import Foundation
import Combine

class UserSettings: ObservableObject {
    
    static let shared = UserSettings()
    
    @Published var username: String {
        didSet {
            UserDefaults.standard.set(username, forKey: "username")
        }
    }
    
    @Published var token: String {
        didSet {
            UserDefaults.standard.set(token, forKey: "token")
        }
    }
    
    @Published var authString: String {
        didSet {
            UserDefaults.standard.set(authString, forKey: "authString")
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
    
    @Published var expandKeywordSection: Bool {
        didSet {
            UserDefaults.standard.set(expandKeywordSection, forKey: "expandKeywordSection")
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
    
    init() {
        self.username = UserDefaults.standard.object(forKey: "username") as? String ?? ""
        self.token = UserDefaults.standard.object(forKey: "token") as? String ?? ""
        self.authString = UserDefaults.standard.object(forKey: "authString") as? String ?? ""
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
        self.expandKeywordSection = UserDefaults.standard.object(forKey: "expandKeywordSection") as? Bool ?? false
        self.expandInfoSection = UserDefaults.standard.object(forKey: "expandInfoSection") as? Bool ?? false
        self.keepScreenAwake = UserDefaults.standard.object(forKey: "keepScreenAwake") as? Bool ?? true
        
        if authString == "" {
            if token != "" && username != "" {
                let loginString = "\(self.username):\(self.token)"
                let loginData = loginString.data(using: String.Encoding.utf8)!
                authString = loginData.base64EncodedString()
            }
        }
    }
    
    func setAuthString() -> String {
        if token != "" && username != "" {
            let loginString = "\(self.username):\(self.token)"
            let loginData = loginString.data(using: String.Encoding.utf8)!
            return loginData.base64EncodedString()
        } else {
            return ""
        }
    }
}
