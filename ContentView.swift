//
//  ContentView.swift
//  PuckMikrofon
//
//  Created by ikbal erdal on 2026-04-04.
//

import SwiftUI

// Startpunkten för all navigering i appen
// NavigationStack håller koll på vilka skärmar som är öppna
struct ContentView: View {
    var body: some View {
        NavigationStack {
            MapHomeView()
        }
        // Sätter blå färg som standard för knappar och interaktiva element
        .tint(Color("AccentBlue"))
    }
}

#Preview {
    ContentView()
        .environmentObject(AnecdoteStore())
        .environmentObject(LocationService())
}
