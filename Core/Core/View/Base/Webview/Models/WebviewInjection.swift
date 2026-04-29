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
                    '-webkit-text-size-adjust:100%;}',
                    'img,video,iframe{max-width:100%;height:auto;border-radius:8px;}',
                    'table{display:block;overflow-x:auto;-webkit-overflow-scrolling:touch;}',
                    'pre{white-space:pre-wrap;word-break:break-word;}',
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
}
