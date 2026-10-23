# Drawing and Controller Failures

Controlled failures, visible recovery, and reporting limits.

These are SAF5/D23U2 candidate observations. They do not dispose of findings, prove native browser failures, select a source rule, or certify anything. At the October 5, 2026 recording (D46), Phase 3 was still open. This is historical status, not a claim about the current phase. There were no production, public-site, permanent-test, CI, or executable-model changes. Clean-author isolation is a coordinator process boundary, not a tested property of these artifacts. V15 to V17 are later private evidence, separate from D45.

## Source and expectation

D23U2 counts a fault as reported when both a small, noninterrupting player notice and a separate test-observable signal occur. No stored fault record is required. Drawing and polling loops keep running.

In the source, drawSafely catches failures, resets drawnBoard/drawnPreviews/lastSnapshot, logs console.error once per load, and schedules a retry. The polling catch logs console.error and continues while connected. Neither handler directly changes the DOM or creates a notice. This is source evidence for these paths, not a universal proof that a notice is absent.

## V15: two adapters

The environment was Chrome154/Node22.23.3, with declared RNG0.3 and an injected clock. Each adapter conditionally threw once at CanvasclearRect or getGamepads.

The actual JSON gates show:

- One fault and one console error each, with zero page errors.
- RAF executions and pad reads advance.
- Opaque-cell geometry, body text, storage, Pause, and the closed dialog stay stable after 40 clock ms.
- ArrowLeft then shifts one column.

The actual recovery pixels were inspected: clear S, ghost, previews, score0, and no visible notice. The source/JSON/pixel reviewer did not rerun the browser. The source comparison reported a trailing-newline difference and lacked index.html. It was not an attestation of exact served bytes.

These are visible and storage projections. They do not prove that every authoritative A1-A16 item is unchanged. Recovery screenshots cannot exclude a transient notice. Conditional adapters do not prove native-fault reachability, hardware behavior, or elapsed deadlines. No stored fault record is expected.

### Harness failures retained

The initial RAF counter was overwritten by the clock. The initial viewport-width change did not resize the board, and the drawing fault occurred only after a later Left action. A second attempt waited for the canvas width to change, timed out, and produced no fresh JSON.

The final wrap after the clock, plus explicit canvas CSS310px, a screenshot flush, and 40 clock ms, delivers the fault before the recovery snapshot. Failed output is not recovery evidence.

## V16: ten method-first-call cuts

One-shot conditional throws covered clearRect, beginPath, moveTo, lineTo, stroke, roundRect, fill, save, restore, and translate. All ten actual JSON records show the matching failedMethod, one fault, one console log, zero page errors, advancing RAF and polling, and stable body text and storage.

Eight retain the opaque-current centers and a subsequent Left shift. Throws at roundRect and restore during ghost drawing leave the current piece translucent. The alpha>200 sampler returns zero before and after Left. That is a lost observation, not a disappeared piece or stopped input. The actual pixels show the dim S still visible.

The V16 roundRect and restore PNGs have identical bytes. Those images alone do not establish which method was injected; method identity comes from separate JSON/script context. Source/JSON/pixel review supports this distinction. It did not rerun the browser.

## V17: measured alpha and follow-up

Separate roundRect and restore fixtures observe these values:

- Actual board-context globalAlpha1→0.5 afterrecovery/afterLeft→1 afterexplicitCSSresize305.
- Currentpixelalpha255→128→255.

A lower alpha>80 center sample recovers the original four S cells, observes ArrowLeft shifting one column at alpha128, and retains the moved geometry after resize.

The coordinator asserted the actual JSON before handoff. Independent source/JSON/pixel review did not rerun the browser. DimLeft and opaqueResize images were inspected. The resize PNG may precede the final 40 ms sample, so geometry equality comes from JSON, not an assumed shared capture instant.

### Measurement and inference

The context alpha, pixel alpha, and geometry above were measured. The inferred cause has three parts: the ghost save/globalAlpha 0.5/roundRect/stroke/restore sequence leaves alpha 0.5 when roundRect or restore throws; the drawSafely cache reset does not reset context alpha; and canvas width/height assignments during resize reset context state. Save-stack depth was neither instrumented nor proved.

The follow-up Left observation shows that ArrowLeft moved in these two fixtures. It does not settle input recovery universally. V16's opaque-only projection could not observe the dim state, so those runs cannot show whether it recovered.

## Open scope

Dim rendering until resize is a conditional, unclassified candidate. Ten methods do not cover all call positions, contexts, property setters, or persistent failures. Initial getContext/getImageData/setTransform, observer pre-catch, and module failures remain open.

There is no full context restoration, containment at every cut point, full A1-A16/state frame, native-fault or platform reachability, physical-device or Safari proof, elapsed-time proof, or Phase 3 closure. The missing notice remains a source, finite-DOM, and pixel candidate, not a universal proof.
