//
//  BebyggelseService.swift
//  PuckMikrofon
//
//  Created by ikbal erdal on 2026-04-22.
//

import Foundation
import CoreLocation

// Detta Avkodar JSON-svaret från Wikipedia REST API
struct WikiSummary: Decodable {
    let title: String
    let extract: String
    let coordinates: WikiCoords?

    // Koordinater finns inte alltid i Wikipedia, därför Optional
    struct WikiCoords: Decodable {
        let lat: Double
        let lon: Double
    }
}

// Hämtar historiska anekdoter från Svenska Wikipedia för 7 Stockholmsplatser
// Singleton (shared) så att appen bara skapar en instans
class BebyggelseService {
    static let shared = BebyggelseService()

    // Stockholmsplatser med Wikipedia-artikelnamn och visningsadress
    // article = exakt Wikipedia-sidnamn, address = adress som visas i appen
    private let places: [(article: String, address: String)] = [
        ("Katarinahissen", "Stadsgårdsleden 22"),
        ("Stadsmuseet_i_Stockholm", "Ryssgården, Slussen"),
        ("Mosebacketerrassen", "Mosebacke torg"),
        ("Fjällgatan", "Södermalm"),
        ("Södermalmstorg", "Södermalm"),
        ("Slussen", "Slussen, Stockholm"),
        ("Stockholms_gamla_stan", "Gamla Stan")
    ]

    // Hämtar anekdoter för alla platser parallellt med TaskGroup för bättre prestanda
    // Om API:t misslyckas helt returneras fallback-data istället
    func fetchStockholmAnecdotes() async -> [Anecdote] {
        var anecdotes: [Anecdote] = []

        await withTaskGroup(of: Anecdote?.self) { group in
            for place in places {
                // Varje plats hämtas parallellt för snabbare laddning
                group.addTask {
                    await self.fetchWikiSummary(article: place.article, address: place.address)
                }
            }
            for await result in group {
                if let anecdote = result {
                    anecdotes.append(anecdote)
                }
            }
        }

        // Om inga anekdoter hämtades från API:t — använder hårdkodad fallback-data
        return anecdotes.isEmpty ? fallback() : anecdotes
    }

    // Hämtar sammanfattning för en Wikipedia-artikel och omvandlar till Anecdote-objekt
    // Använder sv.wikipedia.org REST API: /api/rest_v1/page/summary/{artikel}
    private func fetchWikiSummary(article: String, address: String) async -> Anecdote? {
        let urlStr = "https://sv.wikipedia.org/api/rest_v1/page/summary/\(article)"
        guard let url = URL(string: urlStr) else { return nil }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            let wiki = try JSONDecoder().decode(WikiSummary.self, from: data)

            // Använd Wikipedia-koordinater om de finns, annars fallback till Slussen
            let lat = wiki.coordinates?.lat ?? 59.3198
            let lon = wiki.coordinates?.lon ?? 18.0715

            return Anecdote(
                title: wiki.title.replacingOccurrences(of: "_", with: " "),
                description: wiki.extract,
                durationSeconds: 0,
                latitude: lat,
                longitude: lon,
                address: address,
                category: .viktiga
            )
        } catch {
            return nil
        }
    }

    // Hårdkodad reservdata som visas om Wikipedia API inte svarar
    // Innehåller verkliga historiska fakta om Stockholmsplatser
    private func fallback() -> [Anecdote] {
        [
            Anecdote(title: "Stockholms stadsmuseum",
                     description: "Museet grundades 1936 och berättar Stockholms historia från medeltid till nutid. Byggnaden ritades av Nicodemus Tessin den äldre på 1600-talet.",
                     durationSeconds: 0, latitude: 59.3198, longitude: 18.0715,
                     address: "Ryssgården, Slussen", category: .viktiga),
            Anecdote(title: "Katarinahissen",
                     description: "Katarinahissen invigdes 1883 och var en av Europas första offentliga hissar. Den fraktade Södermalms arbetare ner till Stadsgården varje morgon.",
                     durationSeconds: 0, latitude: 59.3183, longitude: 18.0731,
                     address: "Stadsgårdsleden 22", category: .viktiga),
            Anecdote(title: "Mosebacke torg",
                     description: "Mosebacke torg fick sitt namn efter en trädgårdsmästare vid namn Moses som odlade grönsaker här på 1600-talet. August Strindberg beskrev torget i flera av sina verk.",
                     durationSeconds: 0, latitude: 59.3217, longitude: 18.0756,
                     address: "Mosebacke torg", category: .dagliga),
            Anecdote(title: "Fjällgatan",
                     description: "Fjällgatan anlades på 1700-talet och räknas som en av Stockholms vackraste gator med utsikt över hela innerstaden.",
                     durationSeconds: 0, latitude: 59.3196, longitude: 18.0776,
                     address: "Fjällgatan", category: .dagliga),
            Anecdote(title: "Södermalmstorg",
                     description: "Södermalmstorg har sedan medeltiden varit en viktig mötesplats för hantverkare och handelsmän från hela Södermalm.",
                     durationSeconds: 0, latitude: 59.3201, longitude: 18.0682,
                     address: "Södermalmstorg", category: .dagliga)
        ]
    }
}
