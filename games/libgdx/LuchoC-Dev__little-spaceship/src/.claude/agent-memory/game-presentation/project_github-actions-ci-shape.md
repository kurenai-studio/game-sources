---
name: github-actions-ci-shape
description: What could and could not be verified before opening the CI PR, and why the workflow needs two separate run steps
metadata:
  type: project
---

`gdx_teavm_web_js_build` (registered by the gdx-teavm plugin) is **not** wired into the standard
`build` lifecycle task. `./gradlew build` green does not build the web target — it only compiles
and tests the JVM sources of every module, including `web`'s own `src/main` if it had one. A CI
workflow that wants to prove the web target builds needs an explicit second step
(`./gradlew gdx_teavm_web_js_build`), not just `build`. Confirmed by reading `web/build.gradle.kts`
and `./gradlew tasks --all | grep teavm`: the teavm tasks live under their own task group, not
under `assemble`/`check`.

`gradle/actions/setup-gradle@v4` is worth using over hand-rolled `actions/cache`: it caches both
the wrapper distribution and the dependency/build cache with zero extra config, and it is the
action Gradle itself documents as current (superseding the older `gradle-build-action`).

**A workflow that triggers on `push` has already run by the time you finish writing about it.**
Do not report a workflow as unverifiable-until-the-PR-opens: push the branch, then read
`gh run list` and `gh run view <id> --log-failed`. Reasoning about YAML is not evidence when the
evidence is one command away. Reporting "never run on a real runner" while four real runs sat in
the API is the mistake this entry exists to prevent.

**`gradlew` committed from Windows has mode `100644` and cannot be executed by a Linux runner.**
Every job dies at `./gradlew: Permission denied`, exit 126, in about 15 seconds, before Gradle is
ever reached. Fix is `git update-index --chmod=+x gradlew`, committed. This repository is developed
on Windows, so any future job on a Linux runner inherits the problem for any new script it adds.

Local runs can only ever be a weaker signal than the runner: the development machine has JDK 21 and
25 but no 17, which is the version the workflow pins.
