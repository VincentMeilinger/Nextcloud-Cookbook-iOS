//
//  JSONCoderExtension.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 20.09.23.
//

import Foundation

extension JSONDecoder {
    static func safeDecode<T: Decodable>(_ data: Data) -> T? {
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(T.self, from: data)
        } catch (let error) {
            print(error)
            return nil
        }
    }
}

extension JSONEncoder {
    static func safeEncode<T: Encodable>(_ object: T) -> Data? {
        do {
            return try JSONEncoder().encode(object)
        } catch {
            print("JSONDecoder - safeEncode(): Could not encode object \(T.self)")
        }
        return nil
    }
}
