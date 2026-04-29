import SwiftUI
import Core
import Theme
import Swinject

// MARK: - CourseMoreTabView

/// Tab "Más" del Hub: combina Offline + Handouts en un picker segmentado.
struct CourseMoreTabView: View {

    let courseID: String
    let title: String
    @ObservedObject var viewModel: CourseContainerViewModel

    @State private var segment: Int = 0
    @State private var coordinate: CGFloat = .zero
    @State private var collapsed: Bool = false
    @State private var viewHeight: CGFloat = .zero

    var body: some View {
        VStack(spacing: 0) {
            segmentedPicker
            segmentedContent
        }
        .background(Theme.Colors.brandCream)
    }

    // MARK: - Segmented Picker

    private var segmentedPicker: some View {
        HStack(spacing: 0) {
            segmentButton(label: CourseLocalization.CourseContainer.offline, index: 0)
            segmentButton(label: CourseLocalization.CourseContainer.handouts, index: 1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Theme.Colors.brandCream)
        .overlay(Divider(), alignment: .bottom)
    }

    private func segmentButton(label: String, index: Int) -> some View {
        let isSelected = segment == index
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                segment = index
                // Reset scroll position when switching tabs
                coordinate = .zero
                collapsed = false
            }
        } label: {
            Text(label)
                .font(Theme.Fonts.notoSans(13, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .white : Theme.Colors.brandGreen)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .frame(maxWidth: .infinity)
                .background(
                    Capsule()
                        .fill(isSelected ? Theme.Colors.brandGreen : Theme.Colors.surfaceWhite)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(
                            isSelected ? Color.clear : Theme.Colors.brandCreamStrong,
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Content

    @ViewBuilder
    private var segmentedContent: some View {
        if segment == 0 {
            OfflineView(
                courseID: courseID,
                coordinate: $coordinate,
                collapsed: $collapsed,
                viewHeight: $viewHeight,
                viewModel: viewModel
            )
        } else {
            HandoutsView(
                courseID: courseID,
                coordinate: $coordinate,
                collapsed: $collapsed,
                viewHeight: $viewHeight,
                viewModel: Container.shared.resolve(HandoutsViewModel.self, argument: courseID)!
            )
        }
    }
}
