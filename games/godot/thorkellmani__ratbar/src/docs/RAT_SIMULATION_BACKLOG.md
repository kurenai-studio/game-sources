# Rat Simulation Backlog

Unfinished work and ideas for future sprints. No sprint is active; order here
is not priority. Choose scope and settle design before turning an item into
sprint tasks with observable tests.

## Current baseline

Implemented: five needs and urgency curves, location appeal and physical effects,
job assignment and active work, staggered decisions, need decay, tiered stress,
owned rat state, and debug inspection/editing with pause and speed controls.
Latest completed sprint: [Rat Ownership and Debug Reliability](sprints/06-rat-ownership-and-debug-reliability.md)
(`f376ce5`, 2026-10-12). Tests and retrospective stay in the sprint records.

## Debug tooling

- [ ] Per-field breakdowns: stress details beside stress; decay, location, job,
  and net hourly rates beside each need. Settle layout and data contracts first.
- [ ] Inspect dynamic relationships and job skills when their gameplay needs it.

## Behavior and tuning

- [ ] Tune urgency curves, appeal, decay, modifiers, stress tiers, and work pressure
  through play. Track behavioral goals in [Rat-Turing Complete](RAT_TURING_COMPLETE.md).
- [ ] Personality and owner relationship influence location scoring.
- [ ] Stress influences choices: more vice appeal, less work appeal.
- [ ] Nearby rats influence location appeal through camaraderie and socialness.
- [ ] Define fulfillment events and stopping conditions before adding source
  history and repetition penalties; friends should soften social repetition.
- [ ] Observe switching before choosing inertia, primary-need locks, or variance.
- [ ] Revisit weak-axis dilution in scoring if tuning is insufficient; see
  [Algorithm Research](ALGORITHM_RESEARCH.md).
- [ ] Decide whether health, inebriation, and skill progression need scoring inputs.

## Jobs

- [ ] Job-skill storage, personality-weighted generation, and permanent progression.
- [ ] Assignment slot limits and pods.
- [ ] Individual performance from skill, personality fit, needs, stress, health,
  inebriation, and crisis; pod performance adds group dynamics.
- [ ] Job variety: prolonged assignment carries a stress cost.

## Relationships and social behavior

- [ ] Seed camaraderie on first meeting; good/bad interactions change it and
  separation slowly weakens it. Storage already exists.
- [ ] Social and group-activity broadcasts; personality-dependent fulfillment.
- [ ] Conflict, fight challenges, fleeing/chasing, health costs, and relationship
  consequences. Revisit the old dependence on per-vice identity.
- [ ] Owner relationship responds to met needs, job fit, deprivation, and overwork;
  expose the colony average as appropriate.
- [ ] Temporary owner-pressure spikes, with relationship/stress costs and
  escalating damage from overuse.

## Stress, vice, and crisis

- [ ] Temper and owner relationship influence stress accumulation.
- [ ] Direct vice stress relief, provision/withholding consequences, and inebriation
  effects; smoking near food affects quality. Vice currently has one need.
- [ ] Breaking-point roll: burnout or rebellion, weighted by personality,
  owner relationship, and overwork.
- [ ] Burnout: visible tells, locked stress, faster energy/vice depletion, reduced
  performance, rest/recovery, and fatal extra stress if forced to keep working.
- [ ] Death: remove rat references and apply the colony relationship consequence.
- [ ] Rebellion: conceal distress, organize while working, spread radicalization,
  escalate environmental tells, and resolve isolation/removal consequences.

## Player-facing systems

- [ ] Mood/health tells, pod indicators, colony relationship, and food/vice appetite.
- [ ] Crisis art/animations and environmental tells.
- [ ] Rat economy/currency, owner UI, health inspection/reviews, and Rat Man ending.

## Deferred technical work

- Movement composition; Rat keeps state ownership and arrival acceptance.
- Pathfinding; travel currently follows a straight line.
- Main-mediated clock routing, after agreeing the update/time contract.
- Shared bounds/clamping, after agreeing ownership and API.
- Snapshot allocation profiling at representative colony sizes.
- Investigate existing ObjectDB/two-resource shutdown leaks.
- Event bus for interrupts/broadcasts if a concrete feature needs it.
- Live tuning controls or modifier isolation when playtesting calls for them.

## Shelved

Per-vice identity, addiction/resistance, abstinence decay, and personality-weighted
vice generation. Reopen their design before adding tasks; no RatVice API exists.

See [Rat Simulation](RAT_SIMULATION.md) for feature detail,
[Pitch](PITCH.md) for direction, and [sprint records](sprints/) for history.
