import Foundation
import StoreKit

class StoreManager: NSObject, ObservableObject {
    @Published var products: [Product] = []
    @Published var purchasedProductIDs = Set<String>()
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    let productIDs = [
        "com.citytailor.premium.2.monthly",
        "com.citytailor.premium.2.yearly"
    ]
    
    override init() {
        super.init()
        Task {
            await loadProducts()
            await updatePurchasedProducts()
            
            DispatchQueue.main.async {
                let isPremium = self.isPremium()
                
                if let sharedDefaults = UserDefaults(suiteName: "group.com.app.CityTailor") {
                    sharedDefaults.set(isPremium, forKey: "is_premium_user")
                    sharedDefaults.synchronize()
                }
                
                let context = PersistenceController.shared.container.viewContext
                TravelPlanStore.shared.updatePremiumWidgetData(context: context, isPremium: isPremium)
            }
        }

        Task(priority: .background) {
            await listenForTransactions()
        }
    }
    
    @MainActor
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            products = try await Product.products(for: productIDs)
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
            print("Failed to load products: \(error)")
        }
    }
    
    @MainActor
    func updatePurchasedProducts() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }
            
            if transaction.revocationDate == nil {
                purchasedProductIDs.insert(transaction.productID)
            } else {
                purchasedProductIDs.remove(transaction.productID)
            }
        }
    }
    
    func listenForTransactions() async {
        for await result in Transaction.updates {
            guard case .verified(let transaction) = result else {
                continue
            }
            
            await processTransaction(transaction)
            await transaction.finish()
        }
    }
    
    @MainActor
    func processTransaction(_ transaction: Transaction) async {
        if transaction.revocationDate == nil {
            purchasedProductIDs.insert(transaction.productID)
            let context = PersistenceController.shared.container.viewContext
            TravelPlanStore.shared.updatePremiumWidgetData(context: context, isPremium: true)
        } else {
            purchasedProductIDs.remove(transaction.productID)
            let context = PersistenceController.shared.container.viewContext
            TravelPlanStore.shared.updatePremiumWidgetData(context: context, isPremium: false)
        }
    }
    
    func isPremium() -> Bool {
        return !purchasedProductIDs.isEmpty
    }
    
    func purchase(_ product: Product) async {
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verificationResult):
                guard case .verified(let transaction) = verificationResult else {
                    errorMessage = "Transaction verification failed"
                    return
                }
                
                await processTransaction(transaction)
                await transaction.finish()
                
            case .userCancelled:
                print("User cancelled purchase")
                
            case .pending:
                print("Purchase pending")
                
            @unknown default:
                print("Unknown purchase result")
            }
        } catch {
            errorMessage = "Failed to purchase product: \(error.localizedDescription)"
            print("Purchase error: \(error)")
        }
    }
    
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
        } catch {
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
            print("Restore purchases error: \(error)")
        }
    }
}

struct PremiumFeatures {
    static let unlimited = "Unbegrenzte Reisepläne"
    static let customization = "Benutzerdefinierte Reisepläne"
    static let aiSuggestions = "Verbesserte KI-Vorschläge"
    static let offlineAccess = "Offline-Zugriff"
    static let noAds = "Keine Werbung"
    static let allFeatures = [unlimited, customization, aiSuggestions, offlineAccess, noAds]
}
