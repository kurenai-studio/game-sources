# Rat Ownership and Debug Reliability — Visual Tests

Run `main.tscn` in Godot. Check each item only after observing the expected result.
Record failures or unexpected behavior in the notes below each section.

Date: **2026-10-12**  Tester: **Maintainer**

Status: **Confirmed for now by the maintainer.** Checkmarks record that reported
confirmation; structural/headless checks are recorded separately in the sprint closeout.

## Scene Reorganization

- [x] Open `debug/panel/debug_panel.tscn`: fixed buttons, feedback, field groups, stress breakdown, and job assignment are present in the editor's scene tree.
- [x] Run `main.tscn`: each control appears once, and the overlay layout remains usable.
- [x] Expand each foldout and confirm its fields/labels/buttons appear.

## 1. Selection and Generation

- [x] Startup generates one rat.
- [x] Generate a second rat using the debug panel.
- [x] Switch between rats; each displays its own needs, personality, statuses, Miscellaneous fields, and stress breakdown.
- [x] Miscellaneous starts collapsed and contains owner relationship, currency, crisis, and activity state.
- [x] The assigned-job readout belongs to the selected rat.
- [x] Below the job readout, Location shows the current location title, Travelling in transit, or None before reaching a location; it updates when switching rats and on departure/arrival.
- [x] Editing or assigning a job to one rat leaves the other unaffected.

Notes:

## 2. Editing and Play

- [x] Set speed to `10×`, then start typing in a need field: simulation pauses immediately and the button shows ▶.
- [x] Edit multiple fields, including a status and a Miscellaneous field such as currency.
- [x] Press Enter: the draft remains open and the game stays paused; Enter does not submit.
- [x] Press Play: edits are accepted before simulation resumes at `10×`, and the button shows ⏸.
- [x] Fields continue updating after resume; subsequent simulation ticks use the edited values.

Notes:

## 3. Invalid Input and Discard

- [x] Leave a grouped field empty or as `-`, then press Play: simulation stays paused, feedback appears, and the invalid field receives focus.
- [x] Repeat with a Miscellaneous field such as currency.
- [x] Correct the number and press Play: the edit is accepted and simulation resumes.
- [x] Repeat with invalid input, then press **Discard edits**: accepted values return and feedback disappears.
- [x] Discard leaves the game paused; pressing Play afterward resumes normally.
- [x] Enter an invalid crisis/activity enum value: Play rejects the draft without applying any of its edits; Discard permits recovery. Complete-state rejection is reported in Godot's debugger.

Notes:

## 4. Switching While Editing

- [x] Start editing rat A, then select rat B: A's unfinished draft is discarded and the game stays paused.
- [x] Return to rat A: its accepted values are unchanged by the discarded draft.
- [x] Click the same rat while editing: its draft is preserved.

Notes:

## 5. Pause and Speed

- [x] Pause at `5×`, select `10×`, and confirm the game remains paused.
- [x] Resume: the game runs at `10×`, matching the label.
- [x] Repeat pause/resume and speed changes; the icon and label remain synchronized.
- [x] Editing-triggered pause behaves like manually pressing Pause.

Notes:

## 6. Jobs, Travel, and Arrival

- [x] Assign a job: its title appears immediately; unassigning shows **Unassigned**.
- [x] Assignment alone adds no work stress while idle away from a station or travelling.
- [x] Working at an assigned station adds `+3/h` in the stress breakdown; the net rate equals the need rate plus work rate.
- [x] Unassign before arrival: the rat arrives idle with no work effects.
- [x] Assign while travelling to that job's station: the rat starts work on arrival.
- [x] Arrival at a location outside the assigned job's stations leaves the rat idle.
- [x] Unassign while working: work stops and its stress contribution disappears.
- [x] Reassign a stationary rat: work stops if the new job excludes its location, or starts if the idle rat is at a valid station.
- [x] Movement and destination choices still look consistent with the previous behavior.

Notes:

## 7. Stress Baseline and Bounds

With no job, pause and set nutrition to `-80`, the other four needs to `+50`, and stress to `60`. Submit with Play and inspect the first ticks; ongoing decay will change the exact readings.

- [x] Before Pantry, average urgency is about `.509`, with need stress rate `+6/h`.
- [x] While nutrition is being fulfilled at Pantry, average urgency is about `.321`, with need stress rate `-3/h`.
- [x] Pantry nutrition increases at a net `+15` per game-hour; needs still decay while travelling.
- [x] Needs clamp valid out-of-range input to `-100..100`.
- [x] Owner relationship clamps valid out-of-range input to `-100..100`.
- [x] Stress clamps valid out-of-range input to `0..100`.
- [x] Personality and other status fields retain their existing bounds and display behavior.

Notes:

## 8. Debugger and Overall Result

- [x] No new script errors occur during ordinary valid interactions.
- [x] Intentional rejected-state tests report their validation errors without partial changes or a crash.

Known headless-check messages: macOS certificate/editor-settings errors and shutdown ObjectDB/two-resource leaks were already present. Record any new or different errors.

Overall result: ☑ Passed ☐ Issues found

Issues / screenshots / follow-up:

This checklist covers visual behavior. Snapshot independence, atomic acceptance,
notification ordering, and manager regrouping have separate headless verification
recorded in the [sprint closeout](sprints/06-rat-ownership-and-debug-reliability.md).
