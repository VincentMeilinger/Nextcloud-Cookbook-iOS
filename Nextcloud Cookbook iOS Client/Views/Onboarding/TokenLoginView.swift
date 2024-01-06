//
//  TokenLoginView.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 21.11.23.
//

import Foundation
import SwiftUI



struct TokenLoginView: View {
    @Binding var showAlert: Bool
    @Binding var alertMessage: String
    @FocusState private var focusedField: Field?
    
    @State var userSettings = UserSettings.shared
    
    // TextField handling
    enum Field {
        case server
        case username
        case token
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            /*LoginLabel(text: "Server address")
            LoginTextField(example: "e.g.: example.com", text: $userSettings.serverAddress)
                .focused($focusedField, equals: .server)
                .textContentType(.URL)
                .submitLabel(.next)
                .padding(.bottom)
            */
            ServerAddressField(addressString: $userSettings.serverAddress)
            LoginLabel(text: "User name")
            BorderedLoginTextField(example: "username", text: $userSettings.username)
                .focused($focusedField, equals: .username)
                .textContentType(.username)
                .submitLabel(.next)
                .padding(.bottom)
            
            
            LoginLabel(text: "App Token")
            BorderedLoginTextField(example: "can be generated in security settings of your nextcloud", text: $userSettings.token)
                .focused($focusedField, equals: .token)
                .textContentType(.password)
                .submitLabel(.join)
            HStack{
                Spacer()
                Button {
                    Task {
                        if await loginCheck(nextcloudLogin: false) {
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
            case .server:
                focusedField = .username
            case .username:
                focusedField = .token
            default:
                print("Attempting to log in ...")
            }
        }
    }
    
    func loginCheck(nextcloudLogin: Bool) async -> Bool {
        if userSettings.serverAddress == "" {
            alertMessage = "Please enter a server address!"
            showAlert = true
            return false
        } else if !nextcloudLogin && (userSettings.username == "" || userSettings.token == "") {
            alertMessage = "Please enter a user name and app token!"
            showAlert = true
            return false
        }
        let headerFields = [
            HeaderField.ocsRequest(value: true),
        ]
        let request = RequestWrapper.customRequest(
            method: .GET,
            path: .CATEGORIES,
            headerFields: headerFields,
            authenticate: true
        )
        
        var (data, error): (Data?, Error?) = (nil, nil)
        do {
            let loginString = "\(userSettings.username):\(userSettings.token)"
            let loginData = loginString.data(using: String.Encoding.utf8)!
            let authString = loginData.base64EncodedString()
            DispatchQueue.main.async {
                userSettings.authString = authString
            }
            (data, error) = try await NetworkHandler.sendHTTPRequest(
                request,
                hostPath: "https://\(userSettings.serverAddress)/index.php/apps/cookbook/api/v1/",
                authString: authString
            )
            
        } catch {
            print("Error: ", error)
        }
        guard let data = data else {
            alertMessage = "Login failed. Please check your inputs."
            showAlert = true
            return false
        }
        if let testRequest: [Category] = JSONDecoder.safeDecode(data) {
            print("validationResponse: \(testRequest)")
            return true
        }
        alertMessage = "Login failed. Please check your inputs and internet connection."
        showAlert = true
        return false
    }
}
