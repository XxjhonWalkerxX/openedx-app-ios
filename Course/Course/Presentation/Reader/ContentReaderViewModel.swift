import SwiftUI
import Core
import Theme

// MARK: - ContentReaderViewModel

@MainActor
public final class ContentReaderViewModel: ObservableObject {

    // MARK: - Course Context
    public let chapters: [CourseChapter]
    public let courseID: String
    public let courseName: String

    // MARK: - Navigation State
    @Published public var chapterIndex: Int
    @Published public var sequentialIndex: Int
    @Published public var verticalIndex: Int

    // MARK: - UI State
    @Published public var showChapterCompletionSheet: Bool = false
    @Published public var boundaryLabel: String? = nil
    @Published public var isTopBarVisible: Bool = true
    @Published public var isMarkingComplete: Bool = false
    /// Dirección de la última navegación — usado para transición asimétrica en ContentReaderView.
    @Published public var isMovingForward: Bool = true

    private var completedVerticalIDs: Set<String> = []
    private var prefetchedSequentialIDs: Set<String> = []

    // MARK: - Dependencies
    let router: CourseRouter
    let interactor: CourseInteractorProtocol
    let analytics: CourseAnalytics

    public init(
        chapters: [CourseChapter],
        courseID: String,
        courseName: String,
        chapterIndex: Int,
        sequentialIndex: Int,
        verticalIndex: Int,
        router: CourseRouter,
        interactor: CourseInteractorProtocol,
        analytics: CourseAnalytics
    ) {
        self.chapters = chapters
        self.courseID = courseID
        self.courseName = courseName
        self.chapterIndex = chapterIndex
        self.sequentialIndex = sequentialIndex
        self.verticalIndex = verticalIndex
        self.router = router
        self.interactor = interactor
        self.analytics = analytics
    }

    // MARK: - Computed

    public var currentChapter: CourseChapter {
        chapters[chapterIndex]
    }

    public var currentSequential: CourseSequential {
        currentChapter.childs[sequentialIndex]
    }

    public var currentVerticals: [CourseVertical] {
        currentSequential.childs
    }

    public var currentVertical: CourseVertical? {
        guard verticalIndex < currentVerticals.count else { return nil }
        return currentVerticals[verticalIndex]
    }

    public var isCurrentVerticalComplete: Bool {
        guard let v = currentVertical else { return false }
        return completedVerticalIDs.contains(v.id) || v.completion >= 1.0
    }

    public var canGoPrevious: Bool {
        !(chapterIndex == 0 && sequentialIndex == 0 && verticalIndex == 0)
    }

    public var canGoNext: Bool {
        let atLastVertical = verticalIndex >= currentVerticals.count - 1
        let atLastSequential = sequentialIndex >= currentChapter.childs.count - 1
        let atLastChapter = chapterIndex >= chapters.count - 1
        return !(atLastVertical && atLastSequential && atLastChapter)
    }

    public var progressSegments: [ReaderProgressRail.SegmentState] {
        currentVerticals.enumerated().map { idx, vertical in
            let isComplete = completedVerticalIDs.contains(vertical.id) || vertical.completion >= 1.0
            if isComplete || idx < verticalIndex { return .completed }
            if idx == verticalIndex { return .current }
            return .pending
        }
    }

    // MARK: - Navigation

    public func goNext() {
        isMovingForward = true
        if verticalIndex < currentVerticals.count - 1 {
            withAnimation(.easeInOut(duration: 0.22)) {
                verticalIndex += 1
            }
            prefetchIfApproachingBoundary()
        } else if sequentialIndex < currentChapter.childs.count - 1 {
            let prevName = currentSequential.displayName
            withAnimation(.easeInOut(duration: 0.28)) {
                sequentialIndex += 1
                verticalIndex = 0
            }
            showBoundaryLabel(from: prevName, to: currentSequential.displayName)
            prefetchIfApproachingBoundary()
        } else if chapterIndex < chapters.count - 1 {
            showChapterCompletionSheet = true
        }
        // else: último vertical del curso — sin acción
    }

    public func goPrevious() {
        isMovingForward = false
        if verticalIndex > 0 {
            withAnimation(.easeInOut(duration: 0.22)) {
                verticalIndex -= 1
            }
        } else if sequentialIndex > 0 {
            let prevName = currentSequential.displayName
            withAnimation(.easeInOut(duration: 0.28)) {
                sequentialIndex -= 1
                verticalIndex = max(0, currentVerticals.count - 1)
            }
            showBoundaryLabel(from: prevName, to: currentSequential.displayName)
        } else if chapterIndex > 0 {
            let prevName = currentSequential.displayName
            chapterIndex -= 1
            sequentialIndex = max(0, currentChapter.childs.count - 1)
            verticalIndex = max(0, currentVerticals.count - 1)
            showBoundaryLabel(from: prevName, to: currentSequential.displayName)
        }
    }

    public func jumpTo(verticalIndex idx: Int) {
        guard idx >= 0, idx < currentVerticals.count else { return }
        isMovingForward = idx >= verticalIndex
        withAnimation(.easeInOut(duration: 0.18)) {
            verticalIndex = idx
        }
    }

    public func advanceToNextChapter() {
        showChapterCompletionSheet = false
        guard chapterIndex < chapters.count - 1 else {
            router.back()
            return
        }
        isMovingForward = true
        let prevName = currentChapter.displayName
        chapterIndex += 1
        sequentialIndex = 0
        verticalIndex = 0
        showBoundaryLabel(from: prevName, to: currentChapter.displayName)
    }

    // MARK: - Completion

    public func markComplete() {
        guard let vertical = currentVertical, !isMarkingComplete else { return }
        let blockID = vertical.childs.first?.id ?? vertical.blockId
        isMarkingComplete = true
        completedVerticalIDs.insert(vertical.id)

        Task {
            do {
                try await interactor.blockCompletionRequest(courseID: courseID, blockID: blockID)
            } catch {
                completedVerticalIDs.remove(vertical.id)
            }
            isMarkingComplete = false
        }
    }

    // MARK: - Top Bar Autohide

    public func updateScrollOffset(_ offset: CGFloat) {
        let shouldShow = offset >= -30
        guard shouldShow != isTopBarVisible else { return }
        withAnimation(.easeInOut(duration: 0.18)) {
            isTopBarVisible = shouldShow
        }
    }

    // MARK: - Prefetch

    /// Dispara prefetch del siguiente sequential cuando el usuario está a 1 vertical del límite.
    func prefetchIfApproachingBoundary() {
        let atLastVertical = verticalIndex >= currentVerticals.count - 2
        guard atLastVertical else { return }

        // Siguiente sequential en el mismo chapter
        if sequentialIndex < currentChapter.childs.count - 1 {
            let nextSeq = currentChapter.childs[sequentialIndex + 1]
            prefetchSequential(nextSeq)
        }
        // Primer sequential del siguiente chapter
        else if chapterIndex < chapters.count - 1 {
            let nextChapter = chapters[chapterIndex + 1]
            if let firstSeq = nextChapter.childs.first {
                prefetchSequential(firstSeq)
            }
        }
    }

    private func prefetchSequential(_ sequential: CourseSequential) {
        guard !prefetchedSequentialIDs.contains(sequential.id) else { return }
        prefetchedSequentialIDs.insert(sequential.id)

        let urls: [URL] = sequential.childs.prefix(3).compactMap { vertical in
            vertical.childs.first.flatMap { block in
                let candidate = block.encodedVideo?.mobileHigh?.url
                    ?? block.encodedVideo?.mobileLow?.url
                    ?? (block.studentUrl.isEmpty ? nil : block.studentUrl)
                return candidate.flatMap { URL(string: $0) }
            }
        }

        Task.detached(priority: .background) {
            for url in urls {
                _ = try? await URLSession.shared.data(from: url)
            }
        }
    }

    // MARK: - Private

    private func showBoundaryLabel(from: String, to: String) {
        withAnimation(.easeIn(duration: 0.2)) {
            boundaryLabel = "\(from) → \(to)"
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in
            withAnimation(.easeOut(duration: 0.3)) {
                self?.boundaryLabel = nil
            }
        }
    }
}
