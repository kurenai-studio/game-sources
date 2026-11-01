# Phase 10a — decisions

Tasks 3 and 4 of [`plan.md`](plan.md). Both are documentation defects that have a code fix, and the
10 group does not change production code, so what is here is the decision and the handover.

---

## D1 — `rngcheck` is a real check in a temporary place, and it stays there until it is moved

Resolves [#5](https://github.com/LuchoC-Dev/little-spaceship/issues/5).

### The contradiction

`docs/plan/01-foundations/status.md` calls `spikes/web-viability/rngcheck/` the re-runnable check
that `Rng` produces the same stream on both runtimes:

> The check lives in `spikes/web-viability/rngcheck/` and can be re-run whenever the algorithm is
> touched.

`docs/STATUS.md` says of the same directory's parent:

> a throwaway prototype that validated the platform. Not the base of the game. It can be deleted
> once it stops being useful.

Both cannot be true. Something you are told to re-run is not something you may delete.

### What was actually checked, 26/08/2026

- `spikes/web-viability/rngcheck/` holds `Main.java` and **its own copy of `Rng.java`**, under a
  `rngcheck` package.
- The copy is **currently identical** to `core/…/domain/rng/Rng.java`, modulo package and imports.
  Diffed, not assumed.
- Nothing enforces that. `Rng` has not changed since phase 01, which is the only reason the copy has
  not drifted, and a drifted copy would make the parity check pass while proving nothing — which is
  exactly what #5 warned about.
- Nothing runs it. It is a manual Gradle invocation in a directory the build of the real project does
  not include.

So the check is real, the risk it guards is real — invariant 2 fails silently, and it fails silently
*per runtime* — and the thing standing between the project and that guarantee is somebody
remembering to update a copy and run a command.

### The decision

**The check is kept, moved, and rebuilt around the real class. The spike is not deletable until it
is.**

1. **It moves into the project's own build**, as a verification task that compiles
   `dev.luchoc.littlespaceship.core.domain.rng.Rng` **itself** through TeaVM and runs it on Node.
   No copy. The copy is the defect, not the location.
2. **It asserts the same three pinned sequences `RngTest` already asserts** — the integer stream, the
   float stream and the zero-seed stream — rather than a second set of expectations that can drift
   from the first. One source of truth for what the generator produces, checked on two runtimes.
3. **It does not go into the per-push CI job.** Installing a Node toolchain and running a TeaVM
   compile on every push buys nothing on the days `Rng` is untouched, and `Rng` has been untouched for
   the entire life of the project. It runs on demand and it is named in `RngTest`'s javadoc, so the
   person changing the algorithm meets it at the moment they change it.
4. **Until it exists, `spikes/web-viability/` is not deletable**, and `docs/STATUS.md` says so instead
   of offering the spike for deletion unconditionally.

### Why not the alternatives

**Delete the check and keep the argument.** The argument is good — `Rng` is 32-bit xorshift, only xor
and shifts, and Java's integer semantics are exact — but it is an argument, and the project's own rule
is that the technical parts were *measured, not assumed*. It was measured once. The cost of keeping
that true is one Gradle task.

**Carve the exception into `STATUS.md` and stop there.** That makes the documents agree, which is this
phase's job, and leaves a check nobody can trust: a hand-maintained copy of a class, run by hand, by
whoever remembers. It resolves the contradiction by writing down the weaker of the two claims. Taken
as the *interim* — the spike is not deletable today — but not as the answer.

**Copy `rngcheck` into `core/src/test` as it stands.** Moves the file without fixing the copy. The
whole value of the move is that the thing under test becomes the thing that ships.

### Handover

Recorded as [#52](https://github.com/LuchoC-Dev/little-spaceship/issues/52) for the 11 group.
`docs/plan/01-foundations/status.md` and `docs/STATUS.md` are corrected in this phase so they agree
today, which is what #5 asked for.

---

## D2 — `ForbiddenApiTest` strips comments and string literals before searching

Resolves the decision half of [#3](https://github.com/LuchoC-Dev/little-spaceship/issues/3).

### What is wrong

`ForbiddenApiTest` greps the raw text of every file in `core`, so **no comment in `core` may spell out
a forbidden API name**. The price is paid by the most safety-critical documentation in the project:
`Rng.java` has to describe the two APIs it exists to avoid obliquely — "neither the static helper in
`Math` nor the generator class in `java.util`" — and then spend three more lines explaining why it is
being coy.

Phase 01 recorded the raw-text search as deliberate: "The check is a plain text search, on purpose, so
it finds exactly what a reviewer greps by hand."

### The decision

**Strip comments and string literals before searching, and rewrite `Rng`'s javadoc in plain words.**

The end anyone wants is *no forbidden call in `core`*. Raw-text grep is a means to it, and it is a
means with a standing cost that compounds: every future file in `core` that needs to explain why it
avoids something has to avoid naming it. That is a rule which degrades documentation by construction,
and the reason is invisible to whoever writes the next file.

Phase 01's justification — "it finds exactly what a reviewer greps by hand" — is the part being given
up, and it is worth less than it sounds. A reviewer greps to find candidates and then reads them; a
test that cannot tell a call from a comment is not reproducing that, it is reproducing the first half
of it.

**This phase is the evidence for the change.** Documentation that has to talk around the thing it is
about is documentation that will be misread, and 35 findings' worth of misreading is what this phase
has just spent a day on.

### Scope, and what must not be lost

- Strip `//`, `/* */` and string literals in `JavaSource`, next to the existing `containsToken`.
  Roughly ten lines.
- **The check must still fail on a real call.** Add a test that plants one in a fixture and asserts
  the check catches it — otherwise the stripping is exactly the kind of change that quietly turns a
  green check into a check of nothing, which is defect pattern 1 in the reviewer's own catalogue.
- Then rewrite `Rng`'s class javadoc to name `Math.random()` and `java.util.Random` outright, and
  delete the three lines explaining the coyness.

### Handover

[#53](https://github.com/LuchoC-Dev/little-spaceship/issues/53) for the 11 group.

---

## D3 — the criterion is reworded, and `PublicContractTest` states its own scope

Resolves the decision half of [#4](https://github.com/LuchoC-Dev/little-spaceship/issues/4).

### What is wrong

The phase 01 acceptance criterion reads "No public type in `core` exposes an implementation class",
and PR #2 records it as proven by `PublicContractTest`. The test inspects `core.port` and
`core.application` and never `core.domain`, where `World` publicly returns `ComponentStore`,
`EntityRegistry`, `Rng` and `GameEventQueue`.

**The design is not wrong and the invariant holds in substance.** Systems live in the domain and must
mutate the world; Java without JPMS cannot express "public within `core`"; and `game` can never reach
a running `World`, because `Simulation.world()` is package-private and `view()` returns a `WorldView`.

What does not hold is the claim. #4 offers two ways out, and they are not exclusive.

### The decision

**Both.** Reword the criterion *and* make the test state its scope.

1. **The criterion becomes:** *no type of `core` reachable from `game` exposes an implementation
   class.* That is the invariant that was always meant, it is the one `CLAUDE.md`'s fourth invariant
   states ("No module exposes concrete classes to another"), and unlike the old wording it is true.
2. **`PublicContractTest` says so in its own javadoc** — which packages it inspects, that
   `core.domain` is excluded, and the three facts that make the exclusion safe. A test whose scope
   lives only in its package filter is a test whose scope nobody re-reads.

Rewording alone would leave the next reader to rediscover why the domain is skipped by reading the
filter. Documenting alone would leave a criterion in `docs/plan/01-foundations/plan.md` that the test
does not prove. The pair costs a javadoc and a sentence.

**The two smaller softnesses #4 names are in scope with it**, because they are the same failure —
a check narrower than it reads:

- `isAllowed` accepts all of `java.util.*`, so a public method returning `ArrayList` passes.
  Narrow it to the interfaces that are legitimately part of a contract.
- `LayerDependencyTest`'s `MACHINERY` list names `domain.World` by hand, so a new class directly under
  `core.domain` would not be caught. Make it structural.

### Not done in this phase

`docs/planning/12-architecture.md` said "an architecture test verifies … that no public type of `core`
exposes implementation classes", repeating the overstated claim. **That sentence was corrected on
26/08/2026** as part of task 1: it now states the reachable-from-`game` rule, says what
`PublicContractTest` actually inspects, and links #4. The criterion in
`docs/plan/01-foundations/plan.md` is left alone — a phase's `plan.md` does not change to reflect
what happened after it, and #4 carries the rewording.

### Handover

[#54](https://github.com/LuchoC-Dev/little-spaceship/issues/54) for the 11 group.
