import Foundation
import SwiftUI

// Five curated Collections, eight missions each. All playable offline.
struct OrbitMission: Identifiable {
    enum Objective {
        case jumps(Int)
        case perfect(Int)
        case combo(Int)
        case score(Int)
        case clean(Int, Int)
        case charge(Int)
        case defense(Int)
        case boss(Int)
    }
    enum Boss: String {
        case sentinel = "THE SENTINEL"
        case vortex = "THE VORTEX"
        case mirage = "MIRROR WARDEN"
        case prism = "THE PRISM"
        case eclipse = "ECLIPSE TITAN"
    }
    static let collectionNames = ["Aurora", "Monolith", "Equinox", "Obsidian", "Zenith"]
    static let collectionDescriptions = [
        "Discover precision", "Control the momentum", "Master the illusion",
        "Survive the shadows", "Reach the absolute summit"
    ]
    let id: Int
    let title: String
    let briefing: String
    let objective: Objective
    var chapter: Int { (id - 1) / 8 + 1 }
    var step: Int { (id - 1) % 8 + 1 }
    var collectionName: String { Self.collectionNames[chapter - 1] }
    var isBoss: Bool { if case .boss = objective { return true }; return false }
    var boss: Boss? {
        switch id {
        case 8: return .sentinel
        case 16: return .vortex
        case 24: return .mirage
        case 32: return .prism
        case 40: return .eclipse
        default: return nil
        }
    }
    var goal: Int {
        switch objective {
        case .jumps(let x), .perfect(let x), .combo(let x), .score(let x), .charge(let x), .defense(let x), .boss(let x): return x
        case .clean(let x, _): return x
        }
    }
    var label: String {
        switch objective {
        case .jumps(let x): return "LAND \(x) GATE JUMPS"
        case .perfect(let x): return "LAND \(x) PERFECT HITS"
        case .combo(let x): return "REACH A \(x)× COMBO"
        case .score(let x): return "EARN \(x.formatted()) POINTS"
        case .clean(let x, let maxMisses): return "LAND \(x) JUMPS · MAX \(maxMisses) MISSES"
        case .charge(let x): return "CAPTURE \(x) GOLD CHARGES · PERFECT ONLY"
        case .defense(let x): return "NEUTRALIZE \(x) COMPUTER POINTS"
        case .boss(let x): return "BREAK \(x) CORE SHIELDS"
        }
    }
    // A long-form campaign: several revolutions and defensive interceptions are mandatory.
    var minOrbits: Int { (isBoss ? 5 : 3) + chapter + (step >= 5 ? 1 : 0) }
    var defenseQuota: Int {
        if case .defense(let amount) = objective { return amount }
        return 2 + chapter * 2 + (isBoss ? chapter + 2 : (step >= 5 ? 1 : 0))
    }
    var reward: Int { isBoss ? 1200 + chapter * 400 : 250 + id * 33 }
    var difficulty: String { ["DISCOVER", "CONTROL", "DECEIVE", "ENDURE", "MASTER"][chapter - 1] }
    static let all: [OrbitMission] = [
        .init(id: 1, title: "FIRST LIGHT", briefing: "Learn to capture gates while intercepting red computer points.", objective: .jumps(8)),
        .init(id: 2, title: "THE CENTRE", briefing: "Prove your timing and defend the orbit over several revolutions.", objective: .perfect(6)),
        .init(id: 3, title: "QUIET MOMENTUM", briefing: "Keep a long clean streak without losing control of the attack meter.", objective: .combo(7)),
        .init(id: 4, title: "RED SIGNAL", briefing: "Intercept the computer’s points before the threat track fills.", objective: .defense(7)),
        .init(id: 5, title: "GOLD FREQUENCY", briefing: "Collect charges while keeping computer points under control.", objective: .charge(4)),
        .init(id: 6, title: "STILLNESS", briefing: "Complete a sustained clean run with only one mistake allowed.", objective: .clean(11,1)),
        .init(id: 7, title: "BEFORE DAWN", briefing: "Build an eight-hit streak and hold your defense across several orbits.", objective: .combo(8)),
        .init(id: 8, title: "THE SENTINEL", briefing: "Defend the orbit while the Sentinel reverses after every strike.", objective: .boss(10)),
        .init(id: 9, title: "STONE CIRCLE", briefing: "Intercept red points between gates in a heavier orbit.", objective: .jumps(12)),
        .init(id: 10, title: "GRAVITY LINE", briefing: "Collect six precise gold charges under increasing pressure.", objective: .charge(6)),
        .init(id: 11, title: "COLD FRONT", briefing: "Pulse gates become narrow; land eight PERFECT hits.", objective: .perfect(8)),
        .init(id: 12, title: "BREACH PROTOCOL", briefing: "Destroy computer points while the orbit changes direction.", objective: .defense(10)),
        .init(id: 13, title: "IRON PULSE", briefing: "Reach 9,000 points without letting the computer fill its track.", objective: .score(9000)),
        .init(id: 14, title: "FAULT LINE", briefing: "Land fourteen gates and allow no more than one error.", objective: .clean(14,1)),
        .init(id: 15, title: "TREMOR", briefing: "Gather seven charges while defending through repeated revolutions.", objective: .charge(7)),
        .init(id: 16, title: "THE VORTEX", briefing: "The Vortex accelerates the orbit. Break twelve layers while defending.", objective: .boss(12)),
        .init(id: 17, title: "TWIN SIGNAL", briefing: "A false gate appears. Follow the pale signal and intercept threats.", objective: .jumps(15)),
        .init(id: 18, title: "HALF LIGHT", briefing: "Find ten PERFECT timing windows between computer points.", objective: .perfect(10)),
        .init(id: 19, title: "REFLECTION", briefing: "Keep a ten-jump chain as the orbit rotates through decoys.", objective: .combo(10)),
        .init(id: 20, title: "COUNTER STRIKE", briefing: "Neutralize twelve computer points before they overwhelm the orbit.", objective: .defense(12)),
        .init(id: 21, title: "SPECTRUM", briefing: "Gather eight golden charges as the computer escalates.", objective: .charge(8)),
        .init(id: 22, title: "BALANCE", briefing: "Land sixteen gates while allowing only one missed jump.", objective: .clean(16,1)),
        .init(id: 23, title: "THE OTHER SIDE", briefing: "Hold a twelve-jump streak through double signals.", objective: .combo(12)),
        .init(id: 24, title: "MIRROR WARDEN", briefing: "Ignore the rose decoy and defend against incoming points.", objective: .boss(14)),
        .init(id: 25, title: "DARK MATTER", briefing: "Complete eighteen accurate gates through the shadow orbit.", objective: .jumps(18)),
        .init(id: 26, title: "LAST PHOTON", briefing: "Survive the pulse to land twelve PERFECT hits.", objective: .perfect(12)),
        .init(id: 27, title: "NOCTURNE", briefing: "Hold a fourteen-jump chain. A miss resets it.", objective: .combo(14)),
        .init(id: 28, title: "THE SIEGE", briefing: "Disarm fourteen enemy points in the darkest collection.", objective: .defense(14)),
        .init(id: 29, title: "BLACK GOLD", briefing: "Collect ten charged gates while constantly clearing red points.", objective: .charge(10)),
        .init(id: 30, title: "SILENT RUN", briefing: "Complete eighteen gates with zero misses.", objective: .clean(18,0)),
        .init(id: 31, title: "SHADOW PLAY", briefing: "Land thirteen PERFECT hits amid speed changes and decoys.", objective: .perfect(13)),
        .init(id: 32, title: "THE PRISM", briefing: "The Prism hides the real gate and intensifies computer pressure.", objective: .boss(16)),
        .init(id: 33, title: "THE SUMMIT", briefing: "Master twenty gates with every obstacle active.", objective: .jumps(20)),
        .init(id: 34, title: "PURE FORM", briefing: "Land fifteen PERFECT hits while holding the defense.", objective: .perfect(15)),
        .init(id: 35, title: "LIMITLESS", briefing: "Build a sixteen-jump combo without losing your composure.", objective: .combo(16)),
        .init(id: 36, title: "FINAL DEFENSE", briefing: "Neutralize eighteen incoming points over the final orbit.", objective: .defense(18)),
        .init(id: 37, title: "THE GOLDEN ARC", briefing: "Collect twelve charged gates to unlock the final core.", objective: .charge(12)),
        .init(id: 38, title: "THE UNBROKEN", briefing: "Land twenty gates, suffer no misses and defend the whole run.", objective: .clean(20,0)),
        .init(id: 39, title: "ASCENT", briefing: "Build an eighteen-jump streak with every mechanic active.", objective: .combo(18)),
        .init(id: 40, title: "ECLIPSE TITAN", briefing: "Final boss: break twenty core layers while the computer deploys two points every lap.", objective: .boss(20)),
    ]
    static func find(_ id: Int) -> OrbitMission { all[max(0, min(all.count - 1, id - 1))] }

    /// Only consecutive cleared missions grant access to the next mission.
    /// One or more stars means the mission was completed; three stars are not required.
    /// Always derive this from completed missions, never from a stored unlock number.
    static func highestUnlocked(from stars: [Int: Int]) -> Int {
        var next = 1
        while next < all.count && stars[next, default: 0] >= 1 {
            next += 1
        }
        return next
    }
}

struct ComputerPoint: Identifiable, Equatable {
    let id: UUID
    let angle: Double
    // Tracks are persistent; missed points remain until the player intercepts them.
    init(angle: Double) { self.id = UUID(); self.angle = angle }
}

final class OrbitGame: ObservableObject {
    enum Screen { case home, missions, briefing, playing, paused, missionComplete, dailyComplete, gameOver, shop, settings }
    enum PlayMode { case campaign, endless, daily }
    enum PowerUp: String, CaseIterable, Identifiable {
        case bomb, freeze, shield
        var id: String { rawValue }
        var title: String {
            switch self { case .bomb: return "ORBIT BOMB"; case .freeze: return "TIME FREEZE"; case .shield: return "EXTRA SHIELD" }
        }
        var details: String {
            switch self {
            case .bomb: return "Skip one gate or damage a boss once"
            case .freeze: return "Slow orbital movement for 8 seconds"
            case .shield: return "Restore one shield, up to five"
            }
        }
        var symbol: String {
            switch self { case .bomb: return "burst.fill"; case .freeze: return "snowflake"; case .shield: return "shield.fill" }
        }
        var price: Int {
            switch self { case .bomb: return 1200; case .freeze: return 650; case .shield: return 500 }
        }
    }

    @Published private(set) var screen: Screen = .home
    @Published private(set) var playMode: PlayMode = .campaign
    @Published private(set) var selectedMission = 1
    @Published private(set) var unlockedMission: Int
    @Published private(set) var missionStars: [Int: Int]
    @Published private(set) var masteredCollections: Set<Int>
    @Published private(set) var missionProgress = 0
    @Published private(set) var orbitCount = 0
    @Published private(set) var computerPoints: [ComputerPoint] = []
    @Published private(set) var interceptedPoints = 0
    @Published private(set) var peakComputerPoints = 0
    @Published private(set) var lossReason = ""
    private var orbitStartAngle = -Double.pi / 2
    private var nextRevolution = 1
    // Persistent skill progression. XP comes from first clears and improved star ratings.
    @Published private(set) var pilotXP: Int
    @Published private(set) var earnedPilotXP = 0
    @Published private(set) var isFinishing = false
    @Published private(set) var riftAngle: Double? = nil
    private var finishingRemaining = 0.0
    private var alternateGateTurn = false
    @Published private(set) var missionReward = 0
    @Published private(set) var resultStars = 0
    @Published private(set) var score = 0
    @Published private(set) var wave = 1
    @Published private(set) var shields = 3
    @Published private(set) var combo = 0
    @Published private(set) var perfectStreak = 0
    @Published private(set) var focusSeconds = 0
    @Published private(set) var lastDailyCompletion: String
    @Published private(set) var sparks: Int
    @Published private(set) var ownedPaidCosmetics: Set<String>
    @Published private(set) var equippedShipID: String
    @Published private(set) var equippedEffectID: String
    var hasNordicGold: Bool { ownedPaidCosmetics.contains("nordicgold") }
    var nordicGoldEquipped: Bool { equippedShipID == "nordicgold" }
    @Published private(set) var best: Int
    @Published private(set) var inventory: [PowerUp: Int]
    @Published private(set) var timeSeconds = 15
    @Published var statusText = ""
    @Published var soundEnabled: Bool { didSet { UserDefaults.standard.set(soundEnabled, forKey: "oz.sound") } }
    @Published var musicEnabled: Bool { didSet { UserDefaults.standard.set(musicEnabled, forKey: "oz.music") } }
    @Published var hapticsEnabled: Bool { didSet { UserDefaults.standard.set(hapticsEnabled, forKey: "oz.haptics") } }
    @Published var effectsEnabled: Bool { didSet { UserDefaults.standard.set(effectsEnabled, forKey: "oz.effects") } }
    @Published var easyMode: Bool { didSet { UserDefaults.standard.set(easyMode, forKey: "oz.easy") } }

    let scene: OrbitScene
    private var previousScreen: Screen = .home
    private var remaining = 15.0
    private var statusRemaining = 0.0
    private var hits = 0
    private var perfectHits = 0
    private var longestPerfectStreak = 0
    private var misses = 0
    private var elapsed = 0.0
    private var bossShiftRemaining = 4.5
    private var shiftRemaining = 4.3
    private var focusRemaining = 0.0
    private var usedBomb = false
    private var chargesCollected = 0
    private var lastBossPhase = 0
    @Published private(set) var surgeSeconds = 0
    private var surgeClock = 0.0
    private(set) var angle = -Double.pi / 2
    private(set) var gate = 1.1
    @Published private(set) var bossHealth = 0
    private(set) var freezeRemaining = 0.0
    private var gateDrift = 0.12

    // Stable XP thresholds; no level can be bought with Sparks or real money.
    private var rankTable: [(name: String, xp: Int)] {
        [("Cadet", 0), ("Navigator", 500), ("Orbital Pilot", 1500),
         ("Pathfinder", 3200), ("Commander", 5600),
         ("Star Marshal", 9000), ("Elite Commander", 14000)]
    }
    var pilotRankName: String { rankTable.last(where: { pilotXP >= $0.xp })?.name ?? "Cadet" }
    var pilotNextRankName: String { rankTable.first(where: { pilotXP < $0.xp })?.name ?? "MAX RANK" }
    var pilotXPToNext: Int { rankTable.first(where: { pilotXP < $0.xp })?.xp ?? pilotXP }
    var pilotRankFraction: Double {
        guard let current = rankTable.last(where: { pilotXP >= $0.xp }),
              let next = rankTable.first(where: { pilotXP < $0.xp }) else { return 1 }
        return min(1, max(0, Double(pilotXP - current.xp) / Double(next.xp - current.xp)))
    }
    // The orbital route evolves only after the player has learned its basic controls.
    var dualGateActive: Bool {
        guard isPlaying else { return false }
        return ((isCampaign && mission.chapter >= 2) || (isDaily && orbitCount >= 5) ||
                (!isCampaign && !isDaily && wave >= 5) ||
                (bossType == .prism && bossPhase >= 2)) && orbitCount >= 3
    }
    var inactiveGateAngle: Double { gate + .pi }
    var bossPhase: Int {
        guard bossHealth > 0 else { return 0 }
        let total = isCampaign ? mission.goal : 4 + wave / 12
        if bossHealth * 3 <= total { return 3 }
        if bossHealth * 3 <= total * 2 { return 2 }
        return 1
    }
    private var riftsEnabled: Bool {
        ((isCampaign && mission.chapter >= 3) || (!isCampaign && !isDaily && wave >= 10) ||
         (bossType == .vortex && bossPhase >= 2)) && orbitCount >= 3
    }
    var riftApproaching: Bool {
        guard let a = riftAngle else { return false }
        let ahead = (a - angle).truncatingRemainder(dividingBy: 2 * .pi)
        return ahead > 0 && ahead < 0.72
    }

    var computerCapacity: Int { // Fewer slots in harder Collections, but always two new points per lap.
        isDaily ? 9 : (isCampaign ? max(6, 11 - mission.chapter) : max(6, 10 - wave / 6))
    }
    var computerFraction: Double { Double(computerPoints.count) / Double(computerCapacity) }
    var computerOverdrive: Bool { computerFraction >= 0.65 }
    var defenseTarget: Int { isCampaign ? mission.defenseQuota : (isDaily ? 3 : 0) }
    var orbitTarget: Int { isCampaign ? mission.minOrbits : (isDaily ? 3 : 0) }
    var defenseReady: Bool { interceptedPoints >= defenseTarget && orbitCount >= orbitTarget }
    var defenseStatus: String {
        if isCampaign || isDaily { return "BLOCK \(min(interceptedPoints, defenseTarget))/\(defenseTarget) · LAPS \(min(orbitCount, orbitTarget))/\(orbitTarget)" }
        return "INTERCEPTED \(interceptedPoints) · LAPS \(orbitCount)"
    }
    var isPlaying: Bool { screen == .playing }
    var isCampaign: Bool { playMode == .campaign }
    var isDaily: Bool { playMode == .daily }
    var dailyKey: String { Self.dayKey(Date()) }
    var dailyCompleted: Bool { lastDailyCompletion == dailyKey }
    private static func dayKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    var dailyVariant: Int { (Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 1) % 3 }
    var dailyTarget: Int { dailyVariant == 0 ? 12 : dailyVariant == 1 ? 8 : 8 }
    var dailyGoal: String {
        switch dailyVariant {
        case 0: return "Land 12 gates · maximum 1 miss"
        case 1: return "Land 8 PERFECT hits · maximum 1 miss"
        default: return "Reach an 8× combo · maximum 1 miss"
        }
    }
    var dailyProgress: Int {
        switch dailyVariant {
        case 0: return hits
        case 1: return perfectHits
        default: return combo
        }
    }
    var isChargeMission: Bool {
        guard isCampaign else { return false }
        if case .charge = mission.objective { return true }
        return false
    }
    var isChargeGate: Bool { isPlaying && isChargeMission && hits.isMultiple(of: 2) }
    var surgeActive: Bool { isPlaying && surgeSeconds > 0 }
    var pulseActive: Bool {
        isPlaying && (bossType == .vortex || bossType == .prism || (isDaily || (isCampaign && (mission.chapter >= 4 || [4, 11, 13, 18, 26].contains(selectedMission))) || (!isCampaign && !isDaily && wave >= 5)))
    }
    var pulseLevel: Double { 0.5 + 0.5 * sin(elapsed * 4.2) }
    var reversalActive: Bool {
        isPlaying && bossType != .sentinel && (isDaily || (isCampaign && mission.chapter >= 2) || (!isCampaign && !isDaily && wave >= 9))
    }
    var focusActive: Bool { focusRemaining > 0 }

    var mission: OrbitMission { OrbitMission.find(selectedMission) }
    var isBossWave: Bool { bossHealth > 0 }
    var bossType: OrbitMission.Boss? { isCampaign ? mission.boss : (isBossWave ? .sentinel : nil) }
    var bossTitle: String { bossType?.rawValue ?? "VOID BOSS" }
    var missionCount: Int { OrbitMission.all.count }
    var totalStars: Int { missionStars.values.reduce(0, +) }
    func starsInCollection(_ number: Int) -> Int {
        (1...8).reduce(0) { total, index in
            total + missionStars[(number - 1) * 8 + index, default: 0]
        }
    }
    var progressLabel: String {
        if isDaily { return "DAILY CHALLENGE" }
        if !isCampaign { return "WAVE \(wave) · ENDLESS" }
        return "MISSION \(selectedMission) / \(missionCount)"
    }
    var missionGoal: String { isDaily ? dailyGoal : (isCampaign ? mission.label : "Survive the orbit") }
    var progressText: String {
        if isDaily { return "\(min(dailyProgress, dailyTarget)) / \(dailyTarget)" }
        guard isCampaign else { return "\(combo)× COMBO" }
        if mission.isBoss { return "BOSS HP \(bossHealth) / \(mission.goal)" }
        return "\(min(missionProgress, mission.goal)) / \(mission.goal)"
    }
    var missionFraction: Double {
        if isDaily { return min(1.0, Double(dailyProgress) / Double(dailyTarget)) }
        guard isCampaign else { return 0 }
        if mission.isBoss { return Double(mission.goal - bossHealth) / Double(mission.goal) }
        return min(1.0, Double(missionProgress) / Double(mission.goal))
    }
    var decoyGate: Double? {
        guard isPlaying else { return nil }
        let decoyOn = bossType == .mirage || bossType == .prism ||
            (isBossWave && bossPhase == 3 && bossType == .sentinel) ||
            (isCampaign && mission.chapter >= 3 && [1, 4, 7].contains(mission.step))
        guard decoyOn else { return nil }
        return gate + .pi - 0.26 + sin(elapsed * 1.8) * 0.23
    }
    var eclipseArmor: Bool { bossType == .eclipse && bossHealth > 0 && bossHealth <= 3 }
    var gateWidth: Double {
        let level = isDaily ? 3 : (isCampaign ? mission.chapter * 4 + mission.step : wave)
        let base = easyMode ? 0.40 : 0.32
        let regular = max(0.18, base - min(0.125, Double(level) * 0.0043) - (isBossWave ? 0.012 : 0))
        let pressureWidth = computerOverdrive ? regular * 0.92 : regular
        let phaseWidth = isBossWave && bossPhase == 3 ? pressureWidth * 0.84 : pressureWidth
        return pulseActive ? phaseWidth * (0.72 + 0.28 * pulseLevel) : phaseWidth
    }

    init() {
        let d = UserDefaults.standard
        sparks = d.object(forKey: "oz.sparks") as? Int ?? 800
        // Migrate the existing Nordic Gold entitlement/equipped state from v1.1.
        var legacyOwned = Set(d.stringArray(forKey: "oz.ownedPaidCosmetics") ?? [])
        if d.bool(forKey: "oz.nordicGoldOwned") { legacyOwned.insert("nordicgold") }
        ownedPaidCosmetics = legacyOwned
        equippedShipID = d.string(forKey: "oz.equippedShipID") ?? (d.bool(forKey: "oz.nordicGoldEquipped") ? "nordicgold" : "classic")
        equippedEffectID = d.string(forKey: "oz.equippedEffectID") ?? "classic"
        lastDailyCompletion = d.string(forKey: "oz.dailyComplete") ?? ""
        best = d.integer(forKey: "oz.best")
        inventory = [.bomb: d.integer(forKey: "oz.bomb"),
                     .freeze: d.object(forKey: "oz.freeze") as? Int ?? 1,
                     .shield: d.integer(forKey: "oz.shield")]
        // Previous releases could persist an inflated unlock number (e.g. test mode).
        // Real access is reconstructed below from consecutively completed missions.
        masteredCollections = Set(d.array(forKey: "oz.masteredCollections") as? [Int] ?? [])
        let completedStars: [Int: Int]
        if let stored = d.dictionary(forKey: "oz.missionStars") as? [String: Int] {
            var decoded: [Int: Int] = [:]
            for (k, v) in stored {
                if let key = Int(k), (1...OrbitMission.all.count).contains(key) {
                    decoded[key] = min(3, max(0, v))
                }
            }
            completedStars = decoded
        } else {
            completedStars = [:]
        }
        // Calculate the next unlocked mission before reading any stored property.
        // Swift prohibits accessing `self.unlockedMission` until every property is initialized.
        let verifiedUnlock = OrbitMission.highestUnlocked(from: completedStars)
        missionStars = completedStars
        unlockedMission = verifiedUnlock
        // Keep old save key synchronized for compatibility; it is not trusted for access.
        d.set(verifiedUnlock, forKey: "oz.unlockedMission")
        let migratedXP = completedStars.reduce(0) { result, item in
            result + (item.value > 0 ? 100 + 35 * item.value : 0)
        }
        pilotXP = d.object(forKey: "oz.pilotXP") as? Int ?? migratedXP
        soundEnabled = d.object(forKey: "oz.sound") as? Bool ?? true
        musicEnabled = d.object(forKey: "oz.music") as? Bool ?? true
        hapticsEnabled = d.object(forKey: "oz.haptics") as? Bool ?? true
        effectsEnabled = d.object(forKey: "oz.effects") as? Bool ?? true
        easyMode = d.object(forKey: "oz.easy") as? Bool ?? false
        scene = OrbitScene(size: CGSize(width: 390, height: 760))
        scene.scaleMode = .resizeFill
        scene.game = self
    }

    private func resetRun() {
        score = 0; wave = 1; shields = 3; combo = 0; perfectStreak = 0
        focusRemaining = 0; focusSeconds = 0; shiftRemaining = 4.3
        chargesCollected = 0; surgeSeconds = 0; surgeClock = 0; lastBossPhase = 0
        hits = 0; perfectHits = 0; longestPerfectStreak = 0; misses = 0; elapsed = 0
        angle = -.pi / 2; gate = 1.1; bossHealth = 0
        orbitStartAngle = angle; nextRevolution = 1
        orbitCount = 0; computerPoints = []; interceptedPoints = 0; peakComputerPoints = 0; lossReason = ""
        freezeRemaining = 0; gateDrift = 0.12; remaining = 15; timeSeconds = 15
        missionProgress = 0; missionReward = 0; resultStars = 0; usedBomb = false
        earnedPilotXP = 0; isFinishing = false; finishingRemaining = 0
        riftAngle = nil; alternateGateTurn = false
        statusText = isDaily ? "DAILY START" : "READY"; statusRemaining = 1.3
        bossShiftRemaining = 4.5
        scene.clearEffects()
    }
    private func begin() {
        resetRun()
        if isCampaign && mission.isBoss {
            lastBossPhase = 1
            bossHealth = mission.goal
            remaining = 17
            timeSeconds = 17
            statusText = bossTitle
            scene.emitBossIntro(title: bossTitle)
            AudioFeedback.shared.play(.boss, enabled: soundEnabled)
        } else { AudioFeedback.shared.play(.start, enabled: soundEnabled) }
        screen = .playing
    }
    func isMissionUnlocked(_ id: Int) -> Bool {
        guard (1...missionCount).contains(id) else { return false }
        // The model and UI share the same verified sequential progression rule.
        return id <= unlockedMission && (id == 1 || missionStars[id - 1, default: 0] >= 1)
    }
    func isCollectionUnlocked(_ collection: Int) -> Bool {
        guard (1...OrbitMission.collectionNames.count).contains(collection) else { return false }
        return isMissionUnlocked((collection - 1) * 8 + 1)
    }
    func selectMission(_ id: Int) {
        guard isMissionUnlocked(id) else { return }
        selectedMission = id
        screen = .briefing
    }
    func backToMissions() { screen = .missions }
    func startMission(_ id: Int) {
        guard isMissionUnlocked(id) else { return }
        selectedMission = id
        playMode = .campaign
        begin()
    }
    func startEndless() { playMode = .endless; begin() }
    func startDaily() { playMode = .daily; begin() }
    func retry() { if isCampaign { startMission(selectedMission) } else if isDaily { startDaily() } else { startEndless() } }
    func startNextMission() {
        let next = selectedMission + 1
        guard isMissionUnlocked(next) else { return }
        selectMission(next)
    }
    func openMissions() {
        previousScreen = screen == .playing ? .paused : screen
        screen = .missions
    }
    func pause() { if screen == .playing && !isFinishing { screen = .paused } }
    func resume() { if screen == .paused { screen = .playing } }
    func goHome() { screen = .home; statusText = "" }
    func openShop() { previousScreen = screen == .playing ? .paused : screen; screen = .shop }
    func openSettings() { previousScreen = screen == .playing ? .paused : screen; screen = .settings }
    func closePanel() { screen = previousScreen }

    func advance(_ dt: TimeInterval) {
        guard screen == .playing else { return }
        if isFinishing {
            finishingRemaining -= dt
            if finishingRemaining <= 0 {
                isFinishing = false
                screen = .missionComplete
            }
            return
        }
        surgeClock += dt
        // A clearly signposted 1.6s overdrive every 8s in later Collections.
        let useSurge = (bossType == .vortex || bossType == .prism || (isCampaign && mission.chapter >= 4 && mission.step >= 3))
        if useSurge && surgeClock >= 8 {
            surgeClock = 0
            surgeSeconds = 2
            announce("ORBIT SURGE")
            scene.emitSurge()
            AudioFeedback.shared.play(.surge, enabled: soundEnabled)
        }
        let speedFactor = (freezeRemaining > 0 ? 0.48 : 1.0) * (focusRemaining > 0 ? 0.72 : 1.0)
        let level = isDaily ? 3 : (isCampaign ? mission.chapter * 4 + mission.step : wave)
        var speed = (1.40 + min(1.20, Double(level) * 0.049)) * speedFactor
        if surgeSeconds > 0 { speed *= 1.28 }
        if computerOverdrive { speed *= 1.10 }
        if isBossWave { speed *= (bossPhase == 3 ? 1.17 : (bossPhase == 2 ? 1.07 : 1)) }
        if bossType == .eclipse && eclipseArmor { speed *= 1.18 }
        angle += dt * speed
        // An exact 360° revolution triggers exactly two new computer points.
        // The while loop also makes the rule safe during lag/spikes.
        let rotations = Int(floor((angle - orbitStartAngle) / (2 * .pi)))
        while rotations >= nextRevolution && isPlaying {
            nextRevolution += 1
            orbitCount += 1
            deployComputerPoints()
            if isPlaying { spawnGravityRiftIfNeeded() }
        }
        guard isPlaying else { return }
        if let rift = riftAngle, angularDistance(angle, rift) < 0.095 {
            riftAngle = nil
            fail("GRAVITY RIFT · DODGE NEXT TIME")
            if !isPlaying { return }
        }
        gate += dt * gateDrift * speedFactor
        elapsed += dt
        remaining -= dt
        if bossType == .mirage {
            bossShiftRemaining -= dt
            if bossShiftRemaining <= 0 {
                // Rhythm switch, signaled by both a flash and an announcement.
                gateDrift = -gateDrift * 1.18
                bossShiftRemaining = 4.5
                scene.emitShockwave(color: .pink)
                announce("MIRROR SHIFT")
                AudioFeedback.shared.play(.shift, enabled: soundEnabled)
            }
        }
        if reversalActive {
            shiftRemaining -= dt
            if shiftRemaining <= 0 {
                gateDrift = -gateDrift
                shiftRemaining = 4.3
                announce("DIRECTION SHIFT")
                AudioFeedback.shared.play(.shift, enabled: soundEnabled)
                scene.emitShockwave(color: .aqua)
            }
        }
        if surgeSeconds > 0 && surgeClock >= 1.6 { surgeSeconds = 0 }
        if focusRemaining > 0 { focusRemaining = max(0, focusRemaining - dt) }
        let nextFocus = Int(ceil(focusRemaining))
        if nextFocus != focusSeconds { focusSeconds = nextFocus }
        if freezeRemaining > 0 { freezeRemaining = max(0, freezeRemaining - dt) }
        if statusRemaining > 0 {
            statusRemaining -= dt
            if statusRemaining <= 0 { statusText = "" }
        }
        let rounded = Int(ceil(max(0, remaining)))
        if rounded != timeSeconds { timeSeconds = rounded }
        if remaining <= 0 { fail("TIME EXPIRED") }
    }

    // A single warning arc. Players dodge using the same tap as a gate or intercept.
    // Never placed immediately on the ship; additional rifts are not stacked.
    private func spawnGravityRiftIfNeeded() {
        guard riftsEnabled && riftAngle == nil && orbitCount.isMultiple(of: 2) else { return }
        var candidate = angle + 2.3
        for _ in 0..<12 {
            let clearGate = angularDistance(candidate, gate) > gateWidth + 0.46
            let clearPoints = computerPoints.allSatisfy { angularDistance(candidate, $0.angle) > 0.44 }
            if clearGate && clearPoints { break }
            candidate += 0.26
        }
        riftAngle = candidate
        announce("GRAVITY RIFT · TAP TO EVADE")
        scene.emitRiftWarning(at: candidate)
        AudioFeedback.shared.play(.shift, enabled: soundEnabled)
    }

    private func tryDodgeRift() -> Bool {
        guard let rift = riftAngle, angularDistance(angle, rift) < 0.22 else { return false }
        riftAngle = nil
        score += 280
        scene.emitRiftDodge(at: rift)
        announce("RIFT EVADED · +280")
        AudioFeedback.shared.play(.intercept, enabled: soundEnabled)
        AudioFeedback.shared.haptic(.success, enabled: hapticsEnabled)
        persist()
        return true
    }

    // Placed ahead of the ship in separate sectors, away from the active gate
    // and existing points. This prevents unreactable or overlapping objectives.
    private func deployComputerPoints() {
        let sectors = [0.9...2.45, 3.65...5.15]
        for sector in sectors {
            var candidate = angle + Double.random(in: sector)
            for _ in 0..<30 {
                let distanceToGate = angularDistance(candidate, gate)
                let spaced = computerPoints.allSatisfy { angularDistance(candidate, $0.angle) > 0.40 }
                if distanceToGate > gateWidth + 0.32 && spaced { break }
                candidate = angle + Double.random(in: sector)
            }
            computerPoints.append(ComputerPoint(angle: candidate))
            if computerPoints.count >= computerCapacity {
                peakComputerPoints = computerCapacity
                computerWins()
                return
            }
        }
        peakComputerPoints = max(peakComputerPoints, computerPoints.count)
        announce("+2 COMPUTER POINTS")
        scene.emitComputerDeployment()
        AudioFeedback.shared.play(.deploy, enabled: soundEnabled)
        AudioFeedback.shared.haptic(.light, enabled: hapticsEnabled)
    }

    private func angularDistance(_ lhs: Double, _ rhs: Double) -> Double {
        abs(atan2(sin(lhs - rhs), cos(lhs - rhs)))
    }

    private func computerWins() {
        guard isPlaying else { return }
        lossReason = "COMPUTER WINS · ALL POINT SLOTS FILLED"
        best = max(best, score)
        announce("COMPUTER WINS")
        scene.emitComputerVictory()
        AudioFeedback.shared.play(.failure, enabled: soundEnabled)
        AudioFeedback.shared.haptic(.failure, enabled: hapticsEnabled)
        screen = .gameOver
        persist()
    }

    private func tryInterceptComputerPoint() -> Bool {
        let tolerance: Double = max(0.155, 0.28 - Double(isCampaign ? mission.chapter : 1) * 0.023)
        guard let index = computerPoints.indices.min(by: {
            angularDistance(angle, computerPoints[$0].angle) < angularDistance(angle, computerPoints[$1].angle)
        }), angularDistance(angle, computerPoints[index].angle) <= tolerance else { return false }
        let point = computerPoints.remove(at: index)
        interceptedPoints += 1
        score += 160 + (combo * 15)
        grantSparks(9)
        // An accurate interception buys a little breathing room.
        remaining = max(remaining, 5.0)
        timeSeconds = Int(ceil(remaining))
        scene.emitComputerIntercept(at: point.angle)
        announce("POINT CLEARED · +160")
        AudioFeedback.shared.play(.intercept, enabled: soundEnabled)
        AudioFeedback.shared.haptic(.success, enabled: hapticsEnabled)
        if isCampaign {
            updateMissionProgress()
            if missionProgress >= mission.goal && defenseReady { completeMission(); return true }
        } else if isDaily && dailyProgress >= dailyTarget && defenseReady {
            completeDaily(); return true
        }
        persist()
        return true
    }

    func jump() {
        guard isPlaying && !isFinishing else { return }
        if tryDodgeRift() { return }
        // One input handles all three actions. Red points are checked before the gate.
        if tryInterceptComputerPoint() { return }
        let difference = abs(atan2(sin(angle - gate), cos(angle - gate)))
        guard difference <= gateWidth else { fail("MISSED GATE"); return }
        let perfect = difference < gateWidth * 0.38
        let chargedHit = isChargeGate && perfect
        hits += 1
        if chargedHit { chargesCollected += 1 }
        if perfect { perfectHits += 1; perfectStreak += 1; longestPerfectStreak = max(longestPerfectStreak, perfectStreak) } else { perfectStreak = 0 }
        combo = min(40, combo + 1)
        score += (perfect ? 250 : 100) * min(combo, 8)
        // Reward the skillful streak with an automatic three-second slow motion window.
        if perfect && perfectStreak.isMultiple(of: 3) {
            focusRemaining = 3.0
            focusSeconds = 3
            score += 300
            grantSparks(35)
            announce("FOCUS · +300")
            AudioFeedback.shared.play(.focus, enabled: soundEnabled)
        }
        grantSparks(perfect ? 28 : 12)
        if chargedHit { score += 350; grantSparks(30); scene.emitChargeCapture(); AudioFeedback.shared.play(.intercept, enabled: soundEnabled) }
        if combo > 0 && combo.isMultiple(of: 5) { score += 400; scene.emitComboMilestone(combo: combo) }
        scene.emitBurst(atShip: true, color: perfect ? .gold : .aqua, count: perfect ? 80 : 46)
        scene.emitShockwave(color: perfect ? .gold : .aqua)
        if perfect { scene.emitSignatureEffect(atShip: true) }
        scene.shake(intensity: perfect ? 9 : 4)
        if chargedHit { announce("CHARGE CAPTURED  +350") }
        else if combo.isMultiple(of: 5) { announce("COMBO  \(combo)×") }
        else if !(perfect && perfectStreak.isMultiple(of: 3)) { announce(perfect ? "PERFECT" : "CLEAN") }
        AudioFeedback.shared.play(perfect ? .perfect : .success, enabled: soundEnabled)
        AudioFeedback.shared.haptic(perfect ? .success : .light, enabled: hapticsEnabled)
        if isDaily {
            if dailyProgress >= dailyTarget && defenseReady { completeDaily(); return }
            nextGate()
        } else if isCampaign {
            if mission.isBoss {
                if bossHealth > 0 { hitBoss(perfect: perfect) }
                else { nextGate(); announce("CLEAR COMPUTER POINTS") }
            } else {
                updateMissionProgress()
                if missionProgress >= mission.goal && defenseReady { completeMission(); return }
                nextGate()
            }
        } else {
            if bossHealth > 0 { hitBoss(perfect: perfect) }
            else { completeWave() }
        }
        persist()
    }

    private func updateMissionProgress() {
        switch mission.objective {
        case .jumps, .clean: missionProgress = hits
        case .perfect: missionProgress = perfectHits
        case .combo: missionProgress = combo
        case .score: missionProgress = score
        case .charge: missionProgress = chargesCollected
        case .defense: missionProgress = interceptedPoints
        case .boss: missionProgress = mission.goal - bossHealth
        }
    }

    private func fail(_ reason: String) {
        guard isPlaying else { return }
        shields = max(0, shields - 1)
        misses += 1
        combo = 0
        perfectStreak = 0
        focusRemaining = 0; focusSeconds = 0
        scene.emitBurst(atShip: true, color: .pink, count: 50)
        scene.emitShockwave(color: .pink)
        scene.shake(intensity: 14)
        announce(reason)
        AudioFeedback.shared.play(.failure, enabled: soundEnabled)
        AudioFeedback.shared.haptic(.failure, enabled: hapticsEnabled)
        remaining = max(8, 13 - Double(isCampaign ? selectedMission : wave) * 0.12)
        timeSeconds = Int(ceil(remaining))
        if isCampaign { updateMissionProgress() }
        if shields == 0 || (isDaily && misses > 1) || (isCampaign && violatesCleanMission) {
            lossReason = shields == 0 ? "SHIELDS DEPLETED" : "MISSION LIMIT EXCEEDED"
            best = max(best, score)
            screen = .gameOver
            persist()
        }
    }
    private var violatesCleanMission: Bool {
        if case .clean(_, let maxMisses) = mission.objective { return misses > maxMisses }
        return false
    }

    private func hitBoss(perfect: Bool) {
        if eclipseArmor && !perfect {
            announce("ARMOR! PERFECT REQUIRED")
            nextGate()
            return
        }
        bossHealth = max(0, bossHealth - 1)
        if bossHealth == 0 {
            if isCampaign {
                updateMissionProgress()
                if defenseReady { completeMission() }
                else { nextGate(); announce("CORE DOWN · DEFEND THE ORBIT") }
            } else { completeBossEndless() }
            return
        }
        // All five bosses have three visible stages; each stage increases pressure.
        if bossPhase > lastBossPhase {
            lastBossPhase = bossPhase
            let stageName = bossPhase == 2 ? "PHASE II · ADAPT" : "PHASE III · FINAL"
            scene.emitBossPhase(title: stageName)
            announce(stageName)
            AudioFeedback.shared.play(.boss, enabled: soundEnabled)
            AudioFeedback.shared.haptic(.success, enabled: hapticsEnabled)
        } else if eclipseArmor {
            announce("TITAN ARMOR · PERFECT ONLY")
        } else { announce("CORE HIT · \(bossHealth) LEFT") }
        nextGate()
    }

    private func completeDaily() {
        guard isDaily, screen == .playing else { return }
        best = max(best, score)
        let alreadyClaimed = dailyCompleted
        missionReward = alreadyClaimed ? 0 : 450
        if !alreadyClaimed {
            lastDailyCompletion = dailyKey
            grantSparks(missionReward)
            earnedPilotXP = 90
            pilotXP += earnedPilotXP
        }
        resultStars = 1 + (misses == 0 && peakComputerPoints <= computerCapacity - 2 ? 1 : 0) + (longestPerfectStreak >= 3 ? 1 : 0)
        scene.emitBurst(atShip: false, color: .gold, count: 55)
        announce("DAILY COMPLETE")
        AudioFeedback.shared.play(.perfect, enabled: soundEnabled)
        screen = .dailyComplete
        persist()
    }

    private func completeMission() {
        guard isCampaign, screen == .playing else { return }
        best = max(best, score)
        let earned = 1 + (misses == 0 && peakComputerPoints <= computerCapacity - 2 ? 1 : 0)
            + (hits > 0 && !usedBomb && Double(perfectHits) / Double(hits) >= 0.50 ? 1 : 0)
        resultStars = earned
        let previousStars = missionStars[selectedMission] ?? 0
        missionStars[selectedMission] = max(previousStars, earned)
        let extraStars = max(0, earned - previousStars)
        earnedPilotXP = (previousStars == 0 ? 150 + mission.chapter * 75 : 0) + extraStars * 60
        pilotXP += earnedPilotXP
        // Unlock the immediate next mission only when all earlier missions are cleared.
        unlockedMission = OrbitMission.highestUnlocked(from: missionStars)
        // One-time clear reward and one-time extra-star bonuses: no unlimited replays for huge payouts.
        let base = previousStars == 0 ? mission.reward : 0
        let addedStars = max(0, earned - previousStars)
        missionReward = base + addedStars * 75
        // A one-time mastery reward encourages skillful replay without farming Sparks.
        if starsInCollection(mission.chapter) == 24 && !masteredCollections.contains(mission.chapter) {
            masteredCollections.insert(mission.chapter)
            missionReward += 1000
            announce("COLLECTION MASTERED +1000")
        }
        grantSparks(missionReward)
        scene.emitBurst(atShip: false, color: .gold, count: mission.isBoss ? 110 : 70)
        scene.emitVictory(title: mission.isBoss ? "CORE DEFEATED" : "MISSION CLEAR", boss: mission.isBoss)
        scene.emitSignatureEffect(atShip: false)
        scene.shake(intensity: mission.isBoss ? 14 : 7)
        announce(mission.isBoss ? "BOSS ELIMINATED!" : "MISSION COMPLETE!")
        AudioFeedback.shared.play(.victory, enabled: soundEnabled)
        AudioFeedback.shared.haptic(.success, enabled: hapticsEnabled)
        // Keep the SpriteKit scene visible for the cinematic finisher.
        // Freeze gameplay and transition to results when the animation finishes.
        isFinishing = true
        finishingRemaining = mission.isBoss ? 2.3 : 1.6
        persist()
    }

    private func completeWave() {
        wave += 1
        if wave.isMultiple(of: 6) {
            bossHealth = 4 + wave / 12
            lastBossPhase = 1
            scene.emitShockwave(color: .pink)
            scene.shake(intensity: 12)
            announce("VOID BOSS INCOMING")
            AudioFeedback.shared.play(.boss, enabled: soundEnabled)
        }
        nextGate()
    }
    private func completeBossEndless() {
        score += 850
        grantSparks(140)
        scene.emitBurst(atShip: false, color: .gold, count: 125)
        scene.emitShockwave(color: .gold)
        scene.shake(intensity: 22)
        AudioFeedback.shared.play(.victory, enabled: soundEnabled)
        wave += 1
        nextGate()
        announce("CORE DESTROYED +850")
    }
    private func nextGate() {
        if dualGateActive {
            gate = angle + (alternateGateTurn ? 4.1 : 1.7) + Double.random(in: -0.18...0.18)
            alternateGateTurn.toggle()
            announce("DUAL ROUTE · FOLLOW THE BRIGHT GATE")
        } else {
            gate = angle + Double.random(in: 1.20...4.9)
        }
        // Keep the active gate visually distinct from any pending rift.
        if let rift = riftAngle, angularDistance(gate, rift) < 0.76 {
            gate += 0.88
        }
        let level = isDaily ? 3 : (isCampaign ? mission.chapter * 4 + mission.step : wave)
        let speed = 0.11 + min(0.40, Double(level) * 0.012)
        gateDrift = (Bool.random() ? 1.0 : -1.0) * speed
        if bossType == .sentinel {
            let hitsSoFar = mission.isBoss && isCampaign ? mission.goal - bossHealth : 0
            gateDrift = (hitsSoFar.isMultiple(of: 2) ? 1.0 : -1.0) * speed * 1.5
        }
        if bossType == .mirage { gateDrift *= 1.45 }
        if bossType == .vortex { gateDrift *= 1.35 }
        if bossType == .prism { gateDrift *= 1.35 }
        if bossType == .eclipse { gateDrift *= 1.55 }
        if isBossWave && bossPhase >= 2 { gateDrift *= bossPhase == 3 ? 1.34 : 1.14 }
        remaining = max(9.0, 15.5 - Double(level) * 0.12) + (isBossWave ? 1.5 : 0)
        timeSeconds = Int(ceil(remaining))
    }

    func use(_ power: PowerUp) {
        guard isPlaying else { return }
        guard (inventory[power] ?? 0) > 0 else { announce("OPEN THE SHOP"); return }
        if power == .shield && shields >= 5 { announce("MAXIMUM SHIELDS"); return }
        if power == .bomb && eclipseArmor && computerPoints.isEmpty { announce("TITAN ARMOR · PERFECT REQUIRED"); return }
        inventory[power, default: 0] -= 1
        switch power {
        case .freeze:
            freezeRemaining = 8
            announce("TIME WARP · 8 SEC")
            AudioFeedback.shared.play(.success, enabled: soundEnabled)
        case .shield:
            shields += 1
            announce("+1 SHIELD")
            AudioFeedback.shared.play(.perfect, enabled: soundEnabled)
        case .bomb:
            usedBomb = true
            // Tactical escape hatch: bombs prioritize computer pressure, not free wins.
            if !computerPoints.isEmpty {
                let removed = min(2, computerPoints.count)
                computerPoints.removeFirst(removed)
                announce("BOMB · \(removed) POINTS CLEARED")
                scene.emitComputerIntercept(at: angle)
                AudioFeedback.shared.play(.bomb, enabled: soundEnabled)
                AudioFeedback.shared.haptic(.success, enabled: hapticsEnabled)
                persist()
                return
            }
            scene.emitBurst(atShip: false, color: .gold, count: 140)
            scene.emitShockwave(color: .gold)
            scene.shake(intensity: 22)
            AudioFeedback.shared.play(.bomb, enabled: soundEnabled)
            AudioFeedback.shared.haptic(.success, enabled: hapticsEnabled)
            if bossHealth > 0 {
                // Bombs deal one hit; the Eclipse Titan's final armor cannot be bypassed.
                bossHealth -= 1
                if bossHealth == 0 {
                    if isCampaign {
                        updateMissionProgress()
                        if defenseReady { completeMission() }
                        else { nextGate(); announce("CORE DOWN · DEFEND THE ORBIT") }
                    } else { completeBossEndless() }
                } else { nextGate(); announce("BOMB IMPACT") }
            } else if isCampaign {
                // Bombs count as one clean jump, but never as a PERFECT or combo jump.
                hits += 1
                score += 200
                // Bombs do not count as a collected charged gate.
                updateMissionProgress()
                if missionProgress >= mission.goal && defenseReady { completeMission() }
                else { nextGate(); announce("GATE DESTROYED") }
            } else {
                score += 200
                completeWave()
                announce("ORBIT CLEARED +200")
            }
        }
        persist()
    }

    @discardableResult
    func buyWithSparks(_ power: PowerUp) -> Bool {
        guard sparks >= power.price else { return false }
        sparks -= power.price
        inventory[power, default: 0] += 1
        AudioFeedback.shared.play(.success, enabled: soundEnabled)
        persist()
        return true
    }
    func grantSparks(_ amount: Int) { guard amount > 0 else { return }; sparks += amount; persist() }

    /// Grants a verified StoreKit consumable's full contents together.
    func grantPurchasedItems(sparks amount: Int, powers: [PowerUp: Int]) {
        if amount > 0 { sparks += amount }
        for (item, count) in powers where count > 0 {
            inventory[item, default: 0] += count
        }
        persist()
    }

    // Collection unlocks depend solely on earned stars; purchases never grant gameplay advantages.
    func isCosmeticUnlocked(_ cosmetic: OrbitCosmetic) -> Bool {
        if let collection = cosmetic.masteryCollection { return starsInCollection(collection) == 24 }
        if cosmetic.productID != nil { return ownedPaidCosmetics.contains(cosmetic.id) }
        return true
    }

    func isCosmeticEquipped(_ cosmetic: OrbitCosmetic) -> Bool {
        cosmetic.kind == .ship ? equippedShipID == cosmetic.id : equippedEffectID == cosmetic.id
    }

    func equipCosmetic(_ cosmetic: OrbitCosmetic) {
        guard isCosmeticUnlocked(cosmetic) else { return }
        switch cosmetic.kind {
        case .ship: equippedShipID = cosmetic.id
        case .effect: equippedEffectID = cosmetic.id
        }
        AudioFeedback.shared.haptic(.light, enabled: hapticsEnabled)
        persist()
    }

    /// Called only after StoreKit has verified the transaction / active entitlement.
    func setPaidCosmeticEntitlement(_ cosmeticID: String, owned: Bool) {
        guard OrbitCosmetic.paid.contains(where: { $0.id == cosmeticID }) else { return }
        if owned { ownedPaidCosmetics.insert(cosmeticID) }
        else { ownedPaidCosmetics.remove(cosmeticID) }
        normalizeCosmeticSelection()
        persist()
    }

    /// Reconcile Apple non-consumable entitlements; revoked items are unequipped.
    func syncPaidCosmeticEntitlements(_ entitledIDs: Set<String>) {
        ownedPaidCosmetics = entitledIDs.intersection(Set(OrbitCosmetic.paid.map(\.id)))
        normalizeCosmeticSelection()
        persist()
    }

    private func normalizeCosmeticSelection() {
        if let ship = OrbitCosmetic.ship(equippedShipID), !isCosmeticUnlocked(ship) { equippedShipID = "classic" }
        if let effect = OrbitCosmetic.effect(equippedEffectID), !isCosmeticUnlocked(effect) { equippedEffectID = "classic" }
    }

    private func announce(_ text: String) { statusText = text; statusRemaining = 1.55 }
    private func persist() {
        let d = UserDefaults.standard
        d.set(sparks, forKey: "oz.sparks")
        d.set(hasNordicGold, forKey: "oz.nordicGoldOwned")
        d.set(nordicGoldEquipped, forKey: "oz.nordicGoldEquipped")
        d.set(Array(ownedPaidCosmetics).sorted(), forKey: "oz.ownedPaidCosmetics")
        d.set(equippedShipID, forKey: "oz.equippedShipID")
        d.set(equippedEffectID, forKey: "oz.equippedEffectID")
        d.set(best, forKey: "oz.best")
        d.set(pilotXP, forKey: "oz.pilotXP")
        d.set(lastDailyCompletion, forKey: "oz.dailyComplete")
        d.set(unlockedMission, forKey: "oz.unlockedMission")
        d.set(Array(masteredCollections).sorted(), forKey: "oz.masteredCollections")
        d.set(Dictionary(uniqueKeysWithValues: missionStars.map { (String($0.key), $0.value) }), forKey: "oz.missionStars")
        for power in PowerUp.allCases { d.set(inventory[power, default: 0], forKey: "oz.\(power.rawValue)") }
    }
}
