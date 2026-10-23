# Focus and Touch Checks

Recorded browser input, pointer capture, and the tap-distance boundary.

Candidate observations, not findings disposition, complete input coverage, oracle acceptance or certification. At the October 5, 2026 recording (D44), Phase 3 was still open. This is historical status, not a claim about the current phase. No production, permanent-test or CI changes. Public bytes served locally from the fetched tree associated with main, unchanged from the D43 scoped source.

## Environment and scope
Node22.23.3, actual Google Chrome154.0.8037.57, headless Linux, viewport1000x900, local Python static server. Browser version is from the result JSON. An earlier prose value150.0.7871.13 was wrong and corrected; it is not evidence. Full-page production loaded unmodified. Playwright keys/mouse and Chromium protocol emulated touch are browser-generated trusted events but not physical hardware, Safari, OS gestures or assistive technology. Synthetic DOM PointerEvents are untrusted and kept separate.

Source expectations were predeclared from STA1/STA2, INP5, D18B12, D33C2 and D34E1. Initial exploratory snapshots before rendering returned empty canvas and were discarded as before/after evidence. Corrected harness waits two animation frames before canvas snapshots. Random piece runs are compared by recorded geometry, not identical raw JSON. V6 injects constant Math.random0.3 to give repeatable non-O S geometry; this is declared input, not evidence of random fairness.

## Focus observation
Enter then Escape establish a paused game through browser-dispatched keys. A same-task programmatic NewGame click returns dialogclosed and activeElement empty; after rendering the dialog is open and Cancel active. Actual screenshot inspection shows centered readable dialog, Cancel focus ring and paused controls. This is timing evidence, not a new asynchronous grace period, full focus projection proof or classified violation. Tab/accessibility/focus-loss classes remain open.

## Synthetic capture-failure branch (v3/v4)
Two DOM PointerEvents have isTrustedfalse,pointerTypetouch,id71. Down at500,488 followed by up at560,488 without pointermove rotates a non-O piece in the recorded run. Source pointerdown writes drag state before setPointerCapture; actual pageerror collection shows capture throws 'No active pointer with the given id'. Later synthetic up reads the retained state. This is a conditional capture-failure/untrusted-event path, not successful native touch or proof a real60px move omits pointermove. A cancel counterpart does not rotate. Source endDrag488 never reads final coordinates; the source gap does not prove physical reachability.

## Trusted pointer contrasts (v4/v5)
V4 Playwright mouse down/three moves/up are isTrustedtrue,pointerTypemouse, no capture error. Recorded I shifts2columns for60px and keeps orientation. Earlier public O moved3columns at a different canvas size; this is not a conflict.

V5 Chromium Emulation.setTouchEmulationEnabled and Input.dispatchTouchEvent produce pointerTypetouch,isTrustedtrue,got/lostcapture,no errors:
- Drag O moves from rows0/1,columns4/5 to6/7. O geometry alone cannot show rotation, so this establishes movement/capture only; source moved flag excludes tap path.
- Cancel J moves right2columns with unchanged orientation; already committed movement stays after touchCancel, as E1/C2 require.
- Touchstart, native H Hold, rendered mid-snapshot, then touchMove/end: original O goes to Hold, replacement Z mid/after cells remain(0,3),(0,4),(1,4),(1,5). The gesture does not control the replacement piece in this bounded case. Screenshots show shifted J and held O/replacement Z.

## Exact10px boundary and paused input (v6)
Repeatable S before cells:(0,4),(0,5),(1,3),(1,4). All protocol touch cases log actual trusted coordinates/capture,no pageerrors:
-9px movement/end rotates S to(0,4),(1,4),(1,5),(2,5).
-Exactly10px movement/end preserves original S. E1 says "never moved beyond 10 px" and "ends within 10 px"; under the candidate inclusive-equality reading this is a tap; script448 uses strict less-than10, so exactly10 sets moved449. This is a bounded candidate equality discrepancy, not classification or physical-device proof. Actual9/10screenshots inspected: vertical versus original S.
-11px excursion then return preserves orientation, matching no-tap consequence.
-9px cancel preserves orientation.
-Paused60px drag and9px tap preserve canvas and Resume label. This does not prove no authoritative touch-state mutation or all paused frame items.

## Independent review and limits
Independent reviewer read v3-v5 code, JSON, production source and screenshots and found the conditional scope supported. It could not rerun Playwright/Chrome. Throwing-lock variants were independently run, separately from browser evidence. V6 also received source/JSON/geometry/screenshot review, without an independent browser rerun. The exact10px interpretation remains a candidate reading of E1 wording, not a settled classification or new rule. Only one S, x-axis, integer coordinates and desktop Chromium protocol were sampled; diagonal/subpixel/physical/Safari boundaries remain open. Screenshots are visual evidence, not universal state proof. Physical touch, native omitted-pointermove reachability, Safari/iOS, devices, accessibility, real elapsed repeat timing, all focus states and complete composite/frame projections remain open. Historical erroneous prose/run labels are not used; exact current artifact hashes below identify evidence.
