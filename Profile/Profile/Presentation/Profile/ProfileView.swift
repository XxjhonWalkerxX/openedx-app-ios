//
//  ProfileView.swift
//  Profile
//
//  Fase 6 — Rediseño completo Profile
//  6.1 Hero verde profundo + DecorativeRings + icon buttons + avatar 78pt
//  6.2 Stats card flotante (-70pt overlap)
//  6.3 "Mis constancias" carousel + BrandCertificateCard
//  6.4 Menu rows (editar perfil, administrar cuenta, configuración)
//

import SwiftUI
import Core
import Kingfisher
import Theme
import OEXFoundation

// MARK: - Layout Constants

private enum ProfileLayout {
    static let horizontalPadding: CGFloat = 20
    static let heroTopPadding: CGFloat = 8
    static let heroElementSpacing: CGFloat = 12
    static let heroMinHeight: CGFloat = 270
    static let avatarSize: CGFloat = 78
    static let iconButtonSize: CGFloat = 38
    static let statsCardOverlap: CGFloat = 70
    static let certCardWidth: CGFloat = 160
    static let certCardHeight: CGFloat = 160
}

// MARK: - ProfileView

public struct ProfileView: View {

    @StateObject private var viewModel: ProfileViewModel

    public init(viewModel: ProfileViewModel) {
        self._viewModel = StateObject(wrappedValue: { viewModel }())
    }

    public var body: some View {
        GeometryReader { _ in
            ZStack(alignment: .top) {

                Theme.Colors.brandCream
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        profileHero

                        statsCard
                            .padding(.top, -ProfileLayout.statsCardOverlap)
                            .padding(.horizontal, ProfileLayout.horizontalPadding)
                            .zIndex(5)

                        creamContent
                            .padding(.top, 20)
                    }
                }
                .refreshable {
                    Task { await viewModel.getMyProfile(withProgress: false) }
                }
                .accessibilityAction {}
                .zIndex(1)

                topBar
                    .zIndex(10)

                OfflineSnackBarView(
                    connectivity: viewModel.connectivity,
                    reloadAction: { await viewModel.getMyProfile(withProgress: false) }
                ).zIndex(2)

                if viewModel.showError {
                    VStack {
                        Spacer()
                        SnackBarView(message: viewModel.errorMessage)
                    }
                    .padding(
                        .bottom,
                        viewModel.connectivity.isInternetAvaliable ? 0 : OfflineSnackBarView.height
                    )
                    .transition(.move(edge: .bottom))
                    .onAppear {
                        doAfter(Theme.Timeout.snackbarMessageLongTimeout) {
                            viewModel.errorMessage = nil
                        }
                    }
                    .zIndex(2)
                }
            }
            .onAppear {
                Task { await viewModel.getMyProfile() }
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarHidden(true)
            .navigationTitle(ProfileLocalization.title)
            .onReceive(NotificationCenter.default.publisher(for: .profileUpdated)) { _ in
                Task { await viewModel.getMyProfile() }
            }
        }
    }

    // MARK: - 6.1 Hero

    private var profileHero: some View {
        ZStack(alignment: .top) {
            Theme.Gradients.heroGradient

            DecorativeRings()

            VStack(spacing: ProfileLayout.heroElementSpacing) {
                Color.clear
                    .frame(height: ProfileLayout.iconButtonSize + 8)

                UserAvatar(
                    url: viewModel.userModel?.isFullProfile == true
                        ? (viewModel.userModel?.avatarUrl ?? "") : "",
                    image: viewModel.userModel?.isFullProfile == true
                        ? $viewModel.updatedAvatar : .constant(nil),
                    size: ProfileLayout.avatarSize,
                    borderColor: .white.opacity(0.85)
                )
                .accessibilityIdentifier("user_avatar_image")

                VStack(spacing: 3) {
                    Text(viewModel.userModel?.name ?? "")
                        .font(Theme.Fonts.notoSans(24, weight: .bold))
                        .foregroundStyle(Color.white)
                        .kerning(-0.3)
                        .accessibilityIdentifier("user_name_text")

                    Text("@\(viewModel.userModel?.username ?? "")")
                        .font(Theme.Fonts.notoSans(13, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.65))
                        .accessibilityIdentifier("user_username_text")
                }

                Spacer().frame(height: ProfileLayout.statsCardOverlap + 4)
            }
            .padding(.top, ProfileLayout.heroTopPadding)
        }
        .frame(minHeight: ProfileLayout.heroMinHeight)
    }

    // MARK: - Top bar (bell + settings)

    private var topBar: some View {
        VStack {
            HStack {
                Spacer()
                profileIconButton(
                    systemName: "gearshape",
                    accessibilityLabel: ProfileLocalization.settings
                ) {
                    HapticFeedback.selection()
                    viewModel.router.showSettings()
                }
                .accessibilityIdentifier("settings_button")
            }
            .padding(.horizontal, ProfileLayout.horizontalPadding)
            .padding(.top, ProfileLayout.heroTopPadding)
            Spacer()
        }
    }

    private func profileIconButton(
        systemName: String,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.white)
                .frame(width: ProfileLayout.iconButtonSize, height: ProfileLayout.iconButtonSize)
                .background(Circle().fill(Color.white.opacity(0.14)))
                .overlay(Circle().strokeBorder(Color.white.opacity(0.22), lineWidth: 1))
        }
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - 6.2 Stats card flotante

    private var statsCard: some View {
        let user = viewModel.userModel
        let memberSince: String? = user.map { Self.memberSinceFormatter.string(from: $0.dateJoined) }
        let country: String? = (user?.country).flatMap { $0.isEmpty ? nil : $0 }
        let yearOfBirth: String? = (user?.yearOfBirth).flatMap { $0 != 0 ? String($0) : nil }

        let columns: [(value: String, label: String)] = [
            memberSince.map { (value: $0, label: "Miembro desde") },
            country.map { (value: $0, label: "País") },
            yearOfBirth.map { (value: $0, label: "Año nacimiento") }
        ].compactMap { $0 }

        return HStack(spacing: 0) {
            if columns.isEmpty {
                profileStatColumn(value: "—", unit: nil, label: "Miembro desde")
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(Array(columns.enumerated()), id: \.offset) { idx, col in
                    Spacer()
                    profileStatColumn(value: col.value, unit: nil, label: col.label)
                    Spacer()
                    if idx < columns.count - 1 {
                        statDivider
                    }
                }
            }
        }
        .padding(.vertical, 20)
        .background(Theme.Colors.surfaceWhite)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Sizes.radiusCard))
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }

    private static let memberSinceFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "es_MX")
        df.dateFormat = "LLL yyyy"
        return df
    }()

    private var statDivider: some View {
        Rectangle()
            .fill(Theme.Colors.brandCreamStrong)
            .frame(width: 1, height: 36)
    }

    private func profileStatColumn(value: String, unit: String?, label: String) -> some View {
        VStack(alignment: .center, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(Theme.Fonts.notoSans(22, weight: .bold))
                    .foregroundStyle(Theme.Colors.guindaColor)
                if let unit {
                    Text(unit)
                        .font(Theme.Fonts.notoSans(12, weight: .medium))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            Text(label.uppercased())
                .font(Theme.Fonts.notoSans(9, weight: .medium))
                .tracking(0.5)
                .foregroundStyle(Theme.Colors.textSecondary)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value)\(unit ?? ""), \(label)")
    }

    // MARK: - Cream content

    private var creamContent: some View {
        VStack(spacing: 0) {
            if viewModel.isShowProgress {
                ProgressBar(size: 40, lineWidth: 8)
                    .padding(.top, 60)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .accessibilityIdentifier("progress_bar")
            } else {
                VStack(spacing: 24) {
                    certificatesSection
                    menuSection
                    profileInfo
                    Spacer().frame(height: 40)
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 6.3 Certificates carousel

    private var certificatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            BrandSectionHeader("Mis constancias")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    dashedCertPlaceholder
                }
                .padding(.horizontal, ProfileLayout.horizontalPadding)
                .padding(.vertical, 2)
            }
        }
    }

    private var dashedCertPlaceholder: some View {
        VStack(spacing: 10) {
            Image(systemName: "rosette")
                .font(.system(size: 32, weight: .ultraLight))
                .foregroundStyle(Theme.Colors.brandGreen.opacity(0.4))
            Text("Continúa cursos para\nobtener constancias")
                .font(Theme.Fonts.notoSans(12, weight: .regular))
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
        .padding(14)
        .frame(width: ProfileLayout.certCardWidth, height: ProfileLayout.certCardHeight)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Sizes.radiusCard)
                .strokeBorder(
                    style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                )
                .foregroundStyle(Theme.Colors.brandCreamStrong)
        )
        .accessibilityLabel("Completa cursos para obtener constancias")
    }

    // MARK: - 6.4 Menu rows

    private var menuSection: some View {
        VStack(spacing: 0) {
            profileMenuRow(
                icon: "person.crop.circle",
                label: ProfileLocalization.editProfile
            ) {
                HapticFeedback.selection()
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
            }

            menuDivider

            profileMenuRow(
                icon: "person.text.rectangle",
                label: ProfileLocalization.manageAccount
            ) {
                HapticFeedback.selection()
                viewModel.router.showManageAccount()
            }

            menuDivider

            profileMenuRow(
                icon: "gearshape",
                label: ProfileLocalization.settings
            ) {
                HapticFeedback.selection()
                viewModel.router.showSettings()
            }
        }
        .background(Theme.Colors.surfaceWhite)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Sizes.radiusCard))
        .padding(.horizontal, ProfileLayout.horizontalPadding)
    }

    private var menuDivider: some View {
        Rectangle()
            .fill(Theme.Colors.brandCreamStrong)
            .frame(height: 1)
            .padding(.leading, 56)
    }

    private func profileMenuRow(
        icon: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Theme.Colors.brandGreen)
                    .frame(width: 36, height: 36)
                    .background(Theme.Colors.brandGreenTint)
                    .clipShape(Circle())

                Text(label)
                    .font(Theme.Fonts.notoSans(15, weight: .medium))
                    .foregroundStyle(Theme.Colors.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.Colors.textSecondary.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Profile Info (bio)

    @ViewBuilder
    private var profileInfo: some View {
        if let bio = viewModel.userModel?.shortBiography, !bio.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(ProfileLocalization.about)
                    .font(Theme.Fonts.notoSans(11, weight: .semibold))
                    .tracking(0.5)
                    .foregroundStyle(Theme.Colors.brandGreen)
                    .accessibilityIdentifier("profile_info_text")
                Text(bio)
                    .font(Theme.Fonts.notoSans(14, weight: .regular))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .accessibilityIdentifier("bio_text")
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                (viewModel.userModel?.yearOfBirth != 0 ?
                    ProfileLocalization.Edit.Fields.yearOfBirth
                        + String(viewModel.userModel?.yearOfBirth ?? 0) : "") +
                (viewModel.userModel?.shortBiography != nil ?
                    ProfileLocalization.bio
                        + (viewModel.userModel?.shortBiography ?? "") : "")
            )
            .cardStyle(bgColor: Theme.Colors.textInputUnfocusedBackground, strokeColor: .clear)
            .padding(.horizontal, ProfileLayout.horizontalPadding)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        let router = ProfileRouterMock()
        let vm = ProfileViewModel(
            interactor: ProfileInteractor.mock,
            router: router,
            analytics: ProfileAnalyticsMock(),
            config: ConfigMock(),
            connectivity: Connectivity()
        )
        ProfileView(viewModel: vm)
            .preferredColorScheme(.light)
            .previewDisplayName("ProfileView Light")
            .loadFonts()
    }
}
#endif

// MARK: - UserAvatar

public struct UserAvatar: View {
    private var url: URL?
    private var borderColor: Color
    private var size: CGFloat
    private let defaultAvatarKeyword = "default"

    @Binding private var image: UIImage?

    public init(
        url: String,
        image: Binding<UIImage?>,
        size: CGFloat = 80,
        borderColor: Color = Theme.Colors.avatarStroke
    ) {
        if url.contains(defaultAvatarKeyword) {
            self.url = nil
        } else if let rightUrl = URL(string: url) {
            self.url = rightUrl
        } else {
            self.url = nil
        }
        self._image = image
        self.borderColor = borderColor
        self.size = size
    }

    public var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .cornerRadius(size / 2)
                    .overlay {
                        Circle()
                            .stroke(borderColor, lineWidth: 2)
                    }
            } else {
                KFImage(url)
                    .onFailureImage(CoreAssets.noAvatar.image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .cornerRadius(size / 2)
                    .overlay {
                        Circle()
                            .stroke(borderColor, lineWidth: 2)
                    }
            }
        }
    }
}
