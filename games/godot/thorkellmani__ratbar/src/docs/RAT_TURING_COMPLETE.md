# Rat-Turing Complete

Definition of Done for the simulation's decision-making — general
behavioral properties, not test cases with numbers. Accumulates across the
whole project, unlike an active sprint's per-task scenarios. An
entry stays open until observed in the running sim, not until the formula
behind it is implemented.

---

## Action selection

- [ ] A starving rat prioritizes food over everything else.
- [ ] A content rat leans toward social and stimulation over other needs.
- [ ] Two needs in crisis at once resolve to the more dire one.
- [ ] A location offering nothing for a need is never chosen for that need.
- [ ] An unassigned rat feels no job pressure toward any location.
- [ ] A tired rat starts resting before it's fully drained.
- [ ] A deprived rat reaches for vice easily, but not over social/fun when content.

## Job / location behavior

- [ ] Working a job feels distinct from idling at the same location.
- [ ] Reassigning a job's stations doesn't change how those stations behave for other rats.
- [ ] Arrival at a current assigned station starts work; other arrivals leave the rat idle. Assignment changes during travel are respected.

## Deliberately not on this list yet

Addiction/resistance, job skills, hard crisis overrides — all
deferred on purpose, not abandoned. Add an entry once the system it depends
on actually exists.
