//
//  CourseHeaderView.swift
//  Course
//

import SwiftUI
import Foundation
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
    @Binding private var headerHeight: CGFloat
    @Environment(\.isHorizontal) private var isHorizontal
    private var idiom: UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }

    private let collapsedHorizontalHeight: CGFloat = 230
    private let collapsedVerticalHeight: CGFloat = 260
    private var bannerHeight: CGFloat {
        if idiom == .pad {
            return 380
        }
        return isHorizontal ? 300 : 340
    }
    private let expandedContentHeight: CGFloat = 200
    private let imageOverlap: CGFloat = 40
    @State private var measuredContentHeight: CGFloat = 0
    private var contentHeight: CGFloat {
        measuredContentHeight > 0 ? measuredContentHeight : expandedContentHeight
    }
    private var expandedHeight: CGFloat { bannerHeight + contentHeight - imageOverlap }

    private let courseRawImage: String?
    private static let courseEndFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es")
        formatter.dateFormat = "MMM yyyy"
        return formatter
    }()

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
        courseRawImage: String?,
        headerHeight: Binding<CGFloat>
    ) {
        self.viewModel = viewModel
        self.title = title
        self._collapsed = collapsed
        self.containerWidth = containerWidth
        self.animationNamespace = animationNamespace
        self._isAnimatingForTap = isAnimatingForTap
        self.courseRawImage = courseRawImage
        self._headerHeight = headerHeight
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Banner image — altura colapsada a 0 + opacidad 0 para eliminar derrame
            ZStack {
                if let banner = (courseRawImage ?? viewModel.courseStructure?.media.image.raw)?
                    .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                    GeometryReader { proxy in
                        KFImage(courseBannerURL(for: banner))
                            .onFailureImage(CoreAssets.noCourseImage.image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .center)
                            .allowsHitTesting(false)
                            .clipped()
                            .background(Theme.Colors.background)
                    }
                }
            }
            .frame(height: collapsed ? 0 : bannerHeight)
            .clipped()
            .opacity(collapsed ? 0 : 1)
            .ignoresSafeArea(edges: .top)

            VStack(alignment: .leading) {
                if collapsed {
                    collapsedContent
                } else {
                    expandedContent
                }
            }
            .padding(.top, collapsed ? 0 : (bannerHeight - imageOverlap))
        }
        // Aplicamos fondo solamente en expansión para no bloquear la lista inferior
        .background(collapsed ? Color.clear : Theme.Colors.background)
        .frame(
            height: collapsed ? (
                isHorizontal ? collapsedHorizontalHeight : collapsedVerticalHeight
            ) : expandedHeight,
            alignment: .top
        )
        .ignoresSafeArea(edges: .top)
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        // Reportar altura visible: cuando colapsado, el header sube
                        // 115pt (coordinateBoundaryLower en CourseContainerView),
                        // así que el spacer debe ser frame - 115 para no dejar hueco.
                        headerHeight = collapsed
                            ? max(0, proxy.size.height - 115)
                            : proxy.size.height
                    }
                    .onChange(of: proxy.size.height) { newValue in
                        headerHeight = collapsed
                            ? max(0, newValue - 115)
                            : newValue
                    }
                    .onChange(of: collapsed) { newCollapsed in
                        headerHeight = newCollapsed
                            ? max(0, proxy.size.height - 115)
                            : proxy.size.height
                    }
            }
        )
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
        .background(
            ZStack(alignment: .top) {
                Theme.Colors.brandCream
                    .matchedGeometryEffect(id: GeometryName.blurPrimaryBg, in: animationNamespace)
                    .ignoresSafeArea(edges: .top) // Ignora top safe area para pintar detrás de la batería/notch
                Theme.Colors.guindaColor
                    .frame(height: 4)
                    .matchedGeometryEffect(id: GeometryName.blurSecondaryBg, in: animationNamespace)
                    // La franja guinda queda contenida, pero el fondo crema sube a tapar todo
            }
        )
    }

    // MARK: - Estado expandido

    private var expandedContent: some View {
        VStack(spacing: 0) {
            let hasOrg = (viewModel.courseStructure?.org.isEmpty == false)
            if let org = viewModel.courseStructure?.org {
                orgBadge(org: org)
                    .padding(.top, 14)
            }
            Text(title)
                .lineLimit(3)
                .font(Theme.Fonts.ttRoundsCompressedMedium(18))
                .foregroundColor(Theme.Colors.brandCardPrimary)
                .kerning(-0.3)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 20)
                .padding(.top, hasOrg ? 10 : 14)
                .allowsHitTesting(false)
                .frameLimit(width: containerWidth)
            if !metadataChips.isEmpty {
                HStack(spacing: 8) {
                    ForEach(metadataChips, id: \.self) { label in
                        Text(label)
                            .font(Theme.Fonts.ttRoundsBody(11, weight: 700))
                            .foregroundColor(Theme.Colors.brandCardMedium)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule().fill(Theme.Colors.brandCreamStrong)
                            )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 14)
                .allowsHitTesting(false)
                .frameLimit(width: containerWidth)
            } else {
                Spacer().frame(height: 14)
            }
            courseMenuBar(containerWidth: containerWidth)
                .matchedGeometryEffect(id: GeometryName.topTabBar, in: animationNamespace)
                .padding(.bottom, 12)
        }
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        measuredContentHeight = proxy.size.height
                    }
                    .onChange(of: proxy.size.height) { newValue in
                        measuredContentHeight = newValue
                    }
            }
        )
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
        HStack(spacing: 5) {
            Circle()
                .fill(Theme.Colors.brandGreen)
                .frame(width: 5, height: 5)
            Text(org)
                .font(Theme.Fonts.ttRoundsBody(11, weight: 600))
                .foregroundColor(Theme.Colors.brandGreen)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Theme.Colors.brandGreen.opacity(0.1))
        )
        .overlay(
            Capsule()
                .stroke(Theme.Colors.brandGreen.opacity(0.3), lineWidth: 0.5)
        )
        .frame(maxWidth: containerWidth * 0.55, alignment: .leading)
        .padding(.horizontal, 20)
        .allowsHitTesting(false)
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        .frameLimit(width: containerWidth)
    }

    private var metadataChips: [String] {
        var chips: [String] = []
        if let isSelfPaced = viewModel.courseStructure?.isSelfPaced {
            chips.append(isSelfPaced ? "A tu ritmo" : "Con instructor")
        }
        if let end = viewModel.courseEnd {
            chips.append("Hasta \(Self.courseEndFormatter.string(from: end))")
        }
        return chips
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
