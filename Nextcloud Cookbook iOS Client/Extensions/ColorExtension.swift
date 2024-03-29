//
//  ColorExtension.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 20.09.23.
//

import Foundation
import SwiftUI

extension Color {
    public static var nextcloudBlue: Color {
        return Color("ncblue")
    }
    public static var nextcloudDarkBlue: Color {
        return Color("ncdarkblue")
    }
    public static var backgroundHighlight: Color {
        return Color("backgroundHighlight")
    }
    public static var background: Color {
        return Color(UIColor.systemBackground)
    }
    public static var ncGradientDark: Color {
        return Color("ncgradientdarkblue")
    }
    public static var ncGradientLight: Color {
        return Color("ncgradientlightblue")
    }
    public static var ncTextHighlight: Color {
        return Color("textHighlight")
    }
}
