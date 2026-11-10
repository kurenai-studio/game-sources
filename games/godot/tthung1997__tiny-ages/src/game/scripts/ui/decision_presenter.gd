class_name DecisionPresenter
extends RefCounted
## Turns a pending decision into what the player is shown: the title, the text and the choices,
## each listed, enabled or greyed out with what it needs. Pure logic, no nodes.
##
## A choice is **listed** when the only things stopping it are resources or items (the player
## can see what they are waiting for); anything else (a staged unlock, a building already built)
## keeps it off the list, so nothing hidden is hinted at. It is **enabled** when nothing stops it.

class NeedView extends RefCounted:
	var key: StringName = &""
	var amount: int = 0
	var have: int = 0
	var met: bool = true

class ChoiceView extends RefCounted:
	var id: StringName = &""
	var label: String = ""
	var enabled: bool = true
	## What the choice needs, for example "needs 6 wood" or "needs 6 wood (have 2)".
	var note: String = ""
	## The same, structured, so the panel can draw icons.
	var needs: Array[NeedView] = []

var decision_id: StringName = &""
var event_id: StringName = &""
var title: String = ""
var body: String = ""
var choices: Array[ChoiceView] = []


static func present(decision: PendingDecision, sim: Simulation) -> DecisionPresenter:
	var view: DecisionPresenter = DecisionPresenter.new()
	view.decision_id = decision.id
	view.event_id = decision.event_id
	var event: EventDef = sim.content.get_event(decision.event_id)
	if event == null:
		view.title = String(decision.event_id)
		return view
	var subject: VillagerState = sim.world.find_villager(decision.subject_id)
	view.title = _format(event.title, subject)
	view.body = _format(event.body, subject)
	for choice: ChoiceDef in event.choices:
		var entry: ChoiceView = _present_choice(choice, sim, subject)
		if entry != null:
			view.choices.append(entry)
	return view


static func _present_choice(
	choice: ChoiceDef, sim: Simulation, subject: VillagerState
) -> ChoiceView:
	var needs: PackedStringArray = PackedStringArray()
	var need_views: Array[NeedView] = []
	var enabled: bool = true
	for condition: SimCondition in choice.requires:
		var wants_stock: bool = not condition.negate and (
			condition.kind == SimCondition.Kind.RESOURCE_AT_LEAST
			or condition.kind == SimCondition.Kind.ITEM_AT_LEAST
		)
		var met: bool = condition.is_met(sim.world, sim.config, subject)
		if not wants_stock:
			if not met:
				return null
			continue
		var have: int = sim.world.resource_amount(condition.key) \
				if condition.kind == SimCondition.Kind.RESOURCE_AT_LEAST \
				else sim.world.item_count(condition.key)
		var need: NeedView = NeedView.new()
		need.key = condition.key
		need.amount = condition.amount
		need.have = have
		need.met = met
		need_views.append(need)
		if met:
			needs.append("%d %s" % [condition.amount, _name(condition.key)])
		else:
			enabled = false
			needs.append("%d %s (have %d)" % [condition.amount, _name(condition.key), have])
	var entry: ChoiceView = ChoiceView.new()
	entry.id = choice.id
	entry.label = _format(choice.label, subject)
	entry.enabled = enabled
	entry.needs = need_views
	if not needs.is_empty():
		entry.note = "needs " + ", ".join(needs)
	return entry


static func _name(key: StringName) -> String:
	return String(key).replace("_", " ")


static func _format(text: String, subject: VillagerState) -> String:
	if subject == null:
		return text
	return text.replace("{subject}", subject.display_name)
