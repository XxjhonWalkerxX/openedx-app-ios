//
//  ContentSegmentedControl.swift
//  Course
//
//  Created by  Stepanok Ivan on 24.06.2025.
//

import SwiftUI
import Core
import Theme

enum ContentTab: CaseIterable {
    case all
    case videos
    case assignments
    
    var title: String {
        switch self {
        case .all:
            return CourseLocalization.CourseContent.all
        case .videos:
            return CourseLocalization.CourseContent.videos
        case .assignments:
            return CourseLocalization.CourseContent.assignments
        }
    }
}

struct ContentSegmentedControl: View {
    @Binding var selectedTab: ContentTab
    let courseId: String
    let courseName: String
    let analytics: CourseAnalytics
    let progress: CourseProgress?

    private let unselectedColor = Theme.Colors.textInactive
    private let progressBarWidth: CGFloat = 48

    init(
        selectedTab: Binding<ContentTab>,
        courseId: String,
        courseName: String,
        analytics: CourseAnalytics,
        progress: CourseProgress? = nil
    ) {
        self._selectedTab = selectedTab
        self.courseId = courseId
        self.courseName = courseName
        self.analytics = analytics
        self.progress = progress
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 0) {
                ForEach(ContentTab.allCases, id: \.self) { tab in
                    let isSelected = selectedTab == tab
                    Button(action: {
                        guard !isSelected else { return }
                        selectedTab = tab
                        switch tab {
                        case .all:
                            analytics.courseContentAllTabClicked(courseId: courseId, courseName: courseName)
                        case .videos:
                            analytics.courseContentVideosTabClicked(courseId: courseId, courseName: courseName)
                        case .assignments:
                            analytics.courseContentAssignmentsTabClicked(courseId: courseId, courseName: courseName)
                        }
                    }) {
                        Text(tab.title)
                            .font(Theme.Fonts.ttRoundsBody(13, weight: 700))
                            .foregroundColor(isSelected ? Theme.Colors.brandGreen : unselectedColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.9)
                            .layoutPriority(1) // Evita que SwiftUI corte la palabra si cree que no hay espacio
                            .padding(.horizontal, 14)
                            .padding(.top, 10)
                            .padding(.bottom, 8)
                            .overlay(alignment: .bottom) {
                                // Underline indicator — matches Android 2.5dp brand_green capsule
                                Capsule()
                                    .fill(isSelected ? Theme.Colors.brandGreen : Color.clear)
                                    .frame(height: 2.5)
                            }
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                // Inline progress — matches Android "X/Y + LinearProgressIndicator"
                if let progress,
                   let total = progress.totalAssignmentsCount,
                   let completed = progress.assignmentsCompleted,
                   total > 0 {
                    HStack(spacing: 6) {
                        Text("\(completed)/\(total)")
                            .font(Theme.Fonts.ttRoundsBody(10, weight: 700))
                            .foregroundColor(unselectedColor)

                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Theme.Colors.brandCreamStrong)
                                .frame(width: progressBarWidth, height: 4)
                            Capsule()
                                .fill(Theme.Colors.brandGreen)
                                .frame(
                                    width: progressBarWidth * CGFloat(completed) / CGFloat(total),
                                    height: 4
                                )
                        }
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 2.5) // offset to center within text area, above the underline
                }
            }

            // Full-width divider — matches Android brand_cream_strong separator
            Rectangle()
                .fill(Theme.Colors.brandCreamStrong)
                .frame(height: 1)
        }
    }
}

#if DEBUG
#Preview {
    @State var selectedTab: ContentTab = .all
    
    return VStack(spacing: 20) {
        ContentSegmentedControl(
            selectedTab: $selectedTab,
            courseId: "test",
            courseName: "Test Course",
            analytics: CourseAnalyticsMock()
        )
            .padding(.horizontal, 16)
        
        Text("Selected: \(selectedTab.title)")
            .font(Theme.Fonts.titleMedium)
        
        Spacer()
    }
    .padding()
    .background(Theme.Colors.background)
}
#endif
