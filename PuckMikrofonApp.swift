//
//  PuckMikrofonApp.swift
//  PuckMikrofon
//
//  Created by ikbal erdal on 2026-04-04.
//

import SwiftUI

@main
struct PuckMikrofonApp: App {

    // Skapar en enda instans av varje service som delas med hela appen
    // @StateObject ser till att de inte förstörs när vyer ritas om
    @StateObject private var store = AnecdoteStore()
    @StateObject private var locationService = LocationService()
    @StateObject private var audioRecorder = AudioRecorder()

    var body: some Scene {
        WindowGroup {
            ContentView()
                // Gör att alla vyer kan komma åt dessa objekt utan att skicka dem manuellt
                .environmentObject(store)
                .environmentObject(locationService)
                .environmentObject(audioRecorder)
                .preferredColorScheme(.dark) // Mörkbakgrund för alla vyer
                .onAppear {
                    // Fråga om platstillstånd direkt när appen öppnas
                    locationService.requestPermission()
                }
        }
    }
}
