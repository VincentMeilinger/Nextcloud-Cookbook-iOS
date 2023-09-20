//
//  NetworkHandler.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 13.09.23.
//

import Foundation



struct NetworkHandler {
    static func sendHTTPRequest(
        _ requestWrapper: RequestWrapper,
        hostPath: String,
        authString: String?
    ) async throws -> (Data?, NetworkError?) {
        print("Sending \(requestWrapper.getMethod()) request (path: \(requestWrapper.getPath())) ...")
        
        // Prepare URL
        let urlString = hostPath + requestWrapper.getPath()
        let urlStringSanitized = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let url = URL(string: urlStringSanitized!)!
        
        // Create URL request
        var request = URLRequest(url: url)
        
        // Set URL method
        request.httpMethod = requestWrapper.getMethod()
        
        // Set authentication string, if needed
        if let authString = authString {
            request.setValue(
                "Basic \(authString)",
                forHTTPHeaderField: "Authorization"
            )
        }
        
        // Set other header fields
        for headerField in requestWrapper.getHeaderFields() {
            request.setValue(
                headerField.getValue(),
                forHTTPHeaderField: headerField.getField()
            )
        }
        
        // Set http body
        if let body = requestWrapper.getBody() {
            request.httpBody = body
        }
        
        print("Request:\nMethod: \(request.httpMethod)\nHeaders: \(request.allHTTPHeaderFields)\nBody: \(request.httpBody)")
        
        // Wait for and return data and (decoded) response
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
    
    private static func decodeURLResponse(response: HTTPURLResponse?) -> NetworkError? {
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
}
