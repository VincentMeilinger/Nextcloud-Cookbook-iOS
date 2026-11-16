//
//  SettingsView.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 15.09.23.
//

import Foundation
import SwiftUI
import NextcloudCookbookKit



struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var userSettings = UserSettings.shared
    @StateObject var viewModel = ViewModel()
    @State private var showLoginSheet = false

    var body: some View {
        Form {

            // MARK: - Account
            Section {
                if userSettings.isLoggedIn {
                    HStack(alignment: .center, spacing: 12) {
                        if let avatarImage = viewModel.avatarImage {
                            Image(uiImage: avatarImage)
                                .resizable()
                                .clipShape(Circle())
                                .frame(width: 56, height: 56)
                        } else {
                            Image(systemName: "person.crop.circle")
                                .resizable()
                                .frame(width: 56, height: 56)
                                .foregroundStyle(.secondary)
                        }
                        if let userData = viewModel.userData {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(userData.displayName)
                                    .font(.headline)
                                Text(userData.userId)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                } else {
                    Button {
                        showLoginSheet = true
                    } label: {
                        Label("Sign In to Nextcloud", systemImage: "person.badge.plus")
                    }
                }
            } header: {
                Text("Account")
            }

            Section {
                Picker("Select a default cookbook", selection: $userSettings.defaultCategory) {
                    Text("None").tag("")
                    ForEach(appState.categories, id: \.name) { category in
                        Text(category.name == "*" ? "Other" : category.name).tag(category.name)
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
                if userSettings.isLoggedIn {
                    Button("Sign Out") {
                        viewModel.alertType = .SIGN_OUT
                        viewModel.showAlert = true
                    }
                    .tint(.red)
                }

                Button("Delete local data") {
                    viewModel.alertType = .DELETE_CACHE
                    viewModel.showAlert = true
                }
                .tint(.red)

            } header: {
                Text("Other")
            } footer: {
                Text("Deleting local data removes cached Nextcloud recipes and locally-stored recipes from this device.")
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

        .sheet(isPresented: $showLoginSheet) {
            LoginView()
        }
        .onChange(of: userSettings.authString) {
            if userSettings.isLoggedIn {
                Task { await viewModel.getUserData() }
            } else {
                viewModel.avatarImage = nil
                viewModel.userData = nil
            }
        }
        .navigationTitle("Settings")
        .alert(viewModel.alertType.getTitle(), isPresented: $viewModel.showAlert) {
            Button("Cancel", role: .cancel) { }
            if viewModel.alertType == .SIGN_OUT {
                Button("Sign Out", role: .destructive) { signOut() }
            } else if viewModel.alertType == .DELETE_CACHE {
                Button("Delete", role: .destructive) { deleteCache() }
            }
        } message: {
            Text(viewModel.alertType.getMessage())
        }
        .task {
            if userSettings.isLoggedIn {
                await viewModel.getUserData()
            }
        }
    }

    func signOut() {
        userSettings.serverAddress = ""
        userSettings.username = ""
        userSettings.token = ""
        userSettings.authString = ""
        // Local recipes and the grocery list are preserved; only the Nextcloud cache is cleared
        Task { await appState.deleteNextcloudData() }
    }

    func deleteCache() {
        Task { await appState.deleteAllData() }
    }
}

extension SettingsView {
    class ViewModel: ObservableObject {
        @Published var avatarImage: UIImage? = nil
        @Published var userData: NCKUserData? = nil

        @Published var showAlert: Bool = false
        fileprivate var alertType: SettingsAlert = .NONE

        enum SettingsAlert {
            case SIGN_OUT,
                 DELETE_CACHE,
                 NONE

            func getTitle() -> String {
                switch self {
                case .SIGN_OUT: return "Sign Out"
                case .DELETE_CACHE: return "Delete local data"
                default: return "Please confirm your action."
                }
            }

            func getMessage() -> String {
                switch self {
                case .SIGN_OUT: return "Sign out of your Nextcloud account? Your locally-stored recipes will be preserved."
                case .DELETE_CACHE: return "Are you sure that you want to delete all local data? This includes locally-stored recipes and cached Nextcloud recipes."
                default: return ""
                }
            }
        }

        @MainActor
        func getUserData() async {
            let urlString = UserSettings.shared.serverProtocol + UserSettings.shared.serverAddress
            guard let serverURL = URL(string: urlString) else { return }
            let client = NextcloudAuthClient(serverURL: serverURL)
            let username = UserSettings.shared.username
            let credentials = UserSettings.shared.authString

            async let avatarData = try? client.getAvatar(username: username, size: 100, credentials: credentials)
            async let hoverCard = try? client.getHoverCard(username: username, credentials: credentials)

            let (avatar, userData) = await (avatarData, hoverCard)
            if let avatar { self.avatarImage = UIImage(data: avatar) }
            self.userData = userData
        }
    }
}


