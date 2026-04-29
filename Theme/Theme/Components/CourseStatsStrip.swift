import SwiftUI

// MARK: - CourseStatsStrip

/// Tira horizontal con chips de estadísticas del curso.
/// Scroll horizontal si los chips no caben.
public struct CourseStatsStrip: View {

    public let items: [StatChip]

    public init(items: [StatChip]) {
        self.items = items
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(items) { item in
                    StatChipView(chip: item)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
    }
}

// MARK: - StatChip Model

public struct StatChip: Identifiable {
    public let id: String
    public let icon: String        // SF Symbol name
    public let value: String
    public let label: String
    public let action: (() -> Void)?

    public init(
        id: String,
        icon: String,
        value: String,
        label: String,
        action: (() -> Void)? = nil
    ) {
        self.id = id
        self.icon = icon
        self.value = value
        self.label = label
        self.action = action
    }
}

// MARK: - StatChipView

private struct StatChipView: View {

    let chip: StatChip
    @State private var pressed = false

    var body: some View {
        let content = HStack(spacing: 6) {
            Image(systemName: chip.icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.Colors.brandGreen)
            VStack(alignment: .leading, spacing: 0) {
                Text(chip.value)
                    .font(Theme.Fonts.notoSans(14, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text(chip.label)
                    .font(Theme.Fonts.notoSans(10, weight: .medium))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .lineLimit(1)
            }
            if chip.action != nil {
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Theme.Colors.surfaceWhite)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: Theme.Colors.shadowColor.opacity(0.07), radius: 4, x: 0, y: 1)
        .scaleEffect(pressed ? 0.96 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: pressed)

        if let action = chip.action {
            Button(action: action) { content }
                .buttonStyle(.plain)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in pressed = true }
                        .onEnded { _ in pressed = false }
                )
                .accessibilityLabel("\(chip.value) \(chip.label)")
                .accessibilityHint("Toca para ver detalle")
                .accessibilityAddTraits(.isButton)
        } else {
            content
                .accessibilityLabel("\(chip.value) \(chip.label)")
                .accessibilityElement(children: .combine)
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    VStack(spacing: 16) {
        CourseStatsStrip(items: [
            StatChip(id: "progress", icon: "chart.bar.fill", value: "78%", label: "completado", action: {}),
            StatChip(id: "streak",   icon: "flame.fill",     value: "12 días", label: "racha"),
            StatChip(id: "pending",  icon: "clock.fill",     value: "3",       label: "pendientes", action: {}),
            StatChip(id: "grade",    icon: "star.fill",      value: "95",      label: "calificación", action: {}),
        ])
    }
    .padding(.vertical, 16)
    .background(Theme.Colors.brandCream)
    .loadFonts()
}
#endif
