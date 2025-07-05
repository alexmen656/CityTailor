import SwiftUI

struct AccessCodeView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var languageManager: LanguageManager
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var storeManager: StoreManager
    
    @State private var accessCode = ""
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var loadedPlan: TravelPlan?
    @State private var showPlan = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "key.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .padding(.top, 40)
                
                Text(languageManager.localize("access_with_code"))
                    .font(.title)
                    .bold()
                
                Text(languageManager.localize("enter_6_digit_code"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(spacing: 16) {
                    TextField(languageManager.localize("access_code"), text: $accessCode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .font(.title2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .onChange(of: accessCode) { newValue in
                            if newValue.count > 6 {
                                accessCode = String(newValue.prefix(6))
                            }
                            accessCode = newValue.filter { $0.isNumber }
                        }
                    
                    Button(action: {
                        accessPlanWithCode()
                    }) {
                        if isLoading {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                                Text(languageManager.localize("loading"))
                                    .foregroundColor(.white)
                            }
                        } else {
                            Text(languageManager.localize("access_with_code"))
                                .foregroundColor(.white)
                                .bold()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(accessCode.count == 6 && !isLoading ? Color.blue : Color.gray)
                    .cornerRadius(10)
                    .padding(.horizontal, 40)
                    .disabled(accessCode.count != 6 || isLoading)
                }
                
                Spacer()
            }
            .navigationTitle(languageManager.localize("access_code"))
            .navigationBarItems(
                leading: Button(languageManager.localize("cancel")) {
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
            .sheet(isPresented: $showPlan) {
                if let plan = loadedPlan {
                    TravelPlanView(travelPlan: plan, selectedDay: .constant(1))
                }
            }
        }
    }
    
    private func accessPlanWithCode() {
        guard accessCode.count == 6 else { return }
        
        isLoading = true
        
        CollaborationService.shared.accessPlanWithCode(accessCode) { result in
            self.isLoading = false
            
            switch result {
            case .success(let plan):
                self.loadedPlan = plan
                
                if TravelPlanStore.shared.canSaveTravelPlan(isPremium: storeManager.isPremium(), context: viewContext) {
                    TravelPlanStore.shared.saveTravelPlan(plan, context: viewContext)
                }
                
                self.showPlan = true
                self.presentationMode.wrappedValue.dismiss()
                
            case .failure(let error):
                self.alertTitle = languageManager.localize("error")
                
                if error.localizedDescription.contains("Invalid") || error.localizedDescription.contains("404") {
                    self.alertMessage = languageManager.localize("invalid_access_code")
                } else {
                    self.alertMessage = error.localizedDescription
                }
                
                self.showAlert = true
            }
        }
    }
}

struct AccessCodeView_Previews: PreviewProvider {
    static var previews: some View {
        AccessCodeView()
            .environmentObject(LanguageManager())
    }
}
