//
//  ProfileView.swift
//  Profile
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
    static let heroElementSpacing: CGFloat = 16
    static let heroBottomSpacing: CGFloat = 16
    static let heroMinHeight: CGFloat = 240
    static let guindaBandHeight: CGFloat = 4
    static let settingsButtonSize: CGFloat = 40
    static let avatarSize: CGFloat = 90
    static let handleWidth: CGFloat = 36
    static let handleHeight: CGFloat = 4
    static let handleTopPadding: CGFloat = 12
    static let handleBottomPadding: CGFloat = 16
    static let contentBottomPadding: CGFloat = 60
    static let heroOverlap: CGFloat = 15
    static let circleLargeSize: CGFloat = 210
    static let circleMediumSize: CGFloat = 110
    static let circleSmallSize: CGFloat = 70
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

                // Fondo base
                Theme.Colors.brandGreenDark
                    .ignoresSafeArea()

                // Banda guinda
                Theme.Colors.guindaColor
                    .frame(height: ProfileLayout.guindaBandHeight)
                    .ignoresSafeArea(edges: .top)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .zIndex(10)

                // Contenido scrollable
                ScrollView {
                    VStack(spacing: 0) {
                        profileHero
                        creamCard
                            .padding(.top, -ProfileLayout.heroOverlap)
                    }
                }
                .refreshable {
                    Task {
                        await viewModel.getMyProfile(withProgress: false)
                    }
                }
                .accessibilityAction {}
                .zIndex(1)

                // Settings button — overlay fijo sobre el hero
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            viewModel.router.showSettings()
                        }) {
                            CoreAssets.settings.swiftUIImage
                                .renderingMode(.template)
                                .foregroundColor(.white)
                                .frame(
                                    width: ProfileLayout.settingsButtonSize,
                                    height: ProfileLayout.settingsButtonSize
                                )
                                .background(Circle().fill(Color.white.opacity(0.14)))
                                .overlay(Circle().strokeBorder(Color.white.opacity(0.22), lineWidth: 1))
                        }
                        .accessibilityIdentifier("settings_button")
                    }
                    .padding(.horizontal, ProfileLayout.horizontalPadding)
                    .padding(.top, ProfileLayout.heroTopPadding)
                    Spacer()
                }
                .zIndex(5)

                // Offline snackbar
                OfflineSnackBarView(
                    connectivity: viewModel.connectivity,
                    reloadAction: {
                        await viewModel.getMyProfile(withProgress: false)
                    }
                ).zIndex(2)

                // Error snackbar
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
                Task {
                    await viewModel.getMyProfile()
                }
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarHidden(true)
            .navigationTitle(ProfileLocalization.title)
            .onReceive(NotificationCenter.default.publisher(for: .profileUpdated)) { _ in
                Task {
                    await viewModel.getMyProfile()
                }
            }
        }
    }

    // MARK: - Hero

    private var profileHero: some View {
        ZStack(alignment: .top) {

            Theme.Gradients.heroGradient

            profileCircles
                .allowsHitTesting(false)

            VStack(spacing: ProfileLayout.heroElementSpacing) {

                // Espacio para el settings button flotante
                Color.clear
                    .frame(height: ProfileLayout.settingsButtonSize)

                // Avatar
                UserAvatar(
                    url: viewModel.userModel?.isFullProfile == true
                        ? (viewModel.userModel?.avatarUrl ?? "") : "",
                    image: viewModel.userModel?.isFullProfile == true
                        ? $viewModel.updatedAvatar : .constant(nil),
                    size: ProfileLayout.avatarSize,
                    borderColor: .white.opacity(0.7)
                )
                .accessibilityIdentifier("user_avatar_image")

                // Nombre + username
                VStack(spacing: 4) {
                    Text(viewModel.userModel?.name ?? "")
                        .font(Theme.Fonts.ttRoundsCompressedMedium(24))
                        .foregroundColor(.white)
                        .kerning(-0.3)
                        .accessibilityIdentifier("user_name_text")

                    Text("@\(viewModel.userModel?.username ?? "")")
                        .font(Theme.Fonts.ttRoundsCompressedThinItalic(13))
                        .foregroundColor(.white.opacity(0.7))
                        .accessibilityIdentifier("user_username_text")
                }

                Spacer().frame(height: ProfileLayout.heroBottomSpacing)
            }
            .padding(.top, ProfileLayout.heroTopPadding)
        }
        .frame(minHeight: ProfileLayout.heroMinHeight)
    }

    private var profileCircles: some View {
        ZStack {
            Circle()
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 34)
                .frame(width: ProfileLayout.circleLargeSize, height: ProfileLayout.circleLargeSize)
                .offset(x: 130, y: -40)
            Circle()
                .strokeBorder(Color.white.opacity(0.05), lineWidth: 20)
                .frame(width: ProfileLayout.circleMediumSize, height: ProfileLayout.circleMediumSize)
                .offset(x: -120, y: 130)
            Circle()
                .strokeBorder(Color.white.opacity(0.07), lineWidth: 13)
                .frame(width: ProfileLayout.circleSmallSize, height: ProfileLayout.circleSmallSize)
                .offset(x: -70, y: 20)
        }
    }

    // MARK: - Cream Card

    private var creamCard: some View {
        VStack(spacing: 0) {

            // Drag handle
            Capsule()
                .fill(Theme.Colors.brandHandle)
                .frame(width: ProfileLayout.handleWidth, height: ProfileLayout.handleHeight)
                .padding(.top, ProfileLayout.handleTopPadding)
                .padding(.bottom, ProfileLayout.handleBottomPadding)

            if viewModel.isShowProgress {
                ProgressBar(size: 40, lineWidth: 8)
                    .padding(.top, 60)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, minHeight: 300)
                    .accessibilityIdentifier("progress_bar")
            } else {
                VStack(spacing: 16) {

                    // Edit Profile button — colores del proyecto
                    StyledButton(
                        ProfileLocalization.editProfile,
                        action: {
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
                        },
                        color: Theme.Colors.background,
                        textColor: Theme.Colors.accentColor,
                        borderColor: Theme.Colors.accentColor
                    )
                    .padding(.horizontal, ProfileLayout.horizontalPadding)

                    // Bio (opcional)
                    profileInfo
                }
                .padding(.top, 8)
            }

            // Filler — extiende el fondo crema hasta el borde inferior
            Theme.Colors.brandCream
                .frame(maxWidth: .infinity, minHeight: 300)
        }
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.brandCream)
        .clipShape(ProfileSheetShape(radius: 32))
    }

    // MARK: - Profile Info (bio)

    @ViewBuilder
    private var profileInfo: some View {
        if let bio = viewModel.userModel?.shortBiography, !bio.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text(ProfileLocalization.about)
                    .font(Theme.Fonts.titleSmall)
                    .foregroundColor(Theme.Colors.textPrimary)
                    .accessibilityIdentifier("profile_info_text")
                Text(bio)
                    .font(Theme.Fonts.bodyMedium)
                    .foregroundColor(Theme.Colors.textPrimary)
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

// MARK: - Shape para esquinas redondeadas solo arriba

private struct ProfileSheetShape: Shape {
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

        ProfileView(viewModel: vm)
            .preferredColorScheme(.dark)
            .previewDisplayName("ProfileView Dark")
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
