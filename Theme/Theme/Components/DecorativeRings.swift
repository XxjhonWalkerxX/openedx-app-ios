//
//  DecorativeRings.swift
//  Theme
//
//  Círculos decorativos animados con TimelineView + Canvas.
//  Uso: hero Dashboard, hero Profile, weekly goal card, featured Discovery card.
//

import SwiftUI

/// Anillos blancos semi-transparentes con rotación lenta (~3°/s).
/// No afecta scroll perf — Canvas off-screen no calcula frames.
public struct DecorativeRings: View {

    public init() {}

    public var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            Canvas { gctx, size in
                let center = CGPoint(x: size.width * 0.85, y: size.height * 0.4)
                for i in 1...4 {
                    let r = CGFloat(60 + i * 40)
                    let rect = CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)
                    let path = Path(ellipseIn: rect)
                    gctx.stroke(path, with: .color(.white.opacity(0.08)), lineWidth: 1)
                }
            }
            .rotationEffect(.radians(t * 0.05))
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

#if DEBUG
struct DecorativeRings_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Theme.Colors.guindaColor
                .ignoresSafeArea()
            DecorativeRings()
        }
        .frame(height: 200)
        .previewDisplayName("DecorativeRings — hero guinda")
    }
}
#endif
