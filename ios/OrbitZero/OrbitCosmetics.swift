import Foundation

/// Catalog shared by the wardrobe, SpriteKit and verified StoreKit entitlements.
/// These items only change appearance. They never affect hit boxes, score, speed or health.
struct OrbitCosmetic: Identifiable {
    enum Kind { case ship, effect }
    let id: String
    let name: String
    let subtitle: String
    let symbol: String
    let kind: Kind
    let masteryCollection: Int?
    let productID: String?

    static let ships: [OrbitCosmetic] = [
        .init(id: "classic", name: "Original", subtitle: "The signature pale ship", symbol: "circle.hexagongrid", kind: .ship, masteryCollection: nil, productID: nil),
        .init(id: "aurora", name: "Aurora Pearl", subtitle: "Master Aurora · 24 stars", symbol: "sunrise", kind: .ship, masteryCollection: 1, productID: nil),
        .init(id: "monolith", name: "Monolith Slate", subtitle: "Master Monolith · 24 stars", symbol: "mountain.2", kind: .ship, masteryCollection: 2, productID: nil),
        .init(id: "equinox", name: "Equinox Silver", subtitle: "Master Equinox · 24 stars", symbol: "moon.stars", kind: .ship, masteryCollection: 3, productID: nil),
        .init(id: "obsidian", name: "Obsidian Onyx", subtitle: "Master Obsidian · 24 stars", symbol: "circle.lefthalf.filled", kind: .ship, masteryCollection: 4, productID: nil),
        .init(id: "zenith", name: "Zenith Platinum", subtitle: "Master Zenith · 24 stars", symbol: "crown", kind: .ship, masteryCollection: 5, productID: nil),
        .init(id: "nordicgold", name: "Nordic Gold", subtitle: "Warm gold ship and trail", symbol: "sparkle", kind: .ship, masteryCollection: nil, productID: "com.konhagengames.orbitzero.cosmetic.nordicgold"),
        .init(id: "frostglass", name: "Frost Glass", subtitle: "Icy glass ship and trail", symbol: "snowflake", kind: .ship, masteryCollection: nil, productID: "com.konhagengames.orbitzero.cosmetic.frostglass"),
        .init(id: "copper", name: "Copenhagen Copper", subtitle: "A warm copper signature", symbol: "seal", kind: .ship, masteryCollection: nil, productID: "com.konhagengames.orbitzero.cosmetic.copper"),
        .init(id: "void", name: "Void Carbon", subtitle: "Minimal carbon-black finish", symbol: "moon.fill", kind: .ship, masteryCollection: nil, productID: "com.konhagengames.orbitzero.cosmetic.void")
    ]

    static let effects: [OrbitCosmetic] = [
        .init(id: "classic", name: "Classic Pulse", subtitle: "Subtle original animation", symbol: "circle.dotted", kind: .effect, masteryCollection: nil, productID: nil),
        .init(id: "zenithcrown", name: "Zenith Halo", subtitle: "Master Zenith · 24 stars", symbol: "circle.hexagongrid.fill", kind: .effect, masteryCollection: 5, productID: nil),
        .init(id: "aurorawave", name: "Aurora Wave", subtitle: "Soft double-ring pulse", symbol: "waveform.path", kind: .effect, masteryCollection: nil, productID: "com.konhagengames.orbitzero.cosmetic.aurorawave"),
        .init(id: "prismburst", name: "Prism Burst", subtitle: "A geometric light burst", symbol: "diamond", kind: .effect, masteryCollection: nil, productID: "com.konhagengames.orbitzero.cosmetic.prismburst"),
        .init(id: "stardust", name: "Quiet Stardust", subtitle: "A constellation of particles", symbol: "sparkles", kind: .effect, masteryCollection: nil, productID: "com.konhagengames.orbitzero.cosmetic.stardust")
    ]
    static let all = ships + effects
    static let paid = all.filter { $0.productID != nil }
    static let paidIDs = paid.compactMap(\.productID)
    static func byProduct(_ productID: String) -> OrbitCosmetic? { paid.first { $0.productID == productID } }
    static func ship(_ id: String) -> OrbitCosmetic? { ships.first { $0.id == id } }
    static func effect(_ id: String) -> OrbitCosmetic? { effects.first { $0.id == id } }
}
