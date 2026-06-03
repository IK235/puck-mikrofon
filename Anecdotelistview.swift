//
//  Anecdotelistview.swift
//  PuckMikrofon
//
//  Created by ikbal erdal on 2026-04-04.
//

import SwiftUI

// Listan med alla anekdoter på en specifik adress
// Visas när användaren trycker på en nål på kartan
struct AnecdoteListView: View {
    @EnvironmentObject var store: AnecdoteStore
    let address: String

    @State private var selectedAnecdote: Anecdote? = nil
    @State private var showPlayer = false

    // Hämtar bara anekdoter som tillhör den valda adressen
    var anecdotes: [Anecdote] {
        store.anecdotes(for: address)
    }

    var body: some View {
        VStack(spacing: 0) {

            // Adress-header precis som i wireframen
            VStack(alignment: .leading, spacing: 2) {
                Text("Plats:")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Text(address)
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))

            Divider()

            // Scrollbar lista med alla anekdoter
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(anecdotes) { anecdote in
                        AnecdoteRowView(anecdote: anecdote) {
                            selectedAnecdote = anecdote
                            showPlayer = true
                        }
                        Divider().padding(.leading, 60)
                    }
                }
            }
            .background(Color(.systemBackground))
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Puck-Mikrofon")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showPlayer) {
            if let anecdote = selectedAnecdote {
                PlaybackView(anecdote: anecdote)
            } else {
                EmptyView()
            }
        }
    }
}

// En rad i listan — visar titel, beskrivning, längd och en Lyssna-knapp
struct AnecdoteRowView: View {
    let anecdote: Anecdote
    let onListen: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {

            // Blå cirkel med en vågform-ikon
            ZStack {
                Circle()
                    .fill(Color("AccentBlue").opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: "waveform.circle.fill")
                    .foregroundStyle(Color("AccentBlue"))
                    .font(.system(size: 22))
            }

            // Titel och beskrivning
            VStack(alignment: .leading, spacing: 3) {
                Text(anecdote.title)
                    .font(.system(size: 14, weight: .medium))
                Text(anecdote.description)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Längd och lyssna-knapp på höger sida
            VStack(alignment: .trailing, spacing: 6) {
                Text(anecdote.formattedDuration)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                Button("Lyssna") {
                    onListen()
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color("AccentBlue"), in: Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .background(Color(.systemBackground))
        .contentShape(Rectangle())  // gör hela raden klickbar, inte bara knappen
        .onTapGesture { onListen() }
    }
}

#Preview {
    NavigationStack {
        AnecdoteListView(address: "Borgfjordsgatan 67")
    }
    .environmentObject(AnecdoteStore())
}
