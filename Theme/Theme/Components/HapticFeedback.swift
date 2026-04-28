//
//  HapticFeedback.swift
//  Theme
//
//  API centralizada de hápticos @prende.mx.
//  Regla: máximo 1 háptico por tap, nunca en scroll.
//

import UIKit

public enum HapticFeedback {

    /// Impacto físico — tap en cards, CTAs
    public static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .soft) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    /// Notificación — éxito/error en quiz, lección completada
    public static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    /// Selección — tab activo, chip seleccionado
    public static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
