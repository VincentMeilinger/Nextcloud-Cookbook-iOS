//
//  NetworkRequests.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 13.09.23.
//

import Foundation

enum RequestMethod: String {
    case GET = "GET", 
         POST = "POST",
         PUT = "PUT",
         DELETE = "DELETE"
}

enum ContentType: String {
    case JSON = "application/json", 
         IMAGE = "image/jpeg",
         FORM = "application/x-www-form-urlencoded"
}

struct HeaderField {
    private let _field: String
    private let _value: String
    
    func getField() -> String {
        return _field
    }
    
    func getValue() -> String {
        return _value
    }
    
    static func accept(value: ContentType) -> HeaderField {
        return HeaderField(_field: "accept", _value: value.rawValue)
    }
    
    static func ocsRequest(value: Bool) -> HeaderField {
        return HeaderField(_field: "OCS-APIRequest", _value: value ? "true" : "false")
    }
    
    static func contentType(value: ContentType) -> HeaderField {
        return HeaderField(_field: "Content-Type", _value: value.rawValue)
    }
}

struct RecipeImportRequest: Codable {
    let url: String
}
