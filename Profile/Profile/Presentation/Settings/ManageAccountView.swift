//
//  ManageAccountView.swift
//  Profile
//
//  Fase 7 — ManageAccount rediseño completo
//  7.2 Avatar grande + nombre + email + card campos editables + botón guardar verde + zona peligrosa
//

import SwiftUI
import Core
import OEXFoundation
import Theme

private enum ManageAccountLayout {
    static let headerHorizontalPadding: CGFloat = Theme.Sizes.horizontalPadding
    static let headerTopPaddingPortrait: CGFloat = Theme.Sizes.headerTopPadding
    static let headerTopPaddingLandscape: CGFloat = Theme.Sizes.headerLandscapeTopPadding
    static let headerBottomPaddingPortrait: CGFloat = Theme.Sizes.headerBottomPadding
    static let headerBottomPaddingLandscape: CGFloat = Theme.Sizes.headerLandscapeBottomPadding
    static let headerMinHeightPortrait: CGFloat = Theme.Sizes.headerPortraitMinHeight
    static let headerMinHeightLandscape: CGFloat = Theme.Sizes.headerLandscapeHeight

    static let topBandHeight: CGFloat = 4
    static let backButtonSize: CGFloat = 40
    static let contentTopPaddingPortrait: CGFloat = 2
    static let contentTopPaddingLandscape: CGFloat = 10
    static let contentHorizontalPaddingPortrait: CGFloat = Theme.Sizes.horizontalPadding
    static let contentHorizontalPaddingLandscape: CGFloat = 28
    static let contentMaxWidthLandscape: CGFloat = 620
    static let sectionSpacing: CGFloat = 24
    static let avatarSize: CGFloat = 72
}

public struct ManageAccountView: View {

    @ObservedObject
    private var viewModel: ManageAccountViewModel

    @Environment(\.verticalSizeClass) private var verticalSizeClass

    public init(viewModel: ManageAccountViewModel) {
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
                        VStack(alignment: .leading, spacing: ManageAccountLayout.sectionSpacing) {
                            if viewModel.isShowProgress {
                                ProgressBar(size: 40, lineWidth: 8)
                                    .padding(.top, 120)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .accessibilityIdentifier("progress_bar")
                            } else {
                                avatarSection
                                fieldsCard
                                dangerZone
                            }
                        }
                        .frame(maxWidth: contentMaxWidth(for: proxy.size.width))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, contentTopPadding)
                        .padding(.horizontal, contentHorizontalPadding)
                        .padding(.bottom, 40)
                    }
                    .refreshable {
                        Task { await viewModel.getMyProfile(withProgress: false) }
                    }
                }
                .navigationBarHidden(true)
                .navigationBarBackButtonHidden(true)
                .navigationTitle(ProfileLocalization.manageAccount)

                OfflineSnackBarView(
                    connectivity: viewModel.connectivity,
                    reloadAction: { await viewModel.getMyProfile(withProgress: false) }
                )

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
                }
            }
        }
        .onFirstAppear {
            Task { await viewModel.getMyProfile() }
        }
    }

    // MARK: - Header

    private var topHeader: some View {
        VStack(spacing: 0) {
            Theme.Colors.guindaColor
                .frame(height: ManageAccountLayout.topBandHeight)

            HStack(alignment: .top, spacing: 12) {
                Button(action: {
                    viewModel.router.back()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .frame(
                            width: ManageAccountLayout.backButtonSize,
                            height: ManageAccountLayout.backButtonSize
                        )
                        .background(Capsule().fill(Color.white.opacity(0.2)))
                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.3), lineWidth: 1))
                }
                .accessibilityIdentifier("back_button")
                .accessibilityLabel("Volver")

                Text(ProfileLocalization.manageAccount)
                    .font(Theme.Fonts.notoSans(30, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundStyle(Color.white)
                    .accessibilityIdentifier("manage_account_text")

                Spacer(minLength: 0)
            }
            .padding(.horizontal, ManageAccountLayout.headerHorizontalPadding)
            .padding(.top, headerTopPadding)
            .padding(.bottom, headerBottomPadding)
            .background(Theme.Colors.brandGreen)
        }
        .frame(maxWidth: .infinity, minHeight: headerMinHeight, alignment: .top)
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Avatar section

    private var avatarSection: some View {
        HStack(spacing: 14) {
            UserAvatar(
                url: viewModel.userModel?.avatarUrl ?? "",
                image: $viewModel.updatedAvatar,
                size: ManageAccountLayout.avatarSize,
                borderColor: Theme.Colors.brandCreamStrong
            )
            .accessibilityIdentifier("user_avatar_image")

            VStack(alignment: .leading, spacing: 3) {
                Text(displayName)
                    .font(Theme.Fonts.notoSans(20, weight: .bold))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .accessibilityIdentifier("user_name_text")
                Text(displayEmail)
                    .font(Theme.Fonts.notoSans(13, weight: .regular))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .accessibilityIdentifier("user_username_text")
            }

            Spacer()
        }
        .padding(.top, 4)
    }

    // MARK: - Fields card

    private var fieldsCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Información de la cuenta".uppercased())
                .font(Theme.Fonts.notoSans(11, weight: .semibold))
                .tracking(0.5)
                .foregroundStyle(Theme.Colors.guindaColor)
                .padding(.leading, 2)

            VStack(spacing: 0) {
                fieldRow(
                    icon: "person",
                    label: "Nombre",
                    value: viewModel.userModel?.name ?? "—"
                )
                fieldDivider
                fieldRow(
                    icon: "envelope",
                    label: "Correo",
                    value: displayEmail.isEmpty ? "—" : displayEmail
                )
                fieldDivider
                fieldRow(
                    icon: "at",
                    label: "Usuario",
                    value: viewModel.userModel?.username ?? "—"
                )
            }
            .background(Theme.Colors.surfaceWhite)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Sizes.radiusCard, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)

            // Botón guardar — edita el perfil
            Button(action: {
                HapticFeedback.impact(.medium)
                let userModel = viewModel.userModel ?? UserProfile()
                viewModel.trackProfileEditClicked()
                viewModel.router.showEditProfile(
                    userModel: userModel,
                    avatar: viewModel.updatedAvatar,
                    profileDidEdit: { updatedProfile, updatedImage in
                        if let updatedProfile { viewModel.userModel = updatedProfile }
                        if let updatedImage { viewModel.updatedAvatar = updatedImage }
                    }
                )
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .medium))
                    Text(ProfileLocalization.editProfile)
                        .font(Theme.Fonts.notoSans(15, weight: .semibold))
                }
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Theme.Colors.brandGreen)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Sizes.radiusCard, style: .continuous))
            }
            .accessibilityLabel(ProfileLocalization.editProfile)
        }
    }

    private func fieldRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.Colors.brandGreen)
                .frame(width: 32, height: 32)
                .background(Theme.Colors.brandGreenTint)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(Theme.Fonts.notoSans(10, weight: .medium))
                    .tracking(0.3)
                    .foregroundStyle(Theme.Colors.textSecondary)
                Text(value)
                    .font(Theme.Fonts.notoSans(14, weight: .medium))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private var fieldDivider: some View {
        Rectangle()
            .fill(Theme.Colors.brandCreamStrong)
            .frame(height: 1)
            .padding(.leading, 58)
    }

    // MARK: - Danger zone

    private var dangerZone: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Zona de riesgo".uppercased())
                .font(Theme.Fonts.notoSans(11, weight: .semibold))
                .tracking(0.5)
                .foregroundStyle(Theme.Colors.semanticDestructive)
                .padding(.leading, 2)

            Button(action: {
                HapticFeedback.notification(.warning)
                viewModel.trackProfileDeleteAccountClicked()
                viewModel.router.showDeleteProfileView()
            }) {
                HStack(spacing: 14) {
                    Image(systemName: "trash")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Theme.Colors.semanticDestructive)
                        .frame(width: 34, height: 34)
                        .background(Theme.Colors.semanticDestructive.opacity(0.1))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(ProfileLocalization.Edit.deleteAccount)
                            .font(Theme.Fonts.notoSans(15, weight: .medium))
                            .foregroundStyle(Theme.Colors.semanticDestructive)
                        Text("Esta acción es irreversible")
                            .font(Theme.Fonts.notoSans(12, weight: .regular))
                            .foregroundStyle(Theme.Colors.semanticDestructive.opacity(0.7))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.Colors.semanticDestructive.opacity(0.4))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(Theme.Colors.semanticDestructive.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: Theme.Sizes.radiusCard, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Sizes.radiusCard, style: .continuous)
                        .strokeBorder(Theme.Colors.semanticDestructive.opacity(0.2), lineWidth: 1)
                )
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(ProfileLocalization.Edit.deleteAccount)
            .accessibilityIdentifier("delete_account_button")
        }
    }

    // MARK: - Helpers

    private var isLandscapeLike: Bool { verticalSizeClass == .compact }

    private var headerTopPadding: CGFloat {
        isLandscapeLike ? ManageAccountLayout.headerTopPaddingLandscape : ManageAccountLayout.headerTopPaddingPortrait
    }

    private var headerBottomPadding: CGFloat {
        isLandscapeLike ? ManageAccountLayout.headerBottomPaddingLandscape : ManageAccountLayout.headerBottomPaddingPortrait
    }

    private var headerMinHeight: CGFloat {
        isLandscapeLike ? ManageAccountLayout.headerMinHeightLandscape : ManageAccountLayout.headerMinHeightPortrait
    }

    private var contentTopPadding: CGFloat {
        isLandscapeLike ? ManageAccountLayout.contentTopPaddingLandscape : ManageAccountLayout.contentTopPaddingPortrait
    }

    private var contentHorizontalPadding: CGFloat {
        isLandscapeLike ? ManageAccountLayout.contentHorizontalPaddingLandscape : ManageAccountLayout.contentHorizontalPaddingPortrait
    }

    private func contentMaxWidth(for availableWidth: CGFloat) -> CGFloat {
        if isLandscapeLike {
            return min(availableWidth - (contentHorizontalPadding * 2), ManageAccountLayout.contentMaxWidthLandscape)
        } else {
            return availableWidth - (contentHorizontalPadding * 2)
        }
    }

    private var displayEmail: String {
        viewModel.userModel?.email ?? ""
    }

    private var displayName: String {
        let trimmed = (viewModel.userModel?.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        let prefix = displayEmail.split(separator: "@").first.map(String.init) ?? ""
        if !prefix.isEmpty { return prefix.replacingOccurrences(of: ".", with: " ") }
        return ""
    }
}

#if DEBUG
struct ManageAccountView_Previews: PreviewProvider {
    static var previews: some View {
        let router = ProfileRouterMock()
        let vm = ManageAccountViewModel(
            router: router,
            analytics: ProfileAnalyticsMock(),
            config: ConfigMock(),
            connectivity: Connectivity(),
            interactor: ProfileInteractor.mock
        )
        ManageAccountView(viewModel: vm)
            .loadFonts()
    }
}
#endif
