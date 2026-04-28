//
//  BrandToggleRow.swift
//  Theme
//
//  Row con label + toggle iOS coloreado guinda.
//  Uso: VideoSettingsView, DatesAndCalendarView, cualquier fila toggle.
//

import SwiftUI

public struct BrandToggleRow: View {

    public let label: String
    public let description: String?
    @Binding public var isOn: Bool
    public let onToggle: ((Bool) -> Void)?

    public init(
        label: String,
        description: String? = nil,
        isOn: Binding<Bool>,
        onToggle: ((Bool) -> Void)? = nil
    ) {
        self.label = label
        self.description = description
        self._isOn = isOn
        self.onToggle = onToggle
    }

    public var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(Theme.Fonts.notoSans(15, weight: .medium))
                    .foregroundStyle(Theme.Colors.textPrimary)
                if let description {
                    Text(description)
                        .font(Theme.Fonts.notoSans(12, weight: .regular))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Theme.Colors.guindaColor)
                .onChange(of: isOn) { newValue in
                    HapticFeedback.selection()
                    onToggle?(newValue)
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityValue(isOn ? "activado" : "desactivado")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Preview

#if DEBUG
struct BrandToggleRow_Previews: PreviewProvider {
    @State static var on = true
    @State static var off = false

    static var previews: some View {
        VStack(spacing: 0) {
            BrandToggleRow(
                label: "Notificaciones push",
                description: "Recibe alertas de nuevas lecciones",
                isOn: $on
            )
            Rectangle()
                .fill(Theme.Colors.brandCreamStrong)
                .frame(height: 1)
                .padding(.leading, 16)
            BrandToggleRow(
                label: "Modo sin conexión",
                isOn: $off
            )
        }
        .background(Theme.Colors.surfaceWhite)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding()
        .background(Theme.Colors.brandCream)
        .loadFonts()
        .previewDisplayName("BrandToggleRow")
    }
}
#endif
