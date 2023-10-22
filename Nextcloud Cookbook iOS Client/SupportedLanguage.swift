//
//  SupportedLanguage.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 18.10.23.
//

import Foundation


enum SupportedLanguage: String, Codable {
    case DEVICE = "device",
         EN = "en",
         DE = "de",
         ES = "es"
    
    func descriptor() -> String {
        switch self {
        case .DEVICE:
            return String(localized: "Same as Device")
        case .EN:
            return "English"
        case .DE:
            return "Deutsch"
        case .ES:
            return "Español"
        }
    }
    
    static let allValues = [DEVICE, EN, DE, ES]
}
