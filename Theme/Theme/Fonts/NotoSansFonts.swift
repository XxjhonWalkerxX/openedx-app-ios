//
//  NotoSansFonts.swift
//  Theme
//
//  Noto Sans — tipografía principal @prende.mx post-login.
//  Archivos TTF requeridos en Theme/Theme/Fonts/:
//    NotoSans-Regular.ttf, NotoSans-Medium.ttf, NotoSans-SemiBold.ttf, NotoSans-Bold.ttf,
//    NotoSans-Italic.ttf, NotoSans-MediumItalic.ttf, NotoSans-SemiBoldItalic.ttf, NotoSans-BoldItalic.ttf
//  Descarga: https://fonts.google.com/noto/specimen/Noto+Sans
//

import SwiftUI

public extension Theme.Fonts {

    // MARK: - Primitiva

    /// Fuente Noto Sans con peso e italic configurables.
    /// Si los TTF no están registrados, SwiftUI usa system font como fallback — no crashea.
    static func notoSans(_ size: CGFloat, weight: Font.Weight = .regular, italic: Bool = false) -> Font {
        let name: String
        switch weight {
        case .bold:
            name = italic ? "NotoSans-BoldItalic" : "NotoSans-Bold"
        case .semibold:
            name = italic ? "NotoSans-SemiBoldItalic" : "NotoSans-SemiBold"
        case .medium:
            name = italic ? "NotoSans-MediumItalic" : "NotoSans-Medium"
        default:
            name = italic ? "NotoSans-Italic" : "NotoSans-Regular"
        }
        return Font.custom(name, size: size, relativeTo: .body)
    }

    // MARK: - Roles semánticos (reemplazan Instrument Serif + Geist del mockup)

    /// 34pt bold — headlines de pantalla (saludo hero, featured card, encabezado Discovery)
    static func display(_ size: CGFloat) -> Font { notoSans(size, weight: .bold) }

    /// Semibold — títulos de sección, cards, tabs
    static func title(_ size: CGFloat) -> Font { notoSans(size, weight: .semibold) }

    /// Regular — cuerpo, descripciones, filas de lista
    static func body(_ size: CGFloat) -> Font { notoSans(size, weight: .regular) }

    /// Medium — caption, labels uppercase, metadata
    static func caption(_ size: CGFloat) -> Font { notoSans(size, weight: .medium) }
}
