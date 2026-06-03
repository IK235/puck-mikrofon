//
//  Buttonstyles.swift
//  PuckMikrofon
//
//  Created by ikbal erdal on 2026-04-04.
//

import SwiftUI

// Blå fylld knapp — används för primära actions som "Spara" och "Fortsätt"
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(Color("AccentBlue"), in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(.white)
            // Trycks ihop lite när man trycker — ger fysisk känsla
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// Vit knapp med ram — används för sekundära actions som "Avbryt" och "Till start"
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .medium))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(.primary)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemFill), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
