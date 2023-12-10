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


enum RequestPath {
    case CATEGORIES,
         RECIPE_LIST(categoryName: String),
         RECIPE_DETAIL(recipeId: Int),
         NEW_RECIPE,
         IMAGE(recipeId: Int, thumb: Bool),
         CONFIG,
         KEYWORDS
    
    case LOGINV2REQ,
         CUSTOM(path: String),
         NONE
    
    var stringValue: String {
        switch self {
        case .CATEGORIES: return "categories"
        case .RECIPE_LIST(categoryName: let name): return "category/\(name)"
        case .RECIPE_DETAIL(recipeId: let recipeId): return "recipes/\(recipeId)"
        case .IMAGE(recipeId: let recipeId, thumb: let thumb): return "recipes/\(recipeId)/image?size=\(thumb ? "thumb" : "full")"
        case .NEW_RECIPE: return "recipes"
        case .CONFIG: return "config"
        case .KEYWORDS: return "keywords"
            
        case .LOGINV2REQ: return "/index.php/login/v2"
        case .CUSTOM(path: let path): return path
        case .NONE: return ""
        }
    }
}

struct RequestWrapper {
    private let _method: RequestMethod
    private let _path: RequestPath
    private let _headerFields: [HeaderField]
    private let _body: Data?
    private let _authenticate: Bool = true
    
    private init(
        method: RequestMethod,
        path: RequestPath,
        headerFields: [HeaderField] = [],
        body: Data? = nil,
        authenticate: Bool = true
    ) {
        self._method = method
        self._path = path
        self._headerFields = headerFields
        self._body = body
    }
    
    func getMethod() -> String {
        return self._method.rawValue
    }
    
    func getPath() -> String {
        return self._path.stringValue
    }
    
    func getHeaderFields() -> [HeaderField] {
        return self._headerFields
    }
    
    func getBody() -> Data? {
        return _body
    }
    
    func needsAuth() -> Bool {
        return _authenticate
    }
}

extension RequestWrapper {
    static func customRequest(
        method: RequestMethod,
        path: RequestPath,
        headerFields: [HeaderField] = [],
        body: Data? = nil,
        authenticate: Bool = true
    ) -> RequestWrapper {
        let request = RequestWrapper(
            method: method,
            path: path,
            headerFields: headerFields,
            body: body,
            authenticate: authenticate
        )
        return request
    }
    
    static func jsonGetRequest(path: RequestPath) -> RequestWrapper {
        let headerFields = [
            HeaderField.ocsRequest(value: true),
            HeaderField.accept(value: .JSON)
        ]
        let request = RequestWrapper(
            method: .GET,
            path: path,
            headerFields: headerFields,
            authenticate: true
        )
        return request
    }
    
    static func imageRequest(path: RequestPath) -> RequestWrapper {
        let headerFields = [
            HeaderField.ocsRequest(value: true),
            HeaderField.accept(value: .IMAGE)
        ]
        let request = RequestWrapper(
            method: .GET,
            path: path,
            headerFields: headerFields,
            authenticate: true
        )
        return request
    }
}


