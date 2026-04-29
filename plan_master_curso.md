# Plan Maestro — Refactor Módulo Curso (iOS SwiftUI)

**Proyecto:** Cursos @prende.mx (fork openedx-app-ios)
**Branch:** new-version-app
**Fecha:** 2026-04-28
**Stack:** SwiftUI + UIKit bridges (WKWebView, AVPlayer)
**Tokens marca:** brandCream, brandGreen, guindaColor, Noto Sans, surfaceWhite

---

## 1. Diagnóstico

Estado actual:
- `CourseContainerView` usa `TabView` paginado con 7 tabs (Home/Content/Progress/Dates/Offline/Discussions/More) — redundancia y mimetismo de UI web edX.
- Home muestra carousel + acceso a tabs siblings → duplicación informativa (Progress preview en Home + tab Progress full).
- Syllabus = `CourseVerticalView` con `DisclosureGroup` plano sin señal visual de `completion_stat` por chapter/sequential.
- Lectura `vertical` abre `CourseUnitView` como push modal con `WKWebView` + botón "Finish" estático. Sin nav peer-to-peer entre verticals (forzar back→tap siguiente).

**Problema raíz:** estructura mimetiza UI web edX. iOS necesita patrón hub + drilldown + reader inmersivo.

---

## 2. Datos del Backend

JSON del endpoint `/blocks` estructura jerárquica:

| Nivel | type | Rol UI |
|------|------|--------|
| 1 | `course` | Raíz (hub) |
| 2 | `chapter` | Unidad → BrandUnitCard |
| 3 | `sequential` | Capítulo → Row expandible dentro card |
| 4 | `vertical` | Pantalla consumo → Page en ContentReader |

Cada bloque: `display_name`, `children`, `completion_stat`, `block_type` (para verticals con renderer especializado: html/video/problem/discussion).

---

## 3. Course Hub — Consolidación

**Decisión:** colapsar 7 tabs → **3 tabs nativas** + acciones contextuales (sheets/drilldowns).

```
[Tab Bar inferior 3 items]
  📘 Curso       → Hub (Home + Content + Progress + Dates fusionados)
  💬 Foro        → Discussions
  ⋯ Más          → Offline + Handouts + Info
```

### 3.1 Tab "Curso" — Hub Layout (single ScrollView vertical)

```
┌─────────────────────────────────────┐
│ [HERO STICKY]                       │
│  Portada blur + ProgressRing 78%   │
│  "Continuar: 1.2 Objetivos"  [▶]   │
├─────────────────────────────────────┤
│ [STATS STRIP] horizontal scroll     │
│  78% · 12 días · 3 pendientes · 95 │
├─────────────────────────────────────┤
│ [PRÓXIMA FECHA]   ──→ tap = sheet  │
│  ⏰ Examen parcial · en 3 días      │
├─────────────────────────────────────┤
│ [TEMARIO]                           │
│  Unidad 1 ▸ ●●●○ 3/4               │
│  Unidad 2 ▸ ○○○○ 0/4               │
│  Unidad 3 ▸ ●●●● 4/4 ✓             │
├─────────────────────────────────────┤
│ [DESEMPEÑO]  ──→ tap = sheet detail │
│  Tareas ▰▰▰▰▰▱▱ 82%                │
├─────────────────────────────────────┤
│ [CONSTANCIA]  (estado dinámico)    │
└─────────────────────────────────────┘
```

**Cambios clave:**
- "Progress" deja de ser tab → vista detalle vía sheet desde stats strip o sección "Desempeño".
- "Dates" deja de ser tab → próxima fecha en hero strip; lista completa via sheet "Ver todas".
- "Content" deja de ser tab → temario inline en hub, scroll continuo.
- Pattern: **hub con drilldowns**, no tabs hermanos.

**Componentes nuevos Theme:**
- `CourseHubHero` (portada blur + ring + CTA continuar)
- `CourseStatsStrip` (chips horizontales tap→drilldown)
- `NextDeadlineRow` (tap → DatesSheet)
- Reuso `BrandHeroSummaryCard`, `BrandStatBar`

**Animación:** hero parallax sutil al scroll (respeta `reduceMotion`). Sticky CTA "Continuar" cuando hero scrollea fuera.

---

## 4. Syllabus / Temario Dinámico

JSON tree → 3 niveles UI:

```
chapter (Unidad)        → BrandUnitCard
  └─ sequential (Cap)   → Row dentro card, expandable
      └─ vertical       → Chip dentro row (preview tipo + duración)
```

### 4.1 BrandUnitCard (chapter)

```
┌─ UNIDAD 1 · Marco Legal ───────────┐
│ ████████░░░░░░░░  3/8 · 38%       │ ← BrandStatBar usando completion_stat
│                                     │
│  Cap I · Disposiciones      ✓ 4/4  │ ← sequential row
│  Cap II · Aplicación        ●○ 1/3 │
│  Cap III · Sanciones        ○○ 0/1 │ ← tap = expand verticals
│                                     │
│         [ Continuar unidad → ]     │
└─────────────────────────────────────┘
```

### 4.2 Reglas visuales `completion_stat`

| `completion` | Indicador | Color |
|---|---|---|
| `1.0` | ✓ check fill | brandGreen |
| `0 < x < 1` | ●○ dots o anillo % | guindaColor |
| `0` | ○ outline | textTertiary |

**Sequential expandido:** lista de verticals con icono por type (`video.fill`, `doc.text`, `pencil.and.list.clipboard`) + duration + estado.

**CTA "Continuar unidad":** smart resume — entra al primer vertical incompleto del chapter.

**Reuso:** `BrandUnitAccordion` (ya en backlog Theme).

---

## 5. Content Reader — Vista Inmersiva (vertical)

Reemplaza modal sheet con `WKWebView` + "Finish" pegado.

### 5.1 Arquitectura

```swift
ContentReaderView(verticals: [Vertical], startIndex: Int)
  ├─ TabView(selection: $currentIndex) .page(displayMode: .never)
  │   ForEach(verticals) { vertical in
  │       VerticalRenderer(vertical: vertical)
  │   }
  ├─ ReaderTopBar (close + título sequential + 3/8 progress)
  ├─ ReaderProgressRail (segmented bar, tick por vertical)
  └─ ReaderBottomBar (← anterior · marca completo · siguiente →)
```

**Comportamiento:**
- Swipe horizontal entre verticals dentro mismo sequential.
- Cruce de boundary sequential → animación distinta (slide + label "Cap II →") para conservar orientación.
- Finalizar último vertical del chapter → bottom sheet "Unidad completada" + CTA siguiente unidad.
- NO push nav entre verticals; el reader es container persistente.

### 5.2 VerticalRenderer (por block.type)

| `block.type` | Render iOS |
|---|---|
| `html` | `WKWebView` con CSS injection (Noto Sans + brandCream + max 65ch + dark swap) |
| `video` | `AVPlayerViewController` inline + transcript expandible |
| `problem` | Form nativo SwiftUI (radio/checkbox/text) — NO webview |
| `discussion` | Embed thread inline |
| `drag-and-drop` | Fallback webview con scrim "abre en pantalla completa" |

### 5.3 HTML CSS Injection

```css
body {
  font-family: 'Noto Sans';
  font-size: 17px;
  line-height: 1.6;
  color: #1A1A1A;
  background: #FAF6F0; /* brandCream */
  padding: 24px;
  max-width: 680px;
  margin: 0 auto;
  overflow-x: hidden;       /* defensive */
  word-wrap: break-word;
}
img, video, iframe { max-width: 100%; height: auto; border-radius: 12px; }
table {
  display: block;
  overflow-x: auto;
  -webkit-overflow-scrolling: touch;
}
pre { white-space: pre-wrap; word-break: break-word; }
@media (prefers-color-scheme: dark) { ... }
```

### 5.4 Top/Bottom Bars

```
┌─ ✕    Cap I · Disposiciones · 3/8   ⋯ ┐
│ ▰▰▰▱▱▱▱▱  ← progress segmented        │
├──────────────────────────────────────┤
│                                      │
│         [contenido vertical]         │
│                                      │
├──────────────────────────────────────┤
│  ←  Anterior   ✓ Marcar  Siguiente → │
└──────────────────────────────────────┘
```

- Top bar: blur `.regularMaterial`, autohide al scroll down (revelar al scroll up — patrón Safari).
- Progress rail: tick por vertical en sequential actual, color `brandGreen` completado, `guindaColor` actual, gris pendiente. Tap tick = jump.
- Bottom bar: 3 acciones. "Marcar completo" hace `PATCH completion` y avanza auto si toggle activado.
- Háptico `selection` al cambiar vertical, `success` al completar.

### 5.5 Navegación cross-sequential

Cuando swipe llega al final del último vertical de un sequential:
1. Carga next sequential's verticals en background.
2. Animación transición: slide horizontal + overlay breadcrumb 600ms "Cap I → Cap II".
3. Reader sigue abierto; TopBar actualiza título.

Si llega al final del último vertical del chapter → presenta sheet de celebración + CTA "Siguiente unidad" o "Volver al hub".

---

## 6. Gesture Conflict — WKWebView ↔ TabView paginado

**Problema:** scroll horizontal interno del WKWebView (tablas wide, `<pre>`, img overflow) compite con swipe page → swipe muere o page falla.

### 6.1 Mitigación 3 capas

**Capa A — CSS defensive injection** (ya en 5.3):
- `overflow-x: hidden` en body
- `display: block; overflow-x: auto` solo en `<table>` y `<pre>`
- Resultado: contenido cabe, scroll interno solo en bloques que lo necesitan.

**Capa B — WKWebView config runtime:**
```swift
webView.scrollView.alwaysBounceHorizontal = false
webView.scrollView.showsHorizontalScrollIndicator = false
webView.scrollView.contentInsetAdjustmentBehavior = .never

// Post-load check
webView.evaluateJavaScript("document.body.scrollWidth") { width, _ in
    if let w = width as? CGFloat, w <= webView.bounds.width + 4 {
        webView.scrollView.isScrollEnabled = true  // vertical only
        webView.scrollView.panGestureRecognizer.require(toFail: pageSwipeGR)
    }
}
```

**Capa C — Edge swipe zone (gesture coordination):**
```swift
TabView(selection: $idx) { ... }
  .tabViewStyle(.page(indexDisplayMode: .never))
  // bridge UIViewRepresentable para coordinar gestures:
  // - WKWebView pan horizontal cede a TabView paging cuando contentSize fits
  // - TabView paging cede a WebView cuando user toca tabla/pre wide
```

**Capa D — Fallback botones:** Bottom bar siempre tiene ←/→. Si gesture pelea, user usa botón. No bloqueante.

### 6.2 Detección runtime

Primer load mide `contentSize.width`. Si > `bounds.width + threshold` → log warning + activa modo "scroll bounded only on tables", page swipe sólo en zona edge 24pt.

---

## 7. Sistema Diseño — Tokens

**Mantener brand tokens pre-existentes:**
- Bg base: `brandCream`
- Surface: `surfaceWhite` con sombra suave (`radiusCard`)
- Acento: `brandGreen` (progreso) · `guindaColor` (headers/destacados)
- Tipografía: Noto Sans (regular/medium/semibold)
- Iconos: SF Symbols (no emoji estructural)
- Esquinas: 12pt cards, 6-8pt chips, 999pt capsules en tabs/CTAs

**Nuevos tokens necesarios:**
- `readerSurface` (bg neutro lectura, ligero off-white)
- `progressTrackInactive` (gris suave para rails)
- `boundaryDivider` (dim cross-sequential)

---

## 8. Fases de Ejecución

| Fase | Scope | Componentes nuevos | Build risk |
|---|---|---|---|
| F1 | Theme: `BrandUnitAccordion`, `CourseStatsStrip`, `ReaderProgressRail`, `ReaderTopBar`, `ReaderBottomBar` | 5 nuevos | ✅ BUILD VERDE |
| F2 | `CourseHubView` reemplaza `CourseContainerView` (3 tabs, drilldowns sheet) | hub + sheets Progress/Dates | medio (toca routing) |
| F3 | Syllabus dinámico con `completion_stat` real | usa F1 | bajo |
| F4 | `ContentReaderView` paginado (TabView page) + `VerticalRenderer` por type | nuevo flow | alto (reemplaza CourseUnitView) |
| F5 | HTML injection CSS + AVPlayer inline + problem nativo | renderers | medio |
| F5.1 | **Gesture conflict resolution** (capas A/B/C/D §6) | UIViewRepresentable bridge | alto |
| F6 | Cross-sequential prefetch + animación boundary + sheet celebración | polish | bajo |
| F7 | Smoke E2E + a11y (VoiceOver, Dynamic Type, reduceMotion) + dark mode | QA | — |

Build verde por commit. Cada fase preserva `CourseTab` enum legacy hasta F2 cutover. Rollback flag: `FeaturesConfig.useNewCourseHub: Bool`.

---

## 9. Riesgos + Mitigaciones

| Riesgo | Mitigación |
|---|---|
| `completion_stat` puede venir nulo en API legacy | Default 0, propagar opcional (regla decoding ya aplicada — feedback memory) |
| `WKWebView` performance en swipe TabView page | Cache 1 ahead/behind, dispose >2 distance |
| State preservation al cambiar vertical | `@StateObject` ReaderViewModel ownership en hub, `@ObservedObject` en renderers (regla SwiftUI patterns memory) |
| `.task(id: verticalID)` re-disparo agresivo en swipe | Debounce 200ms o `onChange(of:)` con guard |
| Gesture conflict WKWebView ↔ TabView paginado | §6 mitigación 4 capas (CSS + config + edge zone + botones fallback) |
| Routing legacy esperaba 7 tabs | `CourseTab` enum permanece; hub mapea sólo a `.course`, otros redirigen a sheets |

---

## 10. Métricas éxito

- **Tiempo a primer vertical:** actual ~6 taps. Target: 2 taps (open course → tap "Continuar" hero).
- **Engagement vertical→vertical:** actual = back+tap (2). Target = swipe (1).
- **Crash decoding `certificate_data`:** ya resuelto F0 (commit `ecba55d`).

---

## 11. Estado de Ejecución

| Fase | Estado | Commit |
|---|---|---|
| F1 — Theme components | ✅ completo | (próximo commit) |
| F2 — CourseHubView | ⏳ pendiente | — |
| F3 — Syllabus dinámico | ⏳ pendiente | — |
| F4 — ContentReaderView | ⏳ pendiente | — |
| F5 — Renderers | ⏳ pendiente | — |
| F5.1 — Gesture conflict | ⏳ pendiente | — |
| F6 — Cross-sequential polish | ⏳ pendiente | — |
| F7 — QA + a11y | ⏳ pendiente | — |

**Próxima acción:** confirmar inicio F1 (componentes Theme).

---

## 12. Referencias internas

- `feedback_swiftui_patterns.md` — reglas StateObject/ObservedObject, .task(id:), GeometryReader, decoding opcionales, módulo sweep
- `project_course_tabs_redesign.md` — rediseño previo de 7 tabs (deprecado por este plan que las consolida a 3)
- `registro_errores_ui.md` — ERR-002 (decoding), ERR-003 (StateObject), ERR-004 (DynamicOffsetView scroll)
- `CLAUDE.md` — arquitectura módulos + DI Swinject + Theme tokens
