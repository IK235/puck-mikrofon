//
//  Playbackview.swift
//  PuckMikrofon
//
//  Created by ikbal erdal on 2026-04-04.
//
import SwiftUI
import CoreImage.CIFilterBuiltins

struct PlaybackView: View {
    let anecdote: Anecdote

    @StateObject private var voice = ElevenLabsService()
    @State private var showQR = false
    @State private var pulseScale: CGFloat = 1.0

    private var speechText: String {
        let body = anecdote.description.trimmingCharacters(in: .whitespacesAndNewlines)
        if !body.isEmpty { return body }
        return anecdote.title
    }

  // Huvudvy — kombinerar anekdottitel, vågformanimation, progress bar och play-kontroller
    var body: some View {
        VStack(spacing: 0) {

            // Rubriksektion — visar anekdotens titel och beskrivning överst
            VStack(alignment: .leading, spacing: 4) {
                Text("Spelar upp:")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                Text(anecdote.title)
                    .font(.system(size: 18, weight: .semibold))
                Text(anecdote.description)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color(.systemBackground))

            Divider()

            Spacer()

            // Röstmemo-UI — vågform, tidslinje och play styrs av AI-uppspelningen
            VStack(spacing: 16) {
                WaveformView(progress: voice.progress, isAnimating: voice.isPlaying)
                    .frame(height: 60)
                    .padding(.horizontal, 16)
                    .opacity(voice.isLoading ? 0.5 : 1)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(.systemFill))
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color("AccentBlue"))
                            .frame(width: geo.size.width * voice.progress, height: 4)
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { val in
                                let fraction = min(max(val.location.x / geo.size.width, 0), 1)
                                voice.seek(to: fraction)
                            }
                    )
                }
                .frame(height: 4)
                .padding(.horizontal, 16)

                HStack {
                    Text(formatTime(voice.currentTime))
                    Spacer()
                    Text(formatTime(voice.duration))
                }
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
            }

            // Uppspelningskontroller — bakåt 10s, play/paus och framåt 10s
            HStack(spacing: 36) {
                Button {
                    voice.seek(to: max(voice.progress - 0.05, 0))
                } label: {
                    Image(systemName: "gobackward.10")
                        .font(.system(size: 26))
                        .foregroundStyle(.primary)
                }
                .disabled(voice.isLoading || voice.duration == 0)

                Button {
                    voice.togglePlayPause(text: speechText)
                } label: {
                    ZStack {
                        if voice.isPlaying {
                            Circle()
                                .stroke(Color("AccentBlue").opacity(0.35), lineWidth: 3)
                                .frame(width: 76, height: 76)
                                .scaleEffect(pulseScale)
                                .animation(
                                    .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                                    value: pulseScale
                                )
                        }

                        Circle()
                            .fill(Color("AccentBlue"))
                            .frame(width: 64, height: 64)

                        if voice.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: voice.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 26))
                                .foregroundStyle(.white)
                                .offset(x: voice.isPlaying ? 0 : 2)
                        }
                    }
                }
                .disabled(speechText.isEmpty)
                .onAppear { pulseScale = 1.12 }

                Button {
                    voice.seek(to: min(voice.progress + 0.05, 1))
                } label: {
                    Image(systemName: "goforward.10")
                        .font(.system(size: 26))
                        .foregroundStyle(.primary)
                }
                .disabled(voice.isLoading || voice.duration == 0)
            }
            .padding(.top, 24)

            Button {
                showQR = true
            } label: {
                Label("Dela anekdot", systemImage: "qrcode")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color("AccentBlue"))
            }
            .padding(.top, 16)
            .sheet(isPresented: $showQR) {
                QRShareView(anecdote: anecdote)
            }

            Text("Tryck på play för att höra berättelsen")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
                .padding(.top, 8)

            Spacer()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Puck-Mikrofon")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            voice.stop()
        }
    }

    // Omvandlar sekunder till minuter:sekunder format, t.ex. 90 → "1:30"
    private func formatTime(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        return String(format: "%d:%02d", m, s)
    }
}

struct QRShareView: View {
    let anecdote: Anecdote
    @State private var pulseScale: CGFloat = 1.0

    // Huvudvy — kombinerar anekdottitel, vågformanimation, progress bar och play-kontroller
    var body: some View {
        VStack(spacing: 24) {
            Text("Dela anekdot")
                .font(.title2.bold())

            Text(anecdote.title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let qrImage = generateQR(from: qrText) {
                ZStack {
                    Circle()
                        .stroke(Color("AccentBlue").opacity(0.2), lineWidth: 8)
                        .frame(width: 260, height: 260)
                        .scaleEffect(pulseScale)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseScale)

                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 220, height: 220)
                        .padding()
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            Text("Scanna för att läsa berättelsen")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(32)
        .onAppear { pulseScale = 1.08 }
    }

    private var qrText: String {
        let encoded = anecdote.title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? anecdote.title
        return "https://sv.wikipedia.org/wiki/\(encoded)"
    }

    private func generateQR(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "L"
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 12, y: 12))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

struct WaveformView: View {
    var progress: Double
    var isAnimating: Bool = false
    private let barCount = 40

    // Huvudvy — kombinerar anekdottitel, vågformanimation, progress bar och play-kontroller
    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .center, spacing: 2) {
                ForEach(0..<barCount, id: \.self) { i in
                    let fraction = Double(i) / Double(barCount)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(fraction < progress ? Color("AccentBlue") : Color(.systemFill))
                        .frame(
                            width: (geo.size.width - CGFloat(barCount - 1) * 2) / CGFloat(barCount),
                            height: barHeight(for: i)
                        )
                }
            }
        }
    }

    private func barHeight(for i: Int) -> CGFloat {
        let base: CGFloat = 8
        let wave = abs(sin(Double(i) * 0.45 + (isAnimating ? Date().timeIntervalSinceReferenceDate * 4 : 0))) * 44 + Double(i % 3) * 4
        return base + wave
    }
}

#Preview {
    NavigationStack {
        PlaybackView(anecdote: Anecdote.samples[0])
    }
}
