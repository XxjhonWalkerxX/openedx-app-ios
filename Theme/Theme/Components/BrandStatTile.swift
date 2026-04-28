//
//  BrandStatTile.swift
//  Theme
//
//  Tile de estadística para el hero de Dashboard y Profile.
//  Compacto: valor display + unidad + label uppercase.
//

import SwiftUI

public struct BrandStatTile: View {

    public let value: String
    public let unit: String?
    public let label: String
    public let background: Color

    public init(
        value: String,
        unit: String? = nil,
        label: String,
        background: Color = Color.white.opacity(0.15)
    ) {
        self.value = value
        self.unit = unit
        self.label = label
        self.background = background
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(Theme.Fonts.notoSans(22, weight: .bold))
                    .foregroundStyle(Color.white)
                if let unit {
                    Text(unit)
                        .font(Theme.Fonts.notoSans(12, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.75))
                }
            }
            Text(label.uppercased())
                .font(Theme.Fonts.notoSans(9, weight: .medium))
                .tracking(0.6)
                .foregroundStyle(Color.white.opacity(0.65))
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Sizes.radiusCard))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value)\(unit ?? ""), \(label)")
    }
}

// MARK: - Preview

#if DEBUG
struct BrandStatTile_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 8) {
            BrandStatTile(value: "7", unit: "días", label: "racha")
            BrandStatTile(value: "3", label: "constancias")
            BrandStatTile(value: "2h", unit: "30m", label: "esta semana")
        }
        .padding()
        .background(Theme.Colors.guindaColor)
        .loadFonts()
        .previewDisplayName("BrandStatTile — hero guinda")
    }
}
#endif
