//
//  CourseVerticalView.swift
//  Course
//
//  Created by  Stepanok Ivan on 12.12.2022.
//

import SwiftUI
import Core
import OEXFoundation
import Kingfisher
import Theme

public struct CourseVerticalView: View {
    
    private var title: String
    private var courseName: String
    private var courseID: String
    @ObservedObject
    private var viewModel: CourseVerticalViewModel
    private var idiom: UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
    
    public init(
        title: String,
        courseName: String,
        courseID: String,
        viewModel: CourseVerticalViewModel
    ) {
        self.title = title
        self.courseName = courseName
        self.courseID = courseID
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            // MARK: - Page Body
            VStack(spacing: 0) {
                // MARK: - Custom Header Matches Android
                HStack {
                    Button(action: {
                        viewModel.router.back()
                    }) {
                        CoreAssets.arrowLeft.swiftUIImage
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(Theme.Colors.brandGreen)
                    }
                    .padding(.leading, 24)
                    .frame(width: 48, height: 48, alignment: .leading)
                    
                    Spacer()
                    
                    Text(title)
                        .font(Theme.Fonts.ttRoundsBody(18, weight: 600))
                        .foregroundColor(Theme.Colors.brandGreen)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Fake view for centering
                    Color.clear
                        .frame(width: 48, height: 48)
                }
                .padding(.top, 8)
                .padding(.bottom, 8)
                
                GeometryReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                        
                        // MARK: - Header
                        HStack(spacing: 8) {
                            Rectangle()
                                .fill(Theme.Colors.guindaColor.opacity(0.3))
                                .frame(height: 1)
                            Text("CONTENIDO DE LA SECCIÓN")
                                .font(Theme.Fonts.ttRoundsBody(10, weight: 700))
                                .foregroundColor(Theme.Colors.guindaColor)
                                .kerning(1.2)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .layoutPriority(1)
                            Rectangle()
                                .fill(Theme.Colors.guindaColor.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        .padding(.bottom, 16)
                        
                        // MARK: - Lessons list
                        ForEach(Array(viewModel.verticals.enumerated()), id: \.element.id) { index, vertical in
                            let accentColor = (index % 3 == 2) ? Theme.Colors.guindaColor : Theme.Colors.brandGreen
                            let isCompleted = vertical.completion == 1
                            
                            Button(action: {
                                if let block = vertical.childs.first {
                                    viewModel.trackVerticalClicked(
                                        courseId: courseID,
                                        courseName: courseName,
                                        vertical: vertical
                                    )
                                    viewModel.router.showCourseUnit(
                                        courseName: courseName,
                                        blockId: block.id,
                                        courseID: courseID,
                                        verticalIndex: index,
                                        chapters: viewModel.chapters,
                                        chapterIndex: viewModel.chapterIndex,
                                        sequentialIndex: viewModel.sequentialIndex,
                                        showVideoNavigation: false,
                                        courseVideoStructure: nil
                                    )
                                }
                            }, label: {
                                HStack(spacing: 0) {
                                    // Color margin left
                                    Rectangle()
                                        .fill(accentColor)
                                        .frame(width: 4)
                                    
                                    HStack(spacing: 14) {
                                        // Number
                                        Text(String(format: "%02d", index + 1))
                                            .font(Theme.Fonts.ttRoundsBody(14, weight: 700))
                                            .foregroundColor(accentColor.opacity(0.6))
                                        
                                        // Icon container
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(accentColor.opacity(0.15))
                                                .frame(width: 38, height: 38)
                                            
                                            // Icon from CourseVerticalImageView or Success mark
                                            if isCompleted {
                                                CoreAssets.finishedSequence.swiftUIImage
                                                    .renderingMode(.template)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(width: 18, height: 18)
                                                    .foregroundColor(accentColor)
                                            } else {
                                                if let block = vertical.childs.first {
                                                    block.type.image
                                                        .renderingMode(.template)
                                                        .foregroundColor(accentColor)
                                                } else {
                                                    CourseVerticalImageView(blocks: vertical.childs)
                                                        .foregroundColor(accentColor)
                                                }
                                            }
                                        }
                                        
                                        // Text label
                                        Text(vertical.displayName)
                                            .font(Theme.Fonts.ttRoundsBody(15, weight: 600))
                                            .foregroundColor(Theme.Colors.textPrimary)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.leading)
                                        
                                        Spacer(minLength: 0)
                                        
                                        CoreAssets.chevronRight.swiftUIImage
                                            .renderingMode(.template)
                                            .foregroundColor(Color(red: 0.8, green: 0.8, blue: 0.8))
                                            .frame(width: 12, height: 12)
                                    }
                                    .padding(.vertical, 14)
                                    .padding(.trailing, 20)
                                    .padding(.leading, 16)
                                }
                                .background(Theme.Colors.background)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
                            })
                            .padding(.horizontal, 24)
                            .padding(.bottom, 12)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(vertical.displayName)
                        }
                        .frameLimit(width: proxy.size.width)
                        Spacer(minLength: 84)
                    }
                    .accessibilityAction {}
                    .onRightSwipeGesture {
                        viewModel.router.back()
                    }
                }
            } // Close the VStack
            .padding(.top, 8)
            
            // MARK: - Offline mode SnackBar
            OfflineSnackBarView(connectivity: viewModel.connectivity,
                                reloadAction: { })
            
            // MARK: - Error Alert
            if viewModel.showError {
                VStack {
                    Spacer()
                    SnackBarView(message: viewModel.errorMessage)
                }
                .padding(.bottom, viewModel.connectivity.isInternetAvaliable
                         ? 0 : OfflineSnackBarView.height)
                .transition(.move(edge: .bottom))
                .onAppear {
                    doAfter(Theme.Timeout.snackbarMessageLongTimeout) {
                        viewModel.errorMessage = nil
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .background(
            Theme.Colors.brandCream
                .ignoresSafeArea()
        )
    }
}

#if DEBUG
struct CourseVerticalView_Previews: PreviewProvider {
    static var previews: some View {
        let chapters = [
            CourseChapter(
                blockId: "1",
                id: "1",
                displayName: "Chapter 1",
                type: .chapter,
                childs: [
                    CourseSequential(
                        blockId: "3",
                        id: "3",
                        displayName: "Sequential",
                        type: .sequential,
                        completion: 1,
                        childs: [
                            CourseVertical(
                                blockId: "4",
                                id: "4",
                                courseId: "1",
                                displayName: "Vertical",
                                type: .vertical,
                                completion: 0,
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
                ])
        ]
        
        let viewModel = CourseVerticalViewModel(
            chapters: chapters,
            chapterIndex: 0,
            sequentialIndex: 0,
            router: CourseRouterMock(),
            analytics: CourseAnalyticsMock(),
            connectivity: Connectivity()
        )
        
        return Group {
            CourseVerticalView(
                title: "Course title",
                courseName: "CourseName",
                courseID: "1",
                viewModel: viewModel
            )
            .preferredColorScheme(.light)
            .previewDisplayName("CourseVerticalView Light")
            
            CourseVerticalView(
                title: "Course title",
                courseName: "CourseName",
                courseID: "1",
                viewModel: viewModel
            )
            .preferredColorScheme(.dark)
            .previewDisplayName("CourseVerticalView Dark")
        }
        
    }
}
#endif
