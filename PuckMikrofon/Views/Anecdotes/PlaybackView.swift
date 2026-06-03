import SwiftUI

struct PlaybackView: View {
    let anecdote: Anecdote
    @StateObject private var player = AudioPlayer()

    var body: some View {
        VStack(spacing: 0) {
            // Header card
            VStack(alignment: .leading, spacing: 4) {
                Text("Spelar upp:")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                Text(anecdote.title)
                    .font(.system(size: 18, weight: .semibold))
                Text(""\(anecdote.description)"")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color(.systemBackground))

            Divider()

            Spacer()

            // Waveform + progress
            VStack(spacing: 16) {
                WaveformView(progress: player.progress)
                    .frame(height: 60)
                    .padding(.horizontal, 16)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(.systemFill))
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color("AccentBlue"))
                            .frame(width: geo.size.width * player.progress, height: 4)
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { val in
                                let fraction = min(max(val.location.x / geo.size.width, 0), 1)
                                player.seek(to: fraction)
                            }
                    )
                }
                .frame(height: 4)
                .padding(.horizontal, 16)

                // Time labels
                HStack {
                    Text(formatTime(player.currentTime))
                    Spacer()
                    Text(formatTime(player.duration))
                }
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
            }

            // Controls
            HStack(spacing: 36) {
                Button {
                    player.seek(to: max(player.progress - 0.05, 0))
                } label: {
                    Image(systemName: "gobackward.10")
                        .font(.system(size: 26))
                        .foregroundStyle(.primary)
                }

                Button {
                    player.togglePlayPause()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color("AccentBlue"))
                            .frame(width: 64, height: 64)
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(.white)
                            .offset(x: player.isPlaying ? 0 : 2)
                    }
                }

                Button {
                    player.seek(to: min(player.progress + 0.05, 1))
                } label: {
                    Image(systemName: "goforward.10")
                        .font(.system(size: 26))
                        .foregroundStyle(.primary)
                }
            }
            .padding(.top, 24)

            Text("Tryck på pucken för att pausa")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
                .padding(.top, 16)

            Spacer()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Puck-Mikrofon")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            player.load(fileName: anecdote.audioFileName, fallbackDuration: anecdote.durationSeconds)
            player.play()
        }
        .onDisappear {
            player.stop()
        }
    }

    private func formatTime(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - Waveform

struct WaveformView: View {
    var progress: Double
    private let barCount = 40

    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .center, spacing: 2) {
                ForEach(0..<barCount, id: \.self) { i in
                    let fraction = Double(i) / Double(barCount)
                    let height = barHeight(for: i)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(fraction < progress ? Color("AccentBlue") : Color(.systemFill))
                        .frame(width: (geo.size.width - CGFloat(barCount - 1) * 2) / CGFloat(barCount),
                               height: height)
                }
            }
        }
    }

    private func barHeight(for i: Int) -> CGFloat {
        let base: CGFloat = 8
        let wave = abs(sin(Double(i) * 0.45)) * 44 + Double(i % 3) * 4
        return base + wave
    }
}

#Preview {
    NavigationStack {
        PlaybackView(anecdote: Anecdote.samples[0])
    }
}
