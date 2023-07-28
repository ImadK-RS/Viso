//
//  LoginView.swift
//  ProFlix
//
//  Created for Xtream API integration
//

import SwiftUI

struct LoginView: View {

  @EnvironmentObject var appState: AppState
  @StateObject private var observed = LoginObserved()

  var body: some View {
    ZStack {
      // Background gradient
      LinearGradient(
        colors: [Color(hex: "#1a1a2e") ?? .black, Color(hex: "#16213e") ?? .black],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()

      ScrollView {
        VStack(spacing: 30) {
          // Logo/Title Section
          VStack(spacing: 15) {
            Image(systemName: "tv.fill")
              .font(.system(size: 80))
              .foregroundColor(.white)
              .padding(.top, 60)

            Text("ProFlix")
              .font(.system(size: 48, weight: .bold))
              .foregroundColor(.white)

            Text("Xtream API Login")
              .font(.title3)
              .foregroundColor(.secondary)
          }
          .padding(.bottom, 40)

          // Login Form
          VStack(spacing: 20) {
            // Server URL Field
            VStack(alignment: .leading, spacing: 8) {
              Text("Server URL")
                .font(.headline)
                .foregroundColor(.white)

              TextField("https://example.com:8080", text: $observed.serverURL)
                .textFieldStyle(LoginTextFieldStyle())
                .textContentType(.URL)
                .keyboardType(.URL)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            }

            // Username Field
            VStack(alignment: .leading, spacing: 8) {
              Text("Username")
                .font(.headline)
                .foregroundColor(.white)

              TextField("Enter username", text: $observed.username)
                .textFieldStyle(LoginTextFieldStyle())
                .textContentType(.username)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            }

            // Password Field
            VStack(alignment: .leading, spacing: 8) {
              Text("Password")
                .font(.headline)
                .foregroundColor(.white)

              SecureField("Enter password", text: $observed.password)
                .textFieldStyle(LoginTextFieldStyle())
                .textContentType(.password)
            }

            // Error Message
            if let error = observed.errorMessage {
              Text(error)
                .font(.caption)
                .foregroundColor(.red)
                .padding(.horizontal)
            }

            // Login Button
            Button(action: handleLogin) {
              HStack {
                if appState.isAuthenticating {
                  ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8)
                } else {
                  Image(systemName: "arrow.right.circle.fill")
                    .font(.title3)
                }

                Text(appState.isAuthenticating ? "Connecting..." : "Login")
                  .fontWeight(.semibold)
              }
              .frame(maxWidth: .infinity)
              .frame(height: 50)
              .foregroundColor(.white)
              .background(
                LinearGradient(
                  colors: [Color(hex: "#667eea") ?? .blue, Color(hex: "#764ba2") ?? .purple],
                  startPoint: .leading,
                  endPoint: .trailing
                )
              )
              .cornerRadius(12)
              .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(appState.isAuthenticating || !observed.isFormValid)
            .opacity(observed.isFormValid ? 1.0 : 0.6)
            .padding(.top, 10)
          }
          .padding(.horizontal, 40)
          .padding(.bottom, 60)
        }
      }
    }
  }

  private func handleLogin() {
    observed.validateForm()

    guard observed.isFormValid else {
      return
    }

    Task {
      let success = await appState.login(
        url: observed.serverURL,
        username: observed.username,
        password: observed.password
      )

      if !success, let error = appState.authenticationError {
        await MainActor.run {
          observed.errorMessage = error
        }
      }
    }
  }
}

// MARK: - Login Text Field Style

struct LoginTextFieldStyle: TextFieldStyle {
  func _body(configuration: TextField<Self._Label>) -> some View {
    configuration
      .padding(15)
      .background(Color.white.opacity(0.1))
      .cornerRadius(10)
      .overlay(
        RoundedRectangle(cornerRadius: 10)
          .stroke(Color.white.opacity(0.3), lineWidth: 1)
      )
      .foregroundColor(.white)
  }
}

// MARK: - Login Observed State

final class LoginObserved: ObservableObject {
  @Published var serverURL: String = ""
  @Published var username: String = ""
  @Published var password: String = ""
  @Published var errorMessage: String?

  var isFormValid: Bool {
    !serverURL.isEmpty && !username.isEmpty && !password.isEmpty
  }

  func validateForm() {
    errorMessage = nil

    guard !serverURL.isEmpty else {
      errorMessage = "Server URL is required"
      return
    }

    guard URL(string: serverURL) != nil else {
      errorMessage = "Invalid URL format"
      return
    }

    guard !username.isEmpty else {
      errorMessage = "Username is required"
      return
    }

    guard !password.isEmpty else {
      errorMessage = "Password is required"
      return
    }
  }
}

// MARK: - Preview

struct LoginView_Previews: PreviewProvider {
  static var previews: some View {
    LoginView()
      .environmentObject(AppState())
  }
}
