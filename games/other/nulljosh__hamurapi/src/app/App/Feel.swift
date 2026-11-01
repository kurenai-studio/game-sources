import AVFoundation
#if os(iOS)
import UIKit
#endif

/// Music and effects. Every file comes out of art/make_audio.py.
final class Sound {
    static let shared = Sound()
    private var players: [String: AVAudioPlayer] = [:]
    private var queued = 0
    private let silent = ["XCTestConfigurationFilePath", "HAMURABI_SHOT"].contains { ProcessInfo.processInfo.environment[$0] != nil }

    private init() {
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.ambient)  // obeys the silent switch, plays under your own music
        #endif
    }

    var muted = UserDefaults.standard.bool(forKey: "muted") {
        didSet { UserDefaults.standard.set(muted, forKey: "muted"); if muted { players["music"]?.pause() } else { startMusic() } }
    }

    private func player(_ name: String) -> AVAudioPlayer? {
        if let p = players[name] { return p }
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3"), let p = try? AVAudioPlayer(contentsOf: url) else { return nil }
        players[name] = p
        return p
    }

    var musicOff = UserDefaults.standard.bool(forKey: "musicOff") {
        didSet { UserDefaults.standard.set(musicOff, forKey: "musicOff"); if musicOff { players["music"]?.pause() } else { startMusic() } }
    }

    func startMusic() {
        guard !muted, !musicOff, !silent, let m = player("music") else { return }
        m.numberOfLoops = -1; m.volume = 0.5
        m.play()
    }

    func play(_ name: String, after delay: Double = 0) {
        guard !muted, !silent else { return }
        let mine = queued
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [self] in
            guard mine == queued, !muted, let p = player(name) else { return }
            p.currentTime = 0; p.play()
        }
    }

    /// Drops sounds still waiting their turn, for when the player moves on early.
    func cancelQueued() { queued += 1 }
}

/// What a moment sounds and feels like.
enum Feel {
    static func year(_ r: YearReport) {
        let s = Sound.shared
        s.cancelQueued()
        s.play(r.yield >= 3 ? "harvest" : "poor", after: 0.3)
        if r.rats > 0 { s.play("rats", after: 1.4) }
        if r.starved > 0 { s.play("starve", after: 1.9) }
        if r.born > 0 { s.play("arrive", after: 2.6) }
        if r.plague { s.play("plague", after: 3.4) }
        #if os(iOS)
        if r.starved > 0 || r.plague { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
        else { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
        #endif
    }
    static func omen() { Sound.shared.cancelQueued(); Sound.shared.play("omen") }
    static func tap() {
        Sound.shared.play("tap")
        #if os(iOS)
        UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }
    static func verdict(_ g: Grade) {
        Sound.shared.cancelQueued()
        Sound.shared.play(g == .f ? "lose" : g == .aPlus ? "win" : "arrive")
        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(g == .f ? .error : .success)
        #endif
    }
}
