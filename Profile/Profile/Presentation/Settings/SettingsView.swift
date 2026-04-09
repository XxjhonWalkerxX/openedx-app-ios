//
//  SettingsView.swift
//  Profile
//

import SwiftUI
import Core
import OEXFoundation
import Kingfisher
import Theme

// MARK: - Layout Constants

private enum SettingsLayout {
    static let horizontalPadding: CGFloat = 20
    static let heroTopPadding: CGFloat = 8
    static let heroMinHeight: CGFloat = 140
    static let guindaBandHeight: CGFloat = 4
    static let backButtonSize: CGFloat = 40
    static let handleWidth: CGFloat = 36
    static let handleHeight: CGFloat = 4
    static let handleTopPadding: CGFloat = 10
    static let handleBottomPadding: CGFloat = 8
    static let contentBottomPadding: CGFloat = 60
    static let circleLargeSize: CGFloat = 210
    static let circleMediumSize: CGFloat = 110
    static let circleSmallSize: CGFloat = 70
}

// MARK: - SettingsView

public struct SettingsView: View {

    @ObservedObject
    private var viewModel: SettingsViewModel

    @Environment(\.isHorizontal) private var isHorizontal

    public init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack(alignment: .top) {

            // Fondo base
            Theme.Colors.brandGreenDark
                .ignoresSafeArea()

            // Banda guinda
            Theme.Colors.guindaColor
                .frame(height: SettingsLayout.guindaBandHeight)
                .ignoresSafeArea(edges: .top)
                .frame(maxWidth: .infinity, alignment: .top)
                .zIndex(10)

            // Contenido scrollable
            ScrollView {
                VStack(spacing: 0) {
                    settingsHero
                    creamCard
                        .offset(y: -15)
                }
            }
            .zIndex(1)

            // Error snackbar
            if viewModel.showError {
                VStack {
                    Spacer()
                    SnackBarView(message: viewModel.errorMessage)
                }
                .transition(.move(edge: .bottom))
                .onAppear {
                    doAfter(Theme.Timeout.snackbarMessageLongTimeout) {
                        viewModel.errorMessage = nil
                    }
                }
                .zIndex(2)
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .navigationTitle(ProfileLocalization.settings)
    }

    // MARK: - Hero

    private var settingsHero: some View {
        ZStack(alignment: .top) {

            Theme.Gradients.heroGradient

            settingsCircles
                .allowsHitTesting(false)

            VStack(spacing: 0) {

                // Back button row
                HStack {
                    Button(action: {
                        viewModel.router.back()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(
                                width: SettingsLayout.backButtonSize,
                                height: SettingsLayout.backButtonSize
                            )
                            .background(Circle().fill(Color.white.opacity(0.14)))
                            .overlay(Circle().strokeBorder(Color.white.opacity(0.22), lineWidth: 1))
                    }
                    .padding(.leading, SettingsLayout.horizontalPadding)
                    .accessibilityIdentifier("back_button")

                    Spacer()
                }

                Spacer()

                // Título centrado
                Text(ProfileLocalization.settings)
                    .font(Theme.Fonts.ttRoundsCompressedMedium(22))
                    .foregroundColor(.white)
                    .kerning(-0.2)
                    .padding(.bottom, 24)
            }
            .padding(.top, SettingsLayout.heroTopPadding)
        }
        .frame(minHeight: SettingsLayout.heroMinHeight)
    }

    private var settingsCircles: some View {
        ZStack {
            Circle()
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 34)
                .frame(
                    width: SettingsLayout.circleLargeSize,
                    height: SettingsLayout.circleLargeSize
                )
                .offset(x: 130, y: -40)
            Circle()
                .strokeBorder(Color.white.opacity(0.05), lineWidth: 20)
                .frame(
                    width: SettingsLayout.circleMediumSize,
                    height: SettingsLayout.circleMediumSize
                )
                .offset(x: -120, y: 60)
            Circle()
                .strokeBorder(Color.white.opacity(0.07), lineWidth: 13)
                .frame(
                    width: SettingsLayout.circleSmallSize,
                    height: SettingsLayout.circleSmallSize
                )
                .offset(x: -70, y: 20)
        }
    }

    // MARK: - Cream Card

    private var creamCard: some View {
        VStack(spacing: 0) {

            // Drag handle
            Capsule()
                .fill(Theme.Colors.brandHandle)
                .frame(width: SettingsLayout.handleWidth, height: SettingsLayout.handleHeight)
                .padding(.top, SettingsLayout.handleTopPadding)
                .padding(.bottom, SettingsLayout.handleBottomPadding)

            if viewModel.isShowProgress {
                ProgressBar(size: 40, lineWidth: 8)
                    .padding(.top, 200)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, minHeight: 300)
                    .accessibilityIdentifier("progress_bar")
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    manageAccount
                    settings
                    datesAndCalendar
                    ProfileSupportInfoView(viewModel: viewModel)
                    logOutButton
                }
                .padding(.horizontal, isHorizontal ? 24 : 0)
                .padding(.bottom, SettingsLayout.contentBottomPadding)
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: 32, topTrailingRadius: 32)
                .fill(Theme.Colors.brandCream)
        )
    }

    // MARK: - Dates & Calendar

    @ViewBuilder
    private var datesAndCalendar: some View {
        VStack(alignment: .leading, spacing: 27) {
            Button(action: {
                viewModel.router.showDatesAndCalendar()
            }, label: {
                HStack {
                    Text(ProfileLocalization.datesAndCalendar)
                        .font(Theme.Fonts.titleMedium)
                    Spacer()
                    Image(systemName: "chevron.right")
                }
            })
            .accessibilityIdentifier("dates_and_calendar_cell")
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(ProfileLocalization.datesAndCalendar)
        .cardStyle(
            bgColor: Theme.Colors.textInputUnfocusedBackground,
            strokeColor: .clear
        )
    }

    // MARK: - Manage Account

    @ViewBuilder
    private var manageAccount: some View {
        VStack(alignment: .leading, spacing: 27) {
            Button(action: {
                viewModel.trackProfileVideoSettingsClicked()
                viewModel.router.showManageAccount()
            }, label: {
                HStack {
                    Text(ProfileLocalization.manageAccount)
                        .font(Theme.Fonts.titleMedium)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .flipsForRightToLeftLayoutDirection(true)
                }
            })
            .accessibilityIdentifier("video_settings_button")
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(ProfileLocalization.manageAccount)
        .cardStyle(
            bgColor: Theme.Colors.textInputUnfocusedBackground,
            strokeColor: .clear
        )
    }

    // MARK: - Settings (Video)

    @ViewBuilder
    private var settings: some View {
        Text(ProfileLocalization.settings)
            .padding(.horizontal, 24)
            .font(Theme.Fonts.labelLarge)
            .foregroundColor(Theme.Colors.textSecondary)
            .accessibilityIdentifier("settings_text")
            .padding(.top, 12)

        VStack(alignment: .leading, spacing: 27) {
            Button(action: {
                viewModel.trackProfileVideoSettingsClicked()
                viewModel.router.showVideoSettings()
            }, label: {
                HStack {
                    Text(ProfileLocalization.settingsVideo)
                        .font(Theme.Fonts.titleMedium)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .flipsForRightToLeftLayoutDirection(true)
                }
            })
            .accessibilityIdentifier("video_settings_button")
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(ProfileLocalization.settingsVideo)
        .cardStyle(
            bgColor: Theme.Colors.textInputUnfocusedBackground,
            strokeColor: .clear
        )
    }

    // MARK: - Log out

    private var logOutButton: some View {
        VStack {
            Button(action: {
                viewModel.trackLogoutClickedClicked()
                viewModel.router.presentView(
                    transitionStyle: .crossDissolve,
                    animated: true
                ) {
                    AlertView(
                        alertTitle: ProfileLocalization.LogoutAlert.title,
                        alertMessage: ProfileLocalization.LogoutAlert.text,
                        positiveAction: CoreLocalization.Alert.accept,
                        onCloseTapped: {
                            viewModel.router.dismiss(animated: true)
                        },
                        firstButtonTapped: {
                            viewModel.router.dismiss(animated: true)
                            Task {
                                await viewModel.logOut()
                            }
                        },
                        type: .logOut
                    )
                }
            }, label: {
                HStack {
                    Text(ProfileLocalization.logout)
                    Spacer()
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                }
            })
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(ProfileLocalization.logout)
            .accessibilityIdentifier("logout_button")
        }
        .foregroundColor(Theme.Colors.alert)
        .cardStyle(bgColor: Theme.Colors.textInputUnfocusedBackground, strokeColor: .clear)
        .padding(.top, 24)
        .padding(.bottom, 60)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    let router = ProfileRouterMock()
    let vm = SettingsViewModel(
        interactor: ProfileInteractor.mock,
        downloadManager: DownloadManagerMock(),
        router: router,
        analytics: ProfileAnalyticsMock(),
        coreAnalytics: CoreAnalyticsMock(),
        config: ConfigMock(),
        corePersistence: CorePersistenceMock(),
        connectivity: Connectivity(),
        coreStorage: CoreStorageMock()
    )
    SettingsView(viewModel: vm)
}
#endif

// MARK: - SettingsCell (sin cambios)

public struct SettingsCell: View {

    private var title: String
    private var description: String?

    public init(title: String, description: String?) {
        self.title = title
        self.description = description
    }

    public var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(Theme.Fonts.titleMedium)
                .accessibilityIdentifier("video_settings_text")
            if let description {
                Text(description)
                    .font(Theme.Fonts.bodySmall)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .accessibilityIdentifier("video_settings_sub_text")
            }
        }
        .foregroundColor(Theme.Colors.textPrimary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
