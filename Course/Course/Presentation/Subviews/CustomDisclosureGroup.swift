//
//  CustomDisclosureGroup.swift
//  Course
//
//  Created by  Stepanok Ivan on 21.05.2024.
//

import SwiftUI
import Core
import Theme

struct CustomDisclosureGroup: View {
    private let proxy: GeometryProxy
    private let course: CourseStructure
    private let viewModel: CourseContainerViewModel
    private var idiom: UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
    
    init(course: CourseStructure, proxy: GeometryProxy, viewModel: CourseContainerViewModel) {
        self.course = course
        self.proxy = proxy
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(course.childs) { chapter in
                let chapterIndex = course.childs.firstIndex(where: { $0.id == chapter.id })
                let isExpanded = viewModel.expandedSections[chapter.id] ?? false
                
                VStack(alignment: .leading, spacing: 0) {
                    // MARK: - Header (Chapter)
                    Button(
                        action: {
                            withAnimation(.linear(duration: course.childs.count > 1 ? 0.2 : 0.05)) {
                                viewModel.expandedSections[chapter.id, default: false].toggle()
                            }
                            viewModel.trackSectionClicked(chapter)
                        }, label: {
                            HStack(spacing: 12) {
                                // Círculo verde con el número del módulo
                                ZStack {
                                    Circle()
                                        .fill(Theme.Colors.brandGreen)
                                        .frame(width: 28, height: 28)
                                    Text("\(chapterIndex.map { $0 + 1 } ?? 1)")
                                        .font(Theme.Fonts.ttRoundsBody(14, weight: 700))
                                        .foregroundColor(Theme.Colors.brandCream)
                                }

                                if chapter.childs.allSatisfy({ $0.completion == 1 }) {
                                    CoreAssets.finishedSequence.swiftUIImage.renderingMode(.template)
                                        .foregroundColor(Theme.Colors.success)
                                }
                                Text(chapter.displayName)
                                    .font(Theme.Fonts.ttRoundsBody(15, weight: 600))
                                    .foregroundColor(Theme.Colors.brandGreen)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                                if canDownloadAllSections(in: chapter),
                                   let state = downloadAllButtonState(for: chapter) {
                                    Button(
                                        action: {
                                            downloadAllSubsections(in: chapter, state: state)
                                        }, label: {
                                            switch state {
                                            case .available:
                                                DownloadAvailableView()
                                            case .downloading:
                                                DownloadProgressView()
                                            case .finished:
                                                DownloadFinishedView()
                                            }
                                        }
                                    )
                                }
                                
                                // Chevron del lado derecho
                                CoreAssets.chevronRight.swiftUIImage
                                    .rotationEffect(
                                        .degrees(isExpanded ? 90 : 0)
                                    )
                                    .foregroundColor(Theme.Colors.brandGreen)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                        }
                    )
                    .background(Theme.Colors.background)
                    
                    // MARK: - Expanded Items (Sequentials)
                    if isExpanded {
                        VStack(spacing: 0) {
                            ForEach(Array(chapter.childs.enumerated()), id: \.element.id) { sequentialIndex, sequential in
                                VStack(spacing: 0) {
                                    Button(
                                        action: {
                                            guard let chapterIndex = chapterIndex else { return }
                                            guard let courseVertical = sequential.childs.first else { return }
                                            guard let block = courseVertical.childs.first else {
                                                viewModel.router.showGatedContentError(url: courseVertical.webUrl)
                                                return
                                            }
                                            
                                            viewModel.trackSequentialClicked(sequential)
                                            if viewModel.config.uiComponents.courseDropDownNavigationEnabled {
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
                                        },
                                        label: {
                                            HStack(spacing: 12) {
                                                if sequential.completion == 1 {
                                                    CoreAssets.finishedSequence.swiftUIImage
                                                        .renderingMode(.template)
                                                        .resizable()
                                                        .foregroundColor(Theme.Colors.success)
                                                        .frame(width: 16, height: 16)
                                                } else {
                                                    Circle()
                                                        .stroke(Theme.Colors.brandGreen, lineWidth: 1.5)
                                                        .frame(width: 14, height: 14)
                                                }
                                                
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(sequential.displayName)
                                                        .font(Theme.Fonts.ttRoundsBody(14, weight: 600))
                                                        .foregroundColor(Theme.Colors.textPrimary)
                                                        .multilineTextAlignment(.leading)
                                                        .lineLimit(2)
                                                    
                                                    if let assignmentStatusText = assignmentStatusText(sequential: sequential) {
                                                        Text(assignmentStatusText)
                                                            .font(Theme.Fonts.ttRoundsBody(12, weight: 400))
                                                            .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                                                            .multilineTextAlignment(.leading)
                                                            .lineLimit(2)
                                                    }
                                                }
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                
                                                CoreAssets.chevronRight.swiftUIImage
                                                    .renderingMode(.template)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(width: 12, height: 12)
                                                    .foregroundColor(Theme.Colors.brandGreen)
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 14)
                                        }
                                    )
                                    .accessibilityElement(children: .combine)
                                    .accessibilityLabel(sequential.displayName)
                                    
                                    if sequentialIndex != chapter.childs.count - 1 {
                                        Divider()
                                            .padding(.horizontal, 16)
                                    }
                                }
                                .background(Theme.Colors.background)
                            }
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Theme.Colors.brandCreamStrong, lineWidth: isExpanded ? 1 : 0)
                )
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.Colors.brandCreamStrong)
                        .offset(y: isExpanded ? 0 : 4) // Remueve la sombra "dura" cuando está expandido
                )
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)

    }
    
    private func deleteMessage(for chapter: CourseChapter) -> String {
        "\(CourseLocalization.Alert.deleteVideos) \"\(chapter.displayName)\"?"
    }
    
    func getAssignmentStatus(for date: Date) -> String {
        let calendar = Calendar.current
        let today = Date()
        
        if calendar.isDateInToday(date) {
            return CourseLocalization.Course.dueToday
        } else if calendar.isDateInTomorrow(date) {
            return CourseLocalization.Course.dueTomorrow
        } else if let daysUntil = calendar.dateComponents([.day], from: today, to: date).day, daysUntil > 0 {
            return CourseLocalization.dueIn(daysUntil)
        } else if let daysAgo = calendar.dateComponents([.day], from: date, to: today).day, daysAgo > 0 {
            return CourseLocalization.pastDue(daysAgo)
        } else {
            return ""
        }
    }
    
    private func canDownloadAllSections(in chapter: CourseChapter) -> Bool {
        chapter.childs.contains { sequential in
            sequentialDownloadState(sequential) != nil
        }
    }

    private func assignmentStatusText(
        sequential: CourseSequential
    ) -> String? {
        var parts: [String] = []

        // Name
        if let name = sequential.sequentialProgress?.assignmentType,
           !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            parts.append(name)
        }

        // Deadline
        if let due = sequential.due {
            parts.append(getAssignmentStatus(for: due))
        }

        // Progress
        if let sp = sequential.sequentialProgress,
           let earned = sp.numPointsEarned,
           let possible = sp.numPointsPossible,
           possible != 0 {
            parts.append("\(earned) / \(possible)")
        }

        return parts.isEmpty ? nil : parts.joined(separator: " - ")
    }
    
    private func downloadAllSubsections(in chapter: CourseChapter, state: DownloadViewState) {
        Task {
            var allBlocks: [CourseBlock] = []
            var sequentialsToDownload: [CourseSequential] = []
            for sequential in chapter.childs {
                let blocks = await viewModel.collectBlocks(
                    chapter: chapter,
                    blockId: sequential.id,
                    state: state
                )
                if !blocks.isEmpty {
                    allBlocks.append(contentsOf: blocks)
                    sequentialsToDownload.append(sequential)
                }
            }
            await viewModel.download(
                state: state,
                blocks: allBlocks,
                sequentials: sequentialsToDownload
            )
        }
    }
    
    private func downloadAllButtonState(for chapter: CourseChapter) -> DownloadViewState? {
        if canDownloadAllSections(in: chapter) {
            var downloads: [DownloadViewState] = []
            for sequential in chapter.childs {
                if let state = sequentialDownloadState(sequential) {
                    downloads.append(state)
                }
            }
            if downloads.contains(.downloading) {
                return .downloading
            } else if downloads.allSatisfy({ $0 == .finished }) {
                return .finished
            } else {
                return .available
            }
        }
        return nil
    }
    
    private func sequentialDownloadState(_ sequential: CourseSequential) -> DownloadViewState? {
        return viewModel.sequentialsDownloadState[sequential.id]
    }
    
    private func chapterProgress(for chapter: CourseChapter) -> Double {
        return viewModel.chapterProgress(for: chapter)
    }
}

#if DEBUG
struct CustomDisclosureGroup_Previews: PreviewProvider {
    
    static var previews: some View {
        
        // Sample data models
        let sampleCourseChapters: [CourseChapter] = [
            CourseChapter(
                blockId: "1",
                id: "1",
                displayName: "Chapter 1",
                type: .chapter,
                childs: [
                    CourseSequential(
                        blockId: "1-1",
                        id: "1-1",
                        displayName: "Sequential 1",
                        type: .sequential,
                        completion: 0,
                        childs: [
                            CourseVertical(
                                blockId: "1-1-1",
                                id: "1-1-1",
                                courseId: "1",
                                displayName: "Vertical 1",
                                type: .vertical,
                                completion: 0,
                                childs: [],
                                webUrl: ""
                            ),
                            CourseVertical(
                                blockId: "1-1-2",
                                id: "1-1-2",
                                courseId: "1",
                                displayName: "Vertical 2",
                                type: .vertical,
                                completion: 1.0,
                                childs: [],
                                webUrl: ""
                            )
                        ],
                        sequentialProgress: SequentialProgress(
                            assignmentType: "Advanced Assessment Tools",
                            numPointsEarned: 1,
                            numPointsPossible: 3,
                            shortLabel: nil
                        ),
                        due: Date()
                    ),
                    CourseSequential(
                        blockId: "1-2",
                        id: "1-2",
                        displayName: "Sequential 2",
                        type: .sequential,
                        completion: 1.0,
                        childs: [
                            CourseVertical(
                                blockId: "1-2-1",
                                id: "1-2-1",
                                courseId: "1",
                                displayName: "Vertical 3",
                                type: .vertical,
                                completion: 1.0,
                                childs: [],
                                webUrl: ""
                            )
                        ],
                        sequentialProgress: SequentialProgress(
                            assignmentType: "Basic Assessment Tools",
                            numPointsEarned: 1,
                            numPointsPossible: 3,
                            shortLabel: nil
                        ),
                        due: Date()
                    )
                ]
            ),
            CourseChapter(
                blockId: "2",
                id: "2",
                displayName: "Chapter 2",
                type: .chapter,
                childs: [
                    CourseSequential(
                        blockId: "2-1",
                        id: "2-1",
                        displayName: "Sequential 3",
                        type: .sequential,
                        completion: 1.0,
                        childs: [
                            CourseVertical(
                                blockId: "2-1-1",
                                id: "2-1-1",
                                courseId: "2",
                                displayName: "Vertical 4",
                                type: .vertical,
                                completion: 1.0,
                                childs: [],
                                webUrl: ""
                            ),
                            CourseVertical(
                                blockId: "2-1-2",
                                id: "2-1-2",
                                courseId: "2",
                                displayName: "Vertical 5",
                                type: .vertical,
                                completion: 1.0,
                                childs: [],
                                webUrl: ""
                            )
                        ],
                        sequentialProgress: SequentialProgress(
                            assignmentType: "Advanced Assessment Tools",
                            numPointsEarned: 1,
                            numPointsPossible: 3,
                            shortLabel: nil
                        ),
                        due: Date()
                    )
                ]
            )
        ]
        
        let viewModel = CourseContainerViewModel(
            interactor: CourseInteractor.mock,
            authInteractor: AuthInteractor.mock,
            router: CourseRouterMock(),
            analytics: CourseAnalyticsMock(),
            config: ConfigMock(),
            connectivity: Connectivity(),
            manager: DownloadManagerMock(),
            storage: CourseStorageMock(),
            isActive: true,
            courseStart: Date(),
            courseEnd: nil,
            enrollmentStart: Date(),
            enrollmentEnd: nil,
            lastVisitedBlockID: nil,
            coreAnalytics: CoreAnalyticsMock(),
            courseHelper: CourseDownloadHelper(courseStructure: nil, manager: DownloadManagerMock())
        )
        Task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    await viewModel.getCourseBlocks(courseID: "courseId")
                }
                group.addTask {
                    await viewModel.getCourseDeadlineInfo(courseID: "courseId")
                }
            }
        }
        
        return GeometryReader { proxy in
            ScrollView {
                CustomDisclosureGroup(
                    course: CourseStructure(
                        id: "Id",
                        graded: false,
                        completion: 0,
                        viewYouTubeUrl: "",
                        encodedVideo: "",
                        displayName: "Course",
                        childs: sampleCourseChapters,
                        media: CourseMedia.init(image: CourseImage(raw: "", small: "", large: "")),
                        certificate: nil,
                        org: "org",
                        isSelfPaced: false,
                        courseProgress: nil
                    ),
                    proxy: proxy,
                    viewModel: viewModel
                )
            }
        }
    }
}
#endif
