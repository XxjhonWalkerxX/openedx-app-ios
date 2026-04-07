//
//  LlaveMXAuthProvider.swift
//  Authorization
//
//  OAuth 2.0 con PKCE para LlaveMX — equivalente iOS de LlaveMxAuthManager.kt (Android)
//

import Foundation
import AuthenticationServices
import CryptoKit

// MARK: - Resultado

public enum LlaveMXAuthResult {
    case success(accessToken: String, refreshToken: String)
    case failure(Error)
}

// MARK: - Errores

public enum LlaveMXError: LocalizedError {
    case invalidCallbackURL
    case missingCode
    case stateMismatch
    case missingCodeVerifier
    case serverError(String)
    case networkError(String)

    public var errorDescription: String? {
        switch self {
        case .invalidCallbackURL:   return "URL de callback inválida"
        case .missingCode:          return "No se recibió el código de autorización"
        case .stateMismatch:        return "Error de seguridad: state inválido (CSRF)"
        case .missingCodeVerifier:  return "Error interno: code_verifier no encontrado"
        case .serverError(let msg): return "Error del servidor: \(msg)"
        case .networkError(let msg): return "Error de red: \(msg)"
        }
    }
}

// MARK: - Proveedor

@MainActor
public final class LlaveMXAuthProvider: NSObject {

    // Configuración OAuth
    private static let clientID          = "202602091646467055"
    private static let authorizationURL  = "https://val-llave.infotec.mx/oauth.xhtml"
    // HTTPS bridge igual que Android — el servidor redirige a mx.aprende.ios://oauth/callback
    private static let redirectURI       = "https://dev.mexicox.gob.mx/mobile/callback"
    private static let callbackScheme    = "mx.aprende.ios"

    // UserDefaults keys (temporales durante el flujo)
    private static let keyCodeVerifier   = "llavemx_code_verifier"
    private static let keyState          = "llavemx_state"

    private let apiBaseURL: String

    // Referencia para mantener viva la sesión ASWebAuthenticationSession
    private var authSession: ASWebAuthenticationSession?
    private var presentationAnchor: ASPresentationAnchor?

    public init(apiBaseURL: String) {
        self.apiBaseURL = apiBaseURL
    }

    // MARK: - Punto de entrada principal

    /// Inicia el flujo completo OAuth PKCE y devuelve tokens de Open edX.
    @MainActor
    public func authenticate(from anchor: ASPresentationAnchor) async throws -> (accessToken: String, refreshToken: String) {
        // 1. Generar PKCE
        let codeVerifier = generateAndStoreCodeVerifier()
        let codeChallenge = sha256Base64URL(codeVerifier)
        let state = generateAndStoreState()

        // 2. Construir URL de autorización
        let authURL = buildAuthorizationURL(codeChallenge: codeChallenge, state: state)

        // 3. Abrir ASWebAuthenticationSession y esperar callback
        let callbackURL = try await openAuthSession(url: authURL, anchor: anchor)

        // 4. Procesar callback
        let (code, returnedState) = try extractParams(from: callbackURL)

        // 5. Validar state (protección CSRF)
        guard returnedState == UserDefaults.standard.string(forKey: Self.keyState) else {
            clearStoredData()
            throw LlaveMXError.stateMismatch
        }

        // 6. Obtener code_verifier almacenado
        guard let storedVerifier = UserDefaults.standard.string(forKey: Self.keyCodeVerifier) else {
            clearStoredData()
            throw LlaveMXError.missingCodeVerifier
        }

        clearStoredData()

        // 7. Intercambiar code + code_verifier por tokens de Open edX
        return try await exchangeCodeForTokens(code: code, codeVerifier: storedVerifier)
    }

    // MARK: - PKCE helpers

    private func generateAndStoreCodeVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 64)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        let verifier = Data(bytes).base64URLEncodedString()
        UserDefaults.standard.set(verifier, forKey: Self.keyCodeVerifier)
        return verifier
    }

    private func generateAndStoreState() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        let state = Data(bytes).base64URLEncodedString()
        UserDefaults.standard.set(state, forKey: Self.keyState)
        return state
    }

    private func sha256Base64URL(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return Data(hash).base64URLEncodedString()
    }

    private func clearStoredData() {
        UserDefaults.standard.removeObject(forKey: Self.keyCodeVerifier)
        UserDefaults.standard.removeObject(forKey: Self.keyState)
    }

    // MARK: - Authorization URL

    private func buildAuthorizationURL(codeChallenge: String, state: String) -> URL {
        var components = URLComponents(string: Self.authorizationURL)!
        // IMPORTANTE: LlaveMX usa "redirect_url" (no redirect_uri) — igual que Android
        components.queryItems = [
            URLQueryItem(name: "response_type",           value: "code"),
            URLQueryItem(name: "client_id",               value: Self.clientID),
            URLQueryItem(name: "redirect_url",            value: Self.redirectURI),
            URLQueryItem(name: "code_challenge",          value: codeChallenge),
            URLQueryItem(name: "code_challenge_method",   value: "S256"),
            URLQueryItem(name: "state",                   value: state),
        ]
        return components.url!
    }

    // MARK: - ASWebAuthenticationSession

    @MainActor
    private func openAuthSession(url: URL, anchor: ASPresentationAnchor) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: Self.callbackScheme
            ) { callbackURL, error in
                if let error = error {
                    if (error as? ASWebAuthenticationSessionError)?.code == .canceledLogin {
                        continuation.resume(throwing: LlaveMXError.networkError("Usuario canceló el inicio de sesión"))
                    } else {
                        continuation.resume(throwing: LlaveMXError.networkError(error.localizedDescription))
                    }
                    return
                }
                guard let callbackURL else {
                    continuation.resume(throwing: LlaveMXError.invalidCallbackURL)
                    return
                }
                continuation.resume(returning: callbackURL)
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            self.presentationAnchor = anchor
            self.authSession = session
            session.start()
        }
    }

    // MARK: - Callback parsing

    private func extractParams(from url: URL) throws -> (code: String, state: String) {
        // Chrome / WebView a veces codifica '&' como '&amp;' — igual que Android
        let urlString = url.absoluteString.replacingOccurrences(of: "&amp;", with: "&")
        guard let components = URLComponents(string: urlString) else {
            throw LlaveMXError.invalidCallbackURL
        }

        if let errorParam = components.queryItems?.first(where: { $0.name == "error" })?.value {
            let desc = components.queryItems?.first(where: { $0.name == "error_description" })?.value ?? errorParam
            throw LlaveMXError.serverError(desc)
        }

        guard let code = components.queryItems?.first(where: { $0.name == "code" })?.value,
              !code.isEmpty else {
            throw LlaveMXError.missingCode
        }

        let state = components.queryItems?.first(where: { $0.name == "state" })?.value ?? ""
        return (code, state)
    }

    // MARK: - Token exchange con backend Open edX

    private func exchangeCodeForTokens(code: String, codeVerifier: String) async throws -> (accessToken: String, refreshToken: String) {
        guard let url = URL(string: "\(apiBaseURL)/api/mobile/llavemx/login/") else {
            throw LlaveMXError.networkError("URL de backend inválida")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyParams = [
            "code": code,
            "code_verifier": codeVerifier,
            "redirect_uri": Self.redirectURI,
        ]
        request.httpBody = bodyParams
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LlaveMXError.networkError("Respuesta inválida del servidor")
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "sin detalle"
            throw LlaveMXError.serverError("HTTP \(httpResponse.statusCode): \(body)")
        }

        let json = try JSONDecoder().decode(TokenResponse.self, from: data)

        guard let accessToken = json.accessToken, !accessToken.isEmpty,
              let refreshToken = json.refreshToken else {
            let errorMsg = json.error ?? "Respuesta sin tokens"
            throw LlaveMXError.serverError(errorMsg)
        }

        return (accessToken, refreshToken)
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension LlaveMXAuthProvider: ASWebAuthenticationPresentationContextProviding {
    public nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Acceso seguro desde el MainActor — UIWindow siempre se usa en main thread
        return MainActor.assumeIsolated {
            presentationAnchor ?? ASPresentationAnchor()
        }
    }
}

// MARK: - Response model

private struct TokenResponse: Decodable {
    let accessToken: String?
    let refreshToken: String?
    let tokenType: String?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case accessToken  = "access_token"
        case refreshToken = "refresh_token"
        case tokenType    = "token_type"
        case error        = "error"
    }
}

// MARK: - Data extension

private extension Data {
    /// Base64 URL-safe sin padding — igual que Android Base64.URL_SAFE | NO_WRAP | NO_PADDING
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
