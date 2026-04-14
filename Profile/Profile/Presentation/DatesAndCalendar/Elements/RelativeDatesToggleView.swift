//
//  RelativeDatesToggleView.swift
//  Profile
//
//  Created by  Stepanok Ivan on 22.07.2024.
//

import SwiftUI
import Theme

struct RelativeDatesToggleView: View {
    @Binding var useRelativeDates: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(ProfileLocalization.Options.title)
                .font(Theme.Fonts.labelLarge)
                .foregroundColor(Theme.Colors.brandCardMedium)

            HStack(spacing: 16) {
                Text(ProfileLocalization.Options.useRelativeDates)
                    .font(Theme.Fonts.bodyLarge)
                    .foregroundColor(Theme.Colors.brandCardPrimary)

                Spacer(minLength: 12)

                Toggle("", isOn: $useRelativeDates)
                    .frame(width: 50)
                    .tint(Theme.Colors.brandGreen)
            }
            Text(
                useRelativeDates
                ? ProfileLocalization.Options.showRelativeDates
                : ProfileLocalization.Options.showFullDates
            )
                .font(Theme.Fonts.labelMedium)
                .foregroundColor(Theme.Colors.brandCardMedium)
        }
        .frame(minWidth: 0,
               maxWidth: .infinity,
               alignment: .leading)
        .accessibilityIdentifier("relative_dates_toggle")
    }
}
