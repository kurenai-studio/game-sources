extends Node
## Captures README screenshots (needs a real display, e.g. xvfb-run). SHOTS=<dir>, PORTRAIT=1 for the phone shot.
var main
var out := "user://"
func _ready() -> void:
	out = OS.get_environment("SHOTS") if OS.get_environment("SHOTS") != "" else "user://"
	_run.call_deferred()
func _f(n: int) -> void:
	for i in n: await get_tree().process_frame
func _snap(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	var wdt = 420 if img.get_height() > img.get_width() else 900
	img.resize(wdt, int(float(wdt) * img.get_height() / img.get_width()), Image.INTERPOLATE_BILINEAR)
	img.save_jpg(out + "/" + name + ".jpg", 0.72)
	print("[shot] ", name)
func _play(w, frames: int, fire := true) -> void:
	for i in frames:
		w.hp = w.mhp
		main.mouse_held = fire
		var tgt = null
		var bd = 1e9
		for z in w.zs:
			var d = z.p.distance_to(w.pp)
			if d < bd: bd = d; tgt = z
		if tgt: w.aim = lerp_angle(w.aim, (tgt.p - w.pp).angle(), 0.3)
		if w.state == "intermission": w.ready_up()
		await get_tree().process_frame
func _setup(mi: int, wave: int, weapons: Array):
	main.start_game(mi)
	var w = main.world
	w.mouse_aim = false
	w.cash = 4200
	for id in weapons: w.give_weapon(id)
	w.wave = wave - 1
	return w
func _run() -> void:
	main = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	if OS.get_environment("PORTRAIT") == "1":
		await _f(60)
		var w = _setup(0, 3, ["shotgun"])
		main.touch_mode = true
		w.ready_up()
		await _play(w, 420)
		main.mouse_held = false
		await _snap("mobile")
		get_tree().quit()
		return
	await _f(240)
	await _snap("title")
	var w = _setup(0, 4, ["smg", "shotgun"])
	w.place("bar")
	w.aim = 0.3; w.place("tur")
	w.ready_up()
	await _play(w, 520)
	await _snap("plaza")
	w = _setup(1, 7, ["flamer", "tesla"])
	w.ready_up()
	await _play(w, 600)
	await _snap("overpass")
	w = _setup(2, 5, ["rocket", "minigun"])
	w.ready_up()
	await _play(w, 700)
	await _snap("boss")
	main.start_game(0)
	main.world.cash = 2600
	main.world.pp = main.world.m.bench + Vector2(0, 50)
	await _f(20)
	main.open_shop()
	await _f(10)
	await _snap("bench")
	get_tree().quit()
