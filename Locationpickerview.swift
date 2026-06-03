//
//  Locationpickerview.swift
//  PuckMikrofon
//
//  Created by ikbal erdal on 2026-04-04.
//

import SwiftUI
import MapKit

// Här väljer användaren var berättelsen utspelar sig
// Visas direkt efter att inspelningen är klar
struct LocationPickerView: View {
    @EnvironmentObject var store: AnecdoteStore
    @EnvironmentObject var locationService: LocationService

    // Filnamnet och längden från inspelningen skickas hit
    let audioFileName: String
    let duration: Double

    @State private var region = MuseumMapBounds.initialRegion

    private var regionBinding: Binding<MKCoordinateRegion> {
        Binding(
            get: { region },
            set: { region = MuseumMapBounds.clampRegion($0) }
        )
    }

    @State private var selectedCoordinate: CLLocationCoordinate2D? = nil
    @State private var resolvedAddress: String = ""     // gatuadressen för vald koordinat
    @State private var isResolvingAddress = false       // visas medan vi väntar på adress
    @State private var category: AnecdoteCategory = .dagliga
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var showSuccess = false
    @State private var savedAnecdote: Anecdote? = nil
    @State private var didApplyInitialUserLocation = false

    // Spara-knappen är grå tills användaren valt plats och skrivit en titel
    var canSave: Bool {
        selectedCoordinate != nil && !title.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {

            // Formulär för titel, beskrivning och kategori
            VStack(alignment: .leading, spacing: 14) {
                Text("Var hände din berättelse?")
                    .font(.system(size: 15, weight: .semibold))

                TextField("Titel (t.ex. Här byggdes första huset)", text: $title)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 14))

                TextField("Kort beskrivning (valfri)", text: $description)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 14))

                // Välj om det är en daglig eller viktig berättelse
                Picker("Kategori", selection: $category) {
                    ForEach(AnecdoteCategory.allCases) { cat in
                        Text(cat.rawValue).tag(cat)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(16)
            .background(Color(.systemBackground))

            Divider()

            // Kartan där användaren trycker för att sätta sin nål
            ZStack {
                Map(coordinateRegion: regionBinding,
                    showsUserLocation: true,
                    annotationItems: selectedCoordinate.map { [MapPin(coordinate: $0)] } ?? []) { pin in
                    MapAnnotation(coordinate: pin.coordinate) {
                        MapPinView()
                    }
                }

                // Instruktion som försvinner när en plats valts
                if selectedCoordinate == nil {
                    VStack {
                        Spacer()
                        Text("Tryck på kartan för att markera")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.red)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(.regularMaterial, in: Capsule())
                            .padding(.bottom, 12)
                    }
                } else {
                    // Visar adressen för vald plats
                    VStack {
                        Spacer()
                        if isResolvingAddress {
                            ProgressView().padding(.bottom, 12)
                        } else {
                            Text(resolvedAddress)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 5)
                                .background(.regularMaterial, in: Capsule())
                                .padding(.bottom, 12)
                        }
                    }
                }

                // Transparent yta som fångar tapp-gestures på kartan
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        setPin(at: location)
                    }
            }
            .frame(maxHeight: .infinity)

            Divider()

            // Föregående går tillbaka till inspelningen, Spara skapar anekdoten
            HStack {
                Button("‹ Föregående") {}
                    .font(.system(size: 14))
                    .foregroundStyle(Color("AccentBlue"))

                Spacer()

                Button("Spara") {
                    saveAnecdote()
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!canSave)
                .opacity(canSave ? 1 : 0.5)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Puck-Mikrofon")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showSuccess) {
            if let anecdote = savedAnecdote {
            }
        }
        .onAppear {
            applySwedishUserLocationIfNeeded()
        }
        .onChange(of: locationService.userLocation?.latitude) { _, _ in
            applySwedishUserLocationIfNeeded()
        }
    }

    /// Startnål bara om besökaren faktiskt är vid museet; annars väljer man plats på kartan.
    private func applySwedishUserLocationIfNeeded() {
        guard !didApplyInitialUserLocation,
              let loc = locationService.userLocation,
              loc.isApproximatelyInSweden,
              MuseumMapBounds.contains(loc) else { return }
        didApplyInitialUserLocation = true
        region = MuseumMapBounds.clampRegion(
            MKCoordinateRegion(
                center: loc,
                span: MKCoordinateSpan(latitudeDelta: 0.010, longitudeDelta: 0.008)
            )
        )
        selectedCoordinate = loc
        resolveAddress(loc)
    }

    // Omvandlar skärmkoordinater till kartkoordinater och sätter nålen
    private func setPin(at screenPoint: CGPoint) {
        let mapWidth = UIScreen.main.bounds.width
        let mapHeight = UIScreen.main.bounds.height * 0.45
        let lat = region.center.latitude + (0.5 - screenPoint.y / mapHeight) * region.span.latitudeDelta
        let lon = region.center.longitude + (screenPoint.x / mapWidth - 0.5) * region.span.longitudeDelta
        let coord = MuseumMapBounds.clampCoordinate(CLLocationCoordinate2D(latitude: lat, longitude: lon))
        selectedCoordinate = coord
        resolveAddress(coord)
    }

    // Frågar Apple om gatuadressen för den valda koordinaten
    private func resolveAddress(_ coord: CLLocationCoordinate2D) {
        isResolvingAddress = true
        Task {
            let addr = await locationService.reverseGeocode(coordinate: coord)
            await MainActor.run {
                resolvedAddress = addr
                isResolvingAddress = false
            }
        }
    }

    // Bygger ihop anekdot-objektet och sparar det i AnecdoteStore
    private func saveAnecdote() {
        guard let coord = selectedCoordinate else { return }
        let anecdote = Anecdote(
            title: title.isEmpty ? "Anekdot" : title,
            description: description,
            audioFileName: audioFileName,
            durationSeconds: duration,
            latitude: coord.latitude,
            longitude: coord.longitude,
            address: resolvedAddress.isEmpty ? "Okänd adress" : resolvedAddress,
            category: category
        )
        store.add(anecdote)
        savedAnecdote = anecdote
        showSuccess = true
    }
}

// En enkel wrapper för kartnålar (MapKit kräver Identifiable)
struct MapPin: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

#Preview {
    NavigationStack {
        LocationPickerView(audioFileName: "test.m4a", duration: 60)
    }
    .environmentObject(AnecdoteStore())
    .environmentObject(LocationService())
}
