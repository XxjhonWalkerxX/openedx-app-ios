//
//  CourseProgressScreenView.swift
//  Course
//
//  Created by Ivan Stepanok on 19.06.2025.
//

import SwiftUI
import Core
import Theme
import Foundation

struct CourseProgressScreenView: View {
    
    private let courseID: String
    @Binding private var coordinate: CGFloat
    @Binding private var collapsed: Bool
    @Binding private var viewHeight: CGFloat
    
    @ObservedObject
    private var viewModel: CourseProgressViewModel
    
    private let connectivity: ConnectivityProtocol
    
    public init(
        courseID: String,
        coordinate: Binding<CGFloat>,
        collapsed: Binding<Bool>,
        viewHeight: Binding<CGFloat>,
        viewModel: CourseProgressViewModel,
        connectivity: ConnectivityProtocol,
        courseStructure: CourseStructure?
    ) {
        self.courseID = courseID
        self._coordinate = coordinate
        self._collapsed = collapsed
        self._viewHeight = viewHeight
        self.viewModel = viewModel
        self.connectivity = connectivity
        self.viewModel.courseStructure = courseStructure
    }
    
    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .center) {
                VStack(alignment: .center) {
                    
                    // MARK: - Page Body
                    if viewModel.isLoading {
                        HStack(alignment: .center) {
                            ProgressBar(size: 40, lineWidth: 8)
                                .padding(.top, 200)
                                .padding(.horizontal)
                        }
                    } else {
                        ScrollView {
                            VStack(alignment: .center) {
                        DynamicOffsetView(
                            coordinate: $coordinate,
                            collapsed: $collapsed,
                            viewHeight: $viewHeight,
                            externalHeight: $viewHeight
                        )
                                RefreshProgressView(isShowRefresh: $viewModel.isShowRefresh)
                                
                                courseProgressContent
                                
                                Spacer(minLength: 84)
                            }
                            .padding(.horizontal, 24)
                        }
                        .refreshable {
                            Task {
                                await viewModel.getCourseProgress(courseID: courseID, withProgress: false)
                            }
                        }
                    }
                }
                .accessibilityElement(children: .contain)
                .frameLimit(width: proxy.size.width)
                
                // MARK: - Offline mode SnackBar
                OfflineSnackBarView(
                    connectivity: connectivity,
                    reloadAction: {
                        Task {
                            await viewModel.getCourseProgress(courseID: courseID)
                        }
                    }
                )
                
                // MARK: - Error Alert
                if viewModel.showError {
                    VStack {
                        Spacer()
                        SnackBarView(message: viewModel.errorMessage)
                    }
                    .padding(.bottom, connectivity.isInternetAvaliable
                             ? 0 : OfflineSnackBarView.height)
                    .transition(.move(edge: .bottom))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(
                            deadline: .now() + Theme.Timeout.snackbarMessageLongTimeout
                        ) {
                            viewModel.errorMessage = nil
                        }
                    }
                }
            }
            .background(
                Theme.Colors.brandCream
                    .ignoresSafeArea()
            )
            .onFirstAppear {
                Task {
                    await viewModel.getCourseProgress(courseID: courseID)
                }
            }
        }
    }
    
    @ViewBuilder
    private var courseProgressContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            if viewModel.courseProgress != nil {
                heroSummaryCard
                if viewModel.hasGradedAssignments {
                    performanceSection
                } else {
                    noGradedAssignmentsCard
                }
                certificateSection
            } else if viewModel.isProgressEmpty {
                emptyStateCard
            }
        }
    }

    // MARK: - Hero summary card

    private var heroSummaryCard: some View {
        HStack(alignment: .center, spacing: 18) {
            CourseProgressCircleView(
                progressPercentage: viewModel.overallProgressPercentage
            )
            .accessibilityLabel(CourseLocalization.Accessibility.progressRing)
            .accessibilityValue(
                CourseLocalization.Accessibility.progressPercentageCompleted(
                    "\(Int(ceil(viewModel.overallProgressPercentage * 100)))"
                )
            )
            .accessibilityAddTraits(.updatesFrequently)

            VStack(alignment: .leading, spacing: 6) {
                Text(CourseLocalization.CourseContainer.Progress.title)
                    .font(Theme.Fonts.notoSans(11, weight: .semibold))
                    .tracking(0.5)
                    .foregroundColor(Theme.Colors.guindaColor)
                    .accessibilityAddTraits(.isHeader)

                Text("\(Int(ceil(viewModel.overallProgressPercentage * 100)))%")
                    .font(Theme.Fonts.notoSans(28, weight: .bold))
                    .foregroundColor(Theme.Colors.textPrimary)

                Text(CourseLocalization.CourseContainer.Progress.description)
                    .font(Theme.Fonts.notoSans(12, weight: .regular))
                    .foregroundColor(Theme.Colors.textSecondary)
                    .lineLimit(2)
            }
            .accessibilityElement(children: .combine)

            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.surfaceWhite)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Sizes.radiusCard, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    // MARK: - Performance section

    private var performanceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Desempeño")

            VStack(spacing: 12) {
                OverallGradeView(
                    currentGrade: viewModel.gradePercentage,
                    requiredGrade: viewModel.requiredGradePercentage,
                    assignmentPolicies: viewModel.assignmentPolicies,
                    assignmentProgressData: $viewModel.assignmentProgressData,
                    assignmentColors: viewModel.courseProgress?.gradingPolicy?.assignmentColors ?? []
                )
                .accessibilityElement(children: .contain)
                .accessibilityLabel(CourseLocalization.Accessibility.overallGradeSection)

                GradeDetailsView(
                    assignmentPolicies: viewModel.assignmentPolicies,
                    assignmentProgressData: $viewModel.assignmentProgressData,
                    currentGrade: viewModel.gradePercentage,
                    getAssignmentColor: viewModel.getAssignmentColor
                )
                .accessibilityElement(children: .contain)
                .accessibilityLabel(CourseLocalization.Accessibility.gradeDetailsSection)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Colors.surfaceWhite)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Sizes.radiusCard, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
    }

    // MARK: - Certificate section

    @ViewBuilder
    private var certificateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Constancia")
            certificateCard
        }
    }

    private var certificateCard: some View {
        let certData = viewModel.courseProgress?.certificateData
        let hasCert = viewModel.hasCertificate
        let downloadUrl = viewModel.certificateUrl

        return HStack(alignment: .center, spacing: 14) {
            Image(systemName: hasCert ? "rosette" : "lock.rotation")
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(hasCert ? Theme.Colors.brandGreen : Theme.Colors.textSecondary)
                .frame(width: 44, height: 44)
                .background(
                    (hasCert ? Theme.Colors.brandGreenTint : Theme.Colors.brandCreamStrong)
                )
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(hasCert ? "Constancia disponible" : "Constancia bloqueada")
                    .font(Theme.Fonts.notoSans(14, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text(certificateSubtitle(certData: certData, hasCert: hasCert))
                    .font(Theme.Fonts.notoSans(12, weight: .regular))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            if hasCert, let url = downloadUrl, let URL = URL(string: url) {
                Button(action: {
                    HapticFeedback.impact(.medium)
                    UIApplication.shared.open(URL)
                }) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Theme.Colors.brandGreen)
                }
                .accessibilityLabel("Descargar constancia")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.surfaceWhite)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Sizes.radiusCard, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    private func certificateSubtitle(
        certData: CourseProgressCertificateData?,
        hasCert: Bool
    ) -> String {
        if hasCert {
            return "Tu constancia ya está lista. Tócala para descargar."
        }
        if let date = certData?.certificateAvailableDate, !date.isEmpty {
            return "Disponible el \(date)"
        }
        return "Disponible al completar el curso"
    }

    // MARK: - States

    private var noGradedAssignmentsCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 44, weight: .ultraLight))
                .foregroundColor(Theme.Colors.textSecondary)

            Text(CourseLocalization.CourseContainer.Progress.noGradedAssignments)
                .font(Theme.Fonts.notoSans(14, weight: .medium))
                .foregroundColor(Theme.Colors.textPrimary)
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.surfaceWhite)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Sizes.radiusCard, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(CourseLocalization.CourseContainer.Progress.noGradedAssignments)
        .accessibilityHint(CourseLocalization.Accessibility.noGradedAssignmentsHint)
    }

    private var emptyStateCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundColor(Theme.Colors.brandGreen.opacity(0.5))

            Text(CourseLocalization.CourseContainer.Progress.noProgressAvailable)
                .font(Theme.Fonts.notoSans(15, weight: .semibold))
                .foregroundColor(Theme.Colors.textPrimary)
                .multilineTextAlignment(.center)

            Text(CourseLocalization.CourseContainer.Progress.startLearning)
                .font(Theme.Fonts.notoSans(13, weight: .regular))
                .foregroundColor(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.surfaceWhite)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Sizes.radiusCard, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(CourseLocalization.CourseContainer.Progress.noProgressAvailable)
        .accessibilityHint(CourseLocalization.Accessibility.noProgressHint)
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(Theme.Fonts.notoSans(11, weight: .semibold))
            .tracking(0.5)
            .foregroundColor(Theme.Colors.guindaColor)
            .padding(.leading, 2)
    }
}
