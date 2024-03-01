//
//  BottomClipper.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 27.02.24.
//

import Foundation
import SwiftUI

struct BottomClipper: Shape {
    let bottom: CGFloat

    func path(in rect: CGRect) -> Path {
        Rectangle().path(in: CGRect(x: 0, y: rect.size.height - bottom, width: rect.size.width, height: bottom))
    }
}
