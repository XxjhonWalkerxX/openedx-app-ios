//
//  DatesAndCalendarView.swift
//  Profile
//
//  Created by  Stepanok Ivan on 12.04.2024.
//

import SwiftUI
import Theme
import Core

private enum DatesAndCalendarLayout {
    // Tokens del sistema — ver Theme.Sizes
    static let horizontalPadding: CGFloat            = Theme.Sizes.horizontalPadding
    static let headerVerticalPadding: CGFloat        = Theme.Sizes.headerTopPadding
    static let headerVerticalPaddingLandscape: CGFloat = Theme.Sizes.headerLandscapeTopPadding
    static let headerBottomPaddingPortrait: CGFloat  = Theme.Sizes.headerBottomPadding
    static let headerBottomPaddingLandscape: CGFloat = Theme.Sizes.headerLandscapeBottomPadding
    static let headerMinHeightPortrait: CGFloat      = Theme.Sizes.headerPortraitMinHeight
    static let headerMinHeightLandscape: CGFloat     = Theme.Sizes.headerLandscapeHeight

    // Específicos de DatesAndCalendarView
    static let topBandHeight: CGFloat              = 4
    static let sectionSpacing: CGFloat             = 20
    static let contentTopPadding: CGFloat          = 2
    static let contentTopPaddingLandscape: CGFloat = 16
    static let cardCornerRadius: CGFloat           = 22
    static let cardShadowRadius: CGFloat           = 5
    static let cardShadowYOffset: CGFloat          = 2
    static let cardStrokeOpacity: CGFloat          = 0.04
    static let cardShadowOpacity: CGFloat          = 0.06
    static let buttonCornerRadius: CGFloat         = 14
}

public struct DatesAndCalendarView: View {
    
    @ObservedObject
    private var viewModel: DatesAndCalendarViewModel
    
    @State private var screenDimmed: Bool = false
    
    @Environment(\.isHorizontal) private var isHorizontal
    
    public init(viewModel: DatesAndCalendarViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                Theme.Colors.brandCream
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    topHeader

                    ScrollView {
                        VStack(alignment: .leading, spacing: DatesAndCalendarLayout.sectionSpacing) {
                            calendarSyncCard
                            relativeDatesCard
                        }
                        .padding(.horizontal, DatesAndCalendarLayout.horizontalPadding)
                        .padding(.top, contentTopPadding)
                        .padding(.bottom, 44)
                    }
                    .frameLimit(width: proxy.size.width)
                    .scrollIndicators(.hidden)
                }
                .navigationBarHidden(true)
                .navigationBarBackButtonHidden(true)
                
                if screenDimmed {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            viewModel.openNewCalendarView = false
                            screenDimmed = false
                            viewModel.showCalendaAccessDenied = false
                            viewModel.calendarName = viewModel.oldCalendarName
                            viewModel.colorSelection = viewModel.oldColorSelection
                        }
                }
                
                // Error Alert if needed
                if viewModel.showError {
                    ErrorAlertView(errorMessage: $viewModel.errorMessage)
                }
                
                if viewModel.openNewCalendarView {
                    NewCalendarView(
                        title: .newCalendar,
                        viewModel: viewModel,
                        beginSyncingTapped: {
                            guard viewModel.isInternetAvaliable else {
                                viewModel.openNewCalendarView = false
                                screenDimmed = false
                                viewModel.calendarName = viewModel.oldCalendarName
                                viewModel.colorSelection = viewModel.oldColorSelection
                                return
                            }
                            if viewModel.calendarName == "" {
                                viewModel.calendarName = viewModel.calendarNameHint
                            }
                            viewModel.saveCalendarOptions()
                            viewModel.router.back(animated: false)
                            viewModel.router.showSyncCalendarOptions()
                        },
                        onCloseTapped: {
                            viewModel.calendarName = viewModel.oldCalendarName
                            viewModel.colorSelection = viewModel.oldColorSelection
                            viewModel.openNewCalendarView = false
                            screenDimmed = false
                        }
                    )
                    .transition(.move(edge: .bottom))
                    .frame(alignment: .center)
                    .onAppear {
                        screenDimmed = true
                    }
                }
                
                if viewModel.showCalendaAccessDenied {
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
                }
                
            }
            .ignoresSafeArea(.all, edges: .horizontal)
        }
    }

    private var topHeader: some View {
        VStack(spacing: 0) {
            Theme.Colors.guindaColor
                .frame(height: DatesAndCalendarLayout.topBandHeight)

            HStack(alignment: .top, spacing: 12) {
                Button(action: {
                    viewModel.router.back()
                }) {
                    Image(systemName: "chevron.left")
                        .font(Theme.Fonts.notoSans(16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 54, height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: DatesAndCalendarLayout.buttonCornerRadius, style: .continuous)
                                .fill(Color.white.opacity(0.22))
                        )
                }
                .accessibilityIdentifier("back_button")

                Text(ProfileLocalization.DatesAndCalendar.title)
                    .font(Theme.Fonts.notoSans(30, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .foregroundColor(.white)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, DatesAndCalendarLayout.horizontalPadding)
            .padding(.top, headerTopPadding + 10)
            .padding(.bottom, headerBottomPadding)
            .background(Theme.Colors.brandGreen)
        }
        .frame(maxWidth: .infinity, minHeight: headerMinHeight, alignment: .top)
        .ignoresSafeArea(edges: .top)
    }

    private var headerTopPadding: CGFloat {
        isLandscapeLike ? DatesAndCalendarLayout.headerVerticalPaddingLandscape : DatesAndCalendarLayout.headerVerticalPadding
    }

    private var headerBottomPadding: CGFloat {
        isLandscapeLike ? DatesAndCalendarLayout.headerBottomPaddingLandscape : DatesAndCalendarLayout.headerBottomPaddingPortrait
    }

    private var headerMinHeight: CGFloat {
        isLandscapeLike ? DatesAndCalendarLayout.headerMinHeightLandscape : DatesAndCalendarLayout.headerMinHeightPortrait
    }

    private var contentTopPadding: CGFloat {
        isLandscapeLike ? DatesAndCalendarLayout.contentTopPaddingLandscape : DatesAndCalendarLayout.contentTopPadding
    }

    private var isLandscapeLike: Bool {
        isHorizontal
    }

    // MARK: - Calendar Sync Card
    private var calendarSyncCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(ProfileLocalization.CalendarSync.title)
                .font(Theme.Fonts.notoSans(13, weight: .medium))
                .foregroundColor(Theme.Colors.brandCardMedium)
                .padding(.leading, 2)

            VStack(alignment: .center, spacing: 16) {
                CoreAssets.calendarSyncIcon.swiftUIImage
                    .foregroundStyle(Theme.Colors.brandGreen)
                    .padding(.bottom, 4)

                Text(ProfileLocalization.CalendarSync.title)
                    .font(Theme.Fonts.notoSans(15, weight: .medium))
                    .foregroundColor(Theme.Colors.brandCardPrimary)
                    .accessibilityIdentifier("calendar_sync_title")

                Text(ProfileLocalization.CalendarSync.description)
                    .font(Theme.Fonts.notoSans(14, weight: .regular))
                    .foregroundColor(Theme.Colors.brandCardPrimary)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("calendar_sync_description")

                StyledButton(
                    ProfileLocalization.CalendarSync.button,
                    action: {
                        Task {
                            await viewModel.requestCalendarPermission()
                        }
                    },
                    color: Theme.Colors.brandGreen,
                    textColor: Theme.Colors.white,
                    borderColor: .clear,
                    horizontalPadding: true
                )
                .accessibilityIdentifier("calendar_sync_button")
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: DatesAndCalendarLayout.cardCornerRadius, style: .continuous)
                    .fill(Theme.Colors.brandCreamStrong)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DatesAndCalendarLayout.cardCornerRadius, style: .continuous)
                    .stroke(Color.black.opacity(DatesAndCalendarLayout.cardStrokeOpacity), lineWidth: 1)
            )
            .shadow(color: .black.opacity(DatesAndCalendarLayout.cardShadowOpacity), radius: DatesAndCalendarLayout.cardShadowRadius, x: 0, y: DatesAndCalendarLayout.cardShadowYOffset)
        }
    }

    private var relativeDatesCard: some View {
        RelativeDatesToggleView(useRelativeDates: $viewModel.profileStorage.useRelativeDates)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: DatesAndCalendarLayout.cardCornerRadius, style: .continuous)
                    .fill(Theme.Colors.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DatesAndCalendarLayout.cardCornerRadius, style: .continuous)
                    .stroke(Color.black.opacity(DatesAndCalendarLayout.cardStrokeOpacity), lineWidth: 1)
            )
            .shadow(color: .black.opacity(DatesAndCalendarLayout.cardShadowOpacity), radius: DatesAndCalendarLayout.cardShadowRadius, x: 0, y: DatesAndCalendarLayout.cardShadowYOffset)
    }
}

#if DEBUG
struct DatesAndCalendarView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = DatesAndCalendarViewModel(
            router: ProfileRouterMock(),
            interactor: ProfileInteractor(repository: ProfileRepositoryMock()),
            profileStorage: ProfileStorageMock(),
            persistence: ProfilePersistenceMock(),
            calendarManager: CalendarManagerMock(),
            connectivity: Connectivity()
        )
        DatesAndCalendarView(viewModel: vm)
            .loadFonts()
    }
}
#endif
