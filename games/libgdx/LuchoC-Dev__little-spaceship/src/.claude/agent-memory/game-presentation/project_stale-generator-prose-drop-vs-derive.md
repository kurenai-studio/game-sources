---
name: stale-generator-prose-drop-vs-derive
description: Deciding whether to derive or drop a generator's hardcoded advice sentence once the content it described is deleted (#328); how to tell a real duplicate bug apart from the one an issue names.
metadata:
  type: project
---

`tools/build-level-docs.js` had a class of bug, seen three times in phase 11k (#310, #322, #328):
static prose inside the generator, printed unconditionally or gated by a condition, that stops
being true when content changes underneath it. #328 was the third and closing instance: three
literal strings named `veer-left`/`veer-right`/`swoop`, trajectories phase 11k's task 6 had already
deleted.

**Drop beat derive here**, and the reason generalises: the old advice's numeric threshold
(`atX >= 0.75` / `atX <= 0.25`) was a property of the *specific* deleted arcs' own drift magnitude
and duration, not a universal constant. A generic "spawn on the side you drift away from" rule needs
a per-shape threshold derived from that shape's own swept extent, and the generator already prints a
per-spawn finding with the real numbers (swept min..max, seconds, percentage outside) whenever a
shape's swept extent is mostly off screen. That existing finding already carried the information the
static addendum was for. When a generic mechanism already emits the specific fact, deleting the
static generalization over it is safer than inventing a new generalization to replace it — especially
under a project rule (invariant 6, and this phase's own running theme) against asserting a constraint
without deriving it for the shapes that actually exist now.

**A fourth spot existed that the issue never named**: the same "veer" literal strings were also
hardcoded inside a *dynamic* per-spawn finding (a template string built from a real computed
condition — `t.kind === 'arc' && vx sign` vs `atX`), not just in static prose. It happened to be
silent on current content (only one arc pair exists today and it doesn't cross the trigger
threshold), which is exactly why an issue built from `grep -c` over the content file missed it — the
grep only proves an id string is gone from *content*, not that the generator's *code* never embeds
it. Worth an extra pass over the whole file for the deleted ids, not just the lines an issue quotes.

**What was correctly left alone**: an illustrative JSONC schema-example block in the same file (a
"here is the shape of a `constant`/`arc`/`path`/`speedOf` entry" printed example) used fictional ids
like `dive`, `slow-descent`, `dive-fast` as syntax illustrations, unrelated to real content. These
survive a naive `grep` for deleted ids too, but they're not a factual claim about
`assets/data/trajectories.json` — they're teaching JSON shape. Don't conflate "this string matches a
deleted id" with "this line makes a claim that is now false"; the acceptance criterion in the issue
was about the latter.
