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
            selectedTab == 1 ? Color("ncblue").ignoresSafeArea() : Color(uiColor: .systemBackground).ignoresSafeArea()
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
                Text("Tank you for downloading")
                    .font(.headline)
                Text("Nextcloud")
                    .font(.largeTitle)
                    .bold()
                Text("Cookbook")
                    .font(.largeTitle)
                    .bold()
                Spacer()
                Text("This application is an open source effort and still in development. If you encounter any problems, please report them on our GitHub page.\n\nCurrently, only app token login is supported. You can create an app token in the nextcloud security settings.")
                    .padding()
                Spacer()
            }
            .padding()
            .fontDesign(.rounded)
    }
}

struct LoginTab: View {
    @ObservedObject var userSettings: UserSettings
    
    enum Field {
        case server
        case username
        case token
    }
    @FocusState private var focusedField: Field?
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading) {
                HStack {
                    Spacer()
                    Image("nc-logo-white")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 150)
                        .padding()
                    Spacer()
                }
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
                        userSettings.onboarding = false
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

struct LoginTextField: View {
    var example: String
    @Binding var text: String
    
    var body: some View {
        TextField(example, text: $text)
            .textFieldStyle(.plain)
            .textCase(.lowercase)
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
