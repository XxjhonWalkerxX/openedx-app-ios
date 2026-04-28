//
//  PrimaryCourseDashboardView.swift
//  Dashboard
//
//  Fase 1: hero guinda + DecorativeRings + BrandStatTile + BrandSectionHeader + Noto Sans
//

import SwiftUI
import Core
import OEXFoundation
import Theme
import Swinject

// MARK: - Design Constants

private enum DashboardLayout {
    static let horizontalPadding: CGFloat = 20
    static let heroTopPadding: CGFloat = 8
    static let heroElementSpacing: CGFloat = 16
    static let heroBottomSpacing: CGFloat = 24
    static let handleWidth: CGFloat = 36
    static let handleHeight: CGFloat = 4
    static let handleTopPadding: CGFloat = 8
    static let handleBottomPadding: CGFloat = 8
    static let carouselSpacing: CGFloat = 16
    static let carouselVerticalPadding: CGFloat = 8
    static let courseCardWidth: CGFloat = 200
    static let settingsButtonSize: CGFloat = 40
    static let contentBottomPadding: CGFloat = 60
    static let dropdownBottomPadding: CGFloat = 12
}

public struct PrimaryCourseDashboardView<ProgramView: View>: View {

    @StateObject private var viewModel: PrimaryCourseDashboardViewModel
    @ViewBuilder let programView: ProgramView
    private var openDiscoveryPage: () -> Void
    private var idiom: UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }

    @State private var selectedMenu: MenuOption = .courses

    public init(
        viewModel: PrimaryCourseDashboardViewModel,
        programView: ProgramView,
        openDiscoveryPage: @escaping () -> Void
    ) {
        self._viewModel = StateObject(wrappedValue: { viewModel }())
        self.programView = programView
        self.openDiscoveryPage = openDiscoveryPage
    }

    // MARK: - Body

    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                Theme.Colors.brandGreenDark
                    .ignoresSafeArea()

                if viewModel.enrollments?.primaryCourse == nil
                    && !viewModel.fetchInProgress
                    && selectedMenu == .courses {
                    NoCoursesView(openDiscovery: { openDiscoveryPage() }).zIndex(1)
                }

                ScrollView {
                    VStack(spacing: 0) {
                        dashboardHero(proxy: proxy)
                        creamCard(proxy: proxy)
                            .offset(y: -15)
                    }
                }
                .refreshable {
                    Task { await viewModel.getEnrollments(showProgress: false) }
                }
                .accessibilityAction {}
                .zIndex(1)

                OfflineSnackBarView(
                    connectivity: viewModel.connectivity,
                    reloadAction: { await viewModel.getEnrollments(showProgress: false) }
                ).zIndex(2)

                if viewModel.showError {
                    VStack {
                        Spacer()
                        SnackBarView(message: viewModel.errorMessage)
                    }
                    .padding(
                        .bottom,
                        viewModel.connectivity.isInternetAvaliable ? 0 : OfflineSnackBarView.height
                    )
                    .transition(.move(edge: .bottom))
                    .onAppear {
                        doAfter(Theme.Timeout.snackbarMessageLongTimeout) {
                            viewModel.errorMessage = nil
                        }
                    }
                    .zIndex(2)
                }
            }
            .onFirstAppear {
                Task { await viewModel.getEnrollments() }
                viewModel.setupNotifications()
            }
            .onAppear { viewModel.updateNeeded = true }
            .navigationBarBackButtonHidden(true)
            .navigationBarHidden(true)
            .navigationTitle(DashboardLocalization.title)
        }
    }

    // MARK: - Hero guinda

    @ViewBuilder
    private func dashboardHero(proxy: GeometryProxy) -> some View {
        ZStack(alignment: .top) {
            // Gradiente guinda
            Theme.Gradients.heroGradient

            // Anillos animados detrás del contenido
            DecorativeRings()

            VStack(spacing: DashboardLayout.heroElementSpacing) {
                // Settings button top-right
                HStack {
                    Spacer()
                    Button(action: { viewModel.router.showSettings() }) {
                        CoreAssets.settings.swiftUIImage
                            .renderingMode(.template)
                            .foregroundColor(.white)
                            .frame(
                                width: DashboardLayout.settingsButtonSize,
                                height: DashboardLayout.settingsButtonSize
                            )
                            .background(Circle().fill(Color.white.opacity(0.14)))
                            .overlay(Circle().strokeBorder(Color.white.opacity(0.22), lineWidth: 1))
                    }
                    .padding(.trailing, DashboardLayout.horizontalPadding)
                    .accessibilityLabel("Configuración")
                }

                // Saludo
                VStack(alignment: .leading, spacing: 4) {
                    let firstTwo = viewModel.userName
                        .split(separator: " ")
                        .prefix(2)
                        .joined(separator: " ")
                    Text(firstTwo.isEmpty ? "¡Hola!" : "¡Hola, \(firstTwo)!")
                        .font(Theme.Fonts.display(30))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .accessibilityIdentifier("courses_header_text")

                    Text("Continúa donde lo dejaste")
                        .font(Theme.Fonts.body(13))
                        .foregroundColor(.white.opacity(0.58))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, DashboardLayout.horizontalPadding)

                // Stat tiles
                if let enrollments = viewModel.enrollments {
                    statTiles(enrollments)
                        .padding(.horizontal, DashboardLayout.horizontalPadding)
                }

                Spacer().frame(height: DashboardLayout.heroBottomSpacing - DashboardLayout.heroElementSpacing)
            }
            .padding(.top, DashboardLayout.heroTopPadding)

            // Dropdown si hay programas
            if viewModel.config.program.enabled && viewModel.config.program.isWebViewConfigured {
                VStack {
                    Spacer()
                    HStack(alignment: .center) {
                        DropDownMenu(selectedOption: $selectedMenu, analytics: viewModel.analytics)
                        Spacer()
                    }
                    .padding(.horizontal, DashboardLayout.horizontalPadding)
                    .padding(.bottom, DashboardLayout.dropdownBottomPadding)
                }
            }
        }
        .frame(minHeight: viewModel.config.program.enabled && viewModel.config.program.isWebViewConfigured ? 220 : 200)
    }

    // MARK: - Stat Tiles

    private func courseStats(_ enrollments: PrimaryEnrollment) -> (total: Int, inProgress: Int, notStarted: Int) {
        var progresses: [(earned: Int, possible: Int)] = []
        if let p = enrollments.primaryCourse {
            progresses.append((p.progressEarned, p.progressPossible))
        }
        for c in enrollments.courses { progresses.append((c.progressEarned, c.progressPossible)) }
        let total = progresses.count
        let inProgress = progresses.filter { $0.earned > 0 && $0.earned < $0.possible }.count
        let notStarted = progresses.filter { $0.earned == 0 }.count
        return (total, inProgress, notStarted)
    }

    @ViewBuilder
    private func statTiles(_ enrollments: PrimaryEnrollment) -> some View {
        let stats = courseStats(enrollments)
        HStack(spacing: 8) {
            if stats.total > 0 {
                BrandStatTile(value: "\(stats.total)", label: "cursos")
            }
            if stats.inProgress > 0 {
                BrandStatTile(value: "\(stats.inProgress)", label: "en progreso")
            }
            if stats.notStarted > 0 {
                BrandStatTile(value: "\(stats.notStarted)", label: "por iniciar")
            }
        }
    }

    // MARK: - Cream Card

    @ViewBuilder
    private func creamCard(proxy: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Theme.Colors.brandHandle)
                .frame(width: DashboardLayout.handleWidth, height: DashboardLayout.handleHeight)
                .padding(.top, DashboardLayout.handleTopPadding)
                .padding(.bottom, DashboardLayout.handleBottomPadding)

            switch selectedMenu {
            case .courses:
                coursesContent(proxy: proxy)
            case .programs:
                programView
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: 32, topTrailingRadius: 32)
                .fill(Theme.Colors.brandCream)
        )
    }

    @ViewBuilder
    private func coursesContent(proxy: GeometryProxy) -> some View {
        if viewModel.fetchInProgress {
            VStack(alignment: .center) {
                ProgressBar(size: 40, lineWidth: 8).padding(.top, 10)
            }
            .frame(maxWidth: .infinity, minHeight: 300)
        } else {
            LazyVStack(spacing: 0) {
                if let enrollments = viewModel.enrollments {
                    if let primary = enrollments.primaryCourse {
                        BrandSectionHeader("Continuar aprendiendo")
                        PrimaryCardView(
                            courseName: primary.name,
                            org: primary.org,
                            courseImage: primary.courseBanner,
                            courseStartDate: primary.courseStart,
                            courseEndDate: primary.courseEnd,
                            futureAssignments: primary.futureAssignments,
                            pastAssignments: primary.pastAssignments,
                            progressEarned: primary.progressEarned,
                            progressPossible: primary.progressPossible,
                            canResume: primary.lastVisitedBlockID != nil,
                            resumeTitle: primary.resumeTitle,
                            useRelativeDates: viewModel.storage.useRelativeDates,
                            isSelfPaced: primary.isSelfPaced,
                            assignmentAction: { lastVisitedBlockID in
                                viewModel.router.showCourseScreens(
                                    courseID: primary.courseID,
                                    hasAccess: primary.hasAccess,
                                    courseStart: primary.courseStart,
                                    courseEnd: primary.courseEnd,
                                    enrollmentStart: nil, enrollmentEnd: nil,
                                    title: primary.name,
                                    courseRawImage: primary.courseBanner,
                                    showDates: lastVisitedBlockID == nil,
                                    lastVisitedBlockID: lastVisitedBlockID
                                )
                            },
                            openCourseAction: {
                                viewModel.router.showCourseScreens(
                                    courseID: primary.courseID,
                                    hasAccess: primary.hasAccess,
                                    courseStart: primary.courseStart,
                                    courseEnd: primary.courseEnd,
                                    enrollmentStart: nil, enrollmentEnd: nil,
                                    title: primary.name,
                                    courseRawImage: primary.courseBanner,
                                    showDates: false, lastVisitedBlockID: nil
                                )
                            },
                            resumeAction: {
                                viewModel.router.showCourseScreens(
                                    courseID: primary.courseID,
                                    hasAccess: primary.hasAccess,
                                    courseStart: primary.courseStart,
                                    courseEnd: primary.courseEnd,
                                    enrollmentStart: nil, enrollmentEnd: nil,
                                    title: primary.name,
                                    courseRawImage: primary.courseBanner,
                                    showDates: false,
                                    lastVisitedBlockID: primary.lastVisitedBlockID
                                )
                            }
                        )
                    }

                    if !enrollments.courses.isEmpty {
                        BrandSectionHeader(
                            "Mis cursos",
                            actionLabel: "Ver todos (\(enrollments.count + 1))",
                            onAction: { viewModel.router.showAllCourses(courses: enrollments.courses) }
                        )
                    }

                    if idiom == .pad {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 16),
                                GridItem(.flexible(), spacing: 16),
                                GridItem(.flexible(), spacing: 16)
                            ],
                            alignment: .leading,
                            spacing: 15
                        ) {
                            courses(enrollments)
                        }
                        .padding(.horizontal, DashboardLayout.horizontalPadding)
                        .padding(.vertical, DashboardLayout.carouselVerticalPadding)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: DashboardLayout.carouselSpacing) {
                                courses(enrollments)
                            }
                            .padding(.horizontal, DashboardLayout.horizontalPadding)
                            .padding(.vertical, DashboardLayout.carouselVerticalPadding)
                        }
                    }

                    // Weekly Goal card
                    weeklyGoalCard(enrollments: enrollments)
                        .padding(.horizontal, DashboardLayout.horizontalPadding)
                        .padding(.top, 20)

                    Spacer(minLength: DashboardLayout.contentBottomPadding)
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .frameLimit(width: proxy.size.width)
        }
    }

    // MARK: - Weekly Goal Card (1.5)

    @ViewBuilder
    private func weeklyGoalCard(enrollments: PrimaryEnrollment) -> some View {
        let stats = courseStats(enrollments)
        let weeklyProgress: Double = stats.total > 0
            ? Double(stats.total - stats.notStarted) / Double(stats.total)
            : 0

        ZStack {
            Theme.Gradients.heroGradient
            DecorativeRings()

            HStack(spacing: 16) {
                BrandProgressRing(
                    progress: weeklyProgress,
                    size: 72,
                    lineWidth: 6,
                    trackColor: Color.white.opacity(0.2),
                    fillColor: .white,
                    label: nil
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Meta semanal")
                        .font(Theme.Fonts.notoSans(11, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.65))
                        .tracking(0.5)
                    Text(weeklyProgress >= 1.0 ? "¡Semana completada!" : "Sigue aprendiendo")
                        .font(Theme.Fonts.title(16))
                        .foregroundStyle(Color.white)
                    Text("\(stats.total - stats.notStarted) de \(stats.total) cursos activos")
                        .font(Theme.Fonts.body(13))
                        .foregroundStyle(Color.white.opacity(0.75))
                }
                Spacer()
            }
            .padding(20)
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.Sizes.radiusCard))
        .shadow(color: Theme.Colors.guindaColor.opacity(0.3), radius: 8, x: 0, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Meta semanal: \(stats.total - stats.notStarted) de \(stats.total) cursos activos")
    }

    // MARK: - Courses helpers

    private let accentColors: [Color] = [
        Theme.Colors.guindaColor,
        Theme.Colors.brandGreen,
        Theme.Colors.brandWarmDark,
        Theme.Colors.brandGreenDark,
    ]

    @ViewBuilder
    private func courses(_ enrollments: PrimaryEnrollment) -> some View {
        ForEach(
            Array(enrollments.courses.enumerated()),
            id: \.offset
        ) { index, course in
            Button(action: {
                HapticFeedback.impact(.soft)
                viewModel.router.showCourseScreens(
                    courseID: course.courseID,
                    hasAccess: course.hasAccess,
                    courseStart: course.courseStart,
                    courseEnd: course.courseEnd,
                    enrollmentStart: course.enrollmentStart,
                    enrollmentEnd: course.enrollmentEnd,
                    title: course.name,
                    courseRawImage: course.imageURL,
                    showDates: false,
                    lastVisitedBlockID: nil
                )
            }, label: {
                CourseCardView(
                    courseName: course.name,
                    courseImage: course.imageURL,
                    progressEarned: course.progressEarned,
                    progressPossible: course.progressPossible,
                    courseStartDate: nil,
                    courseEndDate: nil,
                    hasAccess: course.hasAccess,
                    showProgress: true,
                    useRelativeDates: viewModel.storage.useRelativeDates,
                    accentColor: accentColors[index % accentColors.count]
                )
            })
            .frame(width: idiom == .pad ? nil : DashboardLayout.courseCardWidth)
            .accessibilityIdentifier("course_item")
        }
        if enrollments.courses.count < enrollments.count {
            viewAllButton(enrollments)
        }
    }

    private func viewAllButton(_ enrollments: PrimaryEnrollment) -> some View {
        Button(action: { viewModel.router.showAllCourses(courses: enrollments.courses) }, label: {
            VStack(alignment: .center, spacing: 6) {
                Spacer()
                Image(systemName: "chevron.right.circle")
                    .font(.system(size: 28))
                    .foregroundColor(Theme.Colors.brandGreen)
                Text(DashboardLocalization.Learn.viewAll)
                    .font(Theme.Fonts.body(12))
                    .foregroundStyle(Theme.Colors.textPrimary)
                Spacer()
            }
            .background(Theme.Colors.cardViewBackground)
            .cornerRadius(16)
            .shadow(color: Theme.Colors.courseCardShadow, radius: 4, x: 1, y: 2)
        })
        .frame(width: idiom == .pad ? nil : DashboardLayout.courseCardWidth)
    }
}

#if DEBUG
struct PrimaryCourseDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = PrimaryCourseDashboardViewModel(
            interactor: DashboardInteractor.mock,
            connectivity: Connectivity(),
            analytics: DashboardAnalyticsMock(),
            config: ConfigMock(),
            storage: CoreStorageMock(),
            router: DashboardRouterMock()
        )

        PrimaryCourseDashboardView(
            viewModel: vm,
            programView: EmptyView(),
            openDiscoveryPage: {}
        )
        .preferredColorScheme(.light)
        .previewDisplayName("Dashboard — Fase 1")
    }
}
#endif
