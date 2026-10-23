# Hosting, Automation, and Randomness

Hosting, offline storage, automated checks, and the random source.

Status: decision text recorded by a ledger row in `DECISIONS.md` (row D24). The ledger row governs the status and the provenance of this text. The drafter read production code, so this record is not implementation-independent under blueprint O8. No rule below was taken from code or tests.

Baseline: the blueprint's O6 trust ledger and Appendix E (point-in-time candidates, none adopted before this file), `docs/phase-0-baseline.md` section 7 (repository rules), DECISIONS.md F5 and F6, and D21 to D23. This file changes no bytes of any of them.

## Decision text

**V1. Hosting and the offline cache.** GitHub Pages is trusted to serve the files that were deployed. The browser's cache operations are trusted to work as documented when they succeed. The game's own offline-cache logic is not trusted: it is tested, including interference from other projects served from the same site address (APP-2, APP-6). No protection is claimed against a compromised GitHub account and no availability of the hosting is promised.

**V2. GitHub Actions and repository settings.** The audit records dated evidence of what continuous integration and the repository settings enforce, and relies on GitHub to run the workflows as written and report their results accurately. A passing check is evidence that the checks it runs passed. It is not a proof of complete safety. The recording changes no setting and no workflow. The dated facts are those of `docs/phase-0-baseline.md` section 7 (the rule requiring the test check, up to date with the main branch, with no pull request rule and no bypass actor, and classic branch protection not visible) and of Appendix E, as of October 4, 2026; the audit makes no claim about them after that date.

**V3. Random source.** The random-number source is assumed to return valid values. The audit checks that the game follows the seven-piece bag rule (PCE-5) with the values it receives. No claim is made that the sequence is unpredictable, unbiased or cryptographically secure, and no new random generator is added. A random source supplied by a test is a trusted test control, as DECISIONS.md F5 and F6 state.

## Not decided here

- Any control the Appendix E non-goals name: content security policy, a header proxy, code scanning, version-update automation, pinning actions to commit hashes, required reviews, a security policy file, storage persistence. Each remains a separate owner decision and none is adopted here.
- Whether the random source needs checking beyond the bag rule, including whether an unexpected value from the source could break a requirement. That stays an evidence question for later phases.
- Any change to REQUIREMENTS.md and any code change.
- Closure of the Phase 1 exit item on trust assumptions. This file records further entries toward it. It does not close it.
