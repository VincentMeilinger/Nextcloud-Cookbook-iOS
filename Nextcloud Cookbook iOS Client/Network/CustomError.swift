//
//  CustomError.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 13.09.23.
//

import Foundation
import SwiftUI

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

public enum ServerError: Error {
    case unknownError, missingRequestBody, duplicateRecipe, noImage, missingRecipeName, recipeNotFound, deleteFailed, requestUnsuccessful
    
    
    static func decodeFromURLResponse(response: HTTPURLResponse?) -> ServerError? {
        guard let response = response else {
            return ServerError.unknownError
        }
        print("Status code: ", response.statusCode)
        switch response.statusCode {
            case 200...299: return nil
            case 400: return .missingRequestBody
            case 404: return .recipeNotFound
            case 409: return .duplicateRecipe
            case 406: return .noImage
            case 422: return .missingRecipeName
            case 500: return .requestUnsuccessful
            case 502: return .deleteFailed
            default: return ServerError.unknownError
        }
    }
    
    var localizedDescription: LocalizedStringKey {
        switch self {
            case .noImage: return "The recipe has no image whose MIME type matches the Accept header"
            case .missingRecipeName: return "There was no name in the request given for the recipe. Cannot save the recipe."
            default: return "An unknown server error occured."
        }
    }
    
    var localizedTitle: LocalizedStringKey {
        switch self {
        case .missingRequestBody: return "Missing Request Body"
        case .duplicateRecipe: return "Duplicate Recipe"
        case .noImage: return "Image MIME Error"
        case .missingRecipeName: return "Missing Name"
        default: return "Error"
        }
    }
}
