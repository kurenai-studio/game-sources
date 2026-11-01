---
name: rng-parity-task-wiring
description: how the cross-runtime Rng parity check (#52) is wired as a Gradle task in :rngparity, and how to confirm a new subproject stays out of the default `build`.
metadata:
  type: project
---

The `:rngparity` subproject (phase 11a, #52) compiles the real `core` `Rng` — no copy — through the
JVM and through TeaVM/Node, and checks both against the three sequences copied verbatim from
`RngTest` (`pinnedSequence`, `zeroSeed`, `pinnedFloatSequence`). Both runtimes are checked against
that one fixed expectation rather than against each other: comparing two runs against one shared
truth is the stronger check (either runtime alone can drift and get caught) and needs no plumbing to
move a value from one process to the other.

Three tasks: `runOnJvm` (`JavaExec`), `runOnNode` (`Exec`, depends on `generateJavaScript`, runs a
committed `run.cjs` — see [[teavm-node-runner-is-hand-written]]), `rngParityCheck` (depends on both).
Run with `./gradlew :rngparity:rngParityCheck`.

**Confirming a new TeaVM-applying subproject doesn't leak into `./gradlew build`:** don't just trust
that an Exec/JavaExec task is "obviously" not part of the `build` lifecycle — run `./gradlew clean
build` and grep the log for the plugin's task names (here, `generateJavaScript`,
`compileTeavmJava`). A `NO-SOURCE`/absence for those confirms the module's own `build` only compiles
and jars, it never invokes the toolchain. The `web` module's own comment on this ("Not part of the
`build` lifecycle task: the gdx-teavm plugin registers it separately") only tells you the *wrapper*
plugin behaves this way — worth re-verifying for the raw `org.teavm` plugin too, since it's a
different plugin with its own task graph, not an inherited guarantee.

**How to apply:** if a future phase needs another TeaVM-adjacent Gradle subproject outside `:core`,
this module and `spikes/web-viability/threadprobe` are the two working examples to copy from.
