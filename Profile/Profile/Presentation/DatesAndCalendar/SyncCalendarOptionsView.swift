//
//  SyncCalendarOptionsView.swift
//  Profile
//
//  Created by  Stepanok Ivan on 15.05.2024.
//

import SwiftUI
import Theme
import Core

private enum SyncCalendarLayout {
    // Tokens del sistema — ver Theme.Sizes
    static let horizontalPadding: CGFloat              = Theme.Sizes.horizontalPadding
    static let headerVerticalPaddingPortrait: CGFloat  = Theme.Sizes.headerTopPadding
    static let headerVerticalPaddingLandscape: CGFloat = Theme.Sizes.headerLandscapeTopPadding
    static let headerBottomPaddingPortrait: CGFloat    = Theme.Sizes.headerBottomPadding
    static let headerBottomPaddingLandscape: CGFloat   = Theme.Sizes.headerLandscapeBottomPadding
    static let headerMinHeightPortrait: CGFloat        = Theme.Sizes.headerPortraitMinHeight
    static let headerMinHeightLandscape: CGFloat       = Theme.Sizes.headerLandscapeHeight

    // Específicos
    static let topBandHeight: CGFloat          = 4
    static let headerTitleSpacing: CGFloat     = 12
    static let backButtonSize: CGFloat         = 54
    static let backButtonCornerRadius: CGFloat = 14
    static let contentHorizontalPadding: CGFloat = 24
    static let contentTopPadding: CGFloat      = 8
}

public struct SyncCalendarOptionsView: View {

    @ObservedObject
    private var viewModel: DatesAndCalendarViewModel

    @State private var screenDimmed: Bool = false

    @Environment(\.isHorizontal) private var isHorizontal
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    public init(viewModel: DatesAndCalendarViewModel) {
        self.viewModel = viewModel
    }

    private var isLandscapeLike: Bool { verticalSizeClass == .compact }

    private var headerTopPadding: CGFloat {
        isLandscapeLike
            ? SyncCalendarLayout.headerVerticalPaddingLandscape
            : SyncCalendarLayout.headerVerticalPaddingPortrait
    }

    private var headerBottomPadding: CGFloat {
        isLandscapeLike
            ? SyncCalendarLayout.headerBottomPaddingLandscape
            : SyncCalendarLayout.headerBottomPaddingPortrait
    }

    private var headerMinHeight: CGFloat {
        isLandscapeLike
            ? SyncCalendarLayout.headerMinHeightLandscape
            : SyncCalendarLayout.headerMinHeightPortrait
    }

    private var topHeader: some View {
        VStack(spacing: 0) {
            Theme.Colors.guindaColor
                .frame(height: SyncCalendarLayout.topBandHeight)

            HStack(alignment: .top, spacing: SyncCalendarLayout.headerTitleSpacing) {
                Button(action: { viewModel.router.back() }) {
                    Image(systemName: "chevron.left")
                        .font(Theme.Fonts.notoSans(16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(
                            width: SyncCalendarLayout.backButtonSize,
                            height: SyncCalendarLayout.backButtonSize
                        )
                        .background(
                            RoundedRectangle(
                                cornerRadius: SyncCalendarLayout.backButtonCornerRadius,
                                style: .continuous
                            )
                            .fill(Color.white.opacity(0.22))
                        )
                }
                .accessibilityIdentifier("back_button")

                Text(ProfileLocalization.DatesAndCalendar.title)
                    .font(Theme.Fonts.notoSans(30, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, SyncCalendarLayout.horizontalPadding)
            .padding(.top, headerTopPadding)
            .padding(.bottom, headerBottomPadding)
            .background(Theme.Colors.brandGreen)
        }
        .frame(maxWidth: .infinity, minHeight: headerMinHeight, alignment: .top)
        .ignoresSafeArea(edges: .top)
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                Theme.Colors.brandCream
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    topHeader

                    // MARK: Body
                    ScrollView {
                        Group {
                            if let colorSelectionColor = viewModel.colorSelection?.color {
                                optionTitle(ProfileLocalization.CalendarSync.title)
                                    .padding(.top, 24)
                                AssignmentStatusView(
                                    title: viewModel.calendarName,
                                    status: $viewModel.assignmentStatus,
                                    calendarColor: colorSelectionColor
                                )
                                .padding(.horizontal, SyncCalendarLayout.contentHorizontalPadding)
                            }
                            ToggleWithDescriptionView(
                                text: ProfileLocalization.CourseCalendarSync.title,
                                description: viewModel.reconnectRequired
                                ? ProfileLocalization.CourseCalendarSync.Description.reconnectRequired
                                : ProfileLocalization.CourseCalendarSync.Description.syncing,
                                toggle: $viewModel.courseCalendarSync,
                                showAlertIcon: $viewModel.reconnectRequired
                            )
                            .padding(.vertical, 24)
                            .padding(.horizontal, SyncCalendarLayout.contentHorizontalPadding)

                            StyledButton(
                                viewModel.reconnectRequired
                                ? ProfileLocalization.CourseCalendarSync.Button.reconnect
                                : ProfileLocalization.CourseCalendarSync.Button.changeSyncOptions,
                                action: {
                                    screenDimmed = true
                                    withAnimation(.bouncy(duration: 0.3)) {
                                        if viewModel.reconnectRequired {
                                            viewModel.showCalendaAccessDenied = true
                                        } else {
                                            viewModel.openChangeSyncView = true
                                        }
                                    }
                                },
                                color: viewModel.reconnectRequired
                                ? Theme.Colors.brandGreen
                                : Theme.Colors.brandCream,
                                textColor: viewModel.reconnectRequired
                                ? Theme.Colors.primaryButtonTextColor
                                : Theme.Colors.brandGreen,
                                borderColor: viewModel.reconnectRequired
                                ? .clear
                                : Theme.Colors.brandGreen
                            )
                            .padding(.horizontal, SyncCalendarLayout.contentHorizontalPadding)
                            if !viewModel.reconnectRequired {
                                optionTitle(ProfileLocalization.CoursesToSync.title)
                                    .padding(.top, 24)
                                coursesToSync
                                    .padding(.bottom, 24)
                            }
                            RelativeDatesToggleView(useRelativeDates: $viewModel.profileStorage.useRelativeDates)
                        }
                        .padding(.horizontal, isHorizontal ? 48 : 0)
                        .frameLimit(width: proxy.size.width)
                    }
                    .padding(.top, SyncCalendarLayout.contentTopPadding)
                    .frame(minHeight: 0, maxHeight: .infinity, alignment: .top)
                    .ignoresSafeArea(.all, edges: .bottom)
                }
                .navigationBarHidden(true)
                .navigationBarBackButtonHidden(true)

                if screenDimmed {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            viewModel.openChangeSyncView = false
                            viewModel.showCalendaAccessDenied = false
                            viewModel.showDisableCalendarSync = false
                            viewModel.courseCalendarSync = true
                            screenDimmed = false
                            viewModel.calendarName = viewModel.oldCalendarName
                            viewModel.colorSelection = viewModel.oldColorSelection
                        }
                }

                // Error Alert if needed
                if viewModel.showError {
                    ErrorAlertView(errorMessage: $viewModel.errorMessage)
                }

                if viewModel.openChangeSyncView {
                    NewCalendarView(
                        title: .changeSyncOptions,
                        viewModel: viewModel,
                        beginSyncingTapped: {
                            viewModel.openChangeSyncView = false
                            screenDimmed = false

                            guard viewModel.isInternetAvaliable else {
                                viewModel.calendarName = viewModel.oldCalendarName
                                viewModel.colorSelection = viewModel.oldColorSelection
                                return
                            }

                            Task {
                                await viewModel.deleteOldCalendarIfNeeded()
                            }
                        },
                        onCloseTapped: {
                            viewModel.openChangeSyncView = false
                            screenDimmed = false
                            viewModel.calendarName = viewModel.oldCalendarName
                            viewModel.colorSelection = viewModel.oldColorSelection
                        }
                    )
                    .transition(.move(edge: .bottom))
                    .frame(alignment: .center)
                } else if viewModel.showCalendaAccessDenied {
                    CalendarDialogView(
                        type: .calendarAccess,
                        action: {
                            viewModel.showCalendaAccessDenied = false
                            screenDimmed = false
                            viewModel.openAppSettings()
                        },
                        onCloseTapped: {
                            viewModel.showCalendaAccessDenied = false
                            screenDimmed = false
                        }
                    )
                    .transition(.move(edge: .bottom))
                    .frame(alignment: .center)
                    .onAppear {
                        screenDimmed = true
                    }
                } else if viewModel.showDisableCalendarSync {
                    CalendarDialogView(
                        type: .disableCalendarSync(calendarName: viewModel.calendarName),
                        calendarCircleColor: viewModel.colorSelection?.color,
                        calendarName: viewModel.calendarName,
                        action: {
                            Task {
                               await viewModel.clearAllData()
                            }
                        },
                        onCloseTapped: {
                            viewModel.showDisableCalendarSync = false
                            screenDimmed = false
                            viewModel.courseCalendarSync = true
                        }
                    )
                    .transition(.move(edge: .bottom))
                    .frame(alignment: .center)
                }

            }
            .ignoresSafeArea(.all, edges: .horizontal)
        }
        .onFirstAppear {
            Task {
                await viewModel.fetchCourses()
            }
        }
        .onChange(of: viewModel.courseCalendarSync) { sync in
            if !sync {
                screenDimmed = true
            }
        }
        .onAppear {
            viewModel.loadCalendarOptions()
            Task {
                await viewModel.deleteOrAddNewDatesIfNeeded()
            }
        }
    }

    // MARK: - Options Title

    private func optionTitle(_ text: String) -> some View {
        Text(text)
            .multilineTextAlignment(.leading)
            .font(Theme.Fonts.notoSans(13, weight: .medium))
            .foregroundStyle(Theme.Colors.textPrimary)
            .padding(.horizontal, SyncCalendarLayout.contentHorizontalPadding)
            .frame(
                minWidth: 0,
                maxWidth: .infinity,
                alignment: .leading
            )
    }

    // MARK: - Courses to Sync
    @ViewBuilder
    private var coursesToSync: some View {

        VStack(alignment: .leading, spacing: 27) {
            Button(action: {
                //                viewModel.trackProfileVideoSettingsClicked()
                guard viewModel.isInternetAvaliable else { return }
                viewModel.router.showCoursesToSync()
            },
                   label: {
                HStack {
                    Text(
                        String(
                            format: ProfileLocalization.CoursesToSync.syncingCourses(
                                viewModel.syncingCoursesCount
                            )
                        )
                    )
                        .font(Theme.Fonts.notoSans(15, weight: .medium))
                    Spacer()
                    Image(systemName: "chevron.right")
                }
            })
            .accessibilityIdentifier("courses_to_sync_cell")

        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(ProfileLocalization.settingsVideo)
        .cardStyle(
            bgColor: Theme.Colors.textInputUnfocusedBackground,
            strokeColor: .clear
        )
    }
}

#if DEBUG
struct SyncCalendarOptionsView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = DatesAndCalendarViewModel(
            router: ProfileRouterMock(),
            interactor: ProfileInteractor(repository: ProfileRepositoryMock()),
            profileStorage: ProfileStorageMock(),
            persistence: ProfilePersistenceMock(),
            calendarManager: CalendarManagerMock(),
            connectivity: Connectivity()
        )
        SyncCalendarOptionsView(viewModel: vm)
            .loadFonts()
    }
}
#endif
