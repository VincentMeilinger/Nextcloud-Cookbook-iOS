//
//  Duration.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 11.11.23.
//

import Foundation
import SwiftUI


class DurationComponents: ObservableObject {
    @Published var minuteComponent: String = "00" {
        didSet {
            if minuteComponent.count > 2 {
                minuteComponent = oldValue
            } else if minuteComponent.count == 1 {
                minuteComponent = "0\(minuteComponent)"
            } else if minuteComponent.count == 0 {
                minuteComponent = "00"
            }
            let filtered = minuteComponent.filter { $0.isNumber }
            if minuteComponent != filtered {
                minuteComponent = filtered
            }
        }
    }
    
    @Published var hourComponent: String = "00" {
        didSet {
            if hourComponent.count > 2 {
                hourComponent = oldValue
            } else if hourComponent.count == 1 {
                hourComponent = "0\(hourComponent)"
            } else if hourComponent.count == 0 {
                hourComponent = "00"
            }
            let filtered = hourComponent.filter { $0.isNumber }
            if hourComponent != filtered {
                hourComponent = filtered
            }
        }
    }
    
    func fromPTString(_ PTRepresentation: String) {
        let hourRegex = /([0-9]{1,2})H/
        let minuteRegex = /([0-9]{1,2})M/
        if let match = PTRepresentation.firstMatch(of: hourRegex) {
            self.hourComponent = String(match.1)
        }
        if let match = PTRepresentation.firstMatch(of: minuteRegex) {
            self.minuteComponent = String(match.1)
        }
    }
    
    func toPTString() -> String {
        return "PT\(hourComponent)H\(minuteComponent)M00S"
    }
    
    func toText() -> LocalizedStringKey {
        let intHour = Int(hourComponent) ?? 0
        let intMinute = Int(minuteComponent) ?? 0
        if intHour != 0 && intMinute != 0 {
            return "\(intHour) h, \(intMinute) min"
        } else if intHour == 0 && intMinute != 0 {
            return "\(intMinute) min"
        } else if intHour != 0 && intMinute == 0 {
            return "\(intHour) h"
        } else {
            return "-"
        }
    }
    
    static func ptToText(_ ptString: String) -> String {
        let hourRegex = /([0-9]{1,2})H/
        let minuteRegex = /([0-9]{1,2})M/
        
        var intHour = 0
        var intMinute = 0
        if let match = ptString.firstMatch(of: hourRegex) {
            let hourComponent = String(match.1)
            intHour = Int(hourComponent) ?? 0
        }
        if let match = ptString.firstMatch(of: minuteRegex) {
            let minuteComponent = String(match.1)
            intMinute = Int(minuteComponent) ?? 0
        }
        
        if intHour != 0 && intMinute != 0 {
            return "\(intHour) h, \(intMinute) min"
        } else if intHour == 0 && intMinute != 0 {
            return "\(intMinute) min"
        } else if intHour != 0 && intMinute == 0 {
            return "\(intHour) h"
        } else {
            return "-"
        }
    }
}
