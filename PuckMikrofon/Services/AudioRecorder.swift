import Foundation
import AVFoundation
import Combine

@MainActor
class AudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordingTime: TimeInterval = 0
    @Published var audioLevels: [Float] = Array(repeating: 0.1, count: 30)

    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    private(set) var currentFileName: String = ""

    override init() {
        super.init()
    }

    func requestPermission() async -> Bool {
        await AVAudioApplication.requestRecordPermission()
    }

    func startRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
        } catch {
            print("Audio session error: \(error)")
            return
        }

        let fileName = UUID().uuidString + ".m4a"
        currentFileName = fileName
        let url = audioFileURL(for: fileName)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            isRecording = true
            recordingTime = 0
            startTimer()
        } catch {
            print("Failed to start recording: \(error)")
        }
    }

    func stopRecording() -> (fileName: String, duration: TimeInterval) {
        audioRecorder?.stop()
        stopTimer()
        isRecording = false
        let duration = recordingTime
        recordingTime = 0
        return (currentFileName, duration)
    }

    func cancelRecording() {
        audioRecorder?.stop()
        audioRecorder?.deleteRecording()
        stopTimer()
        isRecording = false
        recordingTime = 0
    }

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

    private func updateLevels() {
        guard let recorder = audioRecorder else { return }
        var newLevels: [Float] = []
        for _ in 0..<30 {
            let level = recorder.averagePower(forChannel: 0)
            let normalized = max(0.05, min(1.0, (level + 60) / 60))
            newLevels.append(normalized + Float.random(in: 0...0.1))
        }
        audioLevels = newLevels
    }

    func audioFileURL(for fileName: String) -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }
}
