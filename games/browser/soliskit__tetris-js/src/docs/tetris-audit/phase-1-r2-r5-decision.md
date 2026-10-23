# Saving, Withdrawing, and Reading a Game

R2 to R5: saving and reading games, time between falls, and hand-edited saves.

Status and provenance are recorded in `DECISIONS.md`, row D21. The drafter read production code, so this record is not implementation-independent under blueprint O8. No rule below was taken from code or tests. A wording-only reorganization on October 9, 2026 (ledger row D52 in `DECISIONS.md`) rearranged the save rules of this text into sections. The rule index below maps the original rule numbers S1 to S9 to the sections; the high-score clause of S8, S10 and S11 are carried unchanged. A later selection on October 9, 2026 (ledger row D53 in `DECISIONS.md`) settled the last-good identity after failed publication.

Baseline: D16 (`docs/phase-1-state-decision.md`, SHA-256 0ca7916f67e1b6a2e784272af15732b018b41ed70f3ec0fe05ceb72a5dcc0bad), D16 Amendment 1 (D17), the R1 decision (`docs/phase-1-r1-decision.md`, D18, SHA-256 aacf5189a6aa3b21660e8bfe1a5bf8ab2d62f8e853df3febaa54d81412707dec) and D16 Amendment 2 (`docs/phase-1-d16-amendment-2.md`, ledger row D20), whose items 16 (section 1.1), 5 (section 1.2) and 3 (section 1.4) this text uses. None is changed by this file.

## Save rules

This is a wording-only organization of the selected save rules. It changes no behavior, code, tests, storage or requirements. Exact conversion mechanics remain unresolved. The last-good identity after failed publication is selected below (Fault); its mechanism is not selected.

### Save

A save succeeds when the valid saved position is written and marked available for Continue. If the position writes but marking it available fails, the save failed. A failed save attempts withdrawal as described below. This applies to saving the current game and to an admitted one-time conversion: there is no conversion-specific exception keeping the original available after failed publication. October 9, 2026 update: the admitted one-time conversion case belongs to the superseded convert-once target (D58); the failed-publication rule for saving the current game is unchanged.

New saves use a labeled format that preserves the exact reset count and lowest-row history. The label tells a reader how to decode the save; it does not prove when or by which software version it was written. October 9, 2026 update: the owner selected no dedicated format label for the current save layout (D59); the labeled-format sentences record the superseded target. The exact reset-count and lowest-row history requirement for new saves stays active. The current adopted STA-4/STA-6 requirement contract is unchanged; implementation is unchanged.

The selected conversion direction is to convert existing old saves once, then keep only the new format. This includes otherwise-valid preexisting saves whose old or recent origin cannot be determined. It does not admit all future unlabeled inputs or permit indefinite legacy support. The stored high score is separate and is not erased by old-save policy. October 9, 2026 update: the owner selected current layout only, with old-layout saves refused and no conversion step (D58); this convert-once direction is the superseded target, preserved as history. The limits on accepting future input and the high-score separation stay current. The current adopted STA-4/STA-6 requirement contract remains; implementation is unchanged. Whether refusal of otherwise-valid old-layout content changes persisted eligibility was left open at selection time and resolved the same day by D60: ordinary withdrawal is attempted; stored payload bytes stay.

This direction is not an implemented migration. Exact encoding, keys, trigger, durable completion, cleanup ordering, failure ordering across source and target copies, and old cached tab writes are still to be selected and reviewed. Current STA-6 supported-format loading remains adopted until an authorized behavior and requirement change. October 9, 2026 update: the migration mechanics listed here (encoding, keys, trigger, durable completion, cleanup ordering and failure ordering across source and target copies) were conversion-only and are retired with the convert-once target (D58). Old cached tab writes stay relevant: an old tab can still write, and that interference remains under review.

### Withdraw

Withdrawal means Continue no longer offers the saved game. Deleting its stored bytes is not required.

Withdrawal happens when:
- New Game is confirmed;
- normal game over occurs because a new or held piece has no room;
- stored saved-game content is invalid and rejected whole;
- stored saved-game content is present and successfully read but fails the full finalized current layout and validation, covering old-layout, unknown-layout and malformed-current records; ordinary withdrawal is attempted and no gameplay from the refused record is loaded (D60, October 9, 2026);
- saving the current game fails, including failure to publish the saved position;
- saving an admitted old save in the new format fails, with no conversion-specific exception. (Admitted-conversion trigger, part of the superseded convert-once target, D58; the other triggers are unchanged.)

When withdrawal happens or is attempted, this running session's withdrawn indicator (item 16 of D16 Amendment 2, section 1.1) is set. If writing withdrawal fails, gameplay continues and this session does not offer the previous save; only in that failure case, after a reload nothing is promised: the save may be offered again. No retry system and no new save format are required by this rule.

A later error does not undo a withdrawal already made. Another session saving a game does not clear this session's withdrawn indicator. The indicator starts clear on page load and clears when this session successfully saves. It is not persisted.

Continue is available only when stored eligibility is exactly the string "true", the session's withdrawn indicator is clear, and the saved content passes the persisted-content validity rules. Other stored flag values or absence are ineligible.

### Read

A storage read failure is not invalid stored content and is not absence established by a successful read. A failed read may make the saved game unavailable, but does not by itself withdraw it or change stored values. Nothing is promised about when availability returns.

Invalid stored content is rejected whole and withdrawn. The game does not partly load it or use conversion defaults to repair invalid content. Accepted gameplay content is restored whole and paused under the persisted-content rules. Under the current-layout target (D58/D59), present and successfully read content that fails the full finalized current layout and validation is refused and ordinary withdrawal is attempted (D60); a failed read and a successfully established absence remain distinct from this refusal and do not themselves mutate storage.

### Fault

An engine fault by itself does not withdraw the saved game. Normal game over and an engine fault have different triggers.

The adopted last-good rule keeps a save successfully written with valid content even if the same step later faults, without rolling it back. On a fault stop, the last good save is kept. Only a fully finished save replaces the last-good position: a position written but not published does not become the last-good target. The mechanism, whether recovery, rollback or retention, is not selected.

This section does not expand the safe-terminal definition, promise rollback for ordinary state, or certify any current game-written payload as valid.

### Conversion defaults

Superseded target, October 9, 2026: the owner selected current layout only (D58); these conversion defaults belong to the earlier convert-once target and are preserved as history, not as live target work. The current adopted STA-4/STA-6 requirement contract is unchanged; implementation is unchanged.

The defaults below supply selected values, not recovered gameplay history. Use them only within the applicable old-save or selected preexisting ambiguous-save conversion scope. Preserve history already present, subject to whole-content validity. They do not repair missing required history in future new-format records.

| Condition | Meaning |
| --- | --- |
| Applicable older save has no reset count | Use zero. Do not overwrite a count already present. |
| Applicable older save has no lowest row reached | Use the greatest board-row index occupied by a block of the current falling piece. This is not necessarily the piece's box-origin row. |
| Legacy paused, resting save has count 15 and lacks information distinguishing a pause from 14 to 15 from a pause after the allowance was used | Resume with the lock delay starting, under the exact L2 condition. This is not a general count-15 rule for new saves. |
| Save predates storing the bag and that compatibility condition applies | Continue with a fresh bag under STA-4/B16. A valid empty stored bag is distinct from a missing bag. |

Later saves preserve the selected converted values exactly. That exact restoration does not claim the unknown original history was recovered.

### Unchanged rules

The stored high-score clause of S8 is unchanged:

A stored high score is good when it is a whole number from 0 through 9,007,199,254,740,991, with no divisibility condition; otherwise it counts as zero (R1, B16). The later stored-score ceiling replaces the original unbounded S8 domain; see the current amendment in DECISIONS.md.

S10 is unchanged:

PLY-2 is judged against the delay the game requests from its scheduler, compared with max(0.25, 0.7 - 0.02 x (level - 1)) seconds (R1, B14) expressed in milliseconds, with an absolute tolerance for numerical rounding. The tolerance is 0.000000001 millisecond. The claim covers the value requested. Conversion of that value by the browser, actual elapsed time, lateness and throttling are not claimed. Whether timer registration and cancellation are inside the trusted boundary remains a separate Phase 1 item.

S11 is unchanged:

Persisted state that was edited by hand is judged only by the untrusted-input rules: it is accepted whole if it is valid under R1 (B16), otherwise rejected whole. Gameplay requirements such as PLY-7 govern the play the game itself produces. They are not applied to the history of an accepted saved game, and no claim is made that an accepted state could be reached by legal play. No check that a result was earned through play, no anti-cheating protection and no tamper protection is claimed.

### Rule index

The original decision numbered the save rules S1 to S9. Current records and research ledgers cite those numbers; this index keeps them meaningful after the reorganization.

| Original rule | Where the rule lives now |
| --- | --- |
| S1, meaning of forgetting | Withdraw, first paragraph |
| S2, when withdrawal happens | Withdraw, trigger list and the later-error paragraph |
| S3, compatibility with SAF-3 | Fault, first paragraph |
| S4, failed withdrawal | Withdraw, session indicator and reload paragraph |
| S5, failed save | Save, first paragraph; Withdraw, trigger list |
| S6, last good save | Fault, last good paragraph |
| S7, failed read | Read |
| S8, definitions | the eligibility clause: Withdraw, Continue availability paragraph; the stored high-score clause: unchanged below |
| S9, item 16 lifetime | Withdraw, session indicator paragraphs |

### Publication scope

This text only reorganizes save-related meaning. Gravity timing and hand-edited-state rules in S10/S11 remain unchanged and outside this organization. No finding, property or phase status is closed.

## Not decided here

- The observable criterion for "fault reported" (SAF-3, SAF-5).
- The meaning of "timer" for SAF-4.
- Any change to REQUIREMENTS.md, including whether S1 to S11 should become requirement text, and the class of any later change.
- Any code change. Some of S4, S5, S7 and S9 may differ from how the code behaves today; that is a later separate decision with its own tests and approval.
