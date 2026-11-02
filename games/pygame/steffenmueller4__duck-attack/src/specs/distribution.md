# Distribution

## Purpose

Players get a ready-to-run app without installing Python; developers get fast feedback
on every change.

## Requirements

**DIST-1:** The game must be startable from source with `duck-attack` or
`python -m duck_attack` on Python 3.12+.
Verified by: manual

**DIST-2:** Release builds must be produced for Windows x64, macOS Apple Silicon and
macOS Intel, as zips named `DuckAttack-<version>-<platform>.zip`; on macOS as a
`DuckAttack.app` bundle carrying the version from `pyproject.toml`.
Verified by: `.github/workflows/release.yml`

**DIST-3:** Every build must pass the tests and a headless smoke test (the app is still
running after 10 s) before it is uploaded.
Verified by: `.github/workflows/release.yml`

**DIST-4:** Pushing a tag `vX.Y.Z` must publish a GitHub Release with the zips, or add
them (replacing older ones) to an existing release with that tag. The tag must match the
version in `pyproject.toml`, otherwise the build fails.
Verified by: `.github/workflows/release.yml`

**DIST-5:** Every push and pull request must run `ruff check` and `pytest`.
Verified by: `.github/workflows/ci.yml`

**DIST-6:** Builds are not code-signed; the README must explain how to open them anyway.
Verified by: manual
