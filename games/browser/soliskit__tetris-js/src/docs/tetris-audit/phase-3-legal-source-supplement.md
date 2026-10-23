# Allowed State Changes

The cited decision rules for nineteen legal-operation rows.

This Candidate citation record is a read-only check against fetched PR78. It changes nothing in PR78 and none of the requirements, rules, model, production, tests, or CI. It checks citations and content, not independent adoption provenance, runtime frame proof, a complete writer inventory, or certification. Governing decision status remains in the ledger and original owner exchanges. Document wording is not authority to act.

Existing L03/L19 were not the nineteen pending rows and remain outside this supplemental check. Source hashes below are actual Git bytes from the fetched head, not reconstructed API text.

## L01
L01 confirmationopen: assignedA10pending/A11Cancel,onlypaused. F allothers. W03,W22. Checkpoint relation pendingGMversusdeferredfocus unresolved. Source-citation check pending for this row; do not treat its assignments as independently verified.

Source: D32 Part A op1 line15; D18 B12 lines51-55; REQUIREMENTS STA-1 line62
Check: Confirmed for confirmation open only while paused. A10 pending/A11 Cancel. No ordinary gameplay assignment.

## L02
L02 selectionchange: assignedA11only whilepending. F allothers. W23,W24. Nativefocus/checkpoint mappingopen. Source-citation check pending for this row; do not treat its assignments as independently verified.

Source: D32 op2 line16; STA-1 line62; INP-4 line87; D18 B12
Check: Confirmed A11 selection while pending. Physical-input bookkeeping may be a separate operation; native DOM focus correspondence not proved.

## L04
L04 direction/controlpress: A12token ordered (modifiedCmd/Ctrl/Alt neverheld);gameeffect separatelegaloperation. A13progressiononlywhenrepeatstarts underL06. W25-W27. F remaining,composition recordrequired. Source-citation check pending for this row; do not treat its assignments as independently verified.

Source: D32 op4 line18; D18 B12; INP-3 line86
Check: Confirmed A12 physical token/order; modified presses never held. Gameplay effect is separate. A13 progression requires repeat operation, not arbitrary control press.

## L05
L05 direction/controlrelease: A12tokenremoved/newestremainingwins;disconnectreleasesallINP4;repeat consequenceL06. W25-W28. Release-repeat timingpartial notguessed. Source-citation check pending for this row; do not treat its assignments as independently verified.

Source: D32 op5 line19; D18 B12; INP-2 line85; INP-4 line87
Check: Confirmed token removal/newest remaining. Disconnect releases everything in INP-4. Repeat timing and held-on-resume suppression require C3/E2/E3.

## L06
L06 repeatprogression: A13phaseadvances,idlewhenpaused/over/blur;eachrepeat move/softdrop nested. Resources stopwithmode. W27-W29,W08,W19. A12doesnotbecomearbitrarydiscardablefromphase rule. Source-citation check pending for this row; do not treat its assignments as independently verified.

Source: D32 op6 line20; D18 B12/B13; INP-2 line85
Check: Confirmed repeat phase/progression and nested moves/soft drops. Phase idle while paused/over; blur stops repeat. B13 distinguishes outstanding firing from handle.

## L07
L07 touchbegin: A14perB12/INP5;controlsactualfallingpiece. F rest. W30. No sourceautomaticpauseinputexception. Source-citation check pending for this row; do not treat its assignments as independently verified.

Source: D32 op7 line21; D18 B12; INP-5 line88
Check: Confirmed gesture state A14. Only original falling piece is controlled under INP-5. Does not authorize input while paused or unlisted A-item changes.

## L08
L08 touchupdate: A14plusnestedmove/softdrop allowedsets;onlyoriginalpiececontrolled. F rest. W31. E1committedmoves retained,no rollback inferred. Source-citation check pending for this row; do not treat its assignments as independently verified.

Source: D32 op8 line22; D18 B12; INP-5 line88; D34 E1 line9; D16 section4 lines76-83
Check: Confirmed A14 and nested move/drop compositions. Already committed moves remain after excursion. Full operation/frame relation remains unproved.

## L09
L09 touchend/cancel: A14none;rotationnestedonlyneverbeyond10px andendswithin10px,notcancel. F restexceptlegalrotation. W32/W33compositehidden relationopen. Source-citation check pending for this row; do not treat its assignments as independently verified.

Source: D32 op9 line23; D33 C2 line11; D34 E1 line9; D18 B12
Check: Confirmed A14 none on end/cancel. Rotation only on end, never cancel, never beyond10px and finalpoint within10px. Previously committed drag effects are not undone.

## L10
L10 move/rotate: A2legal iffits plusA9/A15exactB9.2events. F rest except explicitlynestedlock ifrule triggers. W10,W11,W18. Source-citation check pending for this row; do not treat its assignments as independently verified.

Source: D32 move/rotate line29; D18 B9.2 lines33-43; REQUIREMENTS PLY-1/6 lines41/46
Check: Confirmed A2 plus exact A9/A15 events. Lock only as separately sourced consequence. Unchanged failed fit not a reset grant.

## L11
L11 gravity/softdrop: A2down,A15/A9fallrule;rest/lock consequences separatelynested;softdropgravityrestart runtimeeffect. F others. W12,W13. Source-citation check pending for this row; do not treat its assignments as independently verified.

Source: D32 gravity/softdrop line30; D18 B9.2; PLY-2/3 lines42-43
Check: Confirmed fall A2/A9/A15; softdrop scheduler restart explicitly PLY-3. Lock requires separately sourced composite; no blanket frame permission.

## L12
L12 harddrop: A2landing thenL13lock. W14. Source-citation check pending for this row; do not treat its assignments as independently verified.

Source: D32 harddrop line31; PLY-4 line44
Check: Confirmed A2 to landing then lock. Complete lock composition needed; this row alone does not prove all lock writes.

## L13
L13 lock: A1blocks/rowshift,A7score,A2fromA5,A5refillA6,A6refillwhenempty,A4available,A9zero,A15maxnewpiece;A14no longercontrolsoldpiece;ifnoplaceL18over;completedturnsaveC1 includesnextpiece,nooverturnsave. W15,W16. A3 preserved (exceptlateroversemanticabsence). Source-citation check pending for this row; do not treat its assignments as independently verified.

Source: D32 lock line32; D18 B8/B9.2/B12; D33 C1 line9; SCO-1 line54
Check: Confirmed board/score/current/queue/bag/holdavailable/count/lowest/control-original-piece effects. Completed-turn save includes nextpiece; no save when turn ends over. A3 retention conditional on ordinaryover semanticabsence.

## L14
L14 hold: A2/A3swap orincomingfromA5/A6,A4consume,A9zero/A15newinitial;no-roomL18. W17. Source-citation check pending for this row; do not treat its assignments as independently verified.

Source: D32 hold line33; PLY-7 line47; D18 B8/B9.2; STA-3 line64
Check: Confirmed A2/A3 swap or queue/bag incoming, availability consumed, new count/lowest, no-room ordinaryover. This is successful Hold, not any rejected press.

## L15
L15 pause/pagehidden: A8paused,A9pausecountwhilelockdelay,A13idle;gravity/lock/repeatstopped,save. D32doesnotexplicitlyassignA14forpagehidden,sohiddenreset needsseparatetouchcancelcomposition,not silentlyaddedmask. W08,W33. Source-citation check pending for this row; do not treat its assignments as independently verified.

Source: D32 pause/pagehidden line34; D18 B9.2/B12/B13; STA-2/4/5 lines63/65/66; D23 U4
Check: Confirmed A8 paused,A13 idle and stopping resources. A9 changes only during lock delay; count15 becomes16. No D32 A14 pagehidden assignment, so touchcancel composition still open.

## L16
L16 resume:A8playing;count16restinglocks immediately,count15restingdelaystarts;heldrepeat suppressionC3/E2/E3,representationopen. A12tokensnotarbitrary newdiscardpermission;A13idleheld-suppressed untilrelease/newpress. W09,W27-W29. Source-citation check pending for this row; do not treat its assignments as independently verified.

Source: D32 resume line35 (count16); D18 B9.2 line45 explicitly paused resting count15 starts delay; REQUIREMENTS PLY-6 line46; D33 C3 line13; D34 E2/E3 lines11/13
Check: Confirmed A8, restingcount16 instant lock/count15 delay. Every repeating control held at resume suppressed until released/repressed. A12 representation explicitly undecided, not arbitrary discard permission.

## L17
L17 Continue:A1-A9/A15restoredexactly,A8paused;freshbagonlymissingsavebag,A16unchangedC4;controls/cancelprojection requireseparatesources. W07,W21. Do nottreatload-as-spawn resetpermission. Source-citation check pending for this row; do not treat its assignments as independently verified.

Source: D32 Continue line36; D18 B9.2/B16; D33 C4 line15; STA-4/6 lines65/67
Check: Confirmed exact A1-A9/A15 restore paused, freshbag only missingbag, A16 unchanged. Missing legacy resetcount default is not defined by these clauses; do not invent zero.

## L18
L18 ordinaryover:A8over,A16withdraw;allU4timersstop;A2/A3/A4/A6/A9/A14/A15lose semanticvalue,clearingnotrequired;A5stillvalid3,A1/A7retainedunlessauthorized precedinglock effects. W16,W17,W21. Source-citation check pending for this row; do not treat its assignments as independently verified.

Source: D32 ordinaryover line38; D18 B6/B8/B10/B12; STA-3 line64; D21 S2/S9; D23 U4
Check: Confirmed modeover/timerstop/withdraw,A2/A3/A4/A6/A9/A14/A15 semanticabsence,not mandatoryclearing. A5 remains3; A1/A7 retention absent authorized precedinglock. Not fault projection.

## L20
L20 opening: initialstateB1/B7;A16false;A13idle/A14semanticallyabsent/A11absent perstate domains; initialheldtoken contents need source/physicalinput relation,not inferredemptyrequirement. NotordinaryD32legalactionframe. W01,W02. Source-citation check pending for this row; do not treat its assignments as independently verified.

Source: D18 B1/B6/B7/B12/B13; STA-1 line62; D21 S9 line25
Check: Confirmed opening valid ordinaryover,queue3,repeatidle,selectedchoiceabsent/touchsemanticabsence,A16false. Physical token contents not specified as empty. Opening not D32 ordinary operation.

## L21
L21 persistence-only/read/event: maychange external/cache/presentationstate withoutcommittingauthority;A16changesONLYS9lifetime effects andacceptedContinue maycommitsavedAitems underL17. W20,W21,W35. Source-citation check pending for this row; do not treat its assignments as independently verified.

Source: D16 section4 lines76-83; D21 S7/S9 lines21/25; D33 C4 line15; D32 persistence line41/Continue line36
Check: Confirmed external/cache/presentation routes not granted authority; A16 lifetime set only withdraw/attempt, clear sessionstart or successful same-session save. Accepted Continue commits L17 state; external session save does not clear A16.

## Limits
All nineteen row claims are traceable with the conditional/composite qualifications above. Keep Candidate/Not Assessed for implementation relations. Most W anchors remain unchecked. The missing legacy count source gap, live UI/focus/physical token/repeat/touch mapping, hostile adapters, dependency coverage, O8 provenance and universal-frame evidence are not closed. The earlier D43 record remains a historical statement of checks pending at that time. This supplement records later bounded citation work, not runtime completion or Phase 3 closure.

## Independent review scope
Independent citation review reported no error and hashed all nine snapshot files against the governed ledger. It checked the cited D32 operation lines and selected D18/D33/D34/requirements clauses, but did not read every clause of L18/L20 B references, the full L08 E1 sentence, every W anchor, runtime relations or original adoption evidence. This is a bounded independent citation review, not exhaustive independent verification.

## Source identities
REQUIREMENTS.md SHA256 fa2580d6bf0a67dd80d5e569da363776a029a79caef457604c7efe74ea72f7bc
docs/phase-1-state-decision.md SHA256 0ca7916f67e1b6a2e784272af15732b018b41ed70f3ec0fe05ceb72a5dcc0bad
docs/phase-1-r1-decision.md SHA256 aacf5189a6aa3b21660e8bfe1a5bf8ab2d62f8e853df3febaa54d81412707dec
docs/phase-1-r2-r5-decision.md SHA256 2d2de112e371b8b23094652bcb8c991d8d2c6097575a4c61c059a21292b93ed8
docs/phase-1-frame-principle-decision.md SHA256 f2b734876e031b70bf47a618845091deb97e93658b329331d94cca5db311cb41
docs/phase-1-operations-record.md SHA256 9e0a7db4b0423e8c831e265deca6ee2b66df4db1684995c9d070eaead0770101
docs/phase-1-operations-choices-decision.md SHA256 a4aa77c0d2d049f81c017c56dc07f48e96180197bbf7c2366a7fe17b68cee2aa
docs/phase-1-operations-choices-2-decision.md. See [DECISIONS.md, D34](https://github.com/soliskit/tetris-js/blob/main/DECISIONS.md?plain=1#L94), for the D34 fingerprint.
docs/phase-1-trust-and-timer-scope-decision.md SHA256 0d7f14fd13d1eeb4064fd4064eabf18f6f2066b76e74be999d71b5c71522e75b

Status-label publication identities

The REQUIREMENTS.md source hash cited here identifies the historical source used by this record. It is not the hash of the later restyled publication copy. Normative requirement-ID rows are unchanged; the migration receipt records current publication identities separately. Other source hashes and byte counts in this record retain their original historical meanings.
