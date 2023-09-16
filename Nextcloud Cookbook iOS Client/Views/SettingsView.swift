//
//  SettingsView.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 15.09.23.
//

import Foundation
import SwiftUI

struct SettingsView: View {
    @ObservedObject var userSettings: UserSettings
    
    var body: some View {
        List {
            SettingsSection(title: "Language", description: "Language settings coming soon.")
            SettingsSection(title: "Accent Color", description: "The accent color setting will be released in a future update.")
            SettingsSection(title: "Log out", description: "Log out of your Nextcloud account in this app. Your recipes will be removed from local storage.") 
            {
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
            }
            
            SettingsSection(title: "Clear local data", description: "Your recipes will be removed from local storage.")
            {
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


struct SettingsSection<Content: View>: View {
    let title: String
    let description: String
    @ViewBuilder let content: () -> Content
    
    init(title: String, description: String, content: @escaping () -> Content) {
        self.title = title
        self.description = description
        self.content = content
    }
    
    init(title: String, description: String) where Content == EmptyView {
        self.title = title
        self.description = description
        self.content = { EmptyView() }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
            }.padding()
            Spacer()
            content()
        }
        
    }
}
