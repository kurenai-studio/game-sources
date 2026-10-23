extends Area3D

## Forward speed (units/sec) — your only tuning knob for blade speed.
## Raise this until it feels right. Start around 15.
const SPEED := 15.0

const ARC_RATE := 2.0
const LATERAL_SCALE := 60.0
const SPIN_SPEED := 4.0

## Timed-abilities test - hit cap now grows with saw stacks instead of
## being a flat 6. Base/growth/cap are tuning knobs, same spirit as
## AbilityResource's cooldown/area fields, just kept local since this is
## saw-projectile-specific (axe/hammer don't count hits this way).
const MAX_HITS_BASE := 6
const MAX_HITS_PER_STACK := 1
const MAX_HITS_CAP := 16

var max_hits: int = MAX_HITS_BASE
var _lateral_velocity: float = 0.0
var _hits: int = 0
var _player: Node3D = null

func _ready() -> void:
	$SafetyTimer.start()
	_player = get_tree().get_first_node_in_group("Player")

## Timed-abilities test - stack_count grows max_hits, and the lateral kick
## now scales down at low player speed instead of always using the full
## LATERAL_SCALE value. fov_ref_speed is the same "what counts as full
## speed" reference player.gd already uses for its FOV lerp.
func setup(lateral_input: float, stack_count: int = 1) -> void:
	max_hits = min(MAX_HITS_CAP, MAX_HITS_BASE + (stack_count - 1) * MAX_HITS_PER_STACK)
	var speed_ratio: float = 1.0
	if _player and "fov_ref_speed" in _player and _player.fov_ref_speed > 0.0:
		speed_ratio = clamp(_player.player_current_speed / _player.fov_ref_speed, 0.0, 1.0)
	_lateral_velocity = -lateral_input * LATERAL_SCALE * speed_ratio

func _physics_process(delta: float) -> void:
	if not _player:
		return
	var spd: float = _player.player_current_speed
	var dir: Vector3 = _player.player_direction

	# Z: constant speed regardless of player — blade never slows in Vuln
	position.z -= SPEED * delta

	# X: unchanged from working version — stays locked with trees when turning
	_lateral_velocity = lerp(_lateral_velocity, 0.0, ARC_RATE * delta)
	position.x += (spd * dir.x + _lateral_velocity) * delta

	rotation.y += SPIN_SPEED * delta

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Tree"):
		_cut_tree(body)
	elif body.is_in_group("Boulder"):
		_destroy_blade()

func _cut_tree(tree: Node3D) -> void:
	tree.get_node("CollisionShape3D").set_deferred("disabled", true)
	EventBus.tree_cut.emit(tree.global_position)
	var tween := tree.create_tween().set_parallel(true)
	tween.tween_property(tree, "scale", Vector3.ONE * 0.001, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(tree.queue_free)
	_hits += 1
	# Timed-abilities test - report each cut live to the player's combo,
	# if one is running. Small per-cut extend, see combo_controller.gd's
	# report_saw_tree_cut() for why this is live instead of batched.
	if _player:
		var combo := _player.get_node_or_null("ComboController") as ComboController
		if combo:
			combo.report_saw_tree_cut()
	if _hits >= max_hits:
		_destroy_blade()

func _destroy_blade() -> void:
	if is_queued_for_deletion():
		return
	queue_free()

func _on_safety_timer_timeout() -> void:
	_destroy_blade()
