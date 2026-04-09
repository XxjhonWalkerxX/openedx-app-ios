//
//  CourseHeaderView.swift
//  Course
//

import SwiftUI
import Kingfisher
import Core
import Theme

struct CourseHeaderView: View {

    @ObservedObject var viewModel: CourseContainerViewModel
    private var title: String
    private var containerWidth: CGFloat
    private var animationNamespace: Namespace.ID
    @Binding private var collapsed: Bool
    @Binding private var isAnimatingForTap: Bool
    @Environment(\.isHorizontal) private var isHorizontal

    private let collapsedHorizontalHeight: CGFloat = 230
    private let collapsedVerticalHeight: CGFloat = 260
    private let expandedHeight: CGFloat = 420

    private let courseRawImage: String?

    private enum GeometryName {
        case backButton
        case topTabBar
        case blurSecondaryBg
        case blurPrimaryBg
        case blurBg
    }

    init(
        viewModel: CourseContainerViewModel,
        title: String,
        collapsed: Binding<Bool>,
        containerWidth: CGFloat,
        animationNamespace: Namespace.ID,
        isAnimatingForTap: Binding<Bool>,
        courseRawImage: String?
    ) {
        self.viewModel = viewModel
        self.title = title
        self._collapsed = collapsed
        self.containerWidth = containerWidth
        self.animationNamespace = animationNamespace
        self._isAnimatingForTap = isAnimatingForTap
        self.courseRawImage = courseRawImage
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Banner image — sin cambios
            ScrollView {
                if let banner = (courseRawImage ?? viewModel.courseStructure?.media.image.raw)?
                    .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                    KFImage(courseBannerURL(for: banner))
                        .onFailureImage(CoreAssets.noCourseImage.image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxHeight: expandedHeight, alignment: .center)
                        .allowsHitTesting(false)
                        .clipped()
                        .background(Theme.Colors.background)
                }
            }
            .disabled(true)
            .ignoresSafeArea()

            VStack(alignment: .leading) {
                if collapsed {
                    collapsedContent
                } else {
                    expandedContent
                }
            }
        }
        .background(Theme.Colors.background)
        .frame(
            height: collapsed ? (
                isHorizontal ? collapsedHorizontalHeight : collapsedVerticalHeight
            ) : expandedHeight
        )
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Estado colapsado

    private var collapsedContent: some View {
        VStack(spacing: 0) {
            HStack {
                BackNavigationButton(
                    color: Theme.Colors.brandGreen,
                    action: { viewModel.router.back() }
                )
                .backViewStyle()
                .matchedGeometryEffect(id: GeometryName.backButton, in: animationNamespace)
                .frame(width: 30, height: 30)
                .offset(y: 10)
                Text(title)
                    .lineLimit(1)
                    .foregroundStyle(Theme.Colors.brandGreen)
                    .font(Theme.Fonts.ttRoundsCompressedMedium(15))
                    .kerning(-0.2)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    .clipped()
            }
            .padding(.top, 46)
            .padding(.leading, 12)
            courseMenuBar(containerWidth: containerWidth)
                .matchedGeometryEffect(id: GeometryName.topTabBar, in: animationNamespace)
                .padding(.bottom, 12)
        }
        .background {
            ZStack(alignment: .top) {
                Theme.Colors.brandCream
                    .matchedGeometryEffect(id: GeometryName.blurPrimaryBg, in: animationNamespace)
                Theme.Colors.guindaColor
                    .frame(height: 4)
                    .matchedGeometryEffect(id: GeometryName.blurSecondaryBg, in: animationNamespace)
                Color.clear
                    .matchedGeometryEffect(id: GeometryName.blurBg, in: animationNamespace)
                    .ignoresSafeArea()
            }
        }
    }

    // MARK: - Estado expandido

    private var expandedContent: some View {
        VStack(spacing: 0) {
            Text(title)
                .lineLimit(4)
                .font(Theme.Fonts.ttRoundsCompressedMedium(28))
                .foregroundColor(Theme.Colors.brandCardPrimary)
                .kerning(-0.3)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .allowsHitTesting(false)
                .frameLimit(width: containerWidth)
            if let org = viewModel.courseStructure?.org {
                orgBadge(org: org)
            }
            courseMenuBar(containerWidth: containerWidth)
                .matchedGeometryEffect(id: GeometryName.topTabBar, in: animationNamespace)
                .padding(.bottom, 12)
        }
        .background {
            ZStack(alignment: .top) {
                UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28)
                    .fill(Theme.Colors.brandCream)
                    .matchedGeometryEffect(id: GeometryName.blurPrimaryBg, in: animationNamespace)
                Theme.Colors.guindaColor
                    .frame(height: 4)
                    .clipShape(UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28))
                    .matchedGeometryEffect(id: GeometryName.blurSecondaryBg, in: animationNamespace)
                Color.clear
                    .matchedGeometryEffect(id: GeometryName.blurBg, in: animationNamespace)
                    .allowsHitTesting(false)
                    .ignoresSafeArea()
            }
        }
    }

    // MARK: - Org Badge

    private func orgBadge(org: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.white)
                .frame(width: 5, height: 5)
            Text(org)
                .font(Theme.Fonts.ttRoundsBody(11, weight: 600))
                .foregroundColor(.white)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Capsule().fill(Theme.Colors.brandGreen))
        .frame(maxWidth: containerWidth * 0.55, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .allowsHitTesting(false)
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        .frameLimit(width: containerWidth)
    }

    // MARK: - Helpers (sin cambios)

    private func courseBannerURL(for path: String) -> URL? {
        if path.contains("http://") || path.contains("https://") {
            return URL(string: path)
        }
        return URL(string: viewModel.config.baseURL.absoluteString + path)
    }

    private func courseMenuBar(containerWidth: CGFloat) -> some View {
        ScrollSlidingTabBar(
            selection: $viewModel.selection,
            tabs: CourseTab.allCases.map { ($0.title, $0.image) },
            style: ScrollSlidingTabBar.Style(
                font: Theme.Fonts.titleSmall,
                selectedFont: Theme.Fonts.titleSmall,
                activeAccentColor: Theme.Colors.brandGreen,
                inactiveAccentColor: Theme.Colors.background,
                indicatorHeight: 0,
                borderColor: Theme.Colors.brandGreen,
                borderHeight: 1,
                buttonHInset: 4,
                buttonVInset: 2,
                buttonLeadingPadding: 8,
                buttonTrailingPadding: 8
            ),
            containerWidth: containerWidth
        ) { newValue in
            isAnimatingForTap = true
            viewModel.selection = newValue
            DispatchQueue.main.asyncAfter(deadline: .now().advanced(by: .milliseconds(300))) {
                isAnimatingForTap = false
            }
        }
    }
}
