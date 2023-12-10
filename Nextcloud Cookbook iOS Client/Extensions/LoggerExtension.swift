//
//  Logger.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 13.11.23.
//

import Foundation
import OSLog

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!

    /// UI related logging
    static let view = Logger(subsystem: subsystem, category: "view")

    /// Network related logging
    static let network = Logger(subsystem: subsystem, category: "network")
}
