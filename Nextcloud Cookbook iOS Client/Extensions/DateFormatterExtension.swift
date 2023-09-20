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
    let hour, minute, second: Double
    if let index = duration.firstIndex(of: "H") {
        hour = Double(duration[..<index]) ?? 0
        duration.removeSubrange(...index)
    } else { hour = 0 }
    if let index = duration.firstIndex(of: "M") {
        minute = Double(duration[..<index]) ?? 0
        duration.removeSubrange(...index)
    } else { minute = 0 }
    if let index = duration.firstIndex(of: "S") {
        second = Double(duration[..<index]) ?? 0
    } else { second = 0 }
    return Formatter.positional.string(from: hour * 3600 + minute * 60 + second) ?? "0:00"
}
