//
//  SettingsView.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 15.09.23.
//

import Foundation
import SwiftUI



struct SettingsView: View {
    @ObservedObject var viewModel: MainViewModel
    @ObservedObject var userSettings = UserSettings.shared
    
    @State fileprivate var alertType: SettingsAlert = .NONE
    @State var showAlert: Bool = false
    
    var body: some View {
        Form {
            Section {
                Picker("Select a default cookbook", selection: $userSettings.defaultCategory) {
                    Text("None").tag("None")
                    ForEach(viewModel.categories, id: \.name) { category in
                        Text(category.name == "*" ? "Other" : category.name).tag(category)
                    }
                }
            } header: {
                Text("General")
            } footer: {
                Text("The selected cookbook will open on app launch by default.")
            }
            
            Section {
                Toggle(isOn: $userSettings.storeRecipes) {
                    Text("Offline recipes")
                }
                Toggle(isOn: $userSettings.storeImages) {
                    Text("Store recipe images locally")
                }
                Toggle(isOn: $userSettings.storeThumb) {
                    Text("Store recipe thumbnails locally")
                }
            } header: {
                Text("Downloads")
            } footer: {
                Text("Configure what is stored on your device.")
            }
            
            Section {
                Picker("Language", selection: $userSettings.language) {
                    ForEach(SupportedLanguage.allValues, id: \.self) { lang in
                        Text(lang.descriptor()).tag(lang.rawValue)
                    }
                }
            } footer: {
                Text("If \'Same as Device\' is selected and your device language is not supported yet, this option will default to english.")
            }
            
            
            Section {
                Link("Visit the GitHub page", destination: URL(string: "https://github.com/VincentMeilinger/Nextcloud-Cookbook-iOS")!)
            } header: {
                Text("About")
            } footer: {
                Text("If you are interested in contributing to this project or simply wish to review its source code, we encourage you to visit the GitHub repository for this application.")
            }
            
            Section {
                Link("Get support", destination: URL(string: "https://vincentmeilinger.github.io/Nextcloud-Cookbook-Client-Support/")!)
            } header: {
                Text("Support")
            } footer: {
                Text("If you have any inquiries, feedback, or require assistance, please refer to the support page for contact information.")
            }
            
            Section {
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
        userSettings.authString = ""
        viewModel.deleteAllData()
        userSettings.onboarding = true
    }
    
    func deleteCache() {
        viewModel.deleteAllData()
    }
}



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
