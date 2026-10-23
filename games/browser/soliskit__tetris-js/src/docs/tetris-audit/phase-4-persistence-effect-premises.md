# Storage Effects and Missing Evidence

The inspected storage writes and the evidence needed to assess their effects.

Working source ledger against main. This enumerates the direct storage write call sites in the inspected public source plus their current engine callers. It is not an exhaustive alias/native/concurrent-actor theorem or a new execution. No existing finding is reclassified here.

## Direct effect sites

The inspected public JavaScript has three direct storage.setItem sites, all in gameManager.js: high-score setter150, eligibility setter167, payload221. Their callers below are different semantic effects even when they share a setter. Memory-storage implementation and service-worker cache APIs remain separate domains.

| Caller / source | Before effect and subsequent boundary | Successful effect | Provider failure and later effects | Independent premise still needed |
| --- | --- | --- | --- | --- |
| NewGame reset181-194 | Paused mode, empty board, score0, resetBag, current spawn, queue, held/availability and count reset precede eligibilityfalse; outer guard checks after reset returns | Writes false; withdrawal then play and gravity | Factory/spawn/queue/cancel failure can enter safe stop beforefalse; false-write refusal is swallowed | S2 trigger at confirmation, earlier-failure distinction, actual session-history withdrawal. Prior-good payload is not needed for the trigger itself |
| Continue missing/unreadable or invalid content | Eligibility and payload reads precede parsing. A null payload returns before a storage write; for a payload that fails validation, withdrawal is attempted | Null leaves storage alone; invalid content attempts false and stays over | Read failure returns null; invalid-content false-write refusal is swallowed | Separate failure points in the code, not full refusal or prior-good-content proof |
| Save payload219-225 | Serialize evaluated before setItem payload; no separate return flag | Writes new bytes then eligibilitytrue | Serialization/payload throw ->false; true setter catches its own failure, so no catch-levelfalse follows that refused true | Distinguish nonstorage serializer failure, payload failed/succeeded, eligibility failure and completed valid content. No successful call-return shortcut to S6-good |
| Save success eligibilitytrue222 | New payload effect already succeeded | True stored, cache invalidated | True write fails and is swallowed; raw oldtrue/oldfalse may remain | Whether code meets the [Save decision](phase-1-r2-r5-decision.md#save) success rule at every failure cut remains open |
| Save catch eligibilityfalse224 | Serializer or payload effect failed | False stored | False refusal swallowed; old flag persists | S5 failed-save withdrawal and S4 same-session restriction, not automatic payload deletion |
| Next-piece no-room238 | Queue/current/bag/holdavailability/count writes precede no-fit decision and over | False stored; stops gravity | Refusal swallowed; gravity stop can later throw | No-room semantic current absence and S4/S9 history; independent preserved content separate |
| Held-swap no-room568 | Gravity/lock stopped, incoming spawned and checked beforeover; current not assigned incoming | False stored | Refusal swallowed; callback reporting later | Same withdrawal rule, distinct prefix from empty-held next-piece branch |
| Clear high-score349 | Board row removals and score update complete; read high, compute max then write; nextpiece/save/outer check later | High stored | Read throw returns0; write throw swallowed; nextpiece may later throw | Exact stored-number domain and lower-write dispositions already separate; no cross-tab atomicity or actual all numeric syntax theorem |

## Contextual boundaries

The payload writer is reached by Pause after timer/count mutation and by a successful line-clear turn after nextpiece generation, only while still playing. A no-room line-clear turn does not save. A same-step later fault does not roll back valid successfully written content under S6, but that conclusion requires independent B16-good content and successful effect provenance.

failSafe itself sets over and tries gravity/lock cancellation and reporting; it has no direct payload/eligibility/high-score write. This is not all fault composition: a preceding operation may already have written or attempted withdrawal. Failed cancellation may escape before later report attempts. Controller repeat resources and visible notice are separate from the two manager timer handles.

storageChanged invalidates cached eligibility; it does not itself store a value or encode the session withdrawal history. Cross-tab events can call it outside the engine guard. An unchanged cached/stored true is not proof that S4/S9 permits Continue.

## Independent-good-content bottleneck

Both retained released fixtures pass selected static content predicates under the published kind/token relation, but lack reset count. Their introduction account and historical serializer schema are not original capture/history attestation. The new-writer source omits reset count and lowest. The reviewed paired-count information-loss finding proves that at least one of two same-payload histories is not exact; it does not prove that no payload can be good, or identify a particular good one. Full F20/S6 preservation cannot be closed by assuming all saves invalid, by selecting count0 as a default, or by treating a parser pass as goodness.

A valid last-good witness needs exact raw bytes, unique independently justified semantic denotation including count/lowest or applicable approved legacy relation, successful write evidence and prior engine/history binding. No new missing-count default or blanket legacy limit is adopted. Existing S7 no-write and S2 withdrawal-trigger comparisons can progress without that last-good premise; they must not be withheld solely because F20's premise is incomplete.

## F24 reconciliation

The existing Confirmed conditional-source S7 finding covers eligibility-read failure with no payload read (now recorded in DECISIONS.md, eligibility-read failure disposition). The failed-payload-read prefix is an additional cut within the already-open F24 family, not a new family or full F24 closure. The two prefixes do not authenticate one another's historical raw receipt.

## Remaining work

For each source effect above, attach the existing actual receipt or conditional source disposition, mark exactly which cuts it covers and carry uncovered cuts forward. Native provider failures, concurrency, complete notice/resource effects and valid prior content remain. Current call-site enumeration does not certify all writers, routes or the full phase. Correction preparation and implementation approval are separate.
