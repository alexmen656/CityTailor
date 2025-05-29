import SwiftUI

struct LoginView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var languageManager: LanguageManager
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoggingIn = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoggedIn = false
    @State private var showRegisterView = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("E-Mail", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                }
                
                Section {
                    Button(action: handleLogin) {
                        if isLoggingIn {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Login")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(email.isEmpty || password.isEmpty || isLoggingIn)
                }
                
                Section {
                    Button(action: {
                    }) {
                        Text("Forgot Password?")
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: {
                        showRegisterView = true
                    }) {
                        Text(languageManager.localize("create_account"))
                            .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("Login")
            .sheet(isPresented: $showRegisterView) {
                RegisterView()
            }
            .alert(isPresented: $showError) {
                Alert(
                    title: Text(languageManager.localize("error")),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func handleLogin() {
        isLoggingIn = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoggingIn = false
            if email == "test@example.com" && password == "password" {
                isLoggedIn = true
                presentationMode.wrappedValue.dismiss()
            } else {
                errorMessage = "Invalid email or password"
                showError = true
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(LanguageManager())
}
