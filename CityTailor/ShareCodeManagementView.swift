import SwiftUI

struct ShareCodeManagementView: View {
    let plan: SavedTravelPlanViewModel
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var languageManager: LanguageManager
    
    @State private var currentShareCode: String?
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showShareSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    Text(languageManager.localize("share_plan"))
                        .font(.title)
                        .bold()
                    
                    Text(plan.location)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                if let shareCode = currentShareCode {
                    // Share code exists
                    VStack(spacing: 16) {
                        Text(languageManager.localize("share_code_generated"))
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        VStack(spacing: 12) {
                            Text(shareCode)
                                .font(.system(size: 32, weight: .bold, design: .monospaced))
                                .foregroundColor(.primary)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            
                            Button(action: {
                                copyCodeToClipboard(shareCode)
                            }) {
                                HStack {
                                    Image(systemName: "doc.on.doc")
                                    Text(languageManager.localize("copy_code"))
                                }
                                .foregroundColor(.blue)
                            }
                        }
                        
                        Text(languageManager.localize("share_this_code"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color(.systemGray6).opacity(0.5))
                    .cornerRadius(16)
                    
                    Button(action: {
                        shareCodeWithSystem(shareCode)
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text(languageManager.localize("share"))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        removeShareCode()
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text(languageManager.localize("remove_share_code"))
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                } else {
                    // No share code exists
                    VStack(spacing: 16) {
                        Text(languageManager.localize("no_share_code"))
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        
                        Text(languageManager.localize("generate_share_code_description"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button(action: {
                            generateShareCode()
                        }) {
                            if isLoading {
                                HStack {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                    Text(languageManager.localize("generating"))
                                        .foregroundColor(.white)
                                }
                            } else {
                                HStack {
                                    Image(systemName: "plus.circle")
                                    Text(languageManager.localize("generate_share_code"))
                                }
                                .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isLoading ? Color.gray : Color.blue)
                        .cornerRadius(10)
                        .disabled(isLoading)
                    }
                    .padding()
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .navigationTitle(languageManager.localize("share_plan"))
            .navigationBarItems(
                trailing: Button(languageManager.localize("done")) {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text(languageManager.localize("ok")))
                )
            }
            .onAppear {
                // Check if plan already has a share code (this would require backend API to check)
                // For now, we'll assume no code exists
            }
        }
    }
    
    private func generateShareCode() {
        guard let backendPlanId = plan.backendPlanId else {
            alertTitle = languageManager.localize("error")
            alertMessage = languageManager.localize("plan_not_shareable")
            showAlert = true
            return
        }
        
        isLoading = true
        
        CollaborationService.shared.generateAccessCode(for: backendPlanId) { result in
            self.isLoading = false
            
            switch result {
            case .success(let code):
                self.currentShareCode = code
                self.alertTitle = languageManager.localize("share_code_generated")
                self.alertMessage = languageManager.localize("share_code_ready")
                self.showAlert = true
                
            case .failure(let error):
                self.alertTitle = languageManager.localize("error")
                self.alertMessage = error.localizedDescription
                self.showAlert = true
            }
        }
    }
    
    private func removeShareCode() {
        guard let backendPlanId = plan.backendPlanId else { return }
        
        isLoading = true
        
        CollaborationService.shared.removeAccessCode(for: backendPlanId) { result in
            self.isLoading = false
            
            switch result {
            case .success:
                self.currentShareCode = nil
                self.alertTitle = languageManager.localize("share_code_removed")
                self.alertMessage = languageManager.localize("share_code_removed_message")
                self.showAlert = true
                
            case .failure(let error):
                self.alertTitle = languageManager.localize("error")
                self.alertMessage = error.localizedDescription
                self.showAlert = true
            }
        }
    }
    
    private func copyCodeToClipboard(_ code: String) {
        #if os(iOS)
        UIPasteboard.general.string = code
        #elseif os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(code, forType: .string)
        #endif
        
        alertTitle = languageManager.localize("code_copied")
        alertMessage = languageManager.localize("code_copied_message")
        showAlert = true
    }
    
    private func shareCodeWithSystem(_ code: String) {
        let shareText = "\(languageManager.localize("check_share_code")) \(code) \(languageManager.localize("access_my_travel_plan"))"
        
        #if os(iOS)
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            var topController = rootVC
            while let presentedController = topController.presentedViewController {
                topController = presentedController
            }
            
            activityVC.popoverPresentationController?.sourceView = topController.view
            topController.present(activityVC, animated: true)
        }
        #elseif os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(shareText, forType: .string)
        
        alertTitle = languageManager.localize("share_text_copied")
        alertMessage = languageManager.localize("share_text_copied_message")
        showAlert = true
        #endif
    }
}