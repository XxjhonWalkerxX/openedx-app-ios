//
//  BrandSectionHeader.swift
//  Theme
//
//  Header de sección con título + acción opcional "Ver todos (N)".
//  Uso: "Mis cursos · Ver todos (5)", "Para ti esta semana".
//

import SwiftUI

public struct BrandSectionHeader: View {

    public let title: String
    public let actionLabel: String?
    public let onAction: (() -> Void)?

    public init(
        _ title: String,
        actionLabel: String? = nil,
        onAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.actionLabel = actionLabel
        self.onAction = onAction
    }

    public var body: some View {
        HStack(alignment: .center) {
            Text(title)
                .font(Theme.Fonts.notoSans(18, weight: .semibold))
                .foregroundStyle(Theme.Colors.brandCardPrimary)

            Spacer()

            if let label = actionLabel, let action = onAction {
                Button(action: action) {
                    Text(label)
                        .font(Theme.Fonts.notoSans(13, weight: .medium))
                        .foregroundStyle(Theme.Colors.brandGreen)
                }
                .accessibilityLabel(label)
            }
        }
        .padding(.horizontal, Theme.Sizes.horizontalPadding)
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#if DEBUG
struct BrandSectionHeader_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            BrandSectionHeader("Mis cursos", actionLabel: "Ver todos (5)") {}
            BrandSectionHeader("Para ti esta semana")
        }
        .background(Theme.Colors.brandCream)
        .loadFonts()
        .previewDisplayName("BrandSectionHeader")
    }
}
#endif
