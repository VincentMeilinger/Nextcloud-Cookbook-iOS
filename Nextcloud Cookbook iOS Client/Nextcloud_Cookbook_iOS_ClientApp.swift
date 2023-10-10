//
//  Nextcloud_Cookbook_iOS_ClientApp.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 06.09.23.
//

import SwiftUI

@main
struct Nextcloud_Cookbook_iOS_ClientApp: App {
    @StateObject var userSettings = UserSettings()
    @StateObject var mainViewModel = MainViewModel()
    @State(initialValue: "en") var language: String
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if userSettings.onboarding {
                    OnboardingView(userSettings: userSettings)
                } else {
                    MainView(viewModel: mainViewModel, userSettings: userSettings)
                        .onAppear {
                            mainViewModel.apiController = APIController(userSettings: userSettings)
                        }
                }
            }
            .transition(.slide)
            .onAppear {
                language = userSettings.language
                print(userSettings.language)
            }
            .environment(\.locale, .init(identifier: language))
        }
        
    }
}
