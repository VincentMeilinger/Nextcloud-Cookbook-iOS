//
//  Nextcloud_Cookbook_iOS_ClientApp.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 06.09.23.
//

import SwiftUI
import SwiftData
import UIKit

@main
struct Nextcloud_Cookbook_iOS_ClientApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @AppStorage("language") var language = Locale.current.language.languageCode?.identifier ?? "en"

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(
                    \.locale,
                    .init(identifier: language ==
                          SupportedLanguage.DEVICE.rawValue ? (Locale.current.language.languageCode?.identifier ?? "en") : language)
                )
        }
        .modelContainer(sharedModelContainer)
    }
}


// MARK: - Home screen quick actions

/// Home screen quick actions (long-press the app icon). The scene delegate
/// records the requested tab; MainView observes it and switches tabs.
@MainActor @Observable
final class QuickActions {
    static let shared = QuickActions()
    var requestedTab: AppTab?

    private static let groceryListType = "groceryList"

    static func registerShortcuts() {
        UIApplication.shared.shortcutItems = [
            UIApplicationShortcutItem(
                type: groceryListType,
                localizedTitle: String(localized: "Grocery List"),
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(systemImageName: "cart")
            ),
        ]
    }

    @discardableResult
    func handle(_ item: UIApplicationShortcutItem) -> Bool {
        guard item.type == Self.groceryListType else { return false }
        requestedTab = .groceryList
        return true
    }
}

/// SwiftUI has no quick-action callback, so a scene delegate forwards them.
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        configuration.delegateClass = QuickActionSceneDelegate.self
        return configuration
    }
}

@MainActor
final class QuickActionSceneDelegate: NSObject, UIWindowSceneDelegate {
    /// App launched from a quick action.
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let item = connectionOptions.shortcutItem else { return }
        QuickActions.shared.handle(item)
    }

    /// Quick action while the app was already running.
    func windowScene(
        _ windowScene: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        completionHandler(QuickActions.shared.handle(shortcutItem))
    }
}
