//
//  UserSettings.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 15.09.23.
//


import Foundation
import Combine

class UserSettings: ObservableObject {
    @Published var username: String {
        didSet {
            UserDefaults.standard.set(username, forKey: "username")
            self.authString = setAuthString()
        }
    }
    
    @Published var token: String {
        didSet {
            UserDefaults.standard.set(token, forKey: "token")
            self.authString = setAuthString()
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
    
    @Published var downloadRecipes: Bool {
        didSet {
            UserDefaults.standard.set(downloadRecipes, forKey: "downloadRecipes")
        }
    }
    
    init() {
        self.username = UserDefaults.standard.object(forKey: "username") as? String ?? ""
        self.token = UserDefaults.standard.object(forKey: "token") as? String ?? ""
        self.authString = UserDefaults.standard.object(forKey: "authString") as? String ?? ""
        self.serverAddress = UserDefaults.standard.object(forKey: "serverAddress") as? String ?? ""
        self.onboarding = UserDefaults.standard.object(forKey: "onboarding") as? Bool ?? true
        self.defaultCategory = UserDefaults.standard.object(forKey: "defaultCategory") as? String ?? ""
        self.language = UserDefaults.standard.object(forKey: "language") as? String ?? SupportedLanguage.DEVICE.rawValue
        self.downloadRecipes = UserDefaults.standard.object(forKey: "downloadRecipes") as? Bool ?? false
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
