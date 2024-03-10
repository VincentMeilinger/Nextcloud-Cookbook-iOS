//
//  AlertHandler.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 18.10.23.
//

import Foundation
import SwiftUI


protocol UserAlert: Error { 
    var localizedTitle: LocalizedStringKey { get }
    var localizedDescription: LocalizedStringKey { get }
    var alertButtons: [AlertButton] { get }
}

enum AlertButton: LocalizedStringKey, Identifiable {
    var id: Self {
        return self
    }
    
    case OK = "Ok", DELETE = "Delete", CANCEL = "Cancel"
}



enum RecipeAlert: UserAlert {
    
    case NO_TITLE,
         DUPLICATE,
         UPLOAD_ERROR,
         UPLOAD_SUCCESS,
         CONFIRM_DELETE,
         DELETE_SUCCESS,
         LOGIN_FAILED,
         GENERIC,
         CUSTOM(title: LocalizedStringKey, description: LocalizedStringKey)
    
    var localizedDescription: LocalizedStringKey {
        switch self {
        case .NO_TITLE:
            return "Please enter a recipe name."
        case .DUPLICATE:
            return "A recipe with that name already exists."
        case .UPLOAD_ERROR:
            return "Unable to upload your recipe. Please check your internet connection."
        case .UPLOAD_SUCCESS:
            return "Recipe upload successful."
        case .CONFIRM_DELETE:
            return "This action is not reversible!"
        case .DELETE_SUCCESS:
            return "Deletion successful."
        case .LOGIN_FAILED:
            return "Please check your credentials and internet connection."
        case .CUSTOM(title: _, description: let description):
            return description
        default:
            return "An unknown error occured."
        }
    }
    
    var localizedTitle: LocalizedStringKey {
        switch self {
        case .NO_TITLE:
            return "Missing recipe name."
        case .DUPLICATE:
            return "Duplicate recipe."
        case .UPLOAD_ERROR:
            return "Network error."
        case .UPLOAD_SUCCESS:
            return "Success!"
        case .CONFIRM_DELETE:
            return "Delete recipe?"
        case .DELETE_SUCCESS:
            return "Success!"
        case .LOGIN_FAILED:
            return "Login failed."
        case .CUSTOM(title: let title, description: _):
            return title
        default:
            return "Error."
        }
    }
    
    var alertButtons: [AlertButton] {
        switch self {
        case .CONFIRM_DELETE:
            return [.CANCEL, .DELETE]
        default:
            return [.OK]
        }
    }
}


enum RecipeImportAlert: UserAlert {
    case BAD_URL,
         CHECK_CONNECTION,
         WEBSITE_NOT_SUPPORTED
    
    var localizedDescription: LocalizedStringKey {
        switch self {
        case .BAD_URL: return "Please check the entered URL."
        case .CHECK_CONNECTION: return "Unable to load website content. Please check your internet connection."
        case .WEBSITE_NOT_SUPPORTED: return "This website might not be currently supported. If this appears incorrect, you can use the support options in the app settings to raise awareness about this issue."
        }
    }
    
    var localizedTitle: LocalizedStringKey {
        switch self {
        case .BAD_URL: return "Bad URL"
        case .CHECK_CONNECTION: return "Connection error"
        case .WEBSITE_NOT_SUPPORTED: return "Parsing error"
        }
    }
    
    var alertButtons: [AlertButton] {
        return [.OK]
    }
}


enum RequestAlert: UserAlert {
    case REQUEST_DELAYED,
         REQUEST_DROPPED,
         REQUEST_SUCCESS
    
    var localizedDescription: LocalizedStringKey {
        switch self {
        case .REQUEST_DELAYED: return "Could not establish a connection to the server. The action will be retried upon reconnection."
        case .REQUEST_DROPPED: return "Unable to complete action."
        case .REQUEST_SUCCESS: return ""
        }
    }
    
    var localizedTitle: LocalizedStringKey {
        switch self {
        case .REQUEST_DELAYED: return "Action delayed"
        case .REQUEST_DROPPED: return "Error"
        case .REQUEST_SUCCESS: return "Success!"
        }
    }
    
    var alertButtons: [AlertButton] {
        return [.OK]
    }
}
