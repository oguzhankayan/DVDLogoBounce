# Design language — Corner

> Modern Apple aesthetic · subtle glassmorphism · dark luxury · retro‑futuristic ·
> soft gradients · bloom/glow · zero clutter · readable from the couch.

## Principles

1. **The bounce is the hero.** Chrome is small, frosted, and auto‑hides. Nothing
   ever competes with the logo on screen.
2. **Only the logo bounces.** UI fades and rises gently (0.3–0.55 s, ease‑in‑out);
   the *interface* never springs, jitters, or bounces.
3. **Dark, with one accent.** Backgrounds are deep and quiet; each theme contributes
   exactly one bright family (its collision palette). The accent is the only thing
   allowed to glow.
4. **Big and legible.** Type is large, rounded, high‑contrast; the HUD is readable
   from 3+ metres; nothing critical is below 22 pt.
5. **Intentional, not decorated.** Glassmorphism is used for *grouping* (cards), not
   as a texture; gradients are hand‑picked per theme, never the default purple‑blue.
6. **Calm by default, dramatic on purpose.** The default experience is meditative;
   the corner‑hit flash/shake is the one moment we allow ourselves to be loud — and
   even that is short, soft‑edged, and fully optional / suppressed in Streamer mode.

## Colour

- **Surfaces:** `.ultraThinMaterial` cards with a 1 px `white @ 8–12 %` hairline and
  a faint `accent @ 4–18 %` top‑leading wash (more when focused).
- **Text:** `primary` for values/titles, `secondary` for labels, `tertiary` for
  captions/hints. Always on dark.
- **Theme accents** are defined in `ThemeCatalog` as each theme's `collisionPalette`
  (e.g. Neon `#19E3FF / #FF2D95 / #39FF88 …`, Matrix shades of `#00FF41`, VHS muted
  `#5BBFB3 / #D98EA0 …`). The app's own brand accent (`AccentColor`) is a warm
  electric blue `#4C6BF2`.
- **Backgrounds** are per‑theme `BackgroundStyle`s: a solid or a hand‑tuned
  linear/radial gradient + a soft radial vignette (`0.1–0.5`) + optional grain
  (`0.02–0.12`). Custom mode replaces the base colour with a flat dark tone the user
  picks from a small, burn‑in‑safe preset row.

## Typography

- **System Rounded** everywhere (`design: .rounded`), heavy for titles/values,
  semibold for labels — friendly, modern, reads at distance.
- **Wordmark "CORNER":** heavy, generous tracking (6–12 pt depending on size).
- Inside the bouncing badge, the wordmark uses a heavy condensed face
  (`AvenirNextCondensed-Heavy`) so it fits the classic oval; the CRT/Matrix themes
  use `Menlo-Bold` for the right "terminal" flavour.
- Numbers are `monospacedDigit()` wherever they tick (HUD counter, "time since…",
  stat tiles, per‑corner bars).

## Motion

- **The logo:** constant speed, perfect reflections, instant colour change on
  bounce cross‑faded over ~0.22 s (snapped on a perfect corner — that one's allowed
  to be sudden). Optional ghost trail (`ghosts`/`ribbon`/`particles`) and a short
  directional motion‑blur smear.
- **The corner hit:** corner‑anchored colour bloom (≈0.6 s ease‑out) + a faint
  full‑screen lift + a particle burst + an expanding ring + a 0.3 s damped screen
  shake (`worldNode` only) — each component independently toggleable, all suppressed
  in Streamer mode (except the burst).
- **The chrome:** menus/onboarding cross‑fade with a slight rise; focus uses a
  spring lift (`response 0.3, damping 0.7`) to ~1.06–1.08× plus a soft accent
  shadow; presses dip to ~0.95–0.97×. The HUD fades in on any interaction and fades
  out after `autoHideDelay` (4–20 s).
- **Reduce Motion** (in‑app or system): ~0.7× speed, ~0.4–0.5× particles, no motion
  blur, no screen shake, gentler fades.

## Layout

- 16:9, designed at 1920×1080 (renders crisp at 4K). Safe content inset ≈ 90 pt
  horizontal / 70–90 pt vertical for menus; the *screensaver itself uses the full
  bleed* so the corners are the literal screen corners (that's the point).
- Menu home: wordmark + tagline, then a horizontal row of four 300×220 cards
  (Themes / Customize / Statistics / About), then a footer (Shuffle · Resume ·
  current mode/sound chips).
- Settings: a single vertical `ScrollView` of `SettingSection`s, each a header + a
  stack of `GlassCard` rows (slider / toggle / chip‑picker / colour‑swatch).
- Stats: an adaptive `LazyVGrid` of `StatTile`s + a 4‑column per‑corner bar block +
  a reset.

## Asset specifications a designer/sound designer should deliver

### App icon & Top Shelf (tvOS layered)

- `App Icon.imagestack` — 2–3 layers, each `400×240` @1x and `800×480` @2x
  (Front / Middle / Back). See "App icon direction" in `APP_STORE.md`.
- `App Icon - App Store.imagestack` — 2–3 layers at `1280×768` (`tv-marketing`),
  flattened‑friendly composition.
- `Top Shelf Image.imageset` — `1920×720` @1x, `3840×1440` @2x.
- `Top Shelf Image Wide.imageset` — `2320×720` @1x, `4640×1440` @2x.
- The `.brandassets` scaffold (with `Contents.json` for every layer/imageset) is
  already in `Corner/Resources/Assets.xcassets/App Icon & Top Shelf Image.brandassets/`;
  drop the PNGs in and Xcode will pick them up.

### Audio

See `Corner/Resources/Sounds/README.md` for the full list and per‑file character.
Summary: 11 SFX one‑shots (`bounce_soft/neon/crt/matrix`, `logo_collision`,
`corner_hit`, `corner_hit_crt`, `near_miss`, `ui_focus/select/back`) + 3 seamless
ambient loops (`ambient_vhs_hum`, `ambient_synth`, `ambient_room`). `.caf`
preferred for gapless looping; soft and tasteful throughout — this is an ambient
app, the corner chime is the loudest thing in it and it's still gentle.

### Screenshots / App Preview

See "Screenshots direction" in `APP_STORE.md` — six 1920×1080 captures + one
15–30 s App Preview, all real in‑app footage, scored with the synth‑pad bed.
