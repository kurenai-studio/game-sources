# managers/rat_manager/

RatManager coordinates the colony's rats and resolves its LocationManager and
JobManager dependencies through scene unique names.

On each GameClock tick, the manager gets copied rat state, collects applicable
location and active-job rates, runs NeedSystem then StressSystem on a narrow
update draft, and asks the rat to accept it. Scheduled decision slots call
`request_destination_choice()` with copied scoring options and live destinations.

`_assign_slot()` gives each new rat a weighted-random slot out of
GameConstants.GAME_TICK_SLOTS, biased toward less-occupied slots.
TickSlotRegistry (`rat_registry.gd`) stores each slot's index and rats.

The manager checks active work against assignment, activity, and current location.
Arrival and assignment changes request work through the rat's acceptance methods;
holding an assignment alone does not apply work effects.

Inspection uses `get_rat_state_snapshot(rat_id)` and ID-based click/state signals.
`request_debug_state_update()` forwards a complete draft to its owning rat.
Debug selection and time controls live in `debug/controller/debug_controller.gd`.
