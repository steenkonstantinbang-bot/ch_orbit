import Foundation
import StoreKit

/// StoreKit 2 shop. Apple supplies all real-money prices and processes payments.
/// No purchased virtual currency or inventory item expires.
@MainActor
final class SparkStore: ObservableObject {
    static let packAmounts: [String: Int] = [
        "com.konhagengames.orbitzero.sparks500": 500,
        "com.konhagengames.orbitzero.sparks1500": 1500,
        "com.konhagengames.orbitzero.sparks5000": 5000
    ]
    static let starterID = "com.konhagengames.orbitzero.bundle.starter"
    static let defenderID = "com.konhagengames.orbitzero.bundle.defender"
    static let nordicGoldID = "com.konhagengames.orbitzero.cosmetic.nordicgold"
    static let signatureCosmeticIDs = OrbitCosmetic.paidIDs

    static let orderedIDs = [
        "com.konhagengames.orbitzero.sparks500",
        "com.konhagengames.orbitzero.sparks1500",
        "com.konhagengames.orbitzero.sparks5000",
        starterID, defenderID
    ] + signatureCosmeticIDs

    // Other product types (Spark packs and kits) are consumables. Cosmetics are all
    // non-consumables: the player owns each design forever while the entitlement is valid.
    static let cosmeticNameMap = Dictionary(uniqueKeysWithValues: OrbitCosmetic.paid.compactMap { cosmetic in
        cosmetic.productID.map { ($0, cosmetic.name) }
    })
    static let cosmeticDetailMap = Dictionary(uniqueKeysWithValues: OrbitCosmetic.paid.compactMap { cosmetic in
        cosmetic.productID.map { ($0, cosmetic.subtitle + " · appearance only") }
    })


    static let names: [String: String] = [
        "com.konhagengames.orbitzero.sparks500": "Sparks · Small",
        "com.konhagengames.orbitzero.sparks1500": "Sparks · Standard",
        "com.konhagengames.orbitzero.sparks5000": "Sparks · Collection",
        starterID: "Launch Kit",
        defenderID: "Defender Kit",
    ].merging(cosmeticNameMap) { _, new in new }
    static let details: [String: String] = [
        "com.konhagengames.orbitzero.sparks500": "+500 virtual Sparks",
        "com.konhagengames.orbitzero.sparks1500": "+1,500 virtual Sparks",
        "com.konhagengames.orbitzero.sparks5000": "+5,000 virtual Sparks",
        starterID: "1,200 Sparks · 3 Bombs · 3 Freeze · 3 Shields",
        defenderID: "4,000 Sparks · 8 Bombs · 5 Freeze · 5 Shields",
    ].merging(cosmeticDetailMap) { _, new in new }

    @Published private(set) var products: [Product] = []
    @Published private(set) var isPurchasing = false
    @Published var message: String?
    weak var game: OrbitGame?
    private var updateTask: Task<Void, Never>?
    private var recoveryTask: Task<Void, Never>?

    var currencyProducts: [Product] { products.filter { Self.packAmounts[$0.id] != nil } }
    var kitProducts: [Product] { products.filter { $0.id == Self.starterID || $0.id == Self.defenderID } }
    var cosmeticProducts: [Product] { products.filter { Self.signatureCosmeticIDs.contains($0.id) } }

    func attach(_ game: OrbitGame) {
        self.game = game
        guard updateTask == nil else { return }
        // Start the listener when the shop is first initialized, not only when it opens.
        updateTask = Task { [weak self] in
            for await update in Transaction.updates {
                guard !Task.isCancelled else { break }
                await self?.deliver(update)
            }
        }
        recoveryTask = Task { [weak self] in
            guard let self else { return }
            // Unfinished purchases can arrive after an app crash or interrupted delivery.
            for await item in Transaction.unfinished {
                await self.deliver(item)
            }
            await self.refreshEntitlements()
        }
    }

    func loadProducts() async {
        do {
            let loaded = try await Product.products(for: Self.orderedIDs)
            products = loaded.filter { product in
                let expected: Product.ProductType = Self.signatureCosmeticIDs.contains(product.id) ? .nonConsumable : .consumable
                return product.type == expected
            }.sorted { a, b in
                (Self.orderedIDs.firstIndex(of: a.id) ?? Int.max) < (Self.orderedIDs.firstIndex(of: b.id) ?? Int.max)
            }
        } catch {
            // Do not show nonworking purchase buttons or pretend a transaction happened.
            message = "Purchases are unavailable. Check your connection or App Store Connect setup."
        }
    }

    func purchase(_ product: Product) async {
        guard !isPurchasing else { return }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification): await deliver(verification)
            case .pending: message = "Purchase pending Apple approval. No items have been added yet."
            case .userCancelled: break
            @unknown default: message = "The purchase could not be completed."
            }
        } catch {
            message = "Purchase failed. No items were added. Please try again."
        }
    }

    func restorePurchases() async {
        guard !isPurchasing else { return }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            message = (game?.ownedPaidCosmetics.isEmpty == false) ? "Your permanent cosmetics have been synchronized." : "No active permanent purchases found."
        } catch {
            message = "Could not sync purchases with Apple. Try again later."
        }
    }

    private func refreshEntitlements() async {
        var entitled: Set<String> = []
        for await verification in Transaction.currentEntitlements {
            guard case .verified(let transaction) = verification else { continue }
            guard transaction.revocationDate == nil else { continue }
            if let cosmetic = OrbitCosmetic.byProduct(transaction.productID) {
                entitled.insert(cosmetic.id)
            }
        }
        game?.syncPaidCosmeticEntitlements(entitled)
    }

    private func deliver(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else {
            message = "Apple could not verify this transaction. Nothing was added."
            return
        }
        guard let game else {
            // Don't finish; StoreKit can redeliver this transaction on the next launch.
            return
        }
        let id = transaction.productID
        guard Self.orderedIDs.contains(id) else { return }
        if transaction.revocationDate != nil {
            if let cosmetic = OrbitCosmetic.byProduct(id) { game.setPaidCosmeticEntitlement(cosmetic.id, owned: false) }
            await transaction.finish()
            return
        }

        if let cosmetic = OrbitCosmetic.byProduct(id) {
            game.setPaidCosmeticEntitlement(cosmetic.id, owned: true)
            message = "\(cosmetic.name) unlocked. Equip it in your Hangar."
            await transaction.finish()
            return
        }
        let transactionKey = String(transaction.id)
        let ledgerKey = "oz.deliveredConsumableTransactions"
        var delivered = UserDefaults.standard.stringArray(forKey: ledgerKey) ?? []
        if !delivered.contains(transactionKey) {
            // Device-local ledger avoids duplicate grants when an unfinished transaction
            // is presented again. For a commercial launch, use a backend ledger keyed
            // by Apple's transaction ID for robust recovery across installs/devices.
            let amount = Self.packAmounts[id] ?? (id == Self.starterID ? 1200 : 4000)
            let bonuses: [OrbitGame.PowerUp: Int]
            if id == Self.starterID {
                bonuses = [.bomb: 3, .freeze: 3, .shield: 3]
            } else if id == Self.defenderID {
                bonuses = [.bomb: 8, .freeze: 5, .shield: 5]
            } else {
                bonuses = [:]
            }
            game.grantPurchasedItems(sparks: amount, powers: bonuses)
            delivered.append(transactionKey)
            UserDefaults.standard.set(delivered, forKey: ledgerKey)
            message = "Purchase complete: \(Self.names[id] ?? "Items") added."
        }
        await transaction.finish()
    }
}
