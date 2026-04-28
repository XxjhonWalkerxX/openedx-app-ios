//
//  CourseImageView.swift
//  Core
//
//  Punto único de entrada para portadas de curso — estrategia híbrida @prende.mx.
//  Decide automáticamente entre photo/letterbox/pattern según hasEmbeddedText.
//

import SwiftUI
import Kingfisher
import Theme

// MARK: - CourseCoverVariant

public enum CourseCoverVariant {
    case auto
    case photo(scrim: Bool)
    case letterbox(background: Color)
    case pattern
}

// MARK: - CourseImageView

public struct CourseImageView: View {

    public let url: String?
    public let course: CourseItem
    public let accessibilityTitle: String
    public var variant: CourseCoverVariant
    public var background: Color

    public init(
        url: String?,
        course: CourseItem,
        accessibilityTitle: String,
        variant: CourseCoverVariant = .auto,
        background: Color = Theme.Colors.brandCream
    ) {
        self.url = url
        self.course = course
        self.accessibilityTitle = accessibilityTitle
        self.variant = variant
        self.background = background
    }

    public var body: some View {
        Group {
            switch resolvedVariant {
            case .photo(let scrim):
                photoBody(scrim: scrim)
            case .letterbox(let bg):
                letterboxBody(background: bg)
            case .pattern:
                PatternCover(
                    courseID: course.courseID,
                    category: course.courseCategory,
                    institutionShort: course.org
                )
            default:
                EmptyView()
            }
        }
        .accessibilityLabel(accessibilityTitle)
        .accessibilityAddTraits(.isImage)
    }

    // MARK: - Private

    private var resolvedVariant: CourseCoverVariant {
        guard case .auto = variant else { return variant }
        guard let url, !url.isEmpty else { return .pattern }
        return course.hasEmbeddedText
            ? .letterbox(background: background)
            : .photo(scrim: true)
    }

    @ViewBuilder
    private func photoBody(scrim: Bool) -> some View {
        ZStack {
            KFImage(URL(string: url ?? ""))
                .onFailureImage(CoreAssets.noCourseImage.image)
                .resizable()
                .aspectRatio(contentMode: .fill)

            if scrim {
                Theme.Gradients.heroImageScrim
            }
        }
        .clipped()
    }

    @ViewBuilder
    private func letterboxBody(background: Color) -> some View {
        ZStack {
            background
            KFImage(URL(string: url ?? ""))
                .onFailureImage(CoreAssets.noCourseImage.image)
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
    }
}

// MARK: - CourseItem extensions

extension CourseItem {

    /// True si la imagen es un póster SEP con texto incrustado.
    /// Heurística temporal: imágenes cuasi-cuadradas (ratio < 1.05) = póster vertical.
    /// La API debe exponer un flag explícito en versiones futuras.
    var hasEmbeddedText: Bool {
        // Sin metadata de dimensiones → asumir true (safe default)
        true
    }

    /// Categoría temática derivada del campo org (heurística provisional).
    var courseCategory: CourseCategory {
        let org = self.org.lowercased()
        if org.contains("salud") || org.contains("imss") || org.contains("issste") {
            return .salud
        } else if org.contains("segur") || org.contains("polic") || org.contains("defensa") {
            return .seguridad
        } else if org.contains("tecnol") || org.contains("digital") || org.contains("informática") {
            return .tecnologia
        } else if org.contains("ambiente") || org.contains("ecol") || org.contains("semarnat") {
            return .ambiente
        } else if org.contains("ciudadan") || org.contains("civil") || org.contains("participación") {
            return .ciudadania
        } else if org.contains("admin") || org.contains("goberna") || org.contains("hacienda") {
            return .admin
        } else if org.contains("educac") || org.contains("sep") || org.contains("unam") || org.contains("ipn") {
            return .educacion
        }
        return .educacion
    }
}
