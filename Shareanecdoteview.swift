//
//  Shareanecdoteview.swift
//  PuckMikrofon
//
//  Created by ikbal erdal on 2026-04-04.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

// Skärmen för att dela en anekdot med andra
// Visar en QR-kod som andra kan skanna, samt SMS och e-post-alternativ
struct ShareAnecdoteView: View {
    let anecdote: Anecdote
    @Environment(\.dismiss) var dismiss

    // QR-koden som genereras när vyn laddas
    var qrImage: UIImage {
        generateQR(from: "puckmikrofon://anecdote/\(anecdote.id.uuidString)")
    }

    // Texten som skickas via SMS eller e-post
    var shareText: String {
        "Lyssna på min anekdot: \"\(anecdote.title)\" på \(anecdote.address) – via Puck-Mikrofon"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer()

                Text("Skicka anekdot till telefon")
                    .font(.system(size: 17, weight: .semibold))

                // QR-koden — skanna med en annan telefon för att öppna anekdoten
                Image(uiImage: qrImage)
                    .interpolation(.none)   // håller pixlarna skarpa, inte suddiga
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)
                    .padding(12)
                    .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemFill), lineWidth: 1)
                    )

                Text("Skanna med din telefon för att spara anekdoten")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                // Dela-knappar — öppnar iOS inbyggda share-sheet
                VStack(spacing: 10) {
                    ShareLink(item: shareText) {
                        Label("Skicka via SMS", systemImage: "message.fill")
                            .font(.system(size: 15, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(Color("AccentBlue"), in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                    }

                    ShareLink(item: shareText, subject: Text("Puck-Mikrofon anekdot")) {
                        Label("Skicka via e-post", systemImage: "envelope.fill")
                            .font(.system(size: 15, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemFill), lineWidth: 1)
                            )
                            .foregroundStyle(.primary)
                    }
                }
                .padding(.horizontal, 20)

                Button("Avbryt") { dismiss() }
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // Genererar en QR-kod med iOS inbyggda CIFilter
    // Skalar upp 6x så koden blir tydlig och enkel att skanna
    private func generateQR(from string: String) -> UIImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        if let output = filter.outputImage {
            let scaled = output.transformed(by: CGAffineTransform(scaleX: 6, y: 6))
            if let cgImage = context.createCGImage(scaled, from: scaled.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        return UIImage(systemName: "qrcode") ?? UIImage()
    }
}

#Preview {
    ShareAnecdoteView(anecdote: Anecdote.samples[0])
}
