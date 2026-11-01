---
name: verifying-content-against-the-loader
description: Cheapest real check that an assets/data edit loads — build a JsonContentSource over the actual directory — plus the Windows classpath details that make the throwaway program run at all
metadata:
  type: project
---

Learned adding the three `arc` entries to `assets/data/trajectories.json` (phase 11c, #163). Extends
the live-run paragraph in [[wave-migration-mechanics]].

**The strongest cheap check on a content edit is constructing the real `JsonContentSource` over the
real directory, not parsing the one file that changed.** `new JsonContentSource(new FileHandle(new
File("assets/data")), "level-01")` loads `balance`, `trajectories`, `formations`, `enemies`,
`attachments`, `waves` and the level in one call and throws naming the file and id if any of them is
wrong. Reflecting into a single private parse method only proves the edited entry parses; it says
nothing about whether the edit broke something that reads it downstream. Do the whole-set load — it
is the same two commands and it is the check that would actually catch a bad id.

**`game/` has no test source set** (`game/build.gradle.kts` declares no `testImplementation`), so
there is no place to put this as a JUnit test. A throwaway `main` compiled into the scratchpad is the
only form available, and that is a limitation of the module, not a shortcut being taken.

**Two Windows details that make the throwaway program fail confusingly:**

- The classpath separator is `;`, not `:`. With `:` the whole thing is read as one nonsense path.
- `find ~/.gradle/caches -name "gdx-*.jar"` under Git Bash prints a POSIX path (`/c/Users/...`) that
  the Windows JVM cannot resolve. It fails as `NoClassDefFoundError` on a libGDX class — which reads
  like a missing dependency, not a malformed path. Rewrite the prefix to `C:/` before passing it to
  `javac`/`java`. Relative paths into the worktree (`game/build/classes/java/main`) are fine.

**Content that nothing points at is a legitimate deliverable.** A trajectory entry no wave selects
still loads and resolves; it is not dead content when the mechanism that selects it is a separate,
later issue. Say so plainly in the status fragment rather than letting the reader assume the game
already flies it.

**A third Windows detail, 03/09/2026:** Git Bash mangles a multi-entry `-cp` argument even when it is
quoted, and `javac` then reports `package com.badlogic.gdx.files does not exist` as if the jar were
missing. `export MSYS2_ARG_CONV_EXCL='*'` before the `javac`/`java` calls fixes it. Same symptom as
the POSIX-path trap above, different cause, so check both.

**A fourth, 04/09/2026 (phase 11i, #271):** `MSYS2_ARG_CONV_EXCL='*'` did *not* fix it that day —
the same `package com.badlogic.gdx.files does not exist` persisted through both an absolute `C:/`
path and a jar copied into the scratchpad, while `core.jar` on the same `-cp` string resolved fine.
What worked was a **javac/java argument file**: write `-cp "a.jar;b.jar;c.jar"` (and `-d ...`) into a
text file and pass `@path/to/args.txt`. The shell never sees the `;` list at all. Reach for the
argfile first; it is one extra line and it removes the whole class of problem.
