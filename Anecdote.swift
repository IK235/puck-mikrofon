//
//  Anecdote.swift
//  PuckMikrofon
//
//  Created by ikbal erdal on 2026-04-04.
//

import Foundation
import CoreLocation

// Dagliga = vardagshistorier, Viktiga = historiska händelser
enum AnecdoteCategory: String, CaseIterable, Codable, Identifiable {
    case dagliga = "Dagliga"
    case viktiga = "Viktiga"
    var id: String { rawValue }
}

// Datamodell för en anekdot — titel, ljud, plats, kategori
struct Anecdote: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var description: String
    var audioFileName: String   // namnet på .m4a-filen sparad i Documents-mappen
    var durationSeconds: Double
    var latitude: Double
    var longitude: Double
    var address: String         // gatuadress t.ex. "Borgfjordsgatan 67"
    var category: AnecdoteCategory
    var createdAt: Date

    // För att göra det enkelt att använda koordinaten direkt med MapKit
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    // Visar längden som "2 min" eller "45 sek" i listvy
    var formattedDuration: String {
        let m = Int(durationSeconds) / 60
        let s = Int(durationSeconds) % 60
        return m > 0 ? "\(m) min" : "\(s) sek"
    }

    // Visar längden som "2:05" i spelaren
    var formattedProgress: String {
        let m = Int(durationSeconds) / 60
        let s = Int(durationSeconds) % 60
        return String(format: "%d:%02d", m, s)
    }

    static func == (lhs: Anecdote, rhs: Anecdote) -> Bool { lhs.id == rhs.id }

    // Testdata så appen inte är tom första gången den startar
    static let samples: [Anecdote] = [
        Anecdote(
            id: UUID(),
            title: "Anekdot 1",
            description: "Här byggdes första huset",
            audioFileName: "sample1.m4a",
            durationSeconds: 120,
            latitude: 59.3293,
            longitude: 18.0686,
            address: "Borgfjordsgatan 67",
            category: .dagliga,
            createdAt: Date()
        ),
        Anecdote(
            id: UUID(),
            title: "Anekdot 2",
            description: "Minnen från 1950-talet",
            audioFileName: "sample2.m4a",
            durationSeconds: 240,
            latitude: 59.3300,
            longitude: 18.0700,
            address: "Borgfjordsgatan 67",
            category: .viktiga,
            createdAt: Date()
        ),
        Anecdote(
            id: UUID(),
            title: "Anekdot 3",
            description: "Arkitektens berättelse",
            audioFileName: "sample3.m4a",
            durationSeconds: 120,
            latitude: 59.3285,
            longitude: 18.0670,
            address: "Storgatan 12",
            category: .dagliga,
            createdAt: Date()
        )
    ]

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        audioFileName: String = "",
        durationSeconds: Double = 0,
        latitude: Double,
        longitude: Double,
        address: String = "",
        category: AnecdoteCategory = .dagliga,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.audioFileName = audioFileName
        self.durationSeconds = durationSeconds
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.category = category
        self.createdAt = createdAt
    }
}
