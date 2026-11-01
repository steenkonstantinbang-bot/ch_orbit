import AVFoundation
import UIKit

/// Original procedural sci-fi effects and two adaptive, loopable scores.
/// Respects the iPhone Silent Mode switch and mixes with other audio.
final class AudioFeedback {
    static let shared = AudioFeedback()

    enum Sound: String, CaseIterable {
        case start, success, perfect, failure, boss
        case intercept, deploy, surge, shift, bomb, victory, focus
    }
    enum MusicMode: Hashable {
        case silent, orbit, boss

        var filename: String? {
            switch self {
            case .silent: return nil
            case .orbit: return "orbit_ambient"
            case .boss: return "boss_protocol"
            }
        }
    }
    enum Haptic { case light, success, failure }

    // Multiple voices avoid abruptly cutting off a previous jump sound.
    private var effects: [Sound: [AVAudioPlayer]] = [:]
    private var voiceIndex: [Sound: Int] = [:]
    private var musicPlayers: [MusicMode: AVAudioPlayer] = [:]
    private var activeMusic: MusicMode = .silent

    private init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        for sound in Sound.allCases {
            guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "wav") else { continue }
            var voices: [AVAudioPlayer] = []
            for _ in 0..<3 {
                guard let player = try? AVAudioPlayer(contentsOf: url) else { continue }
                player.volume = 0.58
                player.prepareToPlay()
                voices.append(player)
            }
            effects[sound] = voices
        }
        for mode in [MusicMode.orbit, .boss] {
            guard let filename = mode.filename,
                  let url = Bundle.main.url(forResource: filename, withExtension: "wav"),
                  let player = try? AVAudioPlayer(contentsOf: url) else { continue }
            player.numberOfLoops = -1
            player.volume = 0
            player.prepareToPlay()
            musicPlayers[mode] = player
        }
    }

    func play(_ sound: Sound, enabled: Bool) {
        guard enabled, let pool = effects[sound], !pool.isEmpty else { return }
        let selected = pool.first(where: { !$0.isPlaying }) ?? pool[voiceIndex[sound, default: 0] % pool.count]
        if selected.isPlaying { selected.stop() }
        selected.currentTime = 0
        selected.play()
        voiceIndex[sound, default: 0] += 1
    }

    /// Called on game state changes, not on each SpriteKit frame.
    /// Crosses between exploration and combat music while keeping effects independent.
    func setMusic(mode requestedMode: MusicMode, enabled: Bool) {
        let nextMode: MusicMode = enabled ? requestedMode : .silent
        guard nextMode != activeMusic else { return }

        if let oldPlayer = musicPlayers[activeMusic] {
            oldPlayer.stop()
            oldPlayer.currentTime = 0
            oldPlayer.volume = 0
        }
        activeMusic = nextMode
        guard let player = musicPlayers[nextMode] else { return }
        player.volume = 0
        player.currentTime = 0
        player.play()
        player.setVolume(nextMode == .boss ? 0.31 : 0.28, fadeDuration: 0.55)
    }

    func haptic(_ type: Haptic, enabled: Bool) {
        guard enabled else { return }
        switch type {
        case .light: UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .success: UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .failure: UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}
