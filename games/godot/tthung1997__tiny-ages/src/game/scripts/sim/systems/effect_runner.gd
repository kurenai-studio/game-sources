class_name EffectRunner
extends RefCounted
## Applies authored SimEffects to the world. The single place where events change anything.


func apply(
	effect: SimEffect, sim: Simulation, subject: VillagerState, event: EventDef
) -> void:
	var world: WorldState = sim.world
	var event_id: StringName = event.id if event != null else &""
	var kind: StringName = event.category if event != null else &"settlement"
	var subject_id: StringName = subject.id if subject != null else &""
	match effect.kind:
		SimEffect.Kind.ADD_RESOURCE:
			world.add_resource(effect.key, effect.amount)
		SimEffect.Kind.SET_FLAG:
			world.flags[effect.key] = true
		SimEffect.Kind.CLEAR_FLAG:
			world.flags.erase(effect.key)
		SimEffect.Kind.ADD_ITEM:
			world.add_item(effect.key, effect.amount)
		SimEffect.Kind.REMOVE_ITEM:
			world.add_item(effect.key, -effect.amount)
		SimEffect.Kind.START_BUILD:
			if not sim.start_building(effect.key):
				push_warning("Could not start building '%s'" % effect.key)
		SimEffect.Kind.SEND_AWAY:
			if subject == null:
				push_warning("SEND_AWAY needs a subject")
				return
			subject.activity = VillagerState.ACTIVITY_AWAY
			subject.location = effect.key
			subject.away_until_tick = world.tick + effect.amount
		SimEffect.Kind.SCHEDULE_EVENT:
			var queued: ScheduledEvent = ScheduledEvent.new()
			queued.event_id = effect.key
			queued.subject_id = subject_id
			queued.due_tick = world.tick + effect.amount
			world.scheduled.append(queued)
		SimEffect.Kind.PLANT:
			if not sim.plant_seed(effect.key):
				push_warning("Could not plant '%s'" % effect.key)
		SimEffect.Kind.JOURNAL:
			sim.add_journal(_format(effect.text, subject), kind, event_id, subject_id)
		SimEffect.Kind.ACHIEVEMENT:
			sim.grant_achievement(effect.key, effect.text)
		SimEffect.Kind.SET_PROFESSION:
			if subject != null:
				subject.profession = effect.key
		SimEffect.Kind.ADVANCE_ERA:
			if not sim.advance_era(effect.key):
				push_warning("Could not advance to era '%s'" % effect.key)
		SimEffect.Kind.ADD_VILLAGER:
			for _newcomer: int in effect.amount:
				sim.add_villager()
		SimEffect.Kind.REMOVE_VILLAGER:
			for _leaver: int in effect.amount:
				sim.remove_villager()
		SimEffect.Kind.SET_WEATHER:
			sim.set_weather(effect.key, effect.amount)
		SimEffect.Kind.CLEAR_WEATHER:
			sim.clear_weather()
		SimEffect.Kind.DAMAGE_BUILDING:
			sim.damage_building(effect.key, effect.text, kind, event_id)
		SimEffect.Kind.REPAIR_BUILDING:
			sim.repair_buildings(effect.key)


func _format(text: String, subject: VillagerState) -> String:
	if subject == null:
		return text
	return text.replace("{subject}", subject.display_name)
