# Corner - Open Source Retro Screensaver for Apple TV

Corner is an open-source tvOS screensaver built with SwiftUI and SpriteKit. It recreates the classic bouncing-logo experience for Apple TV with editable badge text, hand-tuned themes, corner-hit detection, local statistics, and privacy-first settings.

This repository contains the full app source, unit tests, XcodeGen project definition, design notes, architecture docs, and asset specifications. The project is now maintained as an open-source codebase rather than a commercial App Store release.

## Status

- **Platform:** tvOS 17+
- **Language/UI:** Swift, SwiftUI, SpriteKit
- **Project generation:** XcodeGen
- **License:** MIT
- **Distribution:** source-first; build locally in Xcode or adapt for your own tvOS project
- **Privacy:** no accounts, no analytics, no network calls, no tracking

## Features

- **Editable bouncing badge** - set the word shown on the logo from onboarding or settings.
- **60 fps SpriteKit renderer** - tuned for Apple TV with smooth motion, optional effects, particles, trails, and multiple display modes.
- **Perfect corner detection** - counts exact corner hits, near misses, wall bounces, session streaks, and per-corner totals.
- **Six visual themes** - Classic, Neon, Synthwave, Minimal White, Retro CRT, and VHS.
- **Customization** - speed, logo size, logo count, collisions, background color, HUD, celebration effects, auto-hide controls, reduce motion, and streamer mode.
- **Local persistence** - settings and statistics are stored on device only.
- **Audio hooks** - sound effects and ambient beds are supported, with missing assets handled gracefully in development builds.

## Quick Start

Install Xcode and XcodeGen, then generate the project:

```bash
brew install xcodegen
xcodegen generate
open Corner.xcodeproj
```

Select the **Corner** scheme, choose an **Apple TV** simulator running tvOS 17 or newer, and run.

The generated `Corner.xcodeproj` is intentionally ignored. Regenerate it from `project.yml` when needed so source control stays small and reviewable.

## Tests

After generating the project, run the unit tests from Xcode or with `xcodebuild`:

```bash
xcodebuild test -scheme Corner -destination 'platform=tvOS Simulator,name=Apple TV'
```

If your local simulator name differs, replace the `name=` value with one from:

```bash
xcrun simctl list devices available
```

## Assets

The app icon and Top Shelf image scaffolding live in `Corner/Resources/Assets.xcassets`.

Audio files are intentionally not committed. `AudioController` references optional `.caf` files and fails silently when they are absent, so the app still runs during development. See [Corner/Resources/Sounds/README.md](Corner/Resources/Sounds/README.md) for the expected filenames and sound design specs.

## Project Layout

```text
Corner/
  App/          App entry point, environment, routing, root view
  Engine/       SpriteKit scene, motion, collisions, corner detection, effects
  Model/        Themes, settings, statistics, value types
  Persistence/  UserDefaults-backed Codable stores
  Audio/        Ambient bed and SFX controller
  Theming/      Theme engine and color palette helpers
  UI/           SwiftUI screens, overlays, menu, settings, stats, onboarding
  Support/      Geometry, color, formatting, SVG helpers
  Resources/    Info.plist, assets, sound asset notes
CornerTests/    Unit tests for physics, corner detection, theme catalog
Docs/           Architecture, design, privacy, roadmap, archived launch notes
project.yml     XcodeGen project definition
```

## Documentation

- [Architecture](Docs/ARCHITECTURE.md) - app structure, rendering engine, physics, themes, persistence, and audio.
- [Design](Docs/DESIGN.md) - visual language, motion, typography, color, and asset specs.
- [Roadmap](Docs/ROADMAP.md) - future engine, theme, accessibility, and community ideas.
- [Privacy](Docs/PRIVACY.md) - privacy policy for local builds.
- [Archived App Store notes](Docs/APP_STORE.md) - historical launch positioning retained for context.

## Contributing

Issues and pull requests are welcome. Start with [CONTRIBUTING.md](CONTRIBUTING.md) for setup, testing, and asset guidelines.

Please do not add trademarked logos, copyrighted media, signing credentials, provisioning profiles, or private API keys to the repository.

## License

MIT License. See [LICENSE](LICENSE).
