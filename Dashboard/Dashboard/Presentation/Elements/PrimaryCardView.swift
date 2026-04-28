//
//  PrimaryCardView.swift
//  Dashboard
//
//  Fase 1: imagen 72pt compacta, Noto Sans, háptico .medium en CTA
//

import SwiftUI
import Kingfisher
import Theme
import Core

public struct PrimaryCardView: View {

    private let courseName: String
    private let org: String
    private let courseImage: String
    private let courseStartDate: Date?
    private let courseEndDate: Date?
    private var futureAssignments: [Assignment]
    private let pastAssignments: [Assignment]
    private let progressEarned: Int
    private let progressPossible: Int
    private let canResume: Bool
    private let resumeTitle: String?
    private let useRelativeDates: Bool
    private let isSelfPaced: Bool
    private var assignmentAction: (String?) -> Void
    private var openCourseAction: () -> Void
    private var resumeAction: () -> Void
    @Environment(\.isHorizontal) var isHorizontal

    public init(
        courseName: String,
        org: String,
        courseImage: String,
        courseStartDate: Date?,
        courseEndDate: Date?,
        futureAssignments: [Assignment],
        pastAssignments: [Assignment],
        progressEarned: Int,
        progressPossible: Int,
        canResume: Bool,
        resumeTitle: String?,
        useRelativeDates: Bool,
        isSelfPaced: Bool = false,
        assignmentAction: @escaping (String?) -> Void,
        openCourseAction: @escaping () -> Void,
        resumeAction: @escaping () -> Void
    ) {
        self.courseName = courseName
        self.org = org
        self.courseImage = courseImage
        self.courseStartDate = courseStartDate
        self.courseEndDate = courseEndDate
        self.futureAssignments = futureAssignments
        self.pastAssignments = pastAssignments
        self.progressEarned = progressEarned
        self.progressPossible = progressPossible
        self.canResume = canResume
        self.resumeTitle = resumeTitle
        self.useRelativeDates = useRelativeDates
        self.isSelfPaced = isSelfPaced
        self.assignmentAction = assignmentAction
        self.openCourseAction = openCourseAction
        self.resumeAction = resumeAction
    }

    private var progressValue: Double {
        guard progressPossible > 0 else { return 0 }
        return Double(progressEarned) / Double(progressPossible)
    }

    private var hasPastAssignment: Bool { !pastAssignments.isEmpty }

    private var formattedCourseDate: String? {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US")
        fmt.dateFormat = "MMM d, yyyy"
        let paceLabel = isSelfPaced ? "A tu ritmo" : "Con fechas"
        if let end = courseEndDate {
            let endLabel = Date() < end ? "Ends" : "Ended"
            return "\(paceLabel)  ·  \(endLabel) \(fmt.string(from: end))"
        } else if let start = courseStartDate {
            return "\(paceLabel)  ·  Starts \(fmt.string(from: start))"
        }
        return paceLabel
    }

    public var body: some View {
        VStack(spacing: 0) {
            // ── Fila superior: imagen 72pt + info ─────────────────────────────
            HStack(spacing: 12) {
                KFImage(URL(string: courseImage))
                    .onFailureImage(CoreAssets.noCourseImage.image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 72, height: 72)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Sizes.radiusCard))
                    .accessibilityIdentifier("course_image")
                    .accessibilityLabel(courseName)
                    .onTapGesture { openCourseAction() }

                VStack(alignment: .leading, spacing: 3) {
                    Text(org)
                        .font(Theme.Fonts.notoSans(9, weight: .medium))
                        .foregroundStyle(Theme.Colors.brandCardSecondary)
                        .lineLimit(1)

                    Text(courseName)
                        .font(Theme.Fonts.notoSans(14, weight: .semibold))
                        .foregroundStyle(Theme.Colors.brandCardPrimary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    if let meta = formattedCourseDate {
                        Text(meta)
                            .font(Theme.Fonts.notoSans(10))
                            .foregroundStyle(Theme.Colors.brandCardSecondary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .onTapGesture { openCourseAction() }
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 10)

            // ── Divisor ───────────────────────────────────────────────────────
            Theme.Colors.brandDivider
                .frame(height: 1)
                .padding(.horizontal, 14)

            // ── Pill de tarea pendiente ───────────────────────────────────────
            if hasPastAssignment {
                Button(action: {
                    if pastAssignments.count == 1 {
                        assignmentAction(pastAssignments.first?.firstComponentBlockId)
                    } else {
                        assignmentAction(nil)
                    }
                }) {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Theme.Colors.guindaColor)
                            .frame(width: 5, height: 5)
                        Text(pastAssignments.count == 1
                             ? "1 tarea pendiente"
                             : "\(pastAssignments.count) tareas pendientes")
                            .font(Theme.Fonts.notoSans(10, weight: .semibold))
                            .foregroundColor(Theme.Colors.guindaColor)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Theme.Colors.guindaColor.opacity(0.08)))
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // ── Barra progreso + % + botón ────────────────────────────────────
            HStack(spacing: 10) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Theme.Colors.brandProgressTrack)
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: [Theme.Colors.brandGreen, Theme.Colors.brandGreenLighter],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * CGFloat(progressValue), height: 4)
                    }
                }
                .frame(height: 4)

                Text("\(Int(progressValue * 100))%")
                    .font(Theme.Fonts.notoSans(10, weight: .bold))
                    .foregroundStyle(Theme.Colors.brandCardMedium)
                    .fixedSize()

                Button(action: {
                    HapticFeedback.impact(.medium)
                    resumeAction()
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                        Text(canResume ? "Continuar" : "Iniciar")
                            .font(Theme.Fonts.notoSans(11, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 34)
                    .background(RoundedRectangle(cornerRadius: 9).fill(Theme.Colors.brandGreen))
                }
                .accessibilityLabel((canResume ? "Continuar curso" : "Iniciar curso") + " \(courseName)")
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 14)
        }
        .background(Theme.Colors.surfaceWhite)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Sizes.radiusHero))
        .shadow(color: Theme.Colors.courseCardShadow, radius: 4, x: 1, y: 2)
        .padding(.horizontal, 20)
    }
}

//swiftlint:disable line_length
#if DEBUG
struct PrimaryCardView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Theme.Colors.brandCream
            PrimaryCardView(
                courseName: "Introducción a la Programación con Python",
                org: "UNAM",
                courseImage: "https://thumbs.dreamstime.com/b/logo-edx-samsung-tablet-edx-massive-open-online-course-mooc-provider-hosts-online-university-level-courses-wide-117763805.jpg",
                courseStartDate: nil,
                courseEndDate: Date(),
                futureAssignments: [],
                pastAssignments: [],
                progressEarned: 12,
                progressPossible: 45,
                canResume: true,
                resumeTitle: "Capítulo 3",
                useRelativeDates: false,
                assignmentAction: { _ in },
                openCourseAction: {},
                resumeAction: {}
            )
            .loadFonts()
        }
        .previewDisplayName("PrimaryCardView — Fase 1 (72pt image)")
    }
}
#endif
//swiftlint:enable line_length
