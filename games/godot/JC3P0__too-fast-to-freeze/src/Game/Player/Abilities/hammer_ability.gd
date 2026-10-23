class_name HammerAbility
extends AbilityController

## Button-triggered hammer smash (test/timed-abilities branch).
## Destroys any "Boulder" or "SnowBarrier" group body currently inside the
## player's "HammerSwingArea" node (an Area3D sibling of this node, child
## of Player). Area size kept in sync with get_area_scale() whenever a
## stack is added.
##
## Heat rewards (freeze-timer seconds, see Game/Level/control.gd's
## add_freeze_time): boulders are 1/4 of what a coffee gives, snow barriers
## are 1/8 - same as tree breaks via the axe. Snow barriers never interact
## with the combo system (only boulders/trees do), they're heat-only.

const _BOULDER_HEAT := 1.25
const _SNOW_BARRIER_HEAT := 0.625
## Hammer2's tuned base scale under HammerPivot in Player.tscn (matches the
## hammer pickup's own mesh scale - see Notes/AXE-SWING-MIRROR-MATH.md for
## why the position offset is what it is). Visual mesh scale at any stack
## count is this times get_area_scale(), same growth factor as the
## invisible HammerSwingArea hitbox below.
const _HAMMER_MESH_BASE_SCALE := 0.165

func _ready() -> void:
	super._ready()
	_sync_area_scale()

func add_stack() -> void:
	super.add_stack()
	_sync_area_scale()

var _player_ref: CharacterBody3D = null
var _boulders_smashed_this_swing: int = 0

## Combo system - true if a combo was already running the instant this
## swing began. See the matching flag/comment in axe_ability.gd - same
## reasoning: an already-active combo gets extended live, per boulder, in
## _smash_boulder() below, instead of waiting on the deferred end-of-swing
## report. That deferred report still runs when this is false, since
## starting a fresh combo needs the swing's full tally.
var _combo_active_at_swing_start: bool = false

func _perform_effect(player: CharacterBody3D, _area_scale: float) -> void:
	_player_ref = player
	_boulders_smashed_this_swing = 0
	var combo := player.get_node_or_null("ComboController") as ComboController
	_combo_active_at_swing_start = combo != null and combo.combo_active
	var area := player.get_node_or_null("HammerSwingArea") as Area3D
	if area == null:
		push_warning("HammerAbility: no 'HammerSwingArea' child on Player - add it in Player.tscn.")
		return
	for body in area.get_overlapping_bodies():
		if body.is_in_group("Boulder"):
			_smash_boulder(body)
		elif body.is_in_group("SnowBarrier"):
			_break_snow_barrier(body)
	# Timed-abilities test - also catch boulders/snow barriers the player
	# skis into DURING the swing animation, not just whatever was already
	# in range at the instant the button was pressed. See
	# Notes/TEST-TIMED-ABILITIES.md.
	_watch_area_for_duration(area, "Boulder", stats.swing_duration, _smash_boulder)
	_watch_area_for_duration(area, "SnowBarrier", stats.swing_duration, _break_snow_barrier)
	# Combo system - snow barriers deliberately excluded, boulders only.
	# Only need the deferred, whole-swing report when this swing might be
	# starting a fresh combo - if one's already active, every boulder
	# smashed this swing already reported itself live via _smash_boulder().
	if not _combo_active_at_swing_start:
		get_tree().create_timer(stats.swing_duration).timeout.connect(_report_swing_to_combo)

func _report_swing_to_combo() -> void:
	if _player_ref == null:
		return
	# Combo system fix - see the matching comment in axe_ability.gd. Same
	# fix here: don't let a delayed swing report resurrect a combo right
	# after a hit already ended it.
	if _player_ref.player_state_manager.current_state_name == "Vuln":
		_boulders_smashed_this_swing = 0
		return
	var combo := _player_ref.get_node_or_null("ComboController") as ComboController
	if combo:
		combo.report_boulder_swing(_boulders_smashed_this_swing)
	_boulders_smashed_this_swing = 0

func _smash_boulder(boulder: Node3D) -> void:
	var shape := boulder.get_node_or_null("CollisionShape3D")
	if shape:
		shape.set_deferred("disabled", true)
	var tween := boulder.create_tween().set_parallel(true)
	tween.tween_property(boulder, "scale", Vector3.ONE * 0.001, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(boulder.queue_free)
	_boulders_smashed_this_swing += 1
	_give_heat(_BOULDER_HEAT)
	# Combo system - see _combo_active_at_swing_start above. An already
	# active combo gets extended the instant this boulder breaks, not at
	# the end of the swing.
	if _combo_active_at_swing_start:
		var combo := _player_ref.get_node_or_null("ComboController") as ComboController
		if combo:
			combo.report_boulder_swing(1)

func _break_snow_barrier(barrier: Node3D) -> void:
	var shape := barrier.get_node_or_null("CollisionShape3D")
	if shape:
		shape.set_deferred("disabled", true)
	var tween := barrier.create_tween().set_parallel(true)
	tween.tween_property(barrier, "scale", Vector3.ONE * 0.001, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(barrier.queue_free)
	_give_heat(_SNOW_BARRIER_HEAT)

func _give_heat(amount: float) -> void:
	if _player_ref and "control" in _player_ref and _player_ref.control:
		_player_ref.control.add_freeze_time(amount)

## New AnimationPlayer-based hammer swing (test/timed-abilities branch),
## replacing the inherited full-body-spin _play_swing() - see
## player.play_hammer_swing().
func _play_swing(player: CharacterBody3D) -> void:
	player.play_hammer_swing()

func _sync_area_scale() -> void:
	var player := get_parent()
	if player == null:
		return
	var area := player.get_node_or_null("HammerSwingArea") as Area3D
	if area:
		var scale_value := get_area_scale()
		area.scale = Vector3.ONE * scale_value
		# Timed-abilities test - HammerSwingArea scales uniformly on X/Y/Z as
		# stacks grow, which would also stretch RangeRing's small ground
		# offset upward. Counteract on the ring's own local Y so it stays
		# flush on the snow and keeps a constant ring thickness at any stack
		# count. See Notes/TEST-TIMED-ABILITIES.md.
		var ring := area.get_node_or_null("RangeRing") as Node3D
		if ring and scale_value != 0.0:
			ring.scale.y = 1.0 / scale_value
			ring.position.y = 0.05 / scale_value
	# Grow the visible hammer mesh by the same factor as the hitbox above,
	# so a maxed-out hammer looks - and reaches - proportionally bigger,
	# same idea as SawAbility scaling its blade.
	var hammer_mesh := player.get_node_or_null("ToolHolder/HammerPivot/Hammer2") as Node3D
	if hammer_mesh:
		hammer_mesh.scale = Vector3.ONE * (_HAMMER_MESH_BASE_SCALE * get_area_scale())
