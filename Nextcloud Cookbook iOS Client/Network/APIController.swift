//
//  APIController.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 20.09.23.
//

import Foundation

class APIController {
    var userSettings: UserSettings
    
    var apiPath: String
    var authString: String
    let apiVersion = "1"
    
    init(userSettings: UserSettings) {
        print("Initializing APIController.")
        self.userSettings = userSettings
        
        self.apiPath = "https://\(userSettings.serverAddress)/index.php/apps/cookbook/api/v\(apiVersion)/"
        
        let loginString = "\(userSettings.username):\(userSettings.token)"
        let loginData = loginString.data(using: String.Encoding.utf8)!
        self.authString = loginData.base64EncodedString()
    }
}



extension APIController {
    func imageDataFromServer(recipeId: Int, thumb: Bool) async -> Data? {
        do {
            let request = RequestWrapper.imageRequest(path: .IMAGE(recipeId: recipeId, thumb: thumb))
            let (data, _): (Data?, Error?) = try await NetworkHandler.sendHTTPRequest(
                request,
                hostPath: apiPath,
                authString: authString
            )
            guard let data = data else {
                print("Error receiving or decoding data.")
                return nil
            }
            return data
        } catch {
            print("Could not load image from server.")
        }
        return nil
    }
    
    func sendDataRequest<D: Decodable>(_ request: RequestWrapper) async -> (D?, Error?) {
        do {
            let (data, error) = try await NetworkHandler.sendHTTPRequest(
                request,
                hostPath: apiPath,
                authString: authString
            )
            if let data = data {
                return (JSONDecoder.safeDecode(data), error)
            }
            return (nil, error)
        } catch {
            print("An unknown network error occured.")
        }
        return (nil, NetworkError.unknownError)
    }
    
    func sendRequest(_ request: RequestWrapper) async -> Error? {
        do {
            return try await NetworkHandler.sendHTTPRequest(
                request,
                hostPath: apiPath,
                authString: authString
            ).1
        } catch {
            print("An unknown network error occured.")
        }
        return NetworkError.unknownError
    }
}
