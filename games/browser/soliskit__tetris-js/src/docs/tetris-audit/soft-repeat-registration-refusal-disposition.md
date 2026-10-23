# Soft-Repeat Registration Failure

The event path from a held S key to an interval request.

Status: Confirmed Defect by independently reviewed conditional source argument for the ordinary S event and declared registration refusal below. Operative only after documentation review, exact-head checks, authorized merge and postmerge publication verification. Not newly Reproduced, native scheduler evidence, full SAF/T3/U4/R1 or Phase4 closure.

## Independent criterion

D22 T3 puts timer registration and cancellation throws inside SAF-3: the game must stop safely. D23 U4 includes held-key repeat timers, distinct from drawing and controller polling. The original owner timer-start/cancel question and agreement, and the held-repeat timer-scope question and answer, were independently inspected. No exclusion for this interval registration was found.

Successful cancellation remains trusted. This route refuses registration before callback acceptance or retention; it uses no orphan callback, failed cancellation or delivery after successful cancellation. U3's failed-cancellation-during-fault-stop exception is not its criterion.

## Ordinary registered event

The unchanged public source tree is1e09ad61c19e0b235a231ad8810dae176be4ea77. Choose ordinary O-first NewGame using twelve valid zero-valued shuffled-factory results: empty dense20x10 board, O at(0,4), queueT/S/Z, bagJ/L/I, score0, no held piece and no lock delay. InputController construction registers the shipped key handlers. Its soft-repeat handle starts undefined.

Prior storage, timer, RAF and nonauthoritative onChange operations succeed. No competing actor, other input or gameplay/repeat callback intervenes. The single declared refusal is global setInterval throwing synchronously before accepting or retaining the repeat callback. This is an explicit provider cut, not a measured native failure.

1. Registered nonmodifier, nonrepeat physical S keydown enters KeyS in heldKeys and calls GM.softDrop.
2. GM.guard/runChecked encloses the immediate dropTetromino operation. O moves from(0,4) to(1,4), remains airborne, successfully replaces ordinary gravity and returns playing without an invariant error. Its cells occupy rows1/2 and columns4/5 on the empty board.
3. After that guarded call returns, IC.updateSoftDrop sees KeyS and calls startSoftDrop. Global setInterval is invoked outside GM.guard. The declared registration refusal throws before acceptance; the later assignment to softDropTimer never completes, so no repeat resource or handle is created.
4. The exception unwinds startSoftDrop→updateSoftDrop→handleKey. The registered key listener has no catch or safe-stop conversion. No surrounding shipped page conversion calls GM.failSafe for this path.

At the handler-exception boundary, the game remains playing with O at(1,4) and its successfully registered gravity timeout outstanding. No gameplay callback after the refusal is delivered. Browser event-error reporting can expose the uncaught exception, but does not itself perform the required game-specific safe-stop transition.

## Scoped consequence

Confirmed by conditional source argument: an applicable held-repeat timer registration throws, yet this ordinary event path does not reach SAF-3 gameOver. The wrong mode and missing safe-stop conversion already fail that component of T3. A browser error, later redraw or continued event processing is not a substitute for the stopped-game state.

This comparison does not classify T1's plain player notice or separate test signal, nor establish independently good prior-save content or S6 preservation. Full R1 prestate and detector extent are not certified. The focused ordinary geometry, source call boundaries, successful earlier providers and one refusal-before-acceptance cut remain explicit premises.

## Limits

No game, harness or reference-model execution was performed for this source argument. Existing W28 disconnect-cancellation and retained-registration orphan records remain separate cases with their own evidence and limits; successful Pause retention, paused-firing checkpoint and Resume rearm/movement likewise use different cuts and criteria.

Native scheduling, every registration/cancellation failure, horizontal or gamepad controls, fault-stop composition, all event schedules, full SAF/T3/U4/R1, persistence, Q2 and Phase4 remain open. No correction, permanent test, model, requirement, CI or public-site change is included. A later correction needs its own review and approval.
