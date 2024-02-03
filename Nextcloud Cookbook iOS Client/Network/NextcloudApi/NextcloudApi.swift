//
//  NextcloudApi.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 16.11.23.
//

import Foundation

/// The `NextcloudApi` class provides functionalities to interact with the Nextcloud API, particularly for user authentication.
class NextcloudApi {
    
    /// Initiates the login process with Nextcloud using the Login Flow v2.
    ///
    /// This static function sends a POST request to the Nextcloud server to obtain a `LoginV2Request` object.
    /// The object contains necessary details for the second step of the authentication process.
    ///
    /// - Returns: A tuple containing an optional `LoginV2Request` and an optional `NetworkError`.
    ///   - `LoginV2Request?`: An object containing the necessary information for the second step of the login process, if successful.
    ///   - `NetworkError?`: An error encountered during the network request, if any.

    static func loginV2Request() async -> (LoginV2Request?, NetworkError?) {
        let path = UserSettings.shared.serverProtocol + UserSettings.shared.serverAddress
        let request = ApiRequest(
            path: path + "/index.php/login/v2",
            method: .POST
        )
        
        let (data, error) = await request.send(pathCompletion: false)
        
        if let error = error {
            return (nil, error)
        }
        guard let data = data else {
            return (nil, NetworkError.dataError)
        }
        guard let loginRequest: LoginV2Request = JSONDecoder.safeDecode(data) else {
            return (nil, NetworkError.decodingFailed)
        }
        return (loginRequest, nil)
    }
    
    /// Completes the user authentication process with Nextcloud using the Login Flow v2.
    ///
    /// This static function sends a POST request to the Nextcloud server with the login token obtained from `loginV2Request`.
    /// On successful validation of the token, it returns a `LoginV2Response` object, completing the user login.
    ///
    /// - Parameter req: A `LoginV2Request` object containing the token and endpoint information for the authentication request.
    ///
    /// - Returns: A tuple containing an optional `LoginV2Response` and an optional `NetworkError`.
    ///   - `LoginV2Response?`: An object representing the response of the login process, if successful.
    ///   - `NetworkError?`: An error encountered during the network request, if any.

    static func loginV2Response(req: LoginV2Request) async -> (LoginV2Response?, NetworkError?) {
        let request = ApiRequest(
            path: req.poll.endpoint,
            method: .POST,
            headerFields: [
                HeaderField.ocsRequest(value: true),
                HeaderField.accept(value: .JSON),
                HeaderField.contentType(value: .FORM)
            ],
            body: "token=\(req.poll.token)".data(using: .utf8)
        )
        let (data, error) = await request.send(pathCompletion: false)
        
        if let error = error {
            return (nil, error)
        }
        guard let data = data else {
            return (nil, NetworkError.dataError)
        }
        guard let loginResponse: LoginV2Response = JSONDecoder.safeDecode(data) else {
            return (nil, NetworkError.decodingFailed)
        }
        return (loginResponse, nil)
    }
}
