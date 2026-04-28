//
//  VideoQualityView.swift
//  Profile
//
//  Created by  Stepanok Ivan on 16.03.2023.
//

import SwiftUI
import Core
import OEXFoundation
import Kingfisher
import Theme

private enum VideoQualityLayout {
    // Tokens del sistema — ver Theme.Sizes
    static let horizontalPadding: CGFloat              = Theme.Sizes.horizontalPadding
    static let headerVerticalPaddingPortrait: CGFloat  = Theme.Sizes.headerTopPadding
    static let headerVerticalPaddingLandscape: CGFloat = Theme.Sizes.headerLandscapeTopPadding
    static let headerBottomPaddingPortrait: CGFloat    = Theme.Sizes.headerBottomPadding
    static let headerBottomPaddingLandscape: CGFloat   = Theme.Sizes.headerLandscapeBottomPadding
    static let headerMinHeightPortrait: CGFloat        = Theme.Sizes.headerPortraitMinHeight
    static let headerMinHeightLandscape: CGFloat       = Theme.Sizes.headerLandscapeHeight

    // Específicos de VideoQualityView
    static let topBandHeight: CGFloat                    = 4
    static let headerTitleSpacing: CGFloat               = 12
    static let sectionSpacing: CGFloat                   = 10
    static let contentTopPaddingPortrait: CGFloat        = 2
    static let contentTopPaddingLandscape: CGFloat       = 10
    static let contentHorizontalPaddingPortrait: CGFloat = 24
    static let contentHorizontalPaddingLandscape: CGFloat = 28
    static let contentMaxWidthLandscape: CGFloat         = 620
    static let backButtonSize: CGFloat                   = 54
    static let backButtonCornerRadius: CGFloat           = 14
    static let cardCornerRadius: CGFloat                 = 18
    static let cardHorizontalPadding: CGFloat            = 18
    static let cardVerticalPadding: CGFloat              = 16
}

public struct VideoQualityView: View {
    
    @ObservedObject
    private var viewModel: SettingsViewModel
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    public init(viewModel: SettingsViewModel) {
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
                        VStack(alignment: .leading, spacing: VideoQualityLayout.sectionSpacing) {
                            if viewModel.isShowProgress {
                                ProgressBar(size: 40, lineWidth: 8)
                                    .padding(.top, 120)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .accessibilityIdentifier("progress_bar")
                            } else {
                                ForEach(viewModel.quality, id: \.offset) { _, quality in
                                    qualityCard(quality: quality)
                                }
                            }
                        }
                        .frame(maxWidth: contentMaxWidth(for: proxy.size.width))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal, contentHorizontalPadding)
                        .padding(.top, contentTopPadding)
                        .padding(.bottom, 32)
                    }
                    .scrollIndicators(.hidden)

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
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .navigationTitle(ProfileLocalization.Settings.videoQualityTitle)
    }

    private var isLandscapeLike: Bool {
        verticalSizeClass == .compact
    }

    private var headerTopPadding: CGFloat {
        isLandscapeLike ? VideoQualityLayout.headerVerticalPaddingLandscape : VideoQualityLayout.headerVerticalPaddingPortrait
    }

    private var headerBottomPadding: CGFloat {
        isLandscapeLike ? VideoQualityLayout.headerBottomPaddingLandscape : VideoQualityLayout.headerBottomPaddingPortrait
    }

    private var headerMinHeight: CGFloat {
        isLandscapeLike ? VideoQualityLayout.headerMinHeightLandscape : VideoQualityLayout.headerMinHeightPortrait
    }

    private var contentTopPadding: CGFloat {
        isLandscapeLike ? VideoQualityLayout.contentTopPaddingLandscape : VideoQualityLayout.contentTopPaddingPortrait
    }

    private var contentHorizontalPadding: CGFloat {
        isLandscapeLike ? VideoQualityLayout.contentHorizontalPaddingLandscape : VideoQualityLayout.contentHorizontalPaddingPortrait
    }

    private func contentMaxWidth(for availableWidth: CGFloat) -> CGFloat {
        if isLandscapeLike {
            return min(availableWidth - (contentHorizontalPadding * 2), VideoQualityLayout.contentMaxWidthLandscape)
        } else {
            return availableWidth - (contentHorizontalPadding * 2)
        }
    }

    private var topHeader: some View {
        VStack(spacing: 0) {
            Theme.Colors.guindaColor
                .frame(height: VideoQualityLayout.topBandHeight)

            HStack(alignment: .top, spacing: VideoQualityLayout.headerTitleSpacing) {
                Button(action: {
                    viewModel.router.back()
                }) {
                    Image(systemName: "chevron.left")
                        .font(Theme.Fonts.notoSans(16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: VideoQualityLayout.backButtonSize, height: VideoQualityLayout.backButtonSize)
                        .background(
                            RoundedRectangle(cornerRadius: VideoQualityLayout.backButtonCornerRadius, style: .continuous)
                                .fill(Color.white.opacity(0.22))
                        )
                }
                .accessibilityIdentifier("back_button")

                Text(ProfileLocalization.Settings.videoQualityTitle)
                    .font(Theme.Fonts.notoSans(30, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundColor(.white)
                    .accessibilityIdentifier("manage_account_text")

                Spacer(minLength: 0)
            }
            .padding(.horizontal, VideoQualityLayout.horizontalPadding)
            .padding(.top, headerTopPadding)
            .padding(.bottom, headerBottomPadding)
            .background(Theme.Colors.brandGreen)
            .accessibilityIdentifier("auth_bg_image")
        }
        .frame(maxWidth: .infinity, minHeight: headerMinHeight, alignment: .top)
        .ignoresSafeArea(edges: .top)
    }

    private func qualityCard(quality: StreamingQuality) -> some View {
        Button(action: {
            viewModel.coreAnalytics.videoQualityChanged(
                .videoStreamQualityChanged,
                bivalue: .videoStreamQualityChanged,
                value: quality.value ?? "",
                oldValue: viewModel.selectedQuality.value ?? ""
            )
            viewModel.selectedQuality = quality
        }, label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(quality.title())
                        .font(Theme.Fonts.notoSans(15, weight: .medium))
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.Colors.brandGreen)
                    if let description = quality.description() {
                        Text(description)
                            .font(Theme.Fonts.notoSans(12, weight: .regular))
                            .foregroundColor(Theme.Colors.brandCardMedium)
                    }
                }

                Spacer()

                CoreAssets.checkmark.swiftUIImage
                    .renderingMode(.template)
                    .foregroundColor(Theme.Colors.brandGreen)
                        .opacity(quality == viewModel.selectedQuality ? 1 : 0)
            }
            .padding(.horizontal, VideoQualityLayout.cardHorizontalPadding)
            .padding(.vertical, VideoQualityLayout.cardVerticalPadding)
            .frame(maxWidth: .infinity, minHeight: Theme.Sizes.settingsRowMinHeight, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: VideoQualityLayout.cardCornerRadius, style: .continuous)
                    .fill(Theme.Colors.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: VideoQualityLayout.cardCornerRadius, style: .continuous)
                    .stroke(Color.black.opacity(0.04), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 5, x: 0, y: 2)
        })
        .buttonStyle(.plain)
        .accessibilityIdentifier("select_quality_button")
    }
}

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

    VideoQualityView(viewModel: vm)
        .loadFonts()
}
#endif
