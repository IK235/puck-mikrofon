//
//  SuccessView.swift
//  PuckMikrofon
//
//  Created by ikbal erdal on 2026-04-04.
//


import SwiftUI
import MapKit

// Bekräftelseskärmen efter att en anekdot sparats
// Visar kartan med den nya nålen och erbjuder att spela in en till
struct SuccessView: View {
    @EnvironmentObject var store: AnecdoteStore
    let anecdote: Anecdote

    @State private var showCreateAnother = false
    @State private var navigateHome = false
    @State private var showShare = false

    // Kartan centreras på den nyss sparade anekdotens plats
    @State private var region: MKCoordinateRegion

    init(anecdote: Anecdote) {
        self.anecdote = anecdote
        _region = State(initialValue: MKCoordinateRegion(
            center: anecdote.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
        ))
    }

    // Visar alla anekdoter i samma kategori på kartan
    var allPins: [Anecdote] {
        store.anecdotes.filter { $0.category == anecdote.category }
    }

    var body: some View {
        VStack(spacing: 16) {

            // Grön bock + bekräftelsetext
            VStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.green)
                Text("Anekdoten har sparats!")
                    .font(.system(size: 18, weight: .semibold))
            }
            .padding(.top, 20)

            // Kartan visar var nålen hamnade
            // Den nya nålen är gul, övriga är röda
            Map(coordinateRegion: $region, annotationItems: allPins) { a in
                MapAnnotation(coordinate: a.coordinate) {
                    MapPinView(isNew: a.id == anecdote.id)
                }
            }
            .frame(maxHeight: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 16)

            Text("Din nål syns nu på kartan!")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)

            // Spela in en till eller gå tillbaka till startskärmen
            HStack(spacing: 12) {
                Button("Gör en till") { showCreateAnother = true }
                    .buttonStyle(PrimaryButtonStyle())

                Button("Till start") { navigateHome = true }
                    .buttonStyle(SecondaryButtonStyle())
            }
            .padding(.horizontal, 16)

            // Öppna dela-skärmen med QR-kod
            Button {
                showShare = true
            } label: {
                Label("Dela anekdot", systemImage: "square.and.arrow.up")
                    .font(.system(size: 14))
                    .foregroundStyle(Color("AccentBlue"))
            }
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Puck-Mikrofon")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)  // vi vill inte att de ska kunna gå tillbaka till inspelningen
        .navigationDestination(isPresented: $showCreateAnother) {
            CreateAnecdoteView()
        }
        .navigationDestination(isPresented: $navigateHome) {
            MapHomeView().navigationBarBackButtonHidden(true)
        }
        .sheet(isPresented: $showShare) {
            ShareAnecdoteView(anecdote: anecdote)
        }
    }
}

#Preview {
    NavigationStack {
        SuccessView(anecdote: Anecdote.samples[0])
    }
    .environmentObject(AnecdoteStore())
}