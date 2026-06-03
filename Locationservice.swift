//
//  Locationservice.swift
//  PuckMikrofon
//
//  Created by ikbal erdal on 2026-04-04.
//

import Foundation
import CoreLocation
import MapKit
import Combine

extension CLLocationCoordinate2D {
    /// Grov avgränsning så simulator/utland inte flyttar museikartan till USA.
    var isApproximatelyInSweden: Bool {
        latitude >= 55.0 && latitude <= 69.5 && longitude >= 10.5 && longitude <= 24.5
    }
}

/// Kartvy låst till Stockholms stadsmuseum och närmsta kvarter (skolprojekt: “station” vid museet).
enum MuseumMapBounds {
    /// Ryssgården / Stockholms stadsmuseum — ankarpunkt för kartan.
    static let museumCenter = CLLocationCoordinate2D(latitude: 59.3198, longitude: 18.0715)

    /// Rektangel över museiområdet (ca 1–1,5 km — gångavstånd runt museet).
    private static let minLatitude = 59.314
    private static let maxLatitude = 59.334
    private static let minLongitude = 18.062
    private static let maxLongitude = 18.078

    private static let minLatSpan: CLLocationDegrees = 0.004
    private static let maxLatSpan: CLLocationDegrees = 0.018
    private static let maxLonSpan: CLLocationDegrees = 0.014

    /// Startzoom: museet syns tydligt, man kan inte scrolla bort till resten av stan i första vyn.
    static var initialRegion: MKCoordinateRegion {
        MKCoordinateRegion(
            center: museumCenter,
            span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.010)
        )
    }

    /// Lokalsök (gator/platser) begränsas till samma zon som kartan.
    static var localSearchRegion: MKCoordinateRegion {
        MKCoordinateRegion(
            center: museumCenter,
            span: MKCoordinateSpan(latitudeDelta: 0.022, longitudeDelta: 0.017)
        )
    }

    static func contains(_ c: CLLocationCoordinate2D) -> Bool {
        c.latitude >= minLatitude && c.latitude <= maxLatitude &&
            c.longitude >= minLongitude && c.longitude <= maxLongitude
    }

    /// Sätt nål/inspelningsplats — alltid inom museiområdet.
    static func clampCoordinate(_ c: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: min(max(c.latitude, minLatitude), maxLatitude),
            longitude: min(max(c.longitude, minLongitude), maxLongitude)
        )
    }

    /// Håll pan och zoom inom museets ruta.
    static func clampRegion(_ r: MKCoordinateRegion) -> MKCoordinateRegion {
        var span = r.span
        span.latitudeDelta = min(max(span.latitudeDelta, minLatSpan), maxLatSpan)
        span.longitudeDelta = min(max(span.longitudeDelta, minLatSpan * 0.75), maxLonSpan)
        var c = r.center
        c.latitude = min(max(c.latitude, minLatitude), maxLatitude)
        c.longitude = min(max(c.longitude, minLongitude), maxLongitude)
        return MKCoordinateRegion(center: c, span: span)
    }
}

/// Bakåtkompatibelt alias för startvy.
enum MapRegionDefaults {
    static var initialMuseumRegion: MKCoordinateRegion { MuseumMapBounds.initialRegion }
}

// Hanterar allt med GPS och adresser
// Frågar om tillstånd, hämtar position och omvandlar koordinater till gatuadresser
@MainActor
class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {

    // Användarens nuvarande position — nil om vi inte fått tillstånd ännu
    @Published var userLocation: CLLocationCoordinate2D? = nil

    // Om användaren har godkänt platsåtkomst eller inte
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = manager.authorizationStatus
    }

    // Visar iOS-dialogen "Tillåt Puck-Mikrofon att använda din plats?"
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func startUpdating() {
        manager.startUpdatingLocation()
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()
    }

    // Omvandlar en koordinat till en läsbar gatuadress, t.ex. "Borgfjordsgatan 67, Stockholm"
    // async/await gör att vi kan vänta på svaret utan att frysa UI:t
    func reverseGeocode(coordinate: CLLocationCoordinate2D) async -> String {
        let loc = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(loc)
            if let p = placemarks.first {
                let street = p.thoroughfare ?? ""
                let number = p.subThoroughfare ?? ""
                let city = p.locality ?? ""
                let result = [street + " " + number, city]
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
                    .joined(separator: ", ")
                return result.isEmpty ? "Okänd adress" : result
            }
        } catch {
            print("Kunde inte hämta adress: \(error)")
        }
        return "Okänd adress"
    }

    // Kallas av iOS när vi får en ny GPS-position
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { @MainActor in
            self.userLocation = loc.coordinate
        }
    }

    // Kallas av iOS när användaren ändrar platsbehörighet (godkänner eller nekar)
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
            // Börja uppdatera position automatiskt så fort vi får tillstånd
            if manager.authorizationStatus == .authorizedWhenInUse ||
               manager.authorizationStatus == .authorizedAlways {
                manager.startUpdatingLocation()
            }
        }
    }
}
