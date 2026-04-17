//
//  AllCoursesView.swift
//  Dashboard
//
//  Created by  Stepanok Ivan on 24.04.2024.
//

import SwiftUI
import Core
import OEXFoundation
import Theme

private enum AllCoursesLayout {
    static let horizontalPadding: CGFloat = 20
    static let headerTopPadding: CGFloat = 2
    static let headerBottomPadding: CGFloat = 4
    static let headerButtonSize: CGFloat = 34
    static let sectionSpacing: CGFloat = 10
    static let gridRowSpacing: CGFloat = 12
    static let gridColumnSpacing: CGFloat = 16
}

@MainActor
public struct AllCoursesView: View {
    
    @ObservedObject
    private var viewModel: AllCoursesViewModel
    private let router: DashboardRouter
    @Environment(\.isHorizontal) private var isHorizontal
    private var idiom: UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
    
    public init(viewModel: AllCoursesViewModel, router: DashboardRouter) {
        self.viewModel = viewModel
        self.router = router
    }
    
    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                Theme.Colors.brandCream
                    .ignoresSafeArea()
                
                if let myEnrollments = viewModel.myEnrollments,
                   myEnrollments.courses.isEmpty,
                   !viewModel.fetchInProgress,
                   !viewModel.refresh {
                    NoCoursesView(selectedMenu: viewModel.selectedMenu)
                }
                // MARK: - Page body
                VStack(alignment: .center) {
                    topHeader
                        .frameLimit(width: proxy.size.width)
                    ScrollView {
                        VStack(spacing: AllCoursesLayout.sectionSpacing) {
                            CategoryFilterView(selectedOption: $viewModel.selectedMenu)
                                .disabled(viewModel.fetchInProgress)
                                .frameLimit(width: proxy.size.width)
                            if let myEnrollments = viewModel.myEnrollments {
                                let useRelativeDates = viewModel.storage.useRelativeDates
                                LazyVGrid(columns: columns(), spacing: AllCoursesLayout.gridRowSpacing) {
                                    ForEach(
                                        Array(myEnrollments.courses.enumerated()),
                                        id: \.offset
                                    ) { index, course in
                                        Button(action: {
                                            viewModel.trackDashboardCourseClicked(
                                                courseID: course.courseID,
                                                courseName: course.name
                                            )
                                            router.showCourseScreens(
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
                                                courseStartDate: course.courseStart,
                                                courseEndDate: course.courseEnd,
                                                hasAccess: course.hasAccess,
                                                showProgress: true,
                                                useRelativeDates: useRelativeDates,
                                                visualStyle: .allCoursesCompact,
                                                fillWidth: true
                                            )
                                            .clipped()
                                        })
                                        .buttonStyle(.plain)
                                        .frame(maxWidth: .infinity, alignment: .top)
                                        .accessibilityIdentifier("course_item")
                                        .onAppear {
                                            Task {
                                                await viewModel.getMyCoursesPagination(index: index)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, AllCoursesLayout.horizontalPadding)
                                .frameLimit(width: proxy.size.width)
                            }
                            // MARK: - ProgressBar
                            if viewModel.nextPage <= viewModel.totalPages, !viewModel.refresh {
                                VStack(alignment: .center) {
                                    ProgressBar(size: 40, lineWidth: 8)
                                        .padding(.top, 20)
                                }.frame(maxWidth: .infinity,
                                        maxHeight: .infinity)
                            }
                            VStack {}.frame(height: 40)
                        }
                        .padding(.top, 4)
                    }
                    .refreshable {
                        Task {
                            await viewModel.getCourses(page: 1, refresh: true)
                        }
                    }
                    .accessibilityAction {}
                }
                .padding(.top, 4)
                
                // MARK: - Offline mode SnackBar
                OfflineSnackBarView(
                    connectivity: viewModel.connectivity,
                    reloadAction: {
                        await viewModel.getCourses(page: 1, refresh: true)
                    }
                )
                
                // MARK: - Error Alert
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
            .onFirstAppear {
                Task {
                    await viewModel.getCourses(page: 1)
                }
            }
            .onChange(of: viewModel.selectedMenu) { _ in
                Task {
                    viewModel.myEnrollments?.courses = []
                    await viewModel.getCourses(page: 1, refresh: false)
                }
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarHidden(true)
            .navigationTitle(DashboardLocalization.Learn.allCourses)
        }
    }
    
    private func columnCount() -> Int {
        (isHorizontal || idiom == .pad) ? 3 : 2
    }

    private func columns() -> [GridItem] {
        let count = columnCount()
        return Array(
            repeating: GridItem(
                .flexible(minimum: 0, maximum: .infinity),
                spacing: AllCoursesLayout.gridColumnSpacing,
                alignment: .top
            ),
            count: count
        )
    }

    private func learnTitleAndSearch() -> some View {
        EmptyView()
    }

    private var topHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                Button(action: {
                    router.back()
                }) {
                    CoreAssets.arrowLeft.swiftUIImage
                        .renderingMode(.template)
                        .foregroundColor(Theme.Colors.brandGreen)
                        .frame(width: AllCoursesLayout.headerButtonSize, height: AllCoursesLayout.headerButtonSize)
                }
                .accessibilityIdentifier("back_button")

                Spacer(minLength: 0)

                Button(action: {
                    // Visual only for now.
                }) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Theme.Colors.brandCardPrimary)
                        .frame(width: AllCoursesLayout.headerButtonSize, height: AllCoursesLayout.headerButtonSize)
                }
                .accessibilityIdentifier("search_button")
            }

            Text(DashboardLocalization.Learn.allCourses)
                .font(Theme.Fonts.ttRoundsCompressedMedium(36))
                .foregroundColor(Theme.Colors.brandCardPrimary)
                .accessibilityIdentifier("all_courses_header_text")
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.leading, 2)
        }
        .padding(.horizontal, AllCoursesLayout.horizontalPadding)
        .padding(.top, AllCoursesLayout.headerTopPadding)
        .padding(.bottom, AllCoursesLayout.headerBottomPadding)
        .background(Theme.Colors.brandCream)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(DashboardLocalization.Learn.allCourses)
    }
}

#if DEBUG
struct AllCoursesView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = AllCoursesViewModel(
            interactor: DashboardInteractor.mock,
            connectivity: Connectivity(),
            analytics: DashboardAnalyticsMock(),
            storage: CoreStorageMock()
        )
        
        AllCoursesView(viewModel: vm, router: DashboardRouterMock())
            .preferredColorScheme(.light)
            .previewDisplayName("AllCoursesView Light")
        
        AllCoursesView(viewModel: vm, router: DashboardRouterMock())
            .preferredColorScheme(.dark)
            .previewDisplayName("AllCoursesView Dark")
    }
}
#endif
