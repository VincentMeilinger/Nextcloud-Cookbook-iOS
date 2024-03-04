//
//  Duration.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 11.11.23.
//

import Foundation
import SwiftUI


class DurationComponents: ObservableObject {
    @Published var secondComponent: Int = 0 {
        didSet {
            if secondComponent > 59 {
                secondComponent = 59
            } else if secondComponent < 0 {
                secondComponent = 0
            }
        }
    }
    @Published var minuteComponent: Int = 0 {
        didSet {
            if minuteComponent > 59 {
                minuteComponent = 59
            } else if minuteComponent < 0 {
                minuteComponent = 0
            }
        }
    }
    
    @Published var hourComponent: Int = 0 {
        didSet {
            if hourComponent < 0 {
                hourComponent = 0
            }
        }
    }
    
    
    
    var displayString: String {
        if hourComponent != 0 && minuteComponent != 0 {
            return "\(hourComponent) h \(minuteComponent) min"
        } else if hourComponent == 0 && minuteComponent != 0 {
            return "\(minuteComponent) min"
        } else if hourComponent != 0 && minuteComponent == 0 {
            return "\(hourComponent) h"
        } else {
            return "-"
        }
    }
    
    static func fromPTString(_ PTRepresentation: String) -> DurationComponents {
        let duration = DurationComponents()
        let hourRegex = /([0-9]{1,2})H/
        let minuteRegex = /([0-9]{1,2})M/
        if let match = PTRepresentation.firstMatch(of: hourRegex) {
            duration.hourComponent = Int(match.1) ?? 0
        }
        if let match = PTRepresentation.firstMatch(of: minuteRegex) {
            duration.minuteComponent = Int(match.1) ?? 0
        }
        return duration
    }
    
    func fromPTString(_ PTRepresentation: String) {
        let hourRegex = /([0-9]{1,2})H/
        let minuteRegex = /([0-9]{1,2})M/
        if let match = PTRepresentation.firstMatch(of: hourRegex) {
            self.hourComponent = Int(match.1) ?? 0
        }
        if let match = PTRepresentation.firstMatch(of: minuteRegex) {
            self.minuteComponent = Int(match.1) ?? 0
        }
    }
    
    private func stringFormatComponents() -> (String, String, String) {
        let sec = secondComponent < 10 ? "0\(secondComponent)" : "\(secondComponent)"
        let min = minuteComponent < 10 ? "0\(minuteComponent)" : "\(minuteComponent)"
        let hr = hourComponent < 10 ? "0\(hourComponent)" : "\(hourComponent)"
        return (hr, min, sec)
    }
    
    func toPTString() -> String {
        let (hr, min, sec) = stringFormatComponents()
        return "PT\(hr)H\(min)M\(sec)S"
    }
    
    func toTimerText() -> String {
        var timeString = ""
        let (hr, min, sec) = stringFormatComponents()
        if hourComponent != 0 {
            timeString.append("\(hr):")
        }
        timeString.append("\(min):")
        timeString.append(sec)
        return timeString
    }
    
    func toSeconds() -> Double {
        return Double(hourComponent) * 3600 + Double(minuteComponent) * 60 + Double(secondComponent)
    }
    
    func fromSeconds(_ totalSeconds: Int) {
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        self.hourComponent = Int(hours)
        self.minuteComponent = Int(minutes)
        self.secondComponent = Int(seconds)
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
