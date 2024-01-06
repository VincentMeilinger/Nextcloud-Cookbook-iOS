//
//  V2LoginView.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 21.11.23.
//

import Foundation
import SwiftUI

enum V2LoginStage: LoginStage {
    case serverAddress, login, validate
    
    func next() -> V2LoginStage {
        switch self {
        case .serverAddress: return .login
        case .login: return .validate
        case .validate: return .validate
        }
    }
    
    func previous() -> V2LoginStage {
        switch self {
        case .serverAddress: return .serverAddress
        case .login: return .serverAddress
        case .validate: return .login
        }
    }
}



struct V2LoginView: View {
    @Binding var showAlert: Bool
    @Binding var alertMessage: String
    
    @State var loginStage: V2LoginStage = .serverAddress
    @State var loginRequest: LoginV2Request? = nil
    @FocusState private var focusedField: Field?
    
    @State var userSettings = UserSettings.shared
    
    // TextField handling
    enum Field {
        case server
        case username
        case token
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                /*LoginLabel(text: "Server address")
                    .padding()
                LoginTextField(example: "e.g.: example.com", text: $userSettings.serverAddress, color: loginStage == .serverAddress ? .white : .secondary)
                    .focused($focusedField, equals: .server)
                    .textContentType(.URL)
                    .submitLabel(.done)
                    .padding([.bottom, .horizontal])
                    .onSubmit {
                        withAnimation(.easeInOut) {
                            loginStage = loginStage.next()
                        }
                    }
                */
                ServerAddressField(addressString: $userSettings.serverAddress)
                CollapsibleView {
                    VStack(alignment: .leading) {
                        Text("Make sure to enter the server address in the form 'example.com'. Currently, only servers using the 'https' protocol are supported.")
                        if let loginRequest = loginRequest {
                            Text("If the login button does not open your browser, copy the following link and paste it in your browser manually:")
                            Text(loginRequest.login)
                        }
                    }
                } title: {
                    Text("Show help")
                        .foregroundColor(.white)
                        .font(.headline)
                }.padding()
                
                if loginStage == .login || loginStage == .validate {
                    Text("The 'Login' button will open a web browser. Please follow the login instructions provided there.\nAfter a successful login, return to this application and press 'Validate'.")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .padding()
                }
                HStack {
                    if loginStage == .login || loginStage == .validate {
                        Button {
                            if userSettings.serverAddress == "" {
                                alertMessage = "Please enter a valid server address."
                                showAlert = true
                                return
                            }
                            
                            Task {
                                await sendLoginV2Request()
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
                    }
                    if loginStage == .validate {
                        Spacer()
                        
                        Button {
                            // fetch login v2 response
                            Task {
                                guard let res = await fetchLoginV2Response() else {
                                    alertMessage = "Login failed. Please login via the browser and try again."
                                    showAlert = true
                                    return
                                }
                                print("Login successfull for user \(res.loginName)!")
                                self.userSettings.username = res.loginName
                                self.userSettings.token = res.appPassword
                                let loginString = "\(userSettings.username):\(userSettings.token)"
                                let loginData = loginString.data(using: String.Encoding.utf8)!
                                DispatchQueue.main.async {
                                    userSettings.authString = loginData.base64EncodedString()
                                }
                                self.userSettings.onboarding = false
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
    
    func sendLoginV2Request() async {
        let hostPath = "https://\(userSettings.serverAddress)"
        let headerFields: [HeaderField] = [
            //HeaderField.ocsRequest(value: true),
            //HeaderField.accept(value: .JSON)
        ]
        let request = RequestWrapper.customRequest(
            method: .POST,
            path: .LOGINV2REQ,
            headerFields: headerFields
        )
        do {
            let (data, _): (Data?, Error?) = try await NetworkHandler.sendHTTPRequest(
                request,
                hostPath: hostPath,
                authString: nil
            )
            
            guard let data = data else { return }
            print("Data: \(data)")
            let loginReq: LoginV2Request? = JSONDecoder.safeDecode(data)
            self.loginRequest = loginReq
        } catch {
            print("Could not establish communication with the server.")
        }
        
    }
    
    func fetchLoginV2Response() async -> LoginV2Response? {
        guard let loginRequest = loginRequest else { return nil }
        let headerFields = [
            HeaderField.ocsRequest(value: true),
            HeaderField.accept(value: .JSON),
            HeaderField.contentType(value: .FORM)
        ]
        let request = RequestWrapper.customRequest(
            method: .POST,
            path: .NONE,
            headerFields: headerFields,
            body: "token=\(loginRequest.poll.token)".data(using: .utf8),
            authenticate: false
        )
        
        var (data, error): (Data?, Error?) = (nil, nil)
        do {
            (data, error) = try await NetworkHandler.sendHTTPRequest(
                request,
                hostPath: loginRequest.poll.endpoint,
                authString: nil
            )
        } catch {
            print("Error: ", error)
        }
        guard let data = data else { return nil }
        if let loginRes: LoginV2Response = JSONDecoder.safeDecode(data) {
            return loginRes
        }
        print("Could not decode.")
        return nil
    }
}
