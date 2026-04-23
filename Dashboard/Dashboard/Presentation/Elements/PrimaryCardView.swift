//
//  PrimaryCardView.swift
//  Dashboard
//
//  Tarjeta del curso primario — replica PrimaryCourseCard de Android
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

    /// Fecha formateada igual que Android TimeUtils.getCourseFormattedDate:
    /// "A tu ritmo · Ends Nov 29, 2026" / "Con fechas · Ended Nov 29, 2026"
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
            // ── Bloque superior: imagen + info ────────────────────────────────
            HStack(spacing: 0) {
                KFImage(URL(string: courseImage))
                    .onFailureImage(CoreAssets.noCourseImage.image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 140, height: 140)
                    .clipped()
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 20,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 0
                        )
                    )
                    .accessibilityIdentifier("course_image")
                    .onTapGesture { openCourseAction() }

                ElasticTextBlock(
                    org: org,
                    title: courseName,
                    meta: formattedCourseDate,
                    height: 112,
                    orgFont: Theme.Fonts.ttRoundsBody(9, weight: 600),
                    titleFont: Theme.Fonts.ttRoundsCompressedMedium(14),
                    metaFont: Theme.Fonts.ttRoundsBody(10)
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .onTapGesture { openCourseAction() }
            }
            .frame(height: 140)

            // ── Divisor ───────────────────────────────────────────────────────
            Theme.Colors.brandDivider
                .frame(height: 1)

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
                            .font(Theme.Fonts.ttRoundsBody(10, weight: 600))
                            .foregroundColor(Theme.Colors.guindaColor)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule().fill(Theme.Colors.guindaColor.opacity(0.08))
                    )
                }
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // ── Barra de progreso + % + botón ─────────────────────────────────
            HStack(spacing: 10) {
                // Barra de progreso
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Theme.Colors.brandProgressTrack)
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: [Theme.Colors.brandGreen, Theme.Colors.brandGreenLighter],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * CGFloat(progressValue), height: 4)
                    }
                }
                .frame(height: 4)

                Text("\(Int(progressValue * 100))%")
                    .font(Theme.Fonts.ttRoundsBody(10, weight: 700))
                    .foregroundColor(Theme.Colors.brandCardMedium)
                    .fixedSize()

                // Botón Continuar / Iniciar
                Button(action: { resumeAction() }) {
                    HStack(spacing: 5) {
                        Image(systemName: "play.fill")
                            .font(Theme.Fonts.ttRoundsBody(10))
                            .foregroundColor(.white)
                        Text(canResume ? "Continuar" : "Iniciar")
                            .font(Theme.Fonts.ttRoundsBody(11, weight: 500))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 34)
                    .background(
                        RoundedRectangle(cornerRadius: 9)
                            .fill(Theme.Colors.brandGreen)
                    )
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 12)
        }
        .background(Color.white)
        .cornerRadius(20)
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
    }
}
#endif
//swiftlint:enable line_length
