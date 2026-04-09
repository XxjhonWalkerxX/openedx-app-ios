# Discovery Screen — iOS/Android Parity Design

**Date:** 2026-04-09
**Branch:** theme-aprende
**Scope:** Replicar la pantalla Discovery de Android en iOS (NativeDiscovery)

---

## Objetivo

Reemplazar el layout plano actual de `DiscoveryView` en iOS por el diseño de Android:
hero verde con gradiente, bottom sheet cream, tarjetas horizontales con acento de color rotativo.

Este es el primer paso de un plan mayor de paridad visual Android → iOS en todas las pantallas.

---

## Archivos afectados

### Nuevos
| Archivo | Responsabilidad |
|---|---|
| `Discovery/Discovery/Presentation/NativeDiscovery/DiscoveryHeroView.swift` | Hero verde decorativo + botón settings |
| `Discovery/Discovery/Presentation/NativeDiscovery/DiscoveryCourseCard.swift` | Tarjeta horizontal de curso con acento de color |

### Modificados
| Archivo | Cambio |
|---|---|
| `Discovery/Discovery/Presentation/NativeDiscovery/DiscoveryView.swift` | Reemplaza layout plano por composición de nuevos componentes |

---

## Componente 1 — `DiscoveryHeroView`

Vista decorativa de altura fija **200pt**.

### Capas (de atrás hacia adelante)
1. **Gradiente de fondo** — `LinearGradient` diagonal:
   - Colores: `Theme.Colors.brandGreenDark → Theme.Colors.brandGreen → Theme.Colors.brandGreenLight`
   - `startPoint: .topLeading`, `endPoint: .bottomTrailing`
2. **Línea guinda** — `Rectangle` de 4pt de alto, `Theme.Colors.guindaColor`, al tope del hero
3. **Círculo decorativo grande** — 200pt, borde 32pt, blanco al 6% de opacidad
4. **Círculo decorativo pequeño** — 110pt, borde 20pt, blanco al 5% de opacidad
5. **Texto** — alineado al fondo izquierdo:
   - Título "Explorar": `Theme.Fonts.ttRoundsCompressedMedium(30)`, blanco, `letterSpacing: -0.3`
   - Subtítulo "Encuentra tu próximo aprendizaje": `Theme.Fonts.ttRoundsCompressedThinItalic(13)`, blanco 65%, `letterSpacing: 0.2`
6. **Botón settings** — esquina superior derecha, respeta `safeAreaInsets.top`:
   - Círculo 40pt, fondo `Color.white.opacity(0.14)`, borde `Color.white.opacity(0.22)` 1pt
   - Ícono SF Symbol: `person.crop.circle.badge.gear`, blanco, 20pt
   - Acción: llama al closure `onSettingsClick`

### Interfaz
```swift
struct DiscoveryHeroView: View {
    let onSettingsClick: () -> Void
}
```

---

## Componente 2 — `DiscoveryCourseCard`

Tarjeta blanca con `cornerRadius(16)` y sombra `radius: 4, y: 2, opacity: 0.1`.

### Paleta de acentos rotativos
```swift
private let accentColors: [Color] = [
    Theme.Colors.brandGreen,
    Color(red: 0.380, green: 0.071, blue: 0.196), // guinda #611232
    Theme.Colors.brandWarmDark,
    Theme.Colors.brandGreenDark,
]
```
El color se selecciona por `accentColors[index % accentColors.count]`.

### Estructura visual
```
┌──────────────────────────────────────────┐
│ ▬▬▬ línea acento 3pt (color por índice) │
├──────────┬───────────────────────────────┤
│          │ [Org name]  9pt gris          │
│  imagen  │                               │
│ 120×120  │ [Nombre del curso] 14pt negro │
│  .fill   │ máx 2 líneas                  │
│          │ ● Inscrito  (si enrolled)     │
└──────────┴───────────────────────────────┘
altura total del row: 120pt
```

### Tipografía y colores
| Elemento | Fuente | Tamaño | Color |
|---|---|---|---|
| Org | `ttRoundsBody(weight: 600)` | 9pt | `brandCardSecondary` (#9A9590) |
| Título | `ttRoundsCompressedMedium` | 14pt | `brandCardPrimary` (#1C1B18) |
| "Inscrito" | `ttRoundsBody(weight: 600)` | 9pt | `brandGreen` |
| Punto badge | Circle 5pt | — | `brandGreen` |

### Interfaz
```swift
struct DiscoveryCourseCard: View {
    let course: CourseItem   // modelo de dominio existente
    let index: Int           // para seleccionar color de acento
    let apiHostUrl: String
    let onClick: () -> Void
}
```

> **Nota:** `CourseItem` no tiene campo `isEnrolled`. Se usará `course.hasAccess` como proxy para mostrar el badge "Inscrito" (equivale a tener acceso al curso = estar inscrito).

---

## Componente 3 — `DiscoveryView` (modificado)

### Layout general
```
GeometryReader
└── ZStack
    ├── [A] DiscoveryHeroView (fijo, 200pt, no scrollea)
    ├── [B] ScrollView (.refreshable)
    │   └── LazyVStack(spacing: 0)
    │       ├── Spacer(172pt)          ← heroHeight(200) - overlap(28)
    │       ├── VStack (sheet cream, cornerRadius top: 32pt)
    │       │   ├── Drag handle (36×4pt, brandHandle, centrado, padding top 12)
    │       │   ├── Search bar (cápsula blanca, 46pt alto, padding H:20 top:16)
    │       │   │   └── ícono search verde 18pt + texto placeholder gris
    │       │   ├── Row header (padding H:20, top:20, bottom:12)
    │       │   │   ├── "Todos los cursos" ttRoundsCompressedMedium 20pt
    │       │   │   └── "N disponibles" ttRoundsBody 12pt gris
    │       │   └── ForEach courses → DiscoveryCourseCard (padding H:20, bottom:10)
    │       ├── ProgressBar si nextPage ≤ totalPages
    │       └── Spacer 80pt (fondo brandCream)
    ├── [C] LogistrationBottomView (si !userLoggedIn)
    ├── [D] OfflineSnackBarView
    └── [E] SnackBarView (si showError)
```

### Comportamiento
- `.navigationBarHidden(true)` — sin barra nativa
- El hero queda visualmente fijo; el sheet cream sube sobre él al hacer scroll
- El botón settings está dentro de `DiscoveryHeroView` como overlay con `ZStack`, alineado `.topTrailing`
- Pull-to-refresh: llama `viewModel.discovery(page: 1, withProgress: false)` tras reset de páginas
- Paginación: `onAppear` de cada `DiscoveryCourseCard` llama `viewModel.getDiscoveryCourses(index:)`

### Colores de fondo
- Área del hero: transparente (deja ver el gradiente)
- Sheet y fondo scroll: `Theme.Colors.brandCream`

---

## Fuera de alcance (este sprint)

- Reemplazar `CourseCellView` en otras pantallas (Dashboard, Search)
- Dark mode adaptation
- Soporte landscape / iPad
- Animaciones de transición del sheet

---

## Dependencias

- `Theme.Colors.brandGreen`, `brandGreenDark`, `brandGreenLight`, `brandCream`, `brandWarmDark`, `guindaColor`, `brandHandle`, `brandCardPrimary`, `brandCardSecondary` — **ya existen** en `Theme.swift`
- `Theme.Fonts.ttRoundsCompressedMedium`, `ttRoundsCompressedThinItalic`, `ttRoundsBody` — **ya existen** en `TTRoundsFonts.swift`
- `AsyncImage` / `CachedAsyncImage` — usar el mismo que usa `CourseCellView` actualmente
