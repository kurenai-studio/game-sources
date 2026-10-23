# Test migration provenance

The five scratch files in this directory are the original audit harnesses that
the repository tests under `test/audit/` and `e2e/f28-touch-lift.spec.js` were
ported from, kept byte-identical so every port deviation can be checked. The
assistant wrote and ran them during the audit's October 2026 finding work,
outside the repository; the findings and their dispositions are recorded in
`DECISIONS.md` and `docs/tetris-audit/phase-5-records.md`.

`SHA256SUMS.txt` covers the five scripts and the three raw run logs
(`raw-clear-after.log`, `raw-seed2024.log`, `raw-seed20261017.log`). The logs
themselves (about 474 KB in total) are not in the repository: the ported tests
are deterministic on fixed seeds, so the runs are reproducible without them.
The checksums stay here so a recovered log copy can be verified later.

The scripts reference scratch paths that no longer exist; they are kept as
evidence, not for running. The maintained versions are the repository tests,
and the pull request that introduced them lists every deviation from these
originals.
