# Requirements and Evidence Methods

Where the independent model applies, and how other claims can be checked.

Status: draft supplement to the unchanged 55 partition records. Candidate mappings, certification Not Assessed. No Phase 3 exit. Existing partition records keep their state properties, production routes, assumptions, and code references. This table supplies current model applicability and independent method. Method plans are not treated as executed evidence. Frozen revision 4 only; production base0f4e510 and public-identical documentation main902d504. All names below are exact model functions except explicitly semantic fields. Undefined caller choices remain limits, never copied from production.

| ID | Model function or non-applicability | Actual independent method / planned method | Evidence held now | Remaining limit |
| --- | --- | --- | --- | --- |
| PCE-1 | valid_state; _open; _start_game; _lock; continue_game | Board-writer argument; independent per-cell/dimension classification | Finite fit primitive only; existing partition evidence | No complete board-writer argument or hostile board domain run |
| PCE-2 | GEOM only, no transition | Approved geometry comparison; fixed-color writer analysis | 25 geometry pairs agree | Image/table relation and color writer claim not certified |
| PCE-3 | _spawn; new_game; _lock; hold | Geometry plus centering relation, route enumeration | O caller position supplied in bounded traces | Non-O odd-width centering choice remains partial |
| PCE-4 | rotate; _settle | Independent kick oracle plus order/control-flow relation | No rotation differential evidence | Kicks absent from pack; no production-derived expected kicks |
| PCE-5 | Env.shuffle7; _draw; _next_from_queue; _start_game | Bag permutation and queue induction; replaceable random-source checks | No independent bag enumeration run | Model convention and supplied O factory are not shuffled-bag evidence |
| PCE-6 | fits; valid_state; all piece writers | Independent fit primitive plus transition validity argument | 48125 finite primitive cases; bounded pause/move traces | Primitive agreement is not all legal transition validity |
| PLY-1 | move; _settle | Mapped movement differential and no-op relation | Surface moves in49-state/public traces;675 fixed-orientation empty-board movement cases | O resting only; blocked, ledge and all orientations not covered |
| PLY-2 | gravity_tick; gravity_interval_s; _fall_one | S10 requested-delay predicate; mapped fall and scheduler evidence | Successful soft drops establish reachability, not gravity callback differential | Start/resume request phases and real elapsed timer behavior not modelled |
| PLY-3 | soft_drop; gravity_restarts; _fall_one | Successful-fall differential and requested scheduler restart | Public soft-drop setup;one registration fault;675 movement/fall cases with no landing/restart-counter claim | No dedicated restart comparison; blocked soft-drop reading remains limited |
| PLY-4 | hard_drop; landing_row; _lock | Independent landing predicate then lock/score differential | Public hard drops used for top-out | Harness setup is not complete hard-drop correctness evidence |
| PLY-5 | landing_row semantic only | Independent landing comparison plus actual ghost pixels | No ghost pixel evidence | Rendering has no model transition |
| PLY-6 | _settle; pause; resume; lock_expire | B9.2 differential; scheduler request/deadline relation | 49 states, public count14/15/16 resume; three move deadlines | Resume15 discrepancy; rotations, ledges and real delay unassessed |
| PLY-7 | hold; _spawn; _next_from_queue | Hold swap/once-per-piece differential | No independent hold run | Spawn choices and failure path require separate mapping |
| PLY-8 | queue; _next_from_queue semantic only | Queue induction plus upcoming-piece rendering | Queue aligned only at scratch initialization | Postqueue semantics and pixels not compared |
| SCO-1 | _lock; LINE_SCORE; _set_score | Independent row-clear/score enumeration | No dedicated line-clear differential | Full-row accepted states and >4 clear cases need separate relation |
| SCO-2 | level_of; level | Independent integer arithmetic and mapped getter | Existing partition proposed method only | No independent range/result enumeration performed |
| SCO-3 | _set_score semantic only | Independent stored-high-score predicate; write ordering and monotonicity | No dedicated high-score run | Persistence timing/text validity outside model |
| STA-1 | _open; new_game; open_confirm; select; answer; _start_game | NewGame/frame differential plus real dialog events/pixels | Public NewGame and failed withdrawal traces | Dialog and opening queue/start held-control choices incomplete |
| STA-2 | pause; resume | Mode/resource differential plus input repeat relation | 49 states and public resume/save traces | Resume15 candidate; input resources not injected |
| STA-3 | _game_over; _spawn; _lock; hold | Spawn failure differential; all resource/withdrawal evidence | Public O top-out and failed withdrawal | No all-spawn or hold-top-out domain; UI resources separate |
| STA-4 | pause; _save; snapshot; continue_game; _lock | Semantic save/restore differential; C1 line-clear ordering | 16 save cases; public saved14/15/16; failed save | Current format O only; count loss candidate; line-clear save untested |
| STA-5 | page_hidden; pause | Pause semantic mapping plus real visibilitychange event | No independent hidden event run | Browser dispatch route not proved by model alias |
| STA-6 | validate_save/continue_game post-state only | Exact released fixtures against independent semantic expectations | No released-fixture run | Model has no released syntax; legacy L1/L2 remain separate |
| SAF-1 | validate_save; continue_available; continue_game | Independent B16 hostile payload classifier/reconstruction relation | Successful current-format O loads only | No hostile payload domain or whole rejection proof |
| SAF-2 | _withdraw; _save; continue_available; Env.write_ok | Storage failure injection from S4-S9; high-score predicate separate | Reviewed distinctive failed writes restore old row3 | Read failures, full/missing storage and all branches not run |
| SAF-3 | fault_stop semantic subset | Guard/fault route argument; injected resource failures and T1 notice | Registration throw: stopped, zero injected timers, signal, save preserved | T1 player message, input resources and other throws unassessed |
| SAF-4 | valid_state; fault_stop | Writer induction plus independent predicate attacks and check-point inventory | Invariant-valid initial model states only | No complete detection domain, all-checkpoint or legal-play proof |
| SAF-5 | Not Applicable: outer-layer failure | Drawing/gamepad injection, loop continuity, U2 notice and engine state preservation | Existing P3-D proposed method only | No independent browser fault run |
| SAF-6 | Defined gameplay operations and valid_state | Seeded bounded lockstep random walks; universal property separately | No random lockstep run | Undefined choices require preflight; no universal inference from finite samples |
| INP-1 | Engine semantic actions only | Real keyboard-to-action mapping | No new independent input evidence | Key codes/default behavior outside model |
| INP-2 | press; release; repeat_fire; blur; resume | Held-token differential plus requested repeat timing | No new independent input evidence | Release repeat/start/blur choices partial; actual resources outside model |
| INP-3 | press(modified) and duplicate-token no-op subset | Modifier/repeat event matrix and defaultPrevented | No new independent input evidence | Ignored-modifier/default-prevention conflict remains unreconciled |
| INP-4 | press/release/repeat semantics subset | Real standard-pad event matrix and repeat scheduler | No new independent input evidence | Button precedence/disconnect/dialog UI not modelled |
| INP-5 | touch_begin; touch_move_cols; touch_drop_rows; touch_end; touch_cancel | Independent pixel-to-cell drag relation and E1 excursion evidence | No new independent input evidence | Tap direction/kicks partial; pixel geometry outside model |
| INP-6 | Not Applicable: accessibility/DOM behavior | Keyboard/focus/accessible-name inspection and pixels | No new independent input evidence | No independent accessibility run |
| DSP-1 | Not Applicable: display/DOM/platform claim | Phone layout screenshots and measured bounds | Existing P3-E proposed method and cited tests only | Device portrait sizes remain evidence gap |
| DSP-2 | Not Applicable: display/DOM/platform claim | Canvas backing resolution and resize pixels | Existing P3-E proposed method and cited tests only | Device pixel density not covered by semantic model |
| DSP-3 | Not Applicable: display/DOM/platform claim | Independent draw/storage/frame call counters | Existing P3-E proposed method and cited tests only | No new performance/idle run |
| DSP-4 | Not Applicable: display/DOM/platform claim | Safari touch/zoom/browser gesture traces | Existing P3-E proposed method and cited tests only | Required actual Safari behavior remains gap |
| DSP-5 | Not Applicable: display/DOM/platform claim | Live DOM/state/storage-event comparison | Existing P3-E proposed method and cited tests only | Continue availability semantics separate from visual state |
| DSP-6 | Not Applicable: display/DOM/platform claim | Context colorSpace negotiation plus actual color pixels | Existing P3-E proposed method and cited tests only | Display P3 device remains gap |
| DSP-7 | Not Applicable: display/DOM/platform claim | Wake-lock acquire/release/refusal/revoke browser traces | Existing P3-E proposed method and cited tests only | Platform behavior remains gap |
| DSP-8 | Not Applicable: display/DOM/platform claim | Game-over rendering pixels and screen-reader announcement | Existing P3-E proposed method and cited tests only | Semantic game-over alone does not verify rendering |
| APP-1 | Not Applicable: app/server/cache/device claim | Install/full-screen/icon on target device | Existing P3-E static/cited evidence only | Installation/device evidence gap |
| APP-2 | Not Applicable: app/server/cache/device claim | Service-worker version/offline/atomic cache attacks | Existing P3-E static/cited evidence only | Semantic game model not a cache oracle |
| APP-3 | Not Applicable: app/server/cache/device claim | Independent resource-reference/MIME/subfolder graph checks | Existing P3-E static/cited evidence only | Live server/browser evidence still needed |
| APP-4 | Not Applicable: app/server/cache/device claim | Target iOS/Safari/iPhone compatibility matrix | Existing P3-E static/cited evidence only | Real device evidence gap |
| APP-5 | Not Applicable: app/server/cache/device claim | Preload/import graph plus observed request timing | Existing P3-E static/cited evidence only | Network request behavior needs browser run |
| APP-6 | Not Applicable: app/server/cache/device claim | Namespaced storage/cache inventory and foreign-cache attacks | Existing P3-E static/cited evidence only | Mandatory scratch attacks not yet run |
| QA-1 | Not Applicable: tooling/process claim | Exact test-tag/requirement inventory and assertion linkage | Existing traceability tests only | Tags do not establish assertions verify claims |
| QA-2 | Not Applicable: tooling/process claim | Node26 coverage plus unreachable-code review | Coordinator reported local288 tests/configured100% engine coverage pass; execution report still needs durable citation | Coverage is not independent correctness or removal authority |
| QA-3 | Not Applicable: tooling/process claim | Chromium script coverage report and denominator review | No new browser coverage run | 100% browser coverage not established here |
| QA-4 | Not Applicable: tooling/process claim | WebKit/Chromium phone/desktop execution reports | No new full matrix run | Required runtime/browser matrix remains gap |
| QA-5 | Not Applicable: tooling/process claim | Strict tsconfig/reachable-public graph and CI ordering | Coordinator reported local typecheck pass; execution report still needs durable citation | Typecheck does not prove semantic validity |
| QA-6 | Not Applicable: tooling/process claim | Exact mutation report/config/equivalence reasons and CI triggers | No new mutation run | Survival/timeouts/equivalence not certified |

The governing blueprint requires a complete claim-appropriate mapping and evidence, not merely a function name. Each row refers back to its exact P3-C/D/E record. Before exit, these proposed methods need claim-specific arguments, executions, or explicit justified dispositions. No artificial model relation is made for platform or process requirements. After independent fidelity review, scope-table claim/method columns can cross-reference these records. The owner scope and certification columns must not change.
