import SwiftUI

@main
struct PuckMikrofonApp: App {
    @StateObject private var store = AnecdoteStore()
    @StateObject private var locationService = LocationService()
    @StateObject private var audioRecorder = AudioRecorder()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(locationService)
                .environmentObject(audioRecorder)
                .onAppear {
                    locationService.requestPermission()
                }
        }
    }
}
