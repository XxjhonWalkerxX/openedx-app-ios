//
//  VideoSettingsView.swift
//  Profile
//
//  Created by  Stepanok Ivan on 09.04.2024.
//

import SwiftUI
import Core
import Theme

private enum VideoSettingsLayout {
    // Tokens del sistema — ver Theme.Sizes
    static let horizontalPadding: CGFloat              = Theme.Sizes.horizontalPadding
    static let headerVerticalPaddingPortrait: CGFloat  = Theme.Sizes.headerTopPadding
    static let headerVerticalPaddingLandscape: CGFloat = Theme.Sizes.headerLandscapeTopPadding
    static let headerBottomPaddingPortrait: CGFloat    = Theme.Sizes.headerBottomPadding
    static let headerBottomPaddingLandscape: CGFloat   = Theme.Sizes.headerLandscapeBottomPadding
    static let headerMinHeightPortrait: CGFloat        = Theme.Sizes.headerPortraitMinHeight
    static let headerMinHeightLandscape: CGFloat       = Theme.Sizes.headerLandscapeHeight

    // Específicos de VideoSettingsView
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

public struct VideoSettingsView: View {
    
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
                        VStack(alignment: .leading, spacing: VideoSettingsLayout.sectionSpacing) {
                            videoToggleCard
                            videoNavigationCard(
                                title: ProfileLocalization.Settings.videoQualityTitle,
                                description: viewModel.selectedQuality.settingsDescription(),
                                accessibilityID: "video_stream_quality_button",
                                imageID: "video_stream_quality_image",
                                action: {
                                    viewModel.router.showVideoQualityView(viewModel: viewModel)
                                }
                            )
                            videoNavigationCard(
                                title: CoreLocalization.Settings.videoDownloadQualityTitle,
                                description: viewModel.userSettings.downloadQuality.settingsDescription,
                                accessibilityID: "video_download_quality_button",
                                imageID: "video_download_quality_image",
                                action: {
                                    viewModel.router.showVideoDownloadQualityView(
                                        downloadQuality: viewModel.userSettings.downloadQuality,
                                        didSelect: { quality in
                                            Task {
                                                await viewModel.update(downloadQuality: quality)
                                            }
                                        },
                                        analytics: viewModel.coreAnalytics
                                    )
                                }
                            )
                        }
                        .frame(maxWidth: contentMaxWidth(for: proxy.size.width))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal, contentHorizontalPadding)
                        .padding(.top, contentTopPadding)
                        .padding(.bottom, 32)
                    }
                    .scrollIndicators(.hidden)
                }
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .navigationTitle(ProfileLocalization.Settings.videoSettingsTitle)
    }

    private var isLandscapeLike: Bool {
        verticalSizeClass == .compact
    }

    private var headerTopPadding: CGFloat {
        isLandscapeLike ? VideoSettingsLayout.headerVerticalPaddingLandscape : VideoSettingsLayout.headerVerticalPaddingPortrait
    }

    private var headerBottomPadding: CGFloat {
        isLandscapeLike ? VideoSettingsLayout.headerBottomPaddingLandscape : VideoSettingsLayout.headerBottomPaddingPortrait
    }

    private var headerMinHeight: CGFloat {
        isLandscapeLike ? VideoSettingsLayout.headerMinHeightLandscape : VideoSettingsLayout.headerMinHeightPortrait
    }

    private var contentTopPadding: CGFloat {
        isLandscapeLike ? VideoSettingsLayout.contentTopPaddingLandscape : VideoSettingsLayout.contentTopPaddingPortrait
    }

    private var contentHorizontalPadding: CGFloat {
        isLandscapeLike ? VideoSettingsLayout.contentHorizontalPaddingLandscape : VideoSettingsLayout.contentHorizontalPaddingPortrait
    }

    private func contentMaxWidth(for availableWidth: CGFloat) -> CGFloat {
        if isLandscapeLike {
            return min(availableWidth - (contentHorizontalPadding * 2), VideoSettingsLayout.contentMaxWidthLandscape)
        } else {
            return availableWidth - (contentHorizontalPadding * 2)
        }
    }

    private var topHeader: some View {
        VStack(spacing: 0) {
            Theme.Colors.guindaColor
                .frame(height: VideoSettingsLayout.topBandHeight)

            HStack(alignment: .top, spacing: VideoSettingsLayout.headerTitleSpacing) {
                Button(action: {
                    viewModel.router.back()
                }) {
                    Image(systemName: "chevron.left")
                        .font(Theme.Fonts.ttRoundsSemibold(18))
                        .foregroundColor(.white)
                        .frame(width: VideoSettingsLayout.backButtonSize, height: VideoSettingsLayout.backButtonSize)
                        .background(
                            RoundedRectangle(cornerRadius: VideoSettingsLayout.backButtonCornerRadius, style: .continuous)
                                .fill(Color.white.opacity(0.22))
                        )
                }
                .accessibilityIdentifier("back_button")

                Text(ProfileLocalization.Settings.videoSettingsTitle)
                    .font(Theme.Fonts.ttRoundsCompressedMedium(38))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundColor(.white)
                    .accessibilityIdentifier("manage_account_text")

                Spacer(minLength: 0)
            }
            .padding(.horizontal, VideoSettingsLayout.horizontalPadding)
            .padding(.top, headerTopPadding)
            .padding(.bottom, headerBottomPadding)
            .background(Theme.Colors.brandGreen)
            .accessibilityIdentifier("auth_bg_image")
        }
        .frame(maxWidth: .infinity, minHeight: headerMinHeight, alignment: .top)
        .ignoresSafeArea(edges: .top)
    }

    private var videoToggleCard: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(ProfileLocalization.Settings.wifiTitle)
                    .font(Theme.Fonts.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.Colors.brandGreen)
                Text(ProfileLocalization.Settings.wifiDescription)
                    .font(Theme.Fonts.bodySmall)
                    .foregroundColor(Theme.Colors.brandCardMedium)
            }

            Spacer()

            Toggle(isOn: $viewModel.wifiOnly, label: {})
                .toggleStyle(SwitchToggleStyle(tint: Theme.Colors.brandGreen))
                .frame(width: 50)
                .accessibilityIdentifier("download_agreement_switch")
        }
        .padding(.horizontal, VideoSettingsLayout.cardHorizontalPadding)
        .padding(.vertical, VideoSettingsLayout.cardVerticalPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: VideoSettingsLayout.cardCornerRadius, style: .continuous)
                .fill(Theme.Colors.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: VideoSettingsLayout.cardCornerRadius, style: .continuous)
                .stroke(Color.black.opacity(0.04), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 5, x: 0, y: 2)
    }

    private func videoNavigationCard(
        title: String,
        description: String,
        accessibilityID: String,
        imageID: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(Theme.Fonts.titleMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.Colors.brandGreen)
                    Text(description)
                        .font(Theme.Fonts.bodySmall)
                        .foregroundColor(Theme.Colors.brandCardMedium)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Theme.Fonts.ttRoundsSemibold(15))
                    .foregroundColor(Theme.Colors.brandGreen)
                    .accessibilityIdentifier(imageID)
            }
            .padding(.horizontal, VideoSettingsLayout.cardHorizontalPadding)
            .padding(.vertical, VideoSettingsLayout.cardVerticalPadding)
            .frame(maxWidth: .infinity, minHeight: Theme.Sizes.settingsRowMinHeight, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: VideoSettingsLayout.cardCornerRadius, style: .continuous)
                    .fill(Theme.Colors.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: VideoSettingsLayout.cardCornerRadius, style: .continuous)
                    .stroke(Color.black.opacity(0.04), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessibilityID)
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
        
        VideoSettingsView(viewModel: vm)
            .loadFonts()
    }
#endif
