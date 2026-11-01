---
name: teavm-node-runner-is-hand-written
description: generateJavaScript produces a CommonJS module, never a way to invoke it on Node — the run.cjs a spike module needs is a committed file, not a Gradle-generated artifact.
metadata:
  type: project
---

TeaVM's `js {}` block (raw `org.teavm` plugin, `moduleType.set(JSModuleType.COMMON_JS)`) makes
`generateJavaScript` emit a module exporting `main`, e.g. `exports.main = $rt_export_main`. Nothing
in the plugin writes a runner that calls it — `node build/generated/teavm/js/whatever.js` does
nothing by itself.

`spikes/web-viability/threadprobe/run.cjs` is the one tracked example: a hand-written, committed file
(`require('./probe.js'); m.main([]);`) that the developer ran manually, `cd`'d into the generated
output directory alongside it. Every other spike module (`rngcheck`, `collisionbench`, `langprobe`)
had a `run.cjs` sitting in `build/generated/teavm/js/` too, but `git ls-files` shows none of those are
tracked — `build/` is gitignored, so those were leftover artifacts from a manual run at some point in
the past, not something a fresh `./gradlew generateJavaScript` reproduces. Trusting one of those as
"this is what the task produces" would have been wrong; only `git ls-files` settled it.

**How to apply:** when wiring a Gradle task around a TeaVM/Node module (a new spike, or the
[[rng-parity-task-wiring]] pattern), write and commit your own `run.cjs`, and check with
`git ls-files <dir>` whether an existing one you're tempted to copy is actually tracked before
trusting its behaviour as reproducible.
