# Saved Games and Continue

D16 Amendment 2: when a saved game is eligible and Continue is available.

Status and provenance are recorded in `DECISIONS.md`, row D20. The drafter read production code, so this record is not implementation-independent under blueprint O8. No rule below was taken from code or tests.

Baseline: the approved D16 decision, `docs/phase-1-state-decision.md` (SHA-256 0ca7916f67e1b6a2e784272af15732b018b41ed70f3ec0fe05ceb72a5dcc0bad), and D16 Amendment 1, `docs/phase-1-d16-amendment-1.md` (ledger row D17). Both are unchanged by this file. If adopted, the authority for the Phase 1 state model is D16 together with Amendment 1 and this amendment.

## 1. Amendment

Section 1.1 of D16 gains an item:

16. The withdrawn-from-Continue indicator, a true or false value belonging to one running session of the game (one page load). It is true from the moment a saved game is withdrawn from Continue in this session, or an attempt to withdraw it is made, until this session writes a saved game successfully. It is false when the session starts. It is not persisted. It is authoritative game state.

Section 1.2 of D16 gains an item:

5. Continue availability. It is true only when the saved-game eligibility indicator (D16 1.4 item 3) is true, item 16 of section 1.1 is false, and the saved game passes the validity rules for persisted content. It has no independent semantic authority. How Continue is shown is presentation state (D16 1.5).

Section 1.4 of D16 gains an item:

3. The saved-game eligibility indicator, a stored value. Only the exact stored value "true" makes a saved game eligible for Continue. Any other value, or no value, means no saved game is eligible.

## 2. Validity of item 16

In every mode, item 16 is true or false. Nothing else is a valid value. This adds one predicate to the R1 text and changes no existing R1 predicate.

## 3. Scope

- It adds the three items above and states no behavior. When item 16 becomes true or false and what happens on storage failure belong to the R2 to R5 decision text (`docs/phase-1-r2-r5-decision.md`, ledger row D21).
- It adds no sixth category and moves no existing item.
- It does not change items 1 to 15 of D16 section 1.1, items 1 to 4 of section 1.2, items 1 and 2 of section 1.4, or sections 2 to 10 of D16.
- It does not change REQUIREMENTS.md and authorizes no code change.
