//
//  ApiRequest.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 16.11.23.
//

import Foundation
import OSLog

struct ApiRequest {
    let path: String
    let method: RequestMethod
    let authString: String?
    let headerFields: [HeaderField]
    let body: Data?
            
    init(
        path: String,
        method: RequestMethod,
        authString: String? = nil,
        headerFields: [HeaderField] = [],
        body: Data? = nil
    ) {
        self.method = method
        self.path = path
        self.headerFields = headerFields
        self.authString = authString
        self.body = body
    }
    
    func send(pathCompletion: Bool = true) async -> (Data?, NetworkError?) {
        Logger.network.debug("\(method.rawValue) \(path) sending ...")
        
        // Prepare URL
        let urlString = pathCompletion ? UserSettings.shared.serverProtocol + UserSettings.shared.serverAddress + path : path
        print("Full path: \(urlString)")
        //Logger.network.debug("Full path: \(urlString)")
        guard let urlStringSanitized = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return (nil, .unknownError) }
        guard let url = URL(string: urlStringSanitized) else { return (nil, .unknownError) }
        
        // Create URL request
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        // Set authentication string, if needed
        if let authString = authString {
            request.setValue(
                "Basic \(authString)",
                forHTTPHeaderField: "Authorization"
            )
        }
        
        // Set other header fields
        for headerField in headerFields {
            request.setValue(
                headerField.getValue(),
                forHTTPHeaderField: headerField.getField()
            )
        }
        
        // Set http body
        if let body = body {
            request.httpBody = body
        }
                
        // Wait for and return data and (decoded) response
        var data: Data? = nil
        var response: URLResponse? = nil
        do {
            (data, response) = try await URLSession.shared.data(for: request)
            Logger.network.debug("\(method.rawValue) \(path) SUCCESS!")
            if let error = decodeURLResponse(response: response as? HTTPURLResponse) {
                print("\(method.rawValue) \(path) FAILURE: \(error.localizedDescription)")
                return (nil, error)
            }
            if let data = data {
                print(data, String(data: data, encoding: .utf8) as Any)
                return (data, nil)
            }
            return (nil, .unknownError)
        } catch {
            let error = decodeURLResponse(response: response as? HTTPURLResponse)
            Logger.network.debug("\(method.rawValue) \(path) FAILURE: \(error.debugDescription)")
            return (nil, error)
        }
    }
    
    private func decodeURLResponse(response: HTTPURLResponse?) -> NetworkError? {
        guard let response = response else {
            return NetworkError.unknownError
        }
        print("Status code: ", response.statusCode)
        switch response.statusCode {
            case 200...299: return (nil)
            case 300...399: return (NetworkError.redirectionError)
            case 400...499: return (NetworkError.clientError)
            case 500...599: return (NetworkError.serverError)
            case 600: return (NetworkError.invalidRequest)
            default: return (NetworkError.unknownError)
        }
    }
}
