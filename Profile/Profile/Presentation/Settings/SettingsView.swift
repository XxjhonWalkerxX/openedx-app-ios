//
//  SettingsView.swift
//  Profile
//

import SwiftUI
import Core
import OEXFoundation
import Theme

// MARK: - Layout Constants

private enum SettingsLayout {
    // Tokens del sistema — ver Theme.Sizes
    static let horizontalPadding: CGFloat            = Theme.Sizes.horizontalPadding
    static let headerVerticalPadding: CGFloat        = Theme.Sizes.headerTopPadding
    static let headerVerticalPaddingLandscape: CGFloat = Theme.Sizes.headerLandscapeTopPadding
    static let headerBottomPaddingPortrait: CGFloat  = Theme.Sizes.headerBottomPadding
    static let headerBottomPaddingLandscape: CGFloat = Theme.Sizes.headerLandscapeBottomPadding
    static let headerMinHeightPortrait: CGFloat      = Theme.Sizes.headerPortraitMinHeight
    static let headerMinHeightLandscape: CGFloat     = Theme.Sizes.headerLandscapeHeight
    static let rowMinHeight: CGFloat                 = Theme.Sizes.settingsRowMinHeight

    // Específicos de SettingsView
    static let topBandHeight: CGFloat              = 4
    static let sectionSpacing: CGFloat             = 20
    static let contentTopPadding: CGFloat          = 2
    static let contentTopPaddingLandscape: CGFloat = 16
    static let rowCornerRadius: CGFloat            = 18
    static let versionCardCornerRadius: CGFloat    = 14
    static let logoutCornerRadius: CGFloat         = 14
    static let logoutBorderWidth: CGFloat          = 2
    static let backButtonSize: CGFloat             = 54
    static let backButtonCornerRadius: CGFloat     = 14
}

// MARK: - SettingsView

public struct SettingsView: View {

    @ObservedObject
    private var viewModel: SettingsViewModel

    @Environment(\.verticalSizeClass) private var verticalSizeClass

    public init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack(alignment: .top) {
            Theme.Colors.brandCream
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topHeader

                if viewModel.isShowProgress {
                    ProgressBar(size: 40, lineWidth: 8)
                        .padding(.top, 120)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .accessibilityIdentifier("progress_bar")
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: SettingsLayout.sectionSpacing) {
                            sectionHeader(ProfileLocalization.manageAccount.uppercased())
                            settingsRow(
                                title: ProfileLocalization.manageAccount,
                                accessibilityID: "manage_account_button",
                                action: {
                                    viewModel.trackProfileVideoSettingsClicked()
                                    viewModel.router.showManageAccount()
                                }
                            )

                            sectionHeader(ProfileLocalization.settings.uppercased())
                            settingsRow(
                                title: ProfileLocalization.settingsVideo.replacingOccurrences(of: " settings", with: ""),
                                accessibilityID: "video_settings_button",
                                action: {
                                    viewModel.trackProfileVideoSettingsClicked()
                                    viewModel.router.showVideoSettings()
                                }
                            )
                            settingsRow(
                                title: ProfileLocalization.datesAndCalendar,
                                accessibilityID: "dates_and_calendar_cell",
                                action: {
                                    viewModel.router.showDatesAndCalendar()
                                }
                            )

                            sectionHeader(ProfileLocalization.supportInfo.uppercased())
                            settingsRow(
                                title: ProfileLocalization.contact,
                                accessibilityID: "contact_support",
                                action: {
                                    guard let emailURL = viewModel.contactSupport(),
                                          UIApplication.shared.canOpenURL(emailURL) else {
                                        viewModel.errorMessage = ProfileLocalization.Error.cannotSendEmail
                                        return
                                    }
                                    viewModel.trackEmailSupportClicked()
                                    UIApplication.shared.open(emailURL)
                                }
                            )

                            versionCard
                            logoutButton
                        }
                        .padding(.horizontal, SettingsLayout.horizontalPadding)
                        .padding(.top, contentTopPadding)
                        .padding(.bottom, 44)
                    }
                    .scrollIndicators(.hidden)
                }
            }

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

    private var topHeader: some View {
        VStack(spacing: 0) {
            Theme.Colors.guindaColor
                .frame(height: SettingsLayout.topBandHeight)

            HStack(alignment: .top, spacing: 12) {
                Button(action: {
                    viewModel.router.back()
                }) {
                    Image(systemName: "chevron.left")
                        .font(Theme.Fonts.ttRoundsSemibold(18))
                        .foregroundColor(.white)
                        .frame(width: SettingsLayout.backButtonSize, height: SettingsLayout.backButtonSize)
                        .background(
                            RoundedRectangle(cornerRadius: SettingsLayout.backButtonCornerRadius, style: .continuous)
                                .fill(Color.white.opacity(0.22))
                        )
                }
                .accessibilityIdentifier("back_button")

                VStack(alignment: .leading, spacing: 2) {
                    Text(ProfileLocalization.settings)
                        .font(Theme.Fonts.ttRoundsCompressedMedium(38))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text("Personaliza tu experiencia")
                        .font(Theme.Fonts.labelLarge)
                        .fontWeight(.semibold)
                        .opacity(0.95)
                }
                .foregroundColor(.white)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, SettingsLayout.horizontalPadding)
            .padding(.top, headerTopPadding)
            .padding(.bottom, headerBottomPadding)
            .background(Theme.Colors.brandGreen)
        }
        .frame(maxWidth: .infinity, minHeight: headerMinHeight, alignment: .top)
        .ignoresSafeArea(edges: .top)
    }

    private var headerTopPadding: CGFloat {
        if isLandscapeLike {
            return SettingsLayout.headerVerticalPaddingLandscape
        } else {
            return SettingsLayout.headerVerticalPadding
        }
    }

    private var headerBottomPadding: CGFloat {
        if isLandscapeLike {
            return SettingsLayout.headerBottomPaddingLandscape
        } else {
            return SettingsLayout.headerBottomPaddingPortrait
        }
    }

    private var headerMinHeight: CGFloat {
        if isLandscapeLike {
            return SettingsLayout.headerMinHeightLandscape
        } else {
            return SettingsLayout.headerMinHeightPortrait
        }
    }

    private var isLandscapeLike: Bool {
        verticalSizeClass == .compact
    }

    private var contentTopPadding: CGFloat {
        if isLandscapeLike {
            return SettingsLayout.contentTopPaddingLandscape
        } else {
            return SettingsLayout.contentTopPadding
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(Theme.Fonts.labelLarge)
            .fontWeight(.semibold)
            .tracking(0.3)
            .foregroundColor(Theme.Colors.brandGreen)
            .padding(.leading, 2)
    }

    private func settingsRow(
        title: String,
        accessibilityID: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(Theme.Fonts.titleMedium)
                    .foregroundColor(Theme.Colors.brandCardPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(Theme.Colors.brandGreen)
                    .flipsForRightToLeftLayoutDirection(true)
                    .font(Theme.Fonts.ttRoundsSemibold(15))
            }
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity, minHeight: SettingsLayout.rowMinHeight)
            .background(
                RoundedRectangle(cornerRadius: SettingsLayout.rowCornerRadius, style: .continuous)
                    .fill(Theme.Colors.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: SettingsLayout.rowCornerRadius, style: .continuous)
                    .stroke(Color.black.opacity(0.04), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 5, x: 0, y: 2)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityIdentifier(accessibilityID)
    }

    private var versionCard: some View {
        Button(action: {
            if viewModel.versionState != .actual {
                viewModel.openAppStore()
            }
        }) {
            VStack(spacing: 8) {
                Text("\(ProfileLocalization.Settings.version) \(viewModel.currentVersion)")
                    .font(Theme.Fonts.titleMedium)
                    .foregroundColor(Theme.Colors.brandCardPrimary)

                switch viewModel.versionState {
                case .actual:
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Theme.Colors.brandGreen)
                        Text(ProfileLocalization.Settings.upToDate)
                            .font(Theme.Fonts.labelLarge)
                            .foregroundColor(Theme.Colors.brandCardMedium)
                    }
                case .updateNeeded:
                    Text("\(ProfileLocalization.Settings.tapToUpdate) \(viewModel.latestVersion)")
                        .font(Theme.Fonts.labelLarge)
                        .foregroundColor(Theme.Colors.accentColor)
                case .updateRequired:
                    Text(ProfileLocalization.Settings.tapToInstall)
                        .font(Theme.Fonts.labelLarge)
                        .foregroundColor(Theme.Colors.accentColor)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: SettingsLayout.versionCardCornerRadius, style: .continuous)
                    .fill(Theme.Colors.brandCreamStrong)
            )
        }
        .disabled(viewModel.versionState == .actual)
        .accessibilityIdentifier("version_button")
    }

    private var logoutButton: some View {
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
        }) {
            HStack(spacing: 8) {
                Text(ProfileLocalization.logout)
                    .font(Theme.Fonts.titleMedium)
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(Theme.Fonts.ttRoundsSemibold(18))
            }
            .foregroundColor(Theme.Colors.guindaColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: SettingsLayout.logoutCornerRadius, style: .continuous)
                    .fill(Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: SettingsLayout.logoutCornerRadius, style: .continuous)
                    .stroke(Theme.Colors.guindaColor, lineWidth: SettingsLayout.logoutBorderWidth)
            )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(ProfileLocalization.logout)
        .accessibilityIdentifier("logout_button")
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
