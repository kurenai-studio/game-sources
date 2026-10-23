# Source and Independent Methods

Published method descriptions, with historical and current scope kept separate.

This publication candidate describes domain methods from the exact held sources below. It excludes operational routing, permission, and review mechanics. Those omissions cannot widen method or evidence scope. The original sources and claims still govern. Each text is derived for publication and is not claimed to match its held method source byte for byte. There is no new measurement or independently inspected pixel result.

Historical methods below may contain labels that were pending at the time. Current clause support and the current63 record replace only absent-statement or review labels where later actual methods or reviews exist. The independent whole raw classifier and field projection are now stated. The centering allowed-set and independent kick data are stated. Targeted fidelity reviews were completed. Finite adverse and conditional evidence is unchanged. These updates do not make the original method text a stronger execution.

## board-piece-route-method-v1.md

Held source SHA256 `ca78d61d58d6e58b8e150ad1aee0f9c9e7c3caa73fe32183155ca9b205d04117`.

# PCE-1/PCE-6/STA-3 current route argument preparation

Private claim-appropriate static method artifact, not globalproof/exhaustion/statuschange. Read actual source copies public1e09ad61. Existing D44 static Wanchors/citations, D42 fit48125/movement675, D43 lineclear24, D45Hold/bag, D46ghost and V28successfulrestart evidence are separate. This argument doesnotprove mutability/reachability/externalaliasabsence. Applicable source expectation: B5board20x10; B6fittedfallingpiece playing/paused, ordinaryover semanticabsence; PCE6commitpolicy separateintermediatewrites/faultretention.

## Board dimension preservation under named ordinary writers

- Constructor GM115 and NewGame GM184 use createBoard(rows,columns), GS42-44 independent Array.from argument: each of rows arrays contains columns empty cells. Fixed manager rows20/columns10constructor values provide B5dimensions; exposed mutableconfiguration/directinvocations excluded from this boundedordinaryargument, notassumedharmless.
- Accepted Continue GM208 assigns session.gameBoard. parseBoard SES76-96 rejects unequalouterlength/rowlength and reconstructs fresh cells. This maps acceptedproductionformat dimensionpredicate only; strictfullrow rejection is independent B15candidate and cannot validateall R1 content. Wholeparserindependentclassifier stillmissing.
- Lock GM327-331 writes cells, not arraydimensions, provided everypiececell inbounds and eachrowexists. Required prestate relation is PCE6fits at commit; monitor afteroperation doesn'tbyitselfprove itbefore lockwrites. Failure may leave partialboard underfaultretention, not ordinaryproof.
- clearFullRows GM334-350 collects unique indices from forEach; reverseorder splice removes exactly krows, unshift creates krows ofcolumns cells. Thus starting wellformed20x10 and ordinarycompletion preserves outer20/inner10. Within ordinaryproductionlegalplay startingwithnofullrows, only rows touchedbyfour lockedcells can newlybecomefull, hencek≤4 is a candidateinductionprecondition. Loaderrejectsfullrows even thoughB15doesnotrequirethatR1snapshotconstraint. k may exceed4 for R1validstatewithprefilledfullrows, so scoretableundefined is separate SCO1/B15/legalhistory relation. Do not quietly strengthen R1nofullrows from loader or gameplaytests.
- Search of gameBoard replacement/inplace mutation in sevenenginefiles found constructor/reset/load/lock/clear routes above. External exposedaliases/directcalls, unexpected setters/invalidretainedfault state are excluded unresolvedclasses. The search doesnotestablish complete reachablewriterinventory.

## Piece position/rotation admission by route

| Transition/source writer | Admission or source argument | Concrete commit/checkpoint | Evidence/missing relation |
|---|---|---|---|
| Constructor GM113 | Unguarded source-generated spawn while opening modeover: concretepiece has no B6ordinaryover semanticvalue. No claim of fittedconstructorcommit or ordinaryaction checkpoint. | Outside guardeddispatch; factory/spawn exception can interrupt bootstrap. | Explicitopeningroute, separate semanticinitialization/dependency/faultboundary evidence remains missing. |
| NewGame GM189; Tetromino.spawned59-64 | row0,coltruncatedcenter on empty20x10 and built-in shape→fit boundedsourceargument, notcenteringtieoracle. | GMhandleAction guard thenmonitor playing; constructor isn'tguardedordinaryaction. | D45NewGame5040bag evidence; geometry25offsets. Fullspawnsemanticchoice/constructorrelationstillpartial. |
| Move GM553-555 | fits(board,newPosition) before assignment; blockedmove no positionchange. | Outer guardeddispatch thenmonitor; directhelper exposure separatelyunproved. | D42fitprimitive/movement+ledgebounded; physicalinputroute separateINP. |
| Rotate Tetromino144-146 | each candidate geometry fits before state+position assignment. | Two writes withinnestedhelper; outerrotate thenmonitor. | Fitadmissiondoesnotadopt productionkickorder/oppositedirectionfallback asPCE4expectedbehavior. K1partial. |
| Fall GM246-253 | !isOnSurface means fits(board,below) from GM260; thenassignbelow using immutable-value construction. | Nested drop→landIfResting→gravityrequest thenpostcheck; callbacks useguard. | V28onefallrestart/row, D42movement; temporalalias/writer changesbetweenpredicate andassignment notprovedglobally. |
| HardDrop GM542/ghost353-356/Tetromino.dropDistance115-122 | startingfit+monotonecelltranslation loop returns lastrowbeforefirstblocked nextrow. | Assignghostposition thenlock/spawn/completedturn optionalsave, outerpostcheck. | D43clear24/ghostbounded; startingfit/preboardunchanged/boundtermination needs appropriateassumptions. Canvas classifier notprimitiveproof. |
| Next afterlock / emptyHold GM230-242 | spawnnext, thenfits; no-room commitsmodeover/withdraw/stopsgravity; ordinaryover currentpiecehasnosemanticvalue. | Piece assigned before fits; modeover finalprojection distinct from intermediateinvalidpiece. | No universalintermediatevalidityclaim; normalgameover/resources/fault handling separate. |
| Heldswap GM565-574 | incoming.spawned thenfits before assigning ascurrent; ifno-roommodeover/withdraw, priorconcretepiece semanticabsence. | Holdstopresources first, thenassign/reset/land orover; outerguardpostcheck. | D45Hold traces narrower; top-out allkinds/boards unexhausted. |
| Continue SES107-114/GM211 | built-inkindrotation/wholeposition andfits before returnedactivepiece assigned. | acceptedpausedstate + lockcount/lowest reset, guardedContinuemonitor checksfitonlyplaying, notpaused. | Activepiecefitonlydoesnotestablishheld/queuevalidation. Primitiveadmission held, wholeB16restoration/parserclassification andlegacydefaults stillpartial; no usemonitorasoracle. |

## Ordinary game-over caller inventory (STA-3)

Actual modeover assignments: constructor107(opening), failSafe437(fault, notordinaryno-room), generateNextTetromino237(nextqueue nofit afterlock or emptyHold), heldincomingHold567(nofit). NewGame createsemptyboard and doesn'texplicitlynofit; a malformedfactory/shape failure belongsfault/exposeddependencyclass, notordinarytop-outbyassumption. Source NewGame/factorynewpiece fits requiresbuilt-inwellformedconstructorarguments. Callsites GM320lockAndSpawnNext→generateNext; GM575emptyHold→generateNext. Distinguish fault fromordinarytop-out andsemanticabsence frommandatoryclear. Actual storedflagfalseassignment is not independent successful withdrawal or sessionA16 semanticproof; failure/cacheeffects remainseparate. This staticlist fills route naming/methodfield but not per-route runtimeeffects/resources/withdraw history.

Next independent checks: reviewer staticrouteargument fidelity and preconditions; bounded onecase-perordinarytop-outroute with independentsemantic/resources/withdraw projection, notallboardexhaustion. Existing publicOtop-out and other probes shouldbereconciled beforeextraexecution. No newcentering/kick/modelchoice adoption, no permanenttest/production/CI change. Phase3stillopenwhere relation/evidence unstated; remaining domainsPhase4/dispositionsPhase5.

## checkpoint-admission-method-v1.md

Held source SHA256 `edf739e1f5005aec2b75e5e7a4b64e92db35f776a6ae107e6af3d67029edc5f5`.

# O7 / SAF-4 admission, check and fault method inventory

Current concrete GM source31bb2160 and other public bytes1e09ad61; source D16 transition boundary, D32 operation assignments and Z1 frame rule independent of production monitor. Static mapping/method, not proof that every writer is protected or reachable. W01-W35 historical inventory remains broader and preserves individual unresolved classes.

## Concrete guard order

GMhandleAction459-460 invokes guard with performAction. schedule383 wraps eventual callback in guard. guard389-392 runs runChecked then onChange. runChecked395-408 performs operation then findInvariantViolation inside try; operation/check throw calls failSafe and returns; reported violation calls failSafe after try. onChange outside catch can throw after ordinaryoperation/check. failSafe stateover/stopgravity/cancelLock precede independent caught fault-array/onFault attempts: not every dependency failure during safe conversion is shown contained merely from catch at caller. Timing/registration/cancel fault records D42-D44 remain separate bounded evidence.

## Actual monitor predicates versus source domains

The table below and the Continue row above describe the historical `gameManager.js` source identified in this method, not current main. [PR171](https://github.com/soliskit/tetris-js/pull/171) later added checks that queued pieces and the current falling piece are valid, including the falling piece while paused. The changed checks are at `gameManager.js:421/422/424`. The earlier results keep their original scope. Linking to the change does not verify those results against current code or show that every other missing check was added.

| Predicate / code | Admission/check scope | Independent domain / omitted relation |
|---|---|---|
| Board outer/row lengths GM413-416 | After ordinary guarded op/callback; configured rows/columns | B5 semantic20x10 cellkind/null validity not checked; exposed dimensions/aliases require own preconditions. |
| Queue count GM417 | nextTetrominos.length only | B7 validthree kinds versus runtimecheck elementvalidity reading remains separate; malformed arraylike/element not independently classified by count. |
| Score GM418 | SafeInteger/nonnegative/divisible100 | B3/B11 whole nonnegative noformat/divisibility cap. Monitor restriction not sourceoracle. |
| Current fits GM419-420 | Onlyplaying | B6paused current validity and geometry/kind/orientation relation not fully checked; absentordinaryover projection different; malformedfault contents notordinaryvalidity. |
| Gravity GM421 | Playinghandle !==null | B13outstanding firing not handletruthiness; failedcancel/nativecallback relation external. |
| Lock GM422-423 | Playinghandle presence versus isOnSurface | B13semanticresource requires ledger, surface requires independent B14fitrelation. Resetcount15/16/lowest/history notchecked. |
| Nonplaying timers GM424-425 | GMgravity/lockhandlesnull | IC DAS/softdrop intervals, T timers, constructor polling and otherresources not covered. Pausedrepeatresource candidatev25 remains separately observed. |

## Writer class boundary mapping

| Class | Concrete admission / checkpoint | Method / remaining relation |
|---|---|---|
| Guarded GM ordinarydispatch/callback | Selected mode/fit predicates before nestedwrites; one monitor after composite operation | Per D32 op allowed-write-set, semanticcommit point, prestate and faultconversion must bind. Postcheck doesn't prove before-write fit/noalias or persistencevalidity. |
| Constructor W01/W02 | GMspawn/queue/board and controller initialwrites outsideguard | Opening separateB1validity/bootstrapfault/dependency relation; no fictitiousordinaryop or forcedclearofabsentfields. |
| softDrop W04 | A10pendingfalse before guard then guardedfall | Confirmationother-answer composition/commit source mapping needed; preguardtrivialassignment not automaticexception. |
| A11 native/deferred UI W22-W24 | DOMshow/focus/close outsideGM; nested GMcancel/click guarded | Pendingconditional choiceprojection and native focus/activation checkpoint; v26/v27boundedfocushistory not fullcommitproof. |
| A12/A13 IC W25-W29 | heldaliases/order, movement/interval writes outsideGM; nestedactions guarded | Physicalevent/tokenhistory, timerphase/outstandingledger, C3/E2/E3 expectations separate. pollGamepads catch only logs error; does not establish engine+controlfaultconversion. |
| A14 drag W30-W33 | dragstart/update/reset outsideGM, motion/drop nestedactions | Pieceidentity and eventexcursion adapter plus touchcancel/hiddencomposition required; innerguard notouterframecheck. |
| A16 storage/cache W20-W21 | Settercacheinvalidates before attempt; swallowedflagerror; no explicitsessionwithdrawfield | S4/S9source sessionhistory expected versus storedavailablepolarity. v24failure/externalsave candidate and V32countsave distinct; bytes/flag unchanged not goodcontent proof. |
| Direct helpers / external mutablealiases W34-W35 | Public JSmethods/arrays configurable and directlycallable; guard maybypass | Classify actualauthorizedruntime entry/reachable callback versus arbitraryharness injection first; not automaticexploit or harmlessness. Requirementboundary and dependencytrust drive relation. |

## Claim-appropriate verification method

For every admitted entry, identify source operation and prestate, source-defined authoritative assignment set, candidate concrete writer sequence, semantic projection and conceptual commit/checkpoint, then fault conversion and per-effectpersistence rule. For outer/native classes separately name nested operation versus surrounding writes. Unassigned fields preserve underZ1 only where source isn't silentZ2; never impose wholefieldmask from concrete snapshots. Use existing D43-D49/V28/V32 evidence before new trace work. Remaining Phase3 relation is full claimed-class coverage and valid adapters, not final hostile-domain exhaustion or disposition. Phase4 extends domains; Phase5 classifies discrepancies. No production/model/permanenttest/CI changes or model-author feedback.



## gameover-fault-route-method-v1.md

Held source SHA256 `ad16109555f2c266810764a2e5e240aca84648f73b49e6852889c2457ed70922`.

# STA3 / SAF3 / SAF5 finite route correspondence

This is a static source inventory with independently expected operation and fault rules. It is not a proof of all reachable behavior or a new runtime finding.

Ordinary no-room sites in GM31bb2160: generateNextTetromino tests spawned current fit then sets over/withdraws/stops gravity; holdTetromino held-swap tests fit then over/withdraws with gravity/lock already stopped. Generate-next is called from lockAndSpawnNext and the empty-held branch of holdTetromino; locking is called from lock-delay callback, pieceLanded allowance-exhausted path, and hardDrop. Hold's dispatch is performAction hold. pieceLanded comes through landIfResting called from generate-next, fall, move, rotate, hold and resume. Constructor/NewGame create their opening piece; not ordinaryno-room sites by thisinventory. A nonfitting concrete current after nextspawn has no semantic currentpiece in ordinaryover (B6); no requirement to erase retainedfield. External/directmethod/alias arbitrary calls remain reachability categories, not extra authorizedoperations.

This enumerates finite current GM caller sites and explains semanticabsence, filling the named STA3 caller-table relation. Engine gravity/lock stop is separate from ICtimeout/interval outstanding-resource evidence, which remains partial. Expected withdrawalhistory item16 set on attempt evenflagfailure, no payloaddeletionneeded; v24 contrast bounded. Laterfault doesn'tundo committedwithdrawal (S2); faultstopalone differs (S3).

## Report/notice routes and static absence argument

Actual engine onFault default GMreportToConsole (console.error); page constructs GM with onChange only, no visiblefault callback. failSafe attempts fault-array push and onFault separately after mode/stop/cancel. Actual drawSafely catches draw, resetsrendercaches+DOMsnapshot, console.error once, retries throughrequestDraw. ICpoll catch console.error, keepsconnectedtrue and schedulesnext rAF. These are distinct catches and signals; developerconsole is not playerplainmessage T1a/U2a.

Enumerate page DOMtext/HTML/class/hidden writers: score/highscore labels, announcer ordinarygameOver string, keyhints, playpause label/icon, menu/Continue/over visibility, dialog nativeopen/close and renderingcanvases. None reads faultobject/GMfaults or inserts fault-specific playerexplanation. HTMLstatus GameOver alone does not distinguish enginefailure from ordinaryending. No player-visible faultnotice route in this inspected publicscript/HTML wiring. This is source-search+dataflow absence method over finitecurrent files, not proof everyenvironment lacksofnotice. InjectedonFault testcallback proves signals only in thosefixtures, not publicpage playernotice.

Unprotected stop/cancel escaping failSafe is staticdependency reading, not a new confirmedrun. Browserfault samplesv15-v17 supply bounded actualnocanvas/DOMnotice and retryobservations; enginefieldpreservation not fullycaptured there. No noticeabsence classification/status/patch or allfaultcontainment claim. Actualauthoritative frame/callback resource relations remain O1/O7; independentgoodpayload remains O4. Source/fidelityreviewpending; no newprobes/tests/model/source/CI changes.

Concrete Hold branch distinction: empty-held generateNext may set over, then Hold still assigns heldTetromino and canHold=false; held-swap no-room returns before those assignments. B8 held/hold-used are semantically absent in over, so retained concrete differences alone are not requirement mismatch. Independent P3-D verified callers/GM order and SCfault-reader absence, no runs/source-decision reread; HTMLfaulttext not searched by reviewer, IC/SC identity attributed. Zoomclass toggle added to DOMwriter inventory, no faultreader. Fullreview retained, not allfaultframe proof.

## good-content-checkpoint-method-v1.md

Held source SHA256 `9d0315830d63c6631df0f1f7c836d0191d4f3a7cc68e2354d94cb479aefa544e`.

# O4 independently good content and effect checkpoint relation

Static source/expected method, not new execution or last-good-save certification. Scope GM31bb2160, SES54acbea4; expected R1B16, D20, D21S1-S9, D33C1 and Z1. Raw classifier supplies independent content result; SES output is compared, not treated as validity oracle. Explicit failure to classify is not a good-content finding.

## Named cutpoints and source order

| Route | Actual candidate chronology | Independent checkpoint / claim |
|---|---|---|
| Pause GM486-494 | Set paused; stop gravity; increment reset count only if lock handle present; cancel lock; serialize and write payload; attempt eligibility true; monitor after operation | Source B9.2 pause count distinguishes 15/16; expected before-save semantic board/current/queue/held/bag/score/lowest/count determined from public history or declared independently valid prestate. Save must preserve exact known count/lowest, not assign omission defaults. Pause is not a new-piece event. |
| Line clear GM318-323 | Lock current cells; clear full rows/update score and highscore; generate next (queue shift/new draw/hold availability/reset; possible ordinary over); if cleared and still playing save | D33C1 completed turn includes next current, queue and bag state after dealing. Over caused by no room means no new lineclear save. Serialized score/board alone are not completed-turn correspondence. Postspawn B9.2 reset expected semantic maximum/count0 comes from new-piece rule, not absent payload default. |
| Payload effect GM219-225 | Evaluate serializeSession before setItem; payload setItem success or throw; eligibility true setter follows success; catch sets false on serialization/payload throw | Distinguish serialization failure (no payload call), payload attempt/failure, payload success and subsequent flag attempt/success/failure. A flag failure swallowed by setter does not retroactively show payload failure. The source meaning of successful save across payload/eligibility failure remains an explicitly unresolved operational relation; neither one-function return nor one stored flag settles it. |
| Normal over/NewGame withdrawal | isSessionSaved=false and cache invalidation before flag attempt; no payload deletion | D21S1/S2/S4/S9 item16 set on attempt even when flagwrite fails. Retained payload may be independently valid while unavailable. Polarity cached available is not sessionwithdraw history. |
| Fault after save | operation/check failure enters failSafe, attempts gravity/lock stop/report, does not intentionally delete payload | D21S6 retains successfully written independently valid payload even if later same-step fault. Ordinary monitor acceptance is not independent content judgment; earlier bytes not good without B16 classification. Safe conversion/possible escaping dependency failures remain separately mapped. |
| Continue | eligibility/read then whole parse; invalid branch flag false; success assigns fields/resetBag/resetLock | Independent input classification before all accepted assignments. Failedread differs from invalidcontent; raw output handling alone does not prove S7 or S9. Completed resume history and load count/lowest are separate from saved goodness. |

## Required per-effect ledger

For a bounded evidence row retain session identity, route/operation, independently projected prestate and validity scope, old payload/eligibility, serializer-produced raw bytes, each storage invocation index/key/value/return-or-throw, completed-turn state before payload, postoperation/fault checkpoint and the raw-classifier result. Semantic item16 is expected from source event history independent of flag/cache. Record actual UI eligibility only as its observed adapter. The read/write instrument's failures, trust assumptions and scope are stated separately.

Compute last-good candidate only for a payload whose successful write and independent B16-valid content have both been established, subject to the unresolved save-success/flag-failure relation. No update on failed serialization/write or unresolved content. A later fault preserves this candidate; an intentional withdrawal can retain its bytes while denying Continue. Never relabel retained bytes as last-good merely to compare equality.

## Held evidence bindings and honest gaps

[AUDIT F29](../../DECISIONS.md) records the missing prerequisite: a save written by the game whose content and history have independently been shown to satisfy B16's saved-game rules. Later comparisons show that saving and restoring can lose history. They do not establish such a valid prior save.

- D43 save cutpoints and seven-effect sequence establish attributed actual write chronology. They do not independently establish all payloads' semantic goodness or completed-turn mapping.
- V32 establishes a new-save public O-history count1, omitted count and fresh Continue0. It gives a count-preservation comparison without a missing-count default. Its O-only factory/partial bag scope means it is not a fully B16-certified good payload or general history proof.
- V34 establishes serializer field encoding/schema compatibility with exact historical writers and fixtures; no captured public history, count/lowest, goodness or last-good claim.
- D48/v24 and prior-false contrast establish bounded storage/cache observations against S4/S9 history. Equal payload bytes or reread true are not independent goodness.
- Existing lineclear board/score cases give bounded actual state transitions. Bind next-piece/queue/bag/content/history before any C1/S6 complete claim; no inferred universal reachability.

This file fills the named effect/checkpoint decision procedure for O4/STA4/SAF2. Actual independently good payload and completed-turn content bindings, legacy capture provenance and save-success interpretation remain Phase3 residuals, not replaced by more cutpoint counts. Phase4 expands failure positions/interleavings/native storage domains; Phase5 dispositions remain separate. No permanent tests/executable model/source/CI changes and no clean-author feedback.

Independent targeted O reviewer checked six chronology rows against actual GM31bb2160, source guards and residual statements; no rerun or broader proof. Pause anchor corrected486-494. V34 attributed only, absent from that reviewbundle. Exact original review retained. Named method filled, actual full independently goodpayload/completed-turn proof not claimed.

V36 now independently analyses existing five raw/cutpoint records/scripts, targeted P3D Python outputbyteequal/hashverified. Wrongqueue length2 yields definitive B7-invalid without guessedcount/encoding, literalinvalid syntax reject; otherrawwholevalidity staysunresolved. Cutpoints bind observed payload/flag/read order, failedread-storedfalse contrast, nextdrawthrow beforecompletedturn/newsave and preparatoryrow4save chronology. Fullgoodpayload/turnbytes notrecorded, syntheticstorage and decisionreread reviewlimits remain; no certifiedfinding/closure.

V40kindadapter independently reviewed; V41realSpublichistory18softdrops/floorpause fullpayload/effectsuccess plus Continue now recorded/independentlyrerunNode22/Pythonbyteequal. B5-B11 are independent sourcepredicate evaluation on capturedcontent, not independent prediction of thosecontentvalues (expectedspreadcapture); equalitycapture/raw is selfconsistency. IndependentG6/history occupiedmax19/countpause0→1 versus rawomission/Continue0 supplies preservationrelation. Currentfullpayload is notB16-good/lastgood. No legacycapture/default/native/wholeR1 claim. Fullreview retained.

V42 completed-turn relation independently reviewed: correctedactualpublicdrop calls GMhardDrop; declaredinjectedvalidbottomboard(Oholes4/5) notpublicreachability. Node22actualoutputexceptversion and Python12checks equal/sourcehashesverified. ExpectedG6lockcells(18-19,4-5)/removebothrows/score300/nextcurrentprequeuehead/queuetail+predrawbaghead/bagremaining/holdavailability independentlypredicted from prestate/source, not fromaftercapture. Fullrawsuccessfulpayloadcheckpoint occurs afterspawn oncleared-and-stillplaying path; no-clear lock hasno newpayload sourceguard, not separatelyexecutedhere. Highscoreeffect isprespawn, payload/eligibility afterward. CurrentTspawnmetadata notindependentcenteringoracle; count0 fromnewpiece rule, semanticoccupiedmax1 notconcreteanchor0 identity. Payloadstillomitscount/lowest; no B16-good/lastgood or fullR1 certification. InitialunsupportedhardDropaction failed and initialemptybundle/prematureclaim explicitlywithdrawn; correctedbundle only adoptedasboundedreviewedevidence. Fullreview retained.

Assessment boundary afterV40-42: a missing successful-B16-good payload is not repaired by declaring this writer's incomplete output good. O4 nowhas namedsourcevalidity/effectsuccess decisionprocedure plus independentlyreviewedactual fullbytes/publicpausehistory and completedturnpredictions. A candidate preservationfailure can itself be validPhase3 differential evidence; it neednot be forced intoPhase3proof ofimplementationcompliance. Whether a specifically assertedlastgood/faultpreservation relation needs a separatelyvalid input/prestate remains explicit. Phase4 failurepositions and Phase5 disposition separate.

## raw-format-classifier-method-v1.md

Held source SHA256 `a72b54ebbfe00d79f511ecd6fa43fe16c9be91c0aaff33f61e20c9b758907465`.

# Independent persisted-content classifier and format relation

This written Phase 3 decision procedure is not executable model or test work, full hostile-domain execution, a format adoption, or certification. Its independent expected predicates are R1 B3-B16, D20 item 16, and D21 S7/S11. The SES parser or monitor return is an observation to compare, never expected validity. The source text was reread for this procedure. The adopted G6 fixed table and image define geometry, not production piece arrays. The existing raw-to-semantic field table supplies the concrete encoding routes.

## Two separate inputs

The input is raw text plus a provenance record. Provenance has writer commit/blob/hash, fixture hash, capture session/actions if actually held, new-write versus supported legacy assertion and its supporting evidence, pre-save semantic count/lowest history if known, and read attempt outcome. A payload's optional level, missing bag or similar-looking keys cannot authenticate a version or prove capture. A supplied source identifier is not a release/deployment attestation. Treat read failure separately from contents; no content classifier conclusion follows from an unsuccessful read (S7).

V34 binds both fixture hashes to exact historical Git writers and shows schema field-projection compatibility. The receiver is fixture-derived; no original seed/actions are held, no gameplay capture is proved. The current fixture also matches a with-level writer when its input level is undefined and JSON omits it: current-row equality is not writer discrimination. Ref/blob/hash, not equality, is the identity claim. Commit/ref binding currently coordinator Git-object evidence, not independently checked release chronology. Existing fixtures still have no count; no zero default follows.

## Representation decode before semantic judgment

1. Decode JSON grammar without consulting SES. A syntax error, non-record root, malformed required semantic collection, nonboolean filled/hold field or value of the wrong semantic type is an independently invalid branch when it cannot denote the required domain. A missing authoritative value is not silently zero/null. Record the specific failed source predicate. An unrecognized kind/color token is independently invalid only relative to an independently bound encoding table. R1/G6 do not name color strings: production factory constants supply the concrete encoding lead but not an independent canonical-color oracle. With no independently bound encoding relation, token-to-kind classification is unresolved.
2. Use exact numeric token/value reasoning for whole numbers, rather than Number.isSafeInteger or %100. R1 imposes neither safe-integer range nor divisibility. At precision limits retain the raw decimal token and separate what it denotes from what binary-number parsing preserves. No unapproved high-score text grammar or JSON duplicate-key/ambiguous-record rule is invented; ambiguous decoding gets unresolved representation, not a guessed expected result.
3. Decode board as ordered 20 lists of 10 semantic empty/kind cells (B3/B5). A filled row remains a valid B5 snapshot: B15 expressly excludes a no-full-row condition. Legal history is not required for hand-edited saves (S11). Do not consult parseBoard rejection to alter the expected predicate.
4. Decode current kind/orientation/integer anchor, compute all four occupied cells from G6 and require bounds/empty cells (B6). Decode queue as exactly three ordered kinds (B7), held as none/kind and hold_used as inverse of the concrete boolean (B8). Held none with hold_used true is not rejected merely as unreachable (B15/S11). Stored active/queued/held shapes are not expected geometry; trusted reconstruction uses the independently adopted built-in-kind relation.
5. Decode distinct ordered remaining bag kinds (B10). For authenticated pre-bag supported legacy, B16 requires a fresh bag, not identity to concrete [] installed before next refill. Keep its future draw/randomness relation separate. Unsupported/uncertain format, absent bag or ambiguous version does not gain a compatibility grant by resembling legacy data.
6. Decode score as whole >=0 (B11). Derive level/gravity from B14; earlier-format stored level is ignored under B16. No score earnedness or divisibility test.
7. Continue's semantic mode is paused (STA4/B16). Determine lowest/count from authentic saved fields or independent new-save pre-write history; missing legacy lowest may use L1 only after supported-legacy provenance is established. L1 is greatest occupied block row, not anchor. No missing-count default is adopted. L2 applies only to legacy paused/resting count15 with no distinguishing pause information; it requires delay starting; the resulting count is not specified by the L2 sentence, so no count0 or16 rule is inferred. Known new-save omission of count/lowest is compared to the independently recorded original values (V32 count example), not treated as legacy.
8. Given explicit semantic lowest/count, require B9.1 ranges, lowest >= current block maximum, and count16 only paused/resting. Compute resting independently as inability to descend one cell under B6. Historical B9.2 preservation is a separate comparison, not a B9.1 snapshot predicate. Item16 is session history, not a serialized gameplay value or inverse of cached eligibility.

## Results and comparison

- **Independently invalid**: at least one source predicate is definitively false from decoded semantic content. Reject-whole expected; no assignment of a partly valid prefix. Identify invalid-content withdrawal separately from read failure.
- **Independently valid within defined format relation**: every required semantic value is uniquely established and all source predicates pass. Supported-format evidence establishes expected whole acceptance/trusted reconstruction under B16. For hand-edited persisted state, D21 S11 expressly says it is accepted whole if valid under R1(B16), otherwise rejected whole; that is a separate source for the acceptance converse, not a consequence of B16 necessary-condition wording alone. Application to other/unknown representations remains a source-reading gap, not automatic acceptance. Legal public-play reachability is not required for a hand edit. This result cannot be issued solely because SES accepted.
- **Unresolved relation**: values/provenance/numeric or format decoding needed for judgment are not established. State exactly which missing value or source choice prevents classification. Do not change unresolved into rejection, acceptance or default0. A definitely false independent predicate can still establish invalidity even if other fields are unresolved.

Compare actual parse/load outcome against the independent result, plus separate per-effect persisted bytes/eligibility/session-history ledger. A parser-only replay cannot establish no partial assignment, correct withdrawn history or last-good content. O4 requires content-validity plus payload effect success and completed-turn chronology; equal retained bytes alone are insufficient. Existing finite raw cutpoints stay attributed evidence, not new executions of this procedure.

## Coverage and remaining evidence

This artifact supplies the named independent decision procedure and format/provenance separation for O3/SAF1/STA6. Actual fixture capture authenticity remains unknown; V34 supplies schema replay only. Missing count, G9 numeric text choices, legacy version attestation, bag refill projection and complete per-effect good-content/completed-turn bindings remain explicit. Independent fidelity review of this written method is pending. Phase 4 hostile-domain exhaustion and Phase 5 disposition remain separate.

## Independent written-method review

P3-D checked R1B3/B5-B11/B14-B16/L1/L2 against exact aacf5189 text, no execution/model/repo change. Unknown-kind encoding now explicitly unresolved absent independently bound table; arbitrary-representation acceptance converse not attributed to B16 alone; L2 resulting count not inferred. D20/D21S7/S11 not read by reviewer thisround; coordinator reread them directly, including S11 explicit validhandedit wholeacceptance. Original fullreview retained. Review supports predicate fidelity, not coverage/default/provenance/closure.

V40 current concretekindencoding relation now independently supported: rawfactorygeometry extractedNode26, Node22exceptversion identical; PythonG6-onlyexactbox/orderedstates+separateset/allsevenunique/tokenbijection/Odedupe outputbyteequal. This binds actualtokens to semanticG6kind via definitiongeometry without factorypositionalkindorder/parseracceptance/canonicalcolororacle. Unknown/hexcasealiases and olderwriterbinding remainunresolved; actualmetadata identity notusualcolorcertification, kindalone notwholevalidity. Fullreview retained. Classifier can use these exactcurrenttokens for actualconcretedata; absentcount/provenance/wholecontrol/history predicates stillseparate.

## raw-semantic-save-method-v1.md

Held source SHA256 `6140def9e348349c21b97c366144759a859351dea65ea4648a406c60ee647011`.

# Raw to semantic save relation, bounded source method

Current unchanged SES/GM source; rev6 f958f910. Requirements R1 B16 and B9.2 are independent expected relations, not implementation acceptance. This is written mapping/method preparation, not new execution, a format decision or a complete proof. Historical D43 rawfixtures/cutpoints and D48 withdrawal remain attributed separately.

| Semantic content | Independent source rule | Concrete raw/current route | Projection constraint and method |
|---|---|---|---|
| Board A1 | B5 20x10 cells empty or built-in kind; B16 whole acceptance | gameBoard cells isFilled/color; SES parseBoard rejects each full row (cells local inside for(const row of board), lines82-95) | Decode only actual bool and independently bound kind-to-color; do not use parser acceptance as oracle. Full-row absence is implementation restriction, not silently added R1 rule. |
| Current A2 | B6 kind/orientation/integer position/four valid empty board cells | currentTetromino color/rotationState/position; SES rebuilds piece definitions | Independent G6 adopted table/image maps kind/rotation to offsets. Source factory color mapping identifies concrete encoding but does not make production shape geometry expected truth. Validate all four source-defined cells. |
| Held A3 and hold-used A4 | B8 valid kind/null and bool | heldTetromino color; canHoldTetromino bool | Semantic hold_used = not canHoldTetromino; waiting raw coordinates/shape ignored by current parser. Unknown encoding or malformed type remains rejection/undefined relation, not invented fallback. |
| Queue A5 | B7 exactly three valid kinds | nextTetrominos colors; parser rebuilds spawned pieces | Kind sequence only is semantic queue; raw queued positions do not become extra authoritative fields. Preserve order. |
| Bag A6 | B10 unique remaining valid kinds; pre-bag legacy gets fresh bag per B16 | bag colors or missing -> [] then factory reset | Concrete missing and explicitly empty bag both parse to []; factory resetBag installs that array and generate refills on next draw (TF98-110). Semantic timing of fresh bag is separate from concrete empty-array install. Missing-bag legacy permits fresh bag, not necessarily equality to empty semantic bag. Need released-format identity and later refill input history; parser [] alone not complete correspondence. |
| Score A7 | B11 whole number nonnegative, hand edits need not earned (S11) | score requires safeInteger/nonnegative/divisible100 in SES | Numeric safety/divisibility restrictions are implementation facts; no silently narrowed source domain. Decode exact value where representable, classify inability separately. |
| Mode A8 | Continue restores paused | payload has no governed mode; GM load sets paused | Loaded paused state is independently expected. Raw payload mode field if extra does not become semantic authority. |
| Reset count A9 | B9.1 0..16;16 only paused/resting; B9.2 Continue restores saved count, B16new writes preserve exactly | Serializer does not emit count; load resetLockDelayForNewPiece sets0 | Missing raw count has no adopted absent-count default. Do not silently construct count0 valid oracle payload. A concrete0 observation is behavior, not source-approved reconstruction. Need historicalwriter/format identity and independent expected count when known. |
| Lowest A15 | B9 occupied-block maximum history; B16new writes preserve exactly; L1 missing legacy lowest=max occupied block row | Serializer does not emit lowest; load reset sets piece anchor row | L1 may apply only supported legacy format; not blanket new-save default. Anchor row is not semantic block maximum: use source offsets to compute max(row+dr), never identity-map GM lowestRowReached. Rotation/history relation must be separate. |

## Independent checkpoint procedure

1. Label format/version/new-save versus released legacy from original writer evidence, not just payload looks. Keep absent-count source partiality explicit. Current parser reconstructs declared fields and ignores optional extra fields; this is source reading, not an executed hostile-schema proof.
2. Build an independent semantic pre-save record from event/history and source-defined fields. For lowest/count, source-based history must accompany concrete observation; zeroed loaded count does not validate reconstruction.
3. At each persistence effect, label payload-write attempt/success separately from eligibility-write attempt/success, session identity and semantic withdrawal history (S1/S4/S9). Actual setter GM164-175 invalidates cache before attempting flag write, swallows write error, then later getter may reread retained true (v24 independently rerun). Bytes unchanged is not good-content validity; cached eligibility true is opposite polarity and not item16 history.
4. Compare successful payload content and independent semantic validity under B16; only then S6 last-good-save applies, including later fault retention. Success definition across payload-success/flag-failure remains recorded scope gap, not inferred away.
5. At Continue compare all restored semantic fields and whole-reject outcome using independent predicate. S11 legal-play reachability is deliberately not required. Preserve read failure (S7) versus invalid content behavior as distinct cases.

Current rev6 validate_save consumes semantic reset_count as required field, optional lowest defaults to occupied maximum, optional bag supplied flag. This is a semantic oracle format, not acceptance of actual JSON schema. Rev6 comparison requires explicit raw-to-semantic adapter, source-grounded unsupported/partial outcomes and preflight before external callbacks. No source-produced save bytes alone can establish validity, no silent count0/defaultchoice, no production/model/permanent-test/CI changes.

Remaining Phase3 relation: independently good content plus per-effect commit/checkpoint semantics and raw format provenance. Later Phase4 adds hostile format/value/failure/interleaving domains; Phase5 dispositions. Written mapping alone does not complete all claims.

## Fidelity review scope

P3-D reviewed this file and concrete source subset only; no execution, model read, B16/B9.2/S11 text read, historicalformat provenance or checkpointverification. Coordinator rechecked full parseBoard loop: cells initialized per row, cells.every inside row loop, so each full row rejected, not only full board. Bag timing and setter invalidation/writefailure v24 boundaries integrated. This review does not attest independent semantic validity or last-good-save proof.

## input-route-method-v1.md

Held source SHA256 `58255173d559b2508915f8e118b2cbd1324c978dc6d5b5aed1ed58292bf2cbde`.

# INP-1/INP-3/STA-5 current input-route mapping method

Private static source/method preparation. Not full input-domain/default-action/browser/runtime proof or new interpretation. Source copies currentpublic1e09ad61; actualsourceIC31-47/119-170/SC516-547 inspected. Original INP1bindings read independently from REQUIREMENTS. Engine effects nestedsourceguards separate outertokens/resources/default actions.

| Physical event code | Requirement action | Actual canonical/dispatch route | preventDefault/readiness relation |
|---|---|---|---|
| KeyA / ArrowLeft | Left | ArrowLeft aliasesKeyA, startMoving(moveLeft)→GMhandleAction, release→resumeHeldMovement | Ordinaryhandledpress/release preventDefault; held-modifiedpress returnsbefore prevention; modalArrowLeftselection separate. |
| KeyD / ArrowRight | Right | ArrowRight aliasesKeyD, startMoving(moveRight)→GMhandleAction | Sameordinarydefault/release; aliaseslosephysicalidentity perD47/D48. |
| KeyW / ArrowUp | Clockwise rotate | aliasesKeyW→KEY_ACTIONS.rotate→GMhandleAction | OrdinaryhandledpreventDefault; modalnon-arrow-left/right controls notsent togame. |
| KeyZ | Counterclockwise rotate | KEY_ACTIONS.rotateCounterclockwise→GMhandleAction | OrdinaryhandledpreventDefault. |
| KeyS / ArrowDown | Soft drop | aliasesKeyS→GMsoftDrop immediatepress; updateSoftDrop controlsrepeat | OrdinaryhandledpreventDefault; distinctGMsoftDrop preguardpendingclear/context. |
| Space | Hard drop | KEY_ACTIONS.drop→GMhandleAction | OrdinaryhandledpreventDefault exceptmodaldelegation; focusonHold nativebutton semantics separate. |
| KeyH | Hold | KEY_ACTIONS.hold→GMhandleAction | OrdinaryhandledpreventDefault; pointer/nativebuttonHoldroute separate. |
| KeyP / Escape | Pause/resume | GMtogglePause; modalEsc→GMcancelNewGame | OrdinaryhandledpreventDefault; modalEsc explicitpreventDefault/cancel. |
| Enter / NumpadEnter | NewGame | KEY_ACTIONS.newGame→GMhandleAction; modalnativebuttonactivation | OrdinarypreventDefault; modalnonrepeatEnter returnedtoDOM/native button. PendingkeyboardrepeatpreventDefault butheldset alreadyupdated. |
| KeyC | Continue | KEY_ACTIONS.continueGame→GMhandleAction | OrdinaryhandledpreventDefault; modeguardseparate actualeffects. |

## Separate control/default reading

IC pressedmodifier(meta/ctrl/alt) returns at125 beforeheldadd and before preventDefault: actualignored/notheld/defaultunprevented. INP3thirdsentence says gamekeys donottriggerbrowserdefault; whetherthat includes modifiedgamekey is a governingreadinggap alreadyrecorded, notresolvedbyproductioncomment. Do not adoptactualunpreventedbehavior as specification. Ordinarypressedrepeat is preventedthenreturns, but heldKeys.add occursbeforeevent.repeatcheck; modalrepeatalso preventedafterheldwrite. Setidempotence foralreadyheldcanonicalkey is distinct physicaltokenhistory; release ofneverwheldkey mayrestart anotherdirection. These are source facts/candidate routes, notnewfinding.

## Visibility mapping (STA-5)

SCvisibilitychange542-547: visibleeventreturns; anynonvisibleevent resetsdrag then ifGMplaying dispatchespause. Modelpage_hidden isaliaspause, not browserhandlername. ICblur separatelyreleases/stopscontrols throughownhandler; visibilityhandlerdoesnot call ICblur/release. D43realtabswitch observedblur/hidden/visible/focus withpausedboard, butthese distinctrouteeventsnotone atomicproof. HiddenresetA14 pluspause composite needslegalassignment/checkpoint relation separately. Screenlock/OSswitch/bfcache/platformdomain later, notassume no browserrunbecauseoldrecordsaidnone.

Next claim-appropriate method: trustedkeytable withactualGMaction/defaultPrevented/canonical+physicalhistory, scopedordinary/modal/modifier/repeat/focusedHold; validatefieldsfromeventhistory notcompiledset. ExistingD43/D47/D48/D49evidence shouldbemapped first beforeextraexecution. No sourcechoice/modifierreadingadoption/permanenttest/production/CI mutation/modelauthorfeedback. Table/sourceargument fills staticroute/methodfields only, browseroutcome/allstateframe stillpartial.

## outer-control-history-method-v1.md

Held source SHA256 `7f173d5c7a92ecd11c7c61ef4ef100e9de5b4ea34a5b5df4d959b50d92c58264`.

# A12/A13/A14 control and resource projection procedure

Independent method from B12/B13, D33C3/D34E1-E3 and INP2/4/5, paired with unchanged IC/SC source; not new execution or choice adoption. Canonical heldKeys cannot independently supply physical history. Geometry uses actual measured CSS extent as adapter input, not production movement as expected truth.

## Physical token and pad history (A12)

Record each physical key code, modifier/repeat/release/blur event in order before aliasing; keyboard A and Left remain separate tokens even though concrete IC collapses them. Record stick and directional pad as separate physical control tokens on independent neutral->direction edges, holding simultaneous distinct tokens until their own release. Semantic horizontal list is oldest-to-newest with last-token direction winning; softdrop tokens form separate set. Simulated navigator snapshots are labelled stand-ins, not physical device evidence. Simultaneous snapshot-edge ordering not specified by available source stays unresolved rather than silently applying ICpriority.

Compare concrete aliases, padDirection (merges stick/pad), heldButtons, padDown, movement and resulting actions to expected list/set plus C3/E2/E3 suppression history. At resume mark every then-held repeating token suppressed until its own release/repress; releasing a newer token does not reactivate suppressed older token. New postresume presses behave under newest-direction rule. Disconnect/blur release all semantic tokens; visibility reset+pause is a different composite route, not assumed blur. Pad Menu/View exclusivity and button-action dedup are independent requirements; compare ordered newPresses observations, not production actionSet as oracle. No expected buttoncode invention: standard mapping declared source labels bind concrete PAD_BUTTONS, device mapping remains separate.

## Outstanding resources and phase (A13/B13)

Keep separate ledgers for GM gravity timeout, GM lock timeout, IC horizontal DAS/ARR timeout, IC softdrop interval, and other relevant resources such as IC rAF polling. Entry: session/instrument ID, registration ID/type, requested delay, registering route, cancellation attempt/result, deliveries and mode/token phase at checkpoints. An interval remains outstanding after one delivery until successful cancellation, unlike one-shot timeout; each firing record alone is not a live-handle proof. Under trusted successful cancellation no future firing; throwing cancellation may retain firing per U3, and stopped authoritative game must remain unchanged. Silentnormal-return no-op cancellation is outside adopted trust, not native failure evidence.

Expected horizontal phase waits167ms then repeats33ms; softdrop50ms; keyboard first row immediately per INP2 and pad requirement compared separately without broadening the explicit pad wording. Requested values versus actual elapsed/native delivery are labelled separately. D21S10 request-only rule governs gravity, not silently all input timing. Paused/over B13 no outstanding gameplay repeats independent of handleundefined or callback eventually selfstop. rAF loop has its own scope/trust and DSP3 wake relation, not automatically gameplaytimer exemption for downstream controlwrites. v23/v25 prove only attributed horizontal timeout subset; no observed softdrop interval/rAF ledger is manufactured by this method.

## Pointer history and pixel-to-cell relation (A14)

Record pointeridentity/start/current coordinates, maximum excursion over entire gesture, measured boardCSSwidth/10, pieceidentity atbegin, every controlassignment/action and commit. Expected tap requires never beyond10px and endpoint within10px (D34E1); exact10px comparison boundary remains source reading if ambiguous. Use source halfcell horizontal threshold and onecell steps, one row per wholecell downward; negative halfcell tie needs source allowedresult reading, not unexamined Math.round asymmetry. Track wallcontact anchor and reversal independently: pushing into wall must not bank futuremoves; when reversing compare action/grid displacement with observed finger excursion and source in-step rule. Do not infer expectedblocked displacement from tryMove return alone.

Expected gesture only controls original currentpiece; after hold/lock changes identity later gestureactions cannot move/drop successor. Already committed moves/drops remain when non-tap gesture ends. Pointercancel ends state with no taprotation. Hidden composite independently resetsdrag then expectedpause only ifplaying; ICblur may also occur but is not required by visibilityhandler. SC actualdragstartX can be rebased atwall, so concrete startX is not originalsemanticstart without recordedhistory. moved boolean reflects productionthreshold and cannot supply independent ever-excursion predicate.

## Mapping status

This is named written adapter procedure for X2/X3/X4, not actual full event ledger or all-state validation. Existing D47/D48/v18-v25/v21 samples fill their declared keyboard/mouse/horizontal scopes only. Pad/stick physical orderedhistory, actualinterval/rAF ledger, independentwall/pixel relation and composite hiddencommit bindings remain actual Phase3 evidence residuals. Phase4 enumerates domains/platforms; Phase5 classifies discrepancies. No model/permanenttests/production/CI changes or clean-author feedback.

Independent P3-D source-fidelity review: IC/SC currentbyte identity attributed, GM hash checked stripping own newline, no runs/model/requirements reread. Additional actual A14 route: endDrag does not read pointerup coordinates, decides via moved history/type/pieceidentity only; independently expected endpoint clause therefore requires recorded pointerup coordinates, cannot be certified from moved=false. Exactly10px and negativehalf tie source partiality held. Fullreview retained; actual pad/stick/interval/rAF/wall/hidden ledgers not executed by method.

V38 separate actualICsoftdrop interval ledger nowheld: Node26 actualGM+IC/realfactory, fakekeyboardKeyS publicNewGame/Pause, request50ms remainsoutstandingwhilepaused beforedelivery, firstpauseddelivery actualclearInterval removes/no rowchange/fault0. It fills previously missingsoftinterval actualsignal on one declaredfixture, not nativeclock/rAF/pad/fullR1. Independent reviewpending; priorhorizontalv23/v25scope notexpanded.

V38 independentNode22 actualGM/IC rerun equalsNode26 JSONexceptversion; pinnedsourcebindingsverified. Manualonepauseddelivery and laterkeyupclearundefinedbenign, noafterkeyup snapshot. Resume/pad/blur/disconnect/gameover/rAF uncoveredbyV38. SeparateV39rAFledger executionheld/reviewpending, not expandinterval proof.

V39 independentlyrerunNode22 outputequalsNode26exceptversion/pinnedhashes/sourceflowverified. Restingpadonly/manualrAFqueuedsignal, heldButtonsnotcaptured, gamepaddisconnected eventnotfired (only no-connected snapshot). It shows pollingstops whenpollreturnsfalse, not eventreleaseall/nativeframes/B13newconstraint/fullresourceproof. Fullreview retained.

V38 independentlyreviewed actualGM+ICsetInterval outstandingpause then selfcancel manualdelivery fills namedsoftdropinterval ledger gap; V39 independentlyreviewed pausedrestingconnectedrAFreschedule/no-padstop fills namedpoll-firing ledger, not newB13rAFconstraint. V43 distinctsequentialstickleft/newerpadright/releasestick/releasepad actualpollGamepads withsuppliedstandardbuttons/axes/heldButtons trace fills missingstick/pad ordered-history projection, pendingindependentNode22/Pythonreview. Onephysicaledgeperstep avoids unresolvedsimultaneousorder; fakeAPI is stand-in, nothardware/native. IndependentB12expectednewerpadright contrasts actualmovementmoveLeft while olderstickleft remains; releaseolderstickthenpad transitions matchboundedexpectedprojection. No fullphysicaltokenpersistence/frame/resource/model/certifiedfinding claim.

V43 independentlyreviewedNode22actualexceptversion/Pythonbyteequal/sourcehashesverified. ActualICdirectionternary prioritizesolderleftstick overnewerpadright; no heldtokenorderfield; actualmovementprojectioncontrast verified. B12newestexpected groundedcoordinatordirectsource reading, notrereadbyreviewer; independentPython reconstructs declaredsequentialedges, fixedadapterlabels attributedsource. Notphysicaldevice/keyboard/simultaneousedges/timerdeliveries/fullR1/certifiedfinding/sourceadoption. Fullreview retained.

## hold-accessibility-assertion-method-v1.md

Held source SHA256 `ff3bb1fa8d4d44fb9105cfb3e60812f9b6e3d269d509b2520091ca722a53e141`.

# INP6 full clause and existing assertion relation

Requirement reread verbatim from current REQUIREMENTS: Hold box button for keyboards/screenreaders; Tab reaches; nameHold/shortcutH; focusedEnter/Space holdwhileplaying; clickingdoesnotfocus so keysretain gameactions. Pause/Resume/dialog labels are not substitutes for these Hold-specific subclauses. ExternalmethodNA model; hold semantic operation anchors PLY7, nativefocus/accessibility separate.

HTML33 candidatecanvas rolebutton/tabindex0/aria-labelHold/aria-keyshortcutsH. SC502 mousedown preventDefault leaves priorfocus; SC503-508 keydown Enter/Space onlyplaying preventDefault+stopPropagation thenhold. ClickdispatchHold SC496 distinct; outsideplaying focusedEnter notintercepted and engineNewGame route remains.

Existing game.spec211 asserts role/name/shortcut, publicStart, Tabfocus, Enterholdpreview, Space remainsfourfilledcells (secondholdno-op ratherthanharddrop), otherArrowLeftgameaction, pausedfocusedEnter opensdialog. Explicitskip nonChromium dueSafariTabsetting; not alltargetplatform behavior. game240 mouseclick showsheldpreview and notfocused, thenSpace eightfilledcells. game251 logs actualkeydown/defaultPrevented aftergame onfocusedHold, asserts Enter/Space prevented. Existingdatedsuitepass attributedaggregate, rawperprojectresult not recovered. These are claim-specific tests/expectedcounts, not currentfresh browser evidence or ATtree/speech.

Staticaccessible-name method: inspect actualrole/name/shortcut/taborder attributes and nativeAXcomputedrole/name/shortcut when captured; DOMmetadata alone supplies declarations, not confirmedscreenreaderannouncement. Actual AXtree snapshot not held, AT/hardware/Safarisettings remain residual. Existing testmethods fill clause-specific correspondence, not universalproof. No newbrowser/test/model/source/CI action or new source reading.

P3-D source review supports actual Hold declarations/SC handlers; testassertions and REQUIREMENTS not available/read by reviewer, V26HTMLnotc5dhashchecked, IC/SCidentityattributed. Coordinator directly read those unchanged files/tests/requirement for binding. No AX/AT/Safari/nativeactivation attestation. Holdkeydown stops propagation but keyup may reachIC release path for neverheldkey, possible O15-related staticlead not run/confirmedfinding. Fullreview retained.

## cache-opening-assertion-correspondence-v1.md

Held source SHA256 `fd2c3ee7fff69331e603cc0aa4aca906185e55755cd81f63e774834749ffd131`.

# APP2/APP6 and DSP3 existing assertion bindings

No new execution. Actual unchanged SW source read together with e2e/app.spec.js assertions. Dated Phase0 suite outcome164pass/19declaredskips remains attributed aggregate, not freshly retrieved per-project report or trace. Expected outcomes below come from named requirements, not newestVersion()/completeVersions() return.

## APP2 version/opening/completeness relations

| Clause | Candidate source relation | Existing independent stimulus/assertion | Limits and residual |
|---|---|---|---|
| Cached offline opening | openPage selects newest; pins resultingclient; answer cached else network | app115 test actually kills dedicated server, waits exit, reloads; asserts NewGame visible/public startPause/fourfilledcells | Defines independent offline behavioral method with existing dated suite evidence. Not allresourcescontent/hash or nativeSafari attestation. |
| Background update; nextlaunch | navigate respond opened; waitUntil after opened download; immutable versioncache | app150 mutabletempserver titlechangedDeploy2, firstreload oldtitle, poll newcachedtitle, nextreload newtitle | Labels expected old/new externally by fixturetitle, not SWselector. Poll helper uses implementation-like prefix/completeness heuristic, so downloadedfullness not certified by helper alone. |
| Failed partialupdate keeps old | addAll16shell one transaction; catch deletesnewcache; cleanupseparate | app213 removesposition.js, logsrequests, reload oldtitle, requestobserved, after500ms noDeploy2; restoremodule then newtitle/newgame | Bounded onefailedfile/onewait; no allfilecontent or allinterleaving proof. No methodabsence merely because laterfailure domains remain. |
| Oneopening version | openPage pinsclient before answer; nonnavigate versionFor pinifcacheexists else newest; answer cachefirst | app253 deploy labelsHTMLtitle andpositionmoduleVersion independently, deliberatelydelayedscripts until newerdownload; oldtitle+oldmodule1 then nextlaunch2/2 | Direct two-resource versioncomparison, not everyfile. ModifiedtestHTMLno preloads/delayedloader declared fixture, not exactproductionloading trace. Pinexpiry/clocks/cacheloss/collisions need explicit sourceargument ratherthan selectororacle. |
| Completecache definition | sourcecompleteVersions considers anynonemptyversionprefixcache complete | Existing addAll-generated testfixtures exercise normalcandidate caches | Foreignpartialprefixedcache/provenance not authenticated by nonempty. Trustboundary/nativeaddAllatomicity and cacheownership remain separate; sourcecomment cannot prove completeness. |

This binds existing assertions to actual clauses and qualifies result attribution. Openingpin/download relation now named; fullresourceindependentcontent/order relation stillresidual, not a universal allfuturedevice gate.

## APP6 creator ownership versus name selectors

| Effect | Source actual target selector | Required independent creator relation / evidence |
|---|---|---|
| Storage | tetris.highScore/isSessionSaved/savedGameSession only | Literalkeyinventory plusD43/v24writes bounded. Sharedorigin externallyeditedcontent stilluntrusted; ownkeystringnotproofof untouchedforeigndata. |
| Activate deletion | exactoldnames tetris/tetris-2 | app175 deliberatelygame-labelled oldcaches thenexpectsremoval. Doesnotclassifyforeigncreatorwithsamefixedname. |
| Version cleanup | allVERSION_PREFIX; numberbelownewest exceptkept/pinned | Mustindependentlylabel creator/content before ownershipclaim. Prefixnotcreatorcertificate. Foreignprefixedcache or misleadingnumber remainexplicitdomain, not automaticfinding. |
| Pins | fixedtetris-pins open/put/delete | Sharedorigin collision/foreignentry writes require ownledger; not covered by unrelated-name sentinel. |
| Foreign sentinel test | app195 creates other-project cache | AfterSWcontrolassertscachename survives. Entrycontentnotreadback (WebKitlimitation stated), nofixed/prefixcollision tested. Boundedoneforeignname method/evidence, not allcreatorownership. |

No collision possibility is classified as defect here; source/effect boundary must be reconciled before Phase5 disposition.

## DSP3 existing idle counters

app10 wraps CanvasRenderingContext2D.fill, publiclystarts/pauses, waitsResume then1s andasserts samefillcount. app28 wrapsrequestAnimationFrame, samepublicpause,100mssettle then1s sameRAFrequestcount. These bind declaredpaused/nonchanging interval to independentcounts; fill-only missesotherdrawcalls, RAF-only notallbrowserwake/storage/padpoll. Testdefinitions anddatedaggregatepass areheld, exactcurrentperprojectrawcountervaluesnotrecovered. Sourcewriter/versiontable fillsstaticrelation; actualidleconnectedpad/storage reread/allcanvas counts stillseparate. No inferredbatteryproof.

Independenttargetedfidelityreviewpending. Staticmethod anddatedsuiteattribution distinct from freshruntimeevidence. No repo/permanenttest/model/CI change or new browser/run.

Independent P3-E targeted unchanged SW/appspec source/assertion review found no substantive errors. Named methods bound, aggregate dated outcomes not rawperproject proof; source completeness/creator/quiescence limits held. No rerun/closure; fulloriginalreview retained.

V47distinctactualactivatecreator-effect adapter now independentlyreviewedNode22/Pythonrerun/sourceGitbytes equality. Declaredforeigncreatorfixture caches tetris/tetris-2/other-project: actualactivate callback/waitUntil successfuldeletefixedtwoforeignlabels/entries thenclaimsclients; unrelatedforeignsentinelsurvives. IndependentAPP6expectedonlycreatorgame permitsdelete; labels come from predeclaredfixture, notnameorproductionselector. This fills boundedfixednamecreator-vs-target relation, notactualcurrentnativeusercachecollision/automaticdefect/allAPP6 or install/download/fetch/versioncleanup/concurrency. Fullreviewretained/runtime-pathattribution difference explicit.

V49distinctactualnonempty/completeness/pin/content relation independentlyNode22/Pythonrerun/sourceGitverified. PredeclaredcompletegameV1sixteenexternalURLs versusforeignprefixed999HTML-only; actualselect/pin999 andHTMLFOREIGNlabel, scriptmissingfallbacknetworkV2. Independentsetcompleteness false forselectedcache; samepageexternallabelsdiffer. ControlledbackgroundaddAllthrow deletesownnewemptycache, notchangingforeignfixture; relativeRequest/navigationevent/fixedclock/cache/networkadapters explicit. Actualnativeorigin/currentcachecollision/all16pagefileresponses/race/pinexpiry/automaticdefect/fullAPP2 notclaimed. This supplies boundedselection/pin/contentcontrast method, notcompleteappcertificate. Fullreviewretained.

## display-layout-assertion-correspondence-v1.md

Held source SHA256 `c7e80ebe4b8079ff9abffdb0f1154e4fd108393360b5dc5d5fba20956ef2039b`.

# DSP1/DSP2/DSP4 existing source/assertion relation

Current REQUIREMENTS95-98 reread; unchanged app/game.spec and helpers/source inspected. Static source-to-assertion research, not new execution/pixels. Phase0 dated configuredsuite outcome is attribution, not freshperproject values/nativeSafari verification. ExternalmethodNA model.

## DSP1 layout/mode relation

GamecheckFits422-443 reads actual board/pause/held CSSbounds and document scroll extents: scrollHeight<=innerHeight, scrollWidth<=innerWidth, pausebottom<=height, heldtop>=0, boardheight/width≈2 (precision1), boardwidth>150. Tests446/452 run playing at configuredviewport and375x667/390x844/430x839. Equalitytest461 records openingboardwidth/height then exactequals whileplaying, paused, ordinaryover reachedbounded30harddrops. This fills named measurement/mode relation, not allsafeareas/phonehardware and not allmodewholepagebounds (fitchecksplaying; equalitytestboardonly). CSS aspect/layout declarations sourceargument separate measuredoutcome. Historicalsuitepass notrawbounds/pixelinspection; no newvisualreadyclaim.

## DSP2 resolution/resize relation

SourceSCsizeCanvas56-71 independently defines backingwidth/height round(CSSextent*DPR), setTransform(DPR,0,0,DPR,0,0), cacheCSSextents; ResizeObserver/DPRwatch triggersinvalidate/redraw. Game480checks boardwidth only. App48 resize width-40,height-120 pauses then asserts boardbackingwidth formula and filledCount4. App62 interceptsmatchMedia resolutionqueries, stands-in devicePixelRatio2 + resolutionchangeEvent; asserts boardwidth round(CSSwidth*2), fourfilledcells, subsequentquery '(resolution: 2dppx)'. This is declaredsynthetic densityevent, not physicalDPRswitch. No fivecanvasheight/transformallcontent attestation; current source method plus boundedboardassertions exists, actualfivecanvasmeasurements/pixels distinct residual. Alpha/resizeV17 retains its separatelymeasuredscope; opaque detectorlimitations not erased.

## DSP4 default/gesture relation

App91 reads computedhtmltouchAction/userSelect (prefixedWebKitfallback) and syntheticcancelablegesturestart.defaultPrevented, expectingnone/none/true. SourceSCviewport.scale>1 toggleszoomed; gesturestart/change preventDefault onlynotzoomed; inertboardclick intendedSafariquicktap recognition. ExistingD44 trustedprotocoltouch/9-10px/actionhistory narrowerthanSafari-native pinch/doubletap/reloadzoom/secondtap outcome. No syntheticEvent transformedintonativezoomproof. Requirementsecondtap/recovery remainsin scope; sourcechoiceexact10px not adoptedhere. Moreplatform/safearea/fractional/DPR/error domains Phase4, candidate/dispositionPhase5.

## display-color-wake-assertion-correspondence-v1.md

Held source SHA256 `1e6e693b2e75a76799519161297fea4285419587e412442f278b90695455f506`.

# DSP6/DSP7 existing assertion and source relation

Requirements100-101 reread, unchangedSC34-91/238-274 andapp.spec294-432/helpers150-207 inspected. No freshsuite/browser/pixel/physicalscreenexecution. ModelNA externalbehavior; engine mode providesstimulus not color/sleeporacle. AggregatePhase0outcome attributed, notrawperprojectproof.

## DSP6 acquisition/negotiation/components

AppcolorSpaces helper queries fiveexistingcanvascontext getImageData.colorSpace, compares separatefreshdisplay-p3 request supportprobe (missingreport→srgb). App324 starts/fourfilledcells, expects all5supportedspace, samplesfirstopaque boardcellcenter in own and sRGB spaces; expects hex(own) among importedPieceColors and, ifP3supported, srgb!=own. This establishes explicitnegotiation/component-reading method, notindependentcanonicalcolors because importedproductionconstants boundactualmetadata. V40 mapscurrentexacttokens tokinds viaG6 butdoesnotchooseusualcanonicalcolors. App338 registers DOMContentLoaded contendergetContext beforeload; assertionall5spaces +owncomponent membership. This contender timing fixture notproofnoarbitraryearliercontextowner. App353 interceptsgetContextforcing srgb, expectsall5srgb, own membership andown==srgb. Conditionalfallback method notnativeunsupported-device certification. Pixelhelper alpha>200/cellcenter excludes translucentghost, notallpiecepixels/gamut/perceivediPhonevividness; no visualreadiness claim. Sourcevivid formula channels/255 independentnumericrelation and usualenginehexserialization distinct from actualcanonicalchoice/targetdisplay. Namedmethodrelation no longer absent; freshfivecontextattributes/componentpixels/targetdisplay residual scoped.

## DSP7 policy and fake-sentinel assertions

HelpersfakeWakeLock constructs controlledAPI: missing deletesproperty; refuse rejectsPromise(NotAllowedError); hold queuesgrantclosures; grant immediateEventTargetsentinel. release setsreleased once/firesrelease/returnsresolvedPromise; counts aregrantedlength/notreleased count, requestsseparate. This instrument isnot OSscreen/sleep evidence.

App370 opening0/0→play1/1→pause1/0→resume2/1→bounded30dropsordinaryover2/0 binds mode andrelease policy. App386 heldrequests: playrequest1,pause/resume request2, grantboth→2granted1held (stale/duplicatecleared); laterrequest3thenpausebeforegrant→3/0. App408 revokeswhileplaying→2/1, pause→2/0, requesttotal2 establishesretryonlywhilewanted. App422 refuse/missing starts, Pause label/fourcells, thenpausedResume/errors[] establishesbounded normalgameplay continuation, notwhole faultcontainment. Sourcewantedclear/pointerclearbefore release, stale/duplicate grantrelease, release listeneridentityguard/rerequest andrejectignore align namedpolicy. No request.throw/addEventListenerthrow/releasePromise-reject containment orphysicalscreenawake/sleep proof. Latererror/interleaving/device domains Phase4; scope/candidates/dispositions Phase5.

## display-over-assertion-correspondence-v1.md

Held source SHA256 `630f745782a87c1c9cb65324759eadb450616fe71ced068edd0899eb88524443`.

# DSP8 opening/ordinaryover/display assertion relation

Requirement102 reread, actualgame.spec26-91/helpers90-109 andSCshowsPieces/syncControls sampledstate policy inspected. No new browser/pixelinspection/ATspeech proof; source/assertionmethod with datedsuite attribution. Semantic ordinaryover absence perB6/B8/B10 distinct retainedconcretefields. Model supplies state notpixel/speechoracle.

Game26opening asserts NewGamevisible/Continuehidden/Pausehidden/nooverlay/emptyannouncer(role=status)/score0/highscore0; noopaquealpha>200pixel across boardandfourpreviewscanvases. This is explicitemptyopening method, alpha-threshold notuniversal nofaintpixels.

Game68 suppliesdeclaredsave Oatrow0col0, rows2..19 nineblocks exceptcol9 plusblock(1,4), Resume/drop. Expectedindependentlockedcount18*9+1+4=167; asserts overlayvisibletextGameOver/announcertextGameOver/overlayaria-hiddentrue, boardfilledCount167, nopreviewopaque drawing. Pixelcount discriminates drawing thefailednextcurrent atoplockedboard butnotallpositions/ghost-subthresholdpixels orrawpayloadR1provenance (savehasmissingcount perexistingfixturelimits). NewGameoverlayhidden/announcerempty/fourcells/nextpreviewreturns. Counthelper boardcellcenteralpha>200/color method retainsinstrumentlimits. Ordinaryover testcase isnotfault-retainedcontents proof. Persistencevalidity/Continuehistory belongsO3/O4; no claimtestcertifiescountdefault. Text+role isdeclaration/eventcontent, not heardscreenreaderannouncement. Source sampledstategameEnded overlay remainsuntilsamplednonover; rapideventsbetweendraws/Continueoverlay relation stilldistinct. Phase4 broadenslayouts/rapidframes/platform/readers, Phase5 disposition separate.

## random-play-assertion-relation-v1.md

Held source SHA256 `c7b018a2c18c48ddcb44f520724f998539400da681c76c742dbf56a919eadc5f`.

# SAF6 / QA6 existing random-play assertion and bound relation

Currentunchanged gameManager.test800-830 and helpers inspected, no new testexecution/modelcontact. Requirement SAF6 is longrandomplay/nooverlap/validscoreslevels/nofaults, not itself literal lockstep. Independentreference differential method belongs O8/Phase3 audit method where used; absenceofmodelrun not erase actual existingtest evidence.

Existing test seededRandom2024 sharedstream, 200rounds, each<=2000steps orover. Actions left/right/clockwise/Hold, harddrop, softdrop, pairedpause/resume and boundedfakeclock advance<400ms. Eachstep scoregain in explicit{0,100,300,500,800}, level equals Math.floor(score/1000)+1, board20x10, queuecount3, playingcurrent fits, ghostfits/row>=current; eachroundfaults empty, >100roundsordinaryover. Physicalevents/storage/Continue/CCW/disconnect/kickexpectedsource not thisdomain. Fits/ghost checks reuse productionmethods, so no independentprimitive/fullR1 proof. Scoregain/levelformula/directdimensions/emptyfaultarray are literalassertions independent of monitorreturn but productionfield adapters stillrequired. No recordedfullperstep trace in heldlog; tests26.log actualnamedtestpass/date/outcome binding distinct from sourcecode method.

helpers.advance bounded assertion fired<10000 withtimerremovedbeforedelivery; timerssortedduetime within declaredmanualclock, no nativeclock claim. repeatUntil defaultlimit100 explicitfailure afterlimit. Randominnerloop max2000/outer200 givesfinite bound rather than whilegamecanhang. This fills namedSAF6 currentexistingmethod/boundedloop relation, not alltestloopuniverse, randomuniversality, declaredindependentmodelseeds/lockstepadapter or mutationequivalence proof.

No test weakened/changed, model accepted or phaseclosed. Sourceidentity currentpublic/testtrees alreadybound; exactearliercompiler/project/mutationdenominators remainseparate. Phase4 broadensdeclaredseeds/domains, Phase5 dispositions. Existingtestsnotsoleoracle, no new count-basedclosure.

Independent P3D targeted source/helper review accurate, no randomgametest rerun. Additional seededRandom-only numerical experiment finds double-arithmetic LCG diverges from exactinteger formula and seed2024 period10466; actualtestconsumedrawcount unmeasured, coveragelimitation not defectclassification/fixadoption. Per-step assertions not eachsemantictransition: scheduleradvance can deliver multipletimers, pairedpause/resume hides intermediatepaused boundary. Faultarrayabsence depends on partialmonitorpredicates. Exactfullreview retained.

## instrumentation-trust-method-v1.md

Held source SHA256 `e90b347d3cbda7ddd556ee82b4152833bf4e36a1bc18c28295c8b1db65499692`.

# O6 instrumentation and responsibility crosswalk

This private consolidation of current methods does not expand platform trust or execution. Each instrument names what it observes, who supplies its inputs, why the evidence matters, and what it cannot prove. Matching current source does not establish a historical run identity. Source T/U decisions govern timer and fault expectations. Harness choices create no new source rule. The linked V29-V32 artifacts and earlier named records remain the evidence, not this table.

| Instrument / evidence | Responsibility and independent input | Observed relation | Assumption / known failure / observer effect | Boundary |
|---|---|---|---|---|
| Engine scheduler map V28/V32, earlier D42/D44 | Harness allocates handles, records schedule/cancel/fire; source S10/B13/T3 gives expected requested delay/outstanding state | Map membership, old firing cancellation/new request, nonfiring public-action sequence | V28/V32 no scheduled callback delivered, elapsed real time untested; successful map cancel is declared dependency not native cancel proof. Callback must be removed before delivery in firing variants. | Native clock/deadline accuracy/interleavings/throwcancel separate; no handletruthiness=resource running. |
| Fullpage IC timeout stack ledger v23/v25 | Wrapper delegates to real browser clock APIs, attributes callstack inputController.js | Only attributed horizontal DAS timeout subset across pause; softDrop handle snapshots are concrete values, not outstanding interval proof | SoftDrop uses setInterval/clearInterval (IC291/301), not wrapped timeouts; stack syntax/sourcefilename selection can miss unattributed resources; wrapping changes stack/call timing; controlled clock uses declared logical elapsed, not native walltime. | Not all browser timers/RAF/SW/wakelock or timer-universe T. Pause callback remains finite source/state observation, no platform generalization. |
| Gamepad stand-in v7/v25 | Harness exposes connected/button/axes values; physical meaning from event/source table | Poll route/action/repeat history under explicit standard mapping fixture | No physical device, firmware/deadzone/native disconnect/OS focus attestation; JS stand-in availability can alter polling lifetime. | Physical hardware/device timings stay separate. |
| Prototype delegating captures v25/v26/v27 | Capture actual GM/IC receiver then original function via apply; untouched source files | Concrete fields and resource handles from same live instance | Capture only instances traversing wrapped paths; delegation instrumentation is observer work and can alter stack; direct helpers/other instances not covered. | Concrete equality not A1-A16 validity or commit/frame proof; no screenshot substitutes for semantic fields. |
| Pointer/key event histories v18-v21/v26/v27 | Browser-generated event history identifies physical code and sequence separately from canonical sets | Physical-token order and original drag identity; modifier/repeat/default only where actual event records contain those fields, otherwise instrument capability not measured result | Mouse shared handler not touch hardware; synthetic gamepad not trusted physical input; heldKeys loses aliases/order. Fixture choices must remain explicit. | Native modal/focus/default activation and arbitrary sequences/platforms need own methods; no silent canonical adapter equality. |
| Successful memory storage + write ledger V32/v24 | Harness records key/value/attempt/success/session IDs as applicable; S1/S4/S6/S9 expected independently | Payload write versus flag effect and known public-history count reconstruction | Memory store not native StorageEvent/quota/races; raw bytes from serializer not validity oracle. V32 O-only factory omits bag validity, no full good-content proof. | No cross-tab concurrency/lastgood certification or missingcount default; effect-specific preservation not global rollback. |
| Root HTTP fetch V29 | Unchanged Express source; expected bytes separate filesystem files; expected MIME by explicit extension |17requests/root+16files200/type/byte equality | Local installed Express/Node26 environment, root mount only; loop enumerates files not discovered-browser graph. Cleanup present; independent JSON review not chronology/termination proof. | Nested prefix/network failures/browser/cache/devices not covered. |
| Literal graph V30 | HTMLParser, JSON icons, inspected one-line imports/register/APP_SHELL literals, source-hashed files |47edges/16existing targets/root+namedprefix URL algebra; independent Python rerun | JS regex not lexer; comment removal may consume URL strings; APP_SHELL general evaluation excluded. Current source grammar separately inspected. | Not dynamic browser-discovered graph, HTTPnested/cache or universal grammar requirement. |
| CDP network V31 | DevTools request/response IDs/initiator/HTML line anchors; expected module set from V30 imports |7module parser discovery once each in cold context/SWblocked,200/javascript/cacheflags | Observer timestamps are scheduling trace not simultaneity/speed; source hash from filesystem not responsebody. Independent source/JSON review no browserrerun. | Warmcache/SW/device/native latency and preload-removal performance comparison outside. |
| Pixel/canvas classifiers D43-D49 and G6 image | Pixel-derived display evidence distinct from engine fields and adopted pack geometry | Rendered cell/resource-specific snapshots, bounded geometry image-table comparison | Sparse single-pixel classifier once false-mismatched G6, replaced own-color-area threshold; canvas cached state may differ semantic state. P3-E network method needs no visual claim. | No geometry/kick oracle from production pixels; actual pixels required for visual deliverables, but pixels not whole state proof. |

## Choice and effect preflight

Rev6 env/ch excluded from atomic copied-state rollback; external storage callbacks cannot be un-called. All missing boolean/spawn/kick/release choices must be inspected before running effects or classify whole trace undefined. Callback ledger expectation comes from source rule plus declared environment, never observed production choice relabelled expected truth. Constructor outside atomic/ordinary guard is a separate bootstrap responsibility.

## Claim binding and scope

O5 per-subclaim bindings retain exact code/model/version/choice/domain/results/review limits. O6 asks for responsibility/assumption/boundary mapping, not a claim that stand-ins satisfy native trust. This table consolidates that field for named methods; unlisted instrument/resource classes remain unassessed. Phase3 claim-appropriate evidence is separate from Phase4 domain exhaustion and Phase5 discrepancy disposition. No source, model, permanent tests, CI changes or clean-author feedback.

## Independent method review limits

P3-E source/method fidelity review of this new file checked transferredV29-V32/G6 and priorD43-D49/source. Corrected v23/v25 scope to horizontalDAS timeout only, notsoftdrop interval. No new execution/trust/closure, no raw oldbrowser rerun/V28execution attestation; V28artifacts not independently reread in thisbundle. Other instrument responsibility/bounds preserved.
