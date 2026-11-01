extends "res://tests/base_test.gd"
## Motion reads every duration, transition, ease and extra from the skin's
## motion tokens (docs/ARCHITECTURE.md section 7, DESIGN_SYSTEM.md 4.6, 5.6,
## 6.6). Each test steps the tween by hand: halfway it must sit where the
## skin's curve puts it, just before the skin's duration it must still be
## running, and just after it must be done and at its target.

## How far either side of a duration the tests look, in seconds.
const EPSILON: float = 0.001

var _made: Array[Node] = []


func before_each() -> void:
	# The runner works before the scene tree starts, where bound tweens never
	# step; Motion makes unbound tweens while this is off.
	Motion.bind_tweens = false


func after_each() -> void:
	Motion.bind_tweens = true
	# Unbound tweens outlive the nodes they animated; stop them all.
	for tween: Tween in (Engine.get_main_loop() as SceneTree).get_processed_tweens():
		tween.kill()
	for node: Node in _made:
		if is_instance_valid(node):
			node.free()
	_made.clear()


func _control() -> Control:
	var control: Control = Control.new()
	control.size = Vector2(200.0, 100.0)
	_made.append(control)
	return control


## Checks a float the tween drives: halfway on the skin's curve, still
## running just before seconds, done and at to just after.
func _check_float(tween: Tween, read: Callable, from: float, to: float, skin: SkinData, motion_name: StringName, seconds: float, label: String) -> void:
	var spec: Dictionary = skin.motion_spec(motion_name)
	var trans: Tween.TransitionType = int(spec["trans"]) as Tween.TransitionType
	var ease_type: Tween.EaseType = int(spec["ease"]) as Tween.EaseType
	tween.custom_step(seconds * 0.5)
	var expected: float = float(Tween.interpolate_value(from, to - from, seconds * 0.5, seconds, trans, ease_type))
	assert_near(float(read.call()), expected, 0.001, "%s halfway on the skin's curve" % label)
	tween.custom_step(seconds * 0.5 - EPSILON)
	assert_true(tween.is_running(), "%s still running just before %s s" % [label, seconds])
	tween.custom_step(EPSILON * 2.0)
	assert_false(tween.is_valid() and tween.is_running(), "%s done just after %s s" % [label, seconds])
	assert_near(float(read.call()), to, 0.001, "%s ends at its target" % label)


func test_press_uses_button_press() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var control: Control = _control()
		var to: float = float(skin.motion_spec(&"button_press").get("press_scale", 1.0))
		var tween: Tween = Motion.press(control, skin)
		_check_float(tween, func() -> float: return control.scale.x, 1.0, to, skin, &"button_press", skin.duration(&"button_press"), "%s press" % skin_id)
		assert_eq(control.pivot_offset, control.size * 0.5, "%s presses round its center" % skin_id)
	assert_eq(SkinCatalog.get_skin(&"slate").motion_spec(&"button_press").has("press_scale"), false, "Slate never scales")


func test_release_uses_button_release() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var control: Control = _control()
		control.scale = Vector2(0.5, 0.5)
		var tween: Tween = Motion.release(control, skin)
		_check_float(tween, func() -> float: return control.scale.x, 0.5, 1.0, skin, &"button_release", skin.duration(&"button_release"), "%s release" % skin_id)


func test_dialog_in_uses_dialog_in() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var spec: Dictionary = skin.motion_spec(&"dialog_in")
		var seconds: float = skin.duration(&"dialog_in")
		var control: Control = _control()
		control.position = Vector2(10.0, 500.0)
		var tween: Tween = Motion.dialog_in(control, skin)
		if spec.has("from_offset"):
			assert_near(control.position.y, 500.0 + float(spec["from_offset"]), 0.001, "%s starts from_offset below" % skin_id)
			_check_float(tween, func() -> float: return control.position.y, 500.0 + float(spec["from_offset"]), 500.0, skin, &"dialog_in", seconds, "%s dialog_in position" % skin_id)
		elif spec.has("from_scale"):
			assert_near(control.scale.x, float(spec["from_scale"]), 0.001, "%s starts at from_scale" % skin_id)
			_check_float(tween, func() -> float: return control.scale.x, float(spec["from_scale"]), 1.0, skin, &"dialog_in", seconds, "%s dialog_in scale" % skin_id)
		assert_eq(control.position, Vector2(10.0, 500.0), "%s ends at rest" % skin_id)
		assert_near(control.modulate.a, 1.0, 0.001, "%s ends opaque" % skin_id)
	# Slate and Nova also fade in from from_alpha.
	for skin_id: StringName in [&"slate", &"nova"]:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var control: Control = _control()
		var tween: Tween = Motion.dialog_in(control, skin)
		var from_alpha: float = float(skin.motion_spec(&"dialog_in")["from_alpha"])
		assert_near(control.modulate.a, from_alpha, 0.001, "%s starts at from_alpha" % skin_id)
		_check_float(tween, func() -> float: return control.modulate.a, from_alpha, 1.0, skin, &"dialog_in", skin.duration(&"dialog_in"), "%s dialog_in alpha" % skin_id)


func test_dialog_out_uses_dialog_out() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var control: Control = _control()
		control.position = Vector2(10.0, 500.0)
		var tween: Tween = Motion.dialog_out(control, skin)
		_check_float(tween, func() -> float: return control.modulate.a, 1.0, 0.0, skin, &"dialog_out", skin.duration(&"dialog_out"), "%s dialog_out alpha" % skin_id)
		assert_eq(control.position, Vector2(10.0, 500.0), "%s is back at rest when out" % skin_id)
		assert_eq(control.scale, Vector2.ONE, "%s is back at full scale when out" % skin_id)


func test_dialog_turning_back_returns_to_rest() -> void:
	var skin: SkinData = SkinCatalog.get_skin(&"gumdrop")
	var control: Control = _control()
	control.position = Vector2(10.0, 500.0)
	var going: Tween = Motion.dialog_in(control, skin)
	going.custom_step(skin.duration(&"dialog_in") * 0.3)
	var leaving: Tween = Motion.dialog_out(control, skin)
	assert_false(going.is_valid(), "a new dialog motion stops the old one")
	leaving.custom_step(skin.duration(&"dialog_out") + EPSILON)
	assert_eq(control.position, Vector2(10.0, 500.0), "the resting place survives the turn")


func test_fade_uses_screen_fade() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var control: Control = _control()
		var tween: Tween = Motion.fade(control, skin, 0.25)
		_check_float(tween, func() -> float: return control.modulate.a, 1.0, 0.25, skin, &"screen_fade", skin.duration(&"screen_fade"), "%s fade" % skin_id)


func test_count_up_uses_score_count() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var label: Label = Label.new()
		_made.append(label)
		var tween: Tween = Motion.count_up(label, skin, BigNum.from_int(1000), BigNum.from_int(41286))
		assert_eq(label.text, "1,000", "%s starts at from_value" % skin_id)
		var seconds: float = skin.duration(&"score_count")
		var spec: Dictionary = skin.motion_spec(&"score_count")
		tween.custom_step(seconds * 0.5)
		var halfway: float = float(Tween.interpolate_value(1000.0, 40286.0, seconds * 0.5, seconds, int(spec["trans"]) as Tween.TransitionType, int(spec["ease"]) as Tween.EaseType))
		assert_eq(label.text, NumberFormat.score(BigNum.from_int(roundi(halfway))), "%s halfway on the skin's curve" % skin_id)
		tween.custom_step(seconds * 0.5 - EPSILON)
		assert_true(tween.is_running(), "%s still counting just before %s s" % [skin_id, seconds])
		tween.custom_step(EPSILON * 2.0)
		assert_eq(label.text, "41,286", "%s ends on the final value" % skin_id)


func test_count_up_handles_scores_past_float_precision_steps() -> void:
	var skin: SkinData = SkinCatalog.get_skin(&"gumdrop")
	var label: Label = Label.new()
	_made.append(label)
	var tween: Tween = Motion.count_up(label, skin, BigNum.from_int(9999999000), BigNum.from_int(9999999999))
	tween.custom_step(skin.duration(&"score_count") + EPSILON)
	assert_eq(label.text, "9,999,999,999", "the longest full score lands exactly")


## DESIGN_SYSTEM.md 2.6: with the same suffix the shown digits roll and the
## suffix stays; Bart's score rolls on to a larger B score.
func test_count_up_with_the_same_suffix_rolls_the_digits() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var label: Label = Label.new()
		_made.append(label)
		var from_value: BigNum = BigNum.parse("9221253119629040934", 19)
		var to_value: BigNum = BigNum.parse("9223504919000000000", 19)
		var tween: Tween = Motion.count_up(label, skin, from_value, to_value)
		assert_eq(label.text, "9,221,253,119B", "%s starts on Bart's score" % skin_id)
		var seconds: float = skin.duration(&"score_count")
		var spec: Dictionary = skin.motion_spec(&"score_count")
		tween.custom_step(seconds * 0.5)
		var halfway: float = float(Tween.interpolate_value(9221253119.0, 9223504919.0 - 9221253119.0, seconds * 0.5, seconds, int(spec["trans"]) as Tween.TransitionType, int(spec["ease"]) as Tween.EaseType))
		assert_eq(label.text, Motion.grouped(roundi(halfway)) + "B", "%s halfway the digits roll and keep the B" % skin_id)
		assert_ne(label.text, "9,221,253,119B", "%s it moved" % skin_id)
		tween.custom_step(seconds * 0.5 + EPSILON)
		assert_false(tween.is_running(), "%s done" % skin_id)
		assert_eq(label.text, "9,223,504,919B", "%s ends exactly" % skin_id)
		assert_eq(label.text, NumberFormat.score(to_value), "%s ends on NumberFormat.score" % skin_id)


## When the suffix changes the new text shows at once, with no count.
func test_count_up_across_a_suffix_change_jumps() -> void:
	var cases: Array[PackedStringArray] = [
		PackedStringArray(["9999999999", "10000000000", "10,000,000K"]),
		PackedStringArray(["9221253119629040934", "9223372036854775808", "9,223,372,036B"]),
		PackedStringArray(["9999999999999999999", "10000000000000000000", "10,000,000T"]),
		PackedStringArray(["9999999999999999999999", "10000000000000000000000", "10,000,000Q"]),
	]
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		for case: PackedStringArray in cases:
			var label: Label = Label.new()
			_made.append(label)
			var from_value: BigNum = BigNum.parse(case[0], case[0].length())
			var to_value: BigNum = BigNum.parse(case[1], case[1].length())
			var tween: Tween = Motion.count_up(label, skin, from_value, to_value)
			var final_text: String = NumberFormat.score(to_value)
			if Motion.split_score(NumberFormat.score(from_value))[1] == Motion.split_score(final_text)[1]:
				# Same suffix (B to B): that one rolls; covered above.
				tween.custom_step(skin.duration(&"score_count") + EPSILON)
				assert_eq(label.text, case[2], "%s %s ends exactly" % [skin_id, case[2]])
				continue
			assert_eq(label.text, case[2], "%s %s shows at once" % [skin_id, case[2]])
			tween.custom_step(skin.duration(&"score_count") * 0.5)
			assert_eq(label.text, case[2], "%s %s does not count" % [skin_id, case[2]])
			tween.custom_step(skin.duration(&"score_count"))
			assert_eq(label.text, case[2], "%s %s ends exactly" % [skin_id, case[2]])


func test_count_up_with_no_suffix_counts_as_before() -> void:
	var skin: SkinData = SkinCatalog.get_skin(&"nova")
	var label: Label = Label.new()
	_made.append(label)
	var tween: Tween = Motion.count_up(label, skin, BigNum.zero(), BigNum.from_int(9999999999))
	assert_eq(label.text, "0", "starts at 0")
	tween.custom_step(skin.duration(&"score_count") * 0.5)
	var shown: PackedStringArray = Motion.split_score(label.text)
	assert_eq(shown[1], "", "no suffix while counting")
	assert_true(shown[0].to_int() > 0 and shown[0].to_int() < 9999999999, "counting")
	tween.custom_step(skin.duration(&"score_count"))
	assert_eq(label.text, "9,999,999,999", "ends exactly")


func test_split_score_and_grouped() -> void:
	assert_eq(Motion.split_score("9,221,253,119B"), PackedStringArray(["9221253119", "B"]), "B")
	assert_eq(Motion.split_score("1,267,650,600ab"), PackedStringArray(["1267650600", "ab"]), "ab")
	assert_eq(Motion.split_score("41,286"), PackedStringArray(["41286", ""]), "none")
	assert_eq(Motion.split_score("0"), PackedStringArray(["0", ""]), "zero")
	assert_eq(Motion.grouped(0), "0", "zero")
	assert_eq(Motion.grouped(999), "999", "three digits")
	assert_eq(Motion.grouped(1000), "1,000", "four digits")
	assert_eq(Motion.grouped(9221253119), "9,221,253,119", "ten digits")


func test_gumdrop_pulse_wobbles() -> void:
	var skin: SkinData = SkinCatalog.get_skin(&"gumdrop")
	var control: Control = _control()
	var tween: Tween = Motion.pulse(control, skin)
	assert_true(tween != null, "Gumdrop pulses")
	var period: float = skin.duration(&"target_pulse")
	tween.custom_step(period * 0.25)
	assert_near(control.rotation, deg_to_rad(float(skin.motion_spec(&"target_pulse")["wobble_degrees"])), 0.001, "a quarter period reaches the wobble")
	tween.custom_step(period * 0.5)
	assert_near(control.rotation, -deg_to_rad(float(skin.motion_spec(&"target_pulse")["wobble_degrees"])), 0.001, "three quarters swings the other way")
	tween.custom_step(period * 0.25)
	assert_true(tween.is_running(), "it loops")
	Motion.stop_pulse(control)
	assert_false(tween.is_valid(), "stop_pulse kills it")
	assert_eq(control.rotation, 0.0, "and puts it back at rest")


func test_nova_pulse_breathes() -> void:
	var skin: SkinData = SkinCatalog.get_skin(&"nova")
	var control: Control = _control()
	var tween: Tween = Motion.pulse(control, skin)
	assert_true(tween != null, "Nova pulses")
	var period: float = skin.duration(&"target_pulse")
	tween.custom_step(period * 0.5)
	assert_near(control.modulate.a, float(skin.motion_spec(&"target_pulse")["alpha_low"]), 0.001, "half a period reaches alpha_low")
	tween.custom_step(period * 0.5)
	assert_near(control.modulate.a, 1.0, 0.001, "a full period is back to 1")
	Motion.stop_pulse(control)
	assert_false(tween.is_valid(), "stop_pulse kills it")
	assert_eq(control.modulate.a, 1.0, "and leaves it opaque")


func test_slate_holds_still() -> void:
	var skin: SkinData = SkinCatalog.get_skin(&"slate")
	var control: Control = _control()
	assert_eq(skin.duration(&"target_pulse"), 0.0, "Slate's target_pulse is 0")
	assert_true(Motion.pulse(control, skin) == null, "no pulse")
	Motion.stop_pulse(control)
	assert_eq(control.rotation, 0.0, "stop_pulse is harmless with no pulse")


func test_a_new_press_stops_the_running_release() -> void:
	var skin: SkinData = SkinCatalog.get_skin(&"gumdrop")
	var control: Control = _control()
	var release: Tween = Motion.release(control, skin)
	var press: Tween = Motion.press(control, skin)
	assert_false(release.is_valid(), "the release was stopped")
	assert_true(press.is_valid(), "the press runs")


func test_tween_for_reads_the_named_motion() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		for motion_name: StringName in SkinData.MOTION_NAMES:
			var control: Control = _control()
			var seconds: float = maxf(skin.duration(motion_name), 0.1)
			var tween: Tween = Motion.tween_for(control, skin, motion_name)
			tween.tween_property(control, "modulate:a", 0.0, seconds)
			var spec: Dictionary = skin.motion_spec(motion_name)
			tween.custom_step(seconds * 0.3)
			var expected: float = float(Tween.interpolate_value(1.0, -1.0, seconds * 0.3, seconds, int(spec["trans"]) as Tween.TransitionType, int(spec["ease"]) as Tween.EaseType))
			assert_near(control.modulate.a, expected, 0.001, "%s %s curve" % [skin_id, motion_name])
			tween.kill()
