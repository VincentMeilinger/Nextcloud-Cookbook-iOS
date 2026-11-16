// RecipePage.swift
// RecipeScraperKit

import Foundation
import SwiftSoup

/// A downloaded web page: its final URL (after redirects), the raw HTML and the
/// parsed document.
public struct RecipePage {
    public let url: URL
    public let html: String
    public let document: Document

    public init(url: URL, html: String) throws {
        self.url = url
        self.html = html
        self.document = try SwiftSoup.parse(html, url.absoluteString)
    }

    /// Downloads a page like a mobile browser would. Several recipe sites reject
    /// requests that don't look like they come from a browser.
    public static func download(_ url: URL, session: URLSession = .shared) async throws -> RecipePage {
        var request = URLRequest(url: url, timeoutInterval: 20)
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1",
            forHTTPHeaderField: "User-Agent"
        )
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.setValue(Self.acceptLanguage, forHTTPHeaderField: "Accept-Language")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw RecipeScraperError.network(error.localizedDescription)
        }
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw RecipeScraperError.httpStatus(http.statusCode)
        }
        let html = String(data: data, encoding: .utf8) ?? String(decoding: data, as: UTF8.self)
        do {
            return try RecipePage(url: response.url ?? url, html: html)
        } catch {
            throw RecipeScraperError.noRecipeFound
        }
    }

    private static var acceptLanguage: String {
        let preferred = Locale.preferredLanguages.prefix(3)
        return (preferred + ["en;q=0.5"]).joined(separator: ",")
    }

    /// Content of `<meta property="…">` or `<meta name="…">`, e.g. "og:image".
    public func meta(_ key: String) -> String? {
        let selector = "meta[property=\"\(key)\"], meta[name=\"\(key)\"]"
        let content = try? document.select(selector).first()?.attr("content")
        return content?.isEmpty == false ? content : nil
    }
}
