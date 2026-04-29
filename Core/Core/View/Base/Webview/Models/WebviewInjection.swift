//
//  WebviewInjection.swift
//  Core
//
//  Created by Vadim Kuznetsov on 4.01.24.
//

import WebKit
public struct WebviewInjection: WebViewScriptInjectionProtocol {
    public var id: String
    public var script: String
    public var messages: [WebviewMessage]?
    public var injectionTime: WKUserScriptInjectionTime
    public var forMainFrameOnly: Bool
    init(
        id: String,
        script: String,
        messages: [WebviewMessage]? = nil,
        injectionTime: WKUserScriptInjectionTime = .atDocumentEnd,
        forMainFrameOnly: Bool = true
    ) {
        self.id = id
        self.script = script
        self.messages = messages
        self.injectionTime = injectionTime
        self.forMainFrameOnly = forMainFrameOnly
    }
    
    public static func == (lhs: WebviewInjection, rhs: WebviewInjection) -> Bool {
        lhs.id == rhs.id &&
        lhs.script == rhs.script &&
        lhs.injectionTime == rhs.injectionTime &&
        lhs.messages == rhs.messages &&
        lhs.forMainFrameOnly == rhs.forMainFrameOnly
    }
}

public extension WebviewInjection {

    static var surveyCSS: WebviewInjection {
        SurveyCssInjection()
            .webviewInjection()
    }
    
    static var dragAndDropCss: WebviewInjection {
        DragAndDropCssInjection()
            .webviewInjection()
    }

    static var colorInversionCss: WebviewInjection {
        ColorInversionInjection()
            .webviewInjection()
    }

    static var ajaxCallback: WebviewInjection {
        AjaxInjection()
            .webviewInjection()
    }
    
    static var readability: WebviewInjection {
        ReadabilityInjection()
            .webviewInjection()
    }
    
    static var accessibility: WebviewInjection {
        AccessibilityInjection()
            .webviewInjection()
    }

    /// CSS de marca para ContentReaderView: brandCream bg, Noto Sans, legibilidad móvil + dark mode.
    /// touch-action: pan-y en body = Layer A anti-conflict (WKWebView cede swipe horizontal al TabView paging).
    static var readerBrandCSS: WebviewInjection {
        WebviewInjection(
            id: "readerBrandCSS",
            script: """
            (function() {
                if (document.getElementById('readerBrandCSS')) return;
                var s = document.createElement('style');
                s.id = 'readerBrandCSS';
                s.textContent = [
                    'body{font-family:-apple-system,"Noto Sans",sans-serif;font-size:17px;line-height:1.65;',
                    'color:#1A1A1A;background-color:#FAF6F0;padding:20px 24px 120px 24px;',
                    'max-width:680px;margin:0 auto;overflow-x:hidden;word-wrap:break-word;',
                    '-webkit-text-size-adjust:100%;touch-action:pan-y;}',
                    'img,video,iframe{max-width:100%;height:auto;border-radius:8px;}',
                    'table{display:block;overflow-x:auto;-webkit-overflow-scrolling:touch;touch-action:pan-x pan-y;}',
                    'pre{white-space:pre-wrap;word-break:break-word;overflow-x:auto;touch-action:pan-x pan-y;}',
                    'a{color:#8B1D41;}',
                    'h1,h2,h3,h4{line-height:1.3;}',
                    '@media(prefers-color-scheme:dark){',
                    'body{background-color:#1C1C1E;color:#F2F2F7;}',
                    'a{color:#FF9F9F;}}'
                ].join('');
                document.head.appendChild(s);
            })();
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
    }

    /// Layer B (JS): ajusta touch-action dinámicamente según scrollWidth del contenido.
    /// Si el contenido desborda el viewport (tablas anchas, código), restaura touch-action:auto en body.
    static var readerGestureAdjuster: WebviewInjection {
        WebviewInjection(
            id: "readerGestureAdjuster",
            script: """
            (function() {
                function adjust() {
                    var overflows = document.body.scrollWidth > window.innerWidth + 4;
                    document.body.style.touchAction = overflows ? 'auto' : 'pan-y';
                }
                adjust();
                window.addEventListener('resize', adjust);
                window.addEventListener('load', adjust);
                if (window.MutationObserver) {
                    new MutationObserver(function() { setTimeout(adjust, 80); })
                        .observe(document.body, { childList: true, subtree: true, attributes: false });
                }
            })();
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
    }
}
