//
//  HeroGradientView.swift
//  Core
//
//  Componente reutilizable: patrón Hero + Card de @prende.mx
//  Replica el diseño Android de OnboardingScreen, DashboardHero, ProfileHero, etc.
//

import SwiftUI
import Theme

public struct HeroGradientView<HeroContent: View, CardContent: View>: View {
    let heroHeight: CGFloat
    let cardOffset: CGFloat
    let showGuindaStripe: Bool
    @ViewBuilder let heroContent: () -> HeroContent
    @ViewBuilder let cardContent: () -> CardContent

    public init(
        heroHeight: CGFloat = 280,
        cardOffset: CGFloat = -28,
        showGuindaStripe: Bool = true,
        @ViewBuilder heroContent: @escaping () -> HeroContent,
        @ViewBuilder cardContent: @escaping () -> CardContent
    ) {
        self.heroHeight = heroHeight
        self.cardOffset = cardOffset
        self.showGuindaStripe = showGuindaStripe
        self.heroContent = heroContent
        self.cardContent = cardContent
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero zone
                ZStack(alignment: .top) {
                    // Gradient background
                    Theme.Gradients.heroGradient
                        .frame(height: heroHeight)

                    // Decorative circles
                    DecorativeCirclesView()
                        .frame(height: heroHeight)
                        .clipped()

                    // Guinda stripe
                    if showGuindaStripe {
                        Theme.Colors.guindaColor
                            .frame(height: 4)
                    }

                    // Hero content
                    heroContent()
                }
                .frame(height: heroHeight)

                // Card zone - cream surface overlapping the hero
                VStack(spacing: 0) {
                    // Handle
                    Capsule()
                        .fill(Theme.Colors.brandHandle)
                        .frame(width: 36, height: 4)
                        .padding(.top, 12)

                    cardContent()
                }
                .frame(maxWidth: .infinity)
                .background(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 32,
                        topTrailingRadius: 32
                    )
                    .fill(Theme.Colors.brandCream)
                )
                .offset(y: cardOffset)
            }
        }
        .background(Theme.Colors.brandCream)
        .ignoresSafeArea(edges: .top)
    }
}

// MARK: - Decorative Circles (replicating Android DecorativeCircles)
public struct DecorativeCirclesView: View {
    public init() {}

    public var body: some View {
        ZStack {
            // Large circle top-right
            Circle()
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 36)
                .frame(width: 220, height: 220)
                .offset(x: 240, y: -60)

            // Medium circle bottom-left
            Circle()
                .strokeBorder(Color.white.opacity(0.05), lineWidth: 22)
                .frame(width: 130, height: 130)
                .offset(x: -30, y: 280)

            // Small circle mid-right
            Circle()
                .strokeBorder(Color.white.opacity(0.07), lineWidth: 14)
                .frame(width: 80, height: 80)
                .offset(x: 300, y: 200)
        }
        .allowsHitTesting(false)
    }
}
