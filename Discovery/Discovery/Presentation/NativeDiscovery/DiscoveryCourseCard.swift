//
//  DiscoveryCourseCard.swift
//  Discovery
//
//  Tarjeta horizontal de curso con línea de acento de color rotativo.
//  Reemplaza CourseCellView en el listado de Discovery.
//

import SwiftUI
import Kingfisher
import Theme
import Core

private let accentColors: [Color] = [
    Theme.Colors.brandGreen,
    Color(red: 0.380, green: 0.071, blue: 0.196), // guinda #611232
    Theme.Colors.brandWarmDark,
    Theme.Colors.brandGreenDark,
]

struct DiscoveryCourseCard: View {
    let course: CourseItem
    let index: Int
    let onClick: () -> Void

    private var accentColor: Color {
        accentColors[index % accentColors.count]
    }

    var body: some View {
        Button(action: onClick) {
            VStack(spacing: 0) {
                // Línea de acento superior
                Rectangle()
                    .fill(accentColor)
                    .frame(height: 3)

                // Contenido horizontal
                HStack(spacing: 0) {
                    // Imagen del curso
                    KFImage(URL(string: course.imageURL))
                        .placeholder {
                            Rectangle()
                                .fill(Theme.Colors.brandCream)
                        }
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipped()

                    // Columna de texto
                    VStack(alignment: .leading, spacing: 0) {
                        // Org
                        Text(course.org)
                            .font(Theme.Fonts.ttRoundsBody(9, weight: 600))
                            .foregroundColor(Theme.Colors.brandCardSecondary)
                            .kerning(0.3)
                            .lineLimit(1)

                        Spacer()

                        // Nombre del curso
                        Text(course.name)
                            .font(Theme.Fonts.ttRoundsCompressedMedium(14))
                            .foregroundColor(Theme.Colors.brandCardPrimary)
                            .kerning(-0.2)
                            .lineSpacing(4)
                            .lineLimit(2)

                        Spacer()

                        // Badge "Inscrito" si hasAccess
                        if course.hasAccess {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Theme.Colors.brandGreen)
                                    .frame(width: 5, height: 5)
                                Text("Inscrito")
                                    .font(Theme.Fonts.ttRoundsBody(9, weight: 600))
                                    .foregroundColor(Theme.Colors.brandGreen)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 120)
            }
        }
        .buttonStyle(.plain)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.10), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    let mockCourse = CourseItem(
        name: "Búsqueda en Internet para Universitarios",
        org: "Universidad Autónoma del Estado de Morelos",
        shortDescription: "",
        imageURL: "",
        hasAccess: true,
        courseStart: nil,
        courseEnd: nil,
        enrollmentStart: nil,
        enrollmentEnd: nil,
        courseID: "course-v1:test+test+2024",
        numPages: 1,
        coursesCount: 1,
        courseRawImage: nil,
        progressEarned: 0,
        progressPossible: 0
    )
    VStack(spacing: 10) {
        DiscoveryCourseCard(course: mockCourse, index: 0, onClick: {})
        DiscoveryCourseCard(course: mockCourse, index: 1, onClick: {})
        DiscoveryCourseCard(course: mockCourse, index: 2, onClick: {})
        DiscoveryCourseCard(course: mockCourse, index: 3, onClick: {})
    }
    .padding()
    .background(Theme.Colors.brandCream)
}
