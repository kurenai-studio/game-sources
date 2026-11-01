---
name: filehandle-list-avoided-for-teavm
description: Why JsonContentSource keys a level by an explicit id parameter instead of enumerating level-*.json files with FileHandle#list()
metadata:
  type: project
---

When turning `JsonContentSource`'s hardcoded `LEVEL_ID` into something keyed by id (issue #87,
phase 11b task 5), the tempting shortcut was `dataDir.list()` to discover every `level-*.json` file
and load them all eagerly. Didn't do it: `com.badlogic.gdx.files.FileHandle#list()` has no reliable
answer once TeaVM packages assets for the web target — the browser has no real filesystem to
enumerate, only whatever asset list TeaVM baked in at build time, and nothing in this codebase
(`git grep -rn "\.list()"` across `game/`, `web/`, `desktop/`) uses it anywhere, which is itself a
signal the project has been avoiding it. Confirmed no other call site relies on it as of 28/08/2026.

**How to apply:** a level (or any content kind) stays loaded by an id a caller supplies —
`dataDir.child(levelId + ".json")` — never by scanning the directory for what happens to be there.
If a future phase needs "load every level the game ships," the id list itself should be data (e.g. an
array in a manifest file) that `JsonReader`/`JsonValue` parses, not a filesystem walk.

See [[libgdx-jsonvalue-key-iteration]] for the throwaway-classpath verification technique used to
confirm the constructor's new error path (unknown id) names the file it looked for, with no test
source set in `game` yet.
