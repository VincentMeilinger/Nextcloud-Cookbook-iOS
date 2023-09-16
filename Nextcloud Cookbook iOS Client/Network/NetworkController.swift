//
//  NetworkController.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 13.09.23.
//

import Foundation

public enum NetworkError: String, Error {
    case missingUrl = "Missing URL."
    case parametersNil = "Parameters are nil."
    case encodingFailed = "Parameter encoding failed."
    case redirectionError = "Redirection error"
    case clientError = "Client error"
    case serverError = "Server error"
    case invalidRequest = "Invalid request"
    case unknownError = "Unknown error"
    case dataError = "Invalid data error."
}

class NetworkController {
    var userSettings: UserSettings
    var authString: String
    var urlString: String
    
    let apiVersion = "1"
    
    init() {
        print("Initializing NetworkController.")
        self.userSettings = UserSettings()
        self.urlString = "https://\(userSettings.serverAddress)/index.php/apps/cookbook/api/v\(apiVersion)"
        
        let loginString = "\(userSettings.username):\(userSettings.token)"
        let loginData = loginString.data(using: String.Encoding.utf8)!
        self.authString = loginData.base64EncodedString()
    }
    
    func fetchData(path: String) async throws -> Data? {
        
        let url = URL(string: "\(urlString)/\(path)")!
        
        var request = URLRequest(url: url)
        
        request.httpMethod = "GET"
        request.setValue(
            "true",
            forHTTPHeaderField: "OCS-APIRequest"
        )
        request.setValue(
            "Basic \(authString)",
            forHTTPHeaderField: "Authorization"
        )
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            return data
        } catch {
            
            return nil
        }
    }
    
    func sendHTTPRequest(path: String, _ requestWrapper: RequestWrapper) async throws -> (Data?, NetworkError?) {
        print("Sending \(requestWrapper.method.rawValue) request (path: \(path)) ...")
        let urlStringSanitized = "\(urlString)/\(path)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let url = URL(string: urlStringSanitized!)!
        var request = URLRequest(url: url)
        request.setValue(
            "true",
            forHTTPHeaderField: "OCS-APIRequest"
        )
        request.setValue(
            "Basic \(authString)",
            forHTTPHeaderField: "Authorization"
        )
        
        request.setValue(
            requestWrapper.accept.rawValue,
            forHTTPHeaderField: "Accept"
        )
        
        request.httpMethod = requestWrapper.method.rawValue
        
        switch requestWrapper.method {
        case .GET: break
        case .POST, .PUT:
            guard let httpBody = requestWrapper.body else { return (nil, nil) }
            do {
                print("Encoding request ...")
                request.httpBody = try JSONEncoder().encode(httpBody)
                print("Request body: \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "nil")")
            } catch {
                throw error
            }
        case .DELETE: throw NotImplementedError.notImplemented
        }
        
        var data: Data? = nil
        var response: URLResponse? = nil
        do {
            (data, response) = try await URLSession.shared.data(for: request)
            print("Response: ", response)
            return (data, nil)
        } catch {
            return (nil, decodeURLResponse(response: response as? HTTPURLResponse))
        }
    }
    
    private func decodeURLResponse(response: HTTPURLResponse?) -> NetworkError? {
        guard let response = response else {
            return NetworkError.unknownError
        }
        switch response.statusCode {
            case 200...299: return (nil)
            case 300...399: return (NetworkError.redirectionError)
            case 400...499: return (NetworkError.clientError)
            case 500...599: return (NetworkError.serverError)
            case 600: return (NetworkError.invalidRequest)
            default: return (NetworkError.unknownError)
        }
    }
    
    func sendDataRequest<D: Decodable>(_ request: RequestWrapper) async -> (D?, Error?) {
        do {
            let (data, error) = try await sendHTTPRequest(path: request.path, request)
            if let data = data {
                return (decodeData(data), error)
            }
            return (nil, error)
        } catch {
            print("An unknown network error occured.")
        }
        return (nil, NetworkError.unknownError)
    }
    
    func sendRequest(_ request: RequestWrapper) async -> Error? {
        do {
            return try await sendHTTPRequest(path: request.path, request).1
        } catch {
            print("An unknown network error occured.")
        }
        return NetworkError.unknownError
    }
    
    private func decodeData<D: Decodable>(_ data: Data) -> D? {
        let decoder = JSONDecoder()
        do {
            print("Decoding type ", D.self, " ...")
            return try decoder.decode(D.self, from: data)
        } catch (let error) {
            print("DataController - decodeData(): Failed to decode data.")
            print("Error: ", error)
            return nil
        }
    }
}



