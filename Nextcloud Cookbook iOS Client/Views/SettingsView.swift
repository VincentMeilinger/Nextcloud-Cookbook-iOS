//
//  SettingsView.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 15.09.23.
//

import Foundation
import SwiftUI

fileprivate enum SettingsAlert {
    case LOG_OUT,
         DELETE_CACHE,
         NONE
    
    func getTitle() -> String {
        switch self {
        case .LOG_OUT: return "Log out"
        case .DELETE_CACHE: return "Delete local data"
        default: return "Please confirm your action."
        }
    }
    
    func getMessage() -> String {
        switch self {
        case .LOG_OUT: return "Are you sure that you want to log out of your account?"
        case .DELETE_CACHE: return "Are you sure that you want to delete the downloaded recipes? This action will not affect any recipes stored on your server."
        default: return ""
        }
    }
}

struct SettingsView: View {
    @ObservedObject var userSettings: UserSettings
    @ObservedObject var viewModel: MainViewModel
    
    @State fileprivate var alertType: SettingsAlert = .NONE
    @State var showAlert: Bool = false
    
    var body: some View {
        Form {
            Section {
                Picker("Select a cookbook", selection: $userSettings.defaultCategory) {
                    Text("")
                    ForEach(viewModel.categories, id: \.name) { category in
                        Text(category.name == "*" ? "Other" : category.name)
                    }
                }
                Button {
                    userSettings.defaultCategory = ""
                } label: {
                    Text("Clear default category")
                }
            } header: {
                Text("Default cookbook")
            } footer: {
                Text("The selected cookbook will be opened on app launch by default.")
            }
            Section() {
                Link("Visit the GitHub page", destination: URL(string: "https://github.com/VincentMeilinger/Nextcloud-Cookbook-iOS")!)
            } header: {
                Text("About")
            } footer: {
                Text("If you are interested in contributing to this project or simply wish to review its source code, we encourage you to visit the GitHub repository for this application.")
            }
            
            Section() {
                Link("Get support", destination: URL(string: "https://vincentmeilinger.github.io/Nextcloud-Cookbook-Client-Support/")!)
            } header: {
                Text("Support")
            } footer: {
                Text("If you have any inquiries, feedback, or require assistance, please refer to the support page for contact information.")
            }
            
            Section() {
                Button("Log out") {
                    print("Log out.")
                    alertType = .LOG_OUT
                    showAlert = true
                    
                }
                .tint(.red)
                
                Button("Delete local data") {
                    print("Clear cache.")
                    alertType = .DELETE_CACHE
                    showAlert = true
                }
                .tint(.red)
                            
            } header: {
                Text("Other")
            } footer: {
                Text("Deleting local data will not affect the recipe data stored on your server.")
            }
        }
        .navigationTitle("Settings")
        .alert(alertType.getTitle(), isPresented: $showAlert) {
            Button("Cancel", role: .cancel) { }
            if alertType == .LOG_OUT {
                Button("Log out", role: .destructive) { logOut() }
            } else if alertType == .DELETE_CACHE {
                Button("Delete", role: .destructive) { deleteCache() }
            }
        } message: {
            Text(alertType.getMessage())
        }
    }
    
    func logOut() {
        userSettings.serverAddress = ""
        userSettings.username = ""
        userSettings.token = ""
        viewModel.deleteAllData()
        userSettings.onboarding = true
    }
    
    func deleteCache() {
        //viewModel.deleteAllData()
    }
}



