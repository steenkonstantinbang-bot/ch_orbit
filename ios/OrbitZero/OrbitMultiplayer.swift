import SwiftUI
import GameKit
import UIKit

// Wire protocol is versioned. Game Center provides peer-to-peer transport;
// it is not an anti-cheat authority. Only scores/attacks, never purchases, cross the wire.
struct OrbitDuelPacket: Codable {
    let version: Int
    let kind: String
    let value: Int
    let extra: Int
    let sequence: Int

    init(_ kind: String, value: Int = 0, extra: Int = 0, sequence: Int = 0) {
        self.version = 1
        self.kind = kind
        self.value = value
        self.extra = extra
        self.sequence = sequence
    }
}

@MainActor
final class OrbitMultiplayer: NSObject, ObservableObject, GKMatchmakerViewControllerDelegate, GKMatchDelegate, GKLocalPlayerListener {
    @Published private(set) var isAuthenticated = false
    @Published private(set) var isSearching = false
    @Published private(set) var isConnected = false
    @Published private(set) var opponentName = "Opponent"
    @Published var message = "Sign in to Game Center to play against a friend or a random pilot."

    var onReady: ((String) -> Void)?
    var onPacket: ((OrbitDuelPacket) -> Void)?
    var onDisconnect: (() -> Void)?

    private var currentMatch: GKMatch?
    private weak var matchmaker: GKMatchmakerViewController?
    private var started = false
    private var sequence = 0
    private var lastRemoteSequence = -1
    private var listenerRegistered = false

    func authenticate() {
        if GKLocalPlayer.local.isAuthenticated {
            isAuthenticated = true
            registerListenerIfNeeded()
            message = "Ready. Find an opponent or invite a friend."
            return
        }
        GKLocalPlayer.local.authenticateHandler = { [weak self] controller, error in
            Task { @MainActor in
                guard let self else { return }
                if let controller { self.present(controller); return }
                self.isAuthenticated = GKLocalPlayer.local.isAuthenticated
                if self.isAuthenticated {
                    self.registerListenerIfNeeded()
                    self.message = "Ready. Find an opponent or invite a friend."
                } else {
                    self.message = error?.localizedDescription ?? "Game Center sign-in is required for online battles."
                }
            }
        }
    }

    private func registerListenerIfNeeded() {
        guard !listenerRegistered else { return }
        GKLocalPlayer.local.register(self)
        listenerRegistered = true
    }

    func findMatch() {
        guard isAuthenticated else {
            message = "Sign in to Game Center first."
            authenticate()
            return
        }
        disconnect()
        let request = GKMatchRequest()
        request.minPlayers = 2
        request.maxPlayers = 2
        request.defaultNumberOfPlayers = 2
        guard let controller = GKMatchmakerViewController(matchRequest: request) else {
            message = "Game Center could not open matchmaking."
            return
        }
        controller.matchmakerDelegate = self
        matchmaker = controller
        isSearching = true
        message = "Looking for a pilot…"
        present(controller)
    }

    func player(_ player: GKPlayer, didAccept invite: GKInvite) {
        guard !isConnected else { return }
        disconnect()
        guard let controller = GKMatchmakerViewController(invite: invite) else {
            message = "Unable to accept the invitation."
            return
        }
        controller.matchmakerDelegate = self
        matchmaker = controller
        isSearching = true
        present(controller)
    }

    private func present(_ controller: UIViewController) {
        guard let root = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController }).first else {
            message = "Unable to show Game Center. Try reopening the app."
            isSearching = false
            return
        }
        var top = root
        while let presented = top.presentedViewController { top = presented }
        top.present(controller, animated: true)
    }

    func matchmakerViewControllerWasCancelled(_ viewController: GKMatchmakerViewController) {
        viewController.dismiss(animated: true)
        isSearching = false
        message = "Matchmaking cancelled."
    }

    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFailWithError error: Error) {
        viewController.dismiss(animated: true)
        isSearching = false
        message = error.localizedDescription
    }

    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFind match: GKMatch) {
        viewController.dismiss(animated: true)
        currentMatch = match
        match.delegate = self
        isSearching = false
        attemptStart(match)
    }

    private func attemptStart(_ match: GKMatch) {
        guard match === currentMatch, match.players.count == 1, match.expectedPlayerCount == 0 else { return }
        if started { return }
        started = true
        isConnected = true
        opponentName = match.players[0].displayName
        message = "Connected to \(opponentName)."
        onReady?(opponentName)
        send(.init("hello"))
    }

    func match(_ match: GKMatch, player: GKPlayer, didChange state: GKPlayerConnectionState) {
        Task { @MainActor in
            guard match === self.currentMatch else { return }
            if state == .disconnected {
                self.message = "Opponent disconnected."
                self.onDisconnect?()
                self.disconnect()
            } else if state == .connected {
                self.attemptStart(match)
            }
        }
    }

    func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        guard let packet = try? JSONDecoder().decode(OrbitDuelPacket.self, from: data),
              packet.version == 1, data.count < 1024 else { return }
        Task { @MainActor in
            guard match === self.currentMatch else { return }
            // Reliable ordered packets; guard against replays and malformed ranges.
            guard packet.sequence > self.lastRemoteSequence else { return }
            self.lastRemoteSequence = packet.sequence
            self.onPacket?(packet)
        }
    }

    func match(_ match: GKMatch, didFailWithError error: Error?) {
        Task { @MainActor in
            guard match === self.currentMatch else { return }
            self.message = error?.localizedDescription ?? "Connection lost."
            self.onDisconnect?()
            self.disconnect()
        }
    }

    func send(_ packet: OrbitDuelPacket) {
        guard let match = currentMatch, isConnected else { return }
        sequence += 1
        let outgoing = OrbitDuelPacket(packet.kind, value: packet.value,
                                       extra: packet.extra, sequence: sequence)
        guard let data = try? JSONEncoder().encode(outgoing) else { return }
        do { try match.sendData(toAllPlayers: data, with: .reliable) }
        catch { message = "Network issue: \(error.localizedDescription)" }
    }

    func disconnect() {
        if let match = currentMatch { match.delegate = nil; match.disconnect() }
        currentMatch = nil
        started = false
        isConnected = false
        isSearching = false
        sequence = 0
        lastRemoteSequence = -1
    }
}

struct DuelThreat: Identifiable {
    let id = UUID()
    let angle: Double
}

@MainActor
final class OrbitDuelGame: ObservableObject {
    enum Phase: Equatable { case lobby, playing, won, lost, draw, interrupted }
    @Published private(set) var phase: Phase = .lobby
    @Published private(set) var opponent = "Opponent"
    @Published private(set) var angle = -Double.pi / 2
    @Published private(set) var gate = 1.05
    @Published private(set) var threats: [DuelThreat] = []
    @Published private(set) var score = 0
    @Published private(set) var rivalScore = 0
    @Published private(set) var rivalPressure = 0
    @Published private(set) var shields = 3
    @Published private(set) var perfectStreak = 0
    @Published private(set) var seconds = 90
    @Published private(set) var laps = 0
    @Published private(set) var message = ""
    @Published private(set) var isVisible = false
    @Published private(set) var rating = UserDefaults.standard.object(forKey: "oz.duelRating") as? Int ?? 1000
    @Published private(set) var wins = UserDefaults.standard.integer(forKey: "oz.duelWins")
    @Published private(set) var defeats = UserDefaults.standard.integer(forKey: "oz.duelDefeats")

    var onSend: ((OrbitDuelPacket) -> Void)?
    var onExit: (() -> Void)?
    var soundEnabled = true
    var hapticsEnabled = true
    private var clock: Timer?
    private var remaining: Double = 90
    private var tickDate: Date?
    private var startAngle = -Double.pi / 2
    private var lastLap = 0
    private var lastStateSent = 0.0
    private var timeElapsed = 0.0
    private var didResolve = false
    private var ownFinalScore: Int?
    private var rivalFinalScore: Int?
    private let capacity = 12

    var pressure: Int { threats.count }
    var pressureFraction: Double { Double(threats.count) / Double(capacity) }
    var resultTitle: String {
        switch phase {
        case .won: return "Victory"
        case .lost: return "Defeat"
        case .draw: return "Draw"
        case .interrupted: return "Disconnected"
        default: return "Orbit Duel"
        }
    }

    func start(opponent: String) {
        clock?.invalidate()
        self.opponent = opponent
        phase = .playing; isVisible = true; didResolve = false
        score = 0; rivalScore = 0; rivalPressure = 0
        threats = []; shields = 3; perfectStreak = 0
        seconds = 90; remaining = 90; timeElapsed = 0; lastStateSent = 0
        laps = 0; lastLap = 0; angle = -Double.pi / 2; gate = 1.05
        ownFinalScore = nil; rivalFinalScore = nil
        tickDate = Date(); message = "Duel started — defend your orbit"
        clock = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        if let clock { RunLoop.main.add(clock, forMode: .common) }
    }

    private func tick() {
        guard phase == .playing else { return }
        let now = Date()
        let dt = min(0.08, max(0, now.timeIntervalSince(tickDate ?? now)))
        tickDate = now
        timeElapsed += dt
        remaining = max(0, remaining - dt)
        seconds = Int(ceil(remaining))
        angle += dt * (1.70 + min(0.35, Double(laps) * 0.03))
        gate += dt * 0.14
        let rotation = Int((angle - startAngle) / (.pi * 2))
        if rotation > lastLap {
            lastLap = rotation
            laps = rotation
            addThreats(2)
            message = "+2 computer points"
        }
        if timeElapsed - lastStateSent >= 0.6 {
            lastStateSent = timeElapsed
            onSend?(.init("state", value: score, extra: pressure))
        }
        if remaining <= 0 {
            ownFinalScore = score
            onSend?(.init("time", value: score))
            // Wait for opponent's final score to avoid clock-order bias.
            if let other = rivalFinalScore { resolveTime(other) }
            else { phase = .draw; clock?.invalidate(); message = "Waiting for opponent's final score…" }
        }
    }

    private func addThreats(_ n: Int) {
        guard phase == .playing else { return }
        for _ in 0..<max(0, min(n, 3)) {
            if threats.count >= capacity { end(.lost, reason: "Your threat meter is full", notify: true); return }
            let offset = Double.random(in: 0.65...5.5)
            threats.append(DuelThreat(angle: angle + offset))
        }
        if threats.count >= capacity { end(.lost, reason: "Your threat meter is full", notify: true) }
    }

    func jump() {
        guard phase == .playing else { return }
        let d: (Double, Double) -> Double = { a,b in abs(atan2(sin(a-b),cos(a-b))) }
        if let index = threats.indices.min(by: { d(angle, threats[$0].angle) < d(angle, threats[$1].angle) }),
           d(angle, threats[index].angle) < 0.18 {
            threats.remove(at: index)
            AudioFeedback.shared.play(.intercept, enabled: soundEnabled)
            AudioFeedback.shared.haptic(.light, enabled: hapticsEnabled)
            score += 110; message = "Intercepted +110"
            onSend?(.init("state", value: score, extra: pressure))
        } else if d(angle, gate) < 0.28 {
            let perfect = d(angle, gate) < 0.105
            perfectStreak = perfect ? perfectStreak + 1 : 0
            score += perfect ? 270 : 140
            AudioFeedback.shared.play(perfect ? .perfect : .success, enabled: soundEnabled)
            if perfect && perfectStreak.isMultiple(of: 3) {
                onSend?(.init("attack", value: 2))
                message = "Perfect combo — attack +2"
            } else if perfect {
                onSend?(.init("attack", value: 1))
                message = "Perfect — attack +1"
            } else { message = "Gate cleared" }
            gate = angle + Double.random(in: 1.3...4.7)
        } else {
            shields -= 1; perfectStreak = 0; message = "Missed — shield lost"
            AudioFeedback.shared.play(.failure, enabled: soundEnabled)
            AudioFeedback.shared.haptic(.failure, enabled: hapticsEnabled)
            if shields <= 0 { end(.lost, reason: "No shields remaining", notify: true) }
        }
    }

    func receive(_ p: OrbitDuelPacket) {
        if p.kind == "state" {
            guard (0...1_000_000).contains(p.value), (0...12).contains(p.extra) else { return }
            rivalScore = p.value; rivalPressure = p.extra
        } else if p.kind == "attack" {
            guard (1...2).contains(p.value), phase == .playing else { return }
            addThreats(p.value)
            AudioFeedback.shared.play(.deploy, enabled: soundEnabled)
            message = "Opponent deployed +\(p.value)"
        } else if p.kind == "lost" {
            if phase == .playing || (phase == .draw && ownFinalScore != nil) {
                end(.won, reason: "Opponent orbit collapsed", notify: false)
            }
        } else if p.kind == "time" {
            guard (0...1_000_000).contains(p.value) else { return }
            rivalFinalScore = p.value
            if let own = ownFinalScore { resolveTime(p.value) }
            else if phase == .playing && remaining < 2 { remaining = 0 }
        } else if p.kind == "leave" {
            if phase == .playing { end(.won, reason: "Opponent left the duel", notify: false) }
        }
    }

    private func resolveTime(_ other: Int) {
        guard let own = ownFinalScore, !didResolve else { return }
        end(own > other ? .won : own < other ? .lost : .draw,
            reason: "Time over · \(own) to \(other)", notify: false)
    }

    private func end(_ outcome: Phase, reason: String, notify: Bool) {
        guard !didResolve else { return }
        didResolve = true
        phase = outcome; message = reason; clock?.invalidate(); clock = nil
        if notify { onSend?(.init("lost")) }
        if outcome == .won {
            rating += 25; wins += 1
            AudioFeedback.shared.play(.victory, enabled: soundEnabled)
            AudioFeedback.shared.haptic(.success, enabled: hapticsEnabled)
        }
        if outcome == .lost { rating = max(0, rating - 15); defeats += 1 }
        UserDefaults.standard.set(rating, forKey: "oz.duelRating")
        UserDefaults.standard.set(wins, forKey: "oz.duelWins")
        UserDefaults.standard.set(defeats, forKey: "oz.duelDefeats")
    }

    func disconnected() {
        if phase == .playing { end(.interrupted, reason: "Connection lost — no rating change", notify: false) }
        else if phase == .draw && ownFinalScore != nil && !didResolve {
            end(.interrupted, reason: "Connection lost before the final score arrived", notify: false)
        }
    }

    func forfeitOnBackground() {
        if phase == .playing {
            end(.lost, reason: "Duel forfeited when the app left the foreground", notify: true)
        }
    }

    func exit() {
        if phase == .playing { onSend?(.init("leave")) }
        clock?.invalidate(); clock = nil
        isVisible = false; phase = .lobby; message = ""
        onExit?()
    }
}
