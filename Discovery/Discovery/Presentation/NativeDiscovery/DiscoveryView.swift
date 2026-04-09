//
//  DiscoveryView.swift
//  Discovery
//

import SwiftUI
import Core
import OEXFoundation
import Theme

private let heroHeight: CGFloat = 200
private let heroOverlap: CGFloat = 28

public struct DiscoveryView: View {

    @StateObject
    private var viewModel: DiscoveryViewModel
    private var router: DiscoveryRouter
    @State private var searchQuery: String = ""

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

    public var body: some View {
        ZStack(alignment: .top) {

            // Colorea el área de la status bar con verde (igual que Android)
            Theme.Colors.brandGreenDark
                .ignoresSafeArea(.all, edges: .top)

            // [A] Hero verde — fijo, no scrollea
            DiscoveryHeroView {
                router.showSettings()
            }

            // [B] Contenido scrollable
            ScrollView {
                LazyVStack(spacing: 0) {

                    // Espaciador para que el contenido empiece bajo el hero
                    Color.clear
                        .frame(height: heroHeight - heroOverlap)

                    // Sheet cream con bordes redondeados arriba
                    VStack(spacing: 0) {

                        // Drag handle
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Theme.Colors.brandHandle)
                            .frame(width: 36, height: 4)
                            .padding(.top, 12)
                            .padding(.bottom, 16)

                        // Barra de búsqueda (tap → SearchView)
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                                .foregroundColor(Theme.Colors.brandGreen)
                            Text(DiscoveryLocalization.search)
                                .font(Theme.Fonts.ttRoundsBody(13))
                                .foregroundColor(Theme.Colors.brandCardSecondary)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 46)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .onTapGesture {
                            router.showDiscoverySearch(searchQuery: searchQuery)
                            viewModel.discoverySearchBarClicked()
                        }
                        .padding(.horizontal, 20)

                        // Header "Todos los cursos" + contador
                        HStack {
                            Text("Todos los cursos")
                                .font(Theme.Fonts.ttRoundsCompressedMedium(20))
                                .foregroundColor(Theme.Colors.brandCardPrimary)
                                .kerning(-0.2)
                            Spacer()
                            Text("\(viewModel.courses.count) disponibles")
                                .font(Theme.Fonts.ttRoundsBody(12))
                                .foregroundColor(Theme.Colors.brandCardSecondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 12)

                        // Lista de tarjetas
                        ForEach(Array(viewModel.courses.enumerated()), id: \.offset) { index, course in
                            DiscoveryCourseCard(
                                course: course,
                                index: index,
                                onClick: {
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
                            .padding(.horizontal, 20)
                            .padding(.bottom, 10)
                            .onAppear {
                                Task {
                                    await viewModel.getDiscoveryCourses(index: index)
                                }
                            }
                        }

                        // Indicador de carga para paginación
                        if viewModel.nextPage <= viewModel.totalPages {
                            ProgressView()
                                .padding(.top, 20)
                                .tint(Theme.Colors.brandGreen)
                        }

                        // Espaciador inferior (fondo brandCream)
                        Theme.Colors.brandCream
                            .frame(height: 80)
                    }
                    .frame(maxWidth: .infinity)
                    .background(Theme.Colors.brandCream)
                    .clipShape(DiscoverySheetShape(radius: 32))
                }
            }
            .refreshable {
                viewModel.totalPages = 1
                viewModel.nextPage = 1
                await viewModel.discovery(page: 1, withProgress: false)
            }

            // [C] Panel de login si no está autenticado
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
            }

            // [D] Offline snackbar
            OfflineSnackBarView(
                connectivity: viewModel.connectivity,
                reloadAction: {
                    await viewModel.discovery(page: 1, withProgress: false)
                }
            )

            // [E] Error snackbar
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
            }

        }
        .navigationBarHidden(sourceScreen != .startup)
        .background(Theme.Colors.brandCream.ignoresSafeArea())
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
}

// MARK: - Shape para esquinas redondeadas solo arriba

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
            .previewDisplayName("DiscoveryView Light")
    }
}
#endif
