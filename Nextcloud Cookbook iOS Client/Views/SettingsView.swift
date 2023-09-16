//
//  SettingsView.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 15.09.23.
//

import Foundation
import SwiftUI

struct SettingsView: View {
    @StateObject var userSettings = UserSettings()
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack {
                SettingsSection(headline: "Language", description: "Language settings coming soon.")
                SettingsSection(headline: "Accent Color", description: "The accent color setting will be released in a future update.")
                Button("Log out") {
                    print("Log out.")
                    userSettings.serverAddress = ""
                    userSettings.username = ""
                    userSettings.token = ""
                    userSettings.onboarding = true
                }
                .buttonStyle(.borderedProminent)
                .accentColor(.red)
                .padding()
                
                Button("Clear Cache") {
                    print("Clear cache.")
                    
                }
                .buttonStyle(.borderedProminent)
                .accentColor(.red)
                .padding()
            }
        }.navigationTitle("Settings")
    }
}


struct SettingsSection: View {
    @State var headline: String
    @State var description: String
    var body: some View {
        VStack(alignment: .leading) {
            Text(headline)
                .font(.headline)
            Text(description)
                
            Divider()
        }.padding()
    }
}
