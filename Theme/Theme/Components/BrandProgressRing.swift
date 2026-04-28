//
//  BrandProgressRing.swift
//  Theme
//
//  Anillo de progreso circular — SwiftUI puro, sin CALayer.
//  Uso: ProgressTab, weekly goal card, stats hero.
//

import SwiftUI

public struct BrandProgressRing: View {

    public let progress: Double      // 0.0–1.0
    public let size: CGFloat
    public let lineWidth: CGFloat
    public let trackColor: Color
    public let fillColor: Color
    public let label: String?

    public init(
        progress: Double,
        size: CGFloat = 88,
        lineWidth: CGFloat = 8,
        trackColor: Color = Theme.Colors.brandProgressTrack,
        fillColor: Color = Theme.Colors.brandGreen,
        label: String? = nil
    ) {
        self.progress = min(max(progress, 0), 1)
        self.size = size
        self.lineWidth = lineWidth
        self.trackColor = trackColor
        self.fillColor = fillColor
        self.label = label
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(trackColor, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(fillColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.4), value: progress)

            if let label {
                VStack(spacing: 2) {
                    Text("\(Int(progress * 100))%")
                        .font(Theme.Fonts.notoSans(size * 0.18, weight: .bold))
                        .foregroundStyle(Theme.Colors.brandCardPrimary)
                    Text(label)
                        .font(Theme.Fonts.notoSans(size * 0.11, weight: .medium))
                        .foregroundStyle(Theme.Colors.brandCardSecondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel("\(Int(progress * 100)) por ciento completado\(label.map { ", \($0)" } ?? "")")
    }
}

// MARK: - Preview

#if DEBUG
struct BrandProgressRing_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 24) {
            BrandProgressRing(progress: 0.65, label: "progreso")
            BrandProgressRing(progress: 0.33, size: 56, lineWidth: 5)
            BrandProgressRing(progress: 1.0, size: 44, lineWidth: 4, fillColor: Theme.Colors.guindaColor)
        }
        .padding()
        .background(Theme.Colors.brandCream)
        .loadFonts()
        .previewDisplayName("BrandProgressRing — 3 tamaños")
    }
}
#endif
