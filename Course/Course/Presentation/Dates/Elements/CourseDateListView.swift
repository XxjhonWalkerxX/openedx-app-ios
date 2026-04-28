//
//  CourseDateListView.swift
//  Course
//
//  Created by Ivan Stepanok on 09.12.2024.
//

import SwiftUI
import Core
import Theme

struct CourseDateListView: View {
    @ObservedObject var viewModel: CourseDatesViewModel
    @State private var isExpanded = false
    @Binding var coordinate: CGFloat
    @Binding var collapsed: Bool
    @Binding var viewHeight: CGFloat
    var courseDates: CourseDates
    let courseID: String
    
    var body: some View {
        GeometryReader { proxy in
            VStack {
                ScrollView {
                    DynamicOffsetView(
                        coordinate: $coordinate,
                        collapsed: $collapsed,
                        viewHeight: $viewHeight,
                        externalHeight: $viewHeight
                    )
                    VStack(alignment: .leading, spacing: 16) {

                        statsHeroCard

                        @State var status: SyncStatus = .offline

                        CalendarSyncStatusView(status: status, router: viewModel.router)
                            .task {
                                status = await viewModel.syncStatus()
                            }

                        if !courseDates.hasEnded {
                            DatesStatusInfoView(
                                datesBannerInfo: courseDates.datesBannerInfo,
                                courseID: courseID,
                                courseDatesViewModel: viewModel,
                                screen: .courseDates
                            )
                        }

                        ForEach(Array(viewModel.sortedStatuses), id: \.self) { status in
                            statusSection(status: status)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 5)
                    .frameLimit(width: proxy.size.width)
                    Spacer(minLength: 200)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // MARK: - Stats hero card

    private var statsHeroCard: some View {
        let blocks = courseDates.courseDateBlocks
        let pending = blocks.filter { ($0.complete ?? false) == false && $0.dateType != "course-start-date" }.count
        let nextBlock = blocks
            .filter { $0.date > Date() && ($0.complete ?? false) == false }
            .min(by: { $0.date < $1.date })
        let nextDate: String = nextBlock.map { Self.shortDateFormatter.string(from: $0.date) } ?? "—"

        return HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(pending)")
                    .font(Theme.Fonts.notoSans(28, weight: .bold))
                    .foregroundStyle(Theme.Colors.guindaColor)
                Text("PENDIENTES")
                    .font(Theme.Fonts.notoSans(10, weight: .medium))
                    .tracking(0.5)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Rectangle()
                .fill(Theme.Colors.brandCreamStrong)
                .frame(width: 1, height: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(nextDate)
                    .font(Theme.Fonts.notoSans(20, weight: .bold))
                    .foregroundStyle(Theme.Colors.brandGreen)
                Text("PRÓXIMA FECHA")
                    .font(Theme.Fonts.notoSans(10, weight: .medium))
                    .tracking(0.5)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 16)
        }
        .padding(16)
        .background(Theme.Colors.surfaceWhite)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Sizes.radiusCard, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private static let shortDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "es_MX")
        df.dateFormat = "d MMM"
        return df
    }()

    // MARK: - Status section

    @ViewBuilder
    private func statusSection(status: CompletionStatus) -> some View {
        let courseDateBlockDict = courseDates.statusDatesBlocks[status] ?? [:]
        if status == .completed {
            CompletedBlocks(
                isExpanded: $isExpanded,
                courseDateBlockDict: courseDateBlockDict,
                viewModel: viewModel
            )
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Text(status.rawValue.uppercased())
                    .font(Theme.Fonts.notoSans(11, weight: .semibold))
                    .tracking(0.5)
                    .foregroundStyle(Theme.Colors.guindaColor)
                    .padding(.leading, 2)

                HStack(alignment: .top, spacing: 12) {
                    TimeLineView(status: status)
                        .padding(.top, 4)

                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(courseDateBlockDict.keys.sorted(), id: \.self) { date in
                            let blocks = courseDateBlockDict[date]!
                            let block = blocks[0]
                            VStack(alignment: .leading, spacing: 4) {
                                Text(block.formattedDate)
                                    .font(Theme.Fonts.notoSans(13, weight: .semibold))
                                    .foregroundStyle(Theme.Colors.textPrimary)
                                BlockStatusView(
                                    viewModel: viewModel,
                                    block: block,
                                    blocks: blocks
                                )
                            }
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.Colors.surfaceWhite)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Sizes.radiusCard, style: .continuous))
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
                }
            }
        }
    }
}
