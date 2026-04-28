//
//  SettingsView.swift
//  Profile
//
//  Fase 7 — Settings rediseño completo
//  7.1 InnerNavBar back pill + grupos card uppercase guinda + version card brandCreamStrong + logout outline destructive
//

import SwiftUI
import Core
import OEXFoundation
import Theme

// MARK: - Layout Constants

private enum SettingsLayout {
    static let horizontalPadding: CGFloat = Theme.Sizes.horizontalPadding
    static let headerVerticalPadding: CGFloat = Theme.Sizes.headerTopPadding
    static let headerVerticalPaddingLandscape: CGFloat = Theme.Sizes.headerLandscapeTopPadding
    static let headerBottomPaddingPortrait: CGFloat = Theme.Sizes.headerBottomPadding
    static let headerBottomPaddingLandscape: CGFloat = Theme.Sizes.headerLandscapeBottomPadding
    static let headerMinHeightPortrait: CGFloat = Theme.Sizes.headerPortraitMinHeight
    static let headerMinHeightLandscape: CGFloat = Theme.Sizes.headerLandscapeHeight
    static let rowMinHeight: CGFloat = Theme.Sizes.settingsRowMinHeight

    static let topBandHeight: CGFloat = 4
    static let sectionSpacing: CGFloat = 6
    static let groupSpacing: CGFloat = 20
    static let rowCornerRadius: CGFloat = Theme.Sizes.radiusCard
    static let versionCardCornerRadius: CGFloat = Theme.Sizes.radiusCard
    static let logoutCornerRadius: CGFloat = Theme.Sizes.radiusCard
    static let logoutBorderWidth: CGFloat = 1.5
    static let backButtonSize: CGFloat = 40
    static let backButtonCornerRadius: CGFloat = 20
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
                        VStack(alignment: .leading, spacing: SettingsLayout.groupSpacing) {

                            // MARK: Grupo Cuenta
                            settingsGroup(header: ProfileLocalization.manageAccount.uppercased()) {
                                settingsRow(
                                    icon: "person.text.rectangle",
                                    title: ProfileLocalization.manageAccount,
                                    accessibilityID: "manage_account_button"
                                ) {
                                    HapticFeedback.selection()
                                    viewModel.trackProfileVideoSettingsClicked()
                                    viewModel.router.showManageAccount()
                                }
                            }

                            // MARK: Grupo Configuración
                            settingsGroup(header: ProfileLocalization.settings.uppercased()) {
                                settingsRow(
                                    icon: "play.rectangle",
                                    title: ProfileLocalization.settingsVideo.replacingOccurrences(of: " settings", with: ""),
                                    accessibilityID: "video_settings_button"
                                ) {
                                    HapticFeedback.selection()
                                    viewModel.trackProfileVideoSettingsClicked()
                                    viewModel.router.showVideoSettings()
                                }
                                rowDivider
                                settingsRow(
                                    icon: "calendar",
                                    title: ProfileLocalization.datesAndCalendar,
                                    accessibilityID: "dates_and_calendar_cell"
                                ) {
                                    HapticFeedback.selection()
                                    viewModel.router.showDatesAndCalendar()
                                }
                            }

                            // MARK: Grupo Soporte
                            settingsGroup(header: ProfileLocalization.supportInfo.uppercased()) {
                                settingsRow(
                                    icon: "envelope",
                                    title: ProfileLocalization.contact,
                                    accessibilityID: "contact_support"
                                ) {
                                    guard let emailURL = viewModel.contactSupport(),
                                          UIApplication.shared.canOpenURL(emailURL) else {
                                        viewModel.errorMessage = ProfileLocalization.Error.cannotSendEmail
                                        return
                                    }
                                    HapticFeedback.selection()
                                    viewModel.trackEmailSupportClicked()
                                    UIApplication.shared.open(emailURL)
                                }
                            }

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

    // MARK: - Header

    private var topHeader: some View {
        VStack(spacing: 0) {
            Theme.Colors.guindaColor
                .frame(height: SettingsLayout.topBandHeight)

            HStack(alignment: .top, spacing: 12) {
                Button(action: {
                    viewModel.router.back()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .frame(
                            width: SettingsLayout.backButtonSize,
                            height: SettingsLayout.backButtonSize
                        )
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.2))
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                        )
                }
                .accessibilityIdentifier("back_button")
                .accessibilityLabel("Volver")

                VStack(alignment: .leading, spacing: 2) {
                    Text(ProfileLocalization.settings)
                        .font(Theme.Fonts.notoSans(30, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text("Personaliza tu experiencia")
                        .font(Theme.Fonts.notoSans(13, weight: .medium))
                        .opacity(0.85)
                }
                .foregroundStyle(Color.white)

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

    // MARK: - Helpers dimensiones

    private var isLandscapeLike: Bool { verticalSizeClass == .compact }

    private var headerTopPadding: CGFloat {
        isLandscapeLike ? SettingsLayout.headerVerticalPaddingLandscape : SettingsLayout.headerVerticalPadding
    }

    private var headerBottomPadding: CGFloat {
        isLandscapeLike ? SettingsLayout.headerBottomPaddingLandscape : SettingsLayout.headerBottomPaddingPortrait
    }

    private var headerMinHeight: CGFloat {
        isLandscapeLike ? SettingsLayout.headerMinHeightLandscape : SettingsLayout.headerMinHeightPortrait
    }

    private var contentTopPadding: CGFloat {
        isLandscapeLike ? 16 : 2
    }

    // MARK: - Componentes internos

    @ViewBuilder
    private func settingsGroup(header: String, @ViewBuilder rows: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: SettingsLayout.sectionSpacing) {
            Text(header)
                .font(Theme.Fonts.notoSans(11, weight: .semibold))
                .tracking(0.5)
                .foregroundStyle(Theme.Colors.guindaColor)
                .padding(.leading, 2)

            VStack(spacing: 0) {
                rows()
            }
            .background(Theme.Colors.surfaceWhite)
            .clipShape(RoundedRectangle(cornerRadius: SettingsLayout.rowCornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        }
    }

    private var rowDivider: some View {
        Rectangle()
            .fill(Theme.Colors.brandCreamStrong)
            .frame(height: 1)
            .padding(.leading, 52)
    }

    private func settingsRow(
        icon: String,
        title: String,
        accessibilityID: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Theme.Colors.brandGreen)
                    .frame(width: 34, height: 34)
                    .background(Theme.Colors.brandGreenTint)
                    .clipShape(Circle())

                Text(title)
                    .font(Theme.Fonts.notoSans(15, weight: .medium))
                    .foregroundStyle(Theme.Colors.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.Colors.textSecondary.opacity(0.45))
                    .flipsForRightToLeftLayoutDirection(true)
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: SettingsLayout.rowMinHeight)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityIdentifier(accessibilityID)
    }

    // MARK: - Version card

    private var versionCard: some View {
        Button(action: {
            if viewModel.versionState != .actual {
                viewModel.openAppStore()
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: "app.badge.checkmark")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(
                        viewModel.versionState == .actual
                            ? Theme.Colors.brandGreen
                            : Theme.Colors.guindaColor
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(ProfileLocalization.Settings.version) \(viewModel.currentVersion)")
                        .font(Theme.Fonts.notoSans(14, weight: .medium))
                        .foregroundStyle(Theme.Colors.textPrimary)

                    switch viewModel.versionState {
                    case .actual:
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.Colors.brandGreen)
                            Text(ProfileLocalization.Settings.upToDate)
                                .font(Theme.Fonts.notoSans(12, weight: .regular))
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                    case .updateNeeded:
                        Text("\(ProfileLocalization.Settings.tapToUpdate) \(viewModel.latestVersion)")
                            .font(Theme.Fonts.notoSans(12, weight: .regular))
                            .foregroundStyle(Theme.Colors.guindaColor)
                    case .updateRequired:
                        Text(ProfileLocalization.Settings.tapToInstall)
                            .font(Theme.Fonts.notoSans(12, weight: .medium))
                            .foregroundStyle(Theme.Colors.guindaColor)
                    }
                }

                Spacer()

                if viewModel.versionState != .actual {
                    Image(systemName: "arrow.up.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(Theme.Colors.guindaColor)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(Theme.Colors.brandCreamStrong)
            .clipShape(RoundedRectangle(cornerRadius: SettingsLayout.versionCardCornerRadius, style: .continuous))
        }
        .disabled(viewModel.versionState == .actual)
        .accessibilityIdentifier("version_button")
    }

    // MARK: - Logout button

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
                        Task { await viewModel.logOut() }
                    },
                    type: .logOut
                )
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 16, weight: .medium))
                Text(ProfileLocalization.logout)
                    .font(Theme.Fonts.notoSans(15, weight: .semibold))
            }
            .foregroundStyle(Theme.Colors.semanticDestructive)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .overlay(
                RoundedRectangle(cornerRadius: SettingsLayout.logoutCornerRadius, style: .continuous)
                    .strokeBorder(Theme.Colors.semanticDestructive, lineWidth: SettingsLayout.logoutBorderWidth)
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
        .loadFonts()
}
#endif

// MARK: - SettingsCell (retrocompatibilidad)

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
                .font(Theme.Fonts.notoSans(15, weight: .medium))
                .accessibilityIdentifier("video_settings_text")
            if let description {
                Text(description)
                    .font(Theme.Fonts.notoSans(12, weight: .regular))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .accessibilityIdentifier("video_settings_sub_text")
            }
        }
        .foregroundStyle(Theme.Colors.textPrimary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
