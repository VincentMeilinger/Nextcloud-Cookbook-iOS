//
//  Nextcloud_Cookbook_iOS_ClientApp.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 06.09.23.
//

import SwiftUI

import SwiftUI

@main
struct Nextcloud_Cookbook_iOS_ClientApp: App {
    @StateObject var mainViewModel = AppState()
    @AppStorage("onboarding") var onboarding = true
    @AppStorage("language") var language = Locale.current.language.languageCode?.identifier ?? "en"
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if onboarding {
                    OnboardingView()
                } else {
                    MainView(viewModel: mainViewModel)
                }
            }
            .transition(.slide)
            .environment(
                \.locale,
                .init(identifier: language ==
                      SupportedLanguage.DEVICE.rawValue ? (Locale.current.language.languageCode?.identifier ?? "en") : language)
            )
        }
    }
}
