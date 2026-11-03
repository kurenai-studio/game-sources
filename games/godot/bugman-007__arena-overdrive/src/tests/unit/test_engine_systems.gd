extends GutTest
## Object pool, pickups, projectiles, audio synthesis, localization, data files and the event bus.


func _pool() -> ObjectPool:
	var parent: Node2D = add_child_autofree(Node2D.new())
	return ObjectPool.new(func() -> Node: return Node2D.new(), parent, 3)


func test_pool_prewarms() -> void:
	var p := _pool()
	assert_eq(p.free_count(), 3)
	assert_eq(p.created, 3)


func test_pool_reuses_released_nodes() -> void:
	var p := _pool()
	var a := p.acquire()
	p.release(a)
	for i in 3:
		p.acquire()
	assert_eq(p.created, 3, "no new allocations while free nodes exist")


func test_pool_grows_when_empty() -> void:
	var p := _pool()
	for i in 5:
		p.acquire()
	assert_eq(p.created, 5)
	assert_eq(p.active_count(), 5)


func test_pool_release_hides_and_disables() -> void:
	var p := _pool()
	var n: Node2D = p.acquire()
	assert_true(n.visible)
	p.release(n)
	assert_false(n.visible)
	assert_eq(n.process_mode, Node.PROCESS_MODE_DISABLED)


func test_pool_double_release_is_safe() -> void:
	var p := _pool()
	var n := p.acquire()
	assert_true(p.release(n))
	assert_false(p.release(n))
	assert_eq(p.free_count(), 3)


func test_pool_release_all() -> void:
	var p := _pool()
	for i in 4:
		p.acquire()
	p.release_all()
	assert_eq(p.active_count(), 0)
	assert_eq(p.free_count(), 4)


func test_projectile_pierce_and_hits() -> void:
	var b: Projectile = autofree(Projectile.new())
	b.launch(Vector2.ZERO, Vector2(100, 0), 10, Projectile.Team.PLAYER, Color.WHITE, 1)
	assert_false(b.register_hit(1))
	assert_true(b.already_hit(1))
	assert_true(b.register_hit(2))


func test_projectile_moves_and_expires() -> void:
	var b: Projectile = autofree(Projectile.new())
	b.launch(Vector2.ZERO, Vector2(100, 0), 10, Projectile.Team.ENEMY, Color.WHITE, 0, false, 6.0, 0.5)
	assert_true(b.advance(0.25))
	assert_almost_eq(b.position.x, 25.0, 0.001)
	assert_false(b.advance(0.3))


func test_projectile_relaunch_resets_hits() -> void:
	var b: Projectile = autofree(Projectile.new())
	b.launch(Vector2.ZERO, Vector2.RIGHT, 1, Projectile.Team.PLAYER, Color.WHITE, 3)
	b.register_hit(7)
	b.launch(Vector2.ZERO, Vector2.RIGHT, 1, Projectile.Team.PLAYER, Color.WHITE, 3)
	assert_false(b.already_hit(7))


func test_pickup_idle_outside_magnet() -> void:
	var p: Pickup = autofree(Pickup.new())
	p.setup(Pickup.Kind.XP, 1, Vector2.ZERO)
	assert_false(p.update(0.1, Vector2(500, 0), 100.0))
	assert_false(p.magnetized)
	assert_eq(p.position, Vector2.ZERO)


func test_pickup_magnet_collects() -> void:
	var p: Pickup = autofree(Pickup.new())
	p.setup(Pickup.Kind.COIN, 1, Vector2.ZERO)
	var collected := false
	for i in 120:
		if p.update(1.0 / 60.0, Vector2(80, 0), 100.0):
			collected = true
			break
	assert_true(p.magnetized)
	assert_true(collected)


func test_synth_tone_length() -> void:
	var w := SfxSynth.tone("square", 440.0, 440.0, 0.5)
	assert_eq(w.data.size(), int(0.5 * SfxSynth.MIX_RATE) * 2)
	assert_eq(w.format, AudioStreamWAV.FORMAT_16_BITS)


func test_synth_is_not_silent() -> void:
	var w := SfxSynth.tone("sine", 440.0, 440.0, 0.1, 0.8)
	var peak := 0
	for i in range(0, w.data.size(), 2):
		peak = maxi(peak, absi(w.data.decode_s16(i)))
	assert_gt(peak, 5000)


func test_music_loops() -> void:
	var m := SfxSynth.build_music(1)
	assert_eq(m.loop_mode, AudioStreamWAV.LOOP_FORWARD)
	assert_eq(m.loop_end, m.data.size() / 2)


func test_audio_library_and_buses() -> void:
	for sound in [&"shoot", &"hit", &"explode", &"level_up", &"ui_click", &"boss"]:
		assert_true(AudioManager.has_sound(sound), str(sound))
	for bus in ["Music", "SFX", "UI"]:
		assert_ne(AudioServer.get_bus_index(bus), -1, bus)


func test_localization_english_and_spanish() -> void:
	TranslationServer.set_locale("en")
	assert_eq(tr("PLAY"), "Play")
	TranslationServer.set_locale("es")
	assert_eq(tr("PLAY"), "Jugar")
	assert_eq(tr("HUD_WAVE") % 3, "OLEADA 3")
	Settings.apply()


func test_every_data_key_is_translated() -> void:
	TranslationServer.set_locale("es")
	var keys: Array[String] = []
	for u in GameState.upgrades:
		keys.append_array([u.name_key, u.desc_key])
	for id: StringName in GameState.enemies:
		keys.append((GameState.enemies[id] as EnemyData).name_key)
	for c in GameState.sorted_characters():
		keys.append_array([c.name_key, c.desc_key, c.ability_key, c.ability_key + "_DESC"])
	for k in keys:
		assert_ne(tr(k), k, "untranslated: " + k)
	Settings.apply()


func test_data_registry_loads_all_content() -> void:
	assert_eq(GameState.characters.size(), 3)
	assert_eq(GameState.enemies.size(), 5)
	assert_gte(GameState.upgrades.size(), 12)


func test_enemy_data_is_sane() -> void:
	var behaviors := {}
	for id: StringName in GameState.enemies:
		var e: EnemyData = GameState.enemies[id]
		behaviors[e.behavior] = true
		assert_gt(e.max_hp, 0.0)
		assert_gt(e.speed, 0.0)
		assert_gte(e.shape_sides, 3)
	assert_eq(behaviors.size(), 5, "chaser, shooter, tank, exploder, boss")


func test_characters_have_unique_abilities() -> void:
	var abilities := {}
	for c in GameState.sorted_characters():
		abilities[c.ability] = true
	assert_eq(abilities.size(), 3)
	assert_eq(GameState.sorted_characters()[0].unlock_cost, 0, "first class is free")


func test_event_bus_relays() -> void:
	watch_signals(EventBus)
	EventBus.wave_started.emit(3, false, 12)
	assert_signal_emitted_with_parameters(EventBus, "wave_started", [3, false, 12])
