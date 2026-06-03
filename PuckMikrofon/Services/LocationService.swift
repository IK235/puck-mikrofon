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

enum MapRegionDefaults {
    /// Startvy: Stockholmsområdet (stadsmuseum), tydligt svensk kontext.
    static let initialMuseumRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 59.3293, longitude: 18.0686),
        span: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12)
    )

    /// Bias för MKLocalSearch så gator och orter i Sverige prioriteras.
    static let swedenSearchBiasRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 62.0, longitude: 14.5),
        span: MKCoordinateSpan(latitudeDelta: 11, longitudeDelta: 9)
    )
}

@MainActor
class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var userLocation: CLLocationCoordinate2D? = nil
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var lastResolvedAddress: String = ""

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = manager.authorizationStatus
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func startUpdating() {
        manager.startUpdatingLocation()
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()
    }

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
            print("Geocode error: \(error)")
        }
        return "Okänd adress"
    }

    // MARK: - Delegate
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { @MainActor in
            self.userLocation = loc.coordinate
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
            if manager.authorizationStatus == .authorizedWhenInUse ||
               manager.authorizationStatus == .authorizedAlways {
                manager.startUpdatingLocation()
            }
        }
    }
}
