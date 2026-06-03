//
//  ElevenLabsService.swift
//  PuckMikrofon
//
//  Created by ikbal erdal on 2026-04-22.
//

import Foundation
import AVFoundation
import Combine

// Hanterar all kommunikation med ElevenLabs API för AI-genererad röstuppspelning
// Singleton (shared) så att hela appen delar samma uppspelningsstatus
@MainActor
class ElevenLabsService: NSObject, ObservableObject, AVAudioPlayerDelegate {
    static let shared = ElevenLabsService()

    // API-nyckel och röst-ID för ElevenLabs, detta styr vilken AI-röst som används
    private let apiKey = "sk_52128f3c7603973eccf0b53b386137121311158ce7eab520"
    private let voiceId = "kpTdKfohzvarfFPnwuHW"
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?

    // Publicerade tillstånd som SwiftUI-vyer lyssnar på för att uppdatera UI
    @Published var isPlaying = false
    @Published var isLoading = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var progress: Double = 0

    // Detta skapar en unik cachefil per text så slipper att anropa API:t igen för samma anekdot
    private func cacheFile(for text: String) -> URL {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("tts_\(abs(text.hashValue)).mp3")
    }

    /// Huvudfunktion — anropas från play-knappen i PlaybackView
    /// Kollar cache först, annars hämtas nytt ljud från ElevenLabs API
    func speak(text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Om ljud redan spelas så pausas det istället för att starta om
        if isPlaying {
            pause()
            return
        }

        // Om ljud är pausat mitt i - fortsätt spela från samma position
        if let player = audioPlayer, player.currentTime > 0, player.currentTime < player.duration {
            play()
            return
        }

        isLoading = true
        defer { isLoading = false }

        // Använder cachad fil om den finns, genom det sparas API-anrop och ges snabbare uppspelning
        let cacheURL = cacheFile(for: trimmed)
        if FileManager.default.fileExists(atPath: cacheURL.path) {
            playFile(url: cacheURL)
            return
        }

        // Hämtar nytt ljud från ElevenLabs API och sparar i cache
        guard let data = await generateSpeech(text: trimmed) else { return }
        try? data.write(to: cacheURL)
        playFile(url: cacheURL)
    }

    // Wrapper som anropas från UI-knappar utan async/await
    func togglePlayPause(text: String) {
        Task { await speak(text: text) }
    }

    // Denna pausar uppspelningen och stoppar progress-timern
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        stopTimer()
    }

    // För att kunna hoppa till en specifik position i uppspelningen, den används av progress bar i PlaybackView
    func seek(to fraction: Double) {
        guard let player = audioPlayer, duration > 0 else { return }
        let target = min(max(fraction, 0), 1) * duration
        player.currentTime = target
        currentTime = target
        progress = fraction
    }

    // Stoppar uppspelningen helt och återställer alla tillstånd till startläge
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        isLoading = false
        currentTime = 0
        progress = 0
        duration = 0
        stopTimer()
    }

    // Här startar eller återupptar uppspelning och startar progress-timern
    private func play() {
        audioPlayer?.play()
        isPlaying = true
        startTimer()
    }

    // Här Skickas det POST-förfrågan till ElevenLabs API med texten och returnerar MP3-data
    private func generateSpeech(text: String) async -> Data? {
        let url = URL(string: "https://api.elevenlabs.io/v1/text-to-speech/\(voiceId)")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        req.httpBody = try? JSONSerialization.data(withJSONObject: [
            "text": text,
            "model_id": "eleven_multilingual_v2",
            "voice_settings": ["stability": 0.5, "similarity_boost": 0.75]
        ])
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            return data
        } catch {
            print("ElevenLabs error: \(error)")
            return nil
        }
    }

    // Laddar MP3-filen och konfigurerar AVAudioSession för uppspelning samt startar ljud
    private func playFile(url: URL) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            duration = audioPlayer?.duration ?? 0
            currentTime = 0
            progress = 0
            play()
        } catch {
            print("Uppspelningsfel: \(error)")
        }
    }

    // Här startas det en timer som uppdaterar progress var 0.25 sekund — driver vågformanimationen i UI
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let player = self.audioPlayer else { return }
                self.currentTime = player.currentTime
                self.progress = self.duration > 0 ? player.currentTime / self.duration : 0
            }
        }
    }

    // Stoppar och ogiltigförklarar progress-timern
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // Kallas av AVFoundation när uppspelningen är klar - återställer UI till startläge
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
            self.currentTime = 0
            self.progress = 0
            self.stopTimer()
        }
    }
}
