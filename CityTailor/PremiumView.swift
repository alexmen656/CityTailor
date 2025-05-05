import SwiftUI
import StoreKit

struct PremiumView: View {
    @EnvironmentObject private var storeManager: StoreManager
    @Environment(\.dismiss) private var dismiss
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
                        
                        Text("CityTailor Premium")
                            .font(.largeTitle)
                            .bold()
                        
                        Text("Erleben Sie das Beste von CityTailor")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 30)
                    .padding(.bottom, 20)
                    
                    // Features list
                    VStack(alignment: .leading, spacing: 15) {
                        ForEach(PremiumFeatures.allFeatures, id: \.self) { feature in
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
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Subscription options
                    if storeManager.isLoading {
                        ProgressView()
                            .padding()
                    } else if storeManager.products.isEmpty {
                        Text("Keine Abonnements verfügbar")
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
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Purchase button
                    Button {
                        purchaseSubscription()
                    } label: {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Abonnement kaufen")
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
                    
                    // Restore purchases button
                    Button {
                        restorePurchases()
                    } label: {
                        Text("Käufe wiederherstellen")
                            .foregroundColor(.blue)
                    }
                    .padding()
                    
                    // Terms and conditions
                    VStack(spacing: 8) {
                        Text("Der Kauf wird über Ihren Apple Account abgewickelt.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Ihr Abonnement verlängert sich automatisch, bis es gekündigt wird.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitle("Premium", displayMode: .inline)
            .navigationBarItems(trailing: Button("Schließen") {
                dismiss()
            })
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Information"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    func purchaseSubscription() {
        guard let product = selectedProduct else { return }
        
        isProcessing = true
        
        Task {
            await storeManager.purchase(product)
            await MainActor.run {
                isProcessing = false
                if storeManager.isPremium() {
                    alertMessage = "Vielen Dank für den Kauf! Sie haben jetzt Zugang zu allen Premium-Funktionen."
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
                    alertMessage = "Ihre Käufe wurden wiederhergestellt."
                    showAlert = true
                } else if let error = storeManager.errorMessage {
                    alertMessage = error
                    showAlert = true
                } else {
                    alertMessage = "Keine Käufe zum Wiederherstellen gefunden."
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
            return "Monatliches Premium-Abonnement"
        } else if id.contains("yearly") {
            return "Jährliches Premium-Abonnement (Spare 20%)"
        }
        return nil
    }
    
    private func subscriptionPriceUnit(for id: String) -> String? {
        if id.contains("monthly") {
            return "pro Monat"
        } else if id.contains("yearly") {
            return "pro Jahr"
        }
        return nil
    }
}

#Preview {
    PremiumView()
        .environmentObject(StoreManager())
}