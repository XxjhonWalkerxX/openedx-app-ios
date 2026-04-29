import SwiftUI
import Core
import Theme

// MARK: - VerticalRenderer

/// Renderizador por tipo de bloque del vertical.
/// F4: placeholder informativo con estructura del vertical.
/// F5: renderers reales — WKWebView (html/problem), AVPlayer (video), discussion embed.
struct VerticalRenderer: View {

    let vertical: CourseVertical
    let courseID: String
    let onScrollChange: (CGFloat) -> Void

    var body: some View {
        GeometryReader { _ in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    contentHeader
                    contentPlaceholder
                    if !vertical.childs.isEmpty {
                        childBlocksList
                    }
                    Spacer(minLength: 120)
                }
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: VerticalScrollOffsetKey.self,
                            value: geo.frame(in: .named("readerScroll")).minY
                        )
                    }
                )
            }
            .coordinateSpace(name: "readerScroll")
            .onPreferenceChange(VerticalScrollOffsetKey.self) { onScrollChange($0) }
        }
        .background(Theme.Colors.brandCream)
    }

    // MARK: - Header

    private var contentHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                primaryTypeIcon
                    .frame(width: 18, height: 18)
                    .foregroundStyle(Theme.Colors.guindaColor)
                Text(blockTypeLabel.uppercased())
                    .font(Theme.Fonts.notoSans(10, weight: .semibold))
                    .foregroundStyle(Theme.Colors.guindaColor)
                    .kerning(1.0)
            }
            Text(vertical.displayName)
                .font(Theme.Fonts.notoSans(20, weight: .semibold))
                .foregroundStyle(Theme.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 20)
    }

    // MARK: - Placeholder (F5 will replace this)

    private var contentPlaceholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Theme.Colors.surfaceWhite)
            .frame(minHeight: 220)
            .overlay {
                VStack(spacing: 14) {
                    primaryTypeIcon
                        .frame(width: 36, height: 36)
                        .foregroundStyle(Theme.Colors.textSecondary.opacity(0.4))
                    Text("Contenido disponible próximamente")
                        .font(Theme.Fonts.notoSans(13, weight: .regular))
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
            }
            .padding(.horizontal, 24)
    }

    // MARK: - Child Blocks

    private var childBlocksList: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("BLOQUES")
                .font(Theme.Fonts.notoSans(10, weight: .semibold))
                .foregroundStyle(Theme.Colors.textSecondary)
                .kerning(1.0)
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 10)

            VStack(spacing: 0) {
                ForEach(vertical.childs) { block in
                    HStack(spacing: 12) {
                        block.type.image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .foregroundStyle(Theme.Colors.textSecondary)
                        Text(block.displayName)
                            .font(Theme.Fonts.notoSans(13, weight: .regular))
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .lineLimit(2)
                        Spacer()
                        if block.completion >= 1.0 {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Theme.Colors.brandGreen)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Theme.Colors.surfaceWhite)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Helpers

    private var primaryBlockType: BlockType {
        vertical.childs.first?.type ?? vertical.type
    }

    private var primaryTypeIcon: some View {
        primaryBlockType.image
            .resizable()
            .scaledToFit()
    }

    private var blockTypeLabel: String {
        switch primaryBlockType {
        case .video: return "Video"
        case .html: return "Lectura"
        case .problem: return "Ejercicio"
        case .discussion: return "Discusión"
        case .survey: return "Encuesta"
        case .openassessment: return "Evaluación"
        default: return "Contenido"
        }
    }
}

// MARK: - Preference Key

private struct VerticalScrollOffsetKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
