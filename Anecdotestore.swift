//
//  Anecdotestore.swift
//  PuckMikrofon
//
//  Created by ikbal erdal on 2026-04-04.
//

import Foundation
import Combine
import CoreLocation

// Huvudlagret för appen, detta håller alla anekdoter i minnet och synkar mot UserDefaults
//ObservableObject gör att SwiftUI-vyer uppdateras automatiskt när data ändras
@MainActor
class AnecdoteStore: ObservableObject {

    // Alla anekdoter som visas i appen - uppdateras från Wikipedia API vid start
    @Published var anecdotes: [Anecdote] = []

    // Vilket filter som är aktivt just nu - Dagliga eller Viktiga
    @Published var selectedCategory: AnecdoteCategory = .dagliga

    // Nyckel för att spara/läsa anekdoter lokalt på enheten
    private let storageKey = "saved_anecdotes"

    init() {
        // Rensar gamla sparade anekdoter vid varje start så vi alltid får uppdaterad Wikipedia data
        UserDefaults.standard.removeObject(forKey: storageKey)
        anecdotes = []

        Task {
            // Häämtar anekdoter från Wikipedia API ej samtidigt för att inte frysa UI:t
            var apiAnecdotes = await BebyggelseService.shared.fetchStockholmAnecdotes()

            // Demo-anekdot som alltid visas - baserad på verklig historisk händelse i Gamla Stan
            let demoAnecdote = Anecdote(
                id: UUID(),
                title: "Brandkatastrofen 1759",
                description: "På denna plats utbröt en förödande brand i januari 1759 som ödelade flera kvarter i Gamla Stan. Branden spred sig snabbt längs de trånga gränderna och tog med sig flera av de äldsta trähusen. Stadens brandvakt hade svårt att nå fram i det kalla vintermörkret.",
                audioFileName: "",
                durationSeconds: 45,
                latitude: 59.3235,
                longitude: 18.0723,
                address: "Stortorget, Gamla Stan",
                category: .dagliga,
                createdAt: Date()
            )

            // Lägger demo-anekdoten först i listan
            apiAnecdotes.insert(demoAnecdote, at: 0)
            self.anecdotes = apiAnecdotes
            self.save()
        }
    }

    // Returnerar bara de anekdoter som matchar det valda filtret (Dagliga/Viktiga)
    var filtered: [Anecdote] {
        anecdotes.filter { $0.category == selectedCategory }
    }

    // Hämtar alla anekdoter kopplade till en specifik adress - används när användaren trycker på en kartpin
    func anecdotes(for address: String) -> [Anecdote] {
        anecdotes.filter { $0.address == address }
    }

    // Lägger till en ny anekdot och sparar direkt till UserDefaults
    func add(_ anecdote: Anecdote) {
        anecdotes.insert(anecdote, at: 0)
        save()
    }

    // Tar bort en anekdot och sparar den uppdaterade listan
    func delete(_ anecdote: Anecdote) {
        anecdotes.removeAll { $0.id == anecdote.id }
        save()
    }

    // Kodar anekdotlistan till JSON och sparar lokalt på enheten via UserDefaults
    private func save() {
        if let data = try? JSONEncoder().encode(anecdotes) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    // Läser sparad JSON från UserDefaults och avkodar tillbaka till anekdoter
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([Anecdote].self, from: data) else { return }
        anecdotes = decoded
    }
}
