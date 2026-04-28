//
//  CourseHeaderView.swift
//  Course
//

import SwiftUI
import Foundation
import Kingfisher
import Core
import Theme

private enum CourseHeaderLayout {
    // Tokens del sistema — ver Theme.Sizes
    static let horizontalPadding: CGFloat = Theme.Sizes.horizontalPadding

    // Dimensiones banner (device-aware)
    static let bannerHeightPad: CGFloat       = 360
    static let bannerHeightLandscape: CGFloat = 280
    static let bannerHeightPortrait: CGFloat  = 300

    // Alturas colapsadas — requeridas por matchedGeometryEffect
    static let collapsedHeightHorizontal: CGFloat = 230
    static let collapsedHeightVertical: CGFloat   = 260

    // Layout expandido
    static let expandedContentHeightFallback: CGFloat = 200
    static let imageOverlap: CGFloat                  = 40

    // Radius legacy card cream — matchedGeometry requiere consistencia exacta.
    // No migrar a Theme.Sizes.radiusSheet (32) sin rediseñar animación colapso.
    static let expandedCardTopRadius: CGFloat = 28

    // Franja guinda superior
    static let guindaBandHeight: CGFloat = 4

    // Collapsed content
    static let collapsedContentTopPadding: CGFloat     = 46
    static let collapsedContentLeadingPadding: CGFloat = 12
    static let collapsedContentBottomPadding: CGFloat  = 12
    static let collapsedBackButtonSize: CGFloat        = 30
    static let collapsedBackButtonOffsetY: CGFloat     = 10

    // Expanded content — paddings top condicionales
    static let expandedOrgTopPadding: CGFloat          = 14
    static let expandedTitleTopPaddingWithOrg: CGFloat = 10
    static let expandedTitleTopPaddingNoOrg: CGFloat   = 14

    // Chips metadata
    static let chipsSpacing: CGFloat          = 8
    static let chipsTopPadding: CGFloat       = 12
    static let chipsBottomPadding: CGFloat    = 14
    static let chipHorizontalPadding: CGFloat = 10
    static let chipVerticalPadding: CGFloat   = 4
    static let noChipsSpacerHeight: CGFloat   = 14

    // Org badge
    static let orgBadgeSpacing: CGFloat           = 5
    static let orgBadgeDotSize: CGFloat           = 5
    static let orgBadgeHorizontalPadding: CGFloat = 10
    static let orgBadgeVerticalPadding: CGFloat   = 4
    static let orgBadgeMaxWidthRatio: CGFloat     = 0.55

    // Sync con CourseContainerView.coordinateBoundaryLower
    static let coordinateBoundaryLower: CGFloat = 115
}

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

    private var bannerHeight: CGFloat {
        if idiom == .pad {
            return CourseHeaderLayout.bannerHeightPad
        }
        return isHorizontal
            ? CourseHeaderLayout.bannerHeightLandscape
            : CourseHeaderLayout.bannerHeightPortrait
    }
    @State private var measuredContentHeight: CGFloat = 0
    private var contentHeight: CGFloat {
        measuredContentHeight > 0 ? measuredContentHeight : CourseHeaderLayout.expandedContentHeightFallback
    }
    private var expandedHeight: CGFloat { bannerHeight + contentHeight - CourseHeaderLayout.imageOverlap }

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
            .padding(.top, collapsed ? 0 : (bannerHeight - CourseHeaderLayout.imageOverlap))
        }
        // Aplicamos fondo solamente en expansión para no bloquear la lista inferior
        .background(collapsed ? Color.clear : Theme.Colors.background)
        .frame(
            height: collapsed ? (
                isHorizontal
                    ? CourseHeaderLayout.collapsedHeightHorizontal
                    : CourseHeaderLayout.collapsedHeightVertical
            ) : expandedHeight,
            alignment: .top
        )
        .ignoresSafeArea(edges: .top)
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        // Reportar altura visible: cuando colapsado, el header sube
                        // coordinateBoundaryLower (ver CourseContainerView),
                        // spacer = frame - boundary para no dejar hueco.
                        headerHeight = collapsed
                            ? max(0, proxy.size.height - CourseHeaderLayout.coordinateBoundaryLower)
                            : proxy.size.height
                    }
                    .onChange(of: proxy.size.height) { newValue in
                        headerHeight = collapsed
                            ? max(0, newValue - CourseHeaderLayout.coordinateBoundaryLower)
                            : newValue
                    }
                    .onChange(of: collapsed) { newCollapsed in
                        headerHeight = newCollapsed
                            ? max(0, proxy.size.height - CourseHeaderLayout.coordinateBoundaryLower)
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
                .frame(
                    width: CourseHeaderLayout.collapsedBackButtonSize,
                    height: CourseHeaderLayout.collapsedBackButtonSize
                )
                .offset(y: CourseHeaderLayout.collapsedBackButtonOffsetY)
                Text(title)
                    .lineLimit(1)
                    .foregroundStyle(Theme.Colors.brandGreen)
                    .font(Theme.Fonts.notoSans(14, weight: .semibold))
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    .clipped()
            }
            .padding(.top, CourseHeaderLayout.collapsedContentTopPadding)
            .padding(.leading, CourseHeaderLayout.collapsedContentLeadingPadding)
            courseMenuBar(containerWidth: containerWidth)
                .matchedGeometryEffect(id: GeometryName.topTabBar, in: animationNamespace)
                .padding(.bottom, CourseHeaderLayout.collapsedContentBottomPadding)
        }
        .background(
            ZStack(alignment: .top) {
                Theme.Colors.brandCream
                    .matchedGeometryEffect(id: GeometryName.blurPrimaryBg, in: animationNamespace)
                    .ignoresSafeArea(edges: .top) // Ignora top safe area para pintar detrás de la batería/notch
                Theme.Colors.guindaColor
                    .frame(height: CourseHeaderLayout.guindaBandHeight)
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
                    .padding(.top, CourseHeaderLayout.expandedOrgTopPadding)
            }
            Text(title)
                .lineLimit(3)
                .font(Theme.Fonts.notoSans(17, weight: .bold))
                .foregroundColor(Theme.Colors.brandCardPrimary)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, CourseHeaderLayout.horizontalPadding)
                .padding(.top, hasOrg
                    ? CourseHeaderLayout.expandedTitleTopPaddingWithOrg
                    : CourseHeaderLayout.expandedTitleTopPaddingNoOrg)
                .allowsHitTesting(false)
                .frameLimit(width: containerWidth)
            if !metadataChips.isEmpty {
                HStack(spacing: CourseHeaderLayout.chipsSpacing) {
                    ForEach(metadataChips, id: \.self) { label in
                        Text(label)
                            .font(Theme.Fonts.notoSans(11, weight: .semibold))
                            .foregroundColor(Theme.Colors.brandCardMedium)
                            .padding(.horizontal, CourseHeaderLayout.chipHorizontalPadding)
                            .padding(.vertical, CourseHeaderLayout.chipVerticalPadding)
                            .background(
                                Capsule().fill(Theme.Colors.brandCreamStrong)
                            )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, CourseHeaderLayout.horizontalPadding)
                .padding(.top, CourseHeaderLayout.chipsTopPadding)
                .padding(.bottom, CourseHeaderLayout.chipsBottomPadding)
                .allowsHitTesting(false)
                .frameLimit(width: containerWidth)
            } else {
                Spacer().frame(height: CourseHeaderLayout.noChipsSpacerHeight)
            }
            courseMenuBar(containerWidth: containerWidth)
                .matchedGeometryEffect(id: GeometryName.topTabBar, in: animationNamespace)
                .padding(.bottom, CourseHeaderLayout.collapsedContentBottomPadding)
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
                UnevenRoundedRectangle(
                    topLeadingRadius: CourseHeaderLayout.expandedCardTopRadius,
                    topTrailingRadius: CourseHeaderLayout.expandedCardTopRadius
                )
                .fill(Theme.Colors.brandCream)
                .matchedGeometryEffect(id: GeometryName.blurPrimaryBg, in: animationNamespace)
                Theme.Colors.guindaColor
                    .frame(height: CourseHeaderLayout.guindaBandHeight)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: CourseHeaderLayout.expandedCardTopRadius,
                            topTrailingRadius: CourseHeaderLayout.expandedCardTopRadius
                        )
                    )
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
        HStack(spacing: CourseHeaderLayout.orgBadgeSpacing) {
            Circle()
                .fill(Theme.Colors.brandGreen)
                .frame(
                    width: CourseHeaderLayout.orgBadgeDotSize,
                    height: CourseHeaderLayout.orgBadgeDotSize
                )
            Text(org)
                .font(Theme.Fonts.notoSans(11, weight: .semibold))
                .foregroundColor(Theme.Colors.brandGreen)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .padding(.horizontal, CourseHeaderLayout.orgBadgeHorizontalPadding)
        .padding(.vertical, CourseHeaderLayout.orgBadgeVerticalPadding)
        .background(
            Capsule()
                .fill(Theme.Colors.brandGreen.opacity(0.1))
        )
        .overlay(
            Capsule()
                .stroke(Theme.Colors.brandGreen.opacity(0.3), lineWidth: 0.5)
        )
        .frame(maxWidth: containerWidth * CourseHeaderLayout.orgBadgeMaxWidthRatio, alignment: .leading)
        .padding(.horizontal, CourseHeaderLayout.horizontalPadding)
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
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(CourseTab.allCases, id: \.id) { tab in
                        let isSelected = viewModel.selection == tab.rawValue
                        Button {
                            HapticFeedback.selection()
                            isAnimatingForTap = true
                            viewModel.selection = tab.rawValue
                            DispatchQueue.main.asyncAfter(deadline: .now().advanced(by: .milliseconds(300))) {
                                isAnimatingForTap = false
                            }
                        } label: {
                            Text(tab.title)
                                .font(Theme.Fonts.notoSans(12, weight: isSelected ? .semibold : .regular))
                                .foregroundColor(isSelected ? .white : Theme.Colors.brandCardPrimary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(
                                    Capsule()
                                        .fill(isSelected ? Theme.Colors.brandGreen : Theme.Colors.brandCreamStrong)
                                )
                        }
                        .buttonStyle(.plain)
                        .id(tab.rawValue)
                    }
                }
                .padding(.horizontal, CourseHeaderLayout.horizontalPadding)
                .padding(.vertical, 8)
            }
            .background(Theme.Colors.brandCream)
            .overlay(
                Rectangle()
                    .fill(Theme.Colors.brandDivider)
                    .frame(height: 1),
                alignment: .bottom
            )
            .frame(height: 48)
            .onChange(of: viewModel.selection) { newValue in
                withAnimation { proxy.scrollTo(newValue, anchor: .center) }
            }
        }
    }
}
