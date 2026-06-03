import Foundation
import AVFoundation
import Combine

@MainActor
class AudioPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var progress: Double = 0

    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?

    func load(fileName: String, fallbackDuration: Double) {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback)
            try session.setActive(true)

            if FileManager.default.fileExists(atPath: url.path) {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
            } else {
                // No real file yet — use fallback duration for UI display
                duration = fallbackDuration
                return
            }
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            duration = audioPlayer?.duration ?? fallbackDuration
        } catch {
            print("AudioPlayer load error: \(error)")
            duration = fallbackDuration
        }
    }

    func play() {
        audioPlayer?.play()
        isPlaying = true
        startTimer()
    }

    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        stopTimer()
    }

    func togglePlayPause() {
        isPlaying ? pause() : play()
    }

    func seek(to fraction: Double) {
        let target = fraction * duration
        audioPlayer?.currentTime = target
        currentTime = target
        progress = fraction
    }

    func stop() {
        audioPlayer?.stop()
        isPlaying = false
        currentTime = 0
        progress = 0
        stopTimer()
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let player = self.audioPlayer else { return }
                self.currentTime = player.currentTime
                self.progress = self.duration > 0 ? player.currentTime / self.duration : 0
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
            self.currentTime = 0
            self.progress = 0
            self.stopTimer()
        }
    }
}
