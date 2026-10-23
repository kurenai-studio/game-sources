# Serialization Failure Handling

Separate a serialization exception from a failed storage operation.

Status: Confirmed Defect by independently reviewed source argument in the declared injected-serialization-failure domain. This record becomes operative only after documentation review, exact-head checks, authorized merge and postmerge publication verification. No new runtime reproduction, native-cause claim, property certification or Phase4 closure.

## Admission and criterion

The original audit blueprint includes serialization failures and malformed internal state in its failure model. Its F23 method expressly calls for injecting a failure at serialization and comparing the response with SAF2, SAF3 and O4. A naturally occurring exception from unmodified JSON serialization of fully canonical ordinary objects is a different claim, not a prerequisite for this declared injection domain. Earlier private comparisons left that stronger ordinary-cause premise open; it must not silently become a new admission rule.

SAF3 requires an engine exception to stop the game safely, with game over, no timers and a reported fault. D22 T1 requires both a plain player message and a separate test-observable signal. SAF2 and D23 U1 exempt failed storage operations from stopping gameplay. An exception while evaluating serialization before any payload storage call is not a storage-operation failure. No adopted rule found in the reviewed trust records excludes this explicitly injected failed dependency by assuming JSON never throws. Successful specified browser APIs and native-browser conformity are different trust claims.

D21 S5 requires withdrawal of the previous save after a failed save; it does not waive the engine-error stop/report requirement. S3's statement that a fault stop by itself does not withdraw a save must not be overstated into a prohibition of S5 withdrawal after this combined failed-save trigger. The false eligibility write is therefore not itself the defect established here. Opaque previous bytes and incomplete content classification do not establish S6 last-good preservation or loss.

## Exact source response

At source main, public/game/gameManager.js SHA25631bb2160852bd24485ba258c458b74acdec110c1e11b0d94f4f852f3cf27b9ea and public/game/session.js SHA25654acbea460218f0e0a827619eae51e265461fe9ac6575dc8bf48727f6483049b:

1. Public Pause changes mode to paused, cancels gravity and lock delay, then calls saveGameSession.
2. The save try evaluates serializeSession before invoking payload storage.setItem. A declared serialization exception prevents that payload call.
3. The inner catch attempts false eligibility through the setter. Under successful, noninterfering flag storage, that write succeeds. The setter also contains its own storage-error catch.
4. saveGameSession returns normally without a failure result or rethrow. The owning runChecked still runs its invariant check. Under the separately stated ordinary poststate and successful scheduler/storage premises, the check returns null.
5. The owning operation remains paused, with no failSafe and no test-observable fault signal caused by this serializer exception. Catching the exception does not make it a storage failure.

This violates the required game-over and test-signal facets of SAF3 for the admitted injected nonstorage engine exception. No claim is made that the invariant boundary was skipped. No complete player-display receipt is supplied; the missing required stop and test signal suffice for this narrow source-argument defect. Timer cleanup success in this route does not certify every safe-stop facet.

## Historical corroboration and limits

Historical115 corroborates this mechanism at an artificial global JSON.stringify seam: an armed wrapper throws only on the selected serialization object with own gameBoard/bag keys during public Pause. It does not simulate a storage exception, BigInt, circular reference or native serializer failure. The observed row has serializer entry/throw, no payload attempt, false flag write, normal save return, invariant result null, paused mode, no outstanding timers and no failSafe/onFault signal.

That historical evidence was repeated: two worker launches plus a coordinator rerun with adjusted output/root. The restoration assigns a captured bound stringify delegate, not the original unbound function identity. A repaired lowest-row field, subset validity classifier and opaque old payload do not certify R1/B16 or prior-good write provenance. Original raw archive/source-launch/process limitations remain. This is qualified historical artificial-mechanism corroboration, not a newly Reproduced native failure or fresh UI measurement.

## Disposition and remaining work

F23 is Confirmed Defect by the conditional source argument above, with qualified historical corroboration, for swallowed injected nonstorage serialization exceptions with a normal post-operation invariant result. It is separate from the new-save reset-count information-loss finding and from storage-error handling. It is not folded into F20: the stop/signal failure does not require an O4 ordering violation or good-prior payload.

Natural/native causes on fully canonical ordinary objects remain Not Established. Full T1 player messaging, all failure compositions, successful last-good preservation, R1/B16/F20/S6 properties and Phase4 remain open. No owner rule or absent-field default is adopted. No correction, permanent test, executable model, requirement, CI or public-site change is authorized by this record. The next correction proposal must preserve S5 withdrawal and SAF2 storage-error continuation while separating nonstorage engine exceptions, with its own approval and regression/collateral review.
