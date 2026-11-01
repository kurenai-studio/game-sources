# level-designer memory

- [Level 1 content mechanics](project_level-one-content-mechanics.md) — where a formation actually
  lands, `offsetY` as a head start in pixels rather than seconds, the per-spawn trajectory override
  11c added, what an escaping enemy costs you, unknown JSON keys now being rejected, the carrier's
  lockstep spawners, and why `combatY` decides whether the boss can hit anything.
- [Writing content through Bash](feedback_bash-heredoc-for-content.md) — heredocs carrying long JSON
  or Markdown abort before running; write to the scratchpad and `cat` it in.
- [Verifying content against the loader](project_verifying-content-against-the-loader.md) — load the
  whole `assets/data` set through a real `JsonContentSource`, and the Windows classpath details that
  make the throwaway program run.
- [Level values that live in code](project_level-values-that-live-in-code.md) — drop kinds, boss
  geometry, projectile radius and the playfield dimensions are constants in `core/`, not content, and
  design intent has nowhere in `assets/data/` to live at all.
- [Reading a document back](feedback_reading-a-document-back.md) — grep the document for every fact you
  used instead of grading yourself on whether you managed to write the file; and restoring broken
  generated content means restoring the source and the output.
- [Enemy durability arithmetic](project_enemy-durability-arithmetic.md) — a trigger pull fires 1/2/3/5
  projectiles by weapon level so `shots to kill` overstates durability up to 5x; `fragile` is orthogonal
  to Health, and the bomb ignores Health on a fragile enemy entirely.
- [Shape placement arithmetic](project_shape-placement-arithmetic.md) — how far a drifting shape
  carries a formation off screen, the `atX` windows for `swoop` and the veers, the generator's 50%
  threshold, and why a wave cannot be empty.
- [Carrier spawner survival window](project_carrier-spawner-survival-window.md) — a spawner's first
  child arrives one whole interval late, so a carrier's health has a floor of `interval x ideal dps`.
- [Apply the owner's numbers exactly](feedback_apply-owner-numbers-exactly.md) — ship a play-session
  number verbatim and record the disagreement in the fragment; make the JSON say what is true.
- [Reward cadence in level 1](project_reward-cadence-in-level-one.md) — the generated document charts
  density and never charts rewards, a second shield stacks with nothing, and why every drop rides a
  slow archetype.
- [Scenario level files](project_scenario-level-files.md) — the doc generator only sees `level-NN.json`,
  so a tool-only level is invisible to it; and no level file can set the player's starting state.
- [Path shape authoring](project_path-shape-authoring.md) — a `path`'s loop range always ends the
  segment list, so a zero-drift loop can only exit sideways; the lead-in leg that centres an
  oscillation; and the stale scratchpad class that ran instead of the fresh one.
- [Absolute waypoint authoring](project_absolute-waypoint-authoring.md) — absolute in x only if the
  wave's atX matches the entry point, in y only modulo the collider radius, and unchecked by anything.
- [Vocabulary budget arithmetic](project_vocabulary-budget-arithmetic.md) — thirteen authored shapes is the floor two-or-three-per-archetype produces; absolute paths cannot ride a multi-slot formation; `arc` with a negative `ay`.
- [Generator checks while authoring a level](project_generator-checks-when-authoring-a-level.md) — the
  50% swept-extent threshold measured from the footprint edge, why a negative offset is always a
  finding, constant-velocity over-extrapolation, and generated prose that rots.
- [Wave migration mechanics](project_wave-migration-mechanics.md) — a wave's `FixedDuration` is shared
  across every placement that reuses it, negative offsets overlap two `FixedDuration` waves since 11b, no
  test touches the real `assets/data/level-01.json`, and how to live-run it without a full app context.

This file indexes what this agent learns that `docs/` has no reason to hold:
pacing that did not survive contact with the build, a formation that reads differently than it
looked on paper, a limit of the content format found while using it.

Phase progress does not belong here — that is `status.md`'s job, and two copies of it rot.
