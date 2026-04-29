import SwiftUI
import Combine
import Core
import Theme

// MARK: - VerticalRenderer

/// Despacha cada CourseVertical al renderer correcto según el tipo de bloque.
/// Web (html/problem/survey/dragAndDrop) → WebView + CSS brandCream.
/// Video → EncodedVideoView / YouTubeView.
/// Discussion → mensaje + link a tab Foro.
/// Unknown → NotAvailableOnMobileView.
struct VerticalRenderer: View {

    let vertical: CourseVertical
    let courseID: String
    let onScrollChange: (CGFloat) -> Void

    @State private var playerStateSubject = CurrentValueSubject<VideoPlayerState?, Never>(nil)
    @Environment(\.readerPageSwipeGesture) private var pageSwipeGesture

    private var primaryBlock: CourseBlock? { vertical.childs.first }

    private var lessonType: LessonType? {
        guard let block = primaryBlock else { return nil }
        return LessonType.from(block, streamingQuality: .auto)
    }

    // MARK: - Body

    var body: some View {
        Group {
            switch lessonType {
            case .web(let url, let injections, let blockId, _):
                webRenderer(url: url, injections: injections, blockId: blockId)

            case .video(let encodedUrl, let blockId):
                videoRenderer(encodedUrl: encodedUrl, blockId: blockId)

            case .youtube(let ytUrl, let blockId):
                youtubeRenderer(ytUrl: ytUrl, blockId: blockId)

            case .discussion(let topicId, let blockId, let title):
                discussionRenderer(topicId: topicId, blockId: blockId, title: title)

            case .unknown(let url):
                GeometryReader { geo in
                    NotAvailableOnMobileView(url: url)
                        .frame(width: geo.size.width, height: geo.size.height)
                }

            case nil:
                emptyRenderer
            }
        }
        .onDisappear {
            playerStateSubject.send(.kill)
        }
    }

    // MARK: - Web Renderer

    private func webRenderer(url: String, injections: [WebviewInjection], blockId: String) -> some View {
        GeometryReader { geo in
            WebView(
                url: url,
                localUrl: nil,
                injections: injections + [.readerBrandCSS, .readerGestureAdjuster],
                blockID: blockId,
                roundedBackgroundEnabled: false
            )
            .frame(width: geo.size.width, height: geo.size.height)
            // Layer B+C: configura WKScrollView y coordina con paging gesture
            .background(
                ReaderScrollConfigurator(pageSwipeGesture: pageSwipeGesture)
            )
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Encoded Video Renderer

    private func videoRenderer(encodedUrl: String, blockId: String) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                EncodedVideoView(
                    name: primaryBlock?.displayName ?? vertical.displayName,
                    url: URL(string: encodedUrl),
                    courseID: courseID,
                    blockID: blockId,
                    playerStateSubject: playerStateSubject,
                    languages: primaryBlock?.subtitles ?? [],
                    isOnScreen: true
                )
                .padding(.top, 8)
                Spacer(minLength: 120)
            }
            .background(
                scrollOffsetReader
            )
        }
        .coordinateSpace(name: "readerVerticalScroll")
        .onPreferenceChange(ReaderScrollOffsetKey.self, perform: onScrollChange)
    }

    // MARK: - YouTube Renderer

    private func youtubeRenderer(ytUrl: String, blockId: String) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                YouTubeView(
                    name: primaryBlock?.displayName ?? vertical.displayName,
                    url: ytUrl,
                    courseID: courseID,
                    blockID: blockId,
                    playerStateSubject: playerStateSubject,
                    languages: primaryBlock?.subtitles ?? [],
                    isOnScreen: true
                )
                .padding(.top, 8)
                Spacer(minLength: 120)
            }
            .background(scrollOffsetReader)
        }
        .coordinateSpace(name: "readerVerticalScroll")
        .onPreferenceChange(ReaderScrollOffsetKey.self, perform: onScrollChange)
    }

    // MARK: - Discussion Renderer

    private func discussionRenderer(topicId: String, blockId: String, title: String) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                Spacer(minLength: 40)
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                    .foregroundStyle(Theme.Colors.guindaColor.opacity(0.45))
                    .accessibilityHidden(true)
                VStack(spacing: 8) {
                    Text(title.isEmpty ? "Discusión" : title)
                        .font(Theme.Fonts.notoSans(17, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text("Ve al tab «Foro» para participar en esta discusión.")
                        .font(Theme.Fonts.notoSans(14, weight: .regular))
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .accessibilityElement(children: .combine)
                Spacer(minLength: 80)
            }
            .frame(maxWidth: .infinity)
            .background(scrollOffsetReader)
        }
        .coordinateSpace(name: "readerVerticalScroll")
        .onPreferenceChange(ReaderScrollOffsetKey.self, perform: onScrollChange)
    }

    // MARK: - Empty Renderer

    private var emptyRenderer: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.questionmark")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .foregroundStyle(Theme.Colors.textSecondary.opacity(0.35))
                .accessibilityHidden(true)
            Text("Sin contenido disponible")
                .font(Theme.Fonts.notoSans(14, weight: .regular))
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Scroll Offset Helper

    private var scrollOffsetReader: some View {
        GeometryReader { geo in
            Color.clear.preference(
                key: ReaderScrollOffsetKey.self,
                value: geo.frame(in: .named("readerVerticalScroll")).minY
            )
        }
    }
}

// MARK: - Preference Key

private struct ReaderScrollOffsetKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

