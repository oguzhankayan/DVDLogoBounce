# Corner — A Premium Retro Bouncing Screensaver for Apple TV

> *"A premium retro bouncing screensaver experience for Apple TV."*

**Corner** is a polished, ambient tvOS app inspired by the classic bouncing DVD‑logo
screensaver. It is built for modern large‑screen TVs and designed to be left running
for hours — for ambiance, nostalgia, relaxation, and the eternal hunt for the
**perfect corner hit**.

This repository contains the full Swift / SwiftUI / SpriteKit implementation, the
tvOS navigation structure, the theme engine, the physics & corner‑hit detection
system, settings persistence, the audio system, and the App Store positioning /
ASO / design documentation.

---

## Highlights

- **60 fps SpriteKit renderer** tuned for Apple TV — sub‑pixel motion interpolation,
  pooled trail ghosts, programmatic particles, optional CRT / VHS fragment shaders.
- **Exact corner‑hit detection** with a tunable "close‑call" window, a per‑corner
  counter, session streaks, and a full statistics screen including
  *"time since last perfect corner."*
- **8 hand‑tuned themes** — Classic DVD, Neon, Synthwave, Minimal White, Retro CRT,
  Glassmorphism, Matrix, VHS — each restyling the logo, glow, background, particles,
  trails, and sound.
- **Ambient audio system** — silent / soft collision SFX / VHS hum / synth pad,
  with independent SFX and ambience volume.
- **Deep customization** — speed, logo size, logo count, trail intensity, glow,
  motion blur, background tint, screensaver density, inter‑logo collisions.
- **Display modes** — Single, Multi, Chaos, and a slow Cinematic mode.
- **Native tvOS feel** — focus‑engine‑friendly UI, auto‑hiding chrome, cinematic
  fades, large‑readability typography, Siri Remote `Menu`/swipe controls.
- **Premium design language** — dark luxury, subtle glassmorphism, soft gradients,
  bloom, intentional typography.

## Monetization

Paid up front (target **$0.99 – $2.99**). No subscription, no ads, no accounts,
no tracking.

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

## License

Proprietary — all rights reserved. (Placeholder; replace with your chosen license.)
