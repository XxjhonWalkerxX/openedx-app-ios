//
//  CourseNavigationView.swift
//  Course
//
//  Fase 5: botones Anterior (outline) + Siguiente/Marcar (verde)
//

import SwiftUI
import Core
import Theme
import Combine

struct CourseNavigationView: View {

    @ObservedObject
    private var viewModel: CourseUnitViewModel
    private let playerStateSubject: CurrentValueSubject<VideoPlayerState?, Never>

    init(
        viewModel: CourseUnitViewModel,
        playerStateSubject: CurrentValueSubject<VideoPlayerState?, Never>
    ) {
        self.viewModel = viewModel
        self.playerStateSubject = playerStateSubject
    }

    // MARK: - Helpers

    private var currentVertical: CourseVertical {
        viewModel.verticals[viewModel.verticalIndex]
    }

    private var isFirstBlock: Bool {
        viewModel.selectedLesson() == currentVertical.childs.first
    }

    private var isLastBlock: Bool {
        viewModel.selectedLesson() == currentVertical.childs.last
    }

    // MARK: - Body

    var body: some View {
        if viewModel.showVideoNavigation {
            videoNavigationButtons
        } else {
            lessonNavigationButtons
        }
    }

    // MARK: - Navegación estándar (lectura / web / quiz)

    private var lessonNavigationButtons: some View {
        HStack(spacing: 10) {
            // Anterior — outline verde
            if !isFirstBlock {
                Button {
                    HapticFeedback.impact(.soft)
                    playerStateSubject.send(VideoPlayerState.pause)
                    viewModel.select(move: .previous)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .bold))
                        Text(CourseLocalization.Courseware.previous)
                            .font(Theme.Fonts.notoSans(13, weight: .semibold))
                    }
                    .foregroundColor(Theme.Colors.brandGreen)
                    .frame(height: 50)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .strokeBorder(Theme.Colors.brandGreen, lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
            }

            // Siguiente / Marcar completado / Finalizar — verde sólido
            if isLastBlock {
                finishButton
            } else if isFirstBlock && currentVertical.childs.count == 1 {
                // Solo un bloque → Marcar completado
                finishButton
            } else {
                nextButton
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    private var nextButton: some View {
        Button {
            HapticFeedback.impact(.soft)
            playerStateSubject.send(VideoPlayerState.pause)
            viewModel.select(move: .next)
        } label: {
            HStack(spacing: 6) {
                Text(CourseLocalization.Courseware.next)
                    .font(Theme.Fonts.notoSans(13, weight: .semibold))
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(Theme.Colors.brandGreen)
            )
            .shadow(color: Theme.Colors.brandGreen.opacity(0.25), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }

    private var finishButton: some View {
        Button {
            HapticFeedback.notification(.success)
            viewModel.router.presentAlert(
                alertTitle: CourseLocalization.Courseware.goodWork,
                alertMessage: CoreLocalization.Courseware.sectionCompleted(currentVertical.displayName),
                nextSectionName: {
                    if let data = viewModel.nextData,
                       let vertical = viewModel.vertical(for: data) {
                        return vertical.displayName
                    }
                    return nil
                }(),
                action: CourseLocalization.Courseware.backToOutline,
                image: CoreAssets.goodWork.swiftUIImage,
                onCloseTapped: { viewModel.router.dismiss(animated: false) },
                firstButtonTapped: {
                    playerStateSubject.send(VideoPlayerState.pause)
                    playerStateSubject.send(VideoPlayerState.kill)
                    viewModel.trackFinishVerticalBackToOutlineClicked()
                    viewModel.router.dismiss(animated: false)
                    viewModel.router.back(animated: true)
                },
                nextSectionTapped: {
                    playerStateSubject.send(VideoPlayerState.pause)
                    playerStateSubject.send(VideoPlayerState.kill)
                    viewModel.router.dismiss(animated: false)
                    viewModel.analytics.finishVerticalNextSectionClicked(
                        courseId: viewModel.courseID,
                        courseName: viewModel.courseName,
                        blockId: viewModel.selectedLesson().blockId,
                        blockName: viewModel.selectedLesson().displayName
                    )
                    guard let data = viewModel.nextData else { return }
                    viewModel.router.replaceCourseUnit(
                        courseName: viewModel.courseName,
                        blockId: viewModel.lessonID,
                        courseID: viewModel.courseID,
                        verticalIndex: data.verticalIndex,
                        chapters: viewModel.chapters,
                        chapterIndex: data.chapterIndex,
                        sequentialIndex: data.sequentialIndex,
                        animated: true,
                        showVideoNavigation: false,
                        courseVideoStructure: nil
                    )
                }
            )
            playerStateSubject.send(VideoPlayerState.pause)
            viewModel.analytics.finishVerticalClicked(
                courseId: viewModel.courseID,
                courseName: viewModel.courseName,
                blockId: viewModel.selectedLesson().blockId,
                blockName: viewModel.selectedLesson().displayName
            )
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                Text(CourseLocalization.Courseware.finish)
                    .font(Theme.Fonts.notoSans(13, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(Theme.Colors.brandGreen)
            )
            .shadow(color: Theme.Colors.brandGreen.opacity(0.25), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Navegación de video (modo video navigation)

    private var videoNavigationButtons: some View {
        HStack(spacing: 10) {
            if let index = viewModel.currentVideoIndex, index != 0 {
                Button {
                    playerStateSubject.send(VideoPlayerState.kill)
                    let video = viewModel.allVideosForNavigation[index - 1]
                    viewModel.handleVideoTap(video: video)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .bold))
                        Text(CourseLocalization.Courseware.previous)
                            .font(Theme.Fonts.notoSans(13, weight: .semibold))
                    }
                    .foregroundColor(Theme.Colors.brandGreen)
                    .frame(height: 50)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .strokeBorder(Theme.Colors.brandGreen, lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(CourseLocalization.Courseware.previousFull)
            }

            if let index = viewModel.currentVideoIndex,
               index != viewModel.allVideosForNavigation.count - 1 {
                Button {
                    playerStateSubject.send(VideoPlayerState.kill)
                    let video = viewModel.allVideosForNavigation[index + 1]
                    viewModel.handleVideoTap(video: video)
                } label: {
                    HStack(spacing: 6) {
                        Text(CourseLocalization.Courseware.next)
                            .font(Theme.Fonts.notoSans(13, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .fill(Theme.Colors.brandGreen)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
}

#if DEBUG
struct CourseNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = CourseUnitViewModel(
            lessonID: "1",
            courseID: "1",
            courseName: "Name",
            chapters: [],
            chapterIndex: 1,
            sequentialIndex: 1,
            verticalIndex: 1,
            interactor: CourseInteractor.mock,
            config: ConfigMock(),
            router: CourseRouterMock(),
            analytics: CourseAnalyticsMock(),
            connectivity: Connectivity(),
            storage: CourseStorageMock(),
            manager: DownloadManagerMock()
        )

        CourseNavigationView(
            viewModel: viewModel,
            playerStateSubject: CurrentValueSubject<VideoPlayerState?, Never>(nil)
        )
    }
}
#endif
