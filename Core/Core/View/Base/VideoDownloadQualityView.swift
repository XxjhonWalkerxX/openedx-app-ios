//
//  VideoDownloadQualityView.swift
//  Core
//
//  Created by Eugene Yatsenko on 19.01.2024.
//

import SwiftUI
import Core
import Kingfisher
import Theme

private enum VideoDownloadQualityLayout {
    static let topBandHeight: CGFloat = 4
    static let horizontalPadding: CGFloat = 20
    static let headerVerticalPaddingPortrait: CGFloat = 52
    static let headerVerticalPaddingLandscape: CGFloat = 8
    static let headerBottomPaddingPortrait: CGFloat = 18
    static let headerBottomPaddingLandscape: CGFloat = 10
    static let headerMinHeightPortrait: CGFloat = 152
    static let headerMinHeightLandscape: CGFloat = 84
    static let headerTitleSpacing: CGFloat = 12
    static let sectionSpacing: CGFloat = 10
    static let contentTopPaddingPortrait: CGFloat = 2
    static let contentTopPaddingLandscape: CGFloat = 10
    static let contentHorizontalPaddingPortrait: CGFloat = 24
    static let contentHorizontalPaddingLandscape: CGFloat = 28
    static let contentMaxWidthLandscape: CGFloat = 620
    static let backButtonSize: CGFloat = 54
    static let backButtonCornerRadius: CGFloat = 14
    static let cardCornerRadius: CGFloat = 18
    static let cardHorizontalPadding: CGFloat = 18
    static let cardVerticalPadding: CGFloat = 16
}

public final class VideoDownloadQualityViewModel: ObservableObject {

    var didSelect: ((DownloadQuality) -> Void)?
    let downloadQuality = DownloadQuality.allCases
    
    @Published var selectedDownloadQuality: DownloadQuality {
        willSet {
            if newValue != selectedDownloadQuality {
                didSelect?(newValue)
            }
        }
    }

    public init(downloadQuality: DownloadQuality, didSelect: ((DownloadQuality) -> Void)?) {
        self.selectedDownloadQuality = downloadQuality
        self.didSelect = didSelect
    }
}

public struct VideoDownloadQualityView: View {

    @StateObject
    private var viewModel: VideoDownloadQualityViewModel
    private var analytics: CoreAnalytics
    private var router: BaseRouter
    private var isModal: Bool
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    public init(
        downloadQuality: DownloadQuality,
        didSelect: ((DownloadQuality) -> Void)?,
        analytics: CoreAnalytics,
        router: BaseRouter,
        isModal: Bool = false
    ) {
        self._viewModel = StateObject(
            wrappedValue: .init(
                downloadQuality: downloadQuality,
                didSelect: didSelect
            )
        )
        self.analytics = analytics
        self.router = router
        self.isModal = isModal
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                Theme.Colors.brandCream
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    topHeader

                    ScrollView {
                        VStack(alignment: .leading, spacing: VideoDownloadQualityLayout.sectionSpacing) {
                            ForEach(viewModel.downloadQuality, id: \.self) { quality in
                                qualityCard(quality: quality)
                            }
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
        .navigationTitle(CoreLocalization.Settings.videoDownloadQualityTitle)
    }

    private var isLandscapeLike: Bool {
        verticalSizeClass == .compact
    }

    private var headerTopPadding: CGFloat {
        isLandscapeLike ? VideoDownloadQualityLayout.headerVerticalPaddingLandscape : VideoDownloadQualityLayout.headerVerticalPaddingPortrait
    }

    private var headerBottomPadding: CGFloat {
        isLandscapeLike ? VideoDownloadQualityLayout.headerBottomPaddingLandscape : VideoDownloadQualityLayout.headerBottomPaddingPortrait
    }

    private var headerMinHeight: CGFloat {
        isLandscapeLike ? VideoDownloadQualityLayout.headerMinHeightLandscape : VideoDownloadQualityLayout.headerMinHeightPortrait
    }

    private var contentTopPadding: CGFloat {
        isLandscapeLike ? VideoDownloadQualityLayout.contentTopPaddingLandscape : VideoDownloadQualityLayout.contentTopPaddingPortrait
    }

    private var contentHorizontalPadding: CGFloat {
        isLandscapeLike ? VideoDownloadQualityLayout.contentHorizontalPaddingLandscape : VideoDownloadQualityLayout.contentHorizontalPaddingPortrait
    }

    private func contentMaxWidth(for availableWidth: CGFloat) -> CGFloat {
        if isLandscapeLike {
            return min(availableWidth - (contentHorizontalPadding * 2), VideoDownloadQualityLayout.contentMaxWidthLandscape)
        } else {
            return availableWidth - (contentHorizontalPadding * 2)
        }
    }

    private var topHeader: some View {
        VStack(spacing: 0) {
            Theme.Colors.guindaColor
                .frame(height: VideoDownloadQualityLayout.topBandHeight)

            HStack(alignment: .top, spacing: VideoDownloadQualityLayout.headerTitleSpacing) {
                Button(action: {
                    router.back()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: VideoDownloadQualityLayout.backButtonSize, height: VideoDownloadQualityLayout.backButtonSize)
                        .background(
                            RoundedRectangle(cornerRadius: VideoDownloadQualityLayout.backButtonCornerRadius, style: .continuous)
                                .fill(Color.white.opacity(0.22))
                        )
                }
                .accessibilityIdentifier("back_button")

                Text(CoreLocalization.Settings.videoDownloadQualityTitle)
                    .font(Theme.Fonts.ttRoundsCompressedMedium(38))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundColor(.white)
                    .accessibilityIdentifier("manage_account_text")

                Spacer(minLength: 0)
            }
            .padding(.horizontal, VideoDownloadQualityLayout.horizontalPadding)
            .padding(.top, headerTopPadding)
            .padding(.bottom, headerBottomPadding)
            .background(Theme.Colors.brandGreen)
            .accessibilityIdentifier("auth_bg_image")
        }
        .frame(maxWidth: .infinity, minHeight: headerMinHeight, alignment: .top)
        .ignoresSafeArea(edges: .top)
    }

    private func qualityCard(quality: DownloadQuality) -> some View {
        Button(action: {
            analytics.videoQualityChanged(
                .videoDownloadQualityChanged,
                bivalue: .videoDownloadQualityChanged,
                value: quality.value ?? "",
                oldValue: viewModel.selectedDownloadQuality.value ?? ""
            )

            viewModel.selectedDownloadQuality = quality
        }, label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(quality.title)
                        .font(Theme.Fonts.titleMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.Colors.brandGreen)
                    if let description = quality.description {
                        Text(description)
                            .font(Theme.Fonts.bodySmall)
                            .foregroundColor(Theme.Colors.brandCardMedium)
                    }
                }

                Spacer()

                CoreAssets.checkmark.swiftUIImage
                    .renderingMode(.template)
                    .foregroundColor(Theme.Colors.brandGreen)
                    .opacity(quality == viewModel.selectedDownloadQuality ? 1 : 0)
                    .accessibilityIdentifier("checkmark_image")
            }
            .padding(.horizontal, VideoDownloadQualityLayout.cardHorizontalPadding)
            .padding(.vertical, VideoDownloadQualityLayout.cardVerticalPadding)
            .frame(maxWidth: .infinity, minHeight: 66, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: VideoDownloadQualityLayout.cardCornerRadius, style: .continuous)
                    .fill(Theme.Colors.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: VideoDownloadQualityLayout.cardCornerRadius, style: .continuous)
                    .stroke(Color.black.opacity(0.04), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 5, x: 0, y: 2)
        })
        .buttonStyle(.plain)
        .accessibilityIdentifier("select_quality_button")
    }
}

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
                .accessibilityIdentifier("video_quality_title_text")
            if let description {
                Text(description)
                    .font(Theme.Fonts.bodySmall)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .accessibilityIdentifier("video_quality_des_text")
            }
        }
        .foregroundColor(Theme.Colors.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

public extension DownloadQuality {

    var title: String {
        switch self {
        case .auto:
            return CoreLocalization.Settings.downloadQualityAutoTitle
        case .low:
            return CoreLocalization.Settings.downloadQuality360Title
        case .medium:
            return CoreLocalization.Settings.downloadQuality540Title
        case .high:
            return CoreLocalization.Settings.downloadQuality720Title
        }
    }

    var description: String? {
        switch self {
        case .auto:
            return CoreLocalization.Settings.downloadQualityAutoDescription
        case .low:
            return CoreLocalization.Settings.downloadQuality360Description
        case .medium:
            return nil
        case .high:
            return CoreLocalization.Settings.downloadQuality720Description
        }
    }

    var settingsDescription: String {
        switch self {
        case .auto:
            return CoreLocalization.Settings.downloadQualityAutoTitle + " ("
            + CoreLocalization.Settings.downloadQualityAutoDescription + ")"
        case .low:
            return CoreLocalization.Settings.downloadQuality360Title + " ("
            + CoreLocalization.Settings.downloadQuality360Description + ")"
        case .medium:
            return CoreLocalization.Settings.downloadQuality540Title
        case .high:
            return CoreLocalization.Settings.downloadQuality720Title + " ("
            + CoreLocalization.Settings.downloadQuality720Description + ")"
        }
    }
}

#if DEBUG
struct VideoDownloadQualityView_Previews: PreviewProvider {
    static var previews: some View {
        VideoDownloadQualityView(
            downloadQuality: .auto,
            didSelect: nil,
            analytics: CoreAnalyticsMock(),
            router: BaseRouterMock(),
            isModal: true
        )
    }
}
#endif
