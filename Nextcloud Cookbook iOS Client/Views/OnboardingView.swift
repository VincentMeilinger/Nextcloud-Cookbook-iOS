//
//  OnboardingView.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 15.09.23.
//

import Foundation
import SwiftUI

struct OnboardingView: View {
    @ObservedObject var userSettings: UserSettings
    @State var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            WelcomeTab().tag(0)
            LoginTab(userSettings: userSettings).tag(1)
        }
        .tabViewStyle(.page)
        .background(
            selectedTab == 1 ? Color.nextcloudBlue.ignoresSafeArea() : Color(uiColor: .systemBackground).ignoresSafeArea()
        )
        .animation(.easeInOut, value: selectedTab)
    }
}

struct WelcomeTab: View {
    var body: some View {
            VStack(alignment: .center) {
                Spacer()
                Image("CookBook")
                    .resizable()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                Text("Tank you for downloading the")
                    .font(.headline)
                Text("Cookbook Client")
                    .font(.largeTitle)
                    .bold()
                Spacer()
                Text("This application is an open source effort and still in development. If you encounter any problems, please report them on our GitHub page.")
                    .padding()
                Spacer()
            }
            .padding()
            .fontDesign(.rounded)
    }
}

struct LoginTab: View {
    @ObservedObject var userSettings: UserSettings
    
    // Login flow
    enum LoginMethod {
        case v2, token
    }
    @State var selectedLoginMethod: LoginMethod = .v2
    @State var loginRequest: LoginV2Request? = nil
    
    // Login error alert
    @State var showAlert: Bool = false
    @State var alertMessage: String = "Error: Could not connect to server."
    
    // TextField handling
    enum Field {
        case server
        case username
        case token
    }
    @FocusState private var focusedField: Field?
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading) {
                Spacer()
                Picker("Login Method", selection: $selectedLoginMethod) {
                    Text("Nextcloud Login").tag(LoginMethod.v2)
                    Text("App Token Login").tag(LoginMethod.token)
                }
                .pickerStyle(.segmented)
                .foregroundColor(.white)
                if selectedLoginMethod == .token {
                    LoginLabel(text: "Server address")
                    LoginTextField(example: "e.g.: example.com", text: $userSettings.serverAddress)
                        .focused($focusedField, equals: .server)
                        .textContentType(.URL)
                        .submitLabel(.next)
                        .padding(.bottom)
                    
                    LoginLabel(text: "User name")
                    LoginTextField(example: "username", text: $userSettings.username)
                        .focused($focusedField, equals: .username)
                        .textContentType(.username)
                        .submitLabel(.next)
                        .padding(.bottom)
                    
                    
                    LoginLabel(text: "App Token")
                    LoginTextField(example: "can be generated in security settings of your nextcloud", text: $userSettings.token)
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
                else if selectedLoginMethod == .v2 {
                    LoginLabel(text: "Server address")
                    LoginTextField(example: "e.g.: example.com", text: $userSettings.serverAddress)
                        .focused($focusedField, equals: .server)
                        .textContentType(.URL)
                        .submitLabel(.done)
                        .padding(.bottom)
                        .onSubmit {
                            if userSettings.serverAddress == "" { return }
                            Task {
                                await sendLoginV2Request()
                                if let loginRequest = loginRequest {
                                    await UIApplication.shared.open(URL(string: loginRequest.login)!)
                                } else {
                                    alertMessage = "Unable to reach server. Please check your server address and internet connection."
                                    showAlert = true
                                }
                            }
                        }
                    Text("Entering the server address will open a web browser. Please follow the login instructions provided there. If the browser does not open, click the link 'Open in browser'\nAfter a successfull login, return to this application and press 'Validate'.")
                        .font(.subheadline)
                        .padding(.bottom)
                        .foregroundStyle(.white)
                    Button {
                        Task {
                            await sendLoginV2Request()
                            if let loginRequest = loginRequest {
                                await UIApplication.shared.open(URL(string: loginRequest.login)!)
                            } else {
                                alertMessage = "Unable to reach server. Please check your server address and internet connection."
                                showAlert = true
                            }
                        }
                    } label: {
                        Text("Open in browser")
                            .foregroundColor(.white)
                            .font(.headline)                            
                    }
                        
                    HStack{
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
                                userSettings.username = res.loginName
                                userSettings.token = res.appPassword
                                userSettings.onboarding = false
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
                        Spacer()
                    }
                }
                Spacer()
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
            .fontDesign(.rounded)
            .padding()
            .alert(alertMessage, isPresented: $showAlert) {
                Button("Ok", role: .cancel) { }
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

struct LoginLabel: View {
    let text: String
    var body: some View {
        Text(text)
            .foregroundColor(.white)
            .font(.headline)
            .padding(.vertical, 5)
    }
}

struct LoginTextField: View {
    var example: String
    @Binding var text: String
    
    var body: some View {
        TextField(example, text: $text)
            .textFieldStyle(.plain)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .foregroundColor(.white)
            .accentColor(.white)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white, lineWidth: 2)
                    .foregroundColor(.clear)
            )
    }
}
