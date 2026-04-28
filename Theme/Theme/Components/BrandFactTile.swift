//
//  BrandFactTile.swift
//  Theme
//
//  Tile 1/2 ancho con icono SF Symbol + label + value.
//  Uso: grid 2x2 en OverviewTab (Duración / Lecciones / Constancia / Idioma).
//

import SwiftUI

public struct BrandFactTile: View {

    public let systemImage: String
    public let label: String
    public let value: String

    public init(systemImage: String, label: String, value: String) {
        self.systemImage = systemImage
        self.label = label
        self.value = value
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(Theme.Colors.brandGreen)

            Text(value)
                .font(Theme.Fonts.notoSans(15, weight: .semibold))
                .foregroundStyle(Theme.Colors.brandCardPrimary)
                .lineLimit(1)

            Text(label)
                .font(Theme.Fonts.notoSans(11, weight: .medium))
                .foregroundStyle(Theme.Colors.brandCardSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Theme.Colors.surfaceWhite)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Sizes.radiusCard))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Sizes.radiusCard)
                .strokeBorder(Theme.Colors.cardStrokeSubtle, lineWidth: 1)
        )
        .shadow(color: Theme.Colors.cardShadowSubtle, radius: 4, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Preview

#if DEBUG
struct BrandFactTile_Previews: PreviewProvider {
    static var previews: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            BrandFactTile(systemImage: "clock", label: "Duración", value: "8 horas")
            BrandFactTile(systemImage: "list.number", label: "Lecciones", value: "24")
            BrandFactTile(systemImage: "rosette", label: "Constancia", value: "Sí")
            BrandFactTile(systemImage: "globe", label: "Idioma", value: "Español")
        }
        .padding()
        .background(Theme.Colors.brandCream)
        .loadFonts()
        .previewDisplayName("BrandFactTile — grid 2x2")
    }
}
#endif
