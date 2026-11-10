class_name SimEffect
extends Resource
## One change to the world, applied when an event fires or a choice is picked. Applied by
## EffectRunner. Text fields may use `{subject}` for the subject villager's name.

enum Kind {
	## Append new kinds at the end: saved .tres content stores the integer value.
	ADD_RESOURCE, ## Add `amount` (may be negative) of resource `key`.
	SET_FLAG, ## Set world flag `key`.
	CLEAR_FLAG, ## Clear world flag `key`.
	ADD_ITEM, ## Add `amount` of item `key` to the inventory.
	REMOVE_ITEM, ## Remove `amount` of item `key` from the inventory.
	START_BUILD, ## Begin constructing building `key`, paying its cost.
	SEND_AWAY, ## Send the subject to location `key` for `amount` ticks.
	SCHEDULE_EVENT, ## Fire event `key` for the same subject after `amount` ticks.
	PLANT, ## Plant one item `key` from the inventory.
	JOURNAL, ## Write `text` to the world journal.
	ACHIEVEMENT, ## Earn achievement `key`, shown as `text`.
	SET_PROFESSION, ## The subject's profession becomes `key`.
	ADVANCE_ERA, ## The settlement enters era `key` (must be later than the current one).
	ADD_VILLAGER, ## `amount` newcomers join the group (random name and traits).
	REMOVE_VILLAGER, ## `amount` villagers leave to live elsewhere: the newest who are at home.
	SET_WEATHER, ## Weather `key` begins, for `amount` ticks (0: a span drawn from its WeatherDef).
	CLEAR_WEATHER, ## The weather ends and the sky clears.
	DAMAGE_BUILDING, ## Weather breaks one completed building that carries tag `key` (any building
	## if empty), chosen with the simulation's rng. Journals `text` ({building} is its name) or a
	## plain line. Does nothing if there is none.
	REPAIR_BUILDING, ## Every damaged building is mended (or only the one whose id is `key`).
}

@export var kind: Kind = Kind.JOURNAL
@export var key: StringName = &""
@export var amount: int = 0
@export_multiline var text: String = ""
