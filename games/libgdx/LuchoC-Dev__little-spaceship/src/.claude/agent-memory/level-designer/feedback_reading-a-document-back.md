---
name: reading-a-document-back
description: How to test a generated document by designing from it without fooling yourself, and how to break and restore generated content safely
metadata:
  type: feedback
---

**When asked to prove a document is enough to design from, grep the document for every token you
relied on. Do not grade yourself on whether you managed to write the file.**

**Why:** in phase 11d task 4 I wrote a whole `level-02.json` from `docs/levels/level-01.md` and it came
out almost entirely correct — because I had written task 1 of the same phase with `assets/data/` open
and remembered every JSON key. The document contains none of them. The one key memory did not cover
(`"id"` at the top of a level file, which does not exist) was the one that would have failed the load.
Succeeding at the exercise proved nothing; the greps proved everything.

**How to apply:** after writing the artefact, list every fact it depends on — key names, units,
defaults, closed sets, semantics like "offset is measured from the previous placement's end" — and run
`grep -n` for each against the document. What is absent is the finding, and it is findable in a minute.
The same trick works on any "is this enough to work from" question, not just level documents.

---

**Breaking generated content to test a check means restoring two things, not one.**

`node tools/build-level-docs.js` rewrites `docs/levels/level-01.md` in place, so `git checkout
assets/data/waves.json` alone leaves the generated document stale and `--check` red. Restore the
source *and* the output, then confirm with `node tools/build-level-docs.js --check` (prints
`unchanged  docs/levels/level-01.md`, exit 0) rather than with `git status` alone.

Related: [[verifying-content-against-the-loader]], [[level-values-that-live-in-code]].
