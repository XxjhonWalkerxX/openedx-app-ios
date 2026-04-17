//
//  CategoryFilterView.swift
//  Dashboard
//
//  Created by  Stepanok Ivan on 24.04.2024.
//

import Theme
import Core
import SwiftUI

enum CategoryOption: String, CaseIterable {
    case all
    case inProgress
    case completed
    case expired
    
    var status: String {
        switch self {
        case .all:
            "all"
        case .inProgress:
            "in_progress"
        case .completed:
            "completed"
        case .expired:
            "expired"
        }
    }
    
    var text: String {
        switch self {
        case .all:
            DashboardLocalization.Learn.Category.all
        case .inProgress:
            DashboardLocalization.Learn.Category.inProgress
        case .completed:
            DashboardLocalization.Learn.Category.completed
        case .expired:
            DashboardLocalization.Learn.Category.expired
        }
    }
}

struct CategoryFilterView: View {
    @Binding var selectedOption: CategoryOption
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                ForEach(Array(CategoryOption.allCases.enumerated()), id: \.offset) { index, option in
                    Button(action: {
                        selectedOption = option
                    },
                           label: {
                        HStack {
                            Text(option.text)
                                .font(Theme.Fonts.ttRoundsBody(15, weight: 500))
                                .foregroundColor(
                                    option == selectedOption
                                    ? Theme.Colors.white
                                    : Theme.Colors.brandGreen
                                )
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(option == selectedOption ? Theme.Colors.brandGreen : Theme.Colors.brandCream)
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Theme.Colors.brandGreen, lineWidth: option == selectedOption ? 0 : 1)
                        }
                    })
                    .padding(.leading, index == 0 ? 20 : 0)
                    .padding(.trailing, index == CategoryOption.allCases.count - 1 ? 20 : 0)
                }
            }
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
    }
}
