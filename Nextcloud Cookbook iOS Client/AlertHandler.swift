//
//  AlertHandler.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 18.10.23.
//

import Foundation
import SwiftUI



class AlertHandler: ObservableObject {
    @Published var presentAlert: Bool = false
    var alert: AlertType = .GENERIC
    var alertAction: () -> () = {}
    
    func present(alert: AlertType, onConfirm: @escaping () -> () = {}) {
        self.alert = alert
        self.alertAction = onConfirm
        self.presentAlert = true
    }
    
    func dismiss() {
        self.alertAction = {}
        self.alert = .GENERIC
    }
}



enum AlertButton: LocalizedStringKey, Identifiable {
    var id: Self {
        return self
    }
    
    case OK = "Ok", DELETE = "Delete", CANCEL = "Cancel"
}



enum AlertType: Error {
    
    case NO_TITLE,
         DUPLICATE,
         UPLOAD_ERROR,
         CONFIRM_DELETE,
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
        case .CONFIRM_DELETE:
            return "This action is not reversible!"
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
        case .CONFIRM_DELETE:
            return "Delete recipe?"
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

