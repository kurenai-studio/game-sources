# Refuse an Invalid Save

If a present save is read successfully but fails validation, attempt ordinary withdrawal.

## Decision

For saved-game data that is present and successfully read, failing the full finalized current layout and validation triggers ordinary withdrawal. This covers old-layout, unknown-layout and malformed-current records without requiring a legacy-validity decoder. No gameplay from a refused record is loaded. Withdrawal attempts to mark Continue unavailable under the existing withdrawal semantics; deleting stored payload bytes is not part of this selection. The high score is separate and untouched.

The ordinary withdrawn indicator is set on withdrawal or attempted withdrawal. If persisted withdrawal fails, this session does not offer the refused save; after reload nothing is promised about the persisted eligibility effect. A successful persistence changes eligibility under the existing ordinary withdrawal relation. A later error does not undo a successful withdrawal. This adopts the existing meaning, not a new retry, recovery, marker, key, transaction or cleanup mechanism.

A failed read is not schema rejection or successful absence and does not itself mutate storage. Successfully established absence is outside this present-data trigger and does not itself mutate storage. The existing other withdrawal triggers, failed-save and last-good rules are unchanged. The current-layout-only (D58) and no-label (D59) targets and the current whole-validation constraints remain; the exact schema fields are unfinalized. No fallback or default repair is introduced. This resolves the refusal-persistence gap left open by D58 and D59; it does not authenticate writer age or certify the code.

No code, test, storage, model, CI, settings, requirement, deployment or deletion action. The current adopted STA-4/STA-6 requirement contract remains unchanged; implementation is unchanged until separately authorized paired behavior and requirement work.

## Decision record

The owner approved ordinary withdrawal when present, successfully read saved-game content fails the finalized current layout and validation. This records the decision and its scope, not approval of final document bytes or a code change. Publication follows the separate docs-only review, checks and merge grant.
