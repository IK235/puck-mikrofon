import Foundation
import Combine
import CoreLocation

@MainActor
class AnecdoteStore: ObservableObject {
    @Published var anecdotes: [Anecdote] = []
    @Published var selectedCategory: AnecdoteCategory = .dagliga
    @Published var selectedLocation: CLLocationCoordinate2D? = nil
    @Published var selectedAddress: String = ""

    private let storageKey = "saved_anecdotes"

    init() {
        load()
        if anecdotes.isEmpty {
            anecdotes = Anecdote.samples
        }
    }

    var filtered: [Anecdote] {
        anecdotes.filter { $0.category == selectedCategory }
    }

    func anecdotes(for address: String) -> [Anecdote] {
        anecdotes.filter { $0.address == address }
    }

    func add(_ anecdote: Anecdote) {
        anecdotes.insert(anecdote, at: 0)
        save()
    }

    func delete(_ anecdote: Anecdote) {
        anecdotes.removeAll { $0.id == anecdote.id }
        save()
    }

    // MARK: - Persistence
    private func save() {
        if let data = try? JSONEncoder().encode(anecdotes) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([Anecdote].self, from: data) else { return }
        anecdotes = decoded
    }
}
