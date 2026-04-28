import SwiftUI
import Theme
import Core

struct AssignmentCarouselDetailCardView: View {

    let detailData: AssignmentDetailData

    private var subsectionUI: CourseProgressSubsectionUI {
        detailData.subsectionUI
    }

    private var sectionName: String {
        subsectionUI.sectionName
    }

    private var status: AssignmentCardStatus {
        return subsectionUI.status
    }

    private var statusText: String {
        return subsectionUI.statusTextForCarousel
    }

    var body: some View {
        Button(action: {
            detailData.onAssignmentTap(subsectionUI)
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        
                        if detailData.subsectionUI.status == .pastDue {
                            CoreAssets.icAssignmentPastDue.swiftUIImage
                        }

                        Text(detailData.subsectionUI.status == .pastDue ? CoreLocalization.CourseDates.pastDue
                             : CourseLocalization.CourseCarousel.nextAssignments)
                        .font(Theme.Fonts.notoSans(15, weight: .medium))
                        .foregroundStyle(Theme.Colors.textPrimary)
                    }

                    HStack {
                        VStack(alignment: .leading) {
                            if detailData.subsectionUI.date != nil {
                                Text(statusText)
                                    .font(Theme.Fonts.notoSans(10, weight: .medium))
                                    .foregroundColor(Theme.Colors.accentColor)
                            }

                            Text(subsectionUI.subsection.displayName)
                                .font(Theme.Fonts.notoSans(13, weight: .semibold))
                                .foregroundColor(Theme.Colors.textPrimary)

                            Text(sectionName)
                                .font(Theme.Fonts.notoSans(10, weight: .medium))
                                .foregroundColor(Theme.Colors.textSecondaryDark)
                        }

                        Spacer()

                        CoreAssets.chevronRight.swiftUIImage
                            .resizable()
                            .renderingMode(.template)
                            .frame(width: 24, height: 24)
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .flipsForRightToLeftLayoutDirection(true)
                    }
                }
            }
            .padding(.all, 8)
            .background(content: {
                Theme.Colors.cardViewBackground
            })
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(style: .init(lineWidth: 1, lineCap: .round, lineJoin: .round, miterLimit: 1))
                    .foregroundColor(Theme.Colors.cardViewStroke)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 16)
    }
}
