# Restored Evidence Relations

Centering, restart, landing, independent-model, and process-check methods.

These domain relations were in accepted held support and are restored to the standalone publication derivation. They add no measurement or expected source choice. Source hashes identify the original held methods, not byte equality of this publication text.

## PCE3 occupied-span centering

Original held source SHA256 `6239c3a568df9047ff63686bf70c80548e9ccbd99ba062c89c4d2566a582c6c9`.

This is a private, source-only external method. modelrev6A2 remains callerpartial. No floor tie is chosen, no new inputpack is added, and the model is unchanged. PCE3firststate/center/top2 and B2fixedgeometry govern this relation.

An integral-grid placement cannot exactly center a three-column occupied span on a ten-column board. A claim-appropriate set-valued check can express the existing ordinary meaning "centered": accept the integer placement(s) with the smallest absolute difference between the occupied-span midpoint and boardmidpoint. It does not demand a left or right tie. For span[minc,maxc] in sourceG6spawn state, the independent formula is: minimize |positionColumn+(minc+maxc)/2 - 4.5| over integerpositions whose fourcells fit. All seven spawn shapes span their full sourcebox width: I4, O2, other5kinds3. This yields Icol3, Ocol4, otherscol3or4. Row0 places the G6cells in top2 (Ioccupiedrow1, othersrows0/1). adoptedG6 fixes Firststate.

Actual publicV14 firststate spawn placements are S/L/Z/J/T col3, Icol3, Ocol4, boxrow0. The existing observedcells/rotation match this allowedrelation. This bounded source-to-spawn comparison does not prove that everyfactory/queue/hold/Continue route obeys it. Actual Tetromino.spawned uses row0, Math.trunc with max for (columns-shapewidth)/2, and rotation0. That equals floor only under the current nonnegative fixed-geometry premises, so the named built-in spawn routes satisfy the allowedcentering classes for currentfixedgeometry. The expected value is not extracted from production floor: the formula and G6 independently define the allowed set before comparison.

ModelNA applies specifically to a unique A2 output when the owner has supplied no tie. The external source-defined allowedpredicate is the actual independent evidence method; blueprint467/3.3 permits no artificial model relationship. It may map PCE3 centered/firststate/top2 without forcing a normative unique choice. It neither adopts the formula as a mandatory tie rule nor certifies model A2. If "centered" later requires another explicit unique box/center convention, that is a separate ownerchoice. It is not needed to judge currentplacements against this declared symmetric allowed reading.

## PLY3 fresh-request timing and PLY6 appearing

Original held source SHA256 `89993d3241b3fc0ca98b13540adb07f3ae4f4569517ab89a22eb250e7b824952`.

Original: soft drop moves one row and restarts gravity timer. State relation: when successful one-row fall occurs while playing, the independent expected restart is removal of the previously outstanding gravity request and creation of a fresh request whose delay equals the current gravity interval, measured from the restart call rather than retaining the old deadline. The injected V28 ledger independently checks cancel(old live handle) then request(new handle,700) at score0. It has no clock/delivery field, so it cannot show elapsed native due time. Actual source startGameLoop cancels the old request and issues schedule(interval*1000); schedule delegates that requested delay to scheduler. Under the explicitly declared relative-setTimeout provider contract, a fresh request has due = call time + requested interval; the earlier request no longer determines the due. This is a conditional source timing relation, not a measured actual due field. Native elapsed/delivery, throttling, old-callback race and fault cancellation are separate explicitly unobserved domains, not a requested-only waiver. Model gravity_restarts counter records occurrence, not deadline.

Blocked-floor soft drop remains an actual observation with an undefined model reading. Do not turn the successful-fall expected relation into an adopted blocked restart rule. The V28 zero-delivery scheduler cannot certify all timing. The independent fresh-request relation can still map what is compared and what remains conditional.

## PLY6 0.5 second timing

Original claim states locks0.5seconds after coming to rest. A complete comparison method has TWO distinct observables: requested delay at start/restart and actual elapsed deadline/delivery from the resting event. The first expects500ms; the second expects resting-event time+500ms before allowed resets, retained deadline at reset-limit, no scheduled deadline after off-ledge, and immediate lock on eligible final landing. If fixture time is123 and relative requested500, absolute623 is consistent with the first relative contract, not623ms elapsed. That arithmetic alone never establishes an actual resting timestamp, native elapsed delivery or an owner requested-only choice. Source lockDelayInterval=.5 and startLockDelay schedules500. This maps the requested subrelation conditionally; native timing was unobserved in this historical261source method, without borrowing S10. The current native floor/reset callback-entry and commit-bracket measurements are separately stated in current63 native268relation; appearing/resume/nativeotherclasses remain unobserved. Existing B9 allowed landing comparison separately maps reset/count/deadline-continuation outcomes.

## Appearing at rest

Source generateNextTetromino assigns a new spawned current and queue/bag/hold/count reset; rejects no-fit via ordinary-over; for fitting current invokes landIfResting. That path tests isOnSurface and enters pieceLanded: if no existing delay and count below limit, startLockDelay. Independent expected rule from PLY6/B9.2 is new fitting current at rest gets count0 and initial500ms delay; otherwise no resting delay. This is an explicit source predicate/path comparison, not an executed newly spawned-on-support fixture. Initial NewGame and held-swap routes must be assessed separately rather than all appearing routes generalized from generate-next. Their actual source routes are GameManager NewGame/reset at182-195/performAction and Hold at560-580, with resetLockDelayForNewPiece306-310 and landIfResting/pieceLanded. Those exact pinned files are identified in the source ledger; no omitted excerpt is represented as included below. No reachability or allspawn proof asserted.

## Continue

V32/V41/V62/V66 already map independent known count/lowest history against omitted serialized fields and Continue reset. Preservation failure, or loss of a needed history adapter, is a valid comparison relation. It is not a missing comparison that can be repaired by treating omitted fields as default0 for new saves. Legacy L3 covers only its actual two old formats. By this method, the current/new-write count/lowest relation is not compliant.

## B9 defined and allowed landing

Original held source SHA256 `295f14135257d52beda129fc0c91a25cedb6d13bf66e0154f4b28738ea1bf2e3`.

# B9 existing defined and allowed landing relations

Private exactsource integration, no revisionselection/modelchange. Historicalrev4/5/6 observations retained withtheiridentity and fullreviews. Rev6f958f910 callerlanding_move_counts notauthoritativeA4held.

B9.2 source divides: newlycurrent→count0/maxoccupied; newgreatestoccupiedrow→count0 (wins overrestart); initiallyresting legalmove/rotate remainingresting/no newlowest→count+1below15/restart, at15continuecurrentdeadline; offledge→cancel; returningresting at15withoutnewlowest→immediatelock. Pause/resting14→15; pause15→16; resume15startsdelay, resume16locks. These defined relations do not require a choice about initiallyfalling move which firstcomesresting.

The original source wording "Resting piece, count below15 ... leavespiece resting" and PLY6 "movingorrotating it whileitrests" admit tworeadings for initiallyfalling move endsresting. Independentpack-only reviewer explicitly found this ambiguity; rev6 exposes True/False and Undefined, neitherselectedbycode. Appropriate external set-valued relation permits count c or c+1 for this specificnewlanding-move/no-newlowest c<15; requiresdelayrunning0.5, unchangedboard/score/kind/queue exceptdefinedactions, and appliesrange/sourceB9.1. Both readings coincide onnewlowestcount0 and count15immediatelock. Do not expand allowedset to allmoves/offledge/pause/resume/newpiece.

Existing31inputs×3preflight choices=93actualreviewedcomparisonrows: absent has29defined/twoUndefined, false hasthree offledge countdifferences, true hasfive (includingtwo landingcount differences). For newlanding-movec0/14 actualunchangedcount lies in declaredallowedset; it is not confirmedsourcefailure, uniqueTrue/False remainsunadopted. All25floor softfall cases agree ondefinednewlowest/floorlanding; publicoffledge14/15producecount16playing/nonresting violatingB9.1 independentlyofinitiallandingambiguity. Original13→14 increment depends cancellation/resetreading; preservecandidateconditionality. MatchingFalse doesnotauthorizeFalse.

## O8 bounded reference construction and freeze provenance

Current frozen model f958f910a7a8ae02e2abd4a25a82f4f6127d5ff41440d45008cb92e4b63e93d2, correspondence abd34f81bc2017af9552d7b98e5baf38cf5d53d0544bb7c27afdbc4e4896fe3a and selftest4e6be2d9030b22282dc6dc27ad4615aea0c5cd7bf0db7e1db1dbb74ae2b26532 are distinct artifacts. Recorded October5 chronology supports four supplied specification inputs and specification-only review corrections: initial14:59:40, geometry-box clarification15:05:42, corrections15:12:26/15:14:36, disputed landing reading15:51:54 createdrev5 without changing frozenrev4, strict bool-choice hazard15:54:16 createdrev6, final15:55:01. The inspected bounded authoring record shows supplied requirements/decision/geometry and revision/selftest access, no observed production or external-source retrieval in that scope. Incomplete records cannot prove universal nonexposure. Header/hash alone does not establish that provenance. Implementation-exposed comparison adapters remain distinct. Selftest success is self-consistency, not behavioral truth or model acceptance.

### Current rev6 clause and choice adapter map

The table keeps the historical missing-current-relation descriptions from method preparation. They mark partial executable-model/caller-choice/provenance support, not a current absence of all independent evidence. Where supported, later raw reconstruction/checkpoint/control, centering allowed-set, native268 and current13-field relations in current63/domain/clause support supersede the absent-statement labels. No unresolved model choice is silently accepted. No older execution is renamed rev6.

| Clause / source point | Defined/partial expectation | Choice/preflight before effects | Comparison-adapter boundary / held evidence | Missing current relation |
|---|---|---|---|---|
| _fresh_queue_placeholder lines89-92; opening A9 ambiguity | B7 validqueue3 allmodes, exactopeningkinds unspecified. Model constructor requires opening_queue or raises. | Caller reading explicit, valid3kinds before construction. A9 ambiguity ID differs authoritative A9resetcount. | Opening ordinaryover absence distinct concrete production-generated current/bag. | Openingsemanticprojection/sourcechoiceprovenance; no observedproductionqueueasoracle. |
| _spawn_pos110-113 / A2ambiguity | No adopted uniquecenter tie for oddwidth. Missing spawn choice Undefined. | Pure source-grounded suppliedfunction; enumerate acceptedalternativeplacements or boundedchoice. Preflight everykind beforeNewGame/lock/Hold writes. | O(0,4) oldharnesschoice notnewadoption; sevenkindpublicspawnobservations bounded. A2ambiguity notauthoritativeA2piece. | Choice/allowedrelation proof for fullspawnclaim, notforcedproductioncentering. |
| rotate255-265 / K1 | GEOM geometry adopted; kicks/order not inpack. | Do not extractexpectedkicksfromproduction. ExplicitUndefinedclass or independentlyadoptedsource needed for claimedkicks. | G6image/table28/28 separate geometry only; runtime25offsets only. | Kickclass mapping/provenance remainspartial, not fulloracle gateforotherclaims. |
| _settle241-245 / A4 | landing_move_counts realbool; missingUndefined, wrongtypeChoiceError; rev5 exposed previouslyfixedreading. Falling/newlowest/count15 lock rules separate. | PreflightTrue/False declaredreading, no silenttruthiness. Source-shaped counterpart underbothchoices notchoiceadoption. | Rev4lineclear/movementresultsstayrev4. Rev5/6ledge records citechoice; ambiguityA4 notauthoritativeA4holdused. | Subclaim/sourcechoice/adaptation index, complete historylowest/count relation. |
| release373-376 / A5 | Returningtootherhelddirectionrepeat timing unspecified. | release_repeat puredeclaredchoice before operation; notliveICpriority/restartasexpected. | D47/D48physicalhistoryvsaliascanonicalset exposesrepresentationdifference; modeltokens ordered. | Physicaltoken/historyadapter and choice source; notcanonicalset-equivalence. |
| _maybe_suppress385-390 / A10 | start/blur suppression choices must realbool; resumeeveryheldrepeat suppression fixed C3/E2/E3 separately. | start/blur keys explicitly supplied priorpotentialwithdraw/gameeffects. | v20newerDrelease restarts suppressedAcontrast; fakeControllable and actualGM keptdistinct. | Sourcechoice and controlcompose relation, notborrowresume rule forstart/blur. |
| soft_drop280-284/gravity_interval275-278 / A11/A16ambiguities | Successfulfall incrementsgravity_restarts. Blockedrestart/reissue/phase deadlines partial; intervalcurrentderived sourceS10 requestvalue only. | Distinguishdefinedsuccessfulrestartcounter frompartialblockedcases. A16ambiguity notwithdrawitem16. | V28privatecurrentrequest/cancel adapter one successfulfall matchescounter0→1; independentNode22production/modelrerunsbyteidentical; coordinatorNode26rerun/reviewerartifactcmp notreviewer26execution. v22-v25ICDASmaps notrestartcomparison. | V28onecaseadapterreviewheld; counterdoesnotencode700/cancel, productionassertions+S10relation separate; fullclaimedrestartclasses/choiceboundaries/requested-vs-real-time scope stillpartial. |
| continue_game331-345 / S7/A17 | Failedread maymakeavailabilityeither→Undefined; invalidcontentwithdrawonContinue readingA17; semanticformatonly. | Classifyreadfailure vs invalid independently; do notcauseeffects thenrelabelUndefined. Missingrawresetdefault explicit, not0. | D43raw12/cutpoints/D48gettercontrast notcompletemodelrawparser; cachedavailability oppositeA16polarity. | Rawsemanticprojection, successfulsave definition, independentgoodcontent and source-reading relation. |
| atomic lines28-39 | Deepcopies existingmodelfields exceptenv/ch, savesRNGstate; onUndefined/ChoiceError updatescopies/restoresRNG thenraises. | Preflightallchoicesbeforeexternalwritecallables orrejectwholetrace; rollbackcannotun-callcallback. Constructor_open not wrappedatomic. | ReplacementO8reviewcorrectedenvclaim; selftestsuccessselfconsistencyonly. | External-effect/adaptercommit chronology, no callbackrollbackassurance. |


## QA2-QA6 actual required-runtime and historical report relation

Original independently reviewed receipt SHA256 `6be5bec76d4e649ea5e183a3220dd2bd927cbce81c5c740f329f4f95938d9052`.



OriginalZIP sha25673b92625d4a1912383371a9a8ef2da53cfe07f002b7aa21b570f8c1d5086aa63 matches metadataartifact11309411340 digest. Independently parsed actualmutation.json:1154records =1120Killed+32Timeout+2Ignored,1152tested;0Survived/NoCoverage/CompileError/RuntimeError. Each7embeddedenginesource string byteequal currentowningcheckout. Thresholds100/95/100 and8namedenginetestfiles command are preserved; no script/sw mutationdomain. Ignorednot tested; timeout is a detected status, not proof an assertion killedit. The13-path Git-object source identity record linkslivebe96/historical409faf4/baseline30e/owning310, sourceidentitynot equalexecutionhistory.

Actualcurrentjob metadata testcompleted/success atbe96b538, run37403477306/job112075686125. Rawlog prints Node26.10, command npmglobalinstall12.2.0 and successfulreceipt; nopostupgradeversionecho. typecheckbothconfigs command+success; unit288pass0fail0skip/sevenenginefiles printed100linebranchfunction; browser183registrations164pass19skip. Independently parsed projectrows:WKphone55pass6skip;Chromiumphone61pass0skip;desktop48pass13skip. Historicaltest raw sameprojectcounts. EmulatediPhone notphysicalphone. RawV8offsets/lcov/browsercoverageJSON not present/recovered inthispacket; printed100summary remains an actuallogoutcome, not independentlyrecomputeddenominator/assertionmeaningfulness.

Stable observedsourceurls:
- https://github.com/soliskit/tetris-js/actions/runs/37403477306/job/112075686125
- https://github.com/soliskit/tetris-js/actions/runs/37403477306
- https://github.com/soliskit/tetris-js/actions/runs/37216193410
- https://github.com/soliskit/tetris-js/actions/runs/37216743885
- https://github.com/soliskit/tetris-js/actions/runs/37216743885/artifacts/11309411340
- 


Printed coverage is actual process evidence. Its raw denominators were not independently recomputed. Source-equal historical full mutation is neither a newly rerun campaign nor the separate manual weakened-score experiment. The manual score variant remains Phase4 work. Result counts remain separate from configuration/assertion/control-flow/loop/reachability methods.

### source-identity-reconciliation.json

Exact held artifact SHA256 `5f271596cd66adec5173626a28ca48cad5e0999350800023e29baffb4ae4e188`.

Source public/test/e2e/runner/config identities were compared across livebe96b538, historical409faf4, baseline30e0085 and retainedowning310fb759. Exact object equality establishes current source identity, not execution chronology.

### parsed-project-results.json

Exact held artifact SHA256 `4bd990100303f5469de0ae23259c7dda6180992777beabf2ba28eada0e75d16b`.

```json
[
  {
    "name": "test",
    "projectCounts": {
      "iphone-14-pro-max-webkit": {
        "passed": 55,
        "skipped": 6
      },
      "iphone-14-pro-max": {
        "passed": 61
      },
      "desktop": {
        "passed": 48,
        "skipped": 13
      }
    },
    "rawSHA256": "a5d9702057d174db4fafdf85451fce37d4d0bc4ecd024f9f7d3a4fa94e94da03",
    "rawBrowserOffsetsRecovered": false
  },
  {
    "name": "current",
    "projectCounts": {
      "iphone-14-pro-max-webkit": {
        "passed": 55,
        "skipped": 6
      },
      "iphone-14-pro-max": {
        "passed": 61
      },
      "desktop": {
        "passed": 48,
        "skipped": 13
      }
    },
    "rawSHA256": "495514b2af475b41cd2cb07072551a57c964d08fa63bb1f244f6b606fa15020f",
    "rawBrowserOffsetsRecovered": false
  }
]
```

### mutation-report-summary.json

Exact held artifact SHA256 `b1336584c6d382bb77936ce6f12033443d02d7659535f34a9c9817b5af3085c4`.

```json
{
  "schemaVersion": "1.0",
  "thresholds": {
    "high": 100,
    "low": 95,
    "break": 100
  },
  "counts": {
    "Ignored": 2,
    "Killed": 1120,
    "Timeout": 32
  },
  "files": [
    {
      "file": "public/game/tetrominoFactory.js",
      "counts": {
        "Ignored": 2,
        "Killed": 143,
        "Timeout": 11
      },
      "sourceBytes": 3574
    },
    {
      "file": "public/game/gameManager.js",
      "counts": {
        "Killed": 409,
        "Timeout": 14
      },
      "sourceBytes": 20035
    },
    {
      "file": "public/game/gameState.js",
      "counts": {
        "Killed": 23,
        "Timeout": 1
      },
      "sourceBytes": 1562
    },
    {
      "file": "public/game/inputController.js",
      "counts": {
        "Killed": 328
      },
      "sourceBytes": 11682
    },
    {
      "file": "public/game/position.js",
      "counts": {
        "Killed": 4
      },
      "sourceBytes": 516
    },
    {
      "file": "public/game/session.js",
      "counts": {
        "Killed": 160
      },
      "sourceBytes": 6340
    },
    {
      "file": "public/game/tetromino.js",
      "counts": {
        "Killed": 53,
        "Timeout": 6
      },
      "sourceBytes": 4552
    }
  ]
}
```

## PLY8 playing and paused preview source equivalence

At pinned script.js SHA25659fcb3343f35d0022c739cce82c5c9601a9e3bc354a9dc991eb1660c4e599ad4, showsPieces at138 is state !== gameOver. Lines309-319 use that same predicate in playing and paused, index nextTetrominos into the same three canvases, skip missing canvas sizing, skip unchanged object identities and drawPreview otherwise. No paused-specific shape/order branch exists in that inspected path. This composes V61's actual paused draw geometry with the playing method under identical queue/canvas-size inputs, not a newly executed playing draw or proof every invalidator/frame arrives. PCE5 supplies the deal oracle, effective preview translation is separate from local roundRect geometry.

## V55 selected kick data and visitor relation

The independently selected standard SRS extract is separate from G6 geometry and excludes the Arika variant. V55 compares48 literal kick-data rows and550 actual ordinal visitor traces against the selected extract: requested-direction five candidates first, then opposite-direction five, first fitting candidate selected, unchanged when none fits, O unchanged. Recorded comparisons have zero mismatches. Ordinal fit answers are a declared stand-in, not independent real-board fitting or all rotation/history/native composition. Result/harness/review identities are in grouped and main ledgers; the actual expected source is selected reference data, not production kick constants.

## V60 all-resource opening version relation

The independent shell enumerates16 distinct actual resource paths before running the unchanged worker in a controlled VM/cache/client fixture. Independently labelled V1 and V2 contents are staged under an atomic successful-cache-publication premise and ordinary controlled time. Every one of the opening client's16 resources is V1 before and after V2 completes; the next client gets all16 V2, while retained/pinned V1 remains. Actual outcomes and the independent Python completeness/version comparator supply the bounded relation, not completeVersions() as oracle. Independent Node22 rerun matches delivered Node26 JSON except runtime/relocated source path; Python comparison byte-equal. Native cache behavior, concurrent downloads, hostile foreign creators, corrupt pins, clock jumps and slow-page cutoffs remain declared later domains.

## V61 independent drawing, backing and nominal idle relation

The actual declared current S and L/I/Z queue are stimulus, not an expected deal oracle. Independent fixed G6 geometry and V40 token-kind relation predict S cells at(0,4),(0,5),(1,3),(1,4), empty-board landing anchor18 and ghost cells(18,4),(18,5),(19,3),(19,4). Recorded last-four fill/stroke cells and three local preview shapes match. RoundRect traces omit effective preview translations, so centering/effective placement rests on separately attributed one-view pixel inspection. Five backing widths/heights equal content CSS dimensions timesDPR, with scaleDPR; border2px is excluded from contentbox, so58vs60 and42vs44 do not themselves imply an error. In the declared no-pad paused fixture after stabilization,1000logical-ms shows requests/storage/fill/stroke counters unchanged. Logical time/RAF requests are not native wakes or battery.

Initial pre-clock counter probe produced uninformative zero; corrected post-clock live wrapper recorded one registration after pause. Browser run and prior screenshot inspection remain attributed, not rerun/reviewed pixels here; independent Python comparator rerun was byte-equal. Finite DPR1Chrome declared fixture only, no fullgame/nativegamut/AT or allmodewholepage proof.

## V37 high-score raw forms and failures

Fourteen stored forms crossed with none/read/write failure give42 held records. Independent max(current score100, valid stored whole) comparison does not choose text grammar from Number(). Decimal hypothesis0|[1-9][0-9]* is declared, not adopted; exponent1e3, hex0x10 andspace7 remain unresolved grammar outcomes. Ordinary0/7/100/300 values preserve the maximum; 2^53 is whole but outside safe-integer representability, actualgetter0/write100 is a conditional boundary candidate. Read failure returns0 and writes100, lower than prior300 or2^53, not lower for0/7 or equal100. Write failure keeps each prior stored value while game continues. Storedtext/getter and high-score-before-session-write order are separate from semantic validity or native persistence. Python analysis independently reran over heldJSON, no production/browser rerun. Equal value rewrite is an actual write attempt, not automatically a forbidden semantic replacement; interpretation remains separate.
