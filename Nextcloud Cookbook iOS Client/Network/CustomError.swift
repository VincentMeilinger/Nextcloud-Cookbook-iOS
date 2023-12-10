//
//  CustomError.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 13.09.23.
//

import Foundation

public enum NotImplementedError: Error, CustomStringConvertible {
    case notImplemented
    public var description: String {
        return "Function not implemented."
    }
}

public enum NetworkError: String, Error {
    case missingUrl = "Missing URL."
    case parametersNil = "Parameters are nil."
    case encodingFailed = "Parameter encoding failed."
    case decodingFailed = "Data decoding failed."
    case redirectionError = "Redirection error"
    case clientError = "Client error"
    case serverError = "Server error"
    case invalidRequest = "Invalid request"
    case unknownError = "Unknown error"
    case dataError = "Invalid data error."
}

