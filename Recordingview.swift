//
//  Recordingview.swift
//  PuckMikrofon
//
//  Created by ikbal erdal on 2026-04-04.
//

import SwiftUI

// Inspelningsskärmen — visas medan användaren talar in sin berättelse
// Visar en live-vågform och en timer så användaren vet hur länge de spelat in
struct RecordingView: View {
    @EnvironmentObject var audioRecorder: AudioRecorder
    @State private var showLocationPicker = false
    @State private var recordedFileName: String = ""
    @State private var recordedDuration: Double = 0
    @State private var hasPermission: Bool = false
    @State private var showPermissionAlert = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Spelar in...")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.secondary)

            // Kortet som visar vågform och timer under inspelning
            VStack(spacing: 16) {
                // Den animerade vågformen — uppdateras 10 ggr/sekund från AudioRecorder
                LiveWaveformView(levels: audioRecorder.audioLevels)
                    .frame(height: 56)
                    .padding(.horizontal, 8)

                // Röd prick som blinkar medan inspelning pågår
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 9, height: 9)
                        .opacity(audioRecorder.isRecording ? 1 : 0)
                        .animation(.easeInOut(duration: 0.6).repeatForever(), value: audioRecorder.isRecording)
                    Text("Spelar in")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.red)
                }

                // Stor timer som visar hur länge inspelningen pågått
                Text(formatTime(audioRecorder.recordingTime))
                    .font(.system(size: 28, weight: .light, design: .monospaced))
                    .foregroundStyle(.primary)

                Text("Släpp knappen när du är klar")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.red.opacity(0.3), lineWidth: 1.5)
            )
            .padding(.horizontal, 20)

            Spacer()

            // Den stora knappen — håll inne för att spela in, släpp för att stoppa
            VStack(spacing: 12) {
                Text(audioRecorder.isRecording ? "Håll inne för att fortsätta" : "Håll inne för att spela in")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                Circle()
                    .fill(audioRecorder.isRecording ? Color.red : Color("AccentBlue"))
                    .frame(width: 72, height: 72)
                    .overlay(
                        Image(systemName: audioRecorder.isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white)
                    )
                    // Blir lite större under inspelning för visuell feedback
                    .scaleEffect(audioRecorder.isRecording ? 1.08 : 1.0)
                    .animation(.spring(response: 0.3), value: audioRecorder.isRecording)
                    // LongPressGesture startar inspelning, DragGesture avslutar den
                    .gesture(
                        LongPressGesture(minimumDuration: 0.2)
                            .onChanged { _ in
                                if !audioRecorder.isRecording { startRecording() }
                            }
                            .sequenced(before: DragGesture(minimumDistance: 0))
                            .onEnded { _ in stopRecording() }
                    )
                    .simultaneousGesture(
                        TapGesture().onEnded {
                            if audioRecorder.isRecording { stopRecording() }
                        }
                    )
            }

            Button("Avbryt") {
                audioRecorder.cancelRecording()
            }
            .font(.system(size: 15))
            .foregroundStyle(.secondary)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Puck-Mikrofon")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showLocationPicker) {
            LocationPickerView(audioFileName: recordedFileName, duration: recordedDuration)
        }
        // Visas om användaren inte har gett mikrofontillstånd
        .alert("Mikrofonåtkomst krävs", isPresented: $showPermissionAlert) {
            Button("Öppna inställningar") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Avbryt", role: .cancel) {}
        } message: {
            Text("Gå till Inställningar och aktivera mikrofon för Puck-Mikrofon.")
        }
        // Fråga om mikrofontillstånd när skärmen visas
        .task {
            hasPermission = await audioRecorder.requestPermission()
            if !hasPermission { showPermissionAlert = true }
        }
    }

    private func startRecording() {
        guard hasPermission else {
            showPermissionAlert = true
            return
        }
        audioRecorder.startRecording()
    }

    // Stoppa inspelningen och gå vidare till kartskärmen för att välja plats
    private func stopRecording() {
        let result = audioRecorder.stopRecording()
        recordedFileName = result.fileName
        recordedDuration = result.duration
        // Kräv minst 1 sekund för att det ska räknas som en riktig inspelning
        if recordedDuration > 1 {
            showLocationPicker = true
        }
    }

    private func formatTime(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        return String(format: "%d:%02d", m, s)
    }
}

// Den animerade vågformen under inspelning
// Varje stapel representerar en av de 30 ljudnivåerna från AudioRecorder
struct LiveWaveformView: View {
    let levels: [Float]

    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .center, spacing: 2) {
                ForEach(Array(levels.enumerated()), id: \.offset) { _, level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.red.opacity(0.8))
                        .frame(
                            width: (geo.size.width - CGFloat(levels.count - 1) * 2) / CGFloat(levels.count),
                            height: max(4, CGFloat(level) * geo.size.height)
                        )
                        .animation(.easeOut(duration: 0.1), value: level)
                }
            }
        }
    }
}

#Preview {
    NavigationStack { RecordingView() }
        .environmentObject(AudioRecorder())
}
