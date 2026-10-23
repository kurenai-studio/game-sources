# Model and Source Comparisons

Bounded results for geometry, game transitions, saves, and controlled failures.

Status: prepared for independent review. This is not a Phase 3 exit, finding classification, implementation certification, correction approval, or permanent test change. It is implementation-exposed and must never be clean-author input.

Production base:. Documentation squash has identical public tree `1e09ad61c19e0b235a231ad8810dae176be4ea77`. Source claims use committed Phase 1 text, not production acceptance. Frozen model revision 4 SHA-256 `ad35423776ebda03c8e585d6847faa0fe5fab86431fdda8aed23967f87483430`; executable bytes remain on unmerged PR75. D39 inputs, D41 freezes and bounded review govern their identity and limits.

The coordinator ran the scratch under Node 26.10.0. Independent reviewers reran selected production traces under Node 22.23.3 and the model under Python. Runtime differences are stated rather than hidden. Model self-consistency, bounded agreement and independent reproduction do not imply formal proof.

## 1. Source geometry and fit predicate

- Requirements/properties: PCE-1, PCE-2 and the fit/no-overlap primitive used by PCE-6, O2, O5 and O8.
- State property: B2 geometry, B5 20x10 board, B6 fitted falling piece. Not a whole-transition invariant claim.
- Transition class: none for immutable geometry; fit is a primitive used by movement, rotation, spawn and persistence reconstruction. Their routes are not certified by this primitive result.
- Production: `tetrominoFactory.js:50-71` built-in kind/orientation mapping; `tetromino.js:95-106` fits through per-cell `isFree`; `gameState.js:42-44` board adapter. Kind order I,O,T,S,Z,J,L is independently checked against the 25 orientation geometries.
- Model: frozen `GEOM`, expected predicate independently written as every occupied block in 20x10 with no equality to an occupied blocker. Neither production nor model `fits()` supplies expected results.
- Evidence/method: 25 legal kind/orientation geometry pairs agree. Finite acceptance/rejection domain has 9375 positions: 25 orientations x rows -4..20 x columns -4..10. Empty board plus each in-board overlapping block gives 29375 cases (9375 empty,20000 blocker); 3931 true. Two first/last row-major free blockers per position add18750 cases,7862 true. Total48125,zero mismatches. Piece/play reviewer independently reproduced outputs and recomputed the incremental expected values; original geometry table comparison also agreed.
- Assumptions: approved B2 table, ordinary JavaScript array/cell semantics; adapter maps kinds correctly. The separate table/image relationship is not settled by runtime agreement.
- Limits: single blocker,fixed color,only10 distinct non-overlap blocker locations in extension,limited integer position range,no malformed types/multiple blockers/full-row boards,not kicks/spawn/rendering/color requirement or gameplay proof. Certification: Not Assessed; claim/evidence Candidate.

## 2. Pause/resume and reset limit

- Requirements/properties: STA-2,PLY-6,O1,O2,O5,O8.
- State/transition: B9.1 valid count, B9.2 operation semantics; paused/resting resume,playing/resting move and pause.
- Production: `gameManager.js:278-296` landing/reset,`486-500` pause/resume,`550-555` successful move.
- Model: `pause()`, `resume()`, `move()`, `_settle()` with explicit O queue; O spawn supplied only for the count16 lock case as centered2x2 top-row position. No production spawn or kicks define expected behavior.
- Method/evidence: 49 invariant-valid O states,emptyboard,row18,col4,count0..15 across resume/move/pause plus paused16 resume. Compare mode,count,piece,locked-cellcount,gravity/lock resources. B9.2 explicitly says a paused, resting piece at count15 resumes with a new delay. Only paused15 resume differs: model retains piece/count15 and startsdelay;production locksfourcells,spawns,resetcount0. Direct paused16 resume agrees. This differs from the separate Continue trace, where restored count is incorrectly0 before resume.
- Public reachability: NewGame,18softDrops,13/14/15surface moves,pause,resume. Count14 schedulesnew500msdelay;count15 locks immediately (candidate discrepancy);count16 locks (expected). No field injection in these three traces. Independent piece/play reviewer reproduced the49rows and public traces.
- Requested-deadline evidence: clock123ms,one further move from13/14/15. Below15 newdue623;at15 keepsdue500. All three agree with B9.2. Requested scheduler effects only,not actual elapsedbrowser time.
- Limits: injected initialstates are not all reachable;count0paused is invariant-valid but not ordinary restingpause result. Public traces prove only those concrete paths. Oonly/no rotations/no timercallbackinterleavings,inputresources,real deadlines or universalvalidity. Certification Not Assessed; candidate discrepancy needs Phase4/5 disposition.

## 3. Pause-save,Continue and later resume

- Requirements/properties: STA-4,STA-2,PLY-6,O3,O4,O5,O8.
- State/transition: B9.2/B16 newlywrittensaves preserve exact resetcount and semanticlowest;pause-save then new-sessionContinue,thenresume.
- Production: `session.js:29-39` serializer;`146-186` reconstruction;`gameManager.js:199-216` loader resetsnewpiececount;`219-225` save;`482-500` Continue/pause/resume.
- Model: `pause()`, `snapshot()`, `_save()`, `validate_save()`, `continue_game()`, `resume()` with explicit O geometry/queue. Semantic fields are compared,not invented released-format syntax.
- Evidence:16 invariant-valid playing/resting Oinitialcounts0..15;pausecounts1..16 agree,Continueproductioncount0allcases,modelrestoresexact1..16. Piece/mode/stoppedresources agree. Independent piece/play reviewer reproduced model/save half;state/safety reviewer independently reproduced the production half only of the16-case save-and-Continue scratch.
- Three public-action traces: NewGame,18softdrops,13/14/15surface moves,pause;newmanager,samestorage,Continue,resume. Savedcounts14/15/16;payloadkeys board,score,currentpiece,queue,held,holdavailable,bag withno count/lowest. Continueallcount0;resumeallstartdelay. Count16shouldlockinstantlyunderB9.2,so this shows abehavioraldifference independentofthe Olowestoffset. The independent piece/play reviewer reproduced this extension byte-identically on Node 22. Counts14/15 show state loss only in these traces; the count16 trace demonstrates the different lock outcome.
- Limits: currentformatonly,nolegacycompatibilityclaim;Oonly,inmemorysuccessstorage,queue/bagnotfullsemanticpostcomparison. Lowest18production versus19model is aconstant Obox/blockoffset and alone is not abehavioraldefect. Newmanagertrace notactualreload/device. Certification Not Assessed;candidatecountloss,not approvedcorrection.

## 4. Failed withdrawal/save

- Requirements/properties: STA-1,STA-3,STA-4,SAF-2,O4,O5,O6. No fault inferred from ordinary storagefailure.
- Source: S4 failedwithdrawal and S5 failedsave make oldsaveunavailable in running session;S9 retainsitem16. Preservedoldbytes/zerofaultsagreewithS6 and are not discrepancies.
- Production: `gameManager.js:158-175` cache/setter;`194`NewGamewithdrawal;`238`ordinarygameoverwithdrawal;`219-225`pause-savefailure;`482-484`Continue. UI uses samegetter,butrenderingnotobserved.
- Independentmethod: declared public-action traces withsuccessfulgoodsave,then injectedwrites throwing/readsworking. No productionvalidator or modelneeded for expectedS4/S5availability.
- Evidence: goodOsaveatrow3 via3publicsoftDrops/pause;Trace A: only eligibility-indicator writes fail, then confirmed NewGame and top-out. Trace B: all writes fail, then an extra softDrop, failed pause-save, resume and top-out. Continueatgameoverrestoresoldrow3paused,0faults. Anewgamewasrow0;Bunsavedgamewasrow4. Oldbytesremainunchanged. Independent state/safety reviewer reproducedexact outputs onNode22;coordinatorNode26.
- Earlier mixedNewGamefailure includedfailedpause-savefirst and is historical,not anisolatedwithdrawaltest. Reviewer'sownisolatedscripts clearfailurebeforeContinue;coordinator'sleavefailureactive,readsworking. Bothrestoreoldsave.
- Limits: Oonly,inmemorystorage,fakescheduler,10harddrops boundedat100,noreadfailureS7,real localStorage,crosstab,reload,UIorallstoragefailurecombinations. Certification Not Assessed;S4/S5engine-levelcandidateonly.

## 5. Timer registration fault subset

- Requirements/properties: SAF-3,O1,O4,O6,O7.
- Transition: after successfulsave/resume,inject registrationthrow onpublicsoftDrop.
- Production: guardedsoftDrop`527-529`,faultstop/loopcleanup in `gameManager.js`;source T3 trusted scheduler cancellation and S6 preservegoodsave.
- Method: failureinjection withschedulerrecordedresources andobservablefaultsignal;notcallbackexistencealone.
- Evidence: gameOver,0injectedtimers,1signal,goodsavebytesunchanged. Independent state/safety reviewer reproducedexact productionresult.
- Limits: gravityregistrationonly;noinputtimer,clearTimeoutthrow,postcancelcallback,partialwrite,realbrowserresources. T1 requires a separate plain on-screen player message; its display was not observed. One test-observable signal is not the whole SAF-3 report criterion or safe-state proof. Certification Not Assessed;boundedsubsetcandidate.

## 6. Fixed-orientation movement and soft-drop correspondence

Requirements/properties: PLY-1, defined PLY-3 semantic fall subset, PCE-6, O5/O8. Production routes `gameManager.js:245-258,550-555,527-529`; model `move()`, `soft_drop()`, `_fall_one()`, `_settle()`.

Declared before execution:25 legal orientations x3rows(0,8,floor row) x3columns(left bound,source-derived middle,right bound) x3actions(left,right,softdrop)=675 empty-board cases,count0. Initial and post model states valid,noUndefined. Compared mode,piece,count,semantic-lowest projection,full board,gravity/lock scheduler presence and fault count. Node26:675 agree,0faults. Independent piece/play reviewer regenerated inputs and reproduced both outputs exactly onNode22.

Production lowest box row is normalized by fixed orientation's greatest local block row. This constant-offset conversion is valid only in the declared fixed-orientation domain; it cannot establish correctness of rotation/history or the meaning of the underlying lowest field. Rows0/8/floor give no landing-by-fall. No ledge,landing,nonemptyboard,new-lowest-by-move,count15/16,deadline or gravity-restart-counter comparison is claimed. Blockedsoftdrop compares unchanged semantics/resourcepresence,not restart timing. These are invariant-valid injected states,not all reachable states. Candidate correspondence only;certification Not Assessed.

## 7. Reproducibility and authority

Scratch files and exact results are preserved outside the repository. They are not permanent tests. Every file hash belongs to a coherent final pack;old stale48-row production result was replaced by49rowfile matchingNode26 authoritativeoutput. No model revision changed aftercomparison. No production/test/CI/requirements/public-sitechange was made by this supplement.

Scope provenance only: the original owner exchanges were independently inspected for automatic advancement through Phase10 with phase criteria and safety retained, and documentation-only merges with unchanged-code public-site deployment. Later restrictions and original exchanges govern, not this record. This creates no new permission and authorizes no production, test, CI, scope, test-removal or certification changes. Private source proof is retained separately.

## 8. Remaining Phase 3 mapping work

All55 requirement records remain alongside this supplement. `phase-3-model-method-mapping.md` now supplies model-function or non-applicability anchors and independent methods for all55 rows; `phase-3-O1-O8-obligations.txt` now supplies the eight adopted-property records. The scope-table claim/method cells cross-reference those records. These documentary additions are complete as records, not complete evidence or certification. Writer/frame/checkpoint analysis, ordinary/fault/resource projection, raw released-format and high-score adapters, persistence cutpoints, dependency accounting and O8 provenance still need claim-appropriate evidence. Device/display/browser/input, kicks, opening/spawn choices, timer phases and blocked soft-drop request behavior retain explicit gaps or separate methods. Bounded observations do not erase those gaps. This supplement alone closes none of the remaining exit items.
