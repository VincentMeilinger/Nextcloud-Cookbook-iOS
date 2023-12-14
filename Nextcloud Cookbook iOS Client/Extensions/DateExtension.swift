//
//  DateExtension.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 14.12.23.
//

import Foundation

extension Date {
    static func convertUTCStringToLocalString(utcDateString: String, withFormat format: String = "yyyy-MM-dd HH:mm:ss") -> String? {
        // DateFormatter for parsing the UTC date string
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = format
        inputFormatter.timeZone = TimeZone(secondsFromGMT: 0) // UTC

        // DateFormatter for converting to local time string
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = format // You can modify this format for different output styles
        outputFormatter.timeZone = TimeZone.current // Device's local time zone

        // Convert the string to Date and then to local time string
        if let date = inputFormatter.date(from: utcDateString) {
            return outputFormatter.string(from: date)
        } else {
            return nil // Return nil if the input string is not in the correct format
        }
    }
    
    static func convertISOStringToLocalString(isoDateString: String, withFormat format: String = "yyyy-MM-dd HH:mm:ss") -> String? {
        let inputFormatter = ISO8601DateFormatter()
        // DateFormatter for converting to local time string
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = format // You can modify this format for different output styles
        outputFormatter.timeZone = TimeZone.current // Device's local time zone

        // Convert the string to Date and then to local time string
        if let date = inputFormatter.date(from: isoDateString) {
            return outputFormatter.string(from: date)
        } else {
            return nil // Return nil if the input string is not in the correct format
        }
    }
}
