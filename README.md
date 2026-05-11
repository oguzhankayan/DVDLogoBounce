# Corner — Retro Screensaver (Apple TV)

> *"The classic bouncing‑logo screensaver, scaled up for big modern TVs — with your name on the disc."*

**Corner** is an ambient tvOS app: the classic bouncing‑logo screensaver, rebuilt
for large‑screen TVs and designed to be left running for hours, for ambiance,
nostalgia, and the eternal hunt for the **perfect corner hit**.

This repository contains the full Swift / SwiftUI / SpriteKit implementation, the
tvOS navigation structure, the theme engine, the physics & corner‑hit detection
system, settings persistence, and the audio system.

---

## Highlights

- **Your word on the disc** — the bouncing badge shows whatever you type (your
  name, your channel, anything, up to 14 characters); it re‑tints to the active
  theme's palette on every wall bounce. Set it during the one‑screen onboarding or
  any time from Customize.
- **60 fps SpriteKit renderer** tuned for Apple TV: sub‑pixel motion interpolation,
  programmatic particles, optional CRT / VHS fragment shaders.
- **Exact corner‑hit detection** with a tunable "close‑call" window, a per‑corner
  counter, session streaks, and a statistics screen including *"time since the
  last perfect corner."*
- **6 hand‑tuned themes** — Classic, Neon, Synthwave, Minimal White, Retro CRT, and
  VHS — each restyling the logo colour, background, glow, particles and sound; two
  (Retro CRT, VHS) add a bespoke fragment‑shader post effect.
- **Display modes** — Single, Multi, Chaos.
- **Customization** — the logo text, speed, logo size, logo count, inter‑logo
  collisions, a custom background colour, the corner‑hit celebration (flash /
  particles / screen shake / close‑call effects), the on‑screen counter, auto‑hide,
  reduce motion, and a streamer mode.
- **Native tvOS feel** — focus‑engine‑friendly flat UI, auto‑hiding chrome, gentle
  fades, large‑readability typography, Siri Remote `Menu` / `Play‑Pause` / swipe
  controls. Disables the system idle timer while running so tvOS doesn't take over.

## Monetization

Paid up front. No subscription, no ads, no accounts, no tracking; statistics never
leave the device.

> **Before submitting to the App Store:** drop in an app icon / Top Shelf image
> (`Corner/Resources/Assets.xcassets`), optionally the sound files
> (`Corner/Resources/Sounds/`, the app is silent without them), and set
> `DEVELOPMENT_TEAM` in `project.yml`. The on‑screen mark is the app's own
> wordmark/badge — no trademarked logo ships in the app.

---

## Project layout

```
Corner/
  App/          App entry point, environment, routing, root view
  Engine/       SpriteKit scene, logo node, motion integrator, collisions,
                corner-hit detector, trails, particles, shaders, scene config
  Model/        Themes, theme catalog, app settings, statistics, value types
  Persistence/  UserDefaults-backed Codable stores for settings & statistics
  Audio/        Ambient bed + SFX controller
  Theming/      Theme engine + color palette helpers
  UI/           SwiftUI screens — screensaver host, overlays, menu, settings,
                theme gallery, statistics, onboarding, reusable components
  Support/      Small utilities (color hex, vector math, clamp, formatters)
  Resources/    Info.plist, Assets.xcassets, sound asset notes
CornerTests/    Unit tests for physics, corner detection, theme catalog
Docs/           ARCHITECTURE.md, APP_STORE.md, DESIGN.md, ROADMAP.md
project.yml     XcodeGen project definition (run `xcodegen generate`)
```

## Building

The Xcode project is generated from `project.yml` with
[XcodeGen](https://github.com/yonaskolb/XcodeGen) to keep the repo diff‑friendly:

```bash
brew install xcodegen
xcodegen generate
open Corner.xcodeproj
```

Then pick the **Corner** scheme and an **Apple TV** simulator (tvOS 17+) and run.

> Sound files and the App Icon / Top Shelf imagery are referenced but not committed
> as binaries — see `Corner/Resources/Sounds/README.md` and
> `Docs/DESIGN.md` for the asset specs a designer / sound designer should drop in.

## Documentation

- [`Docs/ARCHITECTURE.md`](Docs/ARCHITECTURE.md) — app architecture, navigation
  graph, SwiftUI hierarchy, SpriteKit scene architecture, physics & corner‑hit
  logic, theme engine, settings persistence, audio system.
- [`Docs/APP_STORE.md`](Docs/APP_STORE.md) — positioning, "minimum functionality"
  defence, ASO keywords, screenshot direction, app‑icon direction, launch
  animation concepts, premium onboarding, viral hooks, branding explorations.
- [`Docs/DESIGN.md`](Docs/DESIGN.md) — visual language, color, typography, motion,
  asset specifications.
- [`Docs/ROADMAP.md`](Docs/ROADMAP.md) — post‑launch ideas.
- [`Docs/PRIVACY.md`](Docs/PRIVACY.md) — the privacy policy (also at
  <https://oguzhankayan.github.io/DVDLogoBounce/privacy.html>); Corner collects no data.

## License

Proprietary — all rights reserved. (Placeholder; replace with your chosen license.)
