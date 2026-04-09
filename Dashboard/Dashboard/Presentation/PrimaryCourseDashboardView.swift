//
//  PrimaryCourseDashboardView.swift
//  Dashboard
//
//  Pantalla principal de cursos — @prende.mx
//  Hero gradiente + Card crema con handle
//

import SwiftUI
import Core
import OEXFoundation
import Theme
import Swinject

// MARK: - Design Constants

private enum DashboardLayout {
    // Padding general
    static let horizontalPadding: CGFloat = 20

    // Hero
    static let heroTopPadding: CGFloat = 8
    static let heroElementSpacing: CGFloat = 16
    static let heroBottomSpacing: CGFloat = 24

    // Drag handle
    static let handleWidth: CGFloat = 36
    static let handleHeight: CGFloat = 4
    static let handleTopPadding: CGFloat = 8
    static let handleBottomPadding: CGFloat = 8

    // Section header
    static let sectionHeaderTopPadding: CGFloat = 20
    static let sectionHeaderBottomPadding: CGFloat = 12

    // Carousel
    static let carouselSpacing: CGFloat = 16
    static let carouselVerticalPadding: CGFloat = 8
    static let courseCardWidth: CGFloat = 144

    // Miscelánea
    static let settingsButtonSize: CGFloat = 40
    static let guindaBandHeight: CGFloat = 4
    static let contentBottomPadding: CGFloat = 60
    static let dropdownBottomPadding: CGFloat = 12

    // Círculos decorativos del hero
    static let circleLargeSize: CGFloat = 210
    static let circleMediumSize: CGFloat = 110
    static let circleSmallSize: CGFloat = 70
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

                // Fondo base
                Theme.Colors.brandGreenDark
                    .ignoresSafeArea()

                // Banda guinda — fija en el borde físico (igual que pre-login)
                Theme.Colors.guindaColor
                    .frame(height: DashboardLayout.guindaBandHeight)
                    .ignoresSafeArea(edges: .top)
                    .frame(maxWidth: .infinity, alignment: .top)
                    .zIndex(10)

                // NoCoursesView — visible solo cuando no hay cursos
                if viewModel.enrollments?.primaryCourse == nil
                    && !viewModel.fetchInProgress
                    && selectedMenu == .courses {
                    NoCoursesView(openDiscovery: {
                        openDiscoveryPage()
                    }).zIndex(1)
                }

                // Contenido scrollable
                ScrollView {
                    VStack(spacing: 0) {

                        // HERO
                        dashboardHero(proxy: proxy)

                        // CARD CREMA — offset -15 igual que Android
                        creamCard(proxy: proxy)
                            .offset(y: -15)
                    }
                }
                .refreshable {
                    Task {
                        await viewModel.getEnrollments(showProgress: false)
                    }
                }
                .accessibilityAction {}
                .zIndex(1)

                // Offline snackbar
                OfflineSnackBarView(
                    connectivity: viewModel.connectivity,
                    reloadAction: {
                        await viewModel.getEnrollments(showProgress: false)
                    }
                ).zIndex(2)

                // Error snackbar
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
                Task {
                    await viewModel.getEnrollments()
                }
                viewModel.setupNotifications()
            }
            .onAppear {
                viewModel.updateNeeded = true
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarHidden(true)
            .navigationTitle(DashboardLocalization.title)
        }
    }

    // MARK: - Hero

    @ViewBuilder
    private func dashboardHero(proxy: GeometryProxy) -> some View {
        ZStack(alignment: .top) {

            // Gradiente
            Theme.Gradients.heroGradient

            // Círculos decorativos
            dashboardCircles
                .allowsHitTesting(false)

            VStack(spacing: DashboardLayout.heroElementSpacing) {
                // Settings button top-right
                HStack {
                    Spacer()
                    Button(action: {
                        viewModel.router.showSettings()
                    }) {
                        CoreAssets.settings.swiftUIImage
                            .renderingMode(.template)
                            .foregroundColor(.white)
                            .frame(width: DashboardLayout.settingsButtonSize,
                                   height: DashboardLayout.settingsButtonSize)
                            .background(Circle().fill(Color.white.opacity(0.14)))
                            .overlay(Circle().strokeBorder(Color.white.opacity(0.22), lineWidth: 1))
                    }
                    .padding(.trailing, DashboardLayout.horizontalPadding)
                }

                // Saludo
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bienvenido de vuelta")
                        .font(Theme.Fonts.ttRoundsCompressedThinItalic(13))
                        .foregroundColor(.white.opacity(0.65))
                        .kerning(0.3)

                    let nombre = viewModel.userName
                    Text(nombre.isEmpty ? "¡Hola!" : "¡Hola, \(nombre)!")
                        .font(Theme.Fonts.ttRoundsCompressedMedium(30))
                        .foregroundColor(.white)
                        .kerning(-0.3)
                        .lineLimit(1)
                        .accessibilityIdentifier("courses_header_text")

                    Text("Continúa donde lo dejaste")
                        .font(Theme.Fonts.ttRoundsBody(13))
                        .foregroundColor(.white.opacity(0.58))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, DashboardLayout.horizontalPadding)

                // Stat pills — conteo de cursos
                if let enrollments = viewModel.enrollments {
                    scrollStatPills(enrollments)
                        .padding(.horizontal, DashboardLayout.horizontalPadding)
                }

                Spacer().frame(height: DashboardLayout.heroBottomSpacing - DashboardLayout.heroElementSpacing)
            }
            .padding(.top, DashboardLayout.heroTopPadding)

            // Dropdown menu si hay programas habilitados
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

    private func courseStats(_ enrollments: PrimaryEnrollment) -> (total: Int, inProgress: Int, notStarted: Int) {
        // Progreso del curso primario
        var progresses: [(earned: Int, possible: Int)] = []
        if let p = enrollments.primaryCourse {
            progresses.append((p.progressEarned, p.progressPossible))
        }
        for c in enrollments.courses {
            progresses.append((c.progressEarned, c.progressPossible))
        }
        let total = progresses.count
        let inProgress = progresses.filter { $0.earned > 0 && $0.earned < $0.possible }.count
        let notStarted = progresses.filter { $0.earned == 0 }.count
        return (total, inProgress, notStarted)
    }

    @ViewBuilder
    private func scrollStatPills(_ enrollments: PrimaryEnrollment) -> some View {
        let stats = courseStats(enrollments)
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if stats.total > 0 {
                    statPill(color: Theme.Colors.pillGreen, label: "\(stats.total) cursos")
                }
                if stats.inProgress > 0 {
                    statPill(color: Theme.Colors.pillPink, label: "\(stats.inProgress) en progreso")
                }
                if stats.notStarted > 0 {
                    statPill(color: Theme.Colors.pillYellow, label: "\(stats.notStarted) por iniciar")
                }
            }
        }
    }

    private func statPill(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(Theme.Fonts.ttRoundsBody(11, weight: 500))
                .foregroundColor(.white.opacity(0.88))
                .kerning(0.2)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(Capsule().fill(Color.white.opacity(0.11)))
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.18), lineWidth: 1))
    }

    private var dashboardCircles: some View {
        ZStack {
            // Grande — esquina superior derecha
            Circle()
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 34)
                .frame(width: DashboardLayout.circleLargeSize, height: DashboardLayout.circleLargeSize)
                .offset(x: 130, y: -40)
            // Mediano — zona inferior izquierda
            Circle()
                .strokeBorder(Color.white.opacity(0.05), lineWidth: 20)
                .frame(width: DashboardLayout.circleMediumSize, height: DashboardLayout.circleMediumSize)
                .offset(x: -120, y: 130)
            // Pequeño — zona central
            Circle()
                .strokeBorder(Color.white.opacity(0.07), lineWidth: 13)
                .frame(width: DashboardLayout.circleSmallSize, height: DashboardLayout.circleSmallSize)
                .offset(x: -70, y: 20)
        }
    }

    // MARK: - Cream Card

    @ViewBuilder
    private func creamCard(proxy: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // Drag handle
            Capsule()
                .fill(Theme.Colors.brandHandle)
                .frame(width: DashboardLayout.handleWidth, height: DashboardLayout.handleHeight)
                .padding(.top, DashboardLayout.handleTopPadding)
                .padding(.bottom, DashboardLayout.handleBottomPadding)

            // Contenido según tab seleccionado
            switch selectedMenu {
            case .courses:
                coursesContent(proxy: proxy)
            case .programs:
                programView
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 32,
                topTrailingRadius: 32
            )
            .fill(Theme.Colors.brandCream)
        )
    }

    @ViewBuilder
    private func coursesContent(proxy: GeometryProxy) -> some View {
        if viewModel.fetchInProgress {
            VStack(alignment: .center) {
                ProgressBar(size: 40, lineWidth: 8)
                    .padding(.top, 10)
            }
            .frame(maxWidth: .infinity, minHeight: 300)
        } else {
            LazyVStack(spacing: 0) {
                if let enrollments = viewModel.enrollments {
                    if let primary = enrollments.primaryCourse {
                        sectionHeader(title: "Continuar aprendiendo")
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
                                    enrollmentStart: nil,
                                    enrollmentEnd: nil,
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
                                    enrollmentStart: nil,
                                    enrollmentEnd: nil,
                                    title: primary.name,
                                    courseRawImage: primary.courseBanner,
                                    showDates: false,
                                    lastVisitedBlockID: nil
                                )
                            },
                            resumeAction: {
                                viewModel.router.showCourseScreens(
                                    courseID: primary.courseID,
                                    hasAccess: primary.hasAccess,
                                    courseStart: primary.courseStart,
                                    courseEnd: primary.courseEnd,
                                    enrollmentStart: nil,
                                    enrollmentEnd: nil,
                                    title: primary.name,
                                    courseRawImage: primary.courseBanner,
                                    showDates: false,
                                    lastVisitedBlockID: primary.lastVisitedBlockID
                                )
                            }
                        )
                    }
                    if !enrollments.courses.isEmpty {
                        sectionHeader(
                            title: "Mis cursos",
                            linkText: "Ver todos (\(enrollments.count + 1))",
                            onLinkTap: { viewModel.router.showAllCourses(courses: enrollments.courses) }
                        )
                    }
                    if idiom == .pad {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 16),
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
                    Spacer(minLength: DashboardLayout.contentBottomPadding)
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .frameLimit(width: proxy.size.width)
        }
    }

    // MARK: - Colores de acento para tarjetas del carrusel

    private let accentColors: [Color] = [
        Theme.Colors.guindaColor,
        Theme.Colors.brandGreen,
        Theme.Colors.brandWarmDark,
        Theme.Colors.brandGreenDark,
    ]

    // MARK: - Courses helpers

    @ViewBuilder
    private func courses(_ enrollments: PrimaryEnrollment) -> some View {
        ForEach(
            Array(enrollments.courses.enumerated()),
            id: \.offset
        ) { index, course in
            Button(action: {
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
        Button(action: {
            viewModel.router.showAllCourses(courses: enrollments.courses)
        }, label: {
            VStack(alignment: .center, spacing: 6) {
                Spacer()
                Image(systemName: "chevron.right.circle")
                    .font(.system(size: 28))
                    .foregroundColor(Theme.Colors.brandGreen)
                Text(DashboardLocalization.Learn.viewAll)
                    .font(Theme.Fonts.ttRoundsBody(12, weight: 500))
                    .foregroundStyle(Theme.Colors.textPrimary)
                Spacer()
            }
            .background(Theme.Colors.cardViewBackground)
            .cornerRadius(16)
            .shadow(color: Theme.Colors.courseCardShadow, radius: 4, x: 1, y: 2)
        })
        .frame(width: idiom == .pad ? nil : DashboardLayout.courseCardWidth)
    }

    // MARK: - Section Header

    private func sectionHeader(
        title: String,
        linkText: String? = nil,
        onLinkTap: (() -> Void)? = nil
    ) -> some View {
        HStack {
            Text(title)
                .font(Theme.Fonts.ttRoundsCompressedMedium(20))
                .foregroundColor(Theme.Colors.brandCardPrimary)
                .kerning(-0.2)
            Spacer()
            if let linkText, let onLinkTap {
                Button(action: onLinkTap) {
                    HStack(spacing: 2) {
                        Text(linkText)
                            .font(Theme.Fonts.ttRoundsBody(12, weight: 500))
                            .foregroundColor(Theme.Colors.brandGreen)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.Colors.brandGreen)
                    }
                }
            }
        }
        .padding(.horizontal, DashboardLayout.horizontalPadding)
        .padding(.top, DashboardLayout.sectionHeaderTopPadding)
        .padding(.bottom, DashboardLayout.sectionHeaderBottomPadding)
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
        .previewDisplayName("DashboardView Light")

        PrimaryCourseDashboardView(
            viewModel: vm,
            programView: EmptyView(),
            openDiscoveryPage: {}
        )
        .preferredColorScheme(.dark)
        .previewDisplayName("DashboardView Dark")
    }
}
#endif
