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
    let recipe_count: Int
    
    private enum CodingKeys: String, CodingKey {
        case name, recipe_count
    }
}

extension Category: Identifiable, Hashable {
    var id: String { name }
}



// MARK: - Login flow

struct LoginV2Request: Codable {
    let poll: LoginV2Poll
    let login: String
}

struct LoginV2Poll: Codable {
    let token: String
    let endpoint: String
}

struct LoginV2Response: Codable {
    let server: String
    let loginName: String
    let appPassword: String
}

struct LoginValidation: Codable {
    let ocs: Ocs
}

struct Ocs: Codable {
    let meta: MetaData
}

struct MetaData: Codable {
    let status: String
    let statuscode: Int
}



