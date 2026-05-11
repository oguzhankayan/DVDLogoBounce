# Audio assets

`AudioController` references the sound files below. They are intentionally **not**
committed as binaries — a sound designer should produce them to the specs here and
drop them into this folder; `project.yml` will bundle anything in `Corner/Resources`.

If a file is missing at runtime, `AudioController` fails gracefully (it logs once
and that channel stays silent), so the app still runs in development.

## Sound effects (one‑shots)

All SFX: 48 kHz, 16/24‑bit, mono, normalised to ‑3 dBFS, no DC offset, hard‑trimmed
at the head, ~80–250 ms long unless noted. Keep them *soft* — this is an ambient app.

| File                         | Used for                                  | Character |
|------------------------------|-------------------------------------------|-----------|
| `bounce_soft.caf`            | wall bounce (default / Classic / Minimal) | warm "tok", low click, almost felt |
| `bounce_neon.caf`            | wall bounce (Neon / Synthwave / Glass)    | short filtered blip with a tail |
| `bounce_crt.caf`             | wall bounce (Retro CRT / VHS)             | dull thunk + faint static tick |
| `bounce_matrix.caf`          | wall bounce (Matrix)                      | crisp digital tick |
| `logo_collision.caf`         | logo‑to‑logo collision (multi mode)       | two soft toks layered |
| `corner_hit.caf`             | perfect corner hit                        | a clean, slightly euphoric chime (~600 ms), tasteful — not a "ding" meme |
| `corner_hit_crt.caf`         | perfect corner hit (CRT / VHS themes)     | the chime run through a tape‑wow + bitcrush |
| `near_miss.caf`              | close‑call (logo grazes a corner)         | a quiet rising "tk‑tk" |
| `ui_focus.caf`               | focus moves in menus                      | barely‑there tick |
| `ui_select.caf`              | select / open                             | soft confirm |
| `ui_back.caf`                | back / dismiss                            | soft de‑confirm |

## Ambient beds (seamless loops, 30–90 s, ‑18 dBFS RMS, fade‑safe at the loop point)

| File                  | Ambient mode  | Character |
|-----------------------|---------------|-----------|
| `ambient_vhs_hum.caf` | VHS Hum       | tape transport hum, faint head noise, gentle wow & flutter |
| `ambient_synth.caf`   | Synth Pad     | slow evolving warm pad, very low movement, no melody |
| `ambient_room.caf`    | Room Tone     | almost‑silent dark‑room tone for a touch of "presence" |

`Silent` mode plays nothing.

## Format note

`.caf` is preferred on Apple platforms for gapless looping. `.m4a` / `.aac` also
work for the ambient beds; if you ship `.m4a`, update the extensions in
`SoundEffect` / `AmbientBed`.
