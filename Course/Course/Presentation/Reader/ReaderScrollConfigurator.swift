import SwiftUI
import WebKit

// MARK: - Environment Key (Layer C bridge)

/// Propaga el UIPanGestureRecognizer del TabView paging desde ContentReaderView
/// hasta VerticalRenderer para coordinar gestos con WKScrollView.
struct ReaderPageGestureKey: EnvironmentKey {
    static let defaultValue: UIPanGestureRecognizer? = nil
}

extension EnvironmentValues {
    var readerPageSwipeGesture: UIPanGestureRecognizer? {
        get { self[ReaderPageGestureKey.self] }
        set { self[ReaderPageGestureKey.self] = newValue }
    }
}

// MARK: - ReaderScrollConfigurator

/// UIViewRepresentable overlay transparente para ContentReaderView.
/// Layer B nativo: configura el WKScrollView del WebView más cercano tras el mount.
/// - alwaysBounceHorizontal = false  → elimina rebote horizontal que confunde al TabView
/// - showsHorizontalScrollIndicator = false
/// - contentInsetAdjustmentBehavior = .never  → header safe-area no desplaza contenido
/// - panGestureRecognizer.require(toFail: pageGR) → cede swipe horizontal al TabView paging
///   Solo cuando el contenido cabe en el viewport (evaluado vía JS callback).
struct ReaderScrollConfigurator: UIViewRepresentable {

    /// Pan gesture del TabView paging (capturado en ContentReaderView via introspect).
    let pageSwipeGesture: UIPanGestureRecognizer?

    func makeUIView(context: Context) -> _Configurator {
        _Configurator(pageSwipeGesture: pageSwipeGesture)
    }

    func updateUIView(_ uiView: _Configurator, context: Context) {
        uiView.pageSwipeGesture = pageSwipeGesture
    }

    // MARK: - Configurator UIView

    final class _Configurator: UIView {
        var pageSwipeGesture: UIPanGestureRecognizer?
        private var didConfigure = false

        init(pageSwipeGesture: UIPanGestureRecognizer?) {
            self.pageSwipeGesture = pageSwipeGesture
            super.init(frame: .zero)
            isHidden = true
            isUserInteractionEnabled = false
            backgroundColor = .clear
        }

        required init?(coder: NSCoder) { fatalError() }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard window != nil, !didConfigure else { return }
            // Espera a que WKWebView complete su primer layout
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                self?.applyConfiguration()
            }
        }

        private func applyConfiguration() {
            guard let wkWebView = nearestWKWebView(from: self) else { return }
            let sv = wkWebView.scrollView
            sv.alwaysBounceHorizontal = false
            sv.showsHorizontalScrollIndicator = false
            sv.contentInsetAdjustmentBehavior = .never

            // Layer C: si hay pageGR, verifica scrollWidth antes de coordinar
            if let pageGR = pageSwipeGesture {
                wkWebView.evaluateJavaScript(
                    "document.body.scrollWidth <= window.innerWidth + 4"
                ) { [weak sv] result, _ in
                    guard let fits = result as? Bool, fits else { return }
                    // Contenido cabe → swipe horizontal va al TabView paging
                    sv?.panGestureRecognizer.require(toFail: pageGR)
                }
            }

            didConfigure = true
        }

        // MARK: - Hierarchy Walk

        /// Sube por superviews hasta encontrar el UIView que contiene un WKWebView,
        /// luego baja por subviews para localizarlo. Acotado a 20 niveles de profundidad.
        private func nearestWKWebView(from view: UIView, depth: Int = 0) -> WKWebView? {
            guard depth < 20 else { return nil }
            if let wk = view as? WKWebView { return wk }
            for sub in view.subviews {
                if let found = nearestWKWebView(from: sub, depth: depth + 1) { return found }
            }
            // No encontrado en este subárbol — sube un nivel
            if let parent = view.superview {
                return nearestWKWebView(from: parent, depth: depth + 1)
            }
            return nil
        }
    }
}
