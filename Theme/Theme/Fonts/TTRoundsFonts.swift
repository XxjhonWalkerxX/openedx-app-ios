//
//  TTRoundsFonts.swift
//  Theme
//
//  TT Rounds Neue Trial Variable — variantes para @prende.mx
//  PostScript name: TTRoundsNeueTrialVariable
//
//  Ejes de variación (tag → valor 32-bit big-endian):
//    wdth  2003072104   50 = compressed, 100 = normal
//    wght  2003265652   100–900
//    slnt  1936486004   0 = upright, 11 = italic
//

import CoreText
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Axis identifiers

private enum TTRoundsAxis {
    static let wdth: Int = 2003072104
    static let wght: Int = 2003265652
    static let slnt: Int = 1936486004
}

private let kTTRoundsPS = "TTRoundsNeueTrialVariable"

// MARK: - Public font factories

public extension Theme.Fonts {

    /// Compressed Medium — wdth=50, wght=500
    /// Uso: títulos de sección, saludo "¡Hola!" en el hero
    static func ttRoundsCompressedMedium(_ size: CGFloat) -> Font {
        ttRoundsVariant(wdth: 50, wght: 500, slnt: 0, size: size)
    }

    /// Compressed Thin Italic — wdth=50, wght=100, slnt=11
    /// Uso: eyebrow "Bienvenido de vuelta", estado "Por iniciar" en tarjetas
    static func ttRoundsCompressedThinItalic(_ size: CGFloat) -> Font {
        ttRoundsVariant(wdth: 50, wght: 100, slnt: 11, size: size)
    }

    /// Regular — wdth=100, peso configurable (400 = regular, 500 = medium, 600 = semi)
    /// Uso: subtítulo hero, pills, links, fechas
    static func ttRoundsBody(_ size: CGFloat, weight: Double = 400) -> Font {
        ttRoundsVariant(wdth: 100, wght: weight, slnt: 0, size: size)
    }

    /// Medium — wdth=100, wght=500
    /// Uso: labels de settings rows, títulos pequeños
    static func ttRoundsMedium(_ size: CGFloat) -> Font {
        ttRoundsBody(size, weight: 500)
    }

    /// Semibold — wdth=100, wght=600
    /// Uso: back buttons, chevrons, CTAs compactos (reemplaza .font(.system(size:, weight: .semibold)))
    static func ttRoundsSemibold(_ size: CGFloat) -> Font {
        ttRoundsBody(size, weight: 600)
    }

    // MARK: - Core

    private static func ttRoundsVariant(wdth: Double, wght: Double, slnt: Double, size: CGFloat) -> Font {
        let variation: [NSNumber: NSNumber] = [
            NSNumber(value: TTRoundsAxis.wdth): NSNumber(value: wdth),
            NSNumber(value: TTRoundsAxis.wght): NSNumber(value: wght),
            NSNumber(value: TTRoundsAxis.slnt): NSNumber(value: slnt),
        ]
        let descriptor = UIFontDescriptor(fontAttributes: [
            .name: kTTRoundsPS,
            UIFontDescriptor.AttributeName(rawValue: kCTFontVariationAttribute as String): variation,
        ])
        return Font(UIFont(descriptor: descriptor, size: size))
    }
}
