//
//  DeleteAccountView.swift
//  Profile
//
//  Created by  Stepanok Ivan on 28.02.2023.
//

import SwiftUI
import Core
import OEXFoundation
import Theme

private enum DeleteAccountLayout {
    // Tokens del sistema — ver Theme.Sizes
    static let horizontalPadding: CGFloat              = Theme.Sizes.horizontalPadding
    static let headerVerticalPaddingPortrait: CGFloat  = Theme.Sizes.headerTopPadding
    static let headerVerticalPaddingLandscape: CGFloat = Theme.Sizes.headerLandscapeTopPadding
    static let headerBottomPaddingPortrait: CGFloat    = Theme.Sizes.headerBottomPadding
    static let headerBottomPaddingLandscape: CGFloat   = Theme.Sizes.headerLandscapeBottomPadding
    static let headerMinHeightPortrait: CGFloat        = Theme.Sizes.headerPortraitMinHeight
    static let headerMinHeightLandscape: CGFloat       = Theme.Sizes.headerLandscapeHeight

    // Específicos de DeleteAccountView
    static let topBandHeight: CGFloat          = 4
    static let headerTitleSpacing: CGFloat     = 12
    static let backButtonSize: CGFloat         = 54
    static let backButtonCornerRadius: CGFloat = 14
    static let contentTopPadding: CGFloat      = 8
    static let contentHorizontalPadding: CGFloat = 24
}

public struct DeleteAccountView: View {

    @ObservedObject
    private var viewModel: DeleteAccountViewModel
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    public init(viewModel: DeleteAccountViewModel) {
        self.viewModel = viewModel
    }
    
    private var isLandscapeLike: Bool { verticalSizeClass == .compact }

    private var headerTopPadding: CGFloat {
        isLandscapeLike
            ? DeleteAccountLayout.headerVerticalPaddingLandscape
            : DeleteAccountLayout.headerVerticalPaddingPortrait
    }

    private var headerBottomPadding: CGFloat {
        isLandscapeLike
            ? DeleteAccountLayout.headerBottomPaddingLandscape
            : DeleteAccountLayout.headerBottomPaddingPortrait
    }

    private var headerMinHeight: CGFloat {
        isLandscapeLike
            ? DeleteAccountLayout.headerMinHeightLandscape
            : DeleteAccountLayout.headerMinHeightPortrait
    }

    private var topHeader: some View {
        VStack(spacing: 0) {
            Theme.Colors.guindaColor
                .frame(height: DeleteAccountLayout.topBandHeight)

            HStack(alignment: .top, spacing: DeleteAccountLayout.headerTitleSpacing) {
                Button(action: { viewModel.router.back() }) {
                    Image(systemName: "chevron.left")
                        .font(Theme.Fonts.notoSans(16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(
                            width: DeleteAccountLayout.backButtonSize,
                            height: DeleteAccountLayout.backButtonSize
                        )
                        .background(
                            RoundedRectangle(
                                cornerRadius: DeleteAccountLayout.backButtonCornerRadius,
                                style: .continuous
                            )
                            .fill(Color.white.opacity(0.22))
                        )
                }
                .accessibilityIdentifier("back_button")

                Text(ProfileLocalization.DeleteAccount.title)
                    .font(Theme.Fonts.notoSans(30, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, DeleteAccountLayout.horizontalPadding)
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

                // MARK: - Page Body
                ScrollView {
                    VStack {
                        Group {
                            ZStack {
                                Circle()
                                    .foregroundColor(Theme.Colors.deleteAccountBG)
                                    .frame(width: 104, height: 104)
                                CoreAssets.deleteChar.swiftUIImage.renderingMode(.template)
                                    .resizable()
                                    .foregroundColor(Theme.Colors.white)
                                    .frame(width: 60, height: 60)
                                    .offset(y: -5)
                                    .accessibilityIdentifier("delete_account_image")
                            }.padding(.top, 50)
                            
                            HStack {
                                Text(ProfileLocalization.DeleteAccount.areYouSure)
                                    .foregroundColor(Theme.Colors.navigationBarTintColor)
                                + Text(ProfileLocalization.DeleteAccount.wantToDelete)
                                    .foregroundColor(Theme.Colors.irreversibleAlert)
                            }
                            .accessibilityIdentifier("are_you_sure_text")
                            
                        }.multilineTextAlignment(.center)
                            .font(Theme.Fonts.headlineSmall)
                        
                        Text(ProfileLocalization.DeleteAccount.description)
                            .foregroundColor(Theme.Colors.textSecondary)
                            .font(Theme.Fonts.notoSans(13, weight: .medium))
                            .multilineTextAlignment(.center)
                            .padding(.top, 16)
                            .accessibilityIdentifier("delete_account_description_text")
                        
                        // MARK: Password
                        Group {
                            Text(ProfileLocalization.DeleteAccount.password)
                                .foregroundColor(Theme.Colors.textSecondary)
                                .font(Theme.Fonts.notoSans(13, weight: .medium))
                                .multilineTextAlignment(.leading)
                                .padding(.top, 16)
                                .accessibilityIdentifier("password_text")
                            
                            HStack(spacing: 11) {
                                SecureField("",
                                            text: $viewModel.password)
                                .font(Theme.Fonts.notoSans(13, weight: .medium))
                                .foregroundColor(Theme.Colors.textInputTextColor)
                                .accessibilityIdentifier("password_textfield")
                            }
                            .padding(.horizontal, 14)
                            .frame(minHeight: 48)
                            .frame(maxWidth: .infinity)
                            .background(
                                Theme.InputFieldBackground(
                                    placeHolder: ProfileLocalization.DeleteAccount.passwordDescription,
                                    text: viewModel.password,
                                    padding: 15
                                )
                            )
                            .overlay(
                                Theme.Shapes.textInputShape
                                    .stroke(lineWidth: 1)
                                    .fill(Theme.Colors.textInputUnfocusedStroke)
                            )
                            Text(viewModel.incorrectPassword
                                 ? ProfileLocalization.DeleteAccount.incorrectPassword
                                 : " ")
                            .foregroundColor(Theme.Colors.irreversibleAlert)
                            .font(Theme.Fonts.notoSans(13, weight: .medium))
                            .multilineTextAlignment(.leading)
                            .padding(.top, 0)
                            .shake($viewModel.incorrectPassword,
                                   onCompletion: { viewModel.incorrectPassword.toggle() })
                            .accessibilityIdentifier("incorrect_password_text")
                            
                        }.frame(minWidth: 0,
                                maxWidth: .infinity,
                                alignment: .topLeading)
                        
                        // MARK: Confirmation button
                        if viewModel.isShowProgress {
                            ProgressBar(size: 40, lineWidth: 8)
                                .padding(.top, 20)
                                .padding(.horizontal)
                                .accessibilityIdentifier("progress_bar")
                        } else {
                            StyledButton(
                                ProfileLocalization.DeleteAccount.confirm,
                                action: {
                                    Task {
                                        try await viewModel.deleteAccount(password: viewModel.password)
                                    }
                                },
                                color: .clear,
                                textColor: Theme.Colors.irreversibleAlert,
                                borderColor: Theme.Colors.irreversibleAlert,
                                isActive: viewModel.password.count >= 2
                            )
                            .padding(.top, 18)
                            .accessibilityIdentifier("delete_account_button")
                        }
                        
                        // MARK: Back to profile
                        StyledButton(
                            ProfileLocalization.DeleteAccount.backToProfile,
                            action: {
                                viewModel.router.back()
                            },
                            color: Theme.Colors.brandGreen,
                            textColor: Theme.Colors.primaryButtonTextColor,
                            iconImage: CoreAssets.arrowLeft.swiftUIImage,
                            iconPosition: .left
                        )
                        .padding(.top, 35)
                        .accessibilityIdentifier("back_button")
                    }
                    .frameLimit(width: proxy.size.width)
                }
                .padding(.horizontal, DeleteAccountLayout.contentHorizontalPadding)
                .frame(minHeight: 0,
                       maxHeight: .infinity,
                       alignment: .top)
                .padding(.top, DeleteAccountLayout.contentTopPadding)
                }
                .navigationBarHidden(true)
                .navigationBarBackButtonHidden(true)
                .navigationTitle(ProfileLocalization.DeleteAccount.title)
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
        }
    }
}

#if DEBUG
struct DeleteAccountView_Previews: PreviewProvider {
    static var previews: some View {
        let router = ProfileRouterMock()
        let vm = DeleteAccountViewModel(
            interactor: ProfileInteractor.mock,
            router: router,
            connectivity: Connectivity(),
            analytics: ProfileAnalyticsMock()
        )
        
        DeleteAccountView(viewModel: vm)
    }
}
#endif
