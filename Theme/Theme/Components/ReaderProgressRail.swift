import SwiftUI

// MARK: - ReaderProgressRail

/// Barra segmentada que muestra progreso entre verticals de un sequential.
/// Cada segmento es tappable para saltar al vertical correspondiente.
public struct ReaderProgressRail: View {

    public enum SegmentState {
        case completed, current, pending
    }

    public let segments: [SegmentState]
    public let onTap: (Int) -> Void

    public init(segments: [SegmentState], onTap: @escaping (Int) -> Void) {
        self.segments = segments
        self.onTap = onTap
    }

    public var body: some View {
        HStack(spacing: 3) {
            ForEach(Array(segments.enumerated()), id: \.offset) { index, state in
                segmentView(state: state, index: index)
            }
        }
        .frame(height: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }

    @ViewBuilder
    private func segmentView(state: SegmentState, index: Int) -> some View {
        Capsule()
            .fill(color(for: state))
            .frame(maxWidth: .infinity, minHeight: state == .current ? 5 : 4, maxHeight: state == .current ? 5 : 4)
            .animation(.easeInOut(duration: 0.2), value: state == .current)
            .onTapGesture { onTap(index) }
    }

    private func color(for state: SegmentState) -> Color {
        switch state {
        case .completed: return Theme.Colors.brandGreen
        case .current:   return Theme.Colors.guindaColor
        case .pending:   return Theme.Colors.brandCreamStrong
        }
    }

    private var accessibilitySummary: String {
        let done = segments.filter { if case .completed = $0 { return true }; return false }.count
        return "\(done) de \(segments.count) secciones completadas"
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    VStack(spacing: 20) {
        ReaderProgressRail(
            segments: [.completed, .completed, .current, .pending, .pending, .pending, .pending, .pending],
            onTap: { _ in }
        )
        .padding(.horizontal, 20)

        ReaderProgressRail(
            segments: [.completed, .completed, .completed, .completed, .current],
            onTap: { _ in }
        )
        .padding(.horizontal, 20)
    }
    .padding()
    .background(Theme.Colors.brandCream)
    .loadFonts()
}
#endif
