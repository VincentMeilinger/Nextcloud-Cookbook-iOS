//
//  NetworkRequests.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 13.09.23.
//

import Foundation

enum RequestMethod: String {
    case GET = "GET", POST = "POST", PUT = "PUT", DELETE = "DELETE"
}

enum RequestPath: String {
    case GET_CATEGORIES = "categories"
}

enum AcceptHeader: String {
    case JSON = "application/json", IMAGE = "image/jpeg"
}

struct RequestWrapper {
    let method: RequestMethod
    let path: String
    let accept: AcceptHeader
    let body: Codable?
    
    init(method: RequestMethod, path: String, body: Codable? = nil, accept: AcceptHeader = .JSON) {
        self.method = method
        self.path = path
        self.body = body
        self.accept = accept
    }
}


