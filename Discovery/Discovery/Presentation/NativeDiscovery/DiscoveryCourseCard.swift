//
//  DiscoveryCourseCard.swift
//  Discovery
//
//  Tarjeta de curso: horizontal (lista/búsqueda) o grid 2 columnas.
//

import SwiftUI
import Kingfisher
import Theme
import Core

private let accentColors: [Color] = [
    Theme.Colors.brandGreen,
    Color(red: 0.380, green: 0.071, blue: 0.196),
    Theme.Colors.brandWarmDark,
    Theme.Colors.brandGreenDark
]

struct DiscoveryCourseCard: View {
    let course: CourseItem
    let index: Int
    let isGrid: Bool
    let onClick: () -> Void

    init(course: CourseItem, index: Int, isGrid: Bool = false, onClick: @escaping () -> Void) {
        self.course = course
        self.index = index
        self.isGrid = isGrid
        self.onClick = onClick
    }

    private var accent: Color { accentColors[index % accentColors.count] }

    var body: some View {
        Button(action: onClick) {
            if isGrid {
                gridLayout
            } else {
                listLayout
            }
        }
        .buttonStyle(.plain)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
    }

    // MARK: Grid (2 columnas)
    private var gridLayout: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Franja de acento
            accent.frame(height: 3)

            // Imagen
            KFImage(URL(string: course.imageURL))
                .placeholder {
                    Rectangle().fill(Theme.Colors.brandCream)
                }
                .resizable()
                .scaledToFill()
                .frame(height: 100)
                .clipped()

            // Texto
            VStack(alignment: .leading, spacing: 6) {
                Text(course.org)
                    .font(Theme.Fonts.notoSans(9, weight: .medium))
                    .foregroundColor(Theme.Colors.brandCardSecondary)
                    .lineLimit(1)

                Text(course.name)
                    .font(Theme.Fonts.notoSans(12, weight: .semibold))
                    .foregroundColor(Theme.Colors.brandCardPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                if course.hasAccess {
                    enrolledBadge
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: List (búsqueda / horizontal)
    private var listLayout: some View {
        VStack(spacing: 0) {
            accent.frame(height: 3)

            HStack(spacing: 0) {
                KFImage(URL(string: course.imageURL))
                    .placeholder {
                        Rectangle().fill(Theme.Colors.brandCream)
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: 110, height: 110)
                    .clipped()

                VStack(alignment: .leading, spacing: 0) {
                    Text(course.org)
                        .font(Theme.Fonts.notoSans(9, weight: .medium))
                        .foregroundColor(Theme.Colors.brandCardSecondary)
                        .lineLimit(1)

                    Spacer()

                    Text(course.name)
                        .font(Theme.Fonts.notoSans(13, weight: .semibold))
                        .foregroundColor(Theme.Colors.brandCardPrimary)
                        .lineLimit(2)

                    Spacer()

                    if course.hasAccess {
                        enrolledBadge
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 110)
        }
    }

    private var enrolledBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Theme.Colors.brandGreen)
                .frame(width: 5, height: 5)
            Text("Inscrito")
                .font(Theme.Fonts.notoSans(9, weight: .semibold))
                .foregroundColor(Theme.Colors.brandGreen)
        }
    }
}

#Preview {
    let mock = CourseItem(
        name: "Búsqueda en Internet para Universitarios",
        org: "UNAM",
        shortDescription: "",
        imageURL: "",
        hasAccess: true,
        courseStart: nil, courseEnd: nil,
        enrollmentStart: nil, enrollmentEnd: nil,
        courseID: "course-v1:test",
        numPages: 1, coursesCount: 1,
        courseRawImage: nil,
        progressEarned: 0, progressPossible: 0
    )
    ScrollView {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(0..<4) { i in
                DiscoveryCourseCard(course: mock, index: i, isGrid: true, onClick: {})
            }
        }
        .padding(20)
    }
    .background(Theme.Colors.brandCream)
}
