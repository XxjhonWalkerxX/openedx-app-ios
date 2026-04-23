import Foundation

public struct EnvironmentConfig {
    // Estas funciones leen directamente lo que inyectamos con el script de Build Phases
    public static var llaveMXClientID: String {
        ProcessInfo.processInfo.environment["LLAVEMX_CLIENT_ID"] ?? "MISSING_ID"
    }
    
    public static var llaveMXAuthorizationURL: String {
        ProcessInfo.processInfo.environment["LLAVEMX_AUTH_URL"] ?? "https://val-llave.infotec.mx/oauth.xhtml"
    }

    public static var llaveMXRedirectURI: String {
        ProcessInfo.processInfo.environment["LLAVEMX_REDIRECT_URI"] ?? "mx.aprende.ios://oauth/callback"
    }

    public static var llaveMXCallbackScheme: String {
        ProcessInfo.processInfo.environment["LLAVEMX_CALLBACK_SCHEME"] ?? "mx.aprende.ios"
    }
}
