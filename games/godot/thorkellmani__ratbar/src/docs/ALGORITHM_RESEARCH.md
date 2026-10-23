# Algorithm Research — Combining Need Axes into a Location Score

This documents the research behind `NeedsEvaluator`'s combination formula — how multiple active need axes at one location get blended into a single score. The power mean is a design choice supported by useful mathematical properties and a recorded playtest, not a uniquely required solution. The corrections below distinguish those properties from earlier, overstated research conclusions.

Implementation mapping after commit `f376ce5`: the former NeedsEvaluator is
removed. `NeedSystem.calculate_need_urgencies()` samples copied needs, and
`LocationChoice.choose_destination_index()` scores copied LocationChoiceOption
values. Historical research and playtest references below retain the earlier name.

## The problem that started this

A location can have several active need axes (e.g. Pantry: `nutrition`, `energy`). An equal-weight arithmetic mean gives each active axis the same marginal influence. Concrete example, assuming full appeal on both axes: a rat near-starving (`nutrition` urgency `≈1.0`) but well-rested (`energy` urgency `≈0.09`) at Pantry — the plain average blends these to `0.545`, diluting the starvation signal with an irrelevant one. A competing location with moderate values on all its active axes could beat it because averaging doesn't let one screaming need dominate.

Explicitly out of scope: a hard veto/lexicographic override ("if starving, don't even consider anything else") — considered and deliberately deferred earlier this sprint as too blunt. We wanted something inside the *soft* scoring math.

## Pass 1 — game AI specifically (insufficient on its own)

Checked Dave Mark's IAUS (Infinite Axis Utility System) directly, since `NeedsEvaluator` is explicitly built on it.

**Confirmed** (Mike Lewis, *Game AI Pro 3* ch. 13, the shipped *Guild Wars 2* IAUS): considerations are combined by **multiplication**, not averaging. The "compensated average" formula we'd built (`M = 1-1/k`, `C = μ + (1-μ)Mμ`) is Dave Mark's own patch for the *count bias* multiplication introduces (multiplying more sub-1 numbers together shrinks the result, unfairly punishing options with more active considerations) — it was designed to correct a product, and we'd been applying it to a plain arithmetic mean instead, which doesn't have that particular bias to correct.

**Not found anywhere in IAUS:** any documented mechanism for one consideration to dynamically outweigh another based on their *relative* current values. IAUS's only documented lever for "importance" is the shape of each consideration's own response curve — which can't express "nutrition should matter more *because* energy happens to be low right now," since curves only ever look at their own axis in isolation.

**The actual shipped industry answer** to "a starving Sim shouldn't bother scoring Fun" (David Graham, *Game AI Pro* ch. 9; Kevin Dill's dual-utility bucketing, *Game AI Pro 2* ch. 3) is **lexicographic bucketing** — a hard tier system, i.e. exactly the veto we'd already ruled out. Worth knowing that's not a workaround, it's the canonical answer game AI actually ships — we're choosing to solve this differently on purpose, not because we missed the standard technique.

This pass produced a plausible-sounding recommendation (a power mean) but wasn't grounded well enough — game AI's own literature doesn't document a rigorous answer to this, so a second, wider pass was needed before trusting any conclusion.

## Pass 2 — cross-disciplinary aggregation research

Reframed the question as a general aggregation problem, not a game-AI one: *given several `0..1` values representing current importance, and an active subset relevant to one option, what proven method lets an extreme value dominate mild ones, tunably, without a hard cutoff?* Surveyed decision theory/MCDA, welfare economics, fuzzy logic, control theory, and reinforcement learning as primary sources, checking game AI's practice against those conclusions rather than starting from it.

### What the characterization theorem actually establishes

**Kolmogorov/Nagumo.** The characterization concerns a family of means satisfying continuity, symmetry, strict increase, reflexivity/idempotence, **and decomposability**. Under those assumptions, the family is quasi-arithmetic: `M(x) = f⁻¹(mean(f(x)))`. Transform every input through a continuous, strictly monotone function `f`, average the transformed values, then undo the transform. The earlier version of this document omitted decomposability; the remaining four properties alone do not establish uniqueness. See [Marichal's characterization paper](https://orbilu.uni.lu/handle/10993/1766).

**Decomposability and internality are compatible.** Decomposability allows a subgroup to be replaced by copies of its own mean without changing the overall result. Equivalently, subgroup means can be combined while preserving subgroup sizes/weights. The arithmetic mean and power means satisfy this and remain within `[min, max]`. Repeatedly combining two means while discarding subgroup sizes is a different operation and need not give the same answer. The earlier claim that these properties were incompatible was incorrect.

Internality guarantees bounds, not immunity to changes in the active-axis set. Multiplication of values in `0..1` can fall below the smallest input and shrinks when additional sub-1 factors are added. That makes it a poor match for our chosen averaging semantics; it does not disqualify multiplication for other utility models, such as combining conditions that must all hold.

### The two real candidates within that family

- **Power mean**: `M_p = (Σwᵢxᵢᵖ/Σwᵢ)^(1/p)`, for nonnegative inputs, positive fixed weights, and `p > 0`. `p=1` is the weighted arithmetic mean; `p→∞` approaches the largest positively weighted input. For `M_p > 0`, `∂M_p/∂xᵢ = (wᵢ/Σw) × xᵢ^(p-1) × M_p^(1-p)`. Within one evaluation, relative marginal influence is therefore proportional to `wᵢ × xᵢ^(p-1)`. This supports stronger emphasis on larger inputs, but does not remove the denominator penalty when a new weak axis is added. In the implementation, each input is urgency **times appeal**, not urgency alone.
- **Exponential/Kolm mean (mellowmax)**: `ln(mean(exp(κx)))/κ`, with the arithmetic mean as the limit at `κ=0`; negative/positive `κ` emphasize smaller/larger inputs. [Asadi & Littman (ICML 2017)](https://proceedings.mlr.press/v70/asadi17a.html) establish non-expansion and convergence benefits for learning and planning. Their Boltzmann-operator counterexamples concern iterative reinforcement-learning/planning settings. They do not by themselves prove Boltzmann aggregation unsuitable for Ratbar's direct location scoring.

### Real-world validation

**Dujmović's Graded Logic / LSP method** — a ~50-year-old, commercially-deployed MCDA technique — is built around exactly the power mean parameterized by an "orness" dial; `p>1` is literally named "soft partial disjunction" in that literature. **Welfare economics** (Atkinson's inequality measure; prioritarianism) uses the mirror-image family for "how much should one person's/criterion's need outweigh others" — though economics only endorses the `p≤1` half on ethical grounds (the Pigou–Dalton transfer principle); the `p>1` extension we want is a reasonable mathematical mirror, not something welfare economics itself endorses — flagged as inference, not citation.

### Rejected alternatives, with real reasons

| Method | Why rejected |
|---|---|
| Plain multiplication (IAUS's own base mechanic) | Not internal/count-stable — the exact bias the compensation patch was fighting |
| Boltzmann softmax (`Σxᵢeᵏˣⁱ/Σeᵏˣⁱ`) | Not selected. The cited convergence problems concern learning/planning operators; applicability to this direct scorer was not established |
| Plain log-sum-exp | Overshoots the true max by an amount that grows with how many axes are active |
| OWA operators | Valid, but the weight vector must be regenerated per active-axis-count — more machinery for the same result |
| WOWA, Choquet integral | Need far more parameters (`n(n+1)/2` or worse) than we have data to justify |
| Benefit-accumulating operators | Some are not idempotent and reward additional benefits. That differs from the chosen mean semantics; whether extra benefits should raise a score is a design decision, not a mathematical error |
| Lexicographic bucketing/tiers | The actual shipped game-AI answer, but it's the hard veto we already deliberately deferred |

## Decision

**Use a power mean, `p > 1`, replacing the compensated average entirely.** The compensation formula (`M`, `makeUp`) gets dropped. The power mean is internal and idempotent: equal-valued inputs return the same value regardless of their count. It is not invariant to adding different-valued axes. These are useful properties for the chosen design, not a proof that this is the uniquely correct scoring model.

```
general weighted power mean = (Σ(wᵢ × xᵢᵖ) / Σwᵢ) ^ (1/p)

current implementation:
A = axes where location.pull[axis] > 0
xᵢ = curve_sampled_urgencyᵢ × normalized_location_pullᵢ
need_score = (Σᵢ∈A xᵢᵖ / |A|) ^ (1/p)
location_score = need_score + applicable_employment_pressure
```

The evaluator uses **equal aggregation weights** (`wᵢ = 1`). Location pull scales each input before exponentiation; it is not the external weight `wᵢ` in the general formula. Current `LocationPull` values range from `0..7`, normalized to `0..1`; zero-pull axes are excluded. Locations with no positive-pull axes are skipped, including before employment pressure is added. Employment pressure sits outside the mean, so the final score need not remain in `0..1`.

`p` is the feel-tuning parameter, currently the code constant `SCORING_TUNING_CONSTANT = 3` (not an Inspector export). With the same inputs and active-axis set, `p=1` gives their arithmetic mean, providing an A/B baseline.

Chosen over mellowmax because: our domain is always `0..1` (no negative inputs, no need to ever flip toward worst-case dominance), performance is a non-concern at this scale (six locations, five needs, run occasionally), and power mean is far simpler to implement correctly (`pow()` and one division vs. `exp`/`ln` plus a numerical safeguard near `κ=0`) — mellowmax's extra robustness solves problems we don't actually have.

## Implemented and verified

`LocationChoice` now uses the equal-weight power mean of urgency × appeal (`SCORING_TUNING_CONSTANT = 3`), preserving the formula previously implemented in `NeedsEvaluator.evaluate()`. Compensated-average code remains removed. The recorded live nutrition-slide test found that a rat assigned Head Chef held work over Pantry all the way to `nutrition = -45`, then Pantry overtook it at `-52` and held/widened the lead through `-72` — a working starvation crossover, which the old compensated-average formula never produced (work won even at full starvation, `-100`). `EMPLOYMENT_PRESSURE = 0.35` held up in that test; no re-tuning was needed there. This validates that tested configuration, not a universal guarantee that starvation wins for every location set, pull assignment, or employment-pressure value.

One known, real limitation surfaced during this verification pass — not a bug, a mathematical property of the formula:

**Idempotence (equal-valued axes don't get punished for count) is guaranteed, but a genuinely weak *unequal* axis still taxes a location's score just for being counted.** Example: one axis at `0.9` alone scores `0.9`. Add one weak axis at `0.1` alongside it (`k=2`): `((0.9³ + 0.1³)/2)^(1/3) ≈ 0.715` — a real ~20% drop, even though the weak axis barely contributed to the sum. The weak axis is nearly free in the numerator but fully counted in the denominator. This showed up concretely: Pantry's `energy` axis (irrelevant for a well-rested rat) measurably dragged down its `nutrition`-crisis score, even at `-72`.

This is a central semantic tradeoff: the score measures the strength of a location's active reasons using a mean biased toward the strongest, rather than accumulating all benefits. Adding a small positive benefit can lower the score. Hand-authoring discipline limits the effect but does not remove it; acceptability needs behavioral testing.

**Practical mitigation, adopted now:** be genuinely disciplined about which axes actually deserve a nonzero `pull` at a location — a location with fewer, honestly-relevant axes will often outscore one with marginal axes tacked on. The `0` (excluded) vs `1` (barely real, but counted) boundary from earlier this sprint now carries more real weight than it did under the compensated average, which had a fairness boost softening exactly this tax.

**Deferred idea, not researched or built:** dynamically excluding an axis from `k` (not just from the location's own `pull`) based on whether the need is currently a "practical consideration" for *this* rat right now — e.g. don't let `energy` count against Pantry at all while the rat isn't meaningfully tired. This would directly fix the tax above, but it reintroduces a hard threshold/cutoff (same category of mechanism as the deliberately-deferred veto, just per-axis instead of per-location), with a real discontinuity risk right at the threshold boundary. A *soft*, continuous version (an axis's practical weight scaling smoothly with its own urgency, rather than a hard in/out cutoff) might exist, but hasn't been researched — don't build this on a hunch, given how much this sprint cost us from doing exactly that with earlier formula ideas. Revisit only if the hand-authoring mitigation above proves insufficient in actual play.

## Honesty on confidence

The characterization and reinforcement-learning claims above link their sources and state the scope of those results. The derivative, bounds, and worked examples can be checked directly from the formula. The implementation mapping was checked against `entities/rat/systems/decisions/location_choice.gd`, `entities/rat/systems/needs/need_system.gd`, and `entities/location/location_pull.gd`; the playtest results remain historical observations, not a new test run. External research was not reverified during this documentation update.

The earlier research's IAUS, bucketing, LSP, and welfare-economics summaries are background claims, not independently reverified by this correction. They do not establish that the selected formula is necessary or best for Ratbar. In particular, negligible axis-count effects cannot be assumed from the small number of needs: the two-axis example already shows a substantial effect. The defensible conclusion is that the power mean is a simple, tunable candidate whose behavioral tradeoffs must remain explicit.
