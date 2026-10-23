# Browser Contracts and Device Evidence

Platform guarantees are conditional arguments, not physical measurements.

This record maps browser contracts to the inspected application for claim-appropriate review. It does not establish formal Phase 3 closure, certification, a new requirement or an additional approved limit. The public source tree is 1e09ad61c19e0b235a231ad8810dae176be4ea77.

## Conditional methods are not physical observations

A contract argument combines an independently described platform behavior with inspected application behavior, under stated assumptions. It is not an observation that every device, browser or assistive technology fulfilled that contract. A failure comparison can be a meaningful mapping without showing that the implementation complies.

### DSP-6: color conversion and display prerequisites

WebKit's Canvas article states that the default color space remains sRGB; the two explicit spaces are `srgb` and `display-p3`. It states that out-of-space drawing colors are clamped, and that `getImageData` by default returns pixel values in the canvas color space. Its Display P3 comparison depends on a browser and display that support Display P3. Display capability remains a model-agnostic conditional premise, not a public binding to a privately recorded device.

Inspected `public/script.js:32-45` creates all five 2D contexts with the P3 request and places only contexts reporting P3 from `getImageData` in the P3 set. The application detects color space through ImageData.colorSpace; this is not claimed to be WebKit's getContextAttributes example recipe. Lines 78-92 convert the three hex components to numbers divided by 255 and use `color(display-p3 r g b)` for piece fill/stroke colors in those contexts; the fallback keeps the hex string. This is not a claim about every drawn color. This supplies a conditional source/platform comparison beyond the metadata request alone. A reported context space does not measure displayed P3 pixels. Existing context/component assertions are separate execution evidence and require their own exact outcome bindings.

Premises: successful supported Canvas and CSS color semantics, P3-reported context, output on a P3-capable display, and the defined piece values interpreted as those components. This does not measure a player's display, establish a subjective vividness threshold, verify exact Safari engine integration or prove future support.

Sources:
- https://webkit.org/blog/12058/wide-gamut-2d-graphics-using-html-canvas/

### INP-6: custom button semantics and activation

W3C's APG button pattern states that Space and Enter activate a focused button and that an accessible name may be supplied by `aria-label`. Application `public/index.html:33` provides `role=button`, `tabindex=0`, name Hold and a shortcut label on the held-piece canvas. `public/script.js:495-508` supplies click activation and explicit Enter/Space activation while playing, prevents default/propagation for that handled key path, and prevents mouse-down focus changes so clicking does not move focus. Outside the playing Enter/Space path, those keys keep their ordinary game actions; the default/propagation handling is not universal.

This maps the own-handler and role/name relation when browser/accessibility semantics cooperate. APG is guidance, not proof that every screen reader recognizes a canvas button or that `aria-keyshortcuts` implements the shortcut. Native recognition, heard output and all reader/settings combinations remain unobserved. The application uses keydown for Space; it has no repeat guard on this handler. Key-release timing and repeated-key native behavior are not examined by this contract argument. Scoped Hold tests require their exact outcome binding separately.

Source: https://www.w3.org/WAI/ARIA/apg/patterns/button/

### DSP-8: conditional status announcement

W3C ARIA22 describes `role=status` as implicitly polite and atomic, with content automatically read by assistive technology without moving focus. Its procedure requires the status role/container before the message update. It also warns that some environments do not treat status as atomic by default and recommends explicit `aria-atomic=true` where the whole content needs announcing.

`public/index.html:49` contains the initially empty status paragraph before the script runs. `public/script.js:210-217` writes Game Over or clears that node. `public/style.css:233-240` clips a one-pixel visually hidden element rather than using display:none. That CSS fact does not itself prove accessibility-tree exposure. Exposure remains an explicit unverified premise. This supports the conditional exposed-node/update contract relation, not measured speech. Browser assertions of status text and overlay attributes are separate from assistive-technology behavior.

Premises: the node is exposed to the accessibility tree, browser/assistive technology cooperate with status updates, and polite notification is permitted. No actual VoiceOver speech, exact announcement timing, all-settings behavior, WCAG conformance or every rapid state update is claimed. Identical Game Over text can be written again when syncControls runs after snapshot changes; whether that produces repeated AT notifications is unexamined. The application does not set explicit aria-atomic, so the documented compatibility gap remains. Atomicity compatibility is not silently guaranteed.

Source: https://www.w3.org/WAI/WCAG22/Techniques/aria/ARIA22

### DSP-7: application's wake policy

`public/script.js:245-274` returns when the API is missing, requests a screen lock when wanted, releases obsolete results and the active lock after the wanted state changes, ignores stale release events, reacquires after the current lock is released while wanted, and silently swallows request rejection. There is no immediate rejection retry; another attempt requires a later setWakeLock state change. The W3C Screen Wake Lock Working Draft specifies only visible, fully active eligible documents, request denial/rejection and release on lost visibility/activity. It also notes that an OS acquisition failure can be indistinguishable from success to avoid fingerprinting. A granted sentinel alone therefore does not prove physical no-sleep behavior. This is inspected policy source, not physical no-sleep execution. Controlled sentinel/assertion evidence needs a separate exact outcome record. Availability, asynchronous failures, device sleep and future platform behavior remain explicit domains.

Primary contract: https://www.w3.org/TR/screen-wake-lock/

## Later recorded device outcomes

Later bounded outcomes are described in the companion [phase-3-native-recording-evidence.md](phase-3-native-recording-evidence.md), from held inspection records and owner-reported gestures. This contract document does not replay recordings or establish their output, identity or privacy. Raw recordings are not repository artifacts.

The four owner-approved Not Established relations in `phase-3-limited-advancement-record.md` remain delivery of both quick taps, double-tap recovery, zoomed-reload recovery and exact phone-cache source correspondence. This document creates no further approved limit and does not settle literal full-screen meaning or broader application integration.

## Source identity

- `public/script.js` SHA-256 `59fcb3343f35d0022c739cce82c5c9601a9e3bc354a9dc991eb1660c4e599ad4`.
- `public/index.html` SHA-256 `96f7fb5b112d6890b33b0f38d51e2bb47fe2289875354559a82ab4e036ab85c1`.
- `public/style.css` SHA-256 `76d219d4a4bad0e4c94ab4c2b1d583992ea08154725c6de002c78623bc87c5ca`.

Review must judge these methods against the full claims and preserve any genuinely incomplete mapping. A source contract or row count cannot replace that judgment.
