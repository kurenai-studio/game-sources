# entities/rat/systems/decisions/

Utility-AI decision scoring for "which location should this rat go to."

- `LocationChoice` — static `choose_destination_index(urgencies: NeedUrgencyValues, options:
  Array[LocationChoiceOption]) -> int`. Returns the winning option index,
  or `-1` if no option has active appeal. Equal scores keep the first option.
  Scores across all five needs: for each need where `option.pull[need] > 0`,
  combine urgency with `option.pull.get_normalized_value(need)`.
  Numeric `employment_pressure` is added after combining need scores.

  Active-axis scores use an equal-weight power mean with `p = 3`; see
  `docs/ALGORITHM_RESEARCH.md` for the design and observed crossover.

  RatManager builds ordered `LocationChoiceOption` copies (`../../data/decisions/`)
  containing appeal, title, and employment pressure. Rat supplies copied
  `Needs` to `NeedSystem.calculate_need_urgencies()`, then passes the returned
  `NeedUrgencyValues` (`../../data/needs/`) to location choice.
  The evaluator receives no Rat, Job, or Location nodes. Rat maps the chosen
  index to the original location and handles travel.

  A veto mechanism (hard override for genuine crisis needs, regardless of
  score) was deliberately deferred rather than built — see
  `docs/RAT_TURING_COMPLETE.md`.
- `NeedUrgencies` / `NeedUrgency` in `../../config/needs/` — per-need `Curve` resources mapping a raw
  need value to a normalized `0..1` urgency. All five curves are authored in
  `../../config/needs/need_urgencies.tres` (`nutrition`, `energy`, `social`, `stimulation`,
  `vice_satisfaction`), and `NeedSystem` samples all five for decisions.
  `LocationChoice` has no curve configuration or sampling logic. `NeedUrgencies`
  also calculates the stress-specific effective average urgency, sampling a
  need being fulfilled at its maximum value without changing its stored need or
  location-choice urgency.
