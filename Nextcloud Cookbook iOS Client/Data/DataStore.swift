//
//  DataController.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 15.09.23.
//

import Foundation
import SwiftUI

class DataStore {
    private static func fileURL(appending: String) throws -> URL {
        try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )

        .appendingPathComponent(appending)
    }
    
    func load<D: Decodable>(fromPath path: String) async throws -> D? {
        let task = Task<D?, Error> {
            let fileURL = try Self.fileURL(appending: path)
            guard let data = try? Data(contentsOf: fileURL) else {
                return nil
            }
            let storedRecipes = try JSONDecoder().decode(D.self, from: data)
            return storedRecipes
        }
        return try await task.value
    }
    
    func save<D: Encodable>(data: D, toPath path: String) async throws {
        let task = Task {
            let data = try JSONEncoder().encode(data)
            let outfile = try Self.fileURL(appending: path)
            try data.write(to: outfile)
        }
        _ = try await task.value
    }
    
    func clearAll() {
        do {
            try FileManager.default.removeItem(at: Self.fileURL(appending: ""))
        } catch {
            print("Could not delete file, probably read-only filesystem")
        }
    }
    
}


