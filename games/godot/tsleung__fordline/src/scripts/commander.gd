class_name Commander
extends RefCounted
## Turns a battle into orders for one side. This one gives none: an army
## that is never commanded, the bottom of every skill ladder. The AI and
## anything else that commands a seat extends it.


func decide(_b: Battle, _team: int) -> Array:
	return []


## The core AI with a persona. `rally` blows the Rally horn when regiments
## near the general are breaking or broken, as a sharp player does.
class AICommander extends Commander:
	var persona: Dictionary
	var rally := false

	func _init(with_persona: Dictionary, blows_rally := false) -> void:
		persona = with_persona
		rally = blows_rally

	func decide(b: Battle, team: int) -> Array:
		var orders := AI.decide(b, team, persona)
		if rally and team == 0 and should_rally(b):
			orders.append({"type": "rally"})
		return orders

	## The horn is ready, the general stands, and a regiment within his
	## reach is running but worth saving, or close to running.
	static func should_rally(b: Battle) -> bool:
		if b.cooldowns.rally > 0.0:
			return false
		var g := b.general_of(0)
		if g == null:
			return false
		for r in b.team_regiments(0):
			if r == g or r.pos.distance_to(g.pos) > Battle.RALLY_RADIUS:
				continue
			if r.state == Regiment.State.ROUTING and r.strength() >= 0.2:
				return true
			if r.fighting() and r.morale < r.morale_max * 0.25:
				return true
		return false
