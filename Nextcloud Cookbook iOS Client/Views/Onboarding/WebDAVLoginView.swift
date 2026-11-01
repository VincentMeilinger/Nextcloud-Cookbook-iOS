//
//  WebDAVLoginView.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Kofi Mandel on 29.10.26.
//

import Foundation
import SwiftUI



struct WebDAVLoginView: View {
    @Binding var showAlert: Bool
    @Binding var alertMessage: String
    @FocusState private var focusedField: Field?

    @State var userSettings = UserSettings.shared

    // TextField handling
    enum Field {
        case username
        case password
    }

    var body: some View {
        VStack(alignment: .leading) {
            ServerAddressField(example: "e.g.: example.com/remote.php/dav/files/user/Recipes")
            CollapsibleView {
                VStack(alignment: .leading) {
                    Text("Enter the full address of the WebDAV folder containing your recipes. Each recipe is stored in its own folder, in the same format as the Nextcloud Cookbook app uses.")
                        .padding(.bottom)
                    Text("For a Nextcloud server, the address has the form '<server address>/remote.php/dav/files/<user name>/Recipes'.")
                }
            } title: {
                Text("Show help")
                    .foregroundColor(.white)
                    .font(.headline)
            }.padding()

            LoginLabel(text: "User name")
            BorderedLoginTextField(example: "username", text: $userSettings.username)
                .focused($focusedField, equals: .username)
                .textContentType(.username)
                .submitLabel(.next)
                .padding(.bottom)

            LoginLabel(text: "Password")
            BorderedLoginTextField(example: "password", text: $userSettings.token, secure: true)
                .focused($focusedField, equals: .password)
                .textContentType(.password)
                .submitLabel(.join)
            HStack{
                Spacer()
                Button {
                    Task {
                        if await loginCheck() {
                            userSettings.onboarding = false
                        }
                    }
                } label: {
                    Text("Submit")
                        .foregroundColor(.white)
                        .font(.headline)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white, lineWidth: 2)
                                .foregroundColor(.clear)
                        )
                }
                .padding()
                Spacer()
            }
        }
        .onSubmit {
            switch focusedField {
            case .username:
                focusedField = .password
            default:
                print("Attempting to log in ...")
            }
        }
    }

    func loginCheck() async -> Bool {
        if userSettings.serverAddress == "" {
            alertMessage = String(localized: "Please enter a server address!")
            showAlert = true
            return false
        } else if userSettings.username == "" || userSettings.token == "" {
            alertMessage = String(localized: "Please enter a user name and password!")
            showAlert = true
            return false
        }

        UserSettings.shared.setAuthString()
        UserSettings.shared.serverType = .webdav
        let error = await CookbookApiWebDAV.validate(auth: UserSettings.shared.authString)

        if error == .notFound {
            alertMessage = String(localized: "Could not find a WebDAV folder at this address.")
            showAlert = true
            return false
        } else if error != nil {
            alertMessage = String(localized: "Login failed. Please check your inputs and internet connection.")
            showAlert = true
            return false
        }
        return true
    }
}
