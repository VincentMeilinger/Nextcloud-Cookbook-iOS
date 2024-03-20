//
//  Locale.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 20.03.24.
//

import Foundation


// Ingredient number formatting
func getNumberFormatter() -> NumberFormatter {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 2
    formatter.decimalSeparator = UserSettings.shared.decimalNumberSeparator
    return formatter
}

let numberFormatter = getNumberFormatter()


