class_name ObstacleState

var combatant := CombatantState.new()
var position: Vector2i = Vector2i(-1, -1)  # (-1,-1) = use BattleSetup default


func duplicate() -> ObstacleState:
	var s := ObstacleState.new()
	s.combatant = combatant.duplicate()
	s.position = position
	return s
