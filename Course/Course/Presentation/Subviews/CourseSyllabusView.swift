import SwiftUI
import Core
import Theme

// MARK: - CourseSyllabusView

/// Reemplaza CustomDisclosureGroup.
/// Cada chapter → BrandUnitAccordion con barra progreso + completion_stat.
/// Cada sequential → BrandUnitAccordionRow con 3 estados.
struct CourseSyllabusView: View {

    let course: CourseStructure
    @ObservedObject var viewModel: CourseContainerViewModel

    private static let dueDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_MX")
        f.dateFormat = "d MMM"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(course.childs) { chapter in
                let chapterIdx = course.childs.firstIndex(where: { $0.id == chapter.id })
                let isExpanded = viewModel.expandedSections[chapter.id] ?? false
                let progress = viewModel.chapterProgress(for: chapter)
                let completedCount = chapter.childs.filter { $0.completion >= 1.0 }.count

                BrandUnitAccordion(
                    title: chapter.displayName,
                    progress: progress,
                    completedCount: completedCount,
                    totalCount: chapter.childs.count,
                    isExpanded: isExpanded,
                    onToggle: {
                        withAnimation(.easeInOut(duration: course.childs.count > 1 ? 0.22 : 0.1)) {
                            viewModel.expandedSections[chapter.id, default: false].toggle()
                        }
                        viewModel.trackSectionClicked(chapter)
                    },
                    onContinue: progress < 1.0 ? {
                        guard let idx = chapterIdx else { return }
                        navigateToFirstIncomplete(chapter: chapter, chapterIndex: idx)
                    } : nil
                ) {
                    sequentialRows(chapter: chapter, chapterIdx: chapterIdx)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Sequential Rows

    @ViewBuilder
    private func sequentialRows(chapter: CourseChapter, chapterIdx: Int?) -> some View {
        ForEach(Array(chapter.childs.enumerated()), id: \.element.id) { seqIdx, sequential in
            BrandUnitAccordionRow(
                title: sequential.displayName,
                detail: detailText(for: sequential),
                state: rowState(for: sequential),
                onTap: {
                    guard let ci = chapterIdx else { return }
                    navigate(
                        chapter: chapter,
                        sequential: sequential,
                        chapterIndex: ci,
                        sequentialIndex: seqIdx
                    )
                }
            )

            if seqIdx < chapter.childs.count - 1 {
                Divider()
                    .padding(.leading, 16)
                    .background(Theme.Colors.brandCreamStrong)
            }
        }
    }

    // MARK: - State

    private func rowState(for sequential: CourseSequential) -> BrandUnitAccordionRow.CompletionState {
        if sequential.completion >= 1.0 {
            return .complete
        } else if sequential.completion > 0 {
            return .partial(sequential.completion)
        }
        return .pending
    }

    // MARK: - Detail Text

    private func detailText(for sequential: CourseSequential) -> String? {
        var parts: [String] = []

        if let assignmentType = sequential.sequentialProgress?.assignmentType,
           !assignmentType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            parts.append(assignmentType)
        }

        if let due = sequential.due {
            parts.append(dueDateStatus(for: due))
        }

        if let sp = sequential.sequentialProgress,
           let earned = sp.numPointsEarned,
           let possible = sp.numPointsPossible,
           possible != 0 {
            parts.append("\(earned)/\(possible) pts")
        }

        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private func dueDateStatus(for date: Date) -> String {
        let cal = Calendar.current
        let today = Date()
        if cal.isDateInToday(date) { return CourseLocalization.Course.dueToday }
        if cal.isDateInTomorrow(date) { return CourseLocalization.Course.dueTomorrow }
        if let d = cal.dateComponents([.day], from: today, to: date).day, d > 0 {
            return CourseLocalization.dueIn(d)
        }
        if let d = cal.dateComponents([.day], from: date, to: today).day, d > 0 {
            return CourseLocalization.pastDue(d)
        }
        return Self.dueDateFormatter.string(from: date)
    }

    // MARK: - Navigation

    private func navigateToFirstIncomplete(chapter: CourseChapter, chapterIndex: Int) {
        guard let seqIdx = chapter.childs.firstIndex(where: { $0.completion < 1.0 }) else {
            // All complete — navigate to last sequential
            if let seqIdx = chapter.childs.indices.last {
                navigate(
                    chapter: chapter,
                    sequential: chapter.childs[seqIdx],
                    chapterIndex: chapterIndex,
                    sequentialIndex: seqIdx
                )
            }
            return
        }
        navigate(
            chapter: chapter,
            sequential: chapter.childs[seqIdx],
            chapterIndex: chapterIndex,
            sequentialIndex: seqIdx
        )
    }

    private func navigate(
        chapter: CourseChapter,
        sequential: CourseSequential,
        chapterIndex: Int,
        sequentialIndex: Int
    ) {
        guard sequential.childs.first != nil else {
            viewModel.router.showGatedContentError(url: sequential.childs.first?.webUrl ?? "")
            return
        }

        viewModel.trackSequentialClicked(sequential)

        if viewModel.config.uiComponents.courseDropDownNavigationEnabled {
            guard let block = sequential.childs.first?.childs.first else {
                viewModel.router.showGatedContentError(url: sequential.childs.first?.webUrl ?? "")
                return
            }
            viewModel.router.showCourseUnit(
                courseName: viewModel.courseStructure?.displayName ?? "",
                blockId: block.id,
                courseID: viewModel.courseStructure?.id ?? "",
                verticalIndex: 0,
                chapters: course.childs,
                chapterIndex: chapterIndex,
                sequentialIndex: sequentialIndex,
                showVideoNavigation: false,
                courseVideoStructure: nil
            )
        } else {
            viewModel.router.showCourseVerticalView(
                courseID: viewModel.courseStructure?.id ?? "",
                courseName: viewModel.courseStructure?.displayName ?? "",
                title: sequential.displayName,
                chapters: course.childs,
                chapterIndex: chapterIndex,
                sequentialIndex: sequentialIndex
            )
        }
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
                    childs: [], sequentialProgress: nil, due: nil
                ),
                CourseSequential(
                    blockId: "s2", id: "seq2",
                    displayName: "Cap II · Aplicación",
                    type: .sequential, completion: 0.5,
                    childs: [],
                    sequentialProgress: SequentialProgress(
                        assignmentType: "Tarea", numPointsEarned: 1,
                        numPointsPossible: 3, shortLabel: nil
                    ),
                    due: Date().addingTimeInterval(86400 * 3)
                ),
                CourseSequential(
                    blockId: "s3", id: "seq3",
                    displayName: "Cap III · Sanciones",
                    type: .sequential, completion: 0.0,
                    childs: [], sequentialProgress: nil, due: nil
                )
            ]
        ),
        CourseChapter(
            blockId: "2", id: "ch2",
            displayName: "Unidad 2 · Fundamentos",
            type: .chapter,
            childs: [
                CourseSequential(
                    blockId: "s4", id: "seq4",
                    displayName: "Cap I · Conceptos base",
                    type: .sequential, completion: 0.0,
                    childs: [], sequentialProgress: nil, due: nil
                )
            ]
        )
    ]

    let vm = CourseContainerViewModel(
        interactor: CourseInteractor.mock,
        authInteractor: AuthInteractor.mock,
        router: CourseRouterMock(),
        analytics: CourseAnalyticsMock(),
        config: ConfigMock(),
        connectivity: Connectivity(),
        manager: DownloadManagerMock(),
        storage: CourseStorageMock(),
        isActive: true, courseStart: nil, courseEnd: nil,
        enrollmentStart: nil, enrollmentEnd: nil,
        lastVisitedBlockID: nil,
        coreAnalytics: CoreAnalyticsMock(),
        courseHelper: CourseDownloadHelper(courseStructure: nil, manager: DownloadManagerMock())
    )
    vm.expandedSections = ["ch1": true, "ch2": false]

    return ScrollView {
        CourseSyllabusView(
            course: CourseStructure(
                id: "c1", graded: false, completion: 0,
                viewYouTubeUrl: "", encodedVideo: "",
                displayName: "Curso Demo",
                childs: chapters,
                media: CourseMedia(image: CourseImage(raw: "", small: "", large: "")),
                certificate: nil, org: "SEP", isSelfPaced: true, courseProgress: nil
            ),
            viewModel: vm
        )
    }
    .background(Theme.Colors.brandCream)
    .loadFonts()
}
#endif
