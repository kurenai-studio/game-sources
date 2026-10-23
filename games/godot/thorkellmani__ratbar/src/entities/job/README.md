# entities/job/

`Job extends Node2D` holds a display `title`, `modifiers: JobModifiers`, and
Inspector-wired `locations: Array[Location]`. JobModifiers extends NeedValues
and bounds physical need effects to `-20..20` per game-hour. These effects are
independent of the station's own modifiers and apply only during active work.

Job instances are direct children of JobManager, which discovers them through
`get_jobs()`. The five jobs in `main.tscn` are HeadChef, SousChef, LineCook,
Dishwasher, and Bartender, each with a station and first-pass modifier values.
Adding a job means adding a Job node and wiring its locations. Slot limits,
pods, job skills, and output/performance calculations remain future work.

JobManager owns a `Dictionary[int, Job]` of assignments keyed by rat ID.
`assign_job(rat_id, job)` assigns a Job; `unassign_job(rat_id)` clears it.
An unassigned lookup returns null. Changed assignments emit
`job_assignment_changed(rat_id)`, allowing RatManager to reconsider stationary
work and DebugController to refresh the selected rat's readout.

Assignment is separate from active work. Rat arrives idle; RatManager requests
`request_start_work()` if the current assignment includes the reached station.
Unassignment or reassignment stops invalid stationary work; travelling rats
continue and use the current assignment on arrival. Rat owns request acceptance.

RatManager adds `JobConstants.EMPLOYMENT_PRESSURE` to copied scoring options
for the assigned job's stations. Jobs have no pull of their own. JobConstants
is a global script class containing that constant, not an autoload; the old
fixed JOB enum and JobSkills type were removed. RatState holds stable location
IDs rather than Job or Location node references, and no Other Resource remains.
