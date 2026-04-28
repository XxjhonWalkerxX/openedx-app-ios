//
//  LessonLineProgressView.swift
//  Course
//
//  Fase 5: barra continua 3pt verde (reemplaza segmentos de colores)
//

import SwiftUI
import Theme

struct LessonLineProgressView: View {
    @ObservedObject var viewModel: CourseUnitViewModel
    @Environment(\.isHorizontal) private var isHorizontal

    init(viewModel: CourseUnitViewModel) {
        self.viewModel = viewModel
    }

    private var progress: CGFloat {
        let total = viewModel.verticals[viewModel.verticalIndex].childs.count
        guard total > 0 else { return 0 }
        return CGFloat(viewModel.index + 1) / CGFloat(total)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Theme.Colors.brandProgressTrack)
                Rectangle()
                    .fill(Theme.Colors.brandGreen)
                    .frame(width: geo.size.width * progress)
                    .animation(.easeInOut(duration: 0.25), value: progress)
            }
        }
        .frame(height: 3)
    }
}
