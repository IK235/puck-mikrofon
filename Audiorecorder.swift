//
//  Audiorecorder.swift
//  PuckMikrofon
//
//  Created by ikbal erdal on 2026-04-04.
//

import Foundation
import AVFoundation
import Combine

// Hanterar allt som har med inspelning att göra
// Kommunicerar med puckens mikrofon och sparar ljudet som en .m4a-fil
@MainActor
class AudioRecorder: NSObject, ObservableObject {

    // true när inspelningen pågår — används för att visa rätt UI
    @Published var isRecording = false

    // Hur länge inspelningen har pågått i sekunder
    @Published var recordingTime: TimeInterval = 0

    // Ljudnivåerna som animeras i vågformsvyn under inspelning (30 staplar)
    @Published var audioLevels: [Float] = Array(repeating: 0.1, count: 30)

    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?

    // Filnamnet på senaste inspelningen, används när anekdoten sparas
    private(set) var currentFileName: String = ""

    override init() {
        super.init()
    }

    // Fråga användaren om tillstånd att använda mikrofonen
    func requestPermission() async -> Bool {
        await AVAudioApplication.requestRecordPermission()
    }

    func startRecording() {
        // Konfigurera ljudsessionen för inspelning
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
        } catch {
            print("Kunde inte starta ljudsessionen: \(error)")
            return
        }

        // Skapa ett unikt filnamn för varje inspelning
        let fileName = UUID().uuidString + ".m4a"
        currentFileName = fileName
        let url = audioFileURL(for: fileName)

        // Inställningar för inspelningskvaliteten
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.isMeteringEnabled = true  // behövs för att läsa av ljudnivåer
            audioRecorder?.record()
            isRecording = true
            recordingTime = 0
            startTimer()
        } catch {
            print("Kunde inte starta inspelningen: \(error)")
        }
    }

    // Stoppar inspelningen och returnerar filnamn + längd så de kan sparas i anekdoten
    func stopRecording() -> (fileName: String, duration: TimeInterval) {
        audioRecorder?.stop()
        stopTimer()
        isRecording = false
        let duration = recordingTime
        recordingTime = 0
        return (currentFileName, duration)
    }

    // Avbryter och raderar filen — används om användaren trycker på Avbryt
    func cancelRecording() {
        audioRecorder?.stop()
        audioRecorder?.deleteRecording()
        stopTimer()
        isRecording = false
        recordingTime = 0
    }

    // Timern tickar 10 gånger per sekund för att hålla koll på tid och uppdatera vågformen
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.recordingTime += 0.1
                self.audioRecorder?.updateMeters()
                self.updateLevels()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // Läser av mikrofonens nuvarande ljudnivå och omvandlar till värden mellan 0 och 1
    private func updateLevels() {
        guard let recorder = audioRecorder else { return }
        var newLevels: [Float] = []
        for _ in 0..<30 {
            let level = recorder.averagePower(forChannel: 0)
            // Mikrofonen returnerar dB (negativt), vi normaliserar till 0-1
            let normalized = max(0.05, min(1.0, (level + 60) / 60))
            newLevels.append(normalized + Float.random(in: 0...0.1))
        }
        audioLevels = newLevels
    }

    // Bygger sökvägen till ljudfilen i telefonens Documents-mapp
    func audioFileURL(for fileName: String) -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }
}
