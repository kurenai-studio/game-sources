# Rat Simulation

This document describes the intended simulation, including future mechanics.
The [backlog](RAT_SIMULATION_BACKLOG.md) records implementation status. The latest
completed sprint is [Rat Ownership and Debug Reliability](sprints/06-rat-ownership-and-debug-reliability.md),
included in commit `f376ce5` (2026-10-12), following the stress implementation in
`4ac4c5f`. No sprint is currently active.

Current behavior: rats own RatState Resources, consumers inspect detached copies,
and RatManager coordinates need/stress update drafts for Rat acceptance. All five
needs start at `80` and decay by `-5/h`, including during travel. Stationary
location effects and active assigned work offset decay. Decisions use a power
mean (`p = 3`) of urgency × normalized pull, plus assigned-station employment
pressure. Stress uses effective average urgency tiers and active work adds `+3/h`.
Personality scoring, random score variance, switching inertia, job skills,
per-vice tracking, social interactions, and gameplay crisis behavior remain future
work. See the [Rat runtime documentation](../entities/rat/README.md) for ownership
and request contracts.

## Overview

Rats operate autonomously. They have needs that decay over time, a personality that shapes how they respond, and a job they are nominally assigned to. The owner manages conditions — he does not control rats directly. Behavior emerges from the simulation.

The model is inspired by The Sims: locations and actions advertise their potential to satisfy needs, a rat evaluates available actions using a weighted algorithm, and picks the best one with some variance. Chaos is baked into the variance — it is not a stat.

---

## Simulation Time

The simulation runs on its own clock, not on Godot's per-frame `_process()` and not on any individual rat's own timer.

**Convention:** 1 game-hour = 60 real seconds at 1x `Engine.time_scale`. A 16-hour shift plays out in 16 real minutes. Debug time-scale controls (0.5x/1x/5x/10x) scale this uniformly — a shift always takes the same number of *game*-hours, just compressed or stretched in real time.

A single `GameClock` emits a tick every simulation second; `GAME_TICKS_PER_IN_GAME_HOUR = 60`. Two kinds of updates run at different cadences:

- **Decision-making** — a rat deciding where to go next. This doesn't need to happen every tick for every rat; each rat is assigned a fixed slot at generation and only re-evaluates on ticks matching its slot, so a colony's decisions are spread out rather than all recomputed on the same tick.
- **Need and stress application** — runs every tick for every rat, regardless of its decision slot. Baseline need decay continues during travel. Location effects apply while stationary; job effects and work stress apply only while actively working an assigned job at one of its stations.

Only RatManager listens to `GameClock.tick`. It runs NeedSystem then StressSystem
on each rat's detached update draft and requests acceptance before scheduled
destination choice. Rats occupy one of 15 weighted-random decision slots, giving
four decisions per game-hour. Movement runs separately in Rat's `_process()`.

---

## Physical Space

### Kitchen

The kitchen is the primary simulation space. All job stations are located here. Rats navigate between stations as they evaluate and act on locations.

| Station | Job | Notes |
|---|---|---|
| Stoves | Head cook, line cook | Center of kitchen activity |
| Counters | Prep cook | Adjacent to stoves |
| Wash basin | Dishwasher | Back of kitchen |
| Bar | Bartender | Front of house |

### Spawn Points

Rats do not have fixed homes. They spawn from environmental hot spots — roof gaps, windows, floor holes, wall cracks. These represent their abstract living space. There is no tracked sleep location; nesting is implied by spawn point affinity.

### Activity Space

Vices that pull rats away from the kitchen are treated as an abstract off-screen state. The rat is simply absent from the kitchen — zero job output, zero pod contribution. The spatial rendering of this space is unresolved and deferred.

---

## Data Model

### Personality Stats

Fixed at generation. Scale -100 to 100. These are weights and modifiers — they seed job skills at generation and modify every calculation downstream.

| Stat | -100 | 0 | +100 | Default |
|---|---|---|---|---|
| `greed` | Selfless, shares, doesn't steal | Neutral self-interest | Petty, steals, always cutting corners | +40 |
| `temper` | Eerily calm, nothing bothers them | Average reactivity | Explosive, stress hits hard and fast | +10 |
| `socialness` | Avoids everyone, poisons interactions | Gets along fine | Magnetic, needs constant interaction, pulls others in | +60 |
| `ambition` | Completely checked out, invisible | Goes through the motions | Highly directed — toward owner if relationship is good, against if bad | -20 |
| `laziness` | Restless, always doing something | Balanced | Profound gravitational pull toward doing absolutely nothing | +20 |

Defaults represent the baseline cartoon rat. `laziness` is the most variant stat — expect the full spectrum across a colony.

High `ambition` + high `laziness` is an inherently stressful combination unless the rat is in a position of control. Without that outlet, ambition and inaction create constant internal pressure.

### Needs

Continuous stats, -100 to 100. 0 = neutral. Negative = deprived. Positive = satisfied. Decay over time, relieved by actions and locations.

| Stat | Decays when | Relieved by | Baseline |
|---|---|---|---|
| `nutrition` | Always | Eating | ~2x per shift |
| `energy` | While awake, faster while working | Sleep (polyphasic — 2-3 naps per shift) | 2-3 naps, adjusted by need value |
| `stimulation` | During repetitive or unstimulating periods | Pranks, gambling, stimulating vices, any engaging activity | 1-2 fun sessions per shift |
| `social` | Always while awake | Interaction with other rats | Near-constant; work chatter maintains but does not grow it |
| `vice_satisfaction` | Driven by stress level, not time | Using their vice | ~3 uses per shift at baseline stress |

`stimulation` and `social` are distinct. A rat can be stimulated but lonely, or socially satisfied but understimulated. Vices and activities relieve stimulation. Only rat interaction relieves social.

### Status Stats

| Stat | Scale | Notes |
|---|---|---|
| `stress` | 0 to 100 | Always negative. Feeds into all calculations. 100 = breaking point. |
| `health` | 0 to 100 | 100 = fully healthy. Recovers over time. |
| `inebriation` | 0 to 100 | Accumulates from drinking and drugs. Decays over time. |
| `owner_relationship` | -100 to 100 | Starts at 0. Primary compliance multiplier on employment pressure. |
| `radicalization` | 0 to 100 | Hidden. Raised by organizer broadcasts. Drives rebellion susceptibility. |
| `extra_stress` | 0 to 100 | Hidden. Accumulates in burnout when forced to work. Maxing out kills the rat. |
| `currency` | 0 to inf | Gains and losses through gambling. Economy TBD. |
| `crisis` | UNAFFECTED / BURNOUT / REBELLION | Set by breaking point roll. |
| `activity_state` | IDLE / TRAVELLING / WORKING | Current implemented activity state. Arrival settles idle; RatManager requests work if the current assignment includes the reached location. |

### Per-Rat Collections

| Collection | Key | Scale | Notes |
|---|---|---|---|
| `job_skills` | JOB | 0-10 | Permanent. Increments slowly with active work. Never decays. |
| `camaraderie` | rat_id | -100 to 100 | Asymmetric per pair. Starts near 0 on first meeting. |

---

## Internal Dynamics

### Need Decay & Fulfillment

Fulfillment is applied every `GameClock` tick a rat spends stationary at a location (see Simulation Time), not gated by the rat's own decision cadence — a rat parked at the Pantry gains nutrition continuously, whether or not this tick happens to be one where it's reconsidering where to go. Baseline amounts assume a rat that is doing okay; unmet needs and stress shift the rates.

`socialness` controls how fast `social` decays and how much positive effect the rat has on others during interaction. A low-socialness rat needs interaction less and contributes less to others' fulfillment. A high-socialness rat is miserable without constant interaction and boosts others significantly.

#### Fulfillment History & Repetition

Each need tracks its last fulfillment source. Repeating the same source yields diminishing returns. One different fulfillment in between fully resets the penalty.

| Need | Tracks |
|---|---|
| `nutrition` | Last food source |
| `stimulation` | Last activity |
| `social` | Last activity and last social partner |

**Friendship modifier** — rats considered friends trigger the repetition debuff much slower for social activities. Working physically adjacent to a friend never counts toward repetition — it always registers as fresh.

#### Urgency Curves

`need_urgency` in the action selection formula is not the raw need value. It is the raw value passed through a per-need urgency curve that determines how much weight a need carries at any point on the scale.

| Need | Curve shape |
|---|---|
| `nutrition` | Flat above +30. Slow rise through neutral. Steep exponential drop below -40. Most dramatic curve — a starving rat is single-minded. |
| `energy` | Broadly linear. Modest increase below 0. Steeper but not dramatic around -40 to -50. Functional degradation rather than crisis. |
| `stimulation` | Stable across the full range. Even when positive, still contributes a gentle pull toward stimulating activities. Shallow slope throughout. |
| `social` | Progressively steepening as it goes negative. No dramatic cliff — loneliness builds steadily the deeper it goes. |
| `vice_satisfaction` | Keyed on its own raw value, same as the other four — not on addiction (addiction tracking is shelved, see Vices below). Low right after use, sharp rise as satisfaction drops, climbing to a peak that rivals `nutrition`/`energy` — vice is fast and easy to reach for, so it competes hard once a rat is deprived, not a last resort. |

Needs do not directly represent mood. They feed into stress.

### Vices

Vice is abstracted into a single need, `vice_satisfaction` — no per-vice type (`smoking`/`drinking`/`drugs`/`sex`/`gambling`/`fighting`) is tracked individually, and there is no per-rat addiction stat. What used to be six distinct vices with independent escalation/decay rates is now just "the rat used a vice" satisfying the one abstracted need, same as any other action satisfies its need.

The owner provides or withholds vices. Providing them satisfies `vice_satisfaction` and improves relationship short-term. Withholding raises stress and degrades the relationship.

**Deliberately shelved, not designed away** — addiction/resistance (a stat that makes repeated use cost more or provide less relief over time, escalating the owner's dependency the way the original per-vice `addiction_escalation_rate`/`addiction_decay_rate` did) may come back later. For now the only friction is the existing money cost of providing a vice at all — there is no additional entrapment mechanic layered on top yet.

### Stress

Tracked stat, 0-100. 0 = fine, 100 = breaking point. Always negative — there is no positive stress.

Stress feeds into all calculations continuously. A rat at 60 stress is already performing worse, socializing differently, and consuming more vice. 100 is not the start of the problem, it is the end of a long slope.

#### Accumulation

Stress increases from:
- Unmet needs (negative need values), weighted by severity
- Repeated fulfillment from the same source (diminishing returns tipping into stress)
- Prolonged assignment to the same job — variety is required, not just need satisfaction
- Bad rat-to-rat interactions
- Hostile owner actions — may trigger an immediate roll rather than gradual accumulation

`temper` is the accumulation multiplier. Same inputs, faster stress gain for a high-temper rat.

`owner_relationship` also feeds into accumulation rate — a rat with a bad owner relationship accumulates stress faster from the same conditions.

#### Decay

Stress decreases from:
- Met needs
- Vices — the fastest and most potent stress relief in the simulation. (The stress → vice → addiction → abstinence stress → vice feedback loop this used to describe is on hold along with addiction tracking — see Vices above.)

#### Breaking Point

When stress reaches 100, roll for a crisis. Personality and owner relationship weight the outcome:
- High `temper` + low `owner_relationship` skews toward **rebellion**
- Prolonged overwork and unmet needs skews toward **burnout**

More crisis may be added later. The roll mechanic leaves room for expansion.

### Crisis ##

Discrete conditions a rat can fall into when stress hits 100 and the breaking point roll triggers. Entry is probabilistic — personality stats and owner relationship weight the outcome.

#### Burnout

- **Entry:** Prolonged overwork and unmet needs skews the breaking point roll toward burnout.
- **Visibility:** Obvious. The owner can clearly see a burned out rat. He should know to rest it.
- **Effect:** Stress locked at 100. `vice_satisfaction` and `energy` decrease faster. Job performance multiplier severely reduced. Self-reinforcing — unmet needs keep stress at max.
- **Extra stress:** If the owner continues to assign work to a burned out rat, `extra_stress` accumulates. If it maxes out, the rat dies. Death triggers a colony-wide owner relationship hit.
- **Recovery:** Prolonged rest and need satisfaction. Slow. The owner must pull the rat off work.

#### Rebellion

- **Entry:** Low owner relationship skews the breaking point roll toward rebellion. High `temper` and high `ambition` increase probability.
- **Visibility:** Partial. The owner gets environmental tells — pamphlets, ribbons, propaganda. The behavioral tell is a previously difficult rat becoming suspiciously compliant and productive. No direct readout.
- **Effect:** The rat enters organizer mode. It continues working to avoid detection while actively trying to radicalize other rats. Organizing effectiveness is determined by the rat's `socialness` and `ambition`.
- **Radicalization:** The organizer raises `radicalization` in nearby rats over time. Susceptibility is determined by the target rat's stats — high `socialness`, `ambition`, `temper`, and `greed` increase susceptibility. High `laziness` reduces it.
- **Escalation:** As radicalization spreads, environmental tells increase. Early signs are subtle. Later signs are unmistakable. If the owner doesn't intervene the rebellion can become colony-wide.
- **Recovery:** Owner must intervene — isolate or remove the organizer. Removal is the union-busting move but does not undo radicalization already spread. If colony conditions remain bad, another rat may pick up the organizing role.

The owner's tools against crisis are the same as always: job assignment, proximity control, vice and food provision. They are blunt and have side effects.

### Owner Relationship

Each rat has a relationship score with the owner, -100 to 100.

- Starts at 0 at generation.
- Increases when needs and vices are met, when job fit is good.
- Decreases when needs are chronically unmet, when the rat is in burnout or rebellion, when overworked or isolated.

The relationship score is the primary compliance multiplier on `employment_pressure`. A rat at -80 barely registers the job assignment. A rat at +60 will show up and try.

`ambition` is always directed at the owner axis — positively or negatively depending on where the relationship sits.

#### Colony Relationship

Derived bottom-up as a simple average of all individual scores. The colony score is what the player can observe. Individual scores are the reality underneath.

---

## Decision-Making

### Action Selection

On its assigned decision tick (see Simulation Time — not every game tick, just the one slot each rat is assigned), a rat evaluates all reachable locations and rat broadcasts and picks the highest scoring one. There is no return-to-post default — after every completed action the rat re-evaluates from scratch. `employment_pressure` on the job location is always competing, pulling the rat back to work passively.

#### Flow

**1. Location broadcasts**
Each reachable location emits a tag set of raw stat effects:
`{nutrition, energy, stimulation, social, vice_satisfaction, stress, health, inebriation, skill_progression, employment_pressure}`

**2. Personality modifier**
Rat personalizes raw tag values:
- `greed` amplifies self-serving tags
- `socialness` amplifies social tags
- `laziness` amplifies idle and rest location tags
- `ambition` amplifies `employment_pressure` tags if `owner_relationship` is positive; amplifies vice and social tags if negative
- `owner_relationship` is the direct multiplier on `employment_pressure` tags

**3. Adjacency group modifier**
Evaluate who is currently at this location:
- Apply camaraderie toward each adjacent rat as a score modifier
- Inebriated adjacent rats degrade the location score and pod performance
- Scales with evaluating rat's `socialness`

**4. Crisis modifier**
If rat is in burnout: suppress all tags except rest and vice.

**5. Rat broadcasts**
Rats themselves emit signals the evaluating rat scores:
- **Social need broadcast** — scored by camaraderie, socialness of both rats, distance, shared adjacency group, current need state
- **Group activity broadcast** (gambling, etc.) — same scoring
- **Organizer broadcast** — scored by radicalization susceptibility, camaraderie, distance. Adjacency group proximity weights it toward the organizer's current group first, then outward.

**6. Stress distortion**
Global skew proportional to stress level:
- Vice tags boosted
- Work and productivity tags suppressed

**7. Repetition penalty**
- Need-level: same fulfillment source as last time, reduce those tag values
- Location-level: same job assigned too long, apply cumulative penalty to that job location

**8. Score calculation**
The implemented score is a power mean (`p = 3`) of urgency × normalized pull
over positive-pull need axes, plus applicable employment pressure. The original
sum proposal was replaced; see [Algorithm Research](ALGORITHM_RESEARCH.md).
Additional personality, health, inebriation, and other modifiers in this flow
need design and verification before extending the current score.

**9. Variance**
Small random factor added to final score.

**10. Switching inertia**
A rat does not switch to a new action unless the challenger's score exceeds the current action's score by a threshold. Prevents jitter when two options are approximately equal. The threshold is a fixed constant for now — a candidate for personality-driven variation later (e.g. a neurotic/anxious trait could lower it).

**11. Selection**
Rat moves toward highest scoring location or rat broadcaster.

### Location Advertising

Each location emits a tag set of stat effects. The rat's action selection algorithm scores all reachable locations each tick and picks the highest.

#### Job Locations

Each job site emits:
- `employment_pressure` — base pull toward work, scaled by `owner_relationship`
- `skill_progression` — slow ambition-dependent satisfaction from improving at the job
- Job-specific need effects — bartender work advertises social and stimulation, dishwasher advertises neither

#### Employment Pressure

`employment_pressure` has a base value on all job locations at all times — the passive pull back to work after every completed action.

The owner can spike it temporarily — a shout, a presence, a threat. The spike applies to all rats equally and decays back to base. Effects:
- Short term: work location scores increase across the board
- Delayed cost: `owner_relationship` worsens per rat, stress increases per rat, scaled by current relationship — a rat at -60 is hurt more than a rat at +60
- Overuse stacks relationship damage and stress until the tool backfires

#### Vice Locations

Vices pull rats into the abstract activity space — physically absent from the kitchen, zero job output. The spatial rendering of vice locations is unresolved and deferred. See Open Questions.

| Vice | Notes |
|---|---|
| `smoking` | Negatively impacts food quality if rat is cooking or serving while smoking. |
| `drinking` | Accumulates `inebriation`. Job performance degrades with inebriation level. Heavy drinking causes hangovers that carry into the next shift. |
| `drugs` | Affects adjacent rats passively — nearby rats receive effects whether they want to or not. Tracked via `inebriation`. |
| `sex` | Rat is absent from kitchen. |
| `gambling` | Rat is absent from kitchen. |
| `fighting` | Rat is absent from kitchen. Reduces `health` of participants. |

---

## Jobs

Each job has a fixed slot count. Rats assigned to the same job form a **pod**. Pod performance is calculated from averaged individual performance values, modified by group dynamics between the specific rats in the pod.

| Job | Slots | Key fit | Poor fit | Worst possible fit |
|---|---|---|---|---|
| **Head cook** | 1 | High `ambition`, low `laziness` | High `socialness` | High `laziness` + high `temper` |
| **Line cook** | 3 | Moderate `ambition`, low `laziness` | High `temper` | High `temper` + high `laziness` |
| **Prep cook** | 2 | Low `ambition`, low `laziness` | High `ambition` | High `ambition` + high `temper` |
| **Dishwasher** | 2 | No strong fit | High `ambition` | High `ambition` + low `laziness` + high `temper` |
| **Bartender** | 3 | High `socialness`, low `temper` | High `greed` | High `greed` + high `temper` |

Minimum 11 rats to fully staff. Understaffing leaves pods incomplete — pod performance calculations adjust accordingly.

### Job Skills

Each rat has a `job_skills` dictionary, one value per job, 0-10. Skills are permanent once learned — they do not decay.

**On generation:** Each job skill is rolled randomly, seeded by personality fit. High-ambition rats roll higher on head cook and line cook. High-socialness rats roll higher on bartender.

**During play:** Skill increments slowly while actively working that job.

### Job Performance

```
performance = job_skill x personality_fit_modifier x current_state_modifier
```

- `personality_fit_modifier` — how well the rat's stats match the job's key attributes
- `current_state_modifier` — reduced by negative needs, stress, inebriation, low health, and burnout

---

## Rat-to-Rat Interactions

Rats affect each other through proximity. Interactions are not scripted — they emerge from the broadcast/response model.

### Camaraderie

Each rat stores its own camaraderie value toward every rat it has met, -100 to 100. Values are asymmetric — Rat A's feeling toward Rat B can differ from Rat B's toward Rat A. First interaction seeds the value near 0 with a slight positive bias.

**Changes over time:**
- Decays slowly without interaction
- Good or neutral interactions tick it up
- Bad interactions tick it down
- Passive stress from hostile pod-mates increases conflict probability, which risks bad interactions
- Radicalization creates a strong camaraderie spike among radicalized rats — shared cause builds solidarity fast
- Organizer removal has two outcomes depending on radicalization spread at time of intervention:
  - **Early removal** — movement fizzles, radicalization-built camaraderie weakens, rats drift back
  - **Late removal** — martyr effect. Radicalization spikes in already-radicalized rats, camaraderie among them strengthens, another susceptible rat may pick up the organizing role

### Social Broadcasts

When a rat has an unmet `social` need, it broadcasts like a location — other rats evaluate it in their action selection algorithm. Score is weighted by:
- Camaraderie toward the broadcasting rat
- `socialness` of both rats
- Distance
- Whether they share a pod
- Current need state of the recipient

Group activities (gambling, etc.) broadcast the same way. If another rat answers, they go together.

### Conflict

Hostile camaraderie between pod-mates generates passive stress. If one rat has `fighting` as a vice and camaraderie toward another rat is sufficiently negative, it may broadcast a fight. The recipient scores it:
- High `temper` + low `stimulation` or low `social` — more likely to accept
- Low `energy` or low `nutrition` — more likely to flee

If the recipient flees, a chase begins. Fight outcome feeds back into camaraderie — hostility deepens regardless of who wins. Fight reduces `health` of participants.

### Proximity Effects

- High-`socialness` rats increase social fulfillment for nearby rats during interaction
- Low-`socialness` rats contribute less to others' fulfillment and give less back
- A rat in rebellion with high `socialness` passively spreads stress to nearby rats
- Working physically adjacent to a friend (same pod, side by side) never counts toward repetition debuff — always registers as fresh

---

## Observability

Owner-facing signals are not a UI dashboard. They are a formalization of what the owner can visually observe — communicated through art and animation. All values below are either calculated per-tick or derived; nothing here is stored on the rat directly.

### Rat-Level Signals

| Signal | What it reflects |
|---|---|
| `mood` | Visible emotional state — driven by stress and need levels. A rat in rebellion actively suppresses this signal. |
| `health` | Visible physical condition — driven by the `health` stat. |

### Pod-Level Signals

Calculated each tick from member rats. Not stored.

| Signal | What it reflects |
|---|---|
| `pod_performance` | Functional output of the pod. Averaged from individual performance values modified by group dynamics. |
| `pod_indicators` | One or two sentences describing the pod vibe. Deliberately ambiguous. Backed by visual signals. |

### Colony-Level Signals

Calculated from all rats. Only `rat_count` is stored.

| Signal | What it reflects |
|---|---|
| `rat_count` | Total number of rats in the colony. |
| `colony_relationship` | Simple average of all individual owner relationship scores. |
| `appetite` | Consumption rate of food and vices from the shared colony pool. |

---

## Open Questions

- Does the owner get any direct signal about colony relationship, or does he infer it from behavior?
- Rebellion contagion threshold: is it purely socialness-gated, or does colony relationship also make rats susceptible?
- Rat economy: does the owner pay rats in currency, or is the deal purely room and board?
- How is the activity space rendered? Is it a separate screen, an off-screen abstraction with UI indicators, or something else?
