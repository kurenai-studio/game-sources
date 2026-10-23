# Drawing console reports

Report again after recovery, without flooding the console during one failure streak. A console report is an error message in the browser's developer console.

## Policy

Drawing failures produce one console report per unbroken failure streak. A successful drawing frame resets the report flag; the next failure after recovery produces a new console report. Only repeats within the same unbroken streak are suppressed.

The existing on-screen notice limit, once per kind of error in a session, is unchanged.

## Evidence and meaning

Console reporting is the separate test-observable signal for SAF-5 and D23 U2. U2 still requires both a small noninterrupting player notice and a separate test-observable signal, with drawing and polling continuing. No stored fault record is required.

At main b1e9cec, `public/script.js` lines 364-377 initialize `renderErrorReported` once, set it after a caught failure and do not clear it after success. Later caught failures still invalidate drawing caches and request retry, but skip the console report.

The Phase 3 O-11/SAF-5 record and drawing/controller-fault supplement describe "draw error reported once per load". That is a source observation, not an adopted once-per-load requirement. This decision resolves the reporting-frequency gap; it does not retroactively make that behavior conformant or promote a finding.

## Proving plan after the audit

With completing console and scheduling providers, inject a first drawing failure and additional failures without recovery: expect one console report. Complete a successful drawing attempt, then inject a new failure: expect a second report. Complete another recovery draw. Record the signal, the separately limited notice, callbacks, game-state preservation and recovery pixels. An idle callback that checks unchanged caches is not the successful drawing witness. Existing one-failure evidence does not cover this sequence.

## Scope and provenance

On October 14, 2026, the owner agreed. This record covers drawing console reporting only, not gamepad report frequency or a new player-notice rule. Implementation and permanent tests wait until after the audit and their existing approval gates. Production, tests, CI, REQUIREMENTS.md, finding dispositions, phase exits and certification are unchanged.
