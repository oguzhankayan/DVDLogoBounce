# Roadmap — Corner

Ordered roughly by value‑per‑effort. Nothing here is required for 1.0.

## Engine / rendering polish

- **Trail‑ghost node pool.** `TrailController` currently creates/removes
  `SKSpriteNode`s on emit; a fixed per‑logo ring buffer would shave allocation
  churn at high density (negligible at default settings, noticeable in Chaos mode
  on the oldest Apple TV HD).
- **Real Matrix code‑rain.** Replace the `.fall` ambient particle field with a
  proper column‑based glyph rain node (pooled `SKLabelNode`s, fading heads) for the
  Matrix theme. Hook: `ParticleSpec.AmbientField.motion == .fall`.
- **Synthwave horizon grid.** A perspective grid line decoration in the Synthwave
  background (scrolling toward the horizon), behind the bouncing logo. Probably a
  small `SKShader` on a full‑width strip, or a generated texture scrolled.
- **Sub‑pixel‑perfect corner detection mode.** Optionally compute the exact time of
  impact within a frame (TOI) and snap to it, so a "perfect corner" is mathematically
  exact rather than "both axes within one frame" — purists will love it; gate behind
  a setting.
- **GameController support.** Map a connected controller's face buttons (pause /
  shuffle / next theme) and report it in `GCSupportedGameControllers`.

## Modes & content

- **More themes** (append‑only `ThemeID`): "Amber Terminal", "Ferrofluid",
  "Aurora", "Blueprint", "Holiday" seasonal.
- **Custom logo text.** Let the user type a short word/initials for the badge
  (`LogoAppearance.wordmark` is already data‑driven) — with a gentle profanity
  filter for the App Store's sake.
- **Photo / shape logo.** Allow a chosen SF Symbol or (later) an imported image as
  the bouncing object.
- **"Day/Night" auto theme.** Switch Minimal White ↔ a dark theme on a schedule.
- **Picture frame mode.** A very slow Cinematic preset tuned to be wall‑art‑grade
  (huge logo, glacial speed, no sound) — markets to the "Apple TV as art" crowd.

## Statistics & longevity

- **Per‑theme stats.** `CornerHitEvent` already carries `themeID`; surface
  "favourite theme by corners", "most corners in one theme", etc.
- **Sparkline / heatmap.** A tiny 7‑/30‑day corners‑per‑day sparkline; a corner
  heatmap that literally lights the four corners by frequency.
- **Achievements (local only).** "First perfect corner", "10 in one session",
  "1,000 lifetime", "broke a 30‑minute dry spell" — purely cosmetic badges, no
  Game Center required (could add Game Center as an *option* later).

## Internet‑native hooks (all opt‑in, no accounts, no identifiers)

- **Daily impossible seed.** Add a "Today's seed" toggle that drives the
  screensaver from `SeededRandom.dailySeed()` and shows a separate "corners on
  today's seed" counter; a tiny on‑screen short code so a stream's viewers can run
  the same seed.
- **Global corner counter.** An opt‑in, anonymous, heavily rate‑limited "+N" beacon
  to a stateless sum endpoint; show "Corners hit by everyone today". No who, no
  when, no device id; the beacon is just a number.
- **"The world's last perfect corner was X seconds ago"** in the HUD when the
  community feed is on — a genuinely fun live number.
- **Shareable corner card.** Render a clean still ("Corner #1,000 · top‑left ·
  Synthwave · 14:32") the user can AirPlay or photograph.
- **Twitch / streamer extras.** Beyond the shipped Streamer mode: a "stream‑safe
  palette" toggle (avoid pure white flashes), and a corner of the screen reserved
  for an optional unobtrusive overlay ("today's seed: ABCD · corners: 7").

## Accessibility & options

- **VoiceOver narration** of stats and settings (the screensaver itself is decorative
  and stays `accessibilityHidden`).
- **High‑contrast / Increase Contrast** support for the chrome.
- **Burn‑in guard.** For OLED owners who really do leave it on for days: a very slow
  global drift of the whole composition, plus periodic micro‑shifts of static UI.
- **Sleep timer.** "Stop after 1/2/4/8 hours" so it's a guilt‑free thing to fall
  asleep to.

## Engineering

- Replace the hand‑written `Contents.json` icon scaffold with real artwork; wire a
  `fastlane` lane for screenshots/App Preview capture.
- A small `XCUITest` smoke test (launch → open menu → switch theme → open stats →
  back).
- Consider extracting `Engine/` + `Model/` into a Swift package so they can be unit
  tested on macOS in CI without a tvOS simulator.
