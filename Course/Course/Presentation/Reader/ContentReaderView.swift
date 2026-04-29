import SwiftUI
import Core
import Theme

// MARK: - ContentReaderView

/// Lector inmersivo de contenido.
/// TabView paginado por verticals dentro del sequential activo.
/// Gestiona navegación cross-sequential, completion y sheet de celebración de unidad.
public struct ContentReaderView: View {

    @ObservedObject public var viewModel: ContentReaderViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(viewModel: ContentReaderViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    public var body: some View {
        ZStack(alignment: .top) {
            Theme.Colors.brandCream
                .ignoresSafeArea()

            // MARK: Pages
            TabView(selection: $viewModel.verticalIndex) {
                ForEach(Array(viewModel.currentVerticals.enumerated()), id: \.element.id) { idx, vertical in
                    VerticalRenderer(
                        vertical: vertical,
                        courseID: viewModel.courseID,
                        onScrollChange: { viewModel.updateScrollOffset($0) }
                    )
                    .tag(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
            // Recrear TabView al cambiar sequential → reset limpio de paginación
            .id(viewModel.currentSequential.id)
            .animation(
                reduceMotion ? .none : .easeInOut(duration: 0.28),
                value: viewModel.currentSequential.id
            )

            // MARK: Top Bar
            VStack(spacing: 0) {
                ReaderTopBar(
                    title: viewModel.currentSequential.displayName,
                    subtitle: viewModel.currentChapter.displayName,
                    currentIndex: viewModel.verticalIndex,
                    totalCount: viewModel.currentVerticals.count,
                    segments: viewModel.progressSegments,
                    isVisible: viewModel.isTopBarVisible,
                    onClose: { viewModel.router.back() },
                    onSegmentTap: { viewModel.jumpTo(verticalIndex: $0) }
                )
                Spacer()
            }

            // MARK: Bottom Bar
            VStack(spacing: 0) {
                Spacer()
                ReaderBottomBar(
                    canGoPrevious: viewModel.canGoPrevious,
                    canGoNext: viewModel.canGoNext,
                    isCompleted: viewModel.isCurrentVerticalComplete,
                    isLoading: viewModel.isMarkingComplete,
                    onPrevious: { viewModel.goPrevious() },
                    onComplete: { viewModel.markComplete() },
                    onNext: { viewModel.goNext() }
                )
            }
            .ignoresSafeArea(edges: .bottom)

            // MARK: Boundary Label Overlay
            if let label = viewModel.boundaryLabel {
                VStack {
                    Spacer()
                    Text(label)
                        .font(Theme.Fonts.notoSans(13, weight: .semibold))
                        .foregroundStyle(Theme.Colors.surfaceWhite)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(
                            Capsule().fill(Color.black.opacity(0.72))
                        )
                    Spacer().frame(height: 80)
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.25), value: viewModel.boundaryLabel)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $viewModel.showChapterCompletionSheet) {
            ChapterCompletionSheet(viewModel: viewModel)
                .presentationDetents([.medium])
        }
    }
}

// MARK: - ChapterCompletionSheet

private struct ChapterCompletionSheet: View {
    @ObservedObject var viewModel: ContentReaderViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            Capsule()
                .fill(Theme.Colors.brandCreamStrong)
                .frame(width: 40, height: 4)
                .padding(.top, 14)

            Spacer().frame(height: 28)

            // Icon
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundStyle(Theme.Colors.brandGreen)

            Spacer().frame(height: 20)

            // Title + chapter name
            Text("¡Unidad completada!")
                .font(Theme.Fonts.notoSans(20, weight: .bold))
                .foregroundStyle(Theme.Colors.textPrimary)
            Spacer().frame(height: 6)
            Text(viewModel.currentChapter.displayName)
                .font(Theme.Fonts.notoSans(14, weight: .regular))
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer().frame(height: 32)

            // CTAs
            VStack(spacing: 12) {
                if viewModel.chapterIndex < viewModel.chapters.count - 1 {
                    Button(action: { viewModel.advanceToNextChapter() }) {
                        Text("Siguiente unidad")
                            .font(Theme.Fonts.notoSans(15, weight: .semibold))
                            .foregroundStyle(Theme.Colors.surfaceWhite)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Capsule().fill(Theme.Colors.brandGreen))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Ir a la siguiente unidad")
                }

                Button(action: {
                    viewModel.showChapterCompletionSheet = false
                    viewModel.router.back()
                }) {
                    Text("Volver al temario")
                        .font(Theme.Fonts.notoSans(15, weight: .medium))
                        .foregroundStyle(Theme.Colors.brandGreen)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .strokeBorder(Theme.Colors.brandGreen, lineWidth: 1.5)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Volver al temario del curso")
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .background(Theme.Colors.brandCream.ignoresSafeArea())
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    let chapters: [CourseChapter] = [
        CourseChapter(
            blockId: "1", id: "ch1",
            displayName: "Unidad 1 · Marco Legal",
            type: .chapter,
            childs: [
                CourseSequential(
                    blockId: "s1", id: "seq1",
                    displayName: "Cap I · Disposiciones Generales",
                    type: .sequential, completion: 1.0,
                    childs: [
                        CourseVertical(
                            blockId: "v1", id: "ver1", courseId: "c1",
                            displayName: "Introducción al Marco",
                            type: .vertical, completion: 1.0,
                            childs: [], webUrl: ""
                        ),
                        CourseVertical(
                            blockId: "v2", id: "ver2", courseId: "c1",
                            displayName: "Conceptos Fundamentales",
                            type: .vertical, completion: 0.5,
                            childs: [], webUrl: ""
                        )
                    ],
                    sequentialProgress: nil, due: nil
                )
            ]
        )
    ]

    let vm = ContentReaderViewModel(
        chapters: chapters,
        courseID: "c1",
        courseName: "Demo",
        chapterIndex: 0,
        sequentialIndex: 0,
        verticalIndex: 0,
        router: CourseRouterMock(),
        interactor: CourseInteractor.mock,
        analytics: CourseAnalyticsMock()
    )

    return ContentReaderView(viewModel: vm)
        .loadFonts()
}
#endif
