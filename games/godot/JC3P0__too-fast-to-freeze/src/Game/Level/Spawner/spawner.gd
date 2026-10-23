extends Node3D

@onready var marker_a: Marker3D = $MarkerA
@onready var marker_b: Marker3D = $MarkerB

## Timed-abilities test - three-lane spawn zones (Notes/TEST-TIMED-ABILITIES.md).
## MarkerA/MarkerB stay the far right/left outer bounds - widening the lane is
## just moving those two further out in the editor, no code change needed.
## MarkerLeft/MarkerRight mark where the center lane ends. MarkerCenter is a
## reference point only, not read by the zone math below.
@onready var marker_center: Marker3D = $MarkerCenter
@onready var marker_left: Marker3D = $MarkerLeft
@onready var marker_right: Marker3D = $MarkerRight

@onready var obstacle_holder: Node3D = $ObstacleHolder

var spawn_distance_interval := 1.0
var last_spawn_distance := 0.0

var _factory := ObstacleFactory.new()

## Timed-abilities test - cached Player ref so spawn_obstacle() can read
## ability stacks each tick without a fresh group search every time. Falls
## back to null gracefully if the player isn't in the tree yet.
var _player: Node3D = null


func _ready() -> void:
	add_child(_factory)
	# Timed-abilities test - randomize() only needs to run once ever, Godot
	# auto-seeds its RNG at startup. Calling it before every single roll (as
	# this script used to) was pure overhead with zero benefit.
	randomize()


func _physics_process(_delta: float) -> void:
	check_spawn_obstacle()


func check_spawn_obstacle() -> void:
	var distance_traveled: float = GlobalState.total_distance
	if distance_traveled - last_spawn_distance >= spawn_distance_interval:
		spawn_obstacle()
		last_spawn_distance = distance_traveled
		spawn_distance_interval = randi_range(2, 6)


func spawn_obstacle() -> void:
	# Timed-abilities test - ability stacks drive tree/boulder scaling below
	# (Notes/TEST-TIMED-ABILITIES.md). Defaults match each ability's
	# start_stacks (1 each) so nothing breaks if the player isn't found yet.
	var hammer_stacks := 1
	var axe_saw_stacks := 2
	# Timed-abilities test - once an ability hits stats.max_stacks there's
	# nothing left for its pickup to do, so stop spawning it entirely
	# instead of just letting it roll uselessly.
	var axe_maxed := false
	var saw_maxed := false
	var hammer_maxed := false
	var player := _get_player()
	if player:
		if "hammer_ability" in player and player.hammer_ability:
			hammer_stacks = player.hammer_ability.current_stacks
			hammer_maxed = player.hammer_ability.is_maxed()
		if "axe_ability" in player and "saw_ability" in player and player.axe_ability and player.saw_ability:
			axe_saw_stacks = player.axe_ability.current_stacks + player.saw_ability.current_stacks
			axe_maxed = player.axe_ability.is_maxed()
			saw_maxed = player.saw_ability.is_maxed()

	# Tree count scales with combined axe+saw stacks. tree_bonus is 0 at the
	# start of a run (both abilities start at 1 stack = 2 combined), so the
	# 10-24 base range below is unchanged at run start and only grows from there.
	var tree_bonus := axe_saw_stacks - 2
	var number_of_trees       := randi_range(10 + tree_bonus, 24 + tree_bonus * 2)
	var number_of_snowpoofs   := randi_range(1, 3)
	var number_of_snow_barrier := randi_range(1, 100)
	var number_of_boulders    := randi_range(1, 100)
	# Timed-abilities test - was <= 30 (30% per tick), way too frequent for a
	# recovery pickup. Dropped to a similar rarity tier as the ability pickups.
	var number_of_coffees     := randi_range(1, 100)

	var tree_types: Array[ObstacleFactory.ObstacleType] = [
		ObstacleFactory.ObstacleType.TREE_S,
		ObstacleFactory.ObstacleType.TREE_M,
		ObstacleFactory.ObstacleType.TREE_L,
	]
	for i in number_of_trees:
		_spawn(tree_types.pick_random(), _rand_x_lane())

	var poof_types: Array[ObstacleFactory.ObstacleType] = [
		ObstacleFactory.ObstacleType.SNOW_POOF_S,
		ObstacleFactory.ObstacleType.SNOW_POOF_M,
		ObstacleFactory.ObstacleType.SNOW_POOF_L,
	]
	for i in number_of_snowpoofs:
		_spawn(poof_types.pick_random(), _rand_x_lane())

	if number_of_snow_barrier <= 30:
		_spawn(ObstacleFactory.ObstacleType.SNOW_BARRIER, _rand_x_lane())

	# Boulder chance and count both scale with hammer stacks. "Just enough
	# rocks to be easy to clear but a few still slip through as the cooldown
	# refreshes" - Josh, Notes/TEST-TIMED-ABILITIES.md. Base bumped from 30%
	# to 40% at 1 stack (combo system needs boulders showing up more often
	# to be reachable), still ramping up toward more frequent, multi-boulder
	# spawns by stack 10, same +4%/stack and 70% cap as before.
	var hammer_bonus := hammer_stacks - 1
	var boulder_chance: int = min(70, 40 + hammer_bonus * 4)
	if number_of_boulders <= boulder_chance:
		@warning_ignore("integer_division")
		var boulder_count := 1 + int(hammer_bonus / 3)
		for i in boulder_count:
			_spawn(ObstacleFactory.ObstacleType.BOULDER, _rand_x_lane())

	# Timed-abilities test - dropped from 20% to 10%. Breaking trees/boulders/
	# snow barriers now also gives heat, and combos pay out a bonus on top,
	# so coffee doesn't need to carry the whole recovery load by itself.
	if number_of_coffees <= 10:
		_spawn(ObstacleFactory.ObstacleType.COFFEE, _rand_x_pickup())

	# Timed-abilities test - axe/saw/hammer pickup odds. Axe and hammer now
	# sit even (both feed the combo system directly), saw stays the rarest
	# since it's the strongest ability and doesn't interact with combos at
	# all. Each roll is skipped once that ability is maxed (axe_maxed/
	# saw_maxed/hammer_maxed above).
	if not axe_maxed:
		var number_of_axes := randi_range(1, 100)
		if number_of_axes <= 20:
			_spawn(ObstacleFactory.ObstacleType.AXE, _rand_x_pickup())

	if not saw_maxed:
		var number_of_saws := randi_range(1, 100)
		if number_of_saws <= 8:
			_spawn(ObstacleFactory.ObstacleType.SAW_PICKUP, _rand_x_pickup())

	# Hammer pickup - flat-chance roll, same shape as axe/saw above. Boulder
	# scaling off hammer_stacks is handled above now (Notes/TEST-TIMED-ABILITIES.md).
	# Raised from 14 to 20 to match axe now that hammer is just as much a
	# combo necessity.
	if not hammer_maxed:
		var number_of_hammers := randi_range(1, 100)
		if number_of_hammers <= 20:
			_spawn(ObstacleFactory.ObstacleType.HAMMER, _rand_x_pickup())


## Timed-abilities test - finds and caches the Player node so
## spawn_obstacle() can read ability stack counts. Re-searches if the cached
## ref ever goes stale (shouldn't normally happen mid-run, but is_instance_valid
## keeps this safe either way).
func _get_player() -> Node3D:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("Player")
	return _player


## Returns a random x position within the full spawn lane defined by MarkerA
## and MarkerB. No longer called by spawn_obstacle() below (see _rand_x_lane()),
## kept around in case something wants the old full-width behavior again.
func _rand_x() -> float:
	return randf_range(marker_a.global_position.x, marker_b.global_position.x)


## Timed-abilities test - picks a zone weighted by its own width, not a flat
## 1/3 each, then rolls a random x within it. Center (MarkerLeft to
## MarkerRight) is much narrower than the two outer zones by design, so a
## flat 1/3 chance was packing center MORE densely than the edges, backwards
## from the goal. Weighting by width keeps density even across the whole
## span, so drifting off-center costs you more purely from the extra travel
## distance, not because it is secretly emptier out there.
func _rand_x_lane() -> float:
	var left_width: float = marker_left.global_position.x - marker_b.global_position.x
	var center_width: float = marker_right.global_position.x - marker_left.global_position.x
	var right_width: float = marker_a.global_position.x - marker_right.global_position.x
	var total_width: float = left_width + center_width + right_width
	var roll := randf_range(0.0, total_width)
	if roll < left_width:
		return randf_range(marker_b.global_position.x, marker_left.global_position.x)
	elif roll < left_width + center_width:
		return randf_range(marker_left.global_position.x, marker_right.global_position.x)
	else:
		return randf_range(marker_right.global_position.x, marker_a.global_position.x)


## Timed-abilities test - pickups (coffee/axe/saw/hammer) jitter around one
## of the three lane markers instead of rolling anywhere in a continuous
## range. Picks MarkerLeft, MarkerCenter, or MarkerRight at random, then
## offsets up to PICKUP_JITTER units either way from that marker's own x
## position. Keeps pickups reachable (never past the outer MarkerA/MarkerB
## obstacle bounds) while still giving them three distinct spots to land in.
const PICKUP_JITTER := 10.0

func _rand_x_pickup() -> float:
	var lanes: Array[Marker3D] = [marker_left, marker_center, marker_right]
	var lane: Marker3D = lanes.pick_random()
	return lane.global_position.x + randf_range(-PICKUP_JITTER, PICKUP_JITTER)


## Instantiates an obstacle via the factory and adds it to the obstacle holder.
func _spawn(type: ObstacleFactory.ObstacleType, x: float) -> void:
	var obs: Node3D = _factory.create(type, Vector3(x, 0.0, 0.0))
	obstacle_holder.add_child(obs)


func _on_despawner_body_entered(body: Node3D) -> void:
	if body.is_in_group("Obstacle"):
		body.queue_free()
	if body.is_in_group("Coffee"):
		body.queue_free()
	if body.is_in_group("Axe"):
		body.queue_free()
	if body.is_in_group("Saw"):
		body.queue_free()
	if body.is_in_group("Hammer"):
		body.queue_free()
	if body.is_in_group("SnowPuff"):
		body.queue_free()
