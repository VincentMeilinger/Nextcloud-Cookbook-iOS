//
//  OnboardingView.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 15.09.23.
//

import Foundation
import SwiftUI

struct OnboardingView: View {
    @State var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            WelcomeTab().tag(0)
            LoginTab().tag(1)
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
                Image("cookbook-icon")
                    .resizable()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                Text("Thank you for downloading")
                    .font(.headline)
                Text("Cookbook Client")
                    .font(.largeTitle)
                    .bold()
                Spacer()
                Text("This application is an open source effort. If you're interested in suggesting or contributing new features, or you encounter any problems, please use the support link or visit the GitHub repository in the app settings.")
                    .padding()
                Spacer()
            }
            .padding()
            .fontDesign(.rounded)
    }
}

protocol LoginStage {
    func next() -> Self
    func previous() -> Self
}

enum LoginMethod {
    case v2, token
}

enum TokenLoginStage: LoginStage {
    case serverAddress, userName, appToken, validate
    
    func next() -> TokenLoginStage {
        switch self {
        case .serverAddress: return .userName
        case .userName: return .appToken
        case .appToken: return .validate
        case .validate: return .validate
        }
    }
    
    func previous() -> TokenLoginStage {
        switch self {
        case .serverAddress: return .serverAddress
        case .userName: return .serverAddress
        case .appToken: return .userName
        case .validate: return .appToken
        }
    }
}





struct LoginTab: View {
    @State var loginMethod: LoginMethod = .v2

    // Login error alert
    @State var showAlert: Bool = false
    @State var alertMessage: String = "Error: Could not connect to server."
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading) {
                Spacer()
                Picker("Login Method", selection: $loginMethod) {
                    Text("Nextcloud Login").tag(LoginMethod.v2)
                    Text("App Token Login").tag(LoginMethod.token)
                }
                .pickerStyle(.segmented)
                .foregroundColor(.white)
                .padding()
                if loginMethod == .token {
                    TokenLoginView(
                        showAlert: $showAlert,
                        alertMessage: $alertMessage
                    )
                }
                else if loginMethod == .v2 {
                    V2LoginView(
                        showAlert: $showAlert,
                        alertMessage: $alertMessage
                    )
                }
                Spacer()
            }
            
            .fontDesign(.rounded)
            .padding()
            .alert(alertMessage, isPresented: $showAlert) {
                Button("Ok", role: .cancel) { }
            }
        }
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

struct BorderedLoginTextField: View {
    var example: String
    @Binding var text: String
    @State var color: Color = .white
    
    var body: some View {
        TextField(example, text: $text)
            .textFieldStyle(.plain)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .foregroundColor(color)
            .accentColor(color)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.white, lineWidth: 2)
                    .foregroundColor(.clear)
            )
            
    }
}

struct LoginTextField: View {
    var example: String
    @Binding var text: String
    @State var color: Color = .white
    
    var body: some View {
        TextField(example, text: $text)
            .textFieldStyle(.plain)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .foregroundColor(color)
            .accentColor(color)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .foregroundColor(Color.white.opacity(0.2))
            )
    }
}


struct ServerAddressField: View {
    @ObservedObject var userSettings = UserSettings.shared
    @State var serverProtocol: ServerProtocol = .https
    
    enum ServerProtocol: String {
        case https="https://", http="http://"
        
        static let all = [https, http]
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            LoginLabel(text: "Server address")
            VStack(alignment: .leading) {
                HStack {
                    Picker(ServerProtocol.https.rawValue, selection: $serverProtocol) {
                        ForEach(ServerProtocol.all, id: \.self) {
                            Text($0.rawValue)
                        }
                    }.pickerStyle(.menu)
                    .tint(.white)
                    .font(.headline)
                    .onChange(of: serverProtocol) { color in
                        userSettings.serverProtocol = color.rawValue
                    }
                    
                    TextField("e.g.: example.com", text: $userSettings.serverAddress)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .foregroundStyle(.white)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .foregroundColor(Color.white.opacity(0.2))
                        )
                    
                }
                
                LoginLabel(text: "Full server address")
                    .padding(.top)
                Text(userSettings.serverProtocol + userSettings.serverAddress)
                    .foregroundColor(.white)
                    .padding(.vertical, 5)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.white, lineWidth: 2)
                    .foregroundColor(.clear)
            )
        }
    }
}

struct ServerAddressField_Preview: PreviewProvider {
    static var previews: some View {
        ServerAddressField()
            .previewLayout(.sizeThatFits)
            .padding()
            .background(Color.nextcloudBlue)
    }
}
