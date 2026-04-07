//
//  StartupView.swift
//  Authorization
//
//  Pantalla de bienvenida — @prende.mx
//  Replica OnboardingScreen de openedx-app-android/theme-cursos
//

import Foundation
import SwiftUI
import Core
import Theme

public struct StartupView: View {

    @State private var searchQuery: String = ""
    @State private var cardOffset: CGFloat = 60
    @State private var contentOpacity: Double = 0
    @State private var animateGradient: Bool = false
    @State private var shimmerOffset: CGFloat = -1.5

    @Environment(\.isHorizontal) private var isHorizontal

    @ObservedObject
    private var viewModel: StartupViewModel

    public init(viewModel: StartupViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                // Fondo hero gradiente animado
                LinearGradient(
                    colors: animateGradient
                        ? [Theme.Colors.brandGreenLight, Theme.Colors.brandGreen, Theme.Colors.brandGreenLight]
                        : [Theme.Colors.brandGreenDark, Theme.Colors.brandGreen, Theme.Colors.brandGreenDark],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .animation(.easeInOut(duration: 7).repeatForever(autoreverses: true), value: animateGradient)
                .ignoresSafeArea()

                // Banda guinda 4pt arriba
                VStack(spacing: 0) {
                    Theme.Colors.guindaColor
                        .frame(height: 4)
                        .ignoresSafeArea(edges: .top)
                    Spacer()
                }

                // Círculos decorativos
                decorativeCircles
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                // Layout principal — sin scroll, ajustado a la pantalla
                VStack(spacing: 0) {
                    // Hero — logos + stats
                    heroSection(screenHeight: geo.size.height)
                        .padding(.top, isHorizontal ? 12 : 16)

                    // Card crema flotante
                    VStack(spacing: 0) {
                        // Drag handle
                        Capsule()
                            .fill(Theme.Colors.brandHandle)
                            .frame(width: 36, height: 4)
                            .padding(.top, 10)

                        Spacer().frame(height: 12)

                        // Buscador
                        searchPill
                            .padding(.horizontal, 16)

                        Spacer().frame(height: 12)

                        // Botones de acción
                        VStack(spacing: 10) {
                            llaveMXCard(screenHeight: geo.size.height)
                            traditionalLoginButton
                        }
                        .padding(.horizontal, 16)

                        Spacer().frame(height: 14)

                        // Footer institucional
                        institutionalFooter
                    }
                    .frame(maxWidth: .infinity)
                    .background(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 32,
                            topTrailingRadius: 32
                        )
                        .fill(Theme.Colors.brandCream)
                    )
                    .offset(y: -24 + cardOffset)
                }
            }
            .background(Theme.Colors.brandCream.ignoresSafeArea(.all))
        }
        .navigationTitle(AuthLocalization.Startup.title)
        .navigationBarHidden(true)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .opacity(contentOpacity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.45)) { contentOpacity = 1 }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) { cardOffset = 0 }
            animateGradient = true
            withAnimation(
                .linear(duration: 1.8)
                .delay(2.2)
                .repeatForever(autoreverses: false)
            ) {
                shimmerOffset = 2.0
            }
        }
        .onDisappear { searchQuery = "" }
        .onTapGesture { UIApplication.shared.endEditing() }
        .onFirstAppear { viewModel.trackScreenEvent() }
    }

    // MARK: - Hero

    private func heroSection(screenHeight: CGFloat) -> some View {
        // El hero ocupa ~38% de la pantalla
        let heroHeight = screenHeight * 0.38
        return VStack(spacing: 0) {
            ThemeAssets.aprendeLogoMarquesina.swiftUIImage
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: min(160, screenHeight * 0.19))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .accessibilityIdentifier("logo_image")

            Spacer().frame(height: heroHeight * 0.07)

            ThemeAssets.aprendeSlogan.swiftUIImage
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: heroHeight * 0.42)
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 20)

            Spacer().frame(height: heroHeight * 0.06)

            // Pill de estadísticas
            HStack(spacing: 8) {
                Circle()
                    .fill(Color(red: 0.722, green: 0.878, blue: 0.831))
                    .frame(width: 7, height: 7)
                Text("95 instituciones  ·  1,359 cursos  ·  100% gratuito")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .kerning(0.2)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                Capsule().fill(Color.white.opacity(0.12))
                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.2), lineWidth: 1))
            )

            Spacer().frame(height: heroHeight * 0.1)
        }
    }

    // MARK: - Search Pill

    private var searchPill: some View {
        Button {
            viewModel.router.showDiscoveryScreen(
                searchQuery: searchQuery,
                sourceScreen: .startup
            )
            viewModel.logAnalytics()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15))
                    .foregroundColor(Color(red: 0.6, green: 0.58, blue: 0.55))

                Text("Busca tu curso…")
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.65, green: 0.63, blue: 0.60))

                Spacer()

                Text("Buscar")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(Theme.Colors.brandGreen))
            }
            .padding(.horizontal, 16)
            .frame(height: 46)
            .background(
                Capsule().fill(Color.white)
                    .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
            )
        }
        .accessibilityIdentifier("explore_courses_button")
    }

    // MARK: - LlaveMX Card

    private func llaveMXCard(screenHeight: CGFloat) -> some View {
        let logoH = min(CGFloat(80), screenHeight * 0.094)
        return VStack(spacing: 0) {
            Text("Inicia sesión con tu cuenta")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(red: 0.239, green: 0.227, blue: 0.212))

            Spacer().frame(height: 12)

            AsyncImage(url: URL(string: "https://aprende.gob.mx/images/llaveMX.png")) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fit)
                case .failure:
                    Text("LlaveMX")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Theme.Colors.guindaColor)
                default:
                    ProgressView()
                }
            }
            .frame(height: logoH)

            Spacer().frame(height: 14)

            // Botón Iniciar sesión — guinda con shimmer
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Theme.Colors.guindaColor)
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .white.opacity(0.18), location: 0.5),
                        .init(color: .clear, location: 1),
                    ],
                    startPoint: UnitPoint(x: shimmerOffset, y: 0),
                    endPoint: UnitPoint(x: shimmerOffset + 0.6, y: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .allowsHitTesting(false)
                Text("Iniciar sesión")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .onTapGesture {
                viewModel.router.showLoginScreen(sourceScreen: .startup)
            }
            .accessibilityIdentifier("llavemx_sign_in_button")

            Spacer().frame(height: 12)

            Divider()
                .background(Color(red: 0.91, green: 0.89, blue: 0.863))

            Spacer().frame(height: 10)

            Text("¿Aún no tienes una cuenta LlaveMX?")
                .font(.system(size: 12))
                .foregroundColor(Color(red: 0.604, green: 0.584, blue: 0.565))

            Spacer().frame(height: 5)

            Button {
                if let url = URL(string: "https://www.gob.mx/llavemx") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Crear cuenta")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.Colors.guindaColor)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.07), radius: 4, y: 2)
        )
    }

    // MARK: - Traditional Login Button

    private var traditionalLoginButton: some View {
        Button {
            viewModel.router.showLoginScreen(sourceScreen: .startup)
        } label: {
            HStack {
                Text("Iniciar sesión con correo y contraseña")
                    .font(.system(size: 13))
                    .foregroundColor(Color(red: 0.45, green: 0.42, blue: 0.37))
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 0.6, green: 0.58, blue: 0.55))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 1.0, green: 0.99, blue: 0.91))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color(red: 0.91, green: 0.85, blue: 0.48).opacity(0.5), lineWidth: 1)
                    )
            )
        }
        .accessibilityIdentifier("sign_in_button")
    }

    // MARK: - Institutional Footer

    private var institutionalFooter: some View {
        ThemeAssets.aprendeLogoEducacion.swiftUIImage
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: 32)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 24)
            .background(Theme.Colors.brandCreamStrong)
    }

    // MARK: - Decorative Circles

    private var decorativeCircles: some View {
        ZStack {
            Circle()
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 36)
                .frame(width: 220, height: 220)
                .offset(x: 120, y: -60)
            Circle()
                .strokeBorder(Color.white.opacity(0.05), lineWidth: 22)
                .frame(width: 130, height: 130)
                .offset(x: -140, y: 220)
            Circle()
                .strokeBorder(Color.white.opacity(0.07), lineWidth: 14)
                .frame(width: 80, height: 80)
                .offset(x: 150, y: 180)
        }
    }
}

#if DEBUG
struct StartupView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = StartupViewModel(
            router: AuthorizationRouterMock(),
            analytics: CoreAnalyticsMock(),
            config: ConfigMock()
        )

        StartupView(viewModel: vm)
            .preferredColorScheme(.light)
            .previewDisplayName("StartupView Light")
            .loadFonts()
    }
}
#endif
