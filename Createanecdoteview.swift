//
//  Createanecdoteview.swift
//  PuckMikrofon
//
//  Created by ikbal erdal on 2026-04-04.
//

import SwiftUI

// Första steget i inspelningsflödet
// Förklarar för användaren att de ska hålla in knappen på pucken
struct CreateAnecdoteView: View {
    @EnvironmentObject var audioRecorder: AudioRecorder
    @State private var showRecording = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 6) {
                Text("Skapa ny anekdot")
                    .font(.system(size: 20, weight: .semibold))
                Text("Berätta en platsbaserad historia")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }

            // Instruktionsrutan med en puck-ikon
            VStack(spacing: 20) {
                Image(systemName: "mic.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color("AccentBlue"))
                    .symbolEffect(.pulse)   // pulserar lite för att locka uppmärksamhet

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

            // Avbryt går tillbaka, Fortsätt tar oss till inspelningsskärmen
            HStack(spacing: 12) {
                Button("Avbryt") {}
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
    NavigationStack { CreateAnecdoteView() }
        .environmentObject(AudioRecorder())
}
