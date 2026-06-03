import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            MapHomeView()
        }
        .tint(Color("AccentBlue"))
    }
}

#Preview {
    ContentView()
        .environmentObject(AnecdoteStore())
        .environmentObject(LocationService())
        .environmentObject(AudioRecorder())
}
