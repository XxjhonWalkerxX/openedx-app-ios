import SwiftUI
import Core
import Discussion
import Swinject
import Theme
@_spi(Advanced) import SwiftUIIntrospect

// MARK: - CourseHubContainerView

/// Reemplaza CourseContainerView. 3 tabs: Curso / Foro / Más.
/// Progress y Dates se acceden como sheets desde el hub (implementado en F3).
/// viewModel.selection sigue funcionando como puente con deep links.
public struct CourseHubContainerView: View {

    @ObservedObject public var viewModel: CourseContainerViewModel
    @ObservedObject public var courseDatesViewModel: CourseDatesViewModel
    @ObservedObject public var courseProgressViewModel: CourseProgressViewModel

    public var courseID: String
    private var title: String
    private let courseRawImage: String?

    // Collapsing header — misma mecánica que CourseContainerView
    @State private var isAnimatingForTap: Bool = false
    @State private var coordinate: CGFloat = .zero
    @State private var lastCoordinate: CGFloat = .zero
    @State private var collapsed: Bool = false
    @State private var viewHeight: CGFloat = .zero
    @State private var ignoreOffset: Bool = false
    @Namespace private var animationNamespace
    @Environment(\.isHorizontal) private var isHorizontal
    private var idiom: UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }

    // Hub navigation (3 tabs)
    @State private var hubTab: Int = 0

    private static let hubTabs: [CourseTab] = [.course, .discussion, .handounds]

    private let coordinateBoundaryLower: CGFloat = -115
    private var coordinateBoundaryHigher: CGFloat {
        let top = UIApplication.shared.windowInsets.top
        return top > 0 ? top : 40
    }

    private struct GeometryName {
        static let backButton = "backButton"
    }

    // MARK: - Init

    public init(
        viewModel: CourseContainerViewModel,
        courseDatesViewModel: CourseDatesViewModel,
        courseProgressViewModel: CourseProgressViewModel,
        courseID: String,
        title: String,
        courseRawImage: String?
    ) {
        self.viewModel = viewModel
        self.courseDatesViewModel = courseDatesViewModel
        self.courseProgressViewModel = courseProgressViewModel
        self.courseID = courseID
        self.title = title
        self.courseRawImage = courseRawImage
    }

    // MARK: - Body

    public var body: some View {
        ZStack(alignment: .top) {
            mainContent

            if viewModel.continueWith != nil && hubTab == 0 {
                VStack {
                    Spacer()
                    BrandFloatingCTA(
                        label: CourseLocalization.Courseware.continue,
                        action: { viewModel.openLastVisitedBlock() }
                    )
                }
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .navigationTitle(title)
        .onChange(of: viewModel.selection, perform: mapSelectionToHub)
        .onChange(of: hubTab, perform: mapHubToSelection)
        .onChange(of: coordinate, perform: collapseHeader)
        .background(Theme.Colors.background)
        .task(id: courseID) {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await viewModel.getCourseBlocks(courseID: courseID) }
                group.addTask { await viewModel.getCourseDeadlineInfo(courseID: courseID, withProgress: false) }
            }
        }
        switch courseDatesViewModel.eventState {
        case .removedCalendar:
            datesSuccessView(
                title: CourseLocalization.CourseDates.calendarEvents,
                message: CourseLocalization.CourseDates.calendarEventsRemoved
            )
        case .updatedCalendar:
            datesSuccessView(
                title: CourseLocalization.CourseDates.calendarEvents,
                message: CourseLocalization.CourseDates.calendarEventsUpdated
            )
        default:
            EmptyView()
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        if let courseStart = viewModel.courseStart, courseStart > Date() {
            // Curso no iniciado: mostrar solo la pantalla de outline
            CourseOutlineView(
                viewModel: viewModel,
                title: title,
                courseID: courseID,
                isVideo: false,
                selection: $viewModel.selection,
                coordinate: $coordinate,
                collapsed: $collapsed,
                viewHeight: $viewHeight,
                dateTabIndex: CourseTab.dates.rawValue
            )
        } else {
            ZStack(alignment: .top) {
                tabsView
                GeometryReader { proxy in
                    VStack(spacing: 0) {
                        CourseHeaderView(
                            viewModel: viewModel,
                            title: title,
                            collapsed: $collapsed,
                            containerWidth: proxy.size.width,
                            animationNamespace: animationNamespace,
                            isAnimatingForTap: $isAnimatingForTap,
                            courseRawImage: courseRawImage,
                            headerHeight: $viewHeight,
                            displayedTabs: Self.hubTabs
                        )
                    }
                    .offset(y: headerOffset)
                    backButton(containerWidth: proxy.size.width)
                }
            }
            .ignoresSafeArea(edges: idiom == .pad ? .leading : .top)
            .onAppear { collapsed = isHorizontal }
        }
    }

    // MARK: - Tabs

    private var tabsView: some View {
        TabView(selection: $hubTab) {
            CourseOutlineAndProgressView(
                viewModelContainer: viewModel,
                viewModelProgress: courseProgressViewModel,
                title: title,
                courseID: courseID,
                isVideo: false,
                selection: $viewModel.selection,
                coordinate: $coordinate,
                collapsed: $collapsed,
                viewHeight: $viewHeight,
                dateTabIndex: CourseTab.dates.rawValue,
                connectivity: viewModel.connectivity
            )
            .tag(0)

            DiscussionTopicsView(
                courseID: courseID,
                coordinate: $coordinate,
                collapsed: $collapsed,
                viewHeight: $viewHeight,
                viewModel: Container.shared.resolve(DiscussionTopicsViewModel.self, argument: title)!,
                router: Container.shared.resolve(DiscussionRouter.self)!
            )
            .tag(1)

            CourseMoreTabView(
                courseID: courseID,
                title: title,
                viewModel: viewModel
            )
            .tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .introspect(.scrollView, on: .iOS(.v16...)) { tabView in
            tabView.isScrollEnabled = false
        }
        .onFirstAppear {
            Task { await viewModel.tryToRefreshCookies() }
            viewModel.analytics.courseOutlineCourseTabClicked(courseId: courseID, courseName: title)
        }
    }

    // MARK: - Header Offset

    private var headerOffset: CGFloat {
        if ignoreOffset {
            return collapsed ? coordinateBoundaryLower : .zero
        }
        let range = coordinateBoundaryLower...coordinateBoundaryHigher
        if range.contains(coordinate) {
            return collapsed ? coordinateBoundaryLower : coordinate
        }
        return collapsed ? coordinateBoundaryLower : .zero
    }

    // MARK: - Back Button

    private func backButton(containerWidth: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            if !collapsed {
                let topInset = UIApplication.shared.windowInsets.top
                HStack {
                    ZStack(alignment: .center) {
                        Circle().fill(Color.white.opacity(0.20))
                        Circle().strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
                        BackNavigationButton(
                            color: .white,
                            action: { viewModel.router.back() }
                        )
                        .backViewStyle()
                        .matchedGeometryEffect(id: GeometryName.backButton, in: animationNamespace)
                        .offset(y: 7)
                    }
                    .frame(width: 30, height: 30)
                    .padding(.vertical, 8)
                    .padding(.leading, 12)
                    .padding(.top, idiom == .pad ? 0 : max(12, topInset + 8))
                    Spacer()
                }
            }
        }
    }

    // MARK: - Dates Success View

    private func datesSuccessView(title: String, message: String) -> some View {
        DatesSuccessView(title: title, message: message, selectedTab: .dates) {
            courseDatesViewModel.resetEventState()
        }
    }

    // MARK: - Selection Mapping

    /// Convierte viewModel.selection (CourseTab rawValue 0–6) → hubTab (0/1/2).
    /// Permite que deep links externos sigan funcionando.
    private func mapSelectionToHub(_ selection: Int) {
        switch selection {
        case CourseTab.discussion.rawValue:
            hubTab = 1
        case CourseTab.handounds.rawValue:
            hubTab = 2
        case CourseTab.offline.rawValue:
            hubTab = 2
        default:
            // .course / .content / .progress / .dates → Curso hub
            hubTab = 0
        }
    }

    /// Sincroniza viewModel.selection cuando el usuario cambia de tab en el hub.
    private func mapHubToSelection(_ tab: Int) {
        lastCoordinate = .zero
        ignoreOffset = true
        let targetTab: CourseTab
        switch tab {
        case 1: targetTab = .discussion
        case 2: targetTab = .handounds
        default: targetTab = .course
        }
        if viewModel.selection != targetTab.rawValue {
            viewModel.selection = targetTab.rawValue
        }
        viewModel.trackSelectedTab(
            selection: targetTab,
            courseId: courseID,
            courseName: title
        )
    }

    // MARK: - Header Collapse Logic (idéntica a CourseContainerView)

    private func collapseHeader(_ coordinate: CGFloat) {
        guard !isHorizontal else { return collapsed = true }
        let lowerBound: CGFloat = -90
        let upperBound: CGFloat = 160
        switch coordinate {
        case lowerBound...upperBound:
            if shouldAnimateHeader(coordinate: coordinate) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0.6)) {
                    ignoreOffset = false
                    collapsed = false
                }
            } else {
                lastCoordinate = coordinate
            }
        default:
            if shouldAnimateHeader(coordinate: coordinate) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0.6)) {
                    ignoreOffset = false
                    collapsed = true
                }
            } else {
                lastCoordinate = coordinate
            }
        }
    }

    private func shouldAnimateHeader(coordinate: CGFloat) -> Bool {
        let ignoringOffset: CGFloat = 120
        guard coordinate <= ignoringOffset, lastCoordinate != 0 else { return false }
        if collapsed && lastCoordinate > coordinate { return false }
        if !collapsed && lastCoordinate < coordinate { return false }
        return true
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    CourseHubContainerView(
        viewModel: CourseContainerViewModel(
            interactor: CourseInteractor.mock,
            authInteractor: AuthInteractor.mock,
            router: CourseRouterMock(),
            analytics: CourseAnalyticsMock(),
            config: ConfigMock(),
            connectivity: Connectivity(),
            manager: DownloadManagerMock(),
            storage: CourseStorageMock(),
            isActive: true,
            courseStart: nil,
            courseEnd: nil,
            enrollmentStart: nil,
            enrollmentEnd: nil,
            lastVisitedBlockID: nil,
            coreAnalytics: CoreAnalyticsMock(),
            courseHelper: CourseDownloadHelper(courseStructure: nil, manager: DownloadManagerMock())
        ),
        courseDatesViewModel: CourseDatesViewModel(
            interactor: CourseInteractor.mock,
            router: CourseRouterMock(),
            cssInjector: CSSInjectorMock(),
            connectivity: Connectivity(),
            config: ConfigMock(),
            courseID: "1",
            courseName: "a",
            analytics: CourseAnalyticsMock(),
            calendarManager: CalendarManagerMock()
        ),
        courseProgressViewModel: CourseProgressViewModel(
            interactor: CourseInteractor.mock,
            router: CourseRouterMock(),
            analytics: CourseAnalyticsMock(),
            connectivity: Connectivity()
        ),
        courseID: "",
        title: "Título del Curso",
        courseRawImage: nil
    )
    .loadFonts()
}
#endif
