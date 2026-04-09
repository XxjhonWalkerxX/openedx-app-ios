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

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                // Barra de acento superior
                accentColor
                    .frame(height: 3)

                // Imagen cuadrada con ring de progreso
                ZStack(alignment: .bottomTrailing) {
                    KFImage(URL(string: courseImage))
                        .onFailureImage(CoreAssets.noCourseImage.image)
                        .resizable()
                        .scaledToFill()
                        .clipped()
                        .accessibilityElement(children: .ignore)
                        .accessibilityIdentifier("course_image")

                    if showProgress {
                        ProgressRingView(progress: progressValue)
                            .frame(width: 32, height: 32)
                            .padding(.trailing, 8)
                            .padding(.bottom, 8)
                    }
                }
                .frame(maxWidth: 144)
                .frame(height: 132)
                .clipped()

                // Título y estado
                VStack(alignment: .leading, spacing: 5) {
                    Text(courseName)
                        .font(Theme.Fonts.ttRoundsCompressedMedium(13))
                        .foregroundColor(Theme.Colors.brandCardPrimary)
                        .kerning(-0.2)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text(statusText)
                        .font(progressValue >= 1.0
                            ? Theme.Fonts.ttRoundsCompressedMedium(11)
                            : Theme.Fonts.ttRoundsCompressedThinItalic(11))
                        .foregroundColor(statusColor)
                }
                .padding(.horizontal, 10)
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
                        .font(.system(size: 10))
                }
                .padding(8)
            }
        }
        .frame(width: 144)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Theme.Colors.courseCardShadow, radius: 3, x: 1, y: 2)
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
