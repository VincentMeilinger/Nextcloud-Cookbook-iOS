//
//  DataController.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 15.09.23.
//

import Foundation
import SwiftUI

class DataStore {
    let fileManager = FileManager.default
    
    
    private static func fileURL(appending: String) throws -> URL {
        try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )
        .appendingPathComponent(appending)
    }
    
    private static func fileURL() throws -> URL {
        try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )
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
    
    func save<D: Encodable>(data: D, toPath path: String) async {
        let task = Task {
            let data = try JSONEncoder().encode(data)
            let outfile = try Self.fileURL(appending: path)
            try data.write(to: outfile)
        }
        do {
            _ = try await task.value
        } catch {
            print("Could not save data (path: \(path)")
        }
    }
    
    func recipeDetailExists(recipeId: Int) -> Bool {
        let filePath = "recipe\(recipeId).data"
        guard let folderPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.path() else { return false }
        return fileManager.fileExists(atPath: folderPath + filePath)
    }
    
    func clearAll() -> Bool {
        print("Attempting to delete all data ...")
        guard let folderPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.path() else { return false }
        print("Folder path: ", folderPath)
        do {
            let filePaths = try fileManager.contentsOfDirectory(atPath: folderPath)
            for filePath in filePaths {
                print("File path: ", filePath)
                try fileManager.removeItem(atPath: folderPath + filePath)
            }
        } catch {
            print("Could not delete documents folder contents: \(error)")
            return false
        }
        print("Done.")
        return true
        
    }
    
}


