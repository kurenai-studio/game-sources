class_name Fights
extends RefCounted
## Battles fought computer against computer, for the suite and the studies:
## the ladder of player commanders, and one way to fight a battle with them,
## through the same loop the game uses.

## Player commanders of rising skill (idle to sharp), then sharp with one
## change each (reserve, hills). every: seconds between decisions (0 never
## decides). persona: the AI persona it plays with. rally: whether it blows
## the horn when regiments near the general break.
const POLICIES := {
	"idle": {"every": 0.0, "persona": {"hold": 8.0, "flank": false}, "rally": false},
	"slow": {"every": 4.0, "persona": {"hold": 8.0, "flank": false}, "rally": false},
	"standard": {"every": 0.75, "persona": AI.PERSONAS["balanced"], "rally": false},
	"sharp": {"every": 0.4, "persona": AI.PERSONAS["balanced"], "rally": true},
	"reserve": {"every": 0.4, "persona": AI.PERSONAS["reserve"], "rally": true},
	"hills": {"every": 0.4, "persona": AI.PERSONAS["hills"], "rally": true},
}
## A quick battle may not run longer than this; a grand one runs to dusk.
const TIME_CAP := 600.0


## The player's seat for `policy`.
static func player_seat(policy: String) -> BattleRun.Seat:
	var p: Dictionary = POLICIES[policy]
	if p.every <= 0.0:
		return BattleRun.Seat.new(0, Commander.new())
	return BattleRun.Seat.new(0, Commander.AICommander.new(p.persona, p.rally), p.every)


## Fight `b` to its end, the enemy under `enemy_persona` and the player
## under `policy`. With `logged`, the player's orders go into the run's log
## as its turns, so the battle can be replayed with one taken out. Returns
## the run, with its trace.
static func fight(b: Battle, enemy_persona: Dictionary, policy: String, logged := false) -> BattleRun:
	var run := BattleRun.new(b)
	for seat in seats(enemy_persona, policy):
		seat.logged = logged and seat.team == 0
		run.add_seat(seat)
	run.begin()
	run.run_for(length(b))
	return run


## The seats for a fight: the enemy first, then the player, the order in
## which they decide within a step.
static func seats(enemy_persona: Dictionary, policy: String) -> Array:
	return [BattleRun.Seat.new(1, Commander.AICommander.new(enemy_persona)), player_seat(policy)]


static func length(b: Battle) -> float:
	return maxf(TIME_CAP, b.deadline + 10.0)
