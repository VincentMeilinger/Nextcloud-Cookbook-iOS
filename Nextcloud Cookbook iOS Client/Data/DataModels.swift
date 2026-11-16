//
//  DataModels.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 15.09.23.
//

import Foundation
import SwiftUI


struct Category: Codable {
    let name: String
    var recipe_count: Int

    private enum CodingKeys: String, CodingKey {
        case name, recipe_count
    }
}

extension Category: Identifiable, Hashable {
    var id: String { name }
}




