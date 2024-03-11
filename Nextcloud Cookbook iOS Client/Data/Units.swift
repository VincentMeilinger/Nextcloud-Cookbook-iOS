//
//  Units.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 11.03.24.
//

import Foundation
import SwiftUI


// MARK: - Ingredient Units

enum MeasurementUnit {
    // Volume Metric
    case milliLiter, centiLiter, deciLiter, liter
    
    // Volume Imperial
    case teaspoon, tablespoon, cup, pint, quart, gallon, gill, fluidOunce // Please just use metric
    
    // Weight Metric
    case milliGram, gram, kilogram
    
    // Weight Imperial
    case ounce, pound
    
    // Other
    case pinch, dash, smidgen
    
    
    var localizedDescription: [LocalizedStringKey] {
        switch self {
        case .milliLiter:
            return ["milliliter", "millilitre", "ml", "cc"]
        case .centiLiter:
            return ["centiliter", "centilitre", "cl"]
        case .deciLiter:
            return ["deciliter", "decilitre", "dl"]
        case .liter:
            return ["liter", "litre", "l"]
        case .teaspoon:
            return ["teaspoon", "tsp"]
        case .tablespoon:
            return ["tablespoon", "tbsp"]
        case .cup:
            return ["cup", "c"]
        case .pint:
            return ["pint", "pt"]
        case .quart:
            return ["quart", "qt"]
        case .gallon:
            return ["gallon", "gal"]
        case .gill:
            return ["gill", "gi"]
        case .fluidOunce:
            return ["fluid ounce", "fl oz"]
        case .milliGram:
            return ["milligram", "mg"]
        case .gram:
            return ["gram", "g"]
        case .kilogram:
            return ["kilogram", "kg"]
        case .ounce:
            return ["ounce", "oz"]
        case .pound:
            return ["pound", "lb"]
        case .pinch:
            return ["pinch"]
        case .dash:
            return ["dash"]
        case .smidgen:
            return ["smidgen"]
        }
    }
    
    static func convert(value: Double, from fromUnit: MeasurementUnit, to toUnit: MeasurementUnit) -> Double? {
        let (baseValue, _) = MeasurementUnit.toBaseUnit(value: value, unit: fromUnit)
        return MeasurementUnit.fromBaseUnit(value: baseValue, targetUnit: toUnit)
    }
    
    private static func baseUnit(of unit: MeasurementUnit) -> MeasurementUnit {
        switch unit {
        // Volume Metric (all converted to liters)
        case .milliLiter, .centiLiter, .deciLiter, .liter, .teaspoon, .tablespoon, .cup, .pint, .quart, .gallon, .gill, .fluidOunce, .dash:
            return .liter

        // Weight (all converted to grams)
        case .milliGram, .gram, .kilogram, .ounce, .pound, .pinch, .smidgen:
            return .gram
        }
    }
    
    private static func toBaseUnit(value: Double, unit: MeasurementUnit) -> (Double, MeasurementUnit) {
        guard abs(value) >= Double(1e-10) else {
            return (0, unit)
        }
        switch unit {
        case .milliLiter:
            return (value/1000, .liter)
        case .centiLiter:
            return (value/100, .liter)
        case .deciLiter:
            return (value/10, .liter)
        case .liter:
            return (value, .liter)
        case .teaspoon:
            return (value * 0.005, .liter)
        case .tablespoon:
            return (value * 0.015, .liter)
        case .cup:
            return (value * 0.25, .liter)
        case .pint:
            return (value * 0.5, .liter)
        case .quart:
            return (value * 0.946, .liter)
        case .gallon:
            return (value * 3.8, .liter)
        case .gill:
            return (value * 0.17, .liter)
        case .fluidOunce:
            return (value * 0.03, .liter)
        case .milliGram:
            return (value * 0.001, .gram)
        case .gram:
            return (value, .gram)
        case .kilogram:
            return (value * 1000, .gram)
        case .ounce:
            return (value * 30, .gram)
        case .pound:
            return (value * 450, .gram)
        case .pinch:
            return (value * 0.3, .gram)
        case .dash:
            return (value * 0.000625, .liter)
        case .smidgen:
            return (value * 0.15, .gram)
        }
    }
    
    static private func fromBaseUnit(value: Double, targetUnit: MeasurementUnit) -> Double {
        guard abs(value) >= Double(1e-10) else {
            return 0
        }

        switch targetUnit {
        case .milliLiter:
            return value * 1000
        case .centiLiter:
            return value * 100
        case .deciLiter:
            return value * 10
        case .liter:
            return value
        case .teaspoon:
            return value / 0.005
        case .tablespoon:
            return value / 0.015
        case .cup:
            return value / 0.25
        case .pint:
            return value / 0.5
        case .quart:
            return value / 0.946
        case .gallon:
            return value / 3.8
        case .gill:
            return value / 0.17
        case .fluidOunce:
            return value / 0.03
        case .milliGram:
            return value * 1000
        case .gram:
            return value
        case .kilogram:
            return value / 1000
        case .ounce:
            return value / 30
        case .pound:
            return value / 450
        case .pinch:
            return value / 0.3
        case .dash:
            return value / 0.000625
        case .smidgen:
            return value / 0.15
        }
    }
}



enum TemperatureUnit {
    case fahrenheit, celsius
    
    var localizedDescription: [LocalizedStringKey] {
        switch self {
        case .fahrenheit:
            ["fahrenheit", "f"]
        case .celsius:
            ["celsius", "c"]
        }
    }
    
    static func celsiusToFahrenheit(_ celsius: Double) -> Double {
        return celsius * 9.0 / 5.0 + 32.0
    }

    static func fahrenheitToCelsius(_ fahrenheit: Double) -> Double {
        return (fahrenheit - 32.0) * 5.0 / 9.0
    }
}
