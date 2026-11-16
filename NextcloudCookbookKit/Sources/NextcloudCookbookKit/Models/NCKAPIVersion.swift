// NCKAPIVersion.swift
// NextcloudCookbookKit
//
// The Cookbook API version a server reports, e.g. 0.1.3.

import Foundation

/// The version of the Cookbook REST API a server implements, as `epoch.major.minor`.
///
/// The URL prefix follows the major version (`/api/v1` is major 1). Minor versions only
/// add to that API (new fields, endpoints, deprecations), so features introduced in a
/// minor version can be gated with a comparison:
///
/// ```swift
/// if client.apiVersion >= NCKAPIVersion(epoch: 0, major: 1, minor: 3) { ... }
/// ```
public struct NCKAPIVersion: Codable, Comparable, Hashable, Sendable, CustomStringConvertible {
    /// Bumped by upstream only to recover from badly numbered releases.
    public let epoch: Int
    public let major: Int
    public let minor: Int

    public init(epoch: Int, major: Int, minor: Int) {
        self.epoch = epoch
        self.major = major
        self.minor = minor
    }

    public static func < (lhs: NCKAPIVersion, rhs: NCKAPIVersion) -> Bool {
        (lhs.epoch, lhs.major, lhs.minor) < (rhs.epoch, rhs.major, rhs.minor)
    }

    public var description: String { "\(epoch).\(major).\(minor)" }
}

// MARK: - Response parsing

extension NCKAPIVersion {

    /// Reads `ocs.data.capabilities.cookbook.api_version` from the OCS capabilities
    /// response (API 0.1.3+). Returns `nil` when the server has no cookbook capability.
    static func fromCapabilities(_ data: Data) -> NCKAPIVersion? {
        struct Response: Decodable {
            struct OCS: Decodable {
                struct Payload: Decodable {
                    struct Capabilities: Decodable {
                        struct Cookbook: Decodable { let api_version: NCKAPIVersion }
                        let cookbook: Cookbook?
                    }
                    let capabilities: Capabilities
                }
                let data: Payload
            }
            let ocs: OCS
        }
        // PHP serialises an empty capability list as `[]`, which fails to decode;
        // that and any other shape mismatch mean "no cookbook capability".
        return (try? JSONDecoder().decode(Response.self, from: data))?.ocs.data.capabilities.cookbook?.api_version
    }

    /// Reads `api_version` from the deprecated `/apps/cookbook/api/version` response.
    static func fromVersionEndpoint(_ data: Data) throws -> NCKAPIVersion {
        struct Response: Decodable { let api_version: NCKAPIVersion }
        do {
            return try JSONDecoder().decode(Response.self, from: data).api_version
        } catch {
            throw NCKError.decodingFailed(underlying: error)
        }
    }
}
