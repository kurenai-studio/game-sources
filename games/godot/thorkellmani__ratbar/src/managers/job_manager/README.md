# managers/job_manager/

- `JobConstants` — the `JOB` enum has been removed entirely; all that's left
  is `EMPLOYMENT_PRESSURE` (currently `0.35`, used with the power-mean
  formula in `LocationChoice`; see `docs/ALGORITHM_RESEARCH.md` for the
  observed nutrition crossover). See
  `entities/job/README.md` for why the enum went away.
- `JobManager` — owner-driven rat ↔ job assignment (`_ASSIGNED_JOBS:
  Dictionary[int, Job]`, keyed by rat id, values are `Job` node references or
  absent — no `null` stored, `unassign_job()` erases the entry).
  Assignment and lookup methods accept rat IDs; no Rat reference is required.
  `get_jobs()` discovers `Job` children the same way
  `LocationManager.get_location_data()` discovers `Location` children. A rat
  never assigns itself a job — jobs have no `pull`, only
  `employment_pressure`.
