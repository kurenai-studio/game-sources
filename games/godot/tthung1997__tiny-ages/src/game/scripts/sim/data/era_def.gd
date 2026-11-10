class_name EraDef
extends Resource
## An age of the settlement's long arc (Cave Age, Settled Age...). An age is a content and art
## pack plus a tech level; content is gated by era through conditions on `order`.

@export var id: StringName = &""
@export var display_name: String = ""
## Position in the timeline, starting at 0. Conditions compare against this.
@export_range(0, 20) var order: int = 0
@export_multiline var description: String = ""
## Journal line written when the settlement enters this age.
@export_multiline var intro_text: String = ""
## How many villagers the age's camp holds before buildings and answers add room (see
## Simulation.refresh_housing). Arrival decisions are only asked while there is room.
@export_range(1, 50) var housing: int = 6
@export_group("Representative profile")
## The most villagers new arrivals can bring the group to in this age, whatever the housing
## says. Villagers stand for the settlement's people rather than counting them, so the ceiling
## keeps the strip readable and cheap; it never removes anyone already in the group, and a
## ceiling that later falls only means nobody new arrives until there is room again.
@export_range(1, 50) var max_villagers: int = 50
## What each villager eats, brings in by foraging and hunting, and brings in by cutting wood,
## as a multiple of the base rates in `SimConfig`. A later age's villager stands for more
## people, so each eats and works for more; the balance, not the head count, is what an age
## tunes. Buildings' own output is not scaled.
@export_range(0.1, 5.0, 0.05) var food_need_scale: float = 1.0
@export_range(0.1, 5.0, 0.05) var food_yield_scale: float = 1.0
@export_range(0.1, 5.0, 0.05) var wood_yield_scale: float = 1.0
@export_group("Entry gate (never shown to the player)")
## Achievements the settlement must have earned before it can enter this age.
@export var required_achievements: Array[StringName] = []
## How long the settlement must have spent in the previous age, in ticks. Stops luck from
## rushing an age; time while the game is closed counts.
@export var min_ticks_in_previous_era: int = 0
## Optional event fired when the gate opens. Every one of its choices must ADVANCE_ERA to this
## age: it decides how the settlement turns, not whether. Empty means advance immediately.
@export var turn_event: StringName = &""
