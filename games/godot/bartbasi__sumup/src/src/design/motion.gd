class_name Motion extends RefCounted
## Shared motion helpers (docs/ARCHITECTURE.md section 7). Every duration,
## transition and ease comes from the skin's motion tokens, and so do the
## extras (press_scale, from_offset, from_alpha, from_scale, wobble_degrees,
## alpha_low), so each skin moves in its own way through the same calls and
## nobody hardcodes a timing.
##
## Each helper claims a channel on the node it animates (scale, dialog, alpha,
## count, pulse). A new call on the same channel stops the tween it replaces,
## so a release never fights a press that is still running.
##
## Tweens are bound to the node they animate, so they stop when it is freed,
## and they only run while it is inside the scene tree.

## Smallest scale a control may shrink to. A scale of exactly 0 makes its
## transform impossible to invert, which Godot reports as an error.
const MIN_SCALE: float = 0.001

const _CHANNEL_SCALE: String = "scale"
const _CHANNEL_DIALOG: String = "dialog"
const _CHANNEL_ALPHA: String = "alpha"
const _CHANNEL_COUNT: String = "count"
const _CHANNEL_PULSE: String = "pulse"
## Where dialog_in and dialog_out keep a control's resting place while one of
## them runs, so a dialog that turns back mid way returns to the right spot.
const _REST_POSITION: StringName = &"ui_motion_rest_position"

## Tests set this to false. The test runner works before the scene tree
## starts, where a tween bound to a node never steps, so tests need unbound
## tweens to step them by hand. The game never changes it.
static var bind_tweens: bool = true


## A Tween on node with the transition and ease of the named motion.
static func tween_for(node: Node, skin: SkinData, motion_name: StringName) -> Tween:
	var spec: Dictionary = skin.motion_spec(motion_name)
	var tween: Tween = node.create_tween() if bind_tweens else (Engine.get_main_loop() as SceneTree).create_tween()
	tween.set_trans(int(spec.get("trans", Tween.TRANS_LINEAR)) as Tween.TransitionType)
	tween.set_ease(int(spec.get("ease", Tween.EASE_IN_OUT)) as Tween.EaseType)
	return tween


## Presses a control down around its center to button_press's press_scale.
## A skin with no press_scale (Slate) does not scale; the tween still runs for
## button_press's duration.
static func press(control: Control, skin: SkinData) -> Tween:
	var spec: Dictionary = skin.motion_spec(&"button_press")
	var to_scale: float = float(spec.get("press_scale", 1.0))
	control.pivot_offset = control.size * 0.5
	var tween: Tween = tween_for(control, skin, &"button_press")
	tween.tween_property(control, "scale", Vector2(to_scale, to_scale), skin.duration(&"button_press"))
	_claim(control, _CHANNEL_SCALE, tween)
	return tween


## Brings a pressed control back to full size with button_release (Gumdrop
## springs back with a back ease).
static func release(control: Control, skin: SkinData) -> Tween:
	control.pivot_offset = control.size * 0.5
	var tween: Tween = tween_for(control, skin, &"button_release")
	tween.tween_property(control, "scale", Vector2.ONE, skin.duration(&"button_release"))
	_claim(control, _CHANNEL_SCALE, tween)
	return tween


## Brings a sheet or panel in with dialog_in. Call it with the control already
## at its resting place and size. Gumdrop rises from_offset px from below;
## Slate slides up from_offset px and fades in from from_alpha; Nova fades in
## from from_alpha and settles from from_scale.
static func dialog_in(control: Control, skin: SkinData) -> Tween:
	var rest: Vector2 = _rest_position(control)
	var spec: Dictionary = skin.motion_spec(&"dialog_in")
	var seconds: float = skin.duration(&"dialog_in")
	var tween: Tween = tween_for(control, skin, &"dialog_in")
	tween.set_parallel(true)
	control.position = rest
	control.scale = Vector2.ONE
	control.modulate.a = 1.0
	if spec.has("from_offset"):
		control.position = rest + Vector2(0.0, float(spec["from_offset"]))
		tween.tween_property(control, "position", rest, seconds)
	if spec.has("from_scale"):
		var from_scale: float = maxf(float(spec["from_scale"]), MIN_SCALE)
		control.pivot_offset = control.size * 0.5
		control.scale = Vector2(from_scale, from_scale)
		tween.tween_property(control, "scale", Vector2.ONE, seconds)
	if spec.has("from_alpha"):
		control.modulate.a = float(spec["from_alpha"])
	# The alpha always runs, so the tween has a step even for a skin with no
	# extras, and a dialog brought back after dialog_out shows again.
	tween.tween_property(control, "modulate:a", 1.0, seconds)
	tween.chain().tween_callback(_forget_rest.bind(control))
	_claim(control, _CHANNEL_DIALOG, tween)
	return tween


## Takes a sheet or panel out with dialog_out's duration and curve: the way
## dialog_in brought it, backwards (back down from_offset px, back to
## from_scale), and fading out, since an exit must end unseen. When it ends,
## the control is back at its resting place and scale with alpha 0, so the
## caller hides or frees it, or brings it back with dialog_in.
static func dialog_out(control: Control, skin: SkinData) -> Tween:
	var rest: Vector2 = _rest_position(control)
	var spec: Dictionary = skin.motion_spec(&"dialog_in")
	var seconds: float = skin.duration(&"dialog_out")
	var tween: Tween = tween_for(control, skin, &"dialog_out")
	tween.set_parallel(true)
	if spec.has("from_offset"):
		tween.tween_property(control, "position", rest + Vector2(0.0, float(spec["from_offset"])), seconds)
	if spec.has("from_scale"):
		var to_scale: float = maxf(float(spec["from_scale"]), MIN_SCALE)
		control.pivot_offset = control.size * 0.5
		tween.tween_property(control, "scale", Vector2(to_scale, to_scale), seconds)
	tween.tween_property(control, "modulate:a", 0.0, seconds)
	tween.chain().tween_callback(_settle_out.bind(control, rest))
	_claim(control, _CHANNEL_DIALOG, tween)
	return tween


## Fades an item to to_alpha with screen_fade.
static func fade(item: CanvasItem, skin: SkinData, to_alpha: float) -> Tween:
	var tween: Tween = tween_for(item, skin, &"screen_fade")
	tween.tween_property(item, "modulate:a", to_alpha, skin.duration(&"screen_fade"))
	_claim(item, _CHANNEL_ALPHA, tween)
	return tween


## Counts a label from from_value to to_value with score_count
## (DESIGN_SYSTEM.md 2.6). It only changes the text: the HUD sizes the score
## for its final value first. Both texts come from NumberFormat.score and are
## split into their shown digits and their suffix (the trailing letters, maybe
## none). With the same suffix, the shown digits count on score_count (at most
## 10 digits, so a plain int), each step with commas and the suffix unchanged:
## "9,221,253,119B" rolls to "9,223,504,919B". When the suffix changes the
## final text shows at once, since a roll from "9,999,999,999" to
## "10,000,000K" would read as the score falling. Either way it ends exactly
## on NumberFormat.score(to_value).
static func count_up(label: Label, skin: SkinData, from_value: BigNum, to_value: BigNum) -> Tween:
	var final_text: String = NumberFormat.score(to_value)
	var from_parts: PackedStringArray = split_score(NumberFormat.score(from_value))
	var to_parts: PackedStringArray = split_score(final_text)
	var tween: Tween = tween_for(label, skin, &"score_count")
	if from_parts[1] == to_parts[1]:
		label.text = NumberFormat.score(from_value)
		var suffix: String = to_parts[1]
		tween.tween_method(_show_count.bind(suffix, label), float(from_parts[0].to_int()), float(to_parts[0].to_int()), skin.duration(&"score_count"))
	else:
		label.text = final_text
	# Land exactly on the final text, whatever the float steps did.
	tween.tween_callback(_show_text.bind(final_text, label))
	_claim(label, _CHANNEL_COUNT, tween)
	return tween


## A score text from NumberFormat.score split into its shown digits, commas
## removed, and its suffix (the trailing letters, "" for none):
## "9,221,253,119B" gives "9221253119" and "B".
static func split_score(text: String) -> PackedStringArray:
	var cut: int = text.length()
	while cut > 0:
		var code: int = text.unicode_at(cut - 1)
		if code >= 48 and code <= 57:
			break
		cut -= 1
	return PackedStringArray([text.substr(0, cut).replace(",", ""), text.substr(cut)])


## value with a comma every three digits: 9221253119 gives "9,221,253,119".
## The one place the count formats its int (a negative value is never shown).
static func grouped(value: int) -> String:
	var digits: String = str(maxi(value, 0))
	var out: String = ""
	var count: int = 0
	for position: int in range(digits.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			out = "," + out
		out = digits[position] + out
		count += 1
	return out


## The target_pulse loop, or null when the skin holds still (duration 0,
## Slate). With wobble_degrees (Gumdrop) the item rocks around its center;
## with alpha_low (Nova) its alpha breathes between 1 and alpha_low. Stop it
## with stop_pulse().
static func pulse(item: CanvasItem, skin: SkinData) -> Tween:
	var spec: Dictionary = skin.motion_spec(&"target_pulse")
	var period: float = skin.duration(&"target_pulse")
	if period <= 0.0:
		stop_pulse(item)
		return null
	if not spec.has("wobble_degrees") and not spec.has("alpha_low"):
		push_error("%s: target_pulse needs wobble_degrees or alpha_low" % skin.id)
		return null
	var tween: Tween = tween_for(item, skin, &"target_pulse")
	tween.set_loops()
	if spec.has("wobble_degrees"):
		var swing: float = deg_to_rad(float(spec["wobble_degrees"]))
		if item is Control:
			var control: Control = item as Control
			control.pivot_offset = control.size * 0.5
		# Quarter steps, eased out away from rest and in back to it, trace one
		# smooth swing per period with no stop as the item passes rest.
		var quarter: float = period * 0.25
		tween.tween_property(item, "rotation", swing, quarter).set_ease(Tween.EASE_OUT)
		tween.tween_property(item, "rotation", 0.0, quarter).set_ease(Tween.EASE_IN)
		tween.tween_property(item, "rotation", -swing, quarter).set_ease(Tween.EASE_OUT)
		tween.tween_property(item, "rotation", 0.0, quarter).set_ease(Tween.EASE_IN)
	else:
		var low: float = float(spec["alpha_low"])
		tween.tween_property(item, "modulate:a", low, period * 0.5)
		tween.tween_property(item, "modulate:a", 1.0, period * 0.5)
	_claim(item, _CHANNEL_PULSE, tween)
	return tween


## Stops a pulse started with pulse() and puts the item back at rest: no
## rotation, full alpha.
static func stop_pulse(item: CanvasItem) -> void:
	_release_channel(item, _CHANNEL_PULSE)
	if item is Control:
		(item as Control).rotation = 0.0
	elif item is Node2D:
		(item as Node2D).rotation = 0.0
	item.modulate.a = 1.0


static func _show_count(value: float, suffix: String, label: Label) -> void:
	_show_text(grouped(roundi(value)) + suffix, label)


static func _show_text(text: String, label: Label) -> void:
	if label.text != text:
		label.text = text


## The control's resting place: the one remembered while a dialog motion runs,
## else where it is now.
static func _rest_position(control: Control) -> Vector2:
	var running: bool = _channel_running(control, _CHANNEL_DIALOG)
	if running and control.has_meta(_REST_POSITION):
		return control.get_meta(_REST_POSITION) as Vector2
	control.set_meta(_REST_POSITION, control.position)
	return control.position


static func _forget_rest(control: Control) -> void:
	if control.has_meta(_REST_POSITION):
		control.remove_meta(_REST_POSITION)


static func _settle_out(control: Control, rest: Vector2) -> void:
	control.position = rest
	control.scale = Vector2.ONE
	control.modulate.a = 0.0
	_forget_rest(control)


## Remembers tween as the one running on node's channel, stopping the one it
## replaces.
static func _claim(node: Node, channel: String, tween: Tween) -> void:
	_release_channel(node, channel)
	node.set_meta(_meta_key(channel), tween)


static func _channel_running(node: Node, channel: String) -> bool:
	var key: StringName = _meta_key(channel)
	if not node.has_meta(key):
		return false
	var tween: Tween = node.get_meta(key) as Tween
	return tween != null and tween.is_valid() and tween.is_running()


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
