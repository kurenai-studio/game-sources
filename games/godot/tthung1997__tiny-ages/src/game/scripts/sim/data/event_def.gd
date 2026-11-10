class_name EventDef
extends Resource
## An authored event template. State and rules decide when it fires; nothing is generated.
## With choices it opens a decision that waits for the player; without, it resolves by itself.

@export var id: StringName = &""
@export var title: String = ""
@export_multiline var body: String = ""
## character, nature, settlement or exploration.
@export var category: StringName = &"character"

@export_group("Eligibility")
## World conditions that must all hold.
@export var requires: Array[SimCondition] = []
## Whether the event is about one villager.
@export var needs_subject: bool = false
## A villager qualifies as the subject only if all of these hold for them.
@export var subject_requires: Array[SimCondition] = []
## Multiplies the chance for a subject with the trait, for example {curious: 3.0}.
@export var trait_weights: Dictionary[StringName, float] = {}
## Chance to fire each tick while eligible. Zero means the event only fires when scheduled.
@export_range(0.0, 1.0, 0.001) var chance_per_tick: float = 0.0
@export var once: bool = false
## Minimum ticks before the event can fire again.
@export var cooldown_ticks: int = 0

@export_group("Outcome")
## Applied as soon as the event fires, before any decision opens.
@export var effects: Array[SimEffect] = []
@export var choices: Array[ChoiceDef] = []
## A decision is only asked while at least this many of its choices can be picked right now:
## with one answer left there is nothing to decide (docs/gameplay.md P13). Every authored
## decision keeps the default of 2.
@export_range(1, 8) var min_choices: int = 2

var _gates_built: bool = false
var _gate_day: int = 0
var _gate_era: int = 0
var _gate_era_day: int = 0
## The age from which an event can no longer be open (a negated ERA_AT_LEAST: "only before this
## age"), or a very large number. Ages only move forward, so it never opens again once passed.
var _gate_era_before: int = 1000000


func is_decision() -> bool:
	return not choices.is_empty()


## A cheap test the event system runs first: false means a day, age or days-into-the-age
## requirement is certainly not met yet (or, for an event that ends with its age, no longer
## can be), so the other conditions need not be looked at. Each only ever moves one way with
## time, which is what makes it safe to skip on them.
func may_be_open(day: int, era_order: int, era_day: int) -> bool:
	if not _gates_built:
		_build_gates()
	return day >= _gate_day and era_order >= _gate_era and era_day >= _gate_era_day \
			and era_order < _gate_era_before


func _build_gates() -> void:
	_gate_day = 0
	_gate_era = 0
	_gate_era_day = 0
	_gate_era_before = 1000000
	for condition: SimCondition in requires:
		if condition.negate:
			if condition.kind == SimCondition.Kind.ERA_AT_LEAST:
				_gate_era_before = mini(_gate_era_before, condition.amount)
			continue
		match condition.kind:
			SimCondition.Kind.DAYS_AT_LEAST:
				_gate_day = maxi(_gate_day, condition.amount)
			SimCondition.Kind.ERA_AT_LEAST:
				_gate_era = maxi(_gate_era, condition.amount)
			SimCondition.Kind.ERA_DAYS_AT_LEAST:
				_gate_era_day = maxi(_gate_era_day, condition.amount)
	_gates_built = true


func get_choice(choice_id: StringName) -> ChoiceDef:
	for choice: ChoiceDef in choices:
		if choice.id == choice_id:
			return choice
	return null


## Chance multiplier for a subject, from their traits.
func subject_weight(subject: VillagerState) -> float:
	var weight: float = 1.0
	if subject == null:
		return weight
	for trait_name: StringName in trait_weights:
		if subject.has_trait(trait_name):
			weight *= trait_weights[trait_name]
	return weight
