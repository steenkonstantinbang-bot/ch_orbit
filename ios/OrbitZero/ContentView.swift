import SwiftUI
import SpriteKit
import StoreKit

// ORBIT ZERO — Scandinavian Edition: compact, stable menus and a one-touch HUD.
private enum OrbitStyle {
    static let background = Color(red: 0.06, green: 0.08, blue: 0.09)
    static let panel = Color(red: 0.12, green: 0.14, blue: 0.15)
    static let line = Color(red: 0.23, green: 0.27, blue: 0.29)
    static let muted = Color(red: 0.62, green: 0.68, blue: 0.70)
    static let white = Color(red: 0.95, green: 0.96, blue: 0.97)
    static let accent = Color(red: 0.72, green: 0.83, blue: 0.85)
    static let sand = Color(red: 0.83, green: 0.77, blue: 0.66)
    static let rose = Color(red: 0.76, green: 0.59, blue: 0.60)
}

struct ContentView: View {
    @StateObject private var game = OrbitGame()
    @StateObject private var store = SparkStore()
    @StateObject private var multiplayer = OrbitMultiplayer()
    @StateObject private var duel = OrbitDuelGame()
    @State private var chapter = 1
    @State private var showingHangar = false
    @State private var showingArenaLobby = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            OrbitStyle.background.ignoresSafeArea()
            SpriteView(scene: game.scene, options: [.ignoresSiblingOrder])
                .ignoresSafeArea()
            if duel.isVisible {
                DuelArenaView(duel: duel)
            } else if game.isPlaying {
                if game.isFinishing { cinematicOverlay } else { playHUD }
            } else {
                menuOverlay
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { game.pause() }
            if phase == .background { duel.forfeitOnBackground() }
            syncSoundtrack()
        }
        .onChange(of: game.musicEnabled) { _, _ in syncSoundtrack() }
        .onChange(of: game.isBossWave) { _, _ in syncSoundtrack() }
        .onChange(of: game.computerOverdrive) { _, _ in syncSoundtrack() }
        .onChange(of: game.screen) { oldScreen, newScreen in
            syncSoundtrack()
            if newScreen == .missions {
                let target = oldScreen == .home ? game.unlockedMission : game.selectedMission
                chapter = max(1, min(5, (target - 1) / 8 + 1))
            }
        }
        .task {
            store.attach(game)
            multiplayer.onReady = { name in
                showingArenaLobby = false
                game.goHome()
                duel.soundEnabled = game.soundEnabled
                duel.hapticsEnabled = game.hapticsEnabled
                AudioFeedback.shared.setMusic(mode: .boss, enabled: game.musicEnabled)
                duel.start(opponent: name)
            }
            multiplayer.onPacket = { packet in duel.receive(packet) }
            multiplayer.onDisconnect = { duel.disconnected() }
            duel.onSend = { packet in multiplayer.send(packet) }
            duel.onExit = { multiplayer.disconnect(); syncSoundtrack() }
            multiplayer.authenticate()
            syncSoundtrack()
            await store.loadProducts()
        }
        .sheet(isPresented: $showingArenaLobby) { arenaLobby }
        .alert("Orbit Zero", isPresented: Binding(
            get: { store.message != nil },
            set: { if !$0 { store.message = nil } }
        )) {
            Button("OK") { store.message = nil }
        } message: {
            Text(store.message ?? "")
        }
    }

    private var cinematicOverlay: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: game.mission.isBoss ? "crown" : "checkmark.seal")
                .font(.system(size: 36, weight: .ultraLight))
                .foregroundStyle(OrbitStyle.sand)
            Text(game.mission.isBoss ? "CORE DEFEATED" : "MISSION COMPLETE")
                .font(.system(size: 19, weight: .semibold))
                .tracking(2)
                .foregroundStyle(OrbitStyle.white)
            Text("+\(game.earnedPilotXP) PILOT XP")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(OrbitStyle.accent)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(OrbitStyle.background.opacity(0.30))
        .allowsHitTesting(true)
        .accessibilityLabel("Mission complete. Victory animation playing")
    }

    private var playHUD: some View {
        GeometryReader { geometry in
            let compact = geometry.size.height < 670
            VStack(spacing: compact ? 7 : 11) {
                HStack(spacing: 12) {
                    Text("ORBIT  ZERO")
                        .font(.system(size: 15, weight: .semibold))
                        .tracking(2.2)
                    Spacer()
                    Button(action: game.pause) {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 13, weight: .medium))
                            .frame(width: 40, height: 40)
                            .background(OrbitStyle.panel, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(OrbitStyle.line))
                    }
                    .accessibilityLabel("Pause")
                }
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(game.progressLabel)
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(0.7)
                            .foregroundStyle(OrbitStyle.accent)
                        Text(game.missionGoal)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(OrbitStyle.white)
                            .lineLimit(2)
                            .minimumScaleFactor(0.82)
                    }
                    Spacer(minLength: 6)
                    Text(game.progressText)
                        .font(.system(size: 11, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(OrbitStyle.sand)
                }
                GeometryReader { bar in
                    ZStack(alignment: .leading) {
                        Capsule().fill(OrbitStyle.line)
                        Capsule().fill(game.isBossWave ? OrbitStyle.rose : OrbitStyle.accent)
                            .frame(width: bar.size.width * max(0, min(1, game.missionFraction)))
                    }
                }
                .frame(height: 3)
                HStack(spacing: 7) {
                    Image(systemName: "cpu")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(OrbitStyle.rose)
                    Text("COMPUTER")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(0.7)
                        .foregroundStyle(OrbitStyle.muted)
                    HStack(spacing: 3) {
                        ForEach(Array(0..<game.computerCapacity), id: \.self) { slot in
                            Capsule()
                                .fill(slot < game.computerPoints.count ? OrbitStyle.rose : OrbitStyle.line)
                                .frame(maxWidth: .infinity)
                                .frame(height: 8)
                        }
                    }
                    Text("\(game.computerPoints.count)/\(game.computerCapacity)")
                        .font(.system(size: 11, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(OrbitStyle.rose)
                }
                .frame(height: 22)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Computer danger \(game.computerPoints.count) out of \(game.computerCapacity); full meter means game over")
                HStack(spacing: 8) {
                    miniStat("SCORE", value: game.score.formatted())
                    miniStat("COMBO", value: "\(game.combo)×")
                    miniStat("SHIELDS", value: String(repeating: "●", count: game.shields), color: OrbitStyle.rose)
                }
                Text(game.statusText.isEmpty ? " " : game.statusText)
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.5)
                    .foregroundStyle(game.statusText.contains("MISS") || game.statusText.contains("EXPIRED") ? OrbitStyle.rose : OrbitStyle.accent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 24)
                    .allowsHitTesting(false)
                Spacer(minLength: 0)
                HStack(spacing: 10) {
                    if game.riftApproaching {
                        Label("GRAVITY RIFT · TAP TO EVADE", systemImage: "exclamationmark.triangle")
                    } else if game.riftAngle != nil {
                        Label("AMBER ARC · EVADE WITH JUMP", systemImage: "circle.dashed")
                    } else if game.dualGateActive {
                        Label("TWO ROUTES · FOLLOW THE BRIGHT GATE", systemImage: "arrow.triangle.branch")
                    } else if game.isBossWave {
                        Label("BOSS PHASE \(game.bossPhase) / 3", systemImage: "scope")
                    } else if game.computerOverdrive {
                        Label("AI OVERDRIVE · CLEAR THE RED POINTS", systemImage: "exclamationmark.triangle")
                    } else if game.focusActive {
                        Label("FOCUS \(game.focusSeconds)s", systemImage: "scope")
                    } else if game.surgeActive {
                        Label("SURGE", systemImage: "bolt")
                    } else if game.isChargeGate {
                        Label("GOLD GATE · PERFECT", systemImage: "circle.hexagongrid")
                    } else {
                        Text(game.computerPoints.isEmpty ? "Every full orbit adds 2 red points" : "Tap red points to clear them")
                    }
                }
                .font(.system(size: 10, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .foregroundStyle(OrbitStyle.sand)
                .frame(maxWidth: .infinity)
                .frame(height: 21)
                HStack(spacing: 8) {
                    powerButton(.bomb)
                    powerButton(.freeze)
                    powerButton(.shield)
                }
                Button(action: game.jump) {
                    Text("JUMP")
                        .font(.system(size: 17, weight: .semibold))
                        .tracking(2)
                        .frame(maxWidth: .infinity)
                        .frame(height: compact ? 48 : 56)
                        .foregroundStyle(OrbitStyle.background)
                        .background(OrbitStyle.accent, in: RoundedRectangle(cornerRadius: 14))
                }
                .accessibilityHint("Tap when the ship reaches a pale gate or a red computer point")
                HStack {
                    Text(game.defenseStatus)
                    Spacer()
                    Text("✦ \(game.sparks.formatted())")
                        .foregroundStyle(OrbitStyle.sand)
                }
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(OrbitStyle.muted)
                .padding(.horizontal, 3)
            }
            .padding(.horizontal, 18)
            .padding(.top, compact ? 3 : 9)
            .padding(.bottom, 10)
        }
    }

    private func miniStat(_ name: String, value: String, color: Color = OrbitStyle.white) -> some View {
        HStack(spacing: 5) {
            Text(name).font(.system(size: 9, weight: .medium)).foregroundStyle(OrbitStyle.muted)
            Text(value).font(.system(size: 11, weight: .semibold)).foregroundStyle(color).lineLimit(1).minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 28)
        .background(OrbitStyle.panel.opacity(0.94), in: RoundedRectangle(cornerRadius: 8))
    }

    private func powerButton(_ item: OrbitGame.PowerUp) -> some View {
        let qty = game.inventory[item, default: 0]
        return Button { game.use(item) } label: {
            HStack(spacing: 6) {
                Image(systemName: item.symbol).font(.system(size: 13))
                Text("\(qty)").font(.system(size: 11, weight: .semibold)).monospacedDigit()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 41)
            .foregroundStyle(qty > 0 ? OrbitStyle.white : OrbitStyle.muted)
            .background(OrbitStyle.panel, in: RoundedRectangle(cornerRadius: 11))
            .overlay(RoundedRectangle(cornerRadius: 11).strokeBorder(OrbitStyle.line))
        }
        .disabled(qty == 0)
        .accessibilityLabel("Use \(item.title), \(qty) remaining")
    }

    // A stable shell: header and footer never scroll or change position.
    // Only the mission list and shop content have their own scroll areas.
    private var menuOverlay: some View {
        ZStack {
            OrbitStyle.background.opacity(0.985).ignoresSafeArea()
            GeometryReader { geo in
                let compact = geo.size.height < 700
                VStack(spacing: 0) {
                    HStack {
                        Text("KONHAGEN GAMES")
                            .font(.system(size: 10, weight: .medium))
                            .tracking(2)
                            .foregroundStyle(OrbitStyle.muted)
                        Spacer()
                        Text("COPENHAGEN")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(OrbitStyle.muted)
                    }
                    .frame(height: 34)
                    Group {
                        switch game.screen {
                        case .home:
                            homePanel(compact: compact)
                        case .missions:
                            missionPanel
                        case .shop:
                            shopPanel
                        default:
                            ScrollView(showsIndicators: false) {
                                auxiliaryPanel
                                    .padding(.bottom, 8)
                            }
                            .scrollBounceBehavior(.basedOnSize)
                        }
                    }
                    .frame(maxWidth: 410, maxHeight: .infinity)
                    Text("ORBIT ZERO  /  VERSION 1.7")
                        .font(.system(size: 9, weight: .medium))
                        .tracking(0.8)
                        .foregroundStyle(OrbitStyle.muted.opacity(0.75))
                        .frame(height: 28)
                }
                .padding(.horizontal, compact ? 17 : 22)
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func homePanel(compact: Bool) -> some View {
        VStack(spacing: compact ? 4 : 9) {
            Spacer(minLength: 1)
            orbitMark(size: compact ? 55 : 85, boss: false)
            Text("Orbit Zero")
                .font(.system(size: compact ? 35 : 49, weight: .semibold))
                .tracking(-2.1)
                .foregroundStyle(OrbitStyle.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text("ONE TOUCH. BEAT THE COMPUTER.")
                .font(.system(size: 9, weight: .medium))
                .tracking(compact ? 1.1 : 1.6)
                .foregroundStyle(OrbitStyle.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            HStack(spacing: 8) {
                metric("UNLOCKED", "\(game.unlockedMission) / 40")
                metric("STARS", "\(game.totalStars) / 120")
                metric("BEST", game.best.formatted())
            }
            .padding(.top, compact ? 4 : 12)
            HStack(spacing: 8) {
                Image(systemName: "rosette")
                    .foregroundStyle(OrbitStyle.sand)
                    .font(.system(size: 12))
                Text("\(game.pilotRankName) · \(game.pilotXP) XP")
                    .foregroundStyle(OrbitStyle.white)
                Spacer(minLength: 8)
                Text(game.pilotNextRankName)
                    .foregroundStyle(OrbitStyle.muted)
            }
            .font(.system(size: 10, weight: .medium))
            .lineLimit(1).minimumScaleFactor(0.7)
            GeometryReader { progress in
                Capsule().fill(OrbitStyle.line)
                    .overlay(alignment: .leading) {
                        Capsule().fill(OrbitStyle.sand)
                            .frame(width: progress.size.width * game.pilotRankFraction)
                    }
            }
            .frame(height: 3)
            VStack(spacing: compact ? 5 : 7) {
                primary("Continue campaign", icon: "arrow.right", height: compact ? 42 : 47) {
                    game.selectMission(game.unlockedMission)
                }
                secondary("All missions", icon: "square.grid.2x2", height: compact ? 40 : 44, action: game.openMissions)
                secondary("Multiplayer · Orbit Arena", icon: "person.2", height: compact ? 40 : 44) {
                    menuTap()
                    showingArenaLobby = true
                }
                secondary("Shop", icon: "bag", height: compact ? 40 : 44) {
                    menuTap()
                    showingHangar = false
                    game.openShop()
                }
                secondary("Daily challenge", icon: "calendar", height: compact ? 40 : 44) {
                    game.startDaily()
                }
                secondary("Endless mode", icon: "infinity", height: compact ? 40 : 44, action: game.startEndless)
            }
            HStack(spacing: 15) {
                Button("Hangar") {
                    menuTap()
                    showingHangar = true
                    game.openShop()
                }
                Text("·").foregroundStyle(OrbitStyle.line)
                Button("Settings") { menuTap(); game.openSettings() }
                Spacer()
                Text("✦ \(game.sparks.formatted())").foregroundStyle(OrbitStyle.sand)
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(OrbitStyle.muted)
            .padding(.horizontal, 5)
            .padding(.top, 4)
            Text(multiplayer.isAuthenticated ? (game.dailyCompleted ? "Game Center ready · Daily complete ✓" : "Game Center connected") : "Game Center sign-in required for multiplayer")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(OrbitStyle.accent)
                .frame(height: compact ? 12 : 14)
                .accessibilityHidden(!game.dailyCompleted)
            Spacer(minLength: 1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // A stable, native lobby before Apple's matchmaking/invite interface.
    private var arenaLobby: some View {
        VStack(spacing: 20) {
            HStack {
                Text("KONHAGEN GAMES").font(.system(size: 10, weight: .medium))
                    .tracking(2).foregroundStyle(OrbitStyle.muted)
                Spacer()
                Button("Close") { showingArenaLobby = false }
                    .font(.system(size: 13)).foregroundStyle(OrbitStyle.accent)
            }
            .padding(.top, 22)
            Spacer(minLength: 6)
            orbitMark(size: 92, boss: false)
            Text("Orbit Arena")
                .font(.system(size: 35, weight: .semibold)).foregroundStyle(OrbitStyle.white)
            Text("1 vs 1 · Real-time online duel")
                .font(.system(size: 12)).foregroundStyle(OrbitStyle.muted)
            HStack(spacing: 11) {
                VStack(spacing: 4) {
                    Text("\(duel.rating)").font(.system(size: 22, weight: .semibold))
                    Text("YOUR RATING").font(.system(size: 10)).foregroundStyle(OrbitStyle.muted)
                }
                Spacer()
                VStack(spacing: 4) {
                    Text("\(duel.wins) / \(duel.defeats)").font(.system(size: 22, weight: .semibold))
                    Text("WINS / LOSSES").font(.system(size: 10)).foregroundStyle(OrbitStyle.muted)
                }
            }
            .padding(16)
            .background(OrbitStyle.panel, in: RoundedRectangle(cornerRadius: 14))
            Text(multiplayer.message)
                .font(.system(size: 12))
                .foregroundStyle(OrbitStyle.muted)
                .multilineTextAlignment(.center)
                .frame(minHeight: 40)
            primary(multiplayer.isAuthenticated ? "Find or invite opponent" : "Sign in to Game Center",
                    icon: "person.2", height: 53) {
                if multiplayer.isAuthenticated { multiplayer.findMatch() }
                else { multiplayer.authenticate() }
            }
            Text("One finger. Intercept incoming points and land PERFECT gates to attack. First to lose all shields or fill 12 threat slots loses; after 90 seconds, highest score wins.")
                .font(.system(size: 12))
                .foregroundStyle(OrbitStyle.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Text("Game Center is required · Real multiplayer needs two Apple devices")
                .font(.system(size: 10)).foregroundStyle(OrbitStyle.muted)
        }
        .padding(.horizontal, 23)
        .padding(.bottom, 24)
        .background(OrbitStyle.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    private func orbitMark(size: CGFloat, boss: Bool) -> some View {
        ZStack {
            Circle().stroke(OrbitStyle.line, lineWidth: 1.5)
            Circle()
                .trim(from: 0.05, to: 0.23)
                .stroke(boss ? OrbitStyle.rose : OrbitStyle.accent,
                        style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-65))
            Circle()
                .fill(OrbitStyle.panel)
                .frame(width: size * 0.34, height: size * 0.34)
                .overlay(Circle().strokeBorder(boss ? OrbitStyle.rose : OrbitStyle.accent, lineWidth: 1.5))
            Circle().fill(OrbitStyle.white).frame(width: 6, height: 6).offset(y: -size / 2)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private func metric(_ label: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(OrbitStyle.white)
                .lineLimit(1).minimumScaleFactor(0.75)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .tracking(0.5)
                .foregroundStyle(OrbitStyle.muted)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background(OrbitStyle.panel, in: RoundedRectangle(cornerRadius: 11))
    }

    private var missionPanel: some View {
        VStack(spacing: 12) {
            sectionTitle("Collections", sub: "Finish each mission to unlock the next")
            HStack(spacing: 6) {
                Text("\(game.unlockedMission) unlocked")
                Spacer()
                Text("★  \(game.totalStars) / 120")
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(OrbitStyle.sand)
            HStack(spacing: 6) {
                ForEach(1...5, id: \.self) { value in
                    let unlocked = game.isCollectionUnlocked(value)
                    Button {
                        guard unlocked else { return }
                        menuTap()
                        chapter = value
                    } label: {
                        VStack(spacing: 3) {
                            Text(String(format: "%02d", value))
                                .font(.system(size: 13, weight: .semibold))
                                .monospacedDigit()
                            Image(systemName: unlocked ? (game.masteredCollections.contains(value) ? "star.fill" : "circle.fill") : "lock.fill")
                                .font(.system(size: 9))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .foregroundStyle(chapter == value ? OrbitStyle.background : OrbitStyle.muted)
                        .background(chapter == value ? OrbitStyle.accent : OrbitStyle.panel,
                                    in: RoundedRectangle(cornerRadius: 10))
                        .opacity(unlocked ? 1 : 0.48)
                    }
                    .buttonStyle(.plain)
                    .disabled(!unlocked)
                    .accessibilityLabel(unlocked
                        ? "Collection \(value): \(OrbitMission.collectionNames[value-1])"
                        : "Collection \(value) locked. Complete mission \((value - 1) * 8) to unlock")
                }
            }
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(OrbitMission.collectionNames[chapter - 1])
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(OrbitStyle.white)
                    Text(game.masteredCollections.contains(chapter) ? "Mastered · 24/24 stars" : OrbitMission.collectionDescriptions[chapter - 1])
                        .font(.system(size: 11))
                        .foregroundStyle(OrbitStyle.muted)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text(String(format: "%02d – %02d", (chapter-1)*8+1, chapter*8))
                    Text("★ \(game.starsInCollection(chapter)) / 24")
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(OrbitStyle.sand)
            }
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 8) {
                    ForEach(OrbitMission.all.filter { $0.chapter == chapter }) { mission in
                        missionRow(mission)
                    }
                }
                .padding(.vertical, 3)
            }
            secondary("Back to menu", icon: "arrow.left", action: game.goHome)
        }
        .padding(.top, 9)
        .padding(.bottom, 7)
    }

    private func missionRow(_ mission: OrbitMission) -> some View {
        let locked = !game.isMissionUnlocked(mission.id)
        let stars = game.missionStars[mission.id, default: 0]
        return Button {
            menuTap()
            game.selectMission(mission.id)
        } label: {
            HStack(spacing: 12) {
                Text(String(format: "%02d", mission.id))
                    .font(.system(size: 16, weight: .medium))
                    .monospacedDigit()
                    .frame(width: 32)
                    .foregroundStyle(mission.isBoss ? OrbitStyle.rose : OrbitStyle.accent)
                VStack(alignment: .leading, spacing: 4) {
                    Text(mission.title.capitalized)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(locked ? OrbitStyle.muted : OrbitStyle.white)
                        .lineLimit(1)
                    Text(locked ? "Complete mission \(mission.id - 1) to unlock" : mission.isBoss ? "Boss mission" : mission.label.capitalized)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(OrbitStyle.muted)
                        .lineLimit(1)
                }
                Spacer(minLength: 5)
                if locked {
                    Image(systemName: "lock")
                        .font(.system(size: 12))
                        .foregroundStyle(OrbitStyle.muted)
                } else {
                    Text(String(repeating: "★", count: stars) + String(repeating: "☆", count: 3 - stars))
                        .font(.system(size: 11))
                        .foregroundStyle(OrbitStyle.sand)
                }
            }
            .padding(.horizontal, 11)
            .frame(height: 65)
            .background(OrbitStyle.panel, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(mission.isBoss && !locked ? OrbitStyle.rose.opacity(0.6) : OrbitStyle.line, lineWidth: 1))
            .opacity(locked ? 0.58 : 1)
        }
        .buttonStyle(.plain)
        .disabled(locked)
        .accessibilityHint(locked ? "Complete the previous mission to unlock" : "Open mission briefing")
    }

    @ViewBuilder private var auxiliaryPanel: some View {
        switch game.screen {
        case .briefing: briefingPanel
        case .paused: pausePanel
        case .missionComplete: victoryPanel
        case .dailyComplete: dailyVictoryPanel
        case .gameOver: gameOverPanel
        case .settings: settingsPanel
        default: EmptyView()
        }
    }

    private var briefingPanel: some View {
        VStack(spacing: 15) {
            sectionTitle(game.mission.title.capitalized,
                         sub: "Mission \(String(format: "%02d", game.selectedMission)) · \(game.mission.collectionName)")
            orbitMark(size: 109, boss: game.mission.isBoss)
                .padding(.vertical, 6)
            Text(game.mission.isBoss ? "BOSS ENCOUNTER" : "YOUR OBJECTIVE")
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(game.mission.isBoss ? OrbitStyle.rose : OrbitStyle.accent)
            Text(game.mission.briefing + " Each 360° lap creates two red points. Tap as your ship crosses a red point to intercept it. Fill the computer meter and you lose.")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(OrbitStyle.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            VStack(spacing: 9) {
                infoRow("Goal", game.mission.label.capitalized)
                infoRow("Defense", "Clear \(game.mission.defenseQuota) red points")
                infoRow("Survive", "At least \(game.mission.minOrbits) full orbits")
                infoRow("Computer", "2 red points per orbit · \(game.computerCapacity) slots")
                infoRow("Reward", "+\(game.mission.reward) Sparks")
            if game.mission.chapter >= 2 {
                infoRow("Evolving orbit", "Alternating gates after lap 3")
            }
            if game.mission.chapter >= 3 {
                infoRow("Gravity rifts", "Tap amber arc to evade")
            }
            if game.mission.isBoss { infoRow("Boss", "Three tactical phases") }
                infoRow("Max rating", "3 stars")
            }
            .padding(15)
            .background(OrbitStyle.panel, in: RoundedRectangle(cornerRadius: 13))
            primary(game.mission.isBoss ? "Engage boss" : "Start mission", icon: "play.fill") {
                game.startMission(game.selectedMission)
            }
            secondary("Mission map", icon: "arrow.left", action: game.backToMissions)
        }
        .padding(.vertical, 8)
    }

    private var pausePanel: some View {
        VStack(spacing: 15) {
            sectionTitle("Paused", sub: game.progressLabel)
            orbitMark(size: 90, boss: game.isBossWave)
            Text(game.missionGoal)
                .font(.system(size: 13))
                .foregroundStyle(OrbitStyle.muted)
                .multilineTextAlignment(.center)
            infoRow("Defended", game.defenseStatus)
            scoreSummary
            primary("Resume", icon: "play.fill", action: game.resume)
            secondary("Shop", icon: "bag") { showingHangar = false; game.openShop() }
            secondary("Settings", icon: "gearshape", action: game.openSettings)
            secondary("Main menu", icon: "house", action: game.goHome)
        }
        .padding(.vertical, 8)
    }

    private var victoryPanel: some View {
        VStack(spacing: 14) {
            sectionTitle(game.mission.isBoss ? "Boss defeated" : "Mission clear", sub: game.mission.title.capitalized)
            animatedVictoryMark(boss: game.mission.isBoss)
            Text(String(repeating: "★", count: game.resultStars) + String(repeating: "☆", count: 3 - game.resultStars))
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(OrbitStyle.sand)
            infoRow("Score", game.score.formatted())
            infoRow("Intercepted", "\(game.interceptedPoints) computer points")
            infoRow("Orbits", "\(game.orbitCount) completed")
            infoRow("Earned", "+\(game.missionReward) Sparks")
            infoRow("Pilot XP", "+\(game.earnedPilotXP) · \(game.pilotRankName)")
            if game.masteredCollections.contains(game.mission.chapter) {
                Text("✦ \(game.mission.collectionName) mastered")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(OrbitStyle.sand)
            }
            else if game.mission.isBoss {
                Text("\(game.mission.collectionName) complete · Earn 24 stars for a mastery bonus")
                    .font(.system(size: 11))
                    .foregroundStyle(OrbitStyle.muted)
                    .multilineTextAlignment(.center)
            }
            if game.isMissionUnlocked(game.selectedMission + 1) {
                primary("Next mission", icon: "arrow.right", action: game.startNextMission)
            }
            secondary("Replay for more stars", icon: "arrow.clockwise", action: game.retry)
            secondary("Mission map", icon: "square.grid.2x2", action: game.openMissions)
            secondary("Main menu", icon: "house", action: game.goHome)
        }
        .padding(.vertical, 8)
    }

    private func animatedVictoryMark(boss: Bool) -> some View {
        VictoryEmblem(boss: boss)
            .frame(width: 122, height: 122)
            .accessibilityLabel(boss ? "Boss victory animation" : "Mission complete animation")
    }

    private var dailyVictoryPanel: some View {
        VStack(spacing: 17) {
            sectionTitle("Daily complete", sub: "Today's orbit mastered")
            orbitMark(size: 115, boss: false)
            Text("+\(game.missionReward) Sparks")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(OrbitStyle.sand)
            Text("A new challenge appears tomorrow. You can replay today's challenge for practice, but its bonus can only be claimed once.")
                .font(.system(size: 12))
                .foregroundStyle(OrbitStyle.muted)
                .multilineTextAlignment(.center)
            scoreSummary
            primary("Play again", icon: "arrow.clockwise", action: game.startDaily)
            secondary("Main menu", icon: "house", action: game.goHome)
        }
        .padding(.vertical, 9)
    }

    private var gameOverPanel: some View {
        VStack(spacing: 17) {
            sectionTitle(game.lossReason.hasPrefix("COMPUTER WINS") ? "Computer wins" : "Signal lost", sub: game.progressLabel)
            orbitMark(size: 105, boss: game.isBossWave)
            Text(game.lossReason.isEmpty ? game.missionGoal : game.lossReason)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(OrbitStyle.rose)
                .multilineTextAlignment(.center)
            infoRow("Computer points", "\(game.computerPoints.count) / \(game.computerCapacity)")
            infoRow("Intercepted", "\(game.interceptedPoints) in \(game.orbitCount) laps")
            Text(game.missionGoal)
                .font(.system(size: 13))
                .foregroundStyle(OrbitStyle.muted)
                .multilineTextAlignment(.center)
            scoreSummary
            primary("Try again", icon: "arrow.clockwise", action: game.retry)
            if game.isCampaign { secondary("Mission map", icon: "square.grid.2x2", action: game.openMissions) }
            secondary("Shop", icon: "bag") { showingHangar = false; game.openShop() }
            secondary("Main menu", icon: "house", action: game.goHome)
        }
        .padding(.vertical, 9)
    }

    private var scoreSummary: some View {
        HStack(spacing: 7) {
            metric("SCORE", game.score.formatted())
            metric("COMBO", "\(game.combo)×")
            metric("RECORD", game.best.formatted())
        }
    }

    // Shop and Hangar are separate, immediately accessible tabs on the same fixed screen.
    // Their product lists can scroll, but navigation buttons do not move.
    private var shopPanel: some View {
        VStack(spacing: 10) {
            sectionTitle(showingHangar ? "Signature Hangar" : "Shop",
                         sub: showingHangar ? "Ships & signature effects" : "Power-ups, Sparks & premium kits")
            HStack(spacing: 8) {
                storeTab("Shop", symbol: "bag", active: !showingHangar) {
                    menuTap()
                    showingHangar = false
                }
                storeTab("Hangar", symbol: "paperplane", active: showingHangar) {
                    menuTap()
                    showingHangar = true
                }
            }
            HStack {
                Label("\(game.sparks.formatted()) Sparks", systemImage: "sparkle")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(OrbitStyle.sand)
                Spacer()
                Text(showingHangar ? "COLLECT · EQUIP" : "EARN OR BUY")
                    .font(.system(size: 9, weight: .medium))
                    .tracking(0.6)
                    .foregroundStyle(OrbitStyle.muted)
            }
            .padding(.horizontal, 3)
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 10) {
                    if showingHangar {
                    shopHeading("SIGNATURE HANGAR", detail: "Choose one ship and one visual signature")
                    ForEach(OrbitCosmetic.ships) { cosmetic in
                        cosmeticWardrobeRow(cosmetic)
                    }
                    shopHeading("SIGNATURE EFFECTS", detail: "Special animations on PERFECT hits and victories")
                    ForEach(OrbitCosmetic.effects) { cosmetic in
                        cosmeticWardrobeRow(cosmetic)
                    }
                    } else {
                    shopHeading("WITH SPARKS", detail: "Earn free Sparks by playing")
                    ForEach(OrbitGame.PowerUp.allCases) { item in
                        HStack(spacing: 10) {
                            Image(systemName: item.symbol)
                                .font(.system(size: 19))
                                .foregroundStyle(OrbitStyle.accent)
                                .frame(width: 29)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title.capitalized)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(OrbitStyle.white)
                                Text(item.details)
                                    .font(.system(size: 10))
                                    .foregroundStyle(OrbitStyle.muted)
                                Text("Owned: \(game.inventory[item, default: 0])")
                                    .font(.system(size: 10))
                                    .foregroundStyle(OrbitStyle.sand)
                            }
                            Spacer(minLength: 5)
                            Button("✦ \(item.price.formatted())") { _ = game.buyWithSparks(item) }
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(OrbitStyle.background)
                                .padding(.horizontal, 9)
                                .frame(height: 37)
                                .background(OrbitStyle.accent, in: RoundedRectangle(cornerRadius: 9))
                                .disabled(game.sparks < item.price)
                                .opacity(game.sparks >= item.price ? 1 : 0.4)
                                .accessibilityLabel("Buy \(item.title) for \(item.price) Sparks")
                        }
                        .padding(12)
                        .background(OrbitStyle.panel, in: RoundedRectangle(cornerRadius: 12))
                    }
                    shopHeading("SPARKS & TACTICAL KITS", detail: "Optional Apple purchases · prices shown by Apple")
                    if store.currencyProducts.isEmpty && store.kitProducts.isEmpty {
                        Text("Apple purchases appear when products are available in App Store Connect. All missions remain playable without buying anything.")
                            .font(.system(size: 11))
                            .foregroundStyle(OrbitStyle.muted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(13)
                            .background(OrbitStyle.panel, in: RoundedRectangle(cornerRadius: 12))
                    }
                    ForEach(store.currencyProducts, id: \.id) { product in
                        paidProductRow(product, symbol: "sparkles")
                    }
                    ForEach(store.kitProducts, id: \.id) { product in
                        paidProductRow(product, symbol: "shippingbox")
                    }
                    }
                    Button {
                        Task { await store.restorePurchases() }
                    } label: {
                        Label("Restore permanent purchases", systemImage: "arrow.clockwise")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(OrbitStyle.muted)
                            .frame(maxWidth: .infinity)
                            .frame(height: 34)
                    }
                    .disabled(store.isPurchasing)
                    Text("No purchase is required to complete any mission. Cosmetic items do not change score, speed, lives or hit detection. Paid designs are permanent non-consumable purchases and can be restored with your Apple Account.")
                        .font(.system(size: 10))
                        .foregroundStyle(OrbitStyle.muted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 6)
                }
                .padding(.bottom, 8)
            }
            .id(showingHangar) // Reset scroll to top on tab switch.
            .scrollBounceBehavior(.basedOnSize)
            secondary("Back", icon: "arrow.left", action: game.closePanel)
        }
        .padding(.top, 10)
        .padding(.bottom, 5)
    }

    private func storeTab(_ name: String, symbol: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(name, systemImage: symbol)
                .font(.system(size: 13, weight: .semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .foregroundStyle(active ? OrbitStyle.background : OrbitStyle.white)
                .background(active ? OrbitStyle.accent : OrbitStyle.panel, in: RoundedRectangle(cornerRadius: 11))
                .overlay(RoundedRectangle(cornerRadius: 11).strokeBorder(active ? OrbitStyle.accent : OrbitStyle.line, lineWidth: 1))
        }
        .accessibilityAddTraits(active ? .isSelected : [])
    }

    private func shopHeading(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.1)
                .foregroundStyle(OrbitStyle.accent)
            Text(detail)
                .font(.system(size: 10))
                .foregroundStyle(OrbitStyle.muted)
        }
        .padding(.top, 6)
    }

    /// Unlocks are either earned through full collection mastery or verified Apple purchases.
    private func cosmeticWardrobeRow(_ cosmetic: OrbitCosmetic) -> some View {
        let unlocked = game.isCosmeticUnlocked(cosmetic)
        let equipped = game.isCosmeticEquipped(cosmetic)
        let product = cosmetic.productID.flatMap { id in store.products.first { $0.id == id } }
        return HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 11)
                    .fill(OrbitStyle.background)
                    .frame(width: 43, height: 43)
                Image(systemName: cosmetic.symbol)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(cosmetic.id == "nordicgold" || cosmetic.id == "zenith" ? OrbitStyle.sand : OrbitStyle.accent)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(cosmetic.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(OrbitStyle.white)
                Text(cosmetic.subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(OrbitStyle.muted)
                    .fixedSize(horizontal: false, vertical: true)
                if let mastery = cosmetic.masteryCollection {
                    Text("★ \(game.starsInCollection(mastery))/24 · \(OrbitMission.collectionNames[mastery-1])")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(OrbitStyle.sand)
                } else if unlocked && cosmetic.productID != nil {
                    Text("Owned permanently").font(.system(size: 10)).foregroundStyle(OrbitStyle.sand)
                }
            }
            Spacer(minLength: 4)
            if equipped {
                Label("On", systemImage: "checkmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(OrbitStyle.sand)
                    .frame(minWidth: 55)
            } else if unlocked {
                Button("Equip") { game.equipCosmetic(cosmetic) }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(OrbitStyle.background)
                    .padding(.horizontal, 10)
                    .frame(height: 35)
                    .background(OrbitStyle.accent, in: RoundedRectangle(cornerRadius: 9))
                    .accessibilityLabel("Equip \(cosmetic.name)")
            } else if let product {
                Button(product.displayPrice) { Task { await store.purchase(product) } }
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .foregroundStyle(OrbitStyle.background)
                    .padding(.horizontal, 8)
                    .frame(minWidth: 54)
                    .frame(height: 35)
                    .background(OrbitStyle.accent, in: RoundedRectangle(cornerRadius: 9))
                    .disabled(store.isPurchasing)
                    .accessibilityLabel("Buy \(cosmetic.name) for \(product.displayPrice)")
            } else {
                Label(cosmetic.masteryCollection == nil ? "Soon" : "Locked", systemImage: "lock")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(OrbitStyle.muted)
                    .frame(minWidth: 55)
            }
        }
        .padding(11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OrbitStyle.panel, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(equipped ? OrbitStyle.sand.opacity(0.55) : OrbitStyle.line, lineWidth: 1))
    }

    private func paidProductRow(_ product: Product, symbol: String) -> some View {
        let owned = false
        return HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 18))
                .foregroundStyle(OrbitStyle.accent)
                .frame(width: 27)
            VStack(alignment: .leading, spacing: 4) {
                Text(SparkStore.names[product.id] ?? product.displayName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(OrbitStyle.white)
                Text(SparkStore.details[product.id] ?? product.description)
                    .font(.system(size: 10))
                    .foregroundStyle(OrbitStyle.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 4)
            Button {
                Task { await store.purchase(product) }
            } label: {
                Text(owned ? "Owned" : product.displayPrice)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(minWidth: 61)
                    .frame(height: 36)
                    .padding(.horizontal, 5)
                    .foregroundStyle(OrbitStyle.background)
                    .background(owned ? OrbitStyle.sand : OrbitStyle.accent, in: RoundedRectangle(cornerRadius: 9))
            }
            .disabled(owned || store.isPurchasing)
        }
        .padding(12)
        .background(OrbitStyle.panel, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(OrbitStyle.line, lineWidth: 1))
    }

    private func syncSoundtrack() {
        let mode: AudioFeedback.MusicMode
        if duel.isVisible && scenePhase == .active {
            mode = .boss
        } else if game.isPlaying && scenePhase == .active {
            mode = (game.isBossWave || game.computerOverdrive) ? .boss : .orbit
        } else {
            mode = .silent
        }
        AudioFeedback.shared.setMusic(mode: mode, enabled: game.musicEnabled)
    }

    private var settingsPanel: some View {
        VStack(spacing: 14) {
            sectionTitle("Settings", sub: "Your orbit, your pace")
            VStack(spacing: 0) {
                toggle("Space soundtrack", symbol: "music.note", value: $game.musicEnabled)
                Divider().overlay(OrbitStyle.line)
                toggle("Sound effects", symbol: "speaker.wave.2", value: $game.soundEnabled)
                Divider().overlay(OrbitStyle.line)
                toggle("Vibration", symbol: "iphone.radiowaves.left.and.right", value: $game.hapticsEnabled)
                Divider().overlay(OrbitStyle.line)
                toggle("Particles", symbol: "sparkles", value: $game.effectsEnabled)
                Divider().overlay(OrbitStyle.line)
                toggle("Easy mode", symbol: "scope", value: $game.easyMode)
            }
            .padding(.horizontal, 13)
            .background(OrbitStyle.panel, in: RoundedRectangle(cornerRadius: 13))
            Text("ORBIT ZERO · VERSION 1.7 · KONHAGEN GAMES")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(OrbitStyle.muted)
            Text("Progress, achievements and currency are saved locally on this device.")
                .font(.system(size: 11))
                .foregroundStyle(OrbitStyle.muted)
                .multilineTextAlignment(.center)
            secondary("Back", icon: "arrow.left", action: game.closePanel)
        }
        .padding(.vertical, 9)
    }

    private func toggle(_ label: String, symbol: String, value: Binding<Bool>) -> some View {
        Toggle(isOn: value) {
            Label(label, systemImage: symbol)
                .font(.system(size: 13, weight: .medium))
        }
        .tint(OrbitStyle.accent)
        .padding(.vertical, 9)
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(label).foregroundStyle(OrbitStyle.muted)
            Spacer(minLength: 8)
            Text(value).foregroundStyle(OrbitStyle.white).multilineTextAlignment(.trailing)
        }
        .font(.system(size: 12, weight: .medium))
    }

    private func sectionTitle(_ title: String, sub: String) -> some View {
        VStack(spacing: 8) {
            Text(sub)
                .font(.system(size: 10, weight: .medium))
                .tracking(0.65)
                .foregroundStyle(OrbitStyle.muted)
                .multilineTextAlignment(.center)
            Text(title)
                .font(.system(size: 30, weight: .semibold))
                .tracking(-0.8)
                .foregroundStyle(OrbitStyle.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
    }

    private func menuTap() {
        AudioFeedback.shared.haptic(.light, enabled: game.hapticsEnabled)
    }

    private func primary(_ label: String, icon: String, height: CGFloat = 49, action: @escaping () -> Void) -> some View {
        Button(action: { menuTap(); action() }) {
            Label(label, systemImage: icon)
                .font(.system(size: 14, weight: .semibold))
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .foregroundStyle(OrbitStyle.background)
                .background(OrbitStyle.accent, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func secondary(_ label: String, icon: String, height: CGFloat = 46, action: @escaping () -> Void) -> some View {
        Button(action: { menuTap(); action() }) {
            Label(label, systemImage: icon)
                .font(.system(size: 13, weight: .medium))
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .foregroundStyle(OrbitStyle.white)
                .background(OrbitStyle.panel, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(OrbitStyle.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// Fixed-size animation: only the emblem animates; menu buttons never move.
private struct VictoryEmblem: View {
    let boss: Bool
    @State private var expand = false

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(index == 1 ? OrbitStyle.sand : OrbitStyle.accent,
                            lineWidth: index == 0 ? 3 : 1)
                    .frame(width: 65, height: 65)
                    .scaleEffect(expand ? 1.5 + CGFloat(index) * 0.2 : 0.55)
                    .opacity(expand ? 0 : 0.75)
                    .animation(.easeOut(duration: 0.75 + Double(index) * 0.16).delay(Double(index) * 0.09), value: expand)
            }
            Image(systemName: boss ? "bolt.shield.fill" : "checkmark.seal.fill")
                .font(.system(size: 54, weight: .ultraLight))
                .foregroundStyle(boss ? OrbitStyle.sand : OrbitStyle.accent)
                .scaleEffect(expand ? 1 : 0.5)
                .opacity(expand ? 1 : 0)
                .animation(.spring(response: 0.60, dampingFraction: 0.60), value: expand)
        }
        .frame(width: 122, height: 122)
        .onAppear { expand = true }
        .onDisappear { expand = false }
    }
}
