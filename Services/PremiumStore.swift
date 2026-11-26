import Foundation
import Observation
import StoreKit

/// Subscription state through StoreKit 2. Prices always come from the store.
@MainActor
@Observable
final class PremiumStore {
    static let yearlyID = "technology.mika.goruldu.premium.yearly"
    static let weeklyID = "technology.mika.goruldu.premium.weekly"
    static let productIDs = [yearlyID, weeklyID]

    enum ProductState {
        case loading
        case loaded([Product])
        /// The store could not be reached or returned no products.
        case unavailable
    }

    enum PurchaseOutcome: Equatable {
        case purchased
        case cancelled
        /// Waiting for approval, for example Ask to Buy.
        case pending
        case failed
    }

    enum RestoreOutcome: Equatable {
        case restored
        case nothingToRestore
        case failed
    }

    private(set) var productState: ProductState = .loading
    private(set) var isSubscribed = false

    #if DEBUG
    /// Debug builds only: opens the paid cards without a purchase.
    var debugUnlocked: Bool = UserDefaults.standard.bool(forKey: "debug.premiumUnlocked") {
        didSet { UserDefaults.standard.set(debugUnlocked, forKey: "debug.premiumUnlocked") }
    }
    #endif

    var isPremium: Bool {
        #if DEBUG
        return isSubscribed || debugUnlocked
        #else
        return isSubscribed
        #endif
    }

    @ObservationIgnored private var updates: Task<Void, Never>?

    init() {
        updates = Task { [weak self] in
            for await update in Transaction.updates {
                if case .verified(let transaction) = update { await transaction.finish() }
                await self?.refreshEntitlements()
            }
        }
        Task { await refreshEntitlements() }
    }

    deinit {
        updates?.cancel()
    }

    func loadProducts() async {
        productState = .loading
        do {
            let products = try await Product.products(for: Self.productIDs)
            let ordered = Self.productIDs.compactMap { id in products.first { $0.id == id } }
            productState = ordered.isEmpty ? .unavailable : .loaded(ordered)
        } catch {
            productState = .unavailable
        }
    }

    func purchase(_ product: Product) async -> PurchaseOutcome {
        do {
            switch try await product.purchase() {
            case .success(let verification):
                guard case .verified(let transaction) = verification else { return .failed }
                await transaction.finish()
                await refreshEntitlements()
                return isSubscribed ? .purchased : .failed
            case .userCancelled:
                return .cancelled
            case .pending:
                return .pending
            @unknown default:
                return .failed
            }
        } catch {
            return .failed
        }
    }

    func restore() async -> RestoreOutcome {
        do {
            try await AppStore.sync()
        } catch {
            return .failed
        }
        await refreshEntitlements()
        return isSubscribed ? .restored : .nothingToRestore
    }

    func refreshEntitlements() async {
        var active = false
        for await entitlement in Transaction.currentEntitlements {
            guard case .verified(let transaction) = entitlement else { continue }
            if Self.productIDs.contains(transaction.productID), transaction.revocationDate == nil {
                active = true
            }
        }
        isSubscribed = active
    }
}
