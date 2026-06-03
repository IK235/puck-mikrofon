//
//  Infoview.swift
//  PuckMikrofon
//
//  Created by ikbal erdal on 2026-04-04.
//

import SwiftUI

// Info-skärmen — visas när man trycker på Info-knappen uppe till höger
// Förklarar appen och vem den är till för (baserat på user stories)
struct InfoView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Appikon och titel
                    VStack(spacing: 10) {
                        Image(systemName: "mic.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(Color("AccentBlue"))
                        Text("Puck-Mikrofon")
                            .font(.system(size: 22, weight: .semibold))
                        Text("Dela och bevara lokalhistoria")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)

                    Divider()

                    // Steg-för-steg förklaring av hur appen fungerar
                    InfoSection(title: "Hur det fungerar", items: [
                        InfoItem(icon: "map.fill",           text: "Utforska kartan och hitta anekdoter nära museet"),
                        InfoItem(icon: "waveform",           text: "Tryck på en nål för att lyssna på berättelser"),
                        InfoItem(icon: "mic.fill",           text: "Spela in nya berättelser med pucken vid museet — inte i appen"),
                        InfoItem(icon: "arrow.up.circle.fill", text: "Skicka din inspelning till telefonen med Skicka-knappen på pucken")
                    ])

                    Divider()

                    // Baserat på user stories från Fas 1
                    InfoSection(title: "Vem är det för?", items: [
                        InfoItem(icon: "person.fill",   text: "Äldre boende som vill bevara sina minnen"),
                        InfoItem(icon: "house.fill",    text: "Nyinflyttade som vill lära sig platsens historia"),
                        InfoItem(icon: "building.fill", text: "Fastighetsägare som vill dela historier om sin fastighet")
                    ])

                    Divider()

                    Text("Version 1.0 · Puck-Mikrofon")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 20)
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("Om appen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Stäng") { dismiss() }
                }
            }
        }
    }
}

// En sektion med rubrik och lista av punkter med ikoner
struct InfoSection: View {
    let title: String
    let items: [InfoItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
            ForEach(items) { item in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: item.icon)
                        .font(.system(size: 16))
                        .foregroundStyle(Color("AccentBlue"))
                        .frame(width: 24)
                    Text(item.text)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct InfoItem: Identifiable {
    let id = UUID()
    let icon: String
    let text: String
}

#Preview { InfoView() }
