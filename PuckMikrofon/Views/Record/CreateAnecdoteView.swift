import SwiftUI

struct CreateAnecdoteView: View {
    @EnvironmentObject var audioRecorder: AudioRecorder
    @State private var showRecording = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Title
            VStack(spacing: 6) {
                Text("Skapa ny anekdot")
                    .font(.system(size: 20, weight: .semibold))
                Text("Berätta en platsbaserad historia")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }

            // Instruction card
            VStack(spacing: 20) {
                Image(systemName: "mic.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color("AccentBlue"))
                    .symbolEffect(.pulse)

                Text("Håll in knappen på pucken\nför att spela in din berättelse")
                    .font(.system(size: 15))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(.systemFill), lineWidth: 1)
            )
            .padding(.horizontal, 20)

            Spacer()

            // Actions
            HStack(spacing: 12) {
                NavigationLink(value: "cancel") {
                    EmptyView()
                }

                Button("Avbryt") {
                    // handled by nav back
                }
                .buttonStyle(SecondaryButtonStyle())

                Button("Fortsätt") {
                    showRecording = true
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Puck-Mikrofon")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showRecording) {
            RecordingView()
        }
    }
}

#Preview {
    NavigationStack {
        CreateAnecdoteView()
    }
    .environmentObject(AudioRecorder())
}
