//
//  WebDAVClient.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Kofi Mandel on 29.10.26.
//

import Foundation
import OSLog


/// A file or folder returned by a WebDAV PROPFIND request.
struct WebDAVResource {
    let url: URL
    let isCollection: Bool
    let etag: String?
    let lastModified: Date?
    /// The Nextcloud/ownCloud file id. Only reported by servers supporting the `oc:fileid` property.
    let fileId: Int?

    var name: String { url.lastPathComponent }
}

/// A file downloaded via WebDAV.
struct WebDAVFile {
    let data: Data
    let etag: String?
    let lastModified: Date?
}

/// The result of a (conditional) WebDAV GET request.
enum WebDAVGetResult {
    case file(WebDAVFile)
    case notModified
}


/// A minimal WebDAV client, used to access recipes stored on a plain WebDAV server.
struct WebDAVClient {
    /// The URL of the WebDAV folder containing the recipe folders. Always ends with a slash.
    let rootURL: URL
    let authString: String

    private static let propfindBody = """
        <?xml version="1.0" encoding="utf-8"?>
        <d:propfind xmlns:d="DAV:" xmlns:oc="http://owncloud.org/ns">
          <d:prop>
            <d:resourcetype/>
            <d:getetag/>
            <d:getlastmodified/>
            <oc:fileid/>
          </d:prop>
        </d:propfind>
        """

    /// Creates a client for the WebDAV folder configured in the user settings.
    static func current(auth: String) -> WebDAVClient? {
        guard let rootURL = rootURL(from: UserSettings.shared.serverProtocol + UserSettings.shared.serverAddress) else {
            return nil
        }
        return WebDAVClient(rootURL: rootURL, authString: auth)
    }

    /// Parses a user entered folder address into a URL ending with a slash.
    static func rootURL(from string: String) -> URL? {
        var urlString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !urlString.isEmpty else { return nil }
        if !urlString.hasSuffix("/") {
            urlString += "/"
        }
        if let url = URL(string: urlString), url.host != nil {
            return url
        }
        guard let encoded = urlString.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: encoded), url.host != nil
        else { return nil }
        return url
    }

    /// Returns the URL of the folder with the specified name inside the root folder.
    func folderURL(named name: String) -> URL {
        rootURL.appendingPathComponent(name, isDirectory: true)
    }


    // MARK: - Requests

    /// List a file or folder (depth 0), or a folder and its direct children (depth 1).
    func propfind(_ url: URL, depth: Int) async -> ([WebDAVResource]?, NetworkError?) {
        var request = makeRequest(url, method: .PROPFIND)
        request.setValue("\(depth)", forHTTPHeaderField: "Depth")
        request.setValue(ContentType.XML.rawValue, forHTTPHeaderField: "Content-Type")
        request.httpBody = Self.propfindBody.data(using: .utf8)

        let (data, response, error) = await send(request)
        if let error = error { return (nil, error) }
        guard let data = data, response?.statusCode == 207 else { return (nil, .dataError) }
        return (WebDAVMultiStatusParser.parse(data, baseURL: url), nil)
    }

    /// Download a file. If an etag is specified and the file did not change, `.notModified` is returned.
    func get(_ url: URL, ifNoneMatch etag: String? = nil) async -> (WebDAVGetResult?, NetworkError?) {
        var request = makeRequest(url, method: .GET)
        if let etag = etag {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }

        let (data, response, error) = await send(request, allowedStatusCodes: [304])
        if let error = error { return (nil, error) }
        guard let response = response else { return (nil, .unknownError) }
        if response.statusCode == 304 {
            return (.notModified, nil)
        }
        let file = WebDAVFile(
            data: data ?? Data(),
            etag: response.value(forHTTPHeaderField: "ETag"),
            lastModified: response.value(forHTTPHeaderField: "Last-Modified").flatMap(WebDAVMultiStatusParser.parseDate)
        )
        return (.file(file), nil)
    }

    /// Upload a file, replacing it if it already exists.
    func put(_ url: URL, data: Data, contentType: ContentType) async -> NetworkError? {
        var request = makeRequest(url, method: .PUT)
        request.setValue(contentType.rawValue, forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        return await send(request).2
    }

    /// Create a folder. Returns `.alreadyExists` if there already is a file or folder at the given URL.
    func mkcol(_ url: URL) async -> NetworkError? {
        let (_, response, error) = await send(makeRequest(url, method: .MKCOL), allowedStatusCodes: [405])
        if response?.statusCode == 405 { return .alreadyExists }
        return error
    }

    /// Delete a file or folder, including its contents.
    func delete(_ url: URL) async -> NetworkError? {
        return await send(makeRequest(url, method: .DELETE)).2
    }

    private func makeRequest(_ url: URL, method: RequestMethod) -> URLRequest {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        request.httpMethod = method.rawValue
        request.setValue("Basic \(authString)", forHTTPHeaderField: "Authorization")
        return request
    }

    private func send(_ request: URLRequest, allowedStatusCodes: Set<Int> = []) async -> (Data?, HTTPURLResponse?, NetworkError?) {
        let method = request.httpMethod ?? ""
        let path = request.url?.path ?? ""
        Logger.network.debug("WebDAV \(method) \(path) sending ...")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else { return (nil, nil, .unknownError) }
            if allowedStatusCodes.contains(response.statusCode) {
                return (data, response, nil)
            }
            if let error = Self.decodeStatusCode(response.statusCode) {
                Logger.network.debug("WebDAV \(method) \(path) FAILURE: \(response.statusCode)")
                return (nil, response, error)
            }
            return (data, response, nil)
        } catch {
            Logger.network.debug("WebDAV \(method) \(path) FAILURE: \(error.localizedDescription)")
            return (nil, nil, .unknownError)
        }
    }

    private static func decodeStatusCode(_ statusCode: Int) -> NetworkError? {
        switch statusCode {
        case 200...299: return nil
        case 300...399: return .redirectionError
        case 404: return .notFound
        case 400...499: return .clientError
        case 500...599: return .serverError
        default: return .unknownError
        }
    }
}



// MARK: - PROPFIND response parsing

/// Parses a WebDAV multistatus (207) response body into a list of resources.
class WebDAVMultiStatusParser: NSObject, XMLParserDelegate {
    private static let davNamespace = "DAV:"
    private static let ownCloudNamespace = "http://owncloud.org/ns"

    private let baseURL: URL
    private var resources: [WebDAVResource] = []

    // Properties of the response element currently being parsed
    private var href: String?
    private var isCollection = false
    private var etag: String?
    private var lastModified: Date?
    private var fileId: Int?
    private var text = ""

    private init(baseURL: URL) {
        self.baseURL = baseURL
    }

    /// - Parameters:
    ///   - data: The response body.
    ///   - baseURL: The URL the request was sent to. Used to resolve relative hrefs.
    static func parse(_ data: Data, baseURL: URL) -> [WebDAVResource] {
        let delegate = WebDAVMultiStatusParser(baseURL: baseURL)
        let parser = XMLParser(data: data)
        parser.shouldProcessNamespaces = true
        parser.delegate = delegate
        parser.parse()
        return delegate.resources
    }

    static func parseDate(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        return formatter.date(from: string.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        text = ""
        if namespaceURI == Self.davNamespace {
            switch elementName {
            case "response":
                href = nil
                isCollection = false
                etag = nil
                lastModified = nil
                fileId = nil
            case "collection":
                isCollection = true
            default: break
            }
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        text += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        text = ""

        if namespaceURI == Self.ownCloudNamespace && elementName == "fileid" {
            fileId = Int(value)
            return
        }
        guard namespaceURI == Self.davNamespace else { return }
        switch elementName {
        case "href":
            href = value
        case "getetag":
            etag = value.isEmpty ? nil : value
        case "getlastmodified":
            lastModified = Self.parseDate(value)
        case "response":
            if let href = href, let url = resolve(href) {
                resources.append(WebDAVResource(
                    url: url,
                    isCollection: isCollection,
                    etag: etag,
                    lastModified: lastModified,
                    fileId: fileId
                ))
            }
        default: break
        }
    }

    /// Resolves an href, which is either an absolute path or a full URL, against the base URL.
    private func resolve(_ href: String) -> URL? {
        if let url = URL(string: href, relativeTo: baseURL) {
            return url.absoluteURL
        }
        guard let encoded = href.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else { return nil }
        return URL(string: encoded, relativeTo: baseURL)?.absoluteURL
    }
}
