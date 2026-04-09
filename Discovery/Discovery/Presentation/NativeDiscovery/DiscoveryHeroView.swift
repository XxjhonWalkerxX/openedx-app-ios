//
//  DiscoveryHeroView.swift
//  Discovery
//
//  Hero verde decorativo con gradiente + botón de settings.
//  No contiene elementos de scroll — es una capa fija de 200pt.
//

import SwiftUI
import Theme

private let heroHeight: CGFloat = 200

struct DiscoveryHeroView: View {
    let onSettingsClick: () -> Void

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
            .frame(height: heroHeight)

            // 2. Línea guinda en la parte superior
            Rectangle()
                .fill(Theme.Colors.guindaColor)
                .frame(height: 4)

            // 3. Círculos decorativos semitransparentes
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

            // 4. Textos — alineados abajo a la izquierda
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
            .frame(height: heroHeight)

            // 5. Botón settings — esquina superior derecha
            VStack {
                HStack {
                    Spacer()
                    Button(action: onSettingsClick) {
                        Image(systemName: "person.crop.circle.badge.gear")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.white)
                    }
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.14))
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
                    )
                    .clipShape(Circle())
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                Spacer()
            }
            .frame(height: heroHeight)
        }
        .frame(height: heroHeight)
        .clipped()
    }
}

#Preview {
    DiscoveryHeroView(onSettingsClick: {})
        .previewLayout(.fixed(width: 390, height: 200))
}
