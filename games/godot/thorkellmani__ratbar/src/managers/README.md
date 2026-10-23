# managers/

`Node2D`s that coordinate entities from the outside. Rat owns its state and
accepts change requests; RatManager gathers context and coordinates calculations.
JobManager owns assignments, and LocationManager resolves scene locations.

- `rat_manager/` — the sim's tick loop; drives every rat's need application
  and decision re-evaluation
- `job_manager/` — rat ↔ job assignment
- `location_manager/` — queries over the `Location` children in the scene
