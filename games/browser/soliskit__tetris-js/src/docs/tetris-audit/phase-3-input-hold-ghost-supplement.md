# Controls, Hold, and Ghost Pieces

Recorded browser cases and the limits of their input and pixel measurements.

Bounded candidate observations, not findings disposition, accepted oracle, complete correspondence or certification. At the October 5, 2026 recording (D45), Phase 3 was still open. This is historical status, not a claim about the current phase. No game code, public-site content, permanent tests, CI or executable-model changes. Evidence remains separate from the clean author.

## Environment and provenance
Node22.23.3 and actual Chrome154.0.8037.57, headless Linux,1000x900 viewport, local static production page. Gamepad values are explicit standard-mapping snapshots replacing navigator.getGamepads, not physical hardware. V7 constantMath.random0.3 without injectedclock; V8-V10 andV13 use injected Playwright browser clock and constant Math.random0.3. Clock advancement is not real elapsed timing or device evidence. Canvas centers/previews, DOM focus and labels are projections, not complete authoritative-state adapters.

Coordinator atOctober5 approximately17:18PDT compared every actual file in the served public directory with Git main789fb7 bytes:16files equal. Independent review compared all16manifest sizes/hashes to Git and found public bytes unchanged from0f4e510. Reviewer did not read the served directory or attest historical executions. Today's equality is not historical-run attestation.

## Gamepad snapshots v7 (INP4/STA1)
Five cases, source/JSON reviewed without independent browser rerun; all recorded errors empty.
- Menu+A at opening yields spawnS and no locked blocks: bounded suppression contrast.
- A+padUp locks exactlyone S and spawnsL: same-action deduplication in this fixture.
- Menu+View at opening yields spawnS. This pixel result cannot distinguish priority, since View has no visible effect there. No priority proof.
- Dialog starts Cancel-focused/paused; right moves focus to NewGame and holding right across polls keeps that focus; A closes dialog and starts game.
- B closes dialog, keeps spawnS and Resume label. No full dialog/control frame proof.

## Controlled clock v8 (INP2/D18B12/D34)
Three cases, reviewed source/JSON without independent browser rerun. Native Playwright keyboard events plus supplied pad axis, no hardware/OS repeat claim.
- Held keyboardLeft, newer stickRight, then centered stick produces left1/right1/left1 column changes. Compatible with ordered-token interpretation, but also with a fixed stick-priority implementation; not a discriminator between them.
- A and ArrowLeft both pressed; releasing ArrowLeft while A remains held stops observed repeat during200clockms. Separate physical-source interpretation remains a candidate; no classification or complete token projection.
- HeldLeft pause/resume before DAS leaves geometry unchanged immediately; advancing170clockms after resume moves two more columns. This bounded observation is a candidate contrast to held-at-resume suppression, not a source-rule change. Older wall-clamped elapsed probes could hide movement counts and are not this evidence.

## Hold v9 (PLY7/PCE3)
Canvas current/held/queue semantics observed, not production getters as expected oracle. Declared RNG fixes a production queue fixture, not independent bag-order prediction or fairness proof. StartS/emptyHold/queueL,I,Z. FirstH gives currentL/heldS/queueI,Z,J. SecondH identical. Space locksL at(18,5),(19,3),(19,4),(19,5), currentI; H restores originalS spawncells(0,4),(0,5),(1,3),(1,4), heldI, queueZ,J,O unchanged. RepeatedH again identical. Actual screenshot inspected: spawnS,heldI,queueZ/J/O,lockedL clear. Independent source/JSON/geometry/pixel review, no browser rerun. Production centering interpretation is not uniquely settled. Topout, resetcount/lowest, all kinds and full state frame remain unassessed.

V13 adds one clockwise-rotatedS case: initialrot0 cells above, ArrowUp producesrot1(0,4),(1,4),(1,5),(2,5); Hold storesS by previewcolor, replacementLlocks, then Hold restoresSrot0initialcells. Actual JSON assertions and independent source/JSON/geometry review support this bounded reset-to-start observation, without browser rerun. Held preview is color-only in JSON, not proof of heldshape orientation. Final screenshot is byte-identical to v9, consistent with identicalfinalstate; it cannot show rotationstep or attest which run produced it. Rotation evidence rests on JSON, not this screenshot. Other kinds, CCW, not-fit/topout, flags/count/lowest remain open.

## Ghost v10 (PLY5)
Independent expected landing from observed current and locked cells: maximal downward translation within20x10 bounds avoiding locked occupancy. No production ghost/dropDistance expected oracle. EmptyS predicts drop18/cells(18,4),(18,5),(19,3),(19,4); lockedS/currentL predicts drop16/cells(16,5),(17,3),(17,4),(17,5). Corrected actual outline sample sets equal these in both fixtures; independent reviewer recomputed drops/sets and inspected screenshot, no browser rerun.

Measurement is implementation-informed and post hoc: firstalpha>120 missed even-row stroke96/102, while odd-row edges128 passed. Alpha>40 admitted neighborbottomedge49. Final eightnear-top samples/cell, alpha>80/color-spread>35 isolates bothimages. Expected translation unchanged. Failed sampler/code/JSON preserved. A premature equality summary was immediately corrected; only corrected JSON supports finite equality. This tuned classifier is not independent universal pixel oracle; other colors, overlaps, DPR, canvas sizes, browsers, physical display and accessibility remain open.

## Remaining scope
Physical gamepads/touch/keyboard, Safari/iOS, OS gestures, elapsed deadlines, disconnect handling, all focus states, accessibility and complete authoritative/composite frame projections remain open. These finite cases do not close requirements or Phase3. No finding disposition or new normative source is adopted.
