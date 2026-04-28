//
//  DiscoveryHeroView.swift
//  Discovery
//
//  Fase 3: hero con contador animado + barra de búsqueda integrada
//

import SwiftUI
import Theme

struct DiscoveryHeroView: View {
    let courseCount: Int
    let onSearchTap: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            // Gradiente de fondo
            LinearGradient(
                colors: [
                    Theme.Colors.brandGreenDark,
                    Theme.Colors.brandGreen,
                    Theme.Colors.brandGreenLight
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Anillos decorativos animados (consistencia con Dashboard/Profile)
            DecorativeRings()

            // Textos + search bar
            VStack(alignment: .leading, spacing: 12) {
                Spacer()

                // Título: "1 359 cursos te esperan"
                VStack(alignment: .leading, spacing: 2) {
                    if courseCount > 0 {
                        HStack(alignment: .lastTextBaseline, spacing: 0) {
                            Text("\(courseCount) cursos ")
                                .font(Theme.Fonts.notoSans(26, weight: .bold))
                                .foregroundColor(.white)
                            Text("te esperan")
                                .font(Theme.Fonts.notoSans(22, weight: .semibold, italic: true))
                                .foregroundColor(Theme.Colors.brandGreenLight.opacity(0.9))
                        }
                    } else {
                        Text("Descubre")
                            .font(Theme.Fonts.notoSans(26, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Text("Encuentra tu próximo aprendizaje")
                        .font(Theme.Fonts.notoSans(12))
                        .foregroundColor(Color.white.opacity(0.65))
                }

                // Barra búsqueda
                Button(action: onSearchTap) {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Theme.Colors.brandGreen)
                        Text("Buscar cursos...")
                            .font(Theme.Fonts.notoSans(13))
                            .foregroundColor(Theme.Colors.brandCardSecondary)
                        Spacer()
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.Colors.brandCardSecondary)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 44)
                    .background(Color.white)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .clipped()
    }
}

#Preview {
    DiscoveryHeroView(courseCount: 1359, onSearchTap: {})
        .frame(height: 240)
}
