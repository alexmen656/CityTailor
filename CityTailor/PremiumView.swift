import SwiftUI
import StoreKit

struct PremiumView: View {
    @EnvironmentObject private var storeManager: StoreManager
    @EnvironmentObject private var languageManager: LanguageManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedProduct: Product?
    @State private var isProcessing = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Premium header
                    VStack {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.yellow)
                            .padding(.bottom, 10)
                        
                        Text(languageManager.localize("citytailor_premium"))
                            .font(.largeTitle)
                            .bold()
                        
                        Text(languageManager.localize("experience_best"))
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 30)
                    .padding(.bottom, 20)
                    
                    // Features list
                    VStack(alignment: .leading, spacing: 15) {
                        ForEach(localizedPremiumFeatures(), id: \.self) { feature in
                            HStack(spacing: 15) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text(feature)
                                    .font(.body)
                                Spacer()
                            }
                        }
                    }
                    .padding()
                    .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Subscription options
                    if storeManager.isLoading {
                        ProgressView()
                            .padding()
                    } else if storeManager.products.isEmpty {
                        Text(languageManager.localize("no_subscriptions"))
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        VStack(spacing: 15) {
                            ForEach(storeManager.products, id: \.id) { product in
                                SubscriptionOptionView(
                                    product: product,
                                    isSelected: selectedProduct?.id == product.id,
                                    onSelect: {
                                        selectedProduct = product
                                    },
                                    languageManager: languageManager
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Button {
                        purchaseSubscription()
                    } label: {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(languageManager.localize("buy_subscription"))
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedProduct == nil ? Color.gray : Color.blue)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .disabled(selectedProduct == nil || isProcessing)
                    
                    HStack(spacing: 15) {
                            Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                                .font(.caption)
                            
                            Link("Privacy Policy", destination: URL(string: "https://alex.polan.sk/privacy-policy.html")!)
                                .font(.caption)
                        }
                        .padding(.top, 8)
                    // Terms and conditions
                    VStack(spacing: 8) {
                        Text(languageManager.localize("purchase_through_apple"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(languageManager.localize("auto_renewal"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitle(languageManager.localize("premium"), displayMode: .inline)
            .navigationBarItems(
                leading: Button(languageManager.localize("restore")) {
                    restorePurchases()
                },
                trailing: Button(languageManager.localize("close")) {
                    dismiss()
                }
            )
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(languageManager.localize("information")),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    func localizedPremiumFeatures() -> [String] {
        return [
            languageManager.localize("unlimited_plans"),
            //languageManager.localize("custom_plans"),
            languageManager.localize("enhanced_ai"),
            languageManager.localize("advanced_settings"),
            languageManager.localize("export_plan_pdf"),
            languageManager.localize("support_future_development")
            //languageManager.localize("offline_access"),
            //languageManager.localize("no_ads")
        ]
    }
    
    func purchaseSubscription() {
        guard let product = selectedProduct else { return }
        
        isProcessing = true
        
        Task {
            await storeManager.purchase(product)
            await MainActor.run {
                isProcessing = false
                if storeManager.isPremium() {
                    alertMessage = languageManager.localize("thank_you")
                    showAlert = true
                } else if let error = storeManager.errorMessage {
                    alertMessage = error
                    showAlert = true
                }
            }
        }
    }
    
    func restorePurchases() {
        isProcessing = true
        
        Task {
            await storeManager.restorePurchases()
            await MainActor.run {
                isProcessing = false
                if storeManager.isPremium() {
                    alertMessage = languageManager.localize("purchases_restored")
                    showAlert = true
                } else if let error = storeManager.errorMessage {
                    alertMessage = error
                    showAlert = true
                } else {
                    alertMessage = languageManager.localize("no_purchases")
                    showAlert = true
                }
            }
        }
    }
}

struct SubscriptionOptionView: View {
    let product: Product
    let isSelected: Bool
    let onSelect: () -> Void
    let languageManager: LanguageManager
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.displayName)
                        .font(.headline)
                    
                    if let description = subscriptionDescription(for: product.id) {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(product.displayPrice)
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    if let unit = subscriptionPriceUnit(for: product.id) {
                        Text(unit)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .animation(.easeInOut, value: isSelected)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func subscriptionDescription(for id: String) -> String? {
        if id.contains("monthly") {
            return languageManager.localize("monthly_subscription")
        } else if id.contains("yearly") {
            return languageManager.localize("yearly_subscription")
        }
        return nil
    }
    
    private func subscriptionPriceUnit(for id: String) -> String? {
        if id.contains("monthly") {
            return languageManager.localize("per_month")
        } else if id.contains("yearly") {
            return languageManager.localize("per_year")
        }
        return nil
    }
}

#Preview {
    PremiumView()
        .environmentObject(StoreManager())
        .environmentObject(LanguageManager())
}
