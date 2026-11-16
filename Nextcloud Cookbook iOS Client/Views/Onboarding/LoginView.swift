//
//  OnboardingView.swift
//  Nextcloud Cookbook iOS Client
//
//  Created by Vincent Meilinger on 15.09.23.
//

import Foundation
import SwiftUI
import WebKit
import NextcloudCookbookKit


// MARK: - Login view

enum LoginMethod { case nextcloud, token }

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Form state
    @State private var serverProtocol: String = UserSettings.shared.serverProtocol
    @State private var serverAddress: String = UserSettings.shared.serverAddress
    @State private var username: String = ""
    @State private var password: String = ""

    @State private var loginMethod: LoginMethod = .nextcloud

    // Nextcloud login flow v2
    @State private var loginRequest: NCKLoginV2Request? = nil
    @State private var showBrowser = false
    @State private var pollingTask: Task<Void, Never>? = nil

    // Loading / error state
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false

    @FocusState private var focused: Field?
    enum Field { case server, username, token }

    var body: some View {
        NavigationStack {
            Form {
                appHeader

                methodPicker

                serverSection

                if loginMethod == .token {
                    credentialsSection
                }

                actionsSection

                helpSection
            }
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showBrowser) {
                if let loginRequest {
                    WebViewSheet(url: loginRequest.login)
                }
            }
            .onDisappear {
                pollingTask?.cancel()
            }
            .alert("Sign In Failed", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Sections

    private var appHeader: some View {
        Section {
            VStack(spacing: 10) {
                Image("cookbook-icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(radius: 2)
                Text("Cookbook Client")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .listRowBackground(Color.clear)
    }

    private var methodPicker: some View {
        Section {
            Picker("Login Method", selection: $loginMethod) {
                Text("Nextcloud Login").tag(LoginMethod.nextcloud)
                Text("App Token").tag(LoginMethod.token)
            }
            .pickerStyle(.segmented)
            .onChange(of: loginMethod) {
                loginRequest = nil
                pollingTask?.cancel()
                pollingTask = nil
            }
        }
        .listRowBackground(Color.clear)
    }

    private var serverSection: some View {
        Section("Server") {
            HStack(spacing: 4) {
                Picker("", selection: $serverProtocol) {
                    Text("https://").tag("https://")
                    Text("http://").tag("http://")
                }
                .pickerStyle(.menu)
                .fixedSize()

                Divider().frame(height: 20)

                TextField("example.com", text: $serverAddress)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($focused, equals: .server)
                    .submitLabel(loginMethod == .token ? .next : .done)
                    .onSubmit { if loginMethod == .token { focused = .username } }
            }
        }
    }

    private var credentialsSection: some View {
        Section("Credentials") {
            TextField("Username", text: $username)
                .textContentType(.username)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($focused, equals: .username)
                .submitLabel(.next)
                .onSubmit { focused = .token }

            SecureField("App Token", text: $password)
                .textContentType(.password)
                .focused($focused, equals: .token)
                .submitLabel(.go)
                .onSubmit { Task { await signInWithToken() } }
        }
    }

    @ViewBuilder
    private var actionsSection: some View {
        Section {
            if loginMethod == .nextcloud {
                // Primary: open browser
                Button {
                    Task { await openNextcloudLogin() }
                } label: {
                    HStack {
                        Spacer()
                        if isLoading {
                            ProgressView()
                        } else {
                            Label(
                                loginRequest == nil ? "Open Nextcloud Login" : "Reopen Login Page",
                                systemImage: "safari"
                            )
                            .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .disabled(serverAddress.isEmpty)

                // Status + copy link — shown after browser was opened
                if let loginRequest {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Waiting for approval…")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Button("Copy Login Link", systemImage: "link") {
                        UIPasteboard.general.string = loginRequest.login
                    }
                    .foregroundStyle(.secondary)
                }

            } else {
                // Token login
                Button {
                    Task { await signInWithToken() }
                } label: {
                    HStack {
                        Spacer()
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Sign In").fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .disabled(serverAddress.isEmpty)
            }
        }
    }

    private var helpSection: some View {
        Section {
            if loginMethod == .nextcloud {
                Text("Tap \"Open Nextcloud Login\" to authenticate in your browser. Once you approve access, this app will sign you in automatically.")
            } else {
                Text("Generate an app token in your Nextcloud settings under Personal Settings → Security → App passwords.")
            }
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .listRowBackground(Color.clear)
    }

    // MARK: - Actions

    private func openNextcloudLogin() async {
        guard let serverURL = serverURL() else {
            fail("Please enter a valid server address.")
            return
        }
        isLoading = true
        defer { isLoading = false }

        do {
            loginRequest = try await NextcloudAuthClient(serverURL: serverURL).loginV2Request()
            showBrowser = true
            startPolling()
        } catch {
            fail("Could not reach the server. Please check the address and your internet connection.")
        }
    }

    /// Polls the Nextcloud Login Flow v2 endpoint every 2 seconds until the user
    /// approves the request in the browser. On success, commits credentials and
    /// dismisses the sheet automatically.
    private func startPolling() {
        pollingTask?.cancel()
        guard let serverURL = serverURL() else { return }

        pollingTask = Task {
            while !Task.isCancelled, let request = loginRequest {
                try? await Task.sleep(for: .seconds(2))
                guard !Task.isCancelled else { break }

                do {
                    let response = try await NextcloudAuthClient(serverURL: serverURL)
                        .loginV2Response(token: request.poll.token, pollEndpoint: request.poll.endpoint)
                    finishLogin(name: response.loginName, password: response.appPassword)
                    dismiss()
                    return
                } catch {
                    // Not yet approved — loop and try again
                }
            }
        }
    }

    private func signInWithToken() async {
        guard !serverAddress.isEmpty else {
            fail("Please enter a server address.")
            return
        }
        guard !username.isEmpty, !password.isEmpty else {
            fail("Please enter a username and app token.")
            return
        }
        guard let serverURL = serverURL() else {
            fail("Please enter a valid server address.")
            return
        }

        isLoading = true
        defer { isLoading = false }

        // Build auth string
        let tempAuthString = Data("\(username):\(password)".utf8).base64EncodedString()
        do {
            _ = try await CookbookAPI.connect(serverURL: serverURL, credentials: tempAuthString)
                .getCategories()
            finishLogin(name: username, password: password)
            dismiss()
        } catch NCKError.unsupportedAPIVersion {
            fail("This version of the Cookbook app on your server is not supported. Please check for an update of this app.")
        } catch NCKError.cookbookUnavailable {
            fail("The Cookbook app is not available on this server. Please make sure it is installed and enabled.")
        } catch {
            fail("Sign in failed. Please check your inputs and internet connection.")
        }
    }

    // MARK: - Helpers

    private func serverURL() -> URL? {
        URL(string: serverProtocol + serverAddress)
    }

    /// Commits credentials to UserSettings, called only after the server confirms them.
    private func finishLogin(name: String, password: String) {
        let settings = UserSettings.shared
        settings.serverProtocol = serverProtocol
        settings.serverAddress = serverAddress
        settings.username = name
        settings.token = password
        settings.authString = Data("\(name):\(password)".utf8).base64EncodedString()
    }

    private func fail(_ message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - Nextcloud browser sheet

private struct WebViewSheet: View {
    @Environment(\.dismiss) private var dismiss
    let url: String
    @State private var page = WebPage()

    var body: some View {
        NavigationStack {
            if let url = URL(string: url) {
                WebView(page)
                    .ignoresSafeArea(edges: .bottom)
                    .navigationTitle(page.title.isEmpty ? "Nextcloud Login" : page.title)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { dismiss() }
                        }
                    }
                    .onAppear {
                        page.load(URLRequest(url: url))
                    }
            } else {
                Text("Invalid login URL")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { dismiss() }
                        }
                    }
            }
        }
    }
}
