import SwiftUI
import MapKit

struct LocationPickerView: View {
    @EnvironmentObject var store: AnecdoteStore
    @EnvironmentObject var locationService: LocationService

    let audioFileName: String
    let duration: Double

    @State private var region = MapRegionDefaults.initialMuseumRegion
    @State private var selectedCoordinate: CLLocationCoordinate2D? = nil
    @State private var resolvedAddress: String = ""
    @State private var isResolvingAddress = false
    @State private var category: AnecdoteCategory = .dagliga
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var showSuccess = false
    @State private var savedAnecdote: Anecdote? = nil
    @State private var didApplyInitialUserLocation = false

    var canSave: Bool {
        selectedCoordinate != nil && !title.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            // Form fields
            VStack(alignment: .leading, spacing: 14) {
                Text("Var hände din berättelse?")
                    .font(.system(size: 15, weight: .semibold))

                TextField("Titel (t.ex. Här byggdes första huset)", text: $title)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 14))

                TextField("Kort beskrivning (valfri)", text: $description)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 14))

                // Category picker
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

            // Map
            ZStack {
                Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: selectedCoordinate.map { [MapPin(coordinate: $0)] } ?? []) { pin in
                    MapAnnotation(coordinate: pin.coordinate) {
                        MapPinView()
                    }
                }
                .onTapGesture { location in
                    // Convert tap to coordinate via UIKit since SwiftUI Map tap isn't directly available
                }

                // Instruction overlay
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
                    VStack {
                        Spacer()
                        if isResolvingAddress {
                            ProgressView()
                                .padding(.bottom, 12)
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

                // Tap interceptor overlay
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        setPin(at: location)
                    }
            }
            .frame(maxHeight: .infinity)

            Divider()

            // Bottom actions
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
                SuccessView(anecdote: anecdote)
            }
        }
        .onAppear {
            applySwedishUserLocationIfNeeded()
        }
        .onChange(of: locationService.userLocation?.latitude) { _, _ in
            applySwedishUserLocationIfNeeded()
        }
    }

    private func applySwedishUserLocationIfNeeded() {
        guard !didApplyInitialUserLocation,
              let loc = locationService.userLocation,
              loc.isApproximatelyInSweden else { return }
        didApplyInitialUserLocation = true
        region.center = loc
        region.span = MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
        selectedCoordinate = loc
        resolveAddress(loc)
    }

    private func setPin(at screenPoint: CGPoint) {
        // Approximate conversion from screen point to coordinate
        // In a real app use MKMapView UIViewRepresentable for precise tap handling
        let mapWidth = UIScreen.main.bounds.width
        let mapHeight = UIScreen.main.bounds.height * 0.45
        let latDelta = region.span.latitudeDelta
        let lonDelta = region.span.longitudeDelta
        let lat = region.center.latitude + (0.5 - screenPoint.y / mapHeight) * latDelta
        let lon = region.center.longitude + (screenPoint.x / mapWidth - 0.5) * lonDelta
        let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        selectedCoordinate = coord
        resolveAddress(coord)
    }

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

    private func saveAnecdote() {
        guard let coord = selectedCoordinate else { return }
        let finalTitle = title.isEmpty ? "Anekdot" : title
        let finalDesc = description.isEmpty ? "" : description
        let finalAddr = resolvedAddress.isEmpty ? "Okänd adress" : resolvedAddress

        let anecdote = Anecdote(
            title: finalTitle,
            description: finalDesc,
            audioFileName: audioFileName,
            durationSeconds: duration,
            latitude: coord.latitude,
            longitude: coord.longitude,
            address: finalAddr,
            category: category
        )
        store.add(anecdote)
        savedAnecdote = anecdote
        showSuccess = true
    }
}

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
