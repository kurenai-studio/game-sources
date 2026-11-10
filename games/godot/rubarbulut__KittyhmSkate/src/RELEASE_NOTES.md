# Kittyhm Skate 0.2.0 — gameplay release candidate

Character and environment art are procedural placeholders. This release focuses
on music-led dual-action gameplay, readable feedback and a complete short tour.

## Play session

- A 30-second interactive warmup teaches tap notes, ollies and sustained notes.
- Three original tracks progress from 128 through 136 to 148 BPM.
- Cyan long notes require holding Shift. Jumping onto rails starts an automatic grind.
- Each finished track opens the next. Final results close the night tour.
- Per-track records, local saved progression, retries, pause and settings.
- Street rhythm view by default, with a classic lane available via Tab.
- Full/reduced VFX, music level, hit sounds and robust tap-to-audio calibration.

## Verified

- Automated full-chart runs at 30, 60 and 120 FPS: every note, barrier and rail.
- Short 50ms Space taps and delayed jump inputs can clear the authored charts.
- Sustains, early release, two physical Shift keys, pause and restart behavior.
- Missing/malformed configuration, NaN values, bounded records and save roundtrip.
- Prototype score migration retains the score without inventing accuracy/combo data.
- Native real-time input tours complete with no misses or bumps, and all rails.
- Real browser integration tour completes with no misses or bumps, all rails, and
  a valid 16-tap calibration. Web console reports no warnings or errors.
- Windows and single-threaded Web export packages are produced by the release script.
- Packed resource/QA exclusion checks and ZIP entry/binary/license audits are automated.

The browser test found and fixed an invalid negative Web mixer-delay estimate
which could advance the first song. Web Sample playback now uses valid output
latency without depending on Godot's inactive mixer clock. Physics follows song
time in small steps so browser stalls cannot skip barrier collisions.

## Game Off

Theme interpretation: Shift is the rhythm input, and the drop shifts the city into
its neon dimension. See [Game Off 2026](https://itch.io/jam/game-off-2026).
The source is MIT licensed; Silkscreen is SIL OFL 1.1. Original music and feedback
sounds are synthesized without third-party recordings or samples.

An exported build is not itself proof of an itch.io submission. Actual repository,
game page and jam submission URLs must be checked separately after publication.
