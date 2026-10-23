class_name AxeAbility
extends AbilityController

## Button-triggered axe swing (test/timed-abilities branch).
## Destroys any "Tree" group body currently inside the player's
## "AxeSwingArea" node (an Area3D sibling of this node, child of Player -
## see Notes/TEST-TIMED-ABILITIES.md for the node Josh adds in-editor).
## The area's size is kept in sync with get_area_scale() whenever a stack
## is added, so it's already correctly sized by the time the button fires.
##
## Heat reward per tree (freeze-timer seconds, see control.gd's
## add_freeze_time): 1/8 of what a coffee gives. Saw-cut trees give no
## heat - only the axe (and hammer, for boulders/snow barriers) do.

const _TREE_HEAT := 0.625
## Axe2's tuned base scale under both AxePivotLeft/AxePivotRight in
## Player.tscn (matches the axe pickup's own mesh scale). Visual mesh scale
## at any stack count is this times get_area_scale(), same growth factor
## as the invisible AxeSwingArea hitbox above.
const _AXE_MESH_BASE_SCALE := 0.2

func _ready() -> void:
	super._ready()
	_sync_area_scale()

func add_stack() -> void:
	super.add_stack()
	_sync_area_scale()

var _player_ref: CharacterBody3D = null
var _trees_cut_this_swing: int = 0

## Combo system - true if a combo was already running the instant this
## swing began. When true, each tree cut during the swing reports to
## ComboController immediately (see _cut_tree()) instead of waiting for
## the deferred end-of-swing report below, so a hit landing right as the
## combo timer is about to hit 0 doesn't lose its credit to the 0.5s
## report delay. When false, the deferred report still handles it - a
## brand new combo needs the whole swing's tally to check the >=3 trees
## start threshold, which isn't known until the swing window closes.
var _combo_active_at_swing_start: bool = false

func _perform_effect(player: CharacterBody3D, _area_scale: float) -> void:
	_player_ref = player
	_trees_cut_this_swing = 0
	var combo := player.get_node_or_null("ComboController") as ComboController
	_combo_active_at_swing_start = combo != null and combo.combo_active
	var area := player.get_node_or_null("AxeSwingArea") as Area3D
	if area == null:
		push_warning("AxeAbility: no 'AxeSwingArea' child on Player - add it in Player.tscn.")
		return
	for body in area.get_overlapping_bodies():
		if body.is_in_group("Tree"):
			_cut_tree(body)
	# Timed-abilities test - also catch trees the player skis into DURING the
	# swing animation, not just whatever was already in range at the instant
	# the button was pressed. See Notes/TEST-TIMED-ABILITIES.md.
	_watch_area_for_duration(area, "Tree", stats.swing_duration, _cut_tree)
	# Combo system - only need the deferred, whole-swing report when this
	# swing might be starting a fresh combo. If one's already active, every
	# tree cut this swing already reported itself live via _cut_tree().
	if not _combo_active_at_swing_start:
		get_tree().create_timer(stats.swing_duration).timeout.connect(_report_swing_to_combo)

func _report_swing_to_combo() -> void:
	if _player_ref == null:
		return
	# Combo system fix - if the player got hit partway through this swing,
	# on_hurt() already ended whatever combo was active. This report timer
	# runs independently of that hit, so without this check it could
	# resurrect a brand new combo right on top of the one that just ended.
	# Vuln lasts 1.5s vs. this 0.5s swing window, so checking state here
	# reliably catches "hit during this swing" and just drops the tally.
	if _player_ref.player_state_manager.current_state_name == "Vuln":
		_trees_cut_this_swing = 0
		return
	var combo := _player_ref.get_node_or_null("ComboController") as ComboController
	if combo:
		combo.report_tree_swing(_trees_cut_this_swing)
	_trees_cut_this_swing = 0

func _cut_tree(tree: Node3D) -> void:
	var shape := tree.get_node_or_null("CollisionShape3D")
	if shape:
		shape.set_deferred("disabled", true)
	EventBus.tree_cut.emit(tree.global_position)
	var tween := tree.create_tween().set_parallel(true)
	tween.tween_property(tree, "scale", Vector3.ONE * 0.001, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(tree.queue_free)
	_trees_cut_this_swing += 1
	if _player_ref and "control" in _player_ref and _player_ref.control:
		_player_ref.control.add_freeze_time(_TREE_HEAT)
	# Combo system - see _combo_active_at_swing_start above. An already
	# active combo gets extended the instant this tree falls, not at the
	# end of the swing.
	if _combo_active_at_swing_start:
		var combo := _player_ref.get_node_or_null("ComboController") as ComboController
		if combo:
			combo.report_tree_swing(1)

## New SwingPlayer-based axe swing (test/timed-abilities branch), replacing
## the inherited full-body-spin _play_swing() - see player.play_axe_swing().
func _play_swing(player: CharacterBody3D) -> void:
	player.play_axe_swing()

func _sync_area_scale() -> void:
	var player := get_parent()
	if player == null:
		return
	var area := player.get_node_or_null("AxeSwingArea") as Area3D
	if area:
		var scale_value := get_area_scale()
		area.scale = Vector3.ONE * scale_value
		# Timed-abilities test - AxeSwingArea scales uniformly on X/Y/Z as
		# stacks grow, which would also stretch RangeRing's small ground
		# offset upward. Counteract on the ring's own local Y so it stays
		# flush on the snow and keeps a constant ring thickness at any stack
		# count. See Notes/TEST-TIMED-ABILITIES.md.
		var ring := area.get_node_or_null("RangeRing") as Node3D
		if ring and scale_value != 0.0:
			ring.scale.y = 1.0 / scale_value
			ring.position.y = 0.05 / scale_value
	# Grow the visible axe mesh on both pivots by the same factor as the
	# hitbox above, so a maxed-out axe looks - and reaches - proportionally
	# bigger, same idea as SawAbility scaling its blade.
	var mesh_scale_value := get_area_scale()
	for pivot_name in ["AxePivotLeft", "AxePivotRight"]:
		var axe_mesh := player.get_node_or_null("ToolHolder/%s/Axe2" % pivot_name) as Node3D
		if axe_mesh:
			axe_mesh.scale = Vector3.ONE * (_AXE_MESH_BASE_SCALE * mesh_scale_value)
