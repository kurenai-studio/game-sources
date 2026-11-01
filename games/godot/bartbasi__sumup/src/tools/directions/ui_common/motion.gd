extends RefCounted
## Shared motion helpers for the Phase 1 directions. Every duration, transition
## and ease comes from the direction's motion tokens, so no caller hardcodes a
## timing. Extra numbers (press_scale, from_offset, wipe, from_scale,
## from_alpha, wobble_degrees) are read from the same motion spec, so each
## direction moves in its own way through the same calls.
##
## Each helper claims a channel on the node (scale, dialog, alpha, count,
## pulse). A new call on the same channel stops the tween it replaces, so a
## release never fights a press that is still running.
##
## Phase 1 prototype code. Nothing under tools/ ships with the game.

const DirectionTokens: GDScript = preload("res://tools/directions/shared/direction_tokens.gd")
const MockState: GDScript = preload("res://tools/directions/shared/mock_state.gd")

## Smallest scale a wipe starts from. A scale of exactly 0 makes the control
## transform impossible to invert, which Godot reports as an error.
const MIN_SCALE: float = 0.001


## A Tween on node with trans and ease set from the named motion.
static func tween_for(node: Node, tokens: DirectionTokens, motion_name: String) -> Tween:
	var spec: Dictionary = tokens.motion_spec(motion_name)
	var tween: Tween = node.create_tween()
	tween.set_trans(int(spec.get("trans", Tween.TRANS_LINEAR)) as Tween.TransitionType)
	tween.set_ease(int(spec.get("ease", Tween.EASE_IN_OUT)) as Tween.EaseType)
	return tween


## Presses a control down to the direction's press_scale (no scaling when the
## direction has none, as in Slate), around its center.
static func press(control: Control, tokens: DirectionTokens) -> Tween:
	var spec: Dictionary = tokens.motion_spec("button_press")
	var to_scale: float = float(spec.get("press_scale", 1.0))
	control.pivot_offset = control.size * 0.5
	var tween: Tween = tween_for(control, tokens, "button_press")
	tween.tween_property(control, "scale", Vector2(to_scale, to_scale), tokens.duration("button_press"))
	_claim(control, "scale", tween)
	return tween


## Brings a pressed control back to full size with the release curve
## (Gumdrop springs back with a back ease).
static func release(control: Control, tokens: DirectionTokens) -> Tween:
	control.pivot_offset = control.size * 0.5
	var tween: Tween = tween_for(control, tokens, "button_release")
	tween.tween_property(control, "scale", Vector2.ONE, tokens.duration("button_release"))
	_claim(control, "scale", tween)
	return tween


## Brings a card or sheet in the direction's way: Gumdrop springs up from
## from_offset, Slate wipes in from the top, Nova fades and settles from
## from_scale. Call it with the control already at its final place and size.
static func dialog_in(control: Control, tokens: DirectionTokens) -> Tween:
	var spec: Dictionary = tokens.motion_spec("dialog_in")
	var seconds: float = tokens.duration("dialog_in")
	var tween: Tween = tween_for(control, tokens, "dialog_in")
	tween.set_parallel(true)
	var steps: int = 0
	if spec.has("from_offset"):
		var end_position: Vector2 = control.position
		control.position = end_position + Vector2(0.0, float(spec["from_offset"]))
		tween.tween_property(control, "position", end_position, seconds)
		steps += 1
	if spec.has("wipe"):
		# The wipe value is the share of the card height that is revealed,
		# from the top edge down. 1.0 reveals the whole card.
		control.pivot_offset = Vector2(control.size.x * 0.5, 0.0)
		control.scale = Vector2(1.0, maxf(1.0 - float(spec["wipe"]), MIN_SCALE))
		tween.tween_property(control, "scale", Vector2.ONE, seconds)
		steps += 1
	if spec.has("from_scale"):
		var from_scale: float = float(spec["from_scale"])
		control.pivot_offset = control.size * 0.5
		control.scale = Vector2(from_scale, from_scale)
		tween.tween_property(control, "scale", Vector2.ONE, seconds)
		steps += 1
	if spec.has("from_alpha"):
		control.modulate.a = float(spec["from_alpha"])
		tween.tween_property(control, "modulate:a", 1.0, seconds)
		steps += 1
	if steps == 0:
		tween.tween_interval(seconds)
	_claim(control, "dialog", tween)
	return tween


## Fades an item to to_alpha with the screen_fade curve.
static func fade(item: CanvasItem, tokens: DirectionTokens, to_alpha: float) -> Tween:
	var tween: Tween = tween_for(item, tokens, "screen_fade")
	tween.tween_property(item, "modulate:a", to_alpha, tokens.duration("screen_fade"))
	_claim(item, "alpha", tween)
	return tween


## Counts a label up with score_count, formatted with MockState.format_number().
static func count_up(label: Label, tokens: DirectionTokens, from_value: int, to_value: int) -> Tween:
	label.text = MockState.format_number(from_value)
	var tween: Tween = tween_for(label, tokens, "score_count")
	var show_value: Callable = func(value: float) -> void:
		label.text = MockState.format_number(roundi(value))
	tween.tween_method(show_value, float(from_value), float(to_value), tokens.duration("score_count"))
	_claim(label, "count", tween)
	return tween


## The target_pulse loop. Returns null when the duration is 0 (Slate).
## With wobble_degrees (Gumdrop) the item rocks around its center; with
## alpha_low (Nova) its alpha breathes between 1 and alpha_low. The item must
## be a Control or a Node2D for the wobble. Stop it with stop_pulse().
static func pulse(item: CanvasItem, tokens: DirectionTokens) -> Tween:
	var spec: Dictionary = tokens.motion_spec("target_pulse")
	var period: float = float(spec.get("duration", 0.0))
	if period <= 0.0:
		return null
	if not spec.has("wobble_degrees") and not spec.has("alpha_low"):
		push_error("%s: target_pulse needs wobble_degrees or alpha_low" % tokens.id)
		return null
	var tween: Tween = tween_for(item, tokens, "target_pulse")
	tween.set_loops()
	if spec.has("wobble_degrees"):
		var swing: float = deg_to_rad(float(spec["wobble_degrees"]))
		if item is Control:
			var control: Control = item as Control
			control.pivot_offset = control.size * 0.5
		# Quarter steps with ease out away from rest and ease in back to it
		# trace one smooth swing per period, with no stop as it passes rest.
		var quarter: float = period * 0.25
		tween.tween_property(item, "rotation", swing, quarter).set_ease(Tween.EASE_OUT)
		tween.tween_property(item, "rotation", 0.0, quarter).set_ease(Tween.EASE_IN)
		tween.tween_property(item, "rotation", -swing, quarter).set_ease(Tween.EASE_OUT)
		tween.tween_property(item, "rotation", 0.0, quarter).set_ease(Tween.EASE_IN)
	else:
		var low: float = float(spec["alpha_low"])
		tween.tween_property(item, "modulate:a", low, period * 0.5)
		tween.tween_property(item, "modulate:a", 1.0, period * 0.5)
	_claim(item, "pulse", tween)
	return tween


## Stops a pulse started with pulse() and puts the item back at rest.
static func stop_pulse(item: CanvasItem) -> void:
	_release_channel(item, "pulse")
	if item is Control:
		(item as Control).rotation = 0.0
	elif item is Node2D:
		(item as Node2D).rotation = 0.0
	item.modulate.a = 1.0


## Remembers tween as the one running on node's channel, stopping the one it
## replaces.
static func _claim(node: Node, channel: String, tween: Tween) -> void:
	_release_channel(node, channel)
	node.set_meta(_meta_key(channel), tween)


static func _release_channel(node: Node, channel: String) -> void:
	var key: StringName = _meta_key(channel)
	if not node.has_meta(key):
		return
	var old: Tween = node.get_meta(key) as Tween
	if old != null and old.is_valid():
		old.kill()
	node.remove_meta(key)


static func _meta_key(channel: String) -> StringName:
	return StringName("ui_motion_" + channel)
