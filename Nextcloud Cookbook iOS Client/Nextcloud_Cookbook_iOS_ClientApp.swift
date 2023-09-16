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
    var body: some Scene {
        WindowGroup {
            MainView()
                .fullScreenCover(isPresented: $userSettings.onboarding) {
                    OnboardingView(userSettings: userSettings)
                }
        }
    }
}
