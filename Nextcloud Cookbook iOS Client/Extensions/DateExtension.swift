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
}
