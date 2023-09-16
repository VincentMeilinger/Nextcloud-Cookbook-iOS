//
//  CustomError.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 13.09.23.
//

import Foundation

public enum NotImplementedError: Error, CustomStringConvertible {
    case notImplemented
    public var description: String {
        return "Function not implemented."
    }
}
