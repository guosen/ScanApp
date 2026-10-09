import Foundation
import StoreKit

/// StoreKit 2 non-consumable for ClearScan Pro (configure matching product in App Store Connect).
@MainActor
final class PurchaseService: ObservableObject {
    static let proProductID = "com.clearscan.app.pro"

    @Published private(set) var isProUnlocked = false
    @Published private(set) var proProduct: Product?
    @Published private(set) var purchaseInProgress = false
    @Published var lastErrorMessage: String?

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = listenForTransactions()
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    func loadProducts() async {
        do {
            let products = try await Product.products(for: [Self.proProductID])
            proProduct = products.first
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func refreshEntitlements() async {
        var unlocked = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.proProductID {
                unlocked = true
            }
        }
        isProUnlocked = unlocked
    }

    func purchasePro() async {
        guard let product = proProduct else {
            lastErrorMessage = String(localized: "Pro product is not available yet.")
            return
        }
        purchaseInProgress = true
        defer { purchaseInProgress = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await refreshEntitlements()
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func restorePurchases() async {
        purchaseInProgress = true
        defer { purchaseInProgress = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func canUse(filter: PageFilter) -> Bool {
        !filter.isProOnly || isProUnlocked
    }

    func canUse(proPDFOptions: Bool) -> Bool {
        !proPDFOptions || isProUnlocked
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }
                await transaction.finish()
                await self?.refreshEntitlements()
            }
        }
    }
}
