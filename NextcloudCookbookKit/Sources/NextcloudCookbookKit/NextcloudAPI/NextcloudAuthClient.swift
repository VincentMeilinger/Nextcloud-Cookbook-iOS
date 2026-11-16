// NextcloudAuthClient.swift
// NextcloudCookbookKit
//
// Handles Nextcloud Login Flow v2 and basic user-info endpoints.
// These do not require Cookbook API version knowledge, so they live
// in a separate client.

import Foundation

public final class NextcloudAuthClient: Sendable {

    private let http: NCKHTTPClient

    /// - Parameter serverURL: The root URL of the Nextcloud server.
    ///   Credentials are not needed here — this client is used to *obtain* them.
    public init(serverURL: URL) {
        self.http = NCKHTTPClient(baseURL: serverURL, credentials: nil)
    }

    // MARK: - Login Flow v2

    /// Step 1 — POST to `/index.php/login/v2` to receive a poll endpoint and
    /// a browser login URL that the user must visit to grant access.
    public func loginV2Request() async throws -> NCKLoginV2Request {
        let data = try await http.send(
            path: "/index.php/login/v2",
            method: .POST,
            headers: ["OCS-APIRequest": "true", "Accept": "application/json"]
        )
        do {
            return try JSONDecoder().decode(NCKLoginV2Request.self, from: data)
        } catch {
            throw NCKError.decodingFailed(underlying: error)
        }
    }

    /// Step 2 — Poll the endpoint returned from step 1 until the user has
    /// completed the browser login. Returns the final app-password credentials.
    public func loginV2Response(token: String, pollEndpoint: String) async throws -> NCKLoginV2Response {
        // Percent-encode the token for application/x-www-form-urlencoded; only unreserved chars are safe.
        let allowed = CharacterSet.alphanumerics.union(.init(charactersIn: "-._~"))
        let encodedToken = token.addingPercentEncoding(withAllowedCharacters: allowed) ?? token
        let body = "token=\(encodedToken)".data(using: .utf8)!
        let data = try await http.send(
            path: pollEndpoint,
            method: .POST,
            headers: [
                "OCS-APIRequest": "true",
                "Accept": "application/json",
                "Content-Type": "application/x-www-form-urlencoded",
            ],
            body: body,
            absolutePath: true
        )
        do {
            return try JSONDecoder().decode(NCKLoginV2Response.self, from: data)
        } catch {
            throw NCKError.decodingFailed(underlying: error)
        }
    }

    // MARK: - User info

    /// Fetches the user's avatar as raw JPEG/PNG data.
    /// - Parameters:
    ///   - username: The Nextcloud user ID.
    ///   - size: Pixel size of the avatar (e.g. 64, 100).
    ///   - credentials: Base64-encoded Basic auth credentials.
    public func getAvatar(username: String, size: Int, credentials: String) async throws -> Data {
        let authedHTTP = NCKHTTPClient(baseURL: http.baseURL, credentials: credentials)
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove(charactersIn: "/")
        let encodedUsername = username.addingPercentEncoding(withAllowedCharacters: allowed) ?? username
        return try await authedHTTP.getData(
            path: "/index.php/avatar/\(encodedUsername)/\(size)",
            headers: ["OCS-APIRequest": "true", "Accept": "image/jpeg"]
        )
    }

    /// Fetches hover-card info (display name, user ID) for the logged-in user.
    /// - Parameters:
    ///   - username: The Nextcloud user ID.
    ///   - credentials: Base64-encoded Basic auth credentials.
    public func getHoverCard(username: String, credentials: String) async throws -> NCKUserData {
        let authedHTTP = NCKHTTPClient(baseURL: http.baseURL, credentials: credentials)
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove(charactersIn: "/")
        let encodedUsername = username.addingPercentEncoding(withAllowedCharacters: allowed) ?? username
        let data = try await authedHTTP.getData(
            path: "/ocs/v2.php/hovercard/v1/\(encodedUsername)",
            headers: ["OCS-APIRequest": "true", "Accept": "application/json"]
        )
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let ocsData = (json?["ocs"] as? [String: Any])?["data"] as? [String: Any]
            return NCKUserData(
                userId: ocsData?["userId"] as? String ?? "",
                displayName: ocsData?["displayName"] as? String ?? ""
            )
        } catch {
            throw NCKError.decodingFailed(underlying: error)
        }
    }
}
