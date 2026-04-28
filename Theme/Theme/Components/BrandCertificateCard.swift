//
//  BrandCertificateCard.swift
//  Theme
//
//  Tarjeta horizontal de constancia para el carousel del Profile.
//  Gradient brandCreamStrong → brandCream + icono rosette + título + fecha.
//

import SwiftUI

public struct BrandCertificateCard: View {

    public let title: String
    public let issuedDate: String
    public let institution: String?

    public init(
        title: String,
        issuedDate: String,
        institution: String? = nil
    ) {
        self.title = title
        self.issuedDate = issuedDate
        self.institution = institution
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Image(systemName: "rosette")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(Theme.Colors.brandGreen)
                Spacer()
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Theme.Colors.brandGreen.opacity(0.45))
            }
            Spacer()
            if let institution {
                Text(institution.uppercased())
                    .font(Theme.Fonts.notoSans(9, weight: .medium))
                    .tracking(0.6)
                    .foregroundStyle(Theme.Colors.brandGreen.opacity(0.55))
                    .lineLimit(1)
                    .padding(.bottom, 3)
            }
            Text(title)
                .font(Theme.Fonts.notoSans(13, weight: .semibold))
                .foregroundStyle(Theme.Colors.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .padding(.bottom, 4)
            Text(issuedDate)
                .font(Theme.Fonts.notoSans(11, weight: .regular))
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .padding(14)
        .frame(width: 160, height: 160)
        .background(
            LinearGradient(
                colors: [Theme.Colors.brandCreamStrong, Theme.Colors.brandCream],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Sizes.radiusCard))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Constancia: \(title), emitida el \(issuedDate)")
    }
}

// MARK: - Preview

#if DEBUG
struct BrandCertificateCard_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 12) {
            BrandCertificateCard(
                title: "Fundamentos de Ciberseguridad",
                issuedDate: "12 ene 2026",
                institution: "SEP"
            )
            BrandCertificateCard(
                title: "Primeros Auxilios Básicos",
                issuedDate: "3 mar 2026",
                institution: "IMSS"
            )
        }
        .padding()
        .background(Theme.Colors.brandCream)
        .loadFonts()
        .previewDisplayName("BrandCertificateCard")
    }
}
#endif
