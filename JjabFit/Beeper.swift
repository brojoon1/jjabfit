// Beeper.swift — synthesized beep tones + haptics
// Pure-code sine tones via AVAudioEngine (no audio asset files needed).

import AVFoundation
import UIKit

final class Beeper {
    static let shared = Beeper()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let sampleRate = 44_100.0
    private let format: AVAudioFormat
    private var started = false

    private init() {
        format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
    }

    /// Call on first user gesture so playback is allowed and the engine is warm.
    func prepare() {
        guard !started else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            engine.prepare()
            try engine.start()
            player.play()
            started = true
        } catch {
            print("Beeper audio error: \(error)")
        }
    }

    /// Play a short sine beep. Safe to call rapidly; buffers are queued.
    func beep(frequency: Double = 880, duration: Double = 0.13, volume: Float = 0.28) {
        prepare()
        guard started else { return }
        let frames = AVAudioFrameCount(sampleRate * duration)
        guard frames > 0, let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames) else { return }
        buffer.frameLength = frames
        let ch = buffer.floatChannelData![0]
        let n = Int(frames)
        let attack = max(1, Int(sampleRate * 0.005))
        let release = max(1, Int(sampleRate * 0.04))
        let w = 2.0 * Double.pi * frequency / sampleRate
        for i in 0..<n {
            var amp = volume
            if i < attack { amp *= Float(i) / Float(attack) }
            if i > n - release { amp *= Float(max(0, n - i)) / Float(release) }
            ch[i] = Float(sin(w * Double(i))) * amp
        }
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    }
}

enum Haptic {
    static func tap(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
