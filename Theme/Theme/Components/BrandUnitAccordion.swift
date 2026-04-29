import SwiftUI

// MARK: - BrandUnitAccordion

/// Card expandible para una unidad de curso (chapter → sequentials → verticals).
/// Uso: instanciar por chapter; pasar rows como @ViewBuilder.
public struct BrandUnitAccordion<RowContent: View>: View {

    public let title: String
    public let subtitle: String?
    public let progress: Double          // 0.0–1.0
    public let completedCount: Int
    public let totalCount: Int
    public let isExpanded: Bool
    public let onToggle: () -> Void
    public let onContinue: (() -> Void)?
    @ViewBuilder public let rowContent: () -> RowContent

    public init(
        title: String,
        subtitle: String? = nil,
        progress: Double,
        completedCount: Int,
        totalCount: Int,
        isExpanded: Bool,
        onToggle: @escaping () -> Void,
        onContinue: (() -> Void)? = nil,
        @ViewBuilder rowContent: @escaping () -> RowContent
    ) {
        self.title = title
        self.subtitle = subtitle
        self.progress = progress
        self.completedCount = completedCount
        self.totalCount = totalCount
        self.isExpanded = isExpanded
        self.onToggle = onToggle
        self.onContinue = onContinue
        self.rowContent = rowContent
    }

    public var body: some View {
        VStack(spacing: 0) {
            headerRow
            if isExpanded {
                Divider()
                    .background(Theme.Colors.brandCreamStrong)
                rowsSection
                if let onContinue {
                    continueButton(action: onContinue)
                }
            }
        }
        .background(Theme.Colors.surfaceWhite)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Sizes.radiusCard))
        .shadow(color: Theme.Colors.shadowColor.opacity(0.08), radius: 6, x: 0, y: 2)
    }

    // MARK: - Header

    private var headerRow: some View {
        Button(action: onToggle) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(Theme.Fonts.notoSans(15, weight: .semibold))
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .multilineTextAlignment(.leading)
                        if let subtitle {
                            Text(subtitle)
                                .font(Theme.Fonts.notoSans(12, weight: .regular))
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                    }
                    Spacer()
                    completionBadge
                    chevron
                }
                progressBar
            }
            .padding(16)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), \(completedCount) de \(totalCount) completados")
        .accessibilityHint(isExpanded ? "Toca para colapsar" : "Toca para expandir")
        .accessibilityAddTraits(.isButton)
    }

    private var completionBadge: some View {
        HStack(spacing: 3) {
            if progress >= 1.0 {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.Colors.brandGreen)
            }
            Text("\(completedCount)/\(totalCount)")
                .font(Theme.Fonts.notoSans(12, weight: .medium))
                .foregroundStyle(progress >= 1.0 ? Theme.Colors.brandGreen : Theme.Colors.textSecondary)
        }
    }

    private var chevron: some View {
        Image(systemName: "chevron.down")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Theme.Colors.textSecondary)
            .rotationEffect(.degrees(isExpanded ? 180 : 0))
            .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Theme.Colors.brandCreamStrong)
                    .frame(height: 5)
                Capsule()
                    .fill(progress >= 1.0 ? Theme.Colors.brandGreen : Theme.Colors.guindaColor)
                    .frame(width: geo.size.width * min(max(progress, 0), 1), height: 5)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: 5)
        .accessibilityHidden(true)
    }

    // MARK: - Rows

    private var rowsSection: some View {
        VStack(spacing: 0) {
            rowContent()
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
        .animation(.easeInOut(duration: 0.22), value: isExpanded)
    }

    // MARK: - CTA

    private func continueButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "play.fill")
                    .font(.system(size: 11, weight: .semibold))
                Text("Continuar unidad")
                    .font(Theme.Fonts.notoSans(13, weight: .semibold))
            }
            .foregroundStyle(Theme.Colors.brandGreen)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(Theme.Colors.brandCreamStrong),
                alignment: .top
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Continuar unidad \(title)")
    }
}

// MARK: - BrandUnitAccordionRow

/// Fila de sequential dentro de BrandUnitAccordion.
public struct BrandUnitAccordionRow: View {

    public enum CompletionState {
        case complete, partial(Double), pending
    }

    public let title: String
    public let detail: String?
    public let state: CompletionState
    public let onTap: () -> Void

    public init(
        title: String,
        detail: String? = nil,
        state: CompletionState,
        onTap: @escaping () -> Void
    ) {
        self.title = title
        self.detail = detail
        self.state = state
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                stateIndicator
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Theme.Fonts.notoSans(14, weight: .medium))
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .multilineTextAlignment(.leading)
                    if let detail {
                        Text(detail)
                            .font(Theme.Fonts.notoSans(12, weight: .regular))
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityDescription)
    }

    private var stateIndicator: some View {
        ZStack {
            switch state {
            case .complete:
                Circle()
                    .fill(Theme.Colors.brandGreen)
                    .frame(width: 22, height: 22)
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
            case .partial(let pct):
                Circle()
                    .stroke(Theme.Colors.guindaColor, lineWidth: 2)
                    .frame(width: 22, height: 22)
                Circle()
                    .trim(from: 0, to: pct)
                    .stroke(Theme.Colors.guindaColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 22, height: 22)
                    .rotationEffect(.degrees(-90))
            case .pending:
                Circle()
                    .stroke(Theme.Colors.brandCreamStrong, lineWidth: 2)
                    .frame(width: 22, height: 22)
            }
        }
        .accessibilityHidden(true)
    }

    private var accessibilityDescription: String {
        switch state {
        case .complete:     return "\(title), completado"
        case .partial(let p): return "\(title), \(Int(p * 100))% completado"
        case .pending:      return "\(title), pendiente"
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    ScrollView {
        VStack(spacing: 12) {
            BrandUnitAccordion(
                title: "Unidad 1 · Marco Legal",
                progress: 0.75,
                completedCount: 3,
                totalCount: 4,
                isExpanded: true,
                onToggle: {},
                onContinue: {}
            ) {
                BrandUnitAccordionRow(title: "Cap I · Disposiciones Generales", detail: "4 temas", state: .complete, onTap: {})
                BrandUnitAccordionRow(title: "Cap II · Aplicación", detail: "3 temas", state: .partial(0.5), onTap: {})
                BrandUnitAccordionRow(title: "Cap III · Sanciones", detail: "1 tema", state: .pending, onTap: {})
            }

            BrandUnitAccordion(
                title: "Unidad 2 · Fundamentos",
                progress: 0.0,
                completedCount: 0,
                totalCount: 3,
                isExpanded: false,
                onToggle: {}
            ) {
                EmptyView()
            }
        }
        .padding(16)
    }
    .background(Theme.Colors.brandCream)
    .loadFonts()
}
#endif
