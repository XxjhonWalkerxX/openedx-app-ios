//
//  SignInView.swift
//  Authorization
//
//  Pantalla de login — @prende.mx
//  Replica SignInScreen de openedx-app-android/theme-cursos
//

import SwiftUI
import Core
import OEXFoundation
import Theme
import Swinject

public struct SignInView: View {

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showTraditionalLogin: Bool = false

    @Environment(\.isHorizontal) private var isHorizontal

    @ObservedObject
    private var viewModel: SignInViewModel

    public init(viewModel: SignInViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack(alignment: .top) {
            // Hero verde sólido (45% superior)
            VStack(spacing: 0) {
                Theme.Colors.brandGreen
                    .frame(height: UIScreen.main.bounds.height * 0.45)
                    .ignoresSafeArea(edges: .top)
                Spacer()
            }

            // Banda guinda 4pt
            VStack {
                Theme.Colors.guindaColor
                    .frame(height: 4)
                    .ignoresSafeArea(edges: .top)
                Spacer()
            }

            // Círculos decorativos en hero
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 28)
                        .frame(width: 180, height: 180)
                        .offset(x: 130, y: -30)
                    Circle()
                        .strokeBorder(Color.white.opacity(0.05), lineWidth: 18)
                        .frame(width: 100, height: 100)
                        .offset(x: -120, y: 160)
                }
                .frame(height: UIScreen.main.bounds.height * 0.45)
                .allowsHitTesting(false)
                Spacer()
            }

            // Back button
            if viewModel.config.features.startupScreenEnabled {
                VStack {
                    HStack {
                        Button { viewModel.router.back() } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.15))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "arrow.left")
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.leading, isHorizontal ? 48 : 16)
                        .padding(.top, 12)
                        .accessibilityIdentifier("back_button")
                        Spacer()
                    }
                    Spacer()
                }
                .ignoresSafeArea(edges: .top)
            }

            // Contenido principal
            ScrollView {
                VStack(spacing: 0) {
                    // Logo + slogan en hero
                    heroLogoSection
                        .padding(.top, viewModel.config.features.startupScreenEnabled ? 60 : 36)

                    // Card crema
                    VStack(spacing: 0) {
                        Capsule()
                            .fill(Theme.Colors.brandHandle)
                            .frame(width: 36, height: 4)
                            .padding(.top, 12)

                        Spacer().frame(height: 20)

                        VStack(spacing: 12) {
                            // LlaveMX
                            llaveMXCard

                            // Login tradicional (colapsable)
                            if viewModel.config.uiComponents.loginRegistrationEnabled {
                                traditionalLoginCard
                            }

                            // Social auth (Apple, etc.)
                            if viewModel.socialAuthEnabled {
                                SocialAuthView(
                                    viewModel: .init(
                                        config: viewModel.config,
                                        lastUsedOption: viewModel.storage.lastUsedSocialAuth
                                    ) { result in
                                        Task { await viewModel.login(with: result) }
                                    }
                                )
                                .padding(.top, 4)
                            }

                            // SAML SSO
                            if viewModel.config.uiComponents.samlSSOLoginEnabled {
                                ssoSection
                            }
                        }
                        .padding(.horizontal, 16)

                        // Acuerdos legales
                        agreements
                            .padding(.horizontal, 16)

                        Spacer().frame(height: 40)
                    }
                    .frame(maxWidth: .infinity)
                    .background(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 32,
                            topTrailingRadius: 32
                        )
                        .fill(Theme.Colors.brandCream)
                    )
                    .offset(y: -28)
                }
            }
            .ignoresSafeArea(edges: .top)
            .scrollAvoidKeyboard(dismissKeyboardByTap: true)

            // Alert snackbar top
            if viewModel.showAlert {
                VStack {
                    Text(viewModel.alertMessage ?? "")
                        .shadowCardStyle(
                            bgColor: Theme.Colors.accentColor,
                            textColor: Theme.Colors.white
                        )
                        .padding(.top, 80)
                    Spacer()
                }
                .transition(.move(edge: .top))
                .onAppear {
                    doAfter(Theme.Timeout.snackbarMessageLongTimeout) {
                        viewModel.alertMessage = nil
                    }
                }
            }

            // Error snackbar bottom
            if viewModel.showError {
                VStack {
                    Spacer()
                    SnackBarView(message: viewModel.errorMessage)
                }
                .transition(.move(edge: .bottom))
                .onAppear {
                    doAfter(Theme.Timeout.snackbarMessageLongTimeout) {
                        viewModel.errorMessage = nil
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .background(Theme.Colors.brandCream.ignoresSafeArea(.all))
        .onFirstAppear { viewModel.trackScreenEvent() }
    }

    // MARK: - Hero logo

    private var heroLogoSection: some View {
        VStack(spacing: 10) {
            ThemeAssets.aprendeLogoMarquesina.swiftUIImage
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 160)
                .foregroundColor(.white)
                .accessibilityIdentifier("logo_image")

            ThemeAssets.aprendeSlogan.swiftUIImage
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.white.opacity(0.85))
                .padding(.horizontal, 48)

            Spacer().frame(height: 28)
        }
    }

    // MARK: - LlaveMX Card

    private var llaveMXCard: some View {
        VStack(spacing: 0) {
            Text("Inicia sesión con tu cuenta")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(red: 0.18, green: 0.18, blue: 0.16))

            Spacer().frame(height: 18)

            AsyncImage(url: URL(string: "https://aprende.gob.mx/images/llaveMX.png")) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fit)
                case .failure:
                    Text("LlaveMX")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Theme.Colors.guindaColor)
                default:
                    ProgressView()
                }
            }
            .frame(width: 170, height: 54)
            .accessibilityIdentifier("llave_mx_image")

            Spacer().frame(height: 20)

            if viewModel.isShowProgress {
                ProgressBar(size: 40, lineWidth: 8)
                    .padding(20)
                    .accessibilityIdentifier("progress_bar")
            } else {
                Button {
                    Task {
                        if let window = UIApplication.shared.connectedScenes
                            .compactMap({ $0 as? UIWindowScene })
                            .first?.windows.first {
                            await viewModel.signInWithLlaveMX(from: window)
                        }
                    }
                } label: {
                    Text("Iniciar sesión")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Capsule().fill(Theme.Colors.guindaColor))
                }
                .accessibilityIdentifier("llave_mx_signin_button")
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.07), radius: 4, y: 2)
        )
    }

    // MARK: - Traditional Login (collapsible)

    private var traditionalLoginCard: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showTraditionalLogin.toggle()
                }
            } label: {
                HStack {
                    Text("Iniciar sesión con correo y contraseña")
                        .font(.system(size: 13))
                        .foregroundColor(Color(red: 0.45, green: 0.42, blue: 0.37))
                    Spacer()
                    Image(systemName: showTraditionalLogin ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13))
                        .foregroundColor(Color(red: 0.6, green: 0.58, blue: 0.55))
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 15)
            }

            if showTraditionalLogin {
                Divider().background(Color(red: 0.92, green: 0.90, blue: 0.87))

                VStack(alignment: .leading, spacing: 12) {
                    // Email
                    VStack(alignment: .leading, spacing: 5) {
                        Text(AuthLocalization.SignIn.emailOrUsername)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Theme.Colors.brandGreen)
                            .accessibilityIdentifier("username_text")

                        TextField("", text: $email)
                            .font(Theme.Fonts.bodyLarge)
                            .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.11))
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .padding(13)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(red: 0.97, green: 0.96, blue: 0.95))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .strokeBorder(Color(red: 0.86, green: 0.84, blue: 0.81), lineWidth: 1)
                                    )
                            )
                            .accessibilityIdentifier("username_textfield")
                    }

                    // Password
                    VStack(alignment: .leading, spacing: 5) {
                        Text(AuthLocalization.SignIn.password)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Theme.Colors.brandGreen)
                            .accessibilityIdentifier("password_text")

                        SecureInputView($password)
                            .font(Theme.Fonts.bodyLarge)
                            .padding(13)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(red: 0.97, green: 0.96, blue: 0.95))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .strokeBorder(Color(red: 0.86, green: 0.84, blue: 0.81), lineWidth: 1)
                                    )
                            )
                            .accessibilityIdentifier("password_textfield")
                    }

                    HStack {
                        if !viewModel.config.features.startupScreenEnabled {
                            Button(CoreLocalization.SignIn.registerBtn) {
                                viewModel.router.showRegisterScreen(sourceScreen: viewModel.sourceScreen)
                            }
                            .foregroundColor(Theme.Colors.brandGreen)
                            .accessibilityIdentifier("register_button")
                            Spacer()
                        }

                        Button(AuthLocalization.SignIn.forgotPassBtn) {
                            viewModel.trackForgotPasswordClicked()
                            viewModel.router.showForgotPasswordScreen()
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.Colors.brandGreen)
                        .accessibilityIdentifier("forgot_password_button")
                    }

                    // Sign In button
                    if viewModel.isShowProgress {
                        HStack {
                            ProgressBar(size: 40, lineWidth: 8)
                                .padding(20)
                                .accessibilityIdentifier("progress_bar")
                        }.frame(maxWidth: .infinity)
                    } else {
                        Button {
                            Task { await viewModel.login(username: email, password: password) }
                        } label: {
                            Text(CoreLocalization.SignIn.logInBtn)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Capsule().fill(Theme.Colors.brandGreen))
                        }
                        .accessibilityIdentifier("signin_button")
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 15)
            }
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        )
    }

    // MARK: - SSO Section

    private var ssoSection: some View {
        VStack(alignment: .center, spacing: 0) {
            if !viewModel.config.uiComponents.loginRegistrationEnabled {
                Text(AuthLocalization.SignIn.ssoHeading)
                    .font(Theme.Fonts.headlineSmall)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Theme.Colors.textPrimary)
                    .padding(.bottom, 4)
                    .padding(.horizontal, 20)
                    .accessibilityIdentifier("signin_sso_heading")

                Divider()

                Text(AuthLocalization.SignIn.ssoLogInTitle)
                    .font(Theme.Fonts.headlineSmall)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Theme.Colors.textPrimary)
                    .padding(.bottom, 10)
                    .padding(.horizontal, 20)
                    .accessibilityIdentifier("signin_sso_login_title")

                Text(AuthLocalization.SignIn.ssoLogInSubtitle)
                    .font(Theme.Fonts.titleMedium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Theme.Colors.textSecondaryLight)
                    .padding(.bottom, 10)
                    .padding(.horizontal, 20)
                    .accessibilityIdentifier("signin_sso_login_subtitle")
            }

            if viewModel.isShowProgress {
                HStack {
                    ProgressBar(size: 40, lineWidth: 8)
                        .padding(20)
                        .accessibilityIdentifier("progressbar")
                }.frame(maxWidth: .infinity)
            } else {
                let languageCode = Locale.current.language.languageCode?.identifier ?? "en"
                StyledButton(
                    viewModel.config.ssoButtonTitle[languageCode] as! String,
                    action: {
                        viewModel.router.showSSOWebBrowser(title: CoreLocalization.SignIn.logInBtn)
                    },
                    color: viewModel.config.uiComponents.samlSSODefaultLoginButton
                        ? Theme.Colors.accentColor : .white,
                    textColor: viewModel.config.uiComponents.samlSSODefaultLoginButton
                        ? Theme.Colors.white : Theme.Colors.accentColor,
                    borderColor: viewModel.config.uiComponents.samlSSODefaultLoginButton
                        ? Theme.Colors.accentColor : Theme.Colors.accentColor
                )
                .frame(maxWidth: .infinity)
                .padding(.top, 20)
                .accessibilityIdentifier("signin_SSO_button")
            }
        }
    }

    // MARK: - Agreements

    @ViewBuilder
    private var agreements: some View {
        if let eulaURL = viewModel.config.agreement.eulaURL,
           let tosURL = viewModel.config.agreement.tosURL,
           let policy = viewModel.config.agreement.privacyPolicyURL {
            let text = AuthLocalization.SignIn.agreement(
                "\(viewModel.config.platformName)",
                eulaURL,
                "\(viewModel.config.platformName)",
                tosURL,
                "\(viewModel.config.platformName)",
                policy
            )
            Text(.init(text))
                .tint(Theme.Colors.infoColor)
                .foregroundStyle(Theme.Colors.textSecondaryLight)
                .font(Theme.Fonts.labelSmall)
                .padding(.top, viewModel.socialAuthEnabled ? 0 : 15)
                .padding(.bottom, 15)
                .environment(\.openURL, OpenURLAction(handler: handleURL))
        }
    }

    private func handleURL(_ url: URL) -> OpenURLAction.Result {
        viewModel.router.showWebBrowser(title: "", url: url)
        return .handled
    }
}

#if DEBUG
struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = SignInViewModel(
            interactor: AuthInteractor.mock,
            router: AuthorizationRouterMock(),
            config: ConfigMock(),
            analytics: AuthorizationAnalyticsMock(),
            validator: Validator(),
            storage: CoreStorageMock(),
            sourceScreen: .default
        )

        SignInView(viewModel: vm)
            .preferredColorScheme(.light)
            .previewDisplayName("SignInView Light")
            .loadFonts()
    }
}
#endif
