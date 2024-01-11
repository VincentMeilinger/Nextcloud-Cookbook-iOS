//
//  Duration.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 11.11.23.
//

import Foundation
import SwiftUI


class DurationComponents: ObservableObject {
    @Published var secondComponent: String = "00" {
        didSet {
            if secondComponent.count > 2 {
                secondComponent = oldValue
            } else if secondComponent.count == 1 {
                secondComponent = "0\(secondComponent)"
            } else if secondComponent.count == 0 {
                secondComponent = "00"
            }
            let filtered = secondComponent.filter { $0.isNumber }
            if secondComponent != filtered {
                secondComponent = filtered
            }
        }
    }
    
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
    
    static func fromPTString(_ PTRepresentation: String) -> DurationComponents {
        let duration = DurationComponents()
        let hourRegex = /([0-9]{1,2})H/
        let minuteRegex = /([0-9]{1,2})M/
        if let match = PTRepresentation.firstMatch(of: hourRegex) {
            duration.hourComponent = String(match.1)
        }
        if let match = PTRepresentation.firstMatch(of: minuteRegex) {
            duration.minuteComponent = String(match.1)
        }
        return duration
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
    
    func toTimerText() -> String {
        var timeString = ""
        if hourComponent != "00" {
            timeString.append("\(hourComponent):")
        }
        timeString.append("\(minuteComponent):")
        timeString.append("\(secondComponent)")
        return timeString
    }
    
    func toSeconds() -> Double {
        guard let hours = Double(hourComponent) else { return 0 }
        guard let minutes = Double(minuteComponent) else { return 0 }
        guard let seconds = Double(secondComponent) else { return 0 }
        return hours * 3600 + minutes * 60 + seconds
    }
    
    func fromSeconds(_ totalSeconds: Int) {
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        self.hourComponent = String(hours)
        self.minuteComponent = String(minutes)
        self.secondComponent = String(seconds)
    }
    
    static func ptToText(_ ptString: String) -> String? {
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
            return nil
        }
    }
}
