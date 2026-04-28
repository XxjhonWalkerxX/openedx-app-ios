//
//  BrandFloatingCTA.swift
//  Theme
//
//  Fase 4: sticky CTA inferior con fade desde transparente → brandCream
//

import SwiftUI

public struct BrandFloatingCTA: View {
    public let label: String
    public let icon: String
    public let showDownload: Bool
    public let action: () -> Void
    public let downloadAction: (() -> Void)?

    public init(
        label: String,
        icon: String = "play.fill",
        showDownload: Bool = false,
        action: @escaping () -> Void,
        downloadAction: (() -> Void)? = nil
    ) {
        self.label = label
        self.icon = icon
        self.showDownload = showDownload
        self.action = action
        self.downloadAction = downloadAction
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Gradiente fade transparente → brandCream
            LinearGradient(
                colors: [Theme.Colors.brandCream.opacity(0), Theme.Colors.brandCream],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 48)
            .allowsHitTesting(false)

            // Botones
            HStack(spacing: 10) {
                // CTA principal
                Button {
                    HapticFeedback.impact(.medium)
                    action()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: icon)
                            .font(.system(size: 13, weight: .bold))
                        Text(label)
                            .font(Theme.Fonts.notoSans(15, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Theme.Colors.brandGreen, Theme.Colors.brandGreenLighter],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                    )
                    .shadow(color: Theme.Colors.brandGreen.opacity(0.30), radius: 8, x: 0, y: 4)
                }
                .accessibilityLabel(label)

                // Botón descarga (opcional)
                if showDownload, let dlAction = downloadAction {
                    Button {
                        HapticFeedback.impact(.soft)
                        dlAction()
                    } label: {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Theme.Colors.brandGreen)
                            .frame(width: 52, height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Theme.Colors.brandCreamStrong)
                            )
                    }
                    .accessibilityLabel("Descargar curso")
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            .background(Theme.Colors.brandCream)
        }
    }
}

#if DEBUG
#Preview {
    ZStack(alignment: .bottom) {
        Theme.Colors.brandCream
        ScrollView {
            Color.gray.opacity(0.2)
                .frame(height: 600)
        }
        BrandFloatingCTA(
            label: "Continuar curso",
            showDownload: true,
            action: {},
            downloadAction: {}
        )
    }
    .ignoresSafeArea()
}
#endif
