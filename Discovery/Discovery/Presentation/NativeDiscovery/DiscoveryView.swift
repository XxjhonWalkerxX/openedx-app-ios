//
//  DiscoveryView.swift
//  Discovery
//

import SwiftUI
import Core
import OEXFoundation
import Theme

private let heroHeight: CGFloat = 240
private let heroOverlap: CGFloat = 15

// MARK: - Filtros de categoría

private enum DiscoveryCategoryFilter: String, CaseIterable {
    case todos        = "Todos"
    case salud        = "Salud"
    case seguridad    = "Seguridad"
    case educacion    = "Educación"
    case tecnologia   = "Tecnología"
    case administracion = "Administración"

    func matches(_ course: CourseItem) -> Bool {
        guard self != .todos else { return true }
        let text = (course.name + " " + course.org).lowercased()
        switch self {
        case .todos: return true
        case .salud:
            return text.contains("salud") || text.contains("health") || text.contains("enferm")
        case .seguridad:
            return text.contains("seguridad") || text.contains("prevenci") || text.contains("riesgo")
        case .educacion:
            return text.contains("educaci") || text.contains("enseñ") || text.contains("docen") || text.contains("maestr") || text.contains("pedagog")
        case .tecnologia:
            return text.contains("tecnolog") || text.contains("digital") || text.contains("programaci") || text.contains("informát") || text.contains("software") || text.contains("datos")
        case .administracion:
            return text.contains("administr") || text.contains("gestión") || text.contains("gesti") || text.contains("finanz") || text.contains("contab")
        }
    }
}

// MARK: - Tarjeta editorial destacada

private struct FeaturedCourseCard: View {
    let course: CourseItem
    let onClick: () -> Void

    var body: some View {
        Button(action: onClick) {
            ZStack(alignment: .bottomLeading) {
                // Fondo guinda profundo con anillos decorativos
                ZStack {
                    Theme.Colors.guindaDeep
                    DecorativeRings()
                }
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 8) {
                    // Badge
                    HStack(spacing: 5) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 9))
                            .foregroundColor(Theme.Colors.brandGreenLight)
                        Text("Destacado esta semana")
                            .font(Theme.Fonts.notoSans(10, weight: .semibold))
                            .foregroundColor(Theme.Colors.brandGreenLight)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.white.opacity(0.1)))

                    // Org
                    Text(course.org)
                        .font(Theme.Fonts.notoSans(10, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.65))
                        .lineLimit(1)

                    // Título
                    Text(course.name)
                        .font(Theme.Fonts.notoSans(18, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    // CTA
                    HStack(spacing: 6) {
                        Text("Ver curso")
                            .font(Theme.Fonts.notoSans(12, weight: .semibold))
                            .foregroundColor(Theme.Colors.guindaDeep)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Theme.Colors.guindaDeep)
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 34)
                    .background(Capsule().fill(Color.white))
                }
                .padding(18)
            }
            .frame(height: 180)
        }
        .buttonStyle(.plain)
        .shadow(color: Theme.Colors.guindaDeep.opacity(0.3), radius: 10, x: 0, y: 4)
    }
}

// MARK: - DiscoveryView

public struct DiscoveryView: View {

    @StateObject
    private var viewModel: DiscoveryViewModel
    private var router: DiscoveryRouter
    @State private var searchQuery: String = ""
    @State private var selectedCategory: DiscoveryCategoryFilter = .todos

    private var sourceScreen: LogistrationSourceScreen

    public init(
        viewModel: DiscoveryViewModel,
        router: DiscoveryRouter,
        searchQuery: String? = nil,
        sourceScreen: LogistrationSourceScreen = .default
    ) {
        self._viewModel = StateObject(wrappedValue: { viewModel }())
        self.router = router
        self._searchQuery = State<String>(initialValue: searchQuery ?? "")
        self.sourceScreen = sourceScreen
    }

    private var filteredCourses: [CourseItem] {
        guard selectedCategory != .todos else { return viewModel.courses }
        return viewModel.courses.filter { selectedCategory.matches($0) }
    }

    public var body: some View {
        ZStack(alignment: .top) {

            // 1. Fondo verde
            Theme.Colors.brandGreenDark
                .ignoresSafeArea()

            // 2. Franja guinda top
            Theme.Colors.guindaColor
                .frame(height: 4)
                .ignoresSafeArea(edges: .top)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .zIndex(10)

            // 3. Contenido scrolleable
            ScrollView {
                VStack(spacing: 0) {

                    // Hero
                    DiscoveryHeroView(
                        courseCount: viewModel.courses.count,
                        onSearchTap: {
                            HapticFeedback.selection()
                            router.showDiscoverySearch(searchQuery: searchQuery)
                            viewModel.discoverySearchBarClicked()
                        }
                    )
                    .frame(height: heroHeight)

                    // Sheet cream
                    VStack(spacing: 0) {

                        // Drag handle
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Theme.Colors.brandHandle)
                            .frame(width: 36, height: 4)
                            .padding(.top, 12)
                            .padding(.bottom, 14)

                        // Chips de categoría
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(DiscoveryCategoryFilter.allCases, id: \.rawValue) { cat in
                                    categoryChip(cat)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 2)
                        }
                        .padding(.bottom, 16)

                        // Tarjeta destacada (solo en "Todos" con cursos cargados)
                        if selectedCategory == .todos, let featured = viewModel.courses.first {
                            FeaturedCourseCard(course: featured, onClick: {
                                HapticFeedback.impact(.medium)
                                viewModel.discoveryCourseClicked(
                                    courseID: featured.courseID,
                                    courseName: featured.name
                                )
                                router.showCourseDetais(
                                    courseID: featured.courseID,
                                    title: featured.name
                                )
                            })
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        }

                        // Header sección
                        HStack {
                            Text(selectedCategory == .todos ? "Todos los cursos" : selectedCategory.rawValue)
                                .font(Theme.Fonts.notoSans(16, weight: .semibold))
                                .foregroundColor(Theme.Colors.brandCardPrimary)
                            Spacer()
                            Text("\(filteredCourses.count) cursos")
                                .font(Theme.Fonts.notoSans(12))
                                .foregroundColor(Theme.Colors.brandCardSecondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)

                        // Grid 2 columnas
                        LazyVGrid(
                            columns: [GridItem(.flexible()), GridItem(.flexible())],
                            spacing: 12
                        ) {
                            ForEach(Array(filteredCourses.enumerated()), id: \.offset) { index, course in
                                DiscoveryCourseCard(
                                    course: course,
                                    index: index,
                                    isGrid: true,
                                    onClick: {
                                        HapticFeedback.impact(.soft)
                                        viewModel.discoveryCourseClicked(
                                            courseID: course.courseID,
                                            courseName: course.name
                                        )
                                        router.showCourseDetais(
                                            courseID: course.courseID,
                                            title: course.name
                                        )
                                    }
                                )
                                .onAppear {
                                    Task {
                                        await viewModel.getDiscoveryCourses(index: index)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        // Loader paginación
                        if viewModel.nextPage <= viewModel.totalPages && !viewModel.courses.isEmpty {
                            ProgressView()
                                .padding(.top, 20)
                                .tint(Theme.Colors.brandGreen)
                        }

                        // Relleno inferior
                        Theme.Colors.brandCream
                            .frame(maxWidth: .infinity, minHeight: 200)
                    }
                    .frame(maxWidth: .infinity)
                    .background(Theme.Colors.brandCream)
                    .clipShape(DiscoverySheetShape(radius: 32))
                    .padding(.top, -heroOverlap)
                }
            }
            .refreshable {
                viewModel.totalPages = 1
                viewModel.nextPage = 1
                await viewModel.discovery(page: 1, withProgress: false)
            }
            .zIndex(1)

            // 4. Botón settings overlay
            VStack {
                HStack {
                    Spacer()
                    Button(action: { router.showSettings() }) {
                        CoreAssets.settings.swiftUIImage
                            .renderingMode(.template)
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color.white.opacity(0.14)))
                            .overlay(Circle().strokeBorder(Color.white.opacity(0.22), lineWidth: 1))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                Spacer()
            }
            .zIndex(5)

            // 5. Panel login si no autenticado
            if !viewModel.userloggedIn {
                LogistrationBottomView(
                    ssoEnabled: viewModel.config.uiComponents.samlSSOLoginEnabled
                ) { buttonAction in
                    switch buttonAction {
                    case .signIn:
                        viewModel.router.showLoginScreen(sourceScreen: .discovery)
                    case .register:
                        viewModel.router.showRegisterScreen(sourceScreen: .discovery)
                    case .signInWithSSO:
                        viewModel.router.showLoginScreen(sourceScreen: .discovery)
                    }
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
                .zIndex(2)
            }

            // 6. Offline snackbar
            OfflineSnackBarView(
                connectivity: viewModel.connectivity,
                reloadAction: {
                    await viewModel.discovery(page: 1, withProgress: false)
                }
            )
            .zIndex(3)

            // 7. Error snackbar
            if viewModel.showError {
                VStack {
                    Spacer()
                    SnackBarView(message: viewModel.errorMessage)
                }
                .padding(.bottom, viewModel.connectivity.isInternetAvaliable
                         ? 0 : OfflineSnackBarView.height)
                .transition(.move(edge: .bottom))
                .onAppear {
                    doAfter(Theme.Timeout.snackbarMessageLongTimeout) {
                        viewModel.errorMessage = nil
                    }
                }
                .zIndex(3)
            }
        }
        .navigationBarHidden(sourceScreen != .startup)
        .onFirstAppear {
            if !searchQuery.isEmpty {
                router.showDiscoverySearch(searchQuery: searchQuery)
                searchQuery = ""
            }
            Task {
                await viewModel.discovery(page: 1)
                if case let .courseDetail(courseID, courseTitle) = sourceScreen {
                    viewModel.router.showCourseDetais(courseID: courseID, title: courseTitle)
                }
            }
        }
    }

    // MARK: - Chip de categoría

    @ViewBuilder
    private func categoryChip(_ cat: DiscoveryCategoryFilter) -> some View {
        let isSelected = selectedCategory == cat
        Button {
            HapticFeedback.selection()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                selectedCategory = cat
            }
        } label: {
            Text(cat.rawValue)
                .font(Theme.Fonts.notoSans(12, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : Theme.Colors.brandCardPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule().fill(isSelected ? Theme.Colors.guindaColor : Color.white)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(
                            isSelected ? Color.clear : Theme.Colors.brandDivider,
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Shape esquinas redondeadas arriba

private struct DiscoverySheetShape: Shape {
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#if DEBUG
struct DiscoveryView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = DiscoveryViewModel(
            router: DiscoveryRouterMock(),
            config: ConfigMock(),
            interactor: DiscoveryInteractor.mock,
            connectivity: Connectivity(),
            analytics: DiscoveryAnalyticsMock(),
            storage: CoreStorageMock()
        )
        let router = DiscoveryRouterMock()

        DiscoveryView(viewModel: vm, router: router)
            .preferredColorScheme(.light)
            .previewDisplayName("DiscoveryView Fase 3")
    }
}
#endif
