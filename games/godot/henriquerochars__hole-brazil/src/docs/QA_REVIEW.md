# Independent engineering review

Reviewed by a separate Codex QA agent against the gameplay implementation and actual rendered UI, using Godot 4.5.1. The review covered movement, collision, absorption, growth, timing, replay, native input dispatch, persistence, and bounded simulation work.

## Findings and resolution

| Finding | Impact | Resolution / evidence |
| --- | --- | --- |
| Generated audio playback survived immediate headless shutdown | Automated tests reported a leaked playback object | Gameplay author skips audio generator creation in headless runs and releases playback on teardown; integration tests exit cleanly. |
| UI mute originally did not reach the gameplay tone generator | Absorption sounds could play despite the mute setting | UI implementation now synchronizes the gameplay audio flag at startup, toggle, and replay; UI regressions cover all three. |
| Immediate screen reconstruction during a native button signal | Removing controls during input dispatch produced a Godot `can_process` error | Button and candidate-card callbacks now use deferred connections; all 37 rendered UI checks pass without the dispatch error. |
| Hand-authored settings could contain unexpected value types | Loading corrupted preferences could fail or misinterpret settings | Controller validates types and clamps numeric values; malformed save and valid save tests run and restore the user's original file. |

## Behavioral validation

`tests/test_integration.gd` runs 22 checks against the real gameplay node. These cover deterministic world generation, touch movement and release over UI, unrelated fingers, cancellation, focus loss, one-time scoring, growth, paused simulation and sink animation, oversized collisions, world bounds, one-shot completion, and replay resets.

`tests/test_playthrough.gd` runs twelve complete 90-second rounds: all three candidates, each using seeds 1, 42, 12345, and 7788. The autonomous driver only supplies movement directions and uses normal acceleration, collisions, scoring, and timing. All twelve reach level 6 and absorb all 192 props. This establishes that progression is reachable; it does not estimate average human performance.

`tests/test_ui.gd` runs 37 checks, including an actual touch-driven native button activation, pause and mute transitions, preference loading, and scroll reachability at 360×640, 960×540, and 540×960 window sizes. It runs with a rendering display under Xvfb because headless input emulation is not equivalent to native UI dispatch.

## Performance evidence

`tests/profile_simulation.gd` records ordinary and maximum-radius 90-second runs. Results are saved in [performance.json](performance.json). This measures CPU simulation steps only: no rendering, mobile GPU, real-device frame rate, or sustained thermal behavior. The spatial grid limits nearby collision queries; rendering culls offscreen props and caches repeated style resources. Objects remain in a fixed-size world array, avoiding per-frame scene-tree spawning.

The initial measured ordinary-round mean was approximately 61 microseconds per simulation step, with a 95th percentile of 88 microseconds. Maximum-radius mean was approximately 66 microseconds, with a 95th percentile of 101 microseconds. These values describe this development machine, not a performance guarantee.

## Remaining release limits

- Physical Android/iOS touch feel, cutouts, background behavior, thermal performance, and release signing remain device checks. See [MOBILE.md](MOBILE.md).
- Automated steering is deliberately efficient; player difficulty and retention still benefit from human playtesting.
- Desktop screenshots and the animated GIF are real viewport captures, not a substitute for device usability testing.
