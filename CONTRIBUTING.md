# Contributing

Thanks for helping improve Corner. The project is small, so the contribution process is intentionally lightweight.

## Local Setup

1. Install Xcode with tvOS simulator support.
2. Install XcodeGen:

```bash
brew install xcodegen
```

3. Generate the project:

```bash
xcodegen generate
open Corner.xcodeproj
```

4. Run the **Corner** scheme on an Apple TV simulator running tvOS 17 or newer.

## Tests

Run the unit test target from Xcode, or from the command line after generating the project:

```bash
xcodebuild test -scheme Corner -destination 'platform=tvOS Simulator,name=Apple TV'
```

Use `xcrun simctl list devices available` if your simulator has a different name.

## Pull Requests

- Keep changes scoped to one clear fix or feature.
- Add or update tests when touching physics, collision, settings, persistence, or theme catalog behavior.
- Keep generated project files out of commits; `Corner.xcodeproj` is produced from `project.yml`.
- Prefer existing SwiftUI, SpriteKit, and model patterns over new abstractions.
- Include screenshots or a short screen recording for visible UI changes when practical.

## Assets and Rights

Do not commit signing certificates, provisioning profiles, private keys, paid fonts, unlicensed audio, trademarked logos, or copyrighted media.

Audio assets are optional. If you add sound files, make sure you have the right to publish them under a license compatible with this repository.

## Issues

Bug reports are most useful when they include:

- tvOS simulator or device version
- steps to reproduce
- expected behavior
- actual behavior
- relevant logs or screenshots
