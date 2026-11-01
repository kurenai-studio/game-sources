# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends RefCounted
## S8's old save (docs/ARCHITECTURE.md 14.7): game_level.json, saved mid-wave on r4_l4 by
## the build before the expansion (a gate breaker breaking, slowed Puffballs on their way),
## the stat files of that build, and played_on.json, what that build did when it played the
## save on. Every later build must load the save and play it on the same.

const DIR: String = "res://tests/sim/fixtures/before_a12/"
const LIMIT: int = 40000
const EVERY: int = 200                                 # ticks per checkpoint


static func save_data() -> Variant:
	return JSON.parse_string(FileAccess.get_file_as_string(DIR + "game_level.json"))


## The catalog of the build that made the save, so later tuning of data/stats/ never
## changes how the save plays on.
static func old_catalog() -> Catalog:
	var files: Array = []
	for name: String in ["towers.json", "enemies.json", "rules.json"]:
		files.append(JSON.parse_string(FileAccess.get_file_as_string(DIR + "stats/" + name)))
	return Catalog.from_data(files[0], files[1], files[2])


## Plays a battle on to its end with no command but starting each wave. Returns a
## checkpoint every EVERY ticks and at the end: the tick, a hash of the state at every
## tick and a hash of the events since the last checkpoint. The state is the part of the
## battle that S8 and later steps keep the same for old content, so new save keys do
## not change it.
static func play_on(b: Battle) -> Dictionary:
	var checkpoints: Array = []
	var states: PackedStringArray = PackedStringArray()
	var events: PackedStringArray = PackedStringArray()
	while (b.phase == Battle.Phase.BUILD or b.phase == Battle.Phase.WAVE) and b.tick < LIMIT:
		if b.phase == Battle.Phase.BUILD:
			b.start_next_wave()
		b.step()
		for event: Dictionary in b.take_events():
			events.append(var_to_str(event))
		states.append(JSON.stringify(digest(b)))
		if b.tick % EVERY == 0:
			checkpoints.append(_checkpoint(b.tick, states, events))
			states = PackedStringArray()
			events = PackedStringArray()
	checkpoints.append(_checkpoint(b.tick, states, events))
	return {"checkpoints": checkpoints, "phase": int(b.phase), "tick": b.tick, "result": b.result()}


static func digest(b: Battle) -> Array:
	var creatures: Array = []
	for e: EnemyState in b.enemies:
		creatures.append([e.id, String(e.type), e.wave, e.health, e.max_health, e.pos.x, e.pos.y, e.prev_pos.x, e.prev_pos.y,
			e.from_cell.x, e.from_cell.y, e.to_cell.x, e.to_cell.y, e.progress, e.flown, e.slow_pct, e.slow_ticks,
			e.bubble, e.bubble_ticks, e.breaking, e.heal_at, e.summon_at, e.ups, e.released])
	var towers: Array = []
	for t: TowerState in b.towers:
		towers.append([t.cell.x, t.cell.y, String(t.type), t.tier, t.spec, t.reload])
	var gates: Array = []
	for g: GateState in b.gates:
		gates.append([g.cell.x, g.cell.y, g.fixed, g.broken])
	return [b.tick, int(b.phase), b.gold, b.lives, b.waves_started, b.running.duplicate(), creatures, towers, gates]


static func _checkpoint(tick: int, states: PackedStringArray, events: PackedStringArray) -> Dictionary:
	return {"tick": tick, "state": "\n".join(states).sha256_text(), "events": "\n".join(events).sha256_text()}
