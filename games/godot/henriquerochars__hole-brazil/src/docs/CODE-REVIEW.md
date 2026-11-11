# Independent Codex implementation review

Reviewed on 2026-11-10 by the Codex gameplay agent, independently of the UI author. Scope: `main.gd`, `ui_kit.gd`, input configuration, persistence, UI-to-gameplay integration. Findings refer to the initial implementation; the lead owns fixes and release verification.

## Findings

| Severity | Finding | Evidence | Required change |
| --- | --- | --- | --- |
| P1 — mobile blocker | Ordinary menu and pause buttons do not respond to touch with mouse emulation disabled. | `project.godot` sets `pointing/emulate_mouse_from_touch=false`. A Godot 4.5.1 test dispatched touch press/release to a `Button`: disabled produced 0 activations; enabled produced 1. | Enable touch-to-mouse emulation and verify menu, selection, pause and joystick together. Avoid interpreting a synthesized pointer as an additional joystick. |
| P1 — broken setting | Muting UI leaves swallowing audio enabled. | An isolated runtime check changed `main.muted` from false to true; `gameplay.sound_enabled` remained true. The UI flag only guards `_beep`. | Apply the persisted setting to gameplay during initialization and propagate every toggle. Stop existing audio when muting. |
| P2 — persistence resilience | A syntactically valid settings file with an unexpected value type causes a runtime error. | With `best_score=[]`, `_load_settings()` raises `Invalid call. Nonexistent 'int' constructor`. | Validate Variant types and ranges before conversion; keep safe defaults for malformed values. Handle save failures without claiming persistence succeeded. |
| P2 — misleading HUD | Combo chain count is presented as a score multiplier. | The HUD displays `6x COMBO` at chain 6, while `game_rules.gd` returns multiplier 1.25 at chain 6. | Show the actual `stats.multiplier`, with chain count separately labeled if desired. |
| P2 — layout overflow | Scrolling content puts its vertical scrollbar beyond the base viewport. | At 540×960, the selection `ScrollContainer` measures 548px wide; its scrollbar starts at x540. Fixed 492px content plus 48px margins leaves no scrollbar width. | Reserve scrollbar width or let content shrink; verify the candidate row still fits. |
| P3 — asset fidelity | Menu hero stretches Congress art to an unrelated aspect ratio. | `Hero._draw()` draws the texture into `(w*0.5, h*0.72)` without using its dimensions. | Preserve the source aspect ratio in a bounded centered rectangle. |

The touch behavior also matches the [official Godot TouchScreenButton documentation](https://docs.godotengine.org/en/stable/classes/class_touchscreenbutton.html), which explains enabling mouse emulation for regular Button nodes.

## Positive checks and boundaries

- Main menu and selection primary actions fit the 540×960 viewport: their bottoms are at y811 and y813 respectively.
- HUD decorative Controls use `MOUSE_FILTER_IGNORE`, allowing steering through the playfield.
- Application focus loss pauses an active round. Pausing resets captured pointer state and preserves the simulation timer.
- Candidate indices are clamped at round start; each displayed advantage maps to the corresponding gameplay rule.
- Gameplay regression suite passed 22 integration checks; pure-rule tests also passed.
- Headless audio teardown no longer reports an `AudioStreamGeneratorPlayback` leak after the gameplay patch.
- Automated viewport checks do not establish touch ergonomics or safe-area behavior on a physical Android/iOS device. Device exports still require their platform SDK/signing setup and device validation.

## Release recheck

The lead should record the fixes and actual recheck results below before publishing; initial findings alone are not evidence of resolution.

The integration pass resolved all six initial findings: touch-to-mouse emulation enabled; mute propagated at load/toggle/start; ConfigFile types checked and values bounded; actual multiplier and canonical six level names displayed; scrollbar space reserved; Congress aspect preserved. GUI callbacks now defer screen replacement until after input dispatch. Full validation passed **37 rendered UI checks**, 22 gameplay checks, pure rules and 12 full rounds. Physical-device verification remains pending.
