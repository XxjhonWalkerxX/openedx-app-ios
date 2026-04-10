//
//  ResponsiveView.swift
//  Core
//
//  Created by  Stepanok Ivan on 26.03.2024.
//

import SwiftUI

public struct DynamicOffsetView: View {
    
    private let padHeight: CGFloat = 290
    private let collapsedHorizontalHeight: CGFloat = 120
    private let collapsedVerticalHeight: CGFloat = 100
    private var expandedHeight: CGFloat {
        let topInset = UIApplication.shared.windowInsets.top
        guard topInset > 0 else {
            return 240
        }
        return 300 - topInset
    }
    private let coordinateBoundaryLower: CGFloat = -115
    private var idiom: UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
    
    @Binding private var coordinate: CGFloat
    @Binding private var collapsed: Bool
    @Binding private var viewHeight: CGFloat
    private var externalHeight: Binding<CGFloat>?
    @State private var collapseHeight: CGFloat = .zero
    
    @Environment(\.isHorizontal) private var isHorizontal
    
    @State private var isOnTheScreen: Bool = false
    public init(
        coordinate: Binding<CGFloat>,
        collapsed: Binding<Bool>,
        viewHeight: Binding<CGFloat>,
        externalHeight: Binding<CGFloat>? = nil
    ) {
        self._coordinate = coordinate
        self._collapsed = collapsed
        self._viewHeight = viewHeight
        self.externalHeight = externalHeight
    }

    private var externalHeightValue: CGFloat {
        externalHeight?.wrappedValue ?? 0
    }

    private var effectiveHeight: CGFloat {
        if externalHeightValue > 0 {
            return externalHeightValue
        }
        return collapseHeight
    }
    
    public var body: some View {
        VStack {
        }
        .frame(height: effectiveHeight)
        .overlay(
            GeometryReader { geometry -> Color in
                if !isOnTheScreen {
                    return .clear
                }
                guard idiom != .pad else {
                    return .clear
                }
                guard !isHorizontal else {
                    coordinate = coordinateBoundaryLower
                    return .clear
                }
                DispatchQueue.main.async {
                    coordinate = geometry.frame(in: .global).minY
                }
                return .clear
            }
        )
        .onAppear {
            isOnTheScreen = true
            if externalHeightValue > 0 {
                collapseHeight = externalHeightValue
                viewHeight = collapseHeight
            } else {
                changeCollapsedHeight(collapsed: collapsed, isHorizontal: isHorizontal)
            }
        }
        .onDisappear {
            isOnTheScreen = false
        }
        .onChange(of: collapsed) { collapsed in
            if externalHeightValue > 0 {
                collapseHeight = externalHeightValue
                viewHeight = collapseHeight
            } else if !collapsed {
                changeCollapsedHeight(collapsed: collapsed, isHorizontal: isHorizontal)
            }
        }
        .onChange(of: isHorizontal) { isHorizontal in
            if isHorizontal {
                collapsed = true
            }
            if externalHeightValue > 0 {
                collapseHeight = externalHeightValue
                viewHeight = collapseHeight
            } else {
                changeCollapsedHeight(collapsed: collapsed, isHorizontal: isHorizontal)
            }
        }
        .onChange(of: externalHeightValue) { newValue in
            guard newValue > 0 else { return }
            collapseHeight = newValue
            viewHeight = collapseHeight
        }
    }
    
    private func changeCollapsedHeight(
        collapsed: Bool,
        isHorizontal: Bool
    ) {
        if idiom == .pad {
            collapseHeight = padHeight
        } else if collapsed {
            if isHorizontal {
                collapseHeight = collapsedHorizontalHeight
            } else {
                collapseHeight = collapsedVerticalHeight
            }
        } else {
            collapseHeight = expandedHeight
        }
        viewHeight = collapseHeight
    }
}
