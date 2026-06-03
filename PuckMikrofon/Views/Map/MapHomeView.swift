import SwiftUI
import MapKit

private struct AddressPin: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
}

struct MapHomeView: View {
    @EnvironmentObject var store: AnecdoteStore
    @EnvironmentObject var locationService: LocationService

    @State private var region = MapRegionDefaults.initialMuseumRegion
    @State private var selectedAddress: String? = nil
    @State private var showAnecdoteList = false
    @State private var showCreateFlow = false
    @State private var showInfo = false
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var searchErrorMessage: String?
    @State private var didApplyInitialUserLocation = false

    var filteredAnecdotes: [Anecdote] {
        store.anecdotes.filter { $0.category == store.selectedCategory }
    }

    /// En nål per adress (samma som wireframe: lista vid tryck på nål).
    var addressPins: [AddressPin] {
        let grouped = Dictionary(grouping: filteredAnecdotes, by: { $0.address })
        return grouped.compactMap { address, list in
            guard let first = list.first else { return nil }
            return AddressPin(id: address, coordinate: first.coordinate)
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // MAP
            Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: addressPins) { pin in
                MapAnnotation(coordinate: pin.coordinate) {
                    MapPinView()
                        .onTapGesture {
                            selectedAddress = pin.id
                            showAnecdoteList = true
                        }
                }
            }
            .ignoresSafeArea(edges: .top)

            // OVERLAY CONTROLS
            VStack(spacing: 0) {
                // Search bar (MKLocalSearch, prioriterar Sverige)
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 14))
                    TextField("Sök adress eller ort i Sverige…", text: $searchText)
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

                // Filter tabs
                HStack(spacing: 10) {
                    ForEach(AnecdoteCategory.allCases) { cat in
                        Button(cat.rawValue) {
                            store.selectedCategory = cat
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(store.selectedCategory == cat ? .white : .primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background(
                            store.selectedCategory == cat
                                ? Color.primary
                                : Color(.systemBackground).opacity(0.9),
                            in: Capsule()
                        )
                        .overlay(Capsule().stroke(Color.primary.opacity(0.15), lineWidth: 1))
                    }
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)

                Spacer()

                // Create button
                Button {
                    showCreateFlow = true
                } label: {
                    Label("Skapa anekdot", systemImage: "plus.circle.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color("AccentBlue"), in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 20)
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
        .navigationDestination(isPresented: $showCreateFlow) {
            CreateAnecdoteView()
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

    /// Simulator/användare utanför Sverige: behåll svensk startvy istället för t.ex. Cupertino.
    private func applyUserLocationIfInSweden() {
        guard !didApplyInitialUserLocation,
              let loc = locationService.userLocation,
              loc.isApproximatelyInSweden else { return }
        didApplyInitialUserLocation = true
        region.center = loc
        region.span = MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
    }

    private func performPlaceSearch() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        isSearching = true
        defer { isSearching = false }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MapRegionDefaults.swedenSearchBiasRegion
        request.resultTypes = [.address, .pointOfInterest]

        do {
            let response = try await MKLocalSearch(request: request).start()
            guard let item = response.mapItems.first else {
                searchErrorMessage = "Hittade ingen plats. Prova t.ex. en gata och ort i Sverige."
                return
            }
            let coord = item.placemark.coordinate
            region = MKCoordinateRegion(
                center: coord,
                span: MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025)
            )
            searchErrorMessage = nil
        } catch {
            searchErrorMessage = "Sökningen misslyckades. Kontrollera nätverket och försök igen."
        }
    }
}

// MARK: - Map Pin

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
            Triangle()
                .fill(isNew ? Color.yellow : Color.red)
                .frame(width: 10, height: 8)
        }
    }
}

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
    NavigationStack {
        MapHomeView()
    }
    .environmentObject(AnecdoteStore())
    .environmentObject(LocationService())
    .environmentObject(AudioRecorder())
}
