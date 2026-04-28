//
//  BrandTabBar.swift
//  Theme
//
//  Fase 2: tab bar flotante con glass effect / ultraThinMaterial fallback
//

import SwiftUI

public struct BrandTabItem<ID: Hashable>: Identifiable {
    public let id: ID
    public let icon: String
    public let activeIcon: String
    public let label: String

    public init(id: ID, icon: String, activeIcon: String, label: String) {
        self.id = id
        self.icon = icon
        self.activeIcon = activeIcon
        self.label = label
    }
}

public struct BrandTabBar<ID: Hashable & Equatable>: View {
    public let tabs: [BrandTabItem<ID>]
    @Binding public var selection: ID

    public init(tabs: [BrandTabItem<ID>], selection: Binding<ID>) {
        self.tabs = tabs
        self._selection = selection
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.id) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(barBackground)
        .clipShape(Capsule())
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .shadow(color: .black.opacity(0.22), radius: 18, x: 0, y: 6)
    }

    @ViewBuilder
    private func tabButton(for tab: BrandTabItem<ID>) -> some View {
        let isActive = selection == tab.id
        Button {
            guard !isActive else { return }
            HapticFeedback.selection()
            withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                selection = tab.id
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: isActive ? tab.activeIcon : tab.icon)
                    .font(.system(size: 19, weight: isActive ? .semibold : .regular))
                Text(tab.label)
                    .font(Theme.Fonts.notoSans(9, weight: isActive ? .semibold : .regular))
            }
            .foregroundColor(isActive ? .white : .white.opacity(0.55))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background {
                if isActive {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Theme.Colors.brandGreen)
                        .padding(.horizontal, 6)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.label)
    }

    @ViewBuilder
    private var barBackground: some View {
        ZStack {
            Capsule()
                .fill(.ultraThinMaterial)
            Capsule()
                .fill(Color.black.opacity(0.35))
        }
    }
}

#if DEBUG
private enum PreviewTab: String, Hashable, CaseIterable {
    case learn, discover, profile
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [Theme.Colors.brandGreenDark, Theme.Colors.brandCream],
            startPoint: .top, endPoint: .bottom
        )
        .ignoresSafeArea()

        VStack {
            Spacer()
            BrandTabBar(
                tabs: [
                    BrandTabItem(id: PreviewTab.learn,    icon: "house",              activeIcon: "house.fill",              label: "Aprende"),
                    BrandTabItem(id: PreviewTab.discover, icon: "magnifyingglass",    activeIcon: "magnifyingglass",         label: "Descubre"),
                    BrandTabItem(id: PreviewTab.profile,  icon: "person.crop.circle", activeIcon: "person.crop.circle.fill", label: "Perfil")
                ],
                selection: .constant(PreviewTab.learn)
            )
            .padding(.bottom, 8)
        }
    }
}
#endif
