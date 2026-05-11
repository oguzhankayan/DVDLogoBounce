# Architecture — Corner (tvOS)

A single‑module SwiftUI app (`Corner`) with a SpriteKit rendering core. Everything
runs on one screen at 60 fps; the chrome (menus, settings) is SwiftUI layered over
a `SpriteView`. No backend, no accounts, no analytics.

```
┌──────────────────────────────────────────────────────────────────────┐
│ CornerApp (@main)                                                      │
│   AppEnvironment  ── owns: AppSettings · StatisticsStore ·             │
│                            AudioController · ScreensaverViewModel ·    │
│                            Router       (all injected as EnvObjects)   │
│   └─ RootView (ZStack)                                                 │
│        ├─ ScreensaverView          ← always present, always running    │
│        │     SpriteView(BounceScene) + HUD + CornerFlash + banner      │
│        ├─ MenuOverlay              ← when router.isMenuPresented        │
│        │     MainMenuView · ThemeGalleryView · SettingsView ·          │
│        │     StatisticsView · AboutView                                │
│        └─ OnboardingView           ← first launch only                 │
└──────────────────────────────────────────────────────────────────────┘
        │ settings (Combine)                       ▲ SceneEvent
        ▼                                          │
┌──────────────────────────────────────────────────────────────────────┐
│ ScreensaverViewModel  (BounceSceneDelegate)                            │
│   - builds SceneConfig from AppSettings (+ Reduce Motion)              │
│   - scene.apply(config) on every settings change                      │
│   - routes SceneEvents → StatisticsStore + AudioController + flash     │
│   - owns the BounceScene instance for the app's lifetime              │
└──────────────────────────────────────────────────────────────────────┘
        │ SceneConfig                              ▲ SceneEvent (delegate)
        ▼                                          │
┌──────────────────────────────────────────────────────────────────────┐
│ BounceScene : SKScene                                                  │
│   worldNode ─ backgroundLayer · ambientLayer · trailLayer ·            │
│               logoLayer · burstLayer        (optionally inside a       │
│               PostEffectNode for CRT/VHS shader themes)                │
│   per frame: MotionIntegrator.step → CornerHitDetector.classify        │
│              CollisionResolver.resolve → recolor / particles / shake   │
│   helpers: LogoNode · TrailController · ParticleFactory ·              │
│            BackgroundTextures · SeededRandom                           │
└──────────────────────────────────────────────────────────────────────┘
```

## Module map

| Group         | What's in it |
|---------------|--------------|
| `App/`        | `CornerApp` (`@main`), `AppEnvironment` (DI), `Router` (nav state), `RootView` |
| `Model/`      | Pure value types — `RGBA`, `Theme` + sub‑specs, `ThemeID`, `ThemeCatalog`, `DisplayMode`, `ScreenCorner`, `AmbientMode`, `SoundEffectID`, `Statistics`, `CornerHitEvent`, `AppSettings` (+ `Snapshot`) |
| `Persistence/`| `UserDefaultsSettingsStore`, `StatisticsStore`, `JSONUserDefaultsStorage` |
| `Engine/`     | `BounceScene`, `LogoEntity` + `MotionIntegrator`, `CornerHitDetector`, `CollisionResolver`, `LogoNode`, `TrailController`, `ParticleFactory`, `PostEffectNode`, `BackgroundTextures`, `SeededRandom`, `SceneConfig` |
| `Audio/`      | `AudioController`, `SoundResource` |
| `Theming/`    | `ThemeBackground` (SwiftUI), `SceneConfigFactory` (settings → `SceneConfig`) |
| `UI/`         | `ScreensaverView` + `ScreensaverViewModel`, `Overlay/` (`HUDView`, `CornerFlashView`), `Menu/`, `Settings/`, `Themes/`, `Stats/`, `About/`, `Onboarding/`, `Components.swift` |
| `Support/`    | `RGBA+Bridging` (→ `Color`/`SKColor`), `Geometry` (vector maths), `Comparable+Clamp`, `Formatters` |

The whole `Model/` layer imports nothing UI‑related (only `Foundation`/`CoreGraphics`),
so it is trivially unit‑testable; `Engine/` only adds `SpriteKit`/`UIKit`.

## tvOS navigation

The structure is intentionally **flat** (no `NavigationStack`), because on tvOS
the back button (`onExitCommand`) is then 100 % predictable:

- **Screensaver** is the root. The Siri Remote:
  - **Menu** → `Router.handleExitCommand()` → opens the menu overlay.
  - **Play/Pause** → freezes/unfreezes the bounce.
  - **Any swipe** → momentarily reveals the auto‑hiding HUD.
- **Menu overlay** (`MenuOverlay`) switches between five pages
  (`home / themes / customize / statistics / about`) over a frosted, still‑running
  screensaver tinted with the active theme. **Menu** there: detail page → home;
  home → dismiss back to the screensaver.
- **Onboarding** (first launch) covers everything; **Menu** steps back a page,
  there's an explicit *Skip*, and *Start* completes it.

Focus: each screen sets a sensible initial `@FocusState`; `CardButtonStyle` /
`PrimaryButtonStyle` give the lift‑and‑glow focus feel without heavy platform chrome.

## SwiftUI view hierarchy (abridged)

```
RootView
├─ ScreensaverView
│  ├─ SpriteView(scene: vm.scene, isPaused:)        ← the engine
│  ├─ CornerFlashView(flash: vm.cornerFlash)        ← perfect-corner bloom
│  ├─ HUDView(visible:, lastEvent:)                  ← counter + "time since…"
│  ├─ CornerBannerView(banner: vm.transientBanner)  ← "PERFECT CORNER" / "so close…"
│  └─ pausedOverlay
├─ MenuOverlay
│  ├─ MainMenuView           (4 big cards + shuffle + resume)
│  ├─ ThemeGalleryView       (horizontal ThemeCardView gallery)
│  ├─ SettingsView           (SettingSection × {Mode, Motion, Look, Corner Hit, Audio, Experience})
│  ├─ StatisticsView         (StatTile grid + per-corner bars)
│  └─ AboutView
└─ OnboardingView            (one screen: "your name on the disc" field → theme swatches → "Start watching")
```

## State & data flow

- **`AppSettings`** (`@MainActor ObservableObject`) is the single source of truth
  for everything tunable. Every `@Published` property clamps to its range in
  `didSet` and debounces (350 ms) a JSON write of a `Snapshot` to `UserDefaults`.
  `applyMode(_:)` re‑seeds the relevant sliders for a display mode.
- **`ScreensaverView`** observes `settings.snapshot` (a `Hashable` value) with
  `.onChange` and calls `vm.refresh(reduceMotion:)`, which rebuilds the
  `SceneConfig` (via `SceneConfigFactory`, folding in Reduce Motion) and pushes it
  to the scene + reconfigures audio. So **changing any slider restyles the
  screensaver live**.
- **`BounceScene`** never holds a reference to `AppSettings`; it only ever sees an
  immutable `SceneConfig`. It reports `SceneEvent`s back through a weak
  `BounceSceneDelegate` (the view model), which fans them out to:
  - `StatisticsStore` — counts corners / close calls / wall bounces / run time
    (batched, with a throttled `UserDefaults` write; a perfect hit forces a sooner
    write).
  - `AudioController` — bounce / collision / close‑call / corner SFX (per theme).
  - The flash + banner state on the view model.

## SpriteKit scene architecture

`BounceScene` (`scaleMode = .resizeFill`, `anchorPoint = (0,0)` — playfield ==
the whole screen so the corners are the *real* screen corners) owns one
`worldNode` containing five layers (z‑ordered): `backgroundLayer`,
`ambientLayer`, `trailLayer`, `logoLayer`, `burstLayer`. For CRT/VHS themes the
`worldNode` is re‑parented inside a `PostEffectNode` (`SKEffectNode` + fragment
`SKShader`) which post‑processes the whole frame; for every other theme it's a
direct child of the scene (no render‑to‑texture cost). A perfect‑corner "screen
shake" is a short damped move action on `worldNode`.

`rebuildEverything()` (called on `apply(config:)` or `didChangeSize(_:)` once a
valid size is known) rebuilds the post‑effect, background textures, ambient field,
logos, and re‑configures the trail controller and corner detector. Logos are
created at the requested scale, then the scale is capped so a logo never exceeds
45 % of either screen dimension. Crisp logo geometry is rendered once to an
`SKTexture` (via `SKView.texture(from:)`) that the glow sprite *and* trail ghosts
reuse; until that capture succeeds, glow/trails are simply skipped (graceful).

### Frame loop (`update(_:)`)

1. Compute `dt` from `currentTime` (clamped to `1/240 … 1/20` s to survive pauses
   and spikes — at these speeds tunnelling is impossible without sub‑stepping, so
   none is needed).
2. For each logo: emit a trail sample at the *previous* position; optionally emit
   a motion‑blur ghost; `MotionIntegrator.step(&entity, dt:, bounds:)`;
   `CornerHitDetector.classify(impact)` → `none / wallBounce / closeCall(corner) /
   perfectCorner(corner)`; recolor (animated for bounces, snapped for a perfect
   hit), spawn the bounce burst / corner celebration / shake, and report the event.
3. If inter‑logo collisions are on: `CollisionResolver.resolve(&entities)` → recolor
   the pairs, spark a small burst at the midpoint, report.
4. Mirror entity positions onto the `LogoNode`s.
5. Accumulate run time and report it ~twice a second.

### Physics & corner‑hit logic

- A logo is a centre + a velocity vector whose **magnitude is held constant**
  (`referenceSpeed(forSceneSize:) × speedMultiplier`) — that's the "DVD never
  slows down" feel. `referenceSpeed = √(width·height) × 0.135` per second
  (≈ a few seconds to cross a 1080p screen at speed 1.0).
- `MotionIntegrator.step`: Euler‑integrate; if the x‑extent crosses a wall, reflect
  `dx`, snap the centre back inside (overshoot reflected, clamped to the playfield),
  bump `colorIndex`; same for y; renormalise the velocity to the pre‑step speed to
  kill floating‑point drift. The returned `WallImpact` records which wall(s) were
  hit and the post‑step gap from each extent to the nearest wall on the *other*
  axis.
- `CornerHitDetector.classify`:
  - both axes hit on the same step ⇒ **`perfectCorner`** (the corner is named from
    the two walls);
  - one axis hit and the other extent is within `closeCallTolerance` points of its
    wall ⇒ **`closeCall`** (named from the hit wall + nearest other wall);
  - otherwise ⇒ **`wallBounce`**.
  - The tolerance defaults to ~1.2 % of screen width (configurable via
    `SceneConfig.cornerCloseCallTolerance`, widened by the engine for very large
    displays). Close‑call detection can be switched off entirely.
- `CollisionResolver`: equal‑mass elastic circle collisions (radius = the logo's
  short half‑edge × 0.92). Overlaps are separated symmetrically; the normal
  velocity components are exchanged only when the pair is approaching; each logo is
  then renormalised to its pre‑collision speed.

### Trails, particles, post effects

- **`TrailController`** spawns fading "ghost" `SKSpriteNode`s (reusing the logo's
  captured texture) on a per‑logo budget that scales with `theme.trail.intensity ×
  user trail slider`. `kind` (`ghosts` / `ribbon` / `particles`) just tunes ghost
  size / emit rate / lifetime / budget. (A node pool is a noted future
  optimisation — see ROADMAP — but the live counts are comfortable for SpriteKit.)
- **`ParticleFactory`** builds `SKEmitterNode`s entirely in code (no `.sks` files):
  a quick bounce burst, a bigger corner celebration (burst + expanding ring), and a
  long‑lived ambient field (`fall` / `rise` / `drift` / `twinkle`) sized to the
  playfield. One soft‑white radial dot texture (Core Graphics) is shared by all of
  them and tinted per‑particle.
- **`PostEffectNode`** wraps the world in an `SKEffectNode` with a fragment shader:
  *CRT* — barrel distortion + scanlines + aperture mask + vignette + slight phosphor
  lift; *VHS* — wobble + a scrolling tracking line + chroma split + tape noise +
  warm desaturation + vignette. Resolution is passed via an `SKUniform`; `u_time`
  is SpriteKit's built‑in.

## Theme engine

A `Theme` is a pure value type bundling a `BackgroundStyle`, `LogoAppearance`,
`GlowSpec`, `TrailSpec`, `ParticleSpec`, a `PostEffect`, a `ThemeAudioSet`, and a
`collisionPalette` (the colours the logo cycles through on each bounce).
`ThemeCatalog` is the static library of the six built‑ins (Classic, Neon,
Synthwave, Minimal White, Retro CRT, VHS). The same `Theme` data drives three
renderers:

- **SpriteKit** — `BounceScene` translates `BackgroundStyle` → gradient/vignette/
  grain textures; `LogoAppearance` → vector geometry (`badge` / `wordmark` /
  `monogram` / `ring` / `pixelBlock`) in `LogoNode`; `GlowSpec` → a blurred,
  optionally additive texture sprite; `ParticleSpec`/`TrailSpec` → emitters/ghosts;
  `PostEffect` → the shader node.
- **SwiftUI chrome** — `ThemeBackground` renders the same `BackgroundStyle` behind
  menus; `ThemeSwatch` / `ThemeCardView` / `ThemePreview` mock a theme for the
  gallery and onboarding.
- **Audio** — `ThemeAudioSet` maps bounce/collision/corner/close‑call SFX ids and a
  suggested ambient bed; `AppSettings.effectiveAmbientMode(for:)` resolves the
  user's "Match Theme" choice against it.

Adding a theme = one entry in `ThemeID` (append only — raw values are persisted)
and one `Theme` literal in `ThemeCatalog`. Nothing else changes.

## Settings persistence

`AppSettings.Snapshot` is a flat `Codable` struct of every setting, with a
**tolerant `init(from:)`** (any key missing — e.g. a value added in a future build —
falls back to `Snapshot.defaults`). `UserDefaultsSettingsStore` reads/writes it as
JSON under `corner.settings.v1`; a corrupt payload is dropped so the app falls back
to defaults rather than getting stuck. `StatisticsStore` does the same under
`corner.statistics.v1` (with batched/throttled writes and a `checkpoint()` for
backgrounding). Previews/tests swap in `InMemorySettingsStore` /
`StatisticsStore(persisted: false)` so they touch no real defaults.

## Audio system

`AudioController` (`@MainActor`):

- **SFX** — a small round‑robin pool of `AVAudioPlayer`s per `SoundEffectID` so
  overlapping triggers (multi‑logo bounces) don't cut each other off; volume per
  category (bounce 0.85, corner 1.0, UI 0.4–0.6) × the user's effects volume.
- **Ambient bed** — one looping `AVAudioPlayer`, cross‑faded (≈0.9 s) when the bed
  changes; `pauseAmbient()` / `resumeAmbient()` on app background / Play‑Pause.
- **Session** — `AVAudioSession` category `.ambient` (never interrupts whatever the
  user is already playing); activated only when something is actually audible.
- **Graceful degradation** — every file lookup tries `.caf/.m4a/.aac/.wav/.mp3`
  (and a `Sounds/` subdirectory); a missing file just leaves that channel silent
  (logged once in debug). The app never crashes on missing audio. See
  `Resources/Sounds/README.md` for the file specs.

## Accessibility & performance notes

- Reduce Motion (in‑app toggle **or** the system setting) is blended once in
  `SceneConfigFactory`: ~0.7× speed, ~0.4–0.5× particle density, no motion blur, no
  screen shake.
- The HUD never takes focus; the screensaver keeps running behind the (frosted)
  menu so there's no jarring restart.
- The post‑effect (render‑to‑texture per frame) is only ever in the tree for the
  two themes that need it.
- Trails/particles/glow are all gated on the user's density/trail/glow sliders, so
  the app scales from "lush" to "barely there" (and "Minimal White" is essentially
  free).
