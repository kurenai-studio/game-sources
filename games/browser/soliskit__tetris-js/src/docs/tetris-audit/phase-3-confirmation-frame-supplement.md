# New Game Confirmation

Recorded dialog choices and the game fields preserved in those cases.

Private later draft covering v26-v27, separate from D45 throughv13, D46v14-v17, D47v18-v21 and D48v22-v25. At the October 5, 2026 recording (D49), Phase 3 was still open. This is historical status, not a claim about the current phase. No finding classification, sound all-state correspondence, fullframe proof, oracle acceptance or certification. No production/permanent-test/CI/public mutation or clean-author feedback.

Expectations use D32 operations1/2/operation3 (confirmation answer, Cancel case): open pending while paused, selectedCancel; selection changes choice; cancel clears pending/choice and remains paused. D18B12 choice absent when notpending. Source mapping is separate: pending actualGM.isConfirmingNewGame; choice sourceuses DOM focus/buttonpress, not an enginechoicefield. Chrome154/Playwright native-dispatched trustedkeys throughbrowser, declaredRNG.3/injectedclock/1000x900, not OS/hardware/nativeelapsed. ScratchsameURLclassprototypewrappers captureactualGM/ICthis and delegateunchanged; productionfilesunchanged. TimerMap stack-filefilteredsourceattribution, not allresourceproof.

## V26 open/select/cancel
PublicEnterstart,EscapePause,Enteropen,ArrowRightselect,EscapeCancel;40injectedms each. Actualfinal four samples: GMstatepaused all; pendingfalse,true,true,false; dialogfalse,true,true,false; activeElementidblank,Cancel,NewGame,blank. Opened/selected actualpixels show focusring Cancel thenNewGame with dim pausedboard. No accept/confirmationcommit/newsession.

Coordinator actualfinal JSON checker compares captured board,current(color/position/rotation),held,canHold,queue,bag,score,resetcount,source-lowest-anchor,gravity/lock/soft handles acrossallfour: equal. StackattributedMapempty, canonicalkeysnone/movementnull, no pageerrors/trustedkeyevents. This is finite captured-field preservation, not complete semanticA1-A16frame predicate; lowestanchor/cache/physicaltoken/gesture gaps remain. Independent source/JSON/pixel reviewer supported pending/focus/paused/listedfields but didnot deepcompareallboard/bag; no browserrerun. SourcequestionButtonsfocus/press and GMcancel path fit this projection.

Firstpre-screenshotrun's closedDOMfocus wasNewGame. Finalinstrumented/screenshotrerun closedfocusblank. Coordinator initially re-used firstfocus in report despite checking otherfinalpredicates, then re-read transferredfinalJSON and corrected: strike retainedNewGame and finalvariationclaims. First/finalstdout retained separately. Persisted finalchecker now explicitly asserts closedblank alongwithpending/focus/fieldpredicates. No normative record/finding was promoted from staleclaim.

## V27 reopen afterpriorselection
Samepublicsequence extendedEnterreopen afterNewGameselection/EscapeCancel. Actualfinalpendingfalse,true,true,false,true; focusblank,Cancel,NewGame,blank,Cancel. Reopenedpendingtrue/dialogtrue/focusCancel, actualpixelsCancelring. Priorretainedfocushypothesis notborneout. BothfinalV26/V27closedfocusblank: no measuredvariationbetweenfinalfiles. Gameplayfieldpreservation checkedlocally acrossfive/Mapempty/noerrors. Independentreview supported limitedfields with board/bag/pending excluded from its gameplay comparison (pending separately checked), notcompleteframe.

SourceindexCancelbuttonautofocus andshowModal explain inferreddefaultfocus; attributecausalrole notexperimentallytested. V26opened/V27reopened images equalbytes/hash: plausibleidenticalstate, notindependentrun/actionprovenance. Keyevent/JSON/script context carrieswhichtraceoccurred. SelectedPNG isbeforecancel, notclosedfocusproof.

## Limits
Pendingfocusprojection has finiteusefulness, notuniversalmodal/A11soundness. ClosedDOMfocus has no semanticselectedchoice whenpendingfalse. Otherdialogroutes/Tab/click/gamepad/physicaldevices/accessibility/Safari/cancel/multipointer/fullresources/fullsemanticstate/checkpoints remainopen. Source-selectedCancelexpectation isgoverningD32/B12, notautofocusimplementationasoracle. No fullA1-A16operation-frame or closure result.
