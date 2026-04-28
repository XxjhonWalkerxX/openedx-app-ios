//
//  BrandChip.swift
//  Theme
//
//  Chip institucional con cuatro tonos.
//  Uso: filtros Discovery, estados de lección, metadata de curso.
//

import SwiftUI

// MARK: - BrandChipTone

public enum BrandChipTone {
    case light    // fondo brandGreenSoft, texto brandGreen
    case outline  // borde brandGreen, transparente
    case solid    // fondo brandGreen, texto blanco
    case dark     // fondo guindaColor, texto blanco
}

// MARK: - BrandChip

public struct BrandChip: View {

    public let label: String
    public let tone: BrandChipTone
    public let systemImage: String?

    public init(
        _ label: String,
        tone: BrandChipTone = .light,
        systemImage: String? = nil
    ) {
        self.label = label
        self.tone = tone
        self.systemImage = systemImage
    }

    private var background: Color {
        switch tone {
        case .light:   return Theme.Colors.brandGreenSoft
        case .outline: return .clear
        case .solid:   return Theme.Colors.brandGreen
        case .dark:    return Theme.Colors.guindaColor
        }
    }

    private var foreground: Color {
        switch tone {
        case .light:   return Theme.Colors.brandGreen
        case .outline: return Theme.Colors.brandGreen
        case .solid:   return .white
        case .dark:    return .white
        }
    }

    private var strokeColor: Color {
        tone == .outline ? Theme.Colors.brandGreen : .clear
    }

    public var body: some View {
        HStack(spacing: 4) {
            if let icon = systemImage {
                Image(systemName: icon)
                    .font(Theme.Fonts.notoSans(10, weight: .medium))
            }
            Text(label)
                .font(Theme.Fonts.notoSans(11, weight: .medium))
                .lineLimit(1)
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(background)
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(strokeColor, lineWidth: 1))
    }
}

// MARK: - Preview

#if DEBUG
struct BrandChip_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                BrandChip("Salud", tone: .light, systemImage: "cross.case.fill")
                BrandChip("Seguridad", tone: .outline)
                BrandChip("Tecnología", tone: .solid, systemImage: "cpu")
                BrandChip("SEP", tone: .dark)
            }
        }
        .padding()
        .background(Theme.Colors.brandCream)
        .loadFonts()
        .previewDisplayName("BrandChip — 4 tonos")
    }
}
#endif
