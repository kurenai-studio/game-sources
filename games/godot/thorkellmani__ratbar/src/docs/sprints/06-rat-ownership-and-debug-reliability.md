# Rat Ownership and Debug Reliability — Completed

Closed on **2026-10-12**, following the maintainer's visual checklist confirmation
("confirmed, for now"). No next sprint has been opened.

## Completed tasks

- [x] Simplify stat classes and introduce shared `NeedValues` and unconstrained `NeedRates` before continuing tick integration.
- [x] Remove `Other`/`OtherFields`, move their fields to the agreed owners, migrate callers, and organize `rat.gd` into named regions.
- [x] Use one travel state and idle-on-arrival behavior with manager requests to start work; reconsider stationary activity when assignments change.
- [x] Add the rat's snapshot and update interface.
- [x] Move need and stress coordination into `RatManager`, group calculation scripts under `entities/rat/systems/`, update resource references, and remove the rat's tick methods.
- [x] Keep reconsideration on `Rat`, using manager-supplied context and detached evaluator inputs.
- [x] Separate the debug controller from the panel and route edits through managers to the rat's update interface.
- [x] Replace sibling-node lookups with scene unique manager references, including the debug controller when introduced.
- [x] Add private paused edit drafts, Play submission, input validation, and Discard edits.
- [x] Centralize simulation speed and pause state and connect both buttons to it.
- [x] Verify behavior and update architecture documentation and the concept log.

The reviewed additions also include scene-authored fixed debug controls,
reusable field-group/stress/job scenes, a Miscellaneous foldout, assigned-job
and location-title readouts, and optional property prefixes for field bindings.

## Verification

- **Maintainer:** confirmed the [visual checklist](../06-VISUAL-TEST-CHECKLIST.md),
  covering selection/generation, independent edits, Play/Discard/invalid input,
  pause/speed synchronization, jobs/travel/arrival, and stress/bounds.
- **Headless contracts:** independent state Resources and drafts; complete
  validation and atomic rejection; equality including initial uncalculated
  urgency; changed-only settled notifications; bounded no-ops; copied scoring
  inputs; native resource compatibility and preserved need/stress behavior.
- **Runtime integration:** need changes then effective urgency then stress;
  Pantry nutrition `+15/h`; active work stress `+3/h`; assignment/travel
  without work effects; staggered destination decisions; idle arrival before
  the manager's separate work request.
- **Debug scene integration:** authored fixed controls, correct field counts,
  foldout expansion, no duplicate controls or job lists, event-based selected
  rat refreshes, private draft editing, immediate acceptance before resume,
  and location titles supplied through LocationManager.
- **Manager regrouping:** a temporary scene moved JobManager and LocationManager
  under a grouping node while preserving the main scene as owner. Inspection,
  assignment, Pantry tick effects, and location-title display passed.
- Project startup/import had no script errors; whitespace checks passed.
  Existing certificate/editor-settings and shutdown leak messages remain.
  After script shortening, editor layout restoration also reported a stale
  saved fold-line position; runtime checks passed.

## Retrospective

### Findings

- RatState owns stored values; detached snapshots and narrow drafts make the
  read/update boundary explicit. Rats accept requests and announce settled
  changes; systems calculate using supplied data.
- Scene components make fixed UI structure visible in Godot. DebugPanel owns
  the private edit draft, while focused components display fields, stress,
  and job choices; DebugController coordinates managers and simulation time.
- Keep terminology specific: need is condition, urgency is want; employment
  is assignment, work is execution; snapshots are detached copies and drafts
  are mutable proposed updates.
- Review connected dependencies together. Whole-class previews and collapsible
  regions support understanding without leaving partially connected runtime
  changes active.

### Notes for later sprints

- Design optional breakdowns beside each field input. Move the stress breakdown
  to the stress row and add per-need decay/location/job/net-rate breakdowns.
  Offer the control only where details are available. This replaces the
  standalone need-rate-label proposal; settle layout and data contracts first.
- Consider a reusable Movement child node; Rat retains state ownership and
  arrival acceptance. Keep NeedSystem and StressSystem as static utilities.
- Revisit main-mediated clock routing after choosing its time/update contract.
- Revisit shared bounds/clamping only after agreeing its ownership and API.
- Profile snapshot allocation at representative colony sizes before reuse.
- Investigate existing shutdown leaks separately when prioritized.

Completed results and later considerations are folded into the
[backlog](../RAT_SIMULATION_BACKLOG.md). The
[decision log](06-rat-ownership-decisions.md) and
[behavior baseline](06-behavior-baseline.md) remain historical records.
