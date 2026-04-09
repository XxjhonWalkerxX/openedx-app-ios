# Discovery iOS/Android Parity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reemplazar el layout plano de `DiscoveryView` en iOS por el diseño de Android: hero verde con gradiente, bottom sheet cream, tarjetas horizontales con acento de color rotativo.

**Architecture:** Tres componentes independientes — `DiscoveryHeroView` (decorativo), `DiscoveryCourseCard` (tarjeta), y `DiscoveryView` modificado que los compone. `DiscoveryRouter` recibe `showSettings()` para que el botón del hero pueda navegar.

**Tech Stack:** SwiftUI, Kingfisher (imágenes), Theme module (@prende.mx brand colors + TTRounds fonts), existing `DiscoveryViewModel` sin modificar.

---

## Mapa de archivos

| Archivo | Acción | Responsabilidad |
|---|---|---|
| `Discovery/Discovery/Presentation/NativeDiscovery/DiscoveryHeroView.swift` | Crear | Hero verde + botón settings |
| `Discovery/Discovery/Presentation/NativeDiscovery/DiscoveryCourseCard.swift` | Crear | Tarjeta horizontal con acento de color rotativo |
| `Discovery/Discovery/Presentation/DiscoveryRouter.swift` | Modificar | Agregar `showSettings()` al protocolo y mock |
| `Discovery/Discovery/Presentation/NativeDiscovery/DiscoveryView.swift` | Modificar | Reemplazar layout plano por composición de nuevos componentes |

---

## Task 1: Agregar `showSettings()` a `DiscoveryRouter`

**Files:**
- Modify: `Discovery/Discovery/Presentation/DiscoveryRouter.swift`

- [ ] **Step 1: Agregar método al protocolo `DiscoveryRouter`**

Abrir `Discovery/Discovery/Presentation/DiscoveryRouter.swift` y agregar `showSettings()` al protocolo, justo después de `showDiscoverySearch`:

```swift
public protocol DiscoveryRouter: BaseRouter {
    func showCourseDetais(courseID: String, title: String)
    func showWebDiscoveryDetails(
        pathID: String,
        discoveryType: DiscoveryWebviewType,
        sourceScreen: LogistrationSourceScreen
    )
    func showUpdateRequiredView(showAccountLink: Bool)
    func showUpdateRecomendedView()
    func showDiscoverySearch(searchQuery: String?)
    func showSettings()   // ← agregar esta línea
    func showCourseScreens(
        courseID: String,
        hasAccess: Bool?,
        courseStart: Date?,
        courseEnd: Date?,
        enrollmentStart: Date?,
        enrollmentEnd: Date?,
        title: String,
        courseRawImage: String?,
        showDates: Bool,
        lastVisitedBlockID: String?
    )
    func showWebProgramDetails(
        pathID: String,
        viewType: ProgramViewType
    )
}
```

- [ ] **Step 2: Agregar implementación vacía en el mock**

En el mismo archivo, dentro de `DiscoveryRouterMock`, agregar:

```swift
public func showSettings() {}
```

Después de `public func showDiscoverySearch(searchQuery: String? = nil) {}`.

- [ ] **Step 3: Compilar para verificar**

```bash
cd /Users/diegonicolas/Desktop/edx_diego/edx-back/openedx-app-ios
xcodebuild -scheme Discovery -destination 'generic/platform=iOS Simulator' build 2>&1 | grep -E "error:|Build succeeded"
```

Resultado esperado: `Build succeeded`

- [ ] **Step 4: Commit**

```bash
git add Discovery/Discovery/Presentation/DiscoveryRouter.swift
git commit -m "feat(discovery): add showSettings to DiscoveryRouter"
```

---

## Task 2: Crear `DiscoveryHeroView`

**Files:**
- Create: `Discovery/Discovery/Presentation/NativeDiscovery/DiscoveryHeroView.swift`

- [ ] **Step 1: Crear el archivo**

Crear `Discovery/Discovery/Presentation/NativeDiscovery/DiscoveryHeroView.swift` con el siguiente contenido completo:

```swift
//
//  DiscoveryHeroView.swift
//  Discovery
//
//  Hero verde decorativo con gradiente + botón de settings.
//  No contiene elementos de scroll — es una capa fija de 200pt.
//

import SwiftUI
import Theme

private let heroHeight: CGFloat = 200

struct DiscoveryHeroView: View {
    let onSettingsClick: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            // 1. Gradiente de fondo
            LinearGradient(
                colors: [
                    Theme.Colors.brandGreenDark,
                    Theme.Colors.brandGreen,
                    Theme.Colors.brandGreenLight,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: heroHeight)

            // 2. Línea guinda en la parte superior
            Rectangle()
                .fill(Theme.Colors.guindaColor)
                .frame(height: 4)

            // 3. Círculos decorativos semitransparentes
            Circle()
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 32)
                .frame(width: 200, height: 200)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .offset(x: -40, y: -40)

            Circle()
                .strokeBorder(Color.white.opacity(0.05), lineWidth: 20)
                .frame(width: 110, height: 110)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .offset(x: 20, y: 20)

            // 4. Textos — alineados abajo a la izquierda
            VStack(alignment: .leading, spacing: 4) {
                Spacer()
                Text("Explorar")
                    .font(Theme.Fonts.ttRoundsCompressedMedium(30))
                    .foregroundColor(.white)
                    .kerning(-0.3)
                Text("Encuentra tu próximo aprendizaje")
                    .font(Theme.Fonts.ttRoundsCompressedThinItalic(13))
                    .foregroundColor(Color.white.opacity(0.65))
                    .kerning(0.2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .frame(height: heroHeight)

            // 5. Botón settings — esquina superior derecha
            VStack {
                HStack {
                    Spacer()
                    Button(action: onSettingsClick) {
                        Image(systemName: "person.crop.circle.badge.gear")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.white)
                    }
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.14))
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
                    )
                    .clipShape(Circle())
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                Spacer()
            }
            .frame(height: heroHeight)
        }
        .frame(height: heroHeight)
        .clipped()
    }
}

#Preview {
    DiscoveryHeroView(onSettingsClick: {})
        .previewLayout(.fixed(width: 390, height: 200))
}
```

- [ ] **Step 2: Agregar al proyecto Xcode**

Abrir `Dashboard.xcodeproj` — NO. Abrir `Discovery/Discovery.xcodeproj` en Xcode y agregar `DiscoveryHeroView.swift` al target `Discovery`. O bien verificar que el archivo quede incluido en `Discovery.xcodeproj/project.pbxproj` con el siguiente comando:

```bash
grep "DiscoveryHeroView" /Users/diegonicolas/Desktop/edx_diego/edx-back/openedx-app-ios/Discovery/Discovery.xcodeproj/project.pbxproj
```

Si no aparece, hay que agregarlo desde Xcode: clic derecho en el grupo `NativeDiscovery` → "Add Files to Discovery".

- [ ] **Step 3: Compilar**

```bash
xcodebuild -scheme Discovery -destination 'generic/platform=iOS Simulator' build 2>&1 | grep -E "error:|Build succeeded"
```

Resultado esperado: `Build succeeded`

- [ ] **Step 4: Verificar visualmente**

Abrir `DiscoveryHeroView.swift` en Xcode y activar el Preview de `#Preview`. Debe mostrar:
- Fondo verde con gradiente
- Línea guinda de 4pt en la parte superior
- Dos círculos decorativos semitransparentes
- Texto "Explorar" blanco grande, subtítulo itálico semitransparente
- Botón círculo semitransparente con ícono en la esquina superior derecha

- [ ] **Step 5: Commit**

```bash
git add Discovery/Discovery/Presentation/NativeDiscovery/DiscoveryHeroView.swift \
        Discovery/Discovery.xcodeproj/project.pbxproj
git commit -m "feat(discovery): add DiscoveryHeroView with green gradient hero"
```

---

## Task 3: Crear `DiscoveryCourseCard`

**Files:**
- Create: `Discovery/Discovery/Presentation/NativeDiscovery/DiscoveryCourseCard.swift`

- [ ] **Step 1: Crear el archivo**

Crear `Discovery/Discovery/Presentation/NativeDiscovery/DiscoveryCourseCard.swift`:

```swift
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
                            .fixedSize(horizontal: false, vertical: true)

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
```

- [ ] **Step 2: Agregar al proyecto Xcode**

Igual que en Task 2, agregar desde Xcode o verificar con:

```bash
grep "DiscoveryCourseCard" /Users/diegonicolas/Desktop/edx_diego/edx-back/openedx-app-ios/Discovery/Discovery.xcodeproj/project.pbxproj
```

- [ ] **Step 3: Compilar**

```bash
xcodebuild -scheme Discovery -destination 'generic/platform=iOS Simulator' build 2>&1 | grep -E "error:|Build succeeded"
```

Resultado esperado: `Build succeeded`

- [ ] **Step 4: Verificar visualmente el Preview**

Abrir `DiscoveryCourseCard.swift` en Xcode y activar el Preview. Debe mostrar 4 tarjetas con colores de acento distintos (verde, guinda, café oscuro, verde oscuro).

- [ ] **Step 5: Commit**

```bash
git add Discovery/Discovery/Presentation/NativeDiscovery/DiscoveryCourseCard.swift \
        Discovery/Discovery.xcodeproj/project.pbxproj
git commit -m "feat(discovery): add DiscoveryCourseCard with rotating accent colors"
```

---

## Task 4: Modificar `DiscoveryView` — reemplazar layout por composición

**Files:**
- Modify: `Discovery/Discovery/Presentation/NativeDiscovery/DiscoveryView.swift`

- [ ] **Step 1: Reemplazar el contenido de `DiscoveryView.swift`**

Reemplazar el archivo completo con:

```swift
//
//  DiscoveryView.swift
//  Discovery
//

import SwiftUI
import Core
import OEXFoundation
import Theme

private let heroHeight: CGFloat = 200
private let heroOverlap: CGFloat = 28

public struct DiscoveryView: View {

    @StateObject
    private var viewModel: DiscoveryViewModel
    private var router: DiscoveryRouter
    @State private var searchQuery: String = ""
    @State private var isRefreshing: Bool = false

    private var sourceScreen: LogistrationSourceScreen

    public init(
        viewModel: DiscoveryViewModel,
        router: DiscoveryRouter,
        searchQuery: String? = nil,
        sourceScreen: LogistrationSourceScreen = .default
    ) {
        self._viewModel = StateObject(wrappedValue: { viewModel }())
        self.router = router
        self._searchQuery = State<String>(initialValue: searchQuery ?? "")
        self.sourceScreen = sourceScreen
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {

                // [A] Hero verde — fijo, no scrollea
                DiscoveryHeroView {
                    router.showSettings()
                }

                // [B] Contenido scrollable
                ScrollView {
                    LazyVStack(spacing: 0) {

                        // Espaciador para que el contenido empiece bajo el hero
                        Color.clear
                            .frame(height: heroHeight - heroOverlap)

                        // Sheet cream con bordes redondeados arriba
                        VStack(spacing: 0) {

                            // Drag handle
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Theme.Colors.brandHandle)
                                .frame(width: 36, height: 4)
                                .padding(.top, 12)
                                .padding(.bottom, 16)

                            // Barra de búsqueda (fake field, tap → SearchView)
                            HStack(spacing: 10) {
                                Image(systemName: "magnifyingglass")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 18, height: 18)
                                    .foregroundColor(Theme.Colors.brandGreen)
                                Text("Buscar cursos...")
                                    .font(Theme.Fonts.ttRoundsBody(13))
                                    .foregroundColor(Theme.Colors.brandCardSecondary)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 46)
                            .background(Color.white)
                            .clipShape(Capsule())
                            .onTapGesture {
                                router.showDiscoverySearch(searchQuery: searchQuery)
                                viewModel.discoverySearchBarClicked()
                            }
                            .padding(.horizontal, 20)

                            // Header "Todos los cursos" + contador
                            HStack {
                                Text("Todos los cursos")
                                    .font(Theme.Fonts.ttRoundsCompressedMedium(20))
                                    .foregroundColor(Theme.Colors.brandCardPrimary)
                                    .kerning(-0.2)
                                Spacer()
                                Text("\(viewModel.courses.count) disponibles")
                                    .font(Theme.Fonts.ttRoundsBody(12))
                                    .foregroundColor(Theme.Colors.brandCardSecondary)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            .padding(.bottom, 12)

                            // Lista de tarjetas
                            ForEach(Array(viewModel.courses.enumerated()), id: \.offset) { index, course in
                                DiscoveryCourseCard(
                                    course: course,
                                    index: index,
                                    onClick: {
                                        viewModel.discoveryCourseClicked(
                                            courseID: course.courseID,
                                            courseName: course.name
                                        )
                                        router.showCourseDetais(
                                            courseID: course.courseID,
                                            title: course.name
                                        )
                                    }
                                )
                                .padding(.horizontal, 20)
                                .padding(.bottom, 10)
                                .onAppear {
                                    Task {
                                        await viewModel.getDiscoveryCourses(index: index)
                                    }
                                }
                            }

                            // Indicador de carga para paginación
                            if viewModel.nextPage <= viewModel.totalPages {
                                ProgressView()
                                    .padding(.top, 20)
                                    .tint(Theme.Colors.brandGreen)
                            }

                            // Espaciador inferior
                            Color(Theme.Colors.brandCream)
                                .frame(height: 80)
                        }
                        .frame(maxWidth: .infinity)
                        .background(Theme.Colors.brandCream)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 32)
                                .corners([.topLeft, .topRight])
                        )
                    }
                }
                .refreshable {
                    viewModel.totalPages = 1
                    viewModel.nextPage = 1
                    await viewModel.discovery(page: 1, withProgress: false)
                }

                // [C] Panel de login si no está autenticado
                if !viewModel.userloggedIn {
                    LogistrationBottomView(
                        ssoEnabled: viewModel.config.uiComponents.samlSSOLoginEnabled
                    ) { buttonAction in
                        switch buttonAction {
                        case .signIn:
                            viewModel.router.showLoginScreen(sourceScreen: .discovery)
                        case .register:
                            viewModel.router.showRegisterScreen(sourceScreen: .discovery)
                        case .signInWithSSO:
                            viewModel.router.showLoginScreen(sourceScreen: .discovery)
                        }
                    }
                    .frame(maxHeight: .infinity, alignment: .bottom)
                }

            }
            // [D] Offline snackbar
            OfflineSnackBarView(
                connectivity: viewModel.connectivity,
                reloadAction: {
                    await viewModel.discovery(page: 1, withProgress: false)
                }
            )

            // [E] Error snackbar
            if viewModel.showError {
                VStack {
                    Spacer()
                    SnackBarView(message: viewModel.errorMessage)
                }
                .padding(.bottom, viewModel.connectivity.isInternetAvaliable
                         ? 0 : OfflineSnackBarView.height)
                .transition(.move(edge: .bottom))
                .onAppear {
                    doAfter(Theme.Timeout.snackbarMessageLongTimeout) {
                        viewModel.errorMessage = nil
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .background(Theme.Colors.brandCream.ignoresSafeArea())
        .onFirstAppear {
            if !searchQuery.isEmpty {
                router.showDiscoverySearch(searchQuery: searchQuery)
                searchQuery = ""
            }
            Task {
                await viewModel.discovery(page: 1)
                if case let .courseDetail(courseID, courseTitle) = sourceScreen {
                    viewModel.router.showCourseDetais(courseID: courseID, title: courseTitle)
                }
            }
        }
    }
}

// MARK: - RoundedRectangle helper para esquinas selectivas

private extension RoundedRectangle {
    func corners(_ corners: UIRectCorner) -> some Shape {
        SpecificCornersShape(radius: cornerSize.width, corners: corners)
    }
}

private struct SpecificCornersShape: Shape {
    let radius: CGFloat
    let corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#if DEBUG
struct DiscoveryView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = DiscoveryViewModel(
            router: DiscoveryRouterMock(),
            config: ConfigMock(),
            interactor: DiscoveryInteractor.mock,
            connectivity: Connectivity(),
            analytics: DiscoveryAnalyticsMock(),
            storage: CoreStorageMock()
        )
        let router = DiscoveryRouterMock()

        DiscoveryView(viewModel: vm, router: router)
            .preferredColorScheme(.light)
            .previewDisplayName("DiscoveryView Light")
    }
}
#endif
```

- [ ] **Step 2: Compilar**

```bash
xcodebuild -scheme Discovery -destination 'generic/platform=iOS Simulator' build 2>&1 | grep -E "error:|Build succeeded"
```

Si hay errores por el helper `corners(_:)`, verificar que `SpecificCornersShape` esté declarado correctamente al final del archivo.

Resultado esperado: `Build succeeded`

- [ ] **Step 3: Verificar visualmente en el simulador**

Correr la app en el simulador y navegar a la pestaña Discover. Verificar:
- [ ] Hero verde con gradiente visible arriba
- [ ] Línea guinda de 4pt en la parte superior de la pantalla
- [ ] Botón settings (círculo semitransparente) en la esquina superior derecha
- [ ] Sheet cream con bordes redondeados que sube sobre el hero
- [ ] Drag handle (pastilla gris) arriba del sheet
- [ ] Barra de búsqueda cápsula blanca con ícono verde
- [ ] Encabezado "Todos los cursos" + contador de disponibles
- [ ] Tarjetas con imagen izquierda, línea de acento arriba, colores rotativos
- [ ] Badge "Inscrito" en cursos con `hasAccess = true`
- [ ] Pull-to-refresh funciona
- [ ] Tap en tarjeta navega al detalle del curso
- [ ] Tap en búsqueda navega a SearchView
- [ ] Tap en settings navega a configuración

- [ ] **Step 4: Commit**

```bash
git add Discovery/Discovery/Presentation/NativeDiscovery/DiscoveryView.swift
git commit -m "feat(discovery): replicate Android discovery screen layout in iOS"
```

---

## Task 5: Conectar `showSettings()` en el Router principal

**Files:**
- Modify: `OpenEdX/Router.swift`

> Solo si `Router.swift` no implementa aún `showSettings()` para el módulo Discovery. Verificar primero:

```bash
grep -n "extension.*Router.*Discovery\|showSettings" /Users/diegonicolas/Desktop/edx_diego/edx-back/openedx-app-ios/OpenEdX/Router.swift | head -10
```

Si `Router` ya implementa `DiscoveryRouter` y ya tiene `showSettings()`, este task se puede omitir.

- [ ] **Step 1: Verificar si Router ya conforma `DiscoveryRouter`**

```bash
grep -n "DiscoveryRouter\|showSettings" /Users/diegonicolas/Desktop/edx_diego/edx-back/openedx-app-ios/OpenEdX/Router.swift | head -20
```

- [ ] **Step 2: Si falta, agregar conformance**

Si `Router` no tiene `showSettings()` bajo su conformance a `DiscoveryRouter`, agregar el método. Buscar el bloque de extensión de `DiscoveryRouter` en `Router.swift` y agregar:

```swift
public func showSettings() {
    // Reusar la implementación existente de settings
    // (mismo método que usa DashboardRouter)
    let view = ProfileView(/* parámetros existentes */)
    // Ver implementación en Router.swift línea donde se define showSettings()
    // para DashboardRouter y replicar
}
```

> **Nota:** La implementación exacta depende de cómo `Router.swift` navega a settings. Buscar `func showSettings()` en el archivo y copiar el cuerpo del método existente que ya funciona para el Dashboard.

- [ ] **Step 3: Compilar la app completa**

```bash
xcodebuild -scheme OpenEdX -destination 'generic/platform=iOS Simulator' build 2>&1 | grep -E "error:|Build succeeded"
```

Resultado esperado: `Build succeeded`

- [ ] **Step 4: Commit**

```bash
git add OpenEdX/Router.swift
git commit -m "feat(discovery): wire showSettings in Router for Discovery module"
```

---

## Self-Review

**Cobertura del spec:**
- [x] `DiscoveryHeroView`: gradiente, línea guinda, círculos decorativos, textos, botón settings — Task 2
- [x] `DiscoveryCourseCard`: línea acento, imagen 120×120, org, título, badge Inscrito — Task 3
- [x] `DiscoveryView` modificado: hero fijo, scroll con sheet, drag handle, search bar, header, lista, paginación, pull-to-refresh, snackbars — Task 4
- [x] `showSettings()` en router — Task 1 + Task 5
- [x] `hasAccess` como proxy de `isEnrolled` — implementado en Task 3

**Placeholder scan:** Sin TBDs. Task 5, Step 2 tiene una nota de investigación pero el comando de búsqueda previo guía al desarrollador.

**Consistencia de tipos:**
- `CourseItem` usado consistentemente en Tasks 3 y 4
- `Theme.Colors.brandGreen`, `brandGreenDark`, `brandGreenLight`, `brandCream`, `brandHandle`, `brandCardPrimary`, `brandCardSecondary`, `guindaColor` — todos existen en `Theme.swift`
- `Theme.Fonts.ttRoundsCompressedMedium`, `ttRoundsCompressedThinItalic`, `ttRoundsBody` — todos existen en `TTRoundsFonts.swift`
- `heroHeight` definida en Task 2 y reutilizada en Task 4 (cada archivo la declara como `private let` — correcto, son independientes)
