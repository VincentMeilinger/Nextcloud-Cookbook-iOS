//
//  DateExtension.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 29.09.23.
//

import Foundation

extension Date {
    static var zero: Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat =  "HH:mm"
        if let date = dateFormatter.date(from:"00:00") {
            return date
        } else {
            return Date()
        }
    }
    
    static func toPTRepresentation(date: Date) -> String? {
        // PT0H18M0S
        let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: date)
        if let hour = dateComponents.hour, let minute = dateComponents.minute {
            return "PT\(hour)H\(minute)M0S"
        }
        return nil
    }
    
    static func fromPTRepresentation(_ representation: String) -> Date {
        let (hour, minute) = DateFormatter.stringToComponents(duration: representation)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat =  "HH:mm"
        if let date = dateFormatter.date(from:"\(hour):\(minute)") {
            return date
        } else {
            return Date()
        }
    }
}
