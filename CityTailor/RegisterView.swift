import SwiftUI

struct RegisterView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var languageManager: LanguageManager
    @StateObject private var userManager = UserManager.shared
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var username = ""
    @State private var isRegistering = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField(languageManager.localize("username"), text: $username)
                        .textContentType(.username)
                        .autocapitalization(.none)
                    
                    TextField(languageManager.localize("email"), text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField(languageManager.localize("password"), text: $password)
                        .textContentType(.newPassword)
                    
                    SecureField(languageManager.localize("confirm_password"), text: $confirmPassword)
                        .textContentType(.newPassword)
                }
                
                Section {
                    Button(action: handleRegistration) {
                        if isRegistering {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .frame(maxWidth: .infinity)
                        } else {
                            Text(languageManager.localize("create_account"))
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(isFormInvalid)
                }
                
                Section {
                    Text(languageManager.localize("password_requirements"))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle(languageManager.localize("create_account"))
            .navigationBarItems(leading: Button(languageManager.localize("cancel")) {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $showError) {
                Alert(
                    title: Text(languageManager.localize("error")),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private var isFormInvalid: Bool {
        username.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty ||
        password != confirmPassword ||
        password.count < 8 ||
        !isValidEmail(email) ||
        isRegistering
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func handleRegistration() {
        guard !isFormInvalid else { return }
        isRegistering = true
        
        userManager.login(username: username, email: email)
        
        DispatchQueue.main.async {
            isRegistering = false
            presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview {
    RegisterView()
        .environmentObject(LanguageManager())
}
