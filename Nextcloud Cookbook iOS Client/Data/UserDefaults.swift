//
//  UserDefaults.swift
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
        }
    }
    
    @Published var token: String {
        didSet {
            UserDefaults.standard.set(token, forKey: "token")
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
    
    init() {
        self.username = UserDefaults.standard.object(forKey: "username") as? String ?? ""
        self.token = UserDefaults.standard.object(forKey: "token") as? String ?? ""
        self.serverAddress = UserDefaults.standard.object(forKey: "serverAddress") as? String ?? ""
        self.onboarding = UserDefaults.standard.object(forKey: "onboarding") as? Bool ?? true
    }
}
