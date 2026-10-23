# Debug overlay

`controller/debug_controller.gd` coordinates selection by rat ID, manager requests,
stress display data, and simulation time. Its Node is a root child in `main.tscn`.

`panel/debug_panel.gd` displays a detached RatState copy and prepared stress rates.
It holds no live Rat or Job references. Personality, Needs, Statuses, and
Miscellaneous groups read the captured state or the panel's private edit draft.
Fixed buttons and foldouts are authored in `panel/debug_panel.tscn` and visible
in Godot's scene tree. The panel binds components, forwards requests, and owns
its private edit draft.

- `panel_group/panel_group.tscn` is reused for all four field groups. Its script
  generates rows through supplied getter/setter Callables and an optional
  property prefix; Miscellaneous binds directly to RatState fields.
- `stress_breakdown/stress_breakdown.tscn` owns the stress labels and formatting.
- `job_assignment/job_assignment.tscn` owns its foldout and Unassign button. Its
  script generates job buttons from titles and emits the selected index.

Edit component layouts in their own scenes. Each component handles its own UI
and has no direct manager or live Rat dependency.

The first text edit requests pause and deep-copies the captured state. Typing
changes only that draft; Enter does not submit. Play checks unfinished numeric
inputs, submits the complete draft for immediate rat acceptance, and resumes on
success. Rejected edits remain paused and can be corrected or discarded. Discard
restores accepted values without resuming. Switching rats discards unfinished edits.

Pause and speed buttons emit requests. DebugController applies Engine.time_scale
and updates both displays together. Changing speed while paused selects the
resume speed without unpausing.
