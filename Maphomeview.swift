//
//  Maphomeview.swift
//  PuckMikrofon
//
//  Created by ikbal erdal on 2026-04-04.
//

import SwiftUI
import MapKit

struct AddressPin: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
}

// Huvudskärmen — kartan med alla anekdot-nålar, sökfält och filterknappar
struct MapHomeView: View {
    @EnvironmentObject var store: AnecdoteStore
    @EnvironmentObject var locationService: LocationService

    // Kartans position — låst till Stockholms stadsmuseum (se MuseumMapBounds).
    @State private var region = MuseumMapBounds.initialRegion

    private var regionBinding: Binding<MKCoordinateRegion> {
        Binding(
            get: { region },
            set: { region = MuseumMapBounds.clampRegion($0) }
        )
    }

    @State private var selectedAddress: String? = nil
    @State private var showAnecdoteList = false
    @State private var showInfo = false
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var searchErrorMessage: String?
    @State private var didApplyInitialUserLocation = false

    // Visar bara anekdoter som matchar valt filter (Dagliga/Viktiga)
    var filteredAnecdotes: [Anecdote] {
        store.anecdotes.filter { $0.category == store.selectedCategory }
    }

    /// En nål per adress — samma idé som wireframe (lista när man trycker på nålen).
    var addressPins: [AddressPin] {
        let grouped = Dictionary(grouping: filteredAnecdotes, by: { $0.address })
        return grouped.compactMap { address, list in
            guard let first = list.first else { return nil }
            return AddressPin(id: address, coordinate: first.coordinate)
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {

            // Kartan tar upp hela skärmen
            Map(coordinateRegion: regionBinding, showsUserLocation: true, annotationItems: addressPins) { pin in
                MapAnnotation(coordinate: pin.coordinate) {
                    MapPinView()
                        .onTapGesture {
                            selectedAddress = pin.id
                            showAnecdoteList = true
                        }
                }
            }
            .ignoresSafeArea(edges: .top)

            // Kontroller som ligger ovanpå kartan
            VStack(spacing: 0) {

                // Sök — MKLocalSearch med bias mot Sverige
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 14))
                    TextField("Sök gata eller plats vid museet…", text: $searchText)
                        .font(.system(size: 14))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onSubmit { Task { await performPlaceSearch() } }
                    if isSearching {
                        ProgressView()
                            .scaleEffect(0.85)
                    } else if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            searchErrorMessage = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                                .font(.system(size: 16))
                        }
                        .accessibilityLabel("Rensa")
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22))
                .padding(.horizontal, 14)
                .padding(.top, 8)

                // Filterknappar — Dagliga och Viktiga
                HStack(spacing: 10) {
                    ForEach(AnecdoteCategory.allCases) { cat in
                        let isSelected = store.selectedCategory == cat
                        Button(cat.rawValue) {
                            store.selectedCategory = cat
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(isSelected ? Color.white : Color.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background(
                            isSelected
                                ? Color("AccentBlue")
                                : Color(.systemBackground).opacity(0.92),
                            in: Capsule()
                        )
                        .overlay(
                            Capsule().stroke(
                                isSelected ? Color("AccentBlue") : Color.primary.opacity(0.2),
                                lineWidth: 1
                            )
                        )
                    }
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)

                Spacer()
            }
        }
        .navigationTitle("Puck-Mikrofon")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Info") { showInfo = true }
                    .font(.system(size: 13))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.primary.opacity(0.3), lineWidth: 1))
            }
        }
        .navigationDestination(isPresented: $showAnecdoteList) {
            if let addr = selectedAddress {
                AnecdoteListView(address: addr)
            }
        }
        .sheet(isPresented: $showInfo) {
            InfoView()
        }
        .alert("Kunde inte söka", isPresented: Binding(
            get: { searchErrorMessage != nil },
            set: { if !$0 { searchErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { searchErrorMessage = nil }
        } message: {
            Text(searchErrorMessage ?? "")
        }
        .onAppear {
            applyUserLocationIfInSweden()
        }
        .onChange(of: locationService.userLocation?.latitude) { _, _ in
            applyUserLocationIfInSweden()
        }
    }

    /// Centrera bara om GPS är inom museiområdet (annars: simulator/annan stad → behåll museet).
    private func applyUserLocationIfInSweden() {
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
    }

    private func performPlaceSearch() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        isSearching = true
        defer { isSearching = false }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MuseumMapBounds.localSearchRegion
        request.resultTypes = [.address, .pointOfInterest]

        do {
            let response = try await MKLocalSearch(request: request).start()
            guard let item = response.mapItems.first else {
                searchErrorMessage = "Hittade ingen plats nära museet. Prova en gata i området."
                return
            }
            let coord = item.placemark.coordinate
            guard MuseumMapBounds.contains(coord) else {
                searchErrorMessage = "Platsen ligger utanför museiområdet. Sök närmare Stockholms stadsmuseum."
                return
            }
            region = MuseumMapBounds.clampRegion(
                MKCoordinateRegion(
                    center: coord,
                    span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.010)
                )
            )
            searchErrorMessage = nil
        } catch {
            searchErrorMessage = "Sökningen misslyckades. Kontrollera nätverket och försök igen."
        }
    }
}

// En röd nål som visas på kartan för varje anekdot
// isNew = true ger en gul stjärn-nål för nyligen sparade anekdoter
struct MapPinView: View {
    var isNew: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(isNew ? Color.yellow : Color.red)
                    .frame(width: 24, height: 24)
                Circle()
                    .fill(.white)
                    .frame(width: 8, height: 8)
            }
            // Den lilla triangeln som pekar ner mot platsen
            Triangle()
                .fill(isNew ? Color.yellow : Color.red)
                .frame(width: 10, height: 8)
        }
    }
}

// En enkel triangelform för nålens spets
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            p.closeSubpath()
        }
    }
}

#Preview {
    NavigationStack { MapHomeView() }
        .environmentObject(AnecdoteStore())
        .environmentObject(LocationService())
        .environmentObject(AudioRecorder())
}

