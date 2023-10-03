//
//  DateFormatterExtension.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 14.09.23.
//

import Foundation

extension Formatter {
    static let positional: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        return formatter
    }()
}

func formatDate(duration: String) -> String {
    var duration = duration
    if duration.hasPrefix("PT") { duration.removeFirst(2) }
    var hour: Int = 0, minute: Int = 0
    if let index = duration.firstIndex(of: "H") {
        hour = Int(duration[..<index]) ?? 0
        duration.removeSubrange(...index)
    }
    if let index = duration.firstIndex(of: "M") {
        minute = Int(duration[..<index]) ?? 0
        duration.removeSubrange(...index)
    }
    
    if hour == 0 && minute != 0 {
        return "\(minute)min"
    }
    if hour != 0 && minute == 0 {
        return "\(hour)h"
    }
    if hour != 0 && minute != 0 {
        return "\(hour)h \(minute)"
    }
    return "--"
}
