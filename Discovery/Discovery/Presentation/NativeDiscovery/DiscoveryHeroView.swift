//
//  DiscoveryHeroView.swift
//  Discovery
//
//  Contenido del hero (gradiente + círculos + textos).
//  La franja guinda y el botón settings se manejan como overlays fijos en DiscoveryView.
//

import SwiftUI
import Theme

struct DiscoveryHeroView: View {

    var body: some View {
        ZStack(alignment: .top) {
            // 1. Gradiente de fondo
            LinearGradient(
                colors: [
                    Theme.Colors.brandGreenDark,
                    Theme.Colors.brandGreen,
                    Theme.Colors.brandGreenLight,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // 2. Círculos decorativos semitransparentes
            Circle()
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 32)
                .frame(width: 200, height: 200)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .offset(x: -40, y: -40)

            Circle()
                .strokeBorder(Color.white.opacity(0.05), lineWidth: 20)
                .frame(width: 110, height: 110)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .offset(x: 20, y: 20)

            // 3. Textos — alineados abajo a la izquierda
            VStack(alignment: .leading, spacing: 4) {
                Spacer()
                Text("Explorar")
                    .font(Theme.Fonts.ttRoundsCompressedMedium(30))
                    .foregroundColor(.white)
                    .kerning(-0.3)
                Text("Encuentra tu próximo aprendizaje")
                    .font(Theme.Fonts.ttRoundsCompressedThinItalic(13))
                    .foregroundColor(Color.white.opacity(0.65))
                    .kerning(0.2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .clipped()
    }
}

#Preview {
    DiscoveryHeroView()
        .frame(height: 220)
}
