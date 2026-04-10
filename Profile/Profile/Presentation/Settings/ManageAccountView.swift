//
//  ManageAccountView.swift
//  Profile
//
//  Created by  Stepanok Ivan on 10.04.2024.
//

import SwiftUI
import Core
import OEXFoundation
import Theme

private enum ManageAccountLayout {
    static let topBandHeight: CGFloat = 4
    static let headerHorizontalPadding: CGFloat = 20
    static let headerTopPaddingPortrait: CGFloat = 52
    static let headerTopPaddingLandscape: CGFloat = 8
    static let headerBottomPaddingPortrait: CGFloat = 18
    static let headerBottomPaddingLandscape: CGFloat = 10
    static let headerMinHeightPortrait: CGFloat = 152
    static let headerMinHeightLandscape: CGFloat = 84
    static let headerTitleSpacing: CGFloat = 12
    static let backButtonSize: CGFloat = 54
    static let backButtonCornerRadius: CGFloat = 14

    static let contentTopPaddingPortrait: CGFloat = 2
    static let contentTopPaddingLandscape: CGFloat = 10
    static let contentHorizontalPaddingPortrait: CGFloat = 24
    static let contentHorizontalPaddingLandscape: CGFloat = 28
    static let contentMaxWidthLandscape: CGFloat = 620

    static let sectionSpacing: CGFloat = 20
    static let profileSpacing: CGFloat = 12
    static let profileNameSpacing: CGFloat = 4
    static let profileTopPaddingPortrait: CGFloat = 4
    static let profileTopPaddingLandscape: CGFloat = 12
    static let editButtonTopPadding: CGFloat = 4
    static let deleteButtonTopPadding: CGFloat = 24
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
                                userAvatar
                                editProfileButton
                                deleteAccount
                            }
                        }
                        .frame(maxWidth: contentMaxWidth(for: proxy.size.width))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, contentTopPadding)
                        .padding(.horizontal, contentHorizontalPadding)
                        .padding(.bottom, 32)
                    }
                    .refreshable {
                        Task {
                            await viewModel.getMyProfile(withProgress: false)
                        }
                    }
                }
                .navigationBarHidden(true)
                .navigationBarBackButtonHidden(true)
                .navigationTitle(ProfileLocalization.manageAccount)
                
                // MARK: - Offline mode SnackBar
                OfflineSnackBarView(
                    connectivity: viewModel.connectivity,
                    reloadAction: {
                        await viewModel.getMyProfile(withProgress: false)
                    }
                )
                
                // MARK: - Error Alert
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
            Task {
                await viewModel.getMyProfile()
            }
        }
    }

    private var topHeader: some View {
        VStack(spacing: 0) {
            Theme.Colors.guindaColor
                .frame(height: ManageAccountLayout.topBandHeight)

            HStack(alignment: .top, spacing: ManageAccountLayout.headerTitleSpacing) {
                Button(action: {
                    viewModel.router.back()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: ManageAccountLayout.backButtonSize, height: ManageAccountLayout.backButtonSize)
                        .background(
                            RoundedRectangle(cornerRadius: ManageAccountLayout.backButtonCornerRadius, style: .continuous)
                                .fill(Color.white.opacity(0.22))
                        )
                }
                .accessibilityIdentifier("back_button")

                Text(ProfileLocalization.manageAccount)
                    .font(Theme.Fonts.ttRoundsCompressedMedium(38))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundColor(.white)
                    .accessibilityIdentifier("manage_account_text")

                Spacer(minLength: 0)
            }
            .padding(.horizontal, ManageAccountLayout.headerHorizontalPadding)
            .padding(.top, headerTopPadding)
            .padding(.bottom, headerBottomPadding)
            .background(Theme.Colors.brandGreen)
            .accessibilityIdentifier("auth_bg_image")
        }
        .frame(maxWidth: .infinity, minHeight: headerMinHeight, alignment: .top)
        .ignoresSafeArea(edges: .top)
    }

    private var isLandscapeLike: Bool {
        verticalSizeClass == .compact
    }

    private var headerTopPadding: CGFloat {
        if isLandscapeLike {
            return ManageAccountLayout.headerTopPaddingLandscape
        } else {
            return ManageAccountLayout.headerTopPaddingPortrait
        }
    }

    private var headerBottomPadding: CGFloat {
        if isLandscapeLike {
            return ManageAccountLayout.headerBottomPaddingLandscape
        } else {
            return ManageAccountLayout.headerBottomPaddingPortrait
        }
    }

    private var headerMinHeight: CGFloat {
        if isLandscapeLike {
            return ManageAccountLayout.headerMinHeightLandscape
        } else {
            return ManageAccountLayout.headerMinHeightPortrait
        }
    }

    private var contentTopPadding: CGFloat {
        if isLandscapeLike {
            return ManageAccountLayout.contentTopPaddingLandscape
        } else {
            return ManageAccountLayout.contentTopPaddingPortrait
        }
    }

    private var contentHorizontalPadding: CGFloat {
        if isLandscapeLike {
            return ManageAccountLayout.contentHorizontalPaddingLandscape
        } else {
            return ManageAccountLayout.contentHorizontalPaddingPortrait
        }
    }

    private var profileTopPadding: CGFloat {
        if isLandscapeLike {
            return ManageAccountLayout.profileTopPaddingLandscape
        } else {
            return ManageAccountLayout.profileTopPaddingPortrait
        }
    }

    private func contentMaxWidth(for availableWidth: CGFloat) -> CGFloat {
        if isLandscapeLike {
            return min(availableWidth - (contentHorizontalPadding * 2), ManageAccountLayout.contentMaxWidthLandscape)
        } else {
            return availableWidth - (contentHorizontalPadding * 2)
        }
    }
    
    private var userAvatar: some View {
        HStack(alignment: .center, spacing: ManageAccountLayout.profileSpacing) {
            UserAvatar(url: viewModel.userModel?.avatarUrl ?? "", image: $viewModel.updatedAvatar)
                .accessibilityIdentifier("user_avatar_image")
            VStack(alignment: .leading, spacing: ManageAccountLayout.profileNameSpacing) {
                Text(displayName)
                    .font(Theme.Fonts.headlineSmall)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.Colors.brandGreen)
                    .accessibilityIdentifier("user_name_text")
                Text(displayEmail)
                    .font(Theme.Fonts.labelLarge)
                    .foregroundColor(Theme.Colors.brandGreen)
                    .accessibilityIdentifier("user_username_text")
            }
            Spacer()
        }
        .padding(.top, profileTopPadding)
            .frame(
                minWidth: 0,
                maxWidth: .infinity,
                alignment: .center
            )
    }
    
    private var deleteAccount: some View {
        Button(action: {
            viewModel.trackProfileDeleteAccountClicked()
            viewModel.router.showDeleteProfileView()
        }, label: {
            HStack {
                CoreAssets.deleteAccount.swiftUIImage
                Text(ProfileLocalization.Edit.deleteAccount)
            }
        })
        .frame(
            minWidth: 0,
            maxWidth: .infinity,
            alignment: .center
        )
        .font(Theme.Fonts.labelLarge)
        .foregroundColor(Theme.Colors.guindaColor)
        .padding(.top, ManageAccountLayout.deleteButtonTopPadding)
        .accessibilityIdentifier("delete_account_button")
    }
    
    private var editProfileButton: some View {
        HStack(alignment: .center) {
            StyledButton(
                ProfileLocalization.editProfile,
                action: {
                    let userModel = viewModel.userModel ?? UserProfile()
                    viewModel.trackProfileEditClicked()
                    viewModel.router.showEditProfile(
                        userModel: userModel,
                        avatar: viewModel.updatedAvatar,
                        profileDidEdit: { updatedProfile, updatedImage in
                            if let updatedProfile {
                                self.viewModel.userModel = updatedProfile
                            }
                            if let updatedImage {
                                self.viewModel.updatedAvatar = updatedImage
                            }
                        }
                    )
                },
                color: Theme.Colors.white,
                textColor: Theme.Colors.brandGreen,
                borderColor: Theme.Colors.brandGreen
            )
        }
        .padding(.top, ManageAccountLayout.editButtonTopPadding)
        .frame(
            minWidth: 0,
            maxWidth: .infinity,
            alignment: .center
        )
    }

    private var displayEmail: String {
        viewModel.userModel?.email ?? ""
    }

    private var displayName: String {
        let trimmedName = (viewModel.userModel?.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty {
            return trimmedName.uppercased()
        }

        let emailPrefix = displayEmail.split(separator: "@").first.map(String.init) ?? ""
        if !emailPrefix.isEmpty {
            return emailPrefix.replacingOccurrences(of: ".", with: " ").uppercased()
        }

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
