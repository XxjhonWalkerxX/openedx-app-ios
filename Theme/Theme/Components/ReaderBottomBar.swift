import SwiftUI

// MARK: - ReaderBottomBar

/// Barra inferior del Content Reader con navegación anterior/siguiente y marcado de completado.
public struct ReaderBottomBar: View {

    public let canGoPrevious: Bool
    public let canGoNext: Bool
    public let isCompleted: Bool
    public let isLoading: Bool
    public let onPrevious: () -> Void
    public let onComplete: () -> Void
    public let onNext: () -> Void

    public init(
        canGoPrevious: Bool,
        canGoNext: Bool,
        isCompleted: Bool,
        isLoading: Bool = false,
        onPrevious: @escaping () -> Void,
        onComplete: @escaping () -> Void,
        onNext: @escaping () -> Void
    ) {
        self.canGoPrevious = canGoPrevious
        self.canGoNext = canGoNext
        self.isCompleted = isCompleted
        self.isLoading = isLoading
        self.onPrevious = onPrevious
        self.onComplete = onComplete
        self.onNext = onNext
    }

    public var body: some View {
        HStack(spacing: 0) {
            previousButton
            Spacer()
            completeButton
            Spacer()
            nextButton
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .overlay(Divider(), alignment: .top)
    }

    // MARK: - Previous

    private var previousButton: some View {
        Button(action: { if canGoPrevious { onPrevious() } }) {
            HStack(spacing: 5) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .semibold))
                Text("Anterior")
                    .font(Theme.Fonts.notoSans(14, weight: .medium))
            }
            .foregroundStyle(canGoPrevious ? Theme.Colors.brandGreen : Theme.Colors.textSecondary.opacity(0.4))
        }
        .buttonStyle(.plain)
        .disabled(!canGoPrevious)
        .accessibilityLabel("Sección anterior")
        .accessibilityHint(canGoPrevious ? "Ir a la sección anterior" : "No hay sección anterior")
    }

    // MARK: - Complete

    private var completeButton: some View {
        Button(action: { if !isLoading { onComplete() } }) {
            Group {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(Theme.Colors.surfaceWhite)
                        .scaleEffect(0.8)
                } else {
                    HStack(spacing: 5) {
                        Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 15, weight: .semibold))
                        Text(isCompleted ? "Completado" : "Marcar")
                            .font(Theme.Fonts.notoSans(14, weight: .semibold))
                    }
                }
            }
            .foregroundStyle(isCompleted ? Theme.Colors.surfaceWhite : Theme.Colors.brandGreen)
            .padding(.horizontal, 18)
            .padding(.vertical, 9)
            .background(
                Capsule()
                    .fill(isCompleted ? Theme.Colors.brandGreen : Theme.Colors.brandGreenTint)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isLoading ? 0.97 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isCompleted)
        .accessibilityLabel(isCompleted ? "Sección completada" : "Marcar como completado")
        .accessibilityHint(isCompleted ? "Toca para desmarcar" : "Toca para marcar esta sección")
    }

    // MARK: - Next

    private var nextButton: some View {
        Button(action: { if canGoNext { onNext() } }) {
            HStack(spacing: 5) {
                Text("Siguiente")
                    .font(Theme.Fonts.notoSans(14, weight: .medium))
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(canGoNext ? Theme.Colors.brandGreen : Theme.Colors.textSecondary.opacity(0.4))
        }
        .buttonStyle(.plain)
        .disabled(!canGoNext)
        .accessibilityLabel("Sección siguiente")
        .accessibilityHint(canGoNext ? "Ir a la sección siguiente" : "No hay sección siguiente")
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    VStack(spacing: 0) {
        Spacer()
        ReaderBottomBar(
            canGoPrevious: true,
            canGoNext: true,
            isCompleted: false,
            onPrevious: {},
            onComplete: {},
            onNext: {}
        )
        ReaderBottomBar(
            canGoPrevious: false,
            canGoNext: true,
            isCompleted: true,
            onPrevious: {},
            onComplete: {},
            onNext: {}
        )
    }
    .background(Theme.Colors.brandCream)
    .loadFonts()
}
#endif
