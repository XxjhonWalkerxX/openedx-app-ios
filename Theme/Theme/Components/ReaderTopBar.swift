import SwiftUI

// MARK: - ReaderTopBar

/// Barra superior del Content Reader.
/// Material blur, autohide según scroll, título + subtítulo + progreso + close.
public struct ReaderTopBar: View {

    public let title: String
    public let subtitle: String?
    public let currentIndex: Int
    public let totalCount: Int
    public let segments: [ReaderProgressRail.SegmentState]
    public let isVisible: Bool
    public let onClose: () -> Void
    public let onSegmentTap: (Int) -> Void
    public let trailingMenu: (() -> Void)?

    public init(
        title: String,
        subtitle: String? = nil,
        currentIndex: Int,
        totalCount: Int,
        segments: [ReaderProgressRail.SegmentState],
        isVisible: Bool = true,
        onClose: @escaping () -> Void,
        onSegmentTap: @escaping (Int) -> Void,
        trailingMenu: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.currentIndex = currentIndex
        self.totalCount = totalCount
        self.segments = segments
        self.isVisible = isVisible
        self.onClose = onClose
        self.onSegmentTap = onSegmentTap
        self.trailingMenu = trailingMenu
    }

    public var body: some View {
        VStack(spacing: 0) {
            mainRow
            if !segments.isEmpty {
                ReaderProgressRail(segments: segments, onTap: onSegmentTap)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
            }
        }
        .background(.regularMaterial)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : -8)
        .animation(.easeInOut(duration: 0.22), value: isVisible)
    }

    private var mainRow: some View {
        HStack(alignment: .center, spacing: 12) {
            closeButton
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(Theme.Fonts.notoSans(14, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .lineLimit(1)
                if let subtitle {
                    Text(subtitle)
                        .font(Theme.Fonts.notoSans(11, weight: .regular))
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .lineLimit(1)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(subtitle.map { "\(title), \($0)" } ?? title)
            Spacer()
            progressLabel
            if let trailingMenu {
                trailingButton(action: trailingMenu)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, segments.isEmpty ? 12 : 8)
    }

    private var closeButton: some View {
        Button(action: onClose) {
            Image(systemName: "xmark")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.Colors.textPrimary)
                .frame(width: 32, height: 32)
                .background(Theme.Colors.brandCreamStrong.opacity(0.6))
                .clipShape(Circle())
        }
        .accessibilityLabel("Cerrar lector")
    }

    private var progressLabel: some View {
        Text("\(currentIndex + 1)/\(totalCount)")
            .font(Theme.Fonts.notoSans(12, weight: .medium))
            .foregroundStyle(Theme.Colors.textSecondary)
            .monospacedDigit()
            .accessibilityLabel("Sección \(currentIndex + 1) de \(totalCount)")
    }

    private func trailingButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "ellipsis")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.Colors.textPrimary)
                .frame(width: 32, height: 32)
        }
        .accessibilityLabel("Más opciones")
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    ZStack(alignment: .top) {
        Theme.Colors.brandCream.ignoresSafeArea()
        VStack {
            ReaderTopBar(
                title: "Cap I · Disposiciones Generales",
                subtitle: "Unidad 1 · Marco Legal",
                currentIndex: 2,
                totalCount: 8,
                segments: [.completed, .completed, .current, .pending, .pending, .pending, .pending, .pending],
                isVisible: true,
                onClose: {},
                onSegmentTap: { _ in },
                trailingMenu: {}
            )
            Spacer()
        }
    }
    .loadFonts()
}
#endif
