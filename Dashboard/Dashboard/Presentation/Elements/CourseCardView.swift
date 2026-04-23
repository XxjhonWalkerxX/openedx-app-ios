//
//  CourseCardView.swift
//  Dashboard
//
//  Tarjeta pequeña del carrusel — replica CourseCarouselCard de Android
//

import SwiftUI
import Theme
import Kingfisher
import Core

struct CourseCardView: View {

    enum VisualStyle {
        case dashboardCompact
        case allCoursesCompact
        case allCoursesGrid
    }

    private enum Layout {
        static let compactCardWidth: CGFloat = 144
        static let compactImageHeight: CGFloat = 132
        static let compactCardHeight: CGFloat = 214
        static let allCoursesCompactImageHeight: CGFloat = 132
        static let allCoursesCompactCardHeight: CGFloat = 214
        static let imageHeight: CGFloat = 124
        static let cardHeight: CGFloat = 286
        static let dateRowHeight: CGFloat = 20
        static let titleRowHeight: CGFloat = 70
        static let statusRowHeight: CGFloat = 18
    }

    private let courseName: String
    private let courseImage: String
    private let progressEarned: Int
    private let progressPossible: Int
    private let courseStartDate: Date?
    private let courseEndDate: Date?
    private let hasAccess: Bool
    private let showProgress: Bool
    private let useRelativeDates: Bool
    private let accentColor: Color
    private let visualStyle: VisualStyle
    private let fillWidth: Bool

    init(
        courseName: String,
        courseImage: String,
        progressEarned: Int,
        progressPossible: Int,
        courseStartDate: Date?,
        courseEndDate: Date?,
        hasAccess: Bool,
        showProgress: Bool,
        useRelativeDates: Bool,
        visualStyle: VisualStyle = .dashboardCompact,
        fillWidth: Bool = false,
        accentColor: Color = Theme.Colors.brandGreen
    ) {
        self.courseName = courseName
        self.courseImage = courseImage
        self.progressEarned = progressEarned
        self.progressPossible = progressPossible
        self.courseStartDate = courseStartDate
        self.courseEndDate = courseEndDate
        self.hasAccess = hasAccess
        self.showProgress = showProgress
        self.useRelativeDates = useRelativeDates
        self.visualStyle = visualStyle
        self.fillWidth = fillWidth
        self.accentColor = accentColor
    }

    private var progressValue: Double {
        guard progressPossible > 0 else { return 0 }
        return Double(progressEarned) / Double(progressPossible)
    }

    private var statusText: String {
        if progressValue >= 1.0 { return "Completado" }
        if progressValue > 0.0 { return "En progreso" }
        return "Por iniciar"
    }

    private var statusColor: Color {
        if progressValue >= 1.0 { return Theme.Colors.brandGreen }
        if progressValue > 0.0 { return Theme.Colors.brandCardMedium }
        return Theme.Colors.brandCardSecondary
    }

    private var courseDateText: String {
        if let endDate = courseEndDate {
            let label = Date() < endDate ? "Ends" : "Ended on"
            let formatted = endDate.dateToString(style: .shortWeekdayMonthDayYear, useRelativeDates: useRelativeDates)
            return "\(label) \(formatted)"
        }

        if let startDate = courseStartDate {
            if startDate > Date() {
                return "Starts Soon"
            }
            let formatted = startDate.dateToString(style: .shortWeekdayMonthDayYear, useRelativeDates: useRelativeDates)
            return "Started \(formatted)"
        }

        return "Starts Soon"
    }

    private var shouldShowDateLine: Bool {
        visualStyle == .allCoursesGrid || visualStyle == .allCoursesCompact
    }

    private var cardHeight: CGFloat {
        switch visualStyle {
        case .dashboardCompact:
            return Layout.compactCardHeight
        case .allCoursesCompact:
            return Layout.allCoursesCompactCardHeight
        case .allCoursesGrid:
            return Layout.cardHeight
        }
    }

    private var imageHeight: CGFloat {
        switch visualStyle {
        case .dashboardCompact:
            return Layout.compactImageHeight
        case .allCoursesCompact:
            return Layout.allCoursesCompactImageHeight
        case .allCoursesGrid:
            return Layout.imageHeight
        }
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                accentColor
                    .frame(height: 3)

                ZStack(alignment: .bottomTrailing) {
                    GeometryReader { proxy in
                        KFImage(URL(string: courseImage))
                            .onFailureImage(CoreAssets.noCourseImage.image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: proxy.size.width, height: imageHeight, alignment: .center)
                            .clipped()
                            .accessibilityElement(children: .ignore)
                            .accessibilityIdentifier("course_image")
                    }
                    .frame(height: imageHeight)

                    if showProgress {
                        ProgressRingView(progress: progressValue)
                            .frame(width: 32, height: 32)
                            .padding(.trailing, 8)
                            .padding(.bottom, 8)
                    }
                }
                .frame(maxWidth: fillWidth ? .infinity : Layout.compactCardWidth)
                .frame(height: imageHeight)
                .clipped()

                if showProgress {
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Theme.Colors.brandCardSecondary.opacity(0.5))
                            Capsule()
                                .fill(Theme.Colors.brandGreen)
                                .frame(width: proxy.size.width * CGFloat(progressValue))
                        }
                    }
                    .frame(height: 5)
                } else {
                    Rectangle()
                        .fill(Theme.Colors.brandDivider)
                        .frame(height: 1)
                }

                VStack(alignment: .leading, spacing: 8) {
                    if shouldShowDateLine {
                        HStack(spacing: 6) {
                            Text(courseDateText)
                                .font(Theme.Fonts.labelSmall)
                                .foregroundColor(Theme.Colors.brandCardSecondary)
                                .lineLimit(1)
                                .truncationMode(.tail)

                            Spacer()

                            Text(statusText)
                                .font(Theme.Fonts.ttRoundsCompressedThinItalic(10))
                                .foregroundColor(statusColor)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, minHeight: Layout.dateRowHeight, maxHeight: Layout.dateRowHeight, alignment: .center)
                    }

                    Text(courseName)
                        .font(visualStyle == .allCoursesGrid ? Theme.Fonts.titleMedium : Theme.Fonts.ttRoundsCompressedMedium(13))
                        .foregroundColor(Theme.Colors.brandCardPrimary)
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .multilineTextAlignment(.leading)
                        .frame(
                            maxWidth: .infinity,
                            minHeight: visualStyle == .allCoursesGrid ? Layout.titleRowHeight : 42,
                            maxHeight: visualStyle == .allCoursesGrid ? Layout.titleRowHeight : 42,
                            alignment: .topLeading
                        )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .padding(.bottom, 12)
            }

            // Candado si no tiene acceso
            if !hasAccess {
                ZStack {
                    Circle()
                        .foregroundStyle(Theme.Colors.primaryHeaderColor)
                        .opacity(0.7)
                        .frame(width: 24, height: 24)
                    CoreAssets.lockIcon.swiftUIImage
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .font(Theme.Fonts.ttRoundsBody(10))
                }
                .padding(8)
            }
        }
        .frame(maxWidth: fillWidth ? .infinity : Layout.compactCardWidth)
        .frame(height: cardHeight)
        .background(Theme.Colors.white)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.black.opacity(0.04), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Progress Ring

struct ProgressRingView: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 3.5)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.white, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(progress * 100))%")
                .font(Theme.Fonts.ttRoundsBody(7, weight: 700))
                .foregroundColor(.white)
        }
        .background(Circle().fill(Color.black.opacity(0.15)))
    }
}

//swiftlint:disable line_length
#if DEBUG
#Preview {
    HStack(spacing: 12) {
        CourseCardView(
            courseName: "Introducción al Diseño Web con CSS",
            courseImage: "https://thumbs.dreamstime.com/b/logo-edx-samsung-tablet-edx-massive-open-online-course-mooc-provider-hosts-online-university-level-courses-wide-117763805.jpg",
            progressEarned: 4,
            progressPossible: 8,
            courseStartDate: nil,
            courseEndDate: Date(),
            hasAccess: true,
            showProgress: true,
            useRelativeDates: true,
            accentColor: Theme.Colors.guindaColor
        ).frame(width: 144)

        CourseCardView(
            courseName: "Python para Principiantes",
            courseImage: "",
            progressEarned: 0,
            progressPossible: 0,
            courseStartDate: nil,
            courseEndDate: nil,
            hasAccess: true,
            showProgress: true,
            useRelativeDates: true,
            accentColor: Theme.Colors.brandGreen
        ).frame(width: 144)
    }
    .padding()
    .background(Theme.Colors.brandCream)
}
#endif
//swiftlint:enable line_length
