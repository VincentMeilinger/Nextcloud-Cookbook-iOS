//
//  SettingsView.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 15.09.23.
//

import Foundation
import SwiftUI



struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var userSettings = UserSettings.shared
    @ObservedObject var viewModel = ViewModel()
    
    var body: some View {
        Form {
            HStack(alignment: .center) {
                if let avatarImage = viewModel.avatarImage {
                    Image(uiImage: avatarImage)
                        .resizable()
                        .clipShape(Circle())
                        .frame(width: 100, height: 100)
                        
                }
                if let userData = viewModel.userData {
                    VStack(alignment: .leading) {
                        Text(userData.userDisplayName)
                            .font(.title)
                            .padding(.leading)
                        Text("Username: \(userData.userId)")
                            .font(.subheadline)
                            .padding(.leading)
                        
                        
                        // TODO: Add actions
                    }
                }
                Spacer()
            }
            
            Section {
                Picker("Select a default cookbook", selection: $userSettings.defaultCategory) {
                    Text("None").tag("None")
                    ForEach(appState.categories, id: \.name) { category in
                        Text(category.name == "*" ? "Other" : category.name).tag(category)
                    }
                }
            } header: {
                Text("General")
            } footer: {
                Text("The selected cookbook will open on app launch by default.")
            }
            
            Section {
                Toggle(isOn: $userSettings.expandNutritionSection) {
                    Text("Expand nutrition section")
                }
                Toggle(isOn: $userSettings.expandKeywordSection) {
                    Text("Expand keyword section")
                }
                Toggle(isOn: $userSettings.expandInfoSection) {
                    Text("Expand information section")
                }
            } header: {
                Text("Recipes")
            } footer: {
                Text("Configure which sections in your recipes are expanded by default.")
            }
            
            Section {
                Toggle(isOn: $userSettings.keepScreenAwake) {
                    Text("Keep screen awake when viewing recipes")
                }
            }
            
            Section {
                HStack {
                    Text("Decimal number format")
                    Spacer()
                    Picker("", selection: $userSettings.decimalNumberSeparator) {
                        Text("Point (e.g. 1.42)").tag(".")
                        Text("Comma (e.g. 1,42)").tag(",")
                    }
                    .pickerStyle(.menu)
                }
            } footer: {
                Text("This setting will take effect after the app is restarted. It affects the adjustment of ingredient quantities.")
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
                    viewModel.alertType = .LOG_OUT
                    viewModel.showAlert = true
                    
                }
                .tint(.red)
                
                Button("Delete local data") {
                    print("Clear cache.")
                    viewModel.alertType = .DELETE_CACHE
                    viewModel.showAlert = true
                }
                .tint(.red)
                
            } header: {
                Text("Other")
            } footer: {
                Text("Deleting local data will not affect the recipe data stored on your server.")
            }
            
            Section(header: Text("Acknowledgements")) {
                VStack(alignment: .leading) {
                    if let url = URL(string: "https://github.com/scinfu/SwiftSoup") {
                        Link("SwiftSoup", destination:  url)
                            .font(.headline)
                        Text("An HTML parsing and web scraping library for Swift. Used for importing schema.org recipes from websites.")
                    }
                }
                VStack(alignment: .leading) {
                    if let url = URL(string: "https://github.com/techprimate/TPPDF") {
                        Link("TPPDF", destination: url)
                            .font(.headline)
                        Text("A simple-to-use PDF builder for Swift. Used for generating recipe PDF documents.")
                    }
                }
            }
        }
        
        .navigationTitle("Settings")
        .alert(viewModel.alertType.getTitle(), isPresented: $viewModel.showAlert) {
            Button("Cancel", role: .cancel) { }
            if viewModel.alertType == .LOG_OUT {
                Button("Log out", role: .destructive) { logOut() }
            } else if viewModel.alertType == .DELETE_CACHE {
                Button("Delete", role: .destructive) { deleteCache() }
            }
        } message: {
            Text(viewModel.alertType.getMessage())
        }
        .task {
            await viewModel.getUserData()
        }
    }
    
    func logOut() {
        userSettings.serverAddress = ""
        userSettings.username = ""
        userSettings.token = ""
        userSettings.authString = ""
        appState.deleteAllData()
        userSettings.onboarding = true
    }
    
    func deleteCache() {
        appState.deleteAllData()
    }
}

extension SettingsView {
    class ViewModel: ObservableObject {
        @Published var avatarImage: UIImage? = nil
        @Published var userData: UserData? = nil
        
        @Published var showAlert: Bool = false
        fileprivate var alertType: SettingsAlert = .NONE
        
        enum SettingsAlert {
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
        
        func getUserData() async {
            let (data, _) = await NextcloudApi.getAvatar()
            let (userData, _) = await NextcloudApi.getHoverCard()
            
            DispatchQueue.main.async {
                self.avatarImage = data
                self.userData = userData
            }
        }
    }
}




