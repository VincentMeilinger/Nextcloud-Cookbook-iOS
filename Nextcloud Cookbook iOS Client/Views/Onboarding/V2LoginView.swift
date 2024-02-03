//
//  V2LoginView.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 21.11.23.
//

import Foundation
import SwiftUI

enum V2LoginStage: LoginStage {
    case login, validate
    
    func next() -> V2LoginStage {
        switch self {
        case .login: return .validate
        case .validate: return .validate
        }
    }
    
    func previous() -> V2LoginStage {
        switch self {
        case .login: return .login
        case .validate: return .login
        }
    }
}



struct V2LoginView: View {
    @Binding var showAlert: Bool
    @Binding var alertMessage: String
    
    @State var loginStage: V2LoginStage = .login
    @State var loginRequest: LoginV2Request? = nil
        
    // TextField handling
    enum Field {
        case server
        case username
        case token
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                ServerAddressField()
                CollapsibleView {
                    VStack(alignment: .leading) {
                        Text("Make sure to enter the server address in the form 'example.com', or \n'<server address>:<port>'\n when a non-standard port is used.")
                            .padding(.bottom)
                        Text("The 'Login' button will open a web browser. Please follow the login instructions provided there.\nAfter a successful login, return to this application and press 'Validate'.")
                            .padding(.bottom)
                        Text("If the login button does not open your browser, use the 'Copy Link' button and paste the link in your browser manually.")
                    }
                } title: {
                    Text("Show help")
                        .foregroundColor(.white)
                        .font(.headline)
                }.padding()
                
                if loginRequest != nil {
                    Button("Copy Link") {
                        UIPasteboard.general.string = loginRequest!.login
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding()
                }
                
                HStack {
                    Button {
                        if UserSettings.shared.serverAddress == "" {
                            alertMessage = "Please enter a valid server address."
                            showAlert = true
                            return
                        }
                        
                        Task {
                            let error = await sendLoginV2Request()
                            if let error = error {
                                alertMessage = "A network error occured (\(error.rawValue))."
                                showAlert = true
                            }
                            if let loginRequest = loginRequest {
                                await UIApplication.shared.open(URL(string: loginRequest.login)!)
                            } else {
                                alertMessage = "Unable to reach server. Please check your server address and internet connection."
                                showAlert = true
                            }
                        }
                        loginStage = loginStage.next()
                    } label: {
                        Text("Login")
                            .foregroundColor(.white)
                            .font(.headline)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white, lineWidth: 2)
                                    .foregroundColor(.clear)
                            )
                    }.padding()
                    
                    if loginStage == .validate {
                        Spacer()
                        
                        Button {
                            // fetch login v2 response
                            Task {
                                let (response, error) = await fetchLoginV2Response()
                                
                                if let error = error {
                                    alertMessage = "Login failed. Please login via the browser and try again. (\(error.rawValue))"
                                    showAlert = true
                                    return
                                }
                                guard let response = response else {
                                    alertMessage = "Login failed. Please login via the browser and try again."
                                    showAlert = true
                                    return
                                }
                                print("Login successful for user \(response.loginName)!")
                                UserSettings.shared.username = response.loginName
                                UserSettings.shared.token = response.appPassword
                                let loginString = "\(UserSettings.shared.username):\(UserSettings.shared.token)"
                                let loginData = loginString.data(using: String.Encoding.utf8)!
                                DispatchQueue.main.async {
                                    UserSettings.shared.authString = loginData.base64EncodedString()
                                }
                                UserSettings.shared.onboarding = false
                            }
                        } label: {
                            Text("Validate")
                                .foregroundColor(.white)
                                .font(.headline)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.white, lineWidth: 2)
                                        .foregroundColor(.clear)
                                )
                        }
                        .disabled(loginRequest == nil ? true : false)
                        .padding()
                    }
                }
            }
        }
    }
    
    func sendLoginV2Request() async -> NetworkError? {
        let (req, error) = await NextcloudApi.loginV2Request()
        self.loginRequest = req
        return error
    }
    
    func fetchLoginV2Response() async -> (LoginV2Response?, NetworkError?) {
        guard let loginRequest = loginRequest else { return (nil, .parametersNil) }
        return await NextcloudApi.loginV2Response(req: loginRequest)
    }
}
