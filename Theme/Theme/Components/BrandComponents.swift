//
//  BrandComponents.swift
//  Theme
//
//  Design System @prende.mx — componentes base reutilizables.
//
//  Pilares:
//    1. ElasticTextBlock  — layout elástico (texto dinámico)
//    2. BrandImageStyle   — estandarización de imagen (aspectRatio + crop + radius)
//    3. BrandHeader       — header consistente (60pt portrait, absorbe Safe Area)
//    4. HeroImageCover    — overlay WCAG para imágenes con texto
//

import SwiftUI

// MARK: - 1. ElasticTextBlock ────────────────────────────────────────────────

/// Bloque de texto con altura fija para alineación en grids/lists.
/// Garantiza que `org` (1 línea), `title` (2 líneas) y `meta` (1 línea) nunca
/// empujen el layout: título corto no colapsa la zona, largo trunca con `…`.
public struct ElasticTextBlock: View {

    public let org: String
    public let title: String
    public let meta: String?
    public let height: CGFloat
    public let orgFont: Font
    public let titleFont: Font
    public let metaFont: Font

    public init(
        org: String,
        title: String,
        meta: String? = nil,
        height: CGFloat = Theme.Sizes.CardMetrics.textZoneHeight,
        orgFont: Font = Theme.Fonts.labelSmall,
        titleFont: Font = Theme.Fonts.titleMedium,
        metaFont: Font = Theme.Fonts.labelMedium
    ) {
        self.org = org
        self.title = title
        self.meta = meta
        self.height = height
        self.orgFont = orgFont
        self.titleFont = titleFont
        self.metaFont = metaFont
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(org)
                .font(orgFont)
                .foregroundColor(Theme.Colors.brandCardSecondary)
                .kerning(0.3)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 4)

            Text(title)
                .font(titleFont)
                .foregroundColor(Theme.Colors.brandCardPrimary)
                .kerning(-0.2)
                .lineLimit(2)
                .truncationMode(.tail)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 4)

            if let meta {
                Text(meta)
                    .font(metaFont)
                    .foregroundColor(Theme.Colors.brandCardSecondary)
                    .lineLimit(1)
            }
        }
        .frame(height: height, alignment: .leading)
    }
}

// MARK: - 2. BrandImageStyle + modifier ──────────────────────────────────────

/// Estilo canónico para imágenes del sistema. Cada caso define aspectRatio,
/// método de crop y cornerRadius. Aplicable sobre cualquier fuente
/// (Image, KFImage, AsyncImage, Color placeholder).
public enum BrandImageStyle {
    /// Hero 16:9 con top-rounded. Banners grandes (PrimaryCard, CourseHeader).
    case hero
    /// Thumbnail 1:1, cornerRadius completo. Grid AllCourses, related courses.
    case cardThumb
    /// Course header 16:10, top-rounded grande. Entrada a curso.
    case courseHeader
    /// Avatar circular 1:1. Logos de institución.
    case avatar

    public var aspectRatio: CGFloat {
        switch self {
        case .hero:         return 16.0 / 9.0
        case .cardThumb:    return 1.0
        case .courseHeader: return 16.0 / 10.0
        case .avatar:       return 1.0
        }
    }
}

public extension View {

    /// Aplica tratamiento visual canónico de marca sobre la imagen.
    /// La vista source debería ser resizable y usar aspectRatio(.fill).
    ///
    /// Uso:
    ///     KFImage(url)
    ///         .resizable()
    ///         .aspectRatio(contentMode: .fill)
    ///         .brandImageStyle(.hero)
    @ViewBuilder
    func brandImageStyle(_ style: BrandImageStyle) -> some View {
        switch style {
        case .hero:
            self
                .aspectRatio(style.aspectRatio, contentMode: .fill)
                .frame(maxWidth: .infinity)
                .clipped()
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: Theme.Sizes.radiusHero,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: Theme.Sizes.radiusHero
                    )
                )
        case .cardThumb:
            self
                .aspectRatio(style.aspectRatio, contentMode: .fill)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: Theme.Sizes.radiusCard))
        case .courseHeader:
            self
                .aspectRatio(style.aspectRatio, contentMode: .fill)
                .frame(maxWidth: .infinity)
                .clipped()
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: Theme.Sizes.radiusHero,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: Theme.Sizes.radiusHero
                    )
                )
        case .avatar:
            self
                .aspectRatio(style.aspectRatio, contentMode: .fill)
                .clipped()
                .clipShape(Circle())
        }
    }
}

// MARK: - 3. BrandHeader ─────────────────────────────────────────────────────

/// Header estándar del sistema: 60pt top en portrait, hero gradient, bottom
/// radius 32pt, absorbe Safe Area con `.ignoresSafeArea(edges: .top)`.
///
/// Elimina las variaciones 52/60/+10 entre pantallas de Profile.
/// Detección interna de orientación vía `verticalSizeClass`.
public struct BrandHeader<Content: View>: View {

    public let title: String
    public let onBack: (() -> Void)?
    @ViewBuilder public let content: () -> Content

    @Environment(\.verticalSizeClass) private var verticalSizeClass

    public init(
        title: String,
        onBack: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content = { EmptyView() }
    ) {
        self.title = title
        self.onBack = onBack
        self.content = content
    }

    private var isLandscape: Bool { verticalSizeClass == .compact }

    private var topPadding: CGFloat {
        isLandscape ? Theme.Sizes.headerLandscapeTopPadding : Theme.Sizes.headerTopPadding
    }
    private var bottomPadding: CGFloat {
        isLandscape ? Theme.Sizes.headerLandscapeBottomPadding : Theme.Sizes.headerBottomPadding
    }
    private var minHeight: CGFloat {
        isLandscape ? Theme.Sizes.headerLandscapeHeight : Theme.Sizes.headerPortraitMinHeight
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                if let onBack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: Theme.Sizes.backIconSize, weight: .semibold))
                            .foregroundColor(Theme.Colors.textOnHeader)
                            .frame(
                                width: Theme.Sizes.headerButtonSize,
                                height: Theme.Sizes.headerButtonSize
                            )
                    }
                    .accessibilityLabel("Atrás")
                }

                Text(title)
                    .font(Theme.Fonts.titleLarge)
                    .foregroundColor(Theme.Colors.textOnHeader)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            content()
        }
        .padding(.horizontal, Theme.Sizes.horizontalPadding)
        .padding(.top, topPadding)
        .padding(.bottom, bottomPadding)
        .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .leading)
        .background(Theme.Gradients.heroGradient)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: Theme.Sizes.radiusSheet,
                bottomTrailingRadius: Theme.Sizes.radiusSheet,
                topTrailingRadius: 0
            )
        )
        .ignoresSafeArea(edges: .top)
    }
}

// MARK: - 4. HeroImageCover ──────────────────────────────────────────────────

/// Contenedor para imagen hero con overlay WCAG-compliant.
/// Aplica `Theme.Gradients.heroImageOverlay` (3 stops, U-invertida) sobre
/// imagen + contenido superpuesto alineado al bottom-leading.
///
/// Uso:
///     HeroImageCover(aspectRatio: 16.0/9.0) {
///         KFImage(url).resizable().aspectRatio(contentMode: .fill)
///     } overlay: {
///         VStack(alignment: .leading) {
///             Text(org)
///             Text(title)
///         }
///     }
public struct HeroImageCover<Image: View, Overlay: View>: View {

    public let aspectRatio: CGFloat
    @ViewBuilder public let image: () -> Image
    @ViewBuilder public let overlay: () -> Overlay

    public init(
        aspectRatio: CGFloat = 16.0 / 9.0,
        @ViewBuilder image: @escaping () -> Image,
        @ViewBuilder overlay: @escaping () -> Overlay
    ) {
        self.aspectRatio = aspectRatio
        self.image = image
        self.overlay = overlay
    }

    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = w / aspectRatio
            ZStack(alignment: .bottomLeading) {
                image()
                    .frame(width: w, height: h)
                    .clipped()

                Theme.Gradients.heroImageOverlay
                    .frame(width: w, height: h)

                overlay()
                    .padding(Theme.Sizes.horizontalPadding)
            }
            .frame(width: w, height: h)
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
    }
}

// MARK: - Previews ───────────────────────────────────────────────────────────

#if DEBUG
struct BrandComponents_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ElasticTextBlock(
                org: "UNAM",
                title: "Introducción a la Programación con Python",
                meta: "A tu ritmo · Ends Nov 29, 2026"
            )
            .frame(width: 220)
            .background(Color.white)

            ElasticTextBlock(
                org: "Instituto Politécnico Nacional — Escuela Superior de Ingeniería",
                title: "Desarrollo de videojuegos 3D avanzado con motor Unity y técnicas profesionales",
                meta: "Con fechas · Starts Jan 15, 2027"
            )
            .frame(width: 220)
            .background(Color.white)
        }
        .padding()
        .background(Theme.Colors.brandCream)
        .loadFonts()
        .previewDisplayName("ElasticTextBlock")
    }
}
#endif
