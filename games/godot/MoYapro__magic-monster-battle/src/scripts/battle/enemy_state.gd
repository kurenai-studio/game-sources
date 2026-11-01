class_name EnemyState

var combatant := CombatantState.new()
var armor: int = 0
var block: int = 0
var attack_mult: float = 1.0
var stunned_turns: int = 0
var position: Vector2i = Vector2i(-1, -1)  # (-1,-1) = use BattleSetup default
var intent: Dictionary = {}


func duplicate() -> EnemyState:
	var s := EnemyState.new()
	s.combatant = combatant.duplicate()
	s.armor = armor
	s.block = block
	s.attack_mult = attack_mult
	s.stunned_turns = stunned_turns
	s.position = position
	s.intent = intent.duplicate()
	return s
