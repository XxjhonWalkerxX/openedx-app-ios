//
//  PatternCover.swift
//  Theme
//
//  Portada generativa Canvas + SF Symbol para cursos sin imagen o con imagen póster SEP.
//  Reemplaza la versión SVG del mockup web — vectorial puro, zero dependencias externas.
//

import SwiftUI

// MARK: - CourseCategory

/// Categoría temática de curso — determina SF Symbol, tinte y motivo Canvas.
public enum CourseCategory: String, CaseIterable, Sendable {
    case seguridad
    case salud
    case admin
    case educacion
    case tecnologia
    case ciudadania
    case ambiente
    case otro

    public var sfSymbol: String {
        switch self {
        case .seguridad:   return "shield.checkered"
        case .salud:       return "cross.case.fill"
        case .admin:       return "building.columns.fill"
        case .educacion:   return "graduationcap.fill"
        case .tecnologia:  return "cpu"
        case .ciudadania:  return "person.3.fill"
        case .ambiente:    return "leaf.fill"
        case .otro:        return "book.fill"
        }
    }

    /// Fondo tintado derivado de la paleta institucional
    public var tintBackground: Color {
        switch self {
        case .seguridad:  return Theme.Colors.guindaColor.opacity(0.12)
        case .salud:      return Theme.Colors.brandGreen.opacity(0.10)
        case .admin:      return Theme.Colors.guindaDeep.opacity(0.10)
        case .educacion:  return Theme.Colors.brandGreenDark.opacity(0.10)
        case .tecnologia: return Theme.Colors.brandGreen.opacity(0.08)
        case .ciudadania: return Theme.Colors.guindaColor.opacity(0.08)
        case .ambiente:   return Theme.Colors.brandGreenLight.opacity(0.10)
        case .otro:       return Theme.Colors.brandCreamStrong
        }
    }

    /// Color del glifo SF Symbol decorativo
    public var glyphColor: Color {
        switch self {
        case .seguridad, .admin, .ciudadania: return Theme.Colors.guindaColor
        default:                               return Theme.Colors.brandGreen
        }
    }

    /// Color del texto institucional abreviado
    public var inkColor: Color { Theme.Colors.brandCardPrimary }

    /// Motivo Canvas determinístico: 0=grid, 1=arcos, 2=anillos, 3=rayas, 4=puntos
    public var canvasMotif: Int {
        switch self {
        case .seguridad:   return 0
        case .salud:       return 1
        case .admin:       return 2
        case .educacion:   return 3
        case .tecnologia:  return 4
        case .ciudadania:  return 0
        case .ambiente:    return 1
        case .otro:        return 2
        }
    }
}

// MARK: - PatternCover

/// Portada generativa para cursos. Usa Canvas nativo + SF Symbols.
/// No requiere imágenes de red. Completamente vectorial.
public struct PatternCover: View {

    public let courseID: String
    public let category: CourseCategory
    public let institutionShort: String?

    public init(
        courseID: String,
        category: CourseCategory,
        institutionShort: String? = nil
    ) {
        self.courseID = courseID
        self.category = category
        self.institutionShort = institutionShort
    }

    // Hash determinístico para variar el motivo dentro de la misma categoría
    private var seed: Double {
        Double(courseID.unicodeScalars.reduce(0) { ($0 &* 31) &+ Int($1.value) } & 0xFFFF) / Double(0xFFFF)
    }

    public var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Fondo sólido
            category.tintBackground

            // Motivo Canvas
            Canvas { ctx, size in
                drawMotif(ctx: ctx, size: size)
            }
            .opacity(0.6)

            // Glifo SF Symbol decorativo
            Image(systemName: category.sfSymbol)
                .font(.system(size: 120, weight: .ultraLight))
                .foregroundStyle(category.glyphColor.opacity(0.18))
                .offset(x: 16, y: 16)
                .accessibilityHidden(true)
        }
        .overlay(alignment: .topLeading) {
            if let inst = institutionShort {
                Text(inst.uppercased())
                    .font(Theme.Fonts.caption(9))
                    .tracking(0.8)
                    .foregroundStyle(category.inkColor.opacity(0.55))
                    .padding(.top, 10)
                    .padding(.leading, 12)
                    .accessibilityHidden(true)
            }
        }
        .clipped()
    }

    private func drawMotif(ctx: GraphicsContext, size: CGSize) {
        let color = category.glyphColor.opacity(0.06)
        switch category.canvasMotif {
        case 0: // grid
            let step: CGFloat = 24
            var x: CGFloat = 0
            while x <= size.width {
                ctx.stroke(Path { p in p.move(to: .init(x: x, y: 0)); p.addLine(to: .init(x: x, y: size.height)) },
                           with: .color(color), lineWidth: 1)
                x += step
            }
            var y: CGFloat = 0
            while y <= size.height {
                ctx.stroke(Path { p in p.move(to: .init(x: 0, y: y)); p.addLine(to: .init(x: size.width, y: y)) },
                           with: .color(color), lineWidth: 1)
                y += step
            }
        case 1: // arcos
            let cx = size.width * (0.5 + seed * 0.3)
            let cy = size.height * (0.5 + seed * 0.3)
            for i in 1...6 {
                let r = CGFloat(i) * 28
                let rect = CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)
                ctx.stroke(Path(ellipseIn: rect), with: .color(color), lineWidth: 1)
            }
        case 2: // anillos — solapados
            let offsets: [(CGFloat, CGFloat)] = [(0.3, 0.3), (0.7, 0.4), (0.5, 0.7)]
            for (fx, fy) in offsets {
                let cx = size.width * fx
                let cy = size.height * fy
                for i in 1...4 {
                    let r = CGFloat(i) * 20
                    let rect = CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)
                    ctx.stroke(Path(ellipseIn: rect), with: .color(color), lineWidth: 0.8)
                }
            }
        case 3: // rayas diagonales
            let gap: CGFloat = 20
            var offset: CGFloat = -size.height
            while offset < size.width {
                ctx.stroke(
                    Path { p in
                        p.move(to: .init(x: offset, y: 0))
                        p.addLine(to: .init(x: offset + size.height, y: size.height))
                    },
                    with: .color(color), lineWidth: 1
                )
                offset += gap
            }
        default: // puntos
            let step: CGFloat = 20
            var px: CGFloat = step / 2
            while px < size.width {
                var py: CGFloat = step / 2
                while py < size.height {
                    let dot = Path(ellipseIn: CGRect(x: px - 1.5, y: py - 1.5, width: 3, height: 3))
                    ctx.fill(dot, with: .color(color))
                    py += step
                }
                px += step
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct PatternCover_Previews: PreviewProvider {
    static var previews: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            ForEach(CourseCategory.allCases, id: \.rawValue) { cat in
                PatternCover(courseID: cat.rawValue, category: cat, institutionShort: "SEP")
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        Text(cat.rawValue)
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(4),
                        alignment: .bottomLeading
                    )
            }
        }
        .padding()
        .background(Theme.Colors.brandCream)
        .loadFonts()
        .previewDisplayName("PatternCover — 8 categorías")
    }
}
#endif
