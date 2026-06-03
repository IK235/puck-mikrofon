//
//  Audioplayer.swift
//  PuckMikrofon
//
//  Created by ikbal erdal on 2026-04-04.
//

import Foundation
import AVFoundation
import Combine

// Hanterar uppspelning av inspelade anekdoter
// Användaren kan spela, pausa, spola och se hur långt in i klippet de är
@MainActor
class AudioPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {

    @Published var isPlaying = false

    // Hur långt in i klippet vi är just nu, i sekunder
    @Published var currentTime: TimeInterval = 0

    // Klippets totala längd i sekunder
    @Published var duration: TimeInterval = 0

    // Ett värde mellan 0 och 1 — används för att rita progress-baren
    @Published var progress: Double = 0

    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?

    // Laddar ljudfilen och förbereder spelaren
    // fallbackDuration används om filen inte finns (t.ex. för exempeldata)
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
                // Filen finns inte — visa bara fallback-längden i UI:t
                duration = fallbackDuration
                return
            }
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            duration = audioPlayer?.duration ?? fallbackDuration
        } catch {
            print("Kunde inte ladda ljudfilen: \(error)")
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

    // Används av play/pause-knappen
    func togglePlayPause() {
        isPlaying ? pause() : play()
    }

    // Hoppar till en position — fraction är 0.0 (start) till 1.0 (slut)
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

    // Uppdaterar progress 4 gånger per sekund — tillräckligt smooth utan att slösa batteri
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

    // Kallas automatiskt av iOS när klippet är slut
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
            self.currentTime = 0
            self.progress = 0
            self.stopTimer()
        }
    }
}
