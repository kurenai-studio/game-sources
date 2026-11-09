extends "res://scripts/game/game_base.gd"
## Layer 2: building the 3D arena and HUD, camera, visuals (spin trail, ripples,
## racket poses, footprints) and replays.


# ---------------------------------------------------------------- scene setup

func build_viewport() -> void:
	vp = SubViewport.new()
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_DISABLED
	vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	add_child(vp)

	screen = TextureRect.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	screen.stretch_mode = TextureRect.STRETCH_SCALE
	screen.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	post_mat = ShaderMaterial.new()
	post_mat.shader = PostShader
	screen.material = post_mat
	add_child(screen)
	screen.texture = vp.get_texture()


## Low-res render height: the chosen pixel size, raised as the camera pulls back so
## pixels stay about the same size on the table instead of turning to mush.
func apply_pixel_scale() -> void:
	if hud_vp != null:
		hud_vp.size = Vector2i(get_viewport().get_visible_rect().size)
	var h := int(PIXEL_HEIGHTS[pixel_scale_idx] * pixel_zoom)
	var win := get_viewport().get_visible_rect().size
	vp.size = Vector2i(maxi(int(h * win.x / win.y), 16), h)
	post_mat.set_shader_parameter("source_size", Vector2(vp.size))


func make_mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if color.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


func add_mesh(parent: Node, mesh: Mesh, pos: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = make_mat(color)
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


func add_box(parent: Node, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var bm := BoxMesh.new()
	bm.size = size
	return add_mesh(parent, bm, pos, color)


func add_sphere(parent: Node, radius: float, pos: Vector3, color: Color) -> MeshInstance3D:
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	sm.radial_segments = 10
	sm.rings = 5
	return add_mesh(parent, sm, pos, color)


func _disc_mesh(radius: float) -> CylinderMesh:
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = 0.001
	cm.radial_segments = 16
	return cm


func _sphere_mesh(radius: float) -> SphereMesh:
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	sm.radial_segments = 10
	sm.rings = 5
	return sm


func add_disc(parent: Node, radius: float, pos: Vector3, color: Color) -> MeshInstance3D:
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = 0.001
	cm.radial_segments = 16
	return add_mesh(parent, cm, pos, color)


## Static scenery is gathered into one mesh (vertex colours, one material)
## instead of hundreds of little nodes: a browser draws it in one call.
func add_static(mesh: Mesh, pos: Vector3, color: Color) -> void:
	var arr: Array = mesh.get_mesh_arrays()
	var base := static_pos.size()
	for v in arr[Mesh.ARRAY_VERTEX]:
		static_pos.append(v + pos)
		static_col.append(color)
	for i in arr[Mesh.ARRAY_INDEX]:
		static_idx.append(base + i)


func add_static_box(size: Vector3, pos: Vector3, color: Color) -> void:
	var bm := BoxMesh.new()
	bm.size = size
	add_static(bm, pos, color)


func commit_static() -> void:
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = static_pos
	arr[Mesh.ARRAY_COLOR] = static_col
	arr[Mesh.ARRAY_INDEX] = static_idx
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mi := MeshInstance3D.new()
	mi.mesh = am
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true   # the colours are given as albedo colours are
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(mi)
	static_pos = PackedVector3Array()
	static_col = PackedColorArray()
	static_idx = PackedInt32Array()


func build_world() -> void:
	world = Node3D.new()
	vp.add_child(world)

	# everything is unshaded, so the environment only provides the clear colour
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = C_FLOOR
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)

	var rng := RandomNumberGenerator.new()
	rng.seed = 7

	# tournament arena: navy venue floor, red court, barriers round the court
	add_static_box(Vector3(30.0, 0.02, 30.0), Vector3(0.0, -0.01, 0.0), C_NAVY)
	add_static_box(Vector3(COURT.x * 2.0, 0.004, COURT.y * 2.0), Vector3(0.0, 0.002, 0.0), C_FLOOR)
	build_barriers()
	for i in 160:
		var p := Vector3(rng.randf_range(-COURT.x + 0.2, COURT.x - 0.2), 0.005, rng.randf_range(-COURT.y + 0.2, COURT.y - 0.2))
		if absf(p.x) < 1.0 and absf(p.z) < 1.6:
			continue
		var s := rng.randf_range(0.02, 0.05)
		add_static_box(Vector3(s, 0.002, s), p, C_FLOOR_SHADOW if rng.randf() < 0.7 else C_FLOOR_LIGHT)

	# spare balls lying around and two ball baskets
	for i in 14:
		var p := Vector3(rng.randf_range(-3.5, 3.5), 0.02, rng.randf_range(-3.0, 3.0))
		if absf(p.x) < 1.1:
			p.x = signf(p.x + 0.001) * rng.randf_range(1.2, 3.5)
		add_static(_disc_mesh(0.03), p + Vector3(0.012, -0.018, 0.012), C_FLOOR_SHADOW)
		add_static(_sphere_mesh(0.022), p, C_YELLOW if rng.randf() < 0.6 else C_ORANGE)
	for spot in [Vector3(-1.6, 0.0, -0.4), Vector3(1.7, 0.0, 0.5)]:
		make_basket(spot)

	# table: drop shadow, dark body, light top, white lines
	var ty := Sim.TABLE_Y
	add_static_box(Vector3(Sim.HALF_W * 2.0, 0.002, Sim.HALF_L * 2.0), Vector3(0.18, 0.001, 0.12), C_FLOOR_SHADOW)
	add_static_box(Vector3(Sim.HALF_W * 2.0, 0.03, Sim.HALF_L * 2.0), Vector3(0.0, ty - 0.016, 0.0), C_DEEP)
	add_static_box(Vector3(Sim.HALF_W * 2.0 - 0.01, 0.002, Sim.HALF_L * 2.0 - 0.01), Vector3(0.0, ty, 0.0), C_TABLE)
	for lx in [-0.65, 0.65]:
		for lz in [-1.1, 1.1]:
			add_static_box(Vector3(0.05, ty - 0.03, 0.05), Vector3(lx, (ty - 0.03) * 0.5, lz), C_DEEP)
	# lines: wide enough to stay at least ~2 low-res pixels, and raised clear of the
	# top and the net's shadow so they never flicker or drop out
	var lw := 0.035
	for sx in [-1.0, 1.0]:
		add_static_box(Vector3(lw, 0.004, Sim.HALF_L * 2.0), Vector3((Sim.HALF_W - lw * 0.5) * sx, ty + 0.003, 0.0), C_WHITE)
	for sz in [-1.0, 1.0]:
		add_static_box(Vector3(Sim.HALF_W * 2.0, 0.004, lw), Vector3(0.0, ty + 0.003, (Sim.HALF_L - lw * 0.5) * sz), C_WHITE)
	add_static_box(Vector3(0.025, 0.004, Sim.HALF_L * 2.0), Vector3(0.0, ty + 0.003, 0.0), C_WHITE)

	# net: chequered mesh, white tape, posts, and its shadow on the table
	var net := add_box(world, Vector3(Sim.NET_HALF_W * 2.0, Sim.NET_H - 0.02, 0.01),
			Vector3(0.0, ty + (Sim.NET_H - 0.02) * 0.5, 0.0), C_WHITE)
	var nm := net.material_override as StandardMaterial3D
	nm.albedo_texture = make_checker()
	nm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	nm.uv1_scale = Vector3(36.0, 3.0, 1.0)
	add_static_box(Vector3(Sim.NET_HALF_W * 2.0, 0.02, 0.014), Vector3(0.0, ty + Sim.NET_H - 0.01, 0.0), C_WHITE)
	add_static_box(Vector3(Sim.HALF_W * 2.0 - 0.01, 0.002, 0.06), Vector3(0.0, ty + 0.0015, 0.05), C_TABLE_SHADOW)
	# 铜墙铁壁: an extension that grows out of the top of the net (unit height,
	# scaled by net_up), its own top tape and taller posts
	var ext := add_box(world, Vector3(Sim.NET_HALF_W * 2.0, 1.0, 0.012), Vector3.ZERO, C_WHITE)
	var em := ext.material_override as StandardMaterial3D
	em.albedo_texture = make_checker()
	em.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	em.uv1_scale = Vector3(36.0, 6.0, 1.0)
	var tape := add_box(world, Vector3(Sim.NET_HALF_W * 2.0 + 0.04, 0.025, 0.02), Vector3.ZERO, C_YELLOW)
	wall_nodes = [ext, tape]
	for sx in [-1.0, 1.0]:
		wall_nodes.append(add_box(world, Vector3(0.035, 1.0, 0.035), Vector3(Sim.NET_HALF_W * sx, 0.0, 0.0), C_PALE))
	for n in wall_nodes:
		n.visible = false
	for sx in [-1.0, 1.0]:
		add_static_box(Vector3(0.03, Sim.NET_H + 0.01, 0.03), Vector3(Sim.NET_HALF_W * sx, ty + Sim.NET_H * 0.5, 0.0), C_PALE)

	# ball, its shadow, spin-coloured trail, orbiting spin dots and bounce ripples
	ball_shadow = add_disc(world, 0.03, Vector3.ZERO, C_TABLE_SHADOW)
	ball_mesh = add_sphere(world, 0.034, Vector3.ZERO, C_WHITE)
	var unit := BoxMesh.new()
	unit.size = Vector3.ONE
	for i in TRAIL_N:
		trail_segs.append(add_mesh(world, unit, Vector3.ZERO, C_WHITE))
	for i in ORBIT_N:
		orbit_dots.append(add_sphere(world, 0.014, Vector3.ZERO, C_WHITE))
	for i in 4:
		var quad := PlaneMesh.new()
		quad.size = Vector2.ONE
		var b := add_mesh(world, quad, Vector3.ZERO, C_WHITE)
		var bm := b.material_override as StandardMaterial3D
		bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		bm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		b.visible = false
		bursts.append(b)
		burst_age.append(1.0)
		burst_spin.append(0.0)
		burst_scale.append(1.0)

	var torus := TorusMesh.new()
	torus.inner_radius = 0.07
	torus.outer_radius = 0.09
	torus.rings = 16
	torus.ring_segments = 4
	hit_marker = add_mesh(world, torus, Vector3.ZERO, C_YELLOW)
	# 缩地成寸: red strips over the cut-off edges of each half, a yellow line at the new edge
	for side in [PLAYER, AI]:
		var parts := []
		for k in 4:
			var col := Color(C_RED, 0.6) if k < 2 else C_YELLOW
			var m := add_box(world, Vector3(0.01, 0.003, Sim.HALF_L - 0.02), Vector3(0.0, Sim.TABLE_Y + 0.006, side * Sim.HALF_L * 0.5), col)
			if k < 2:
				(m.material_override as StandardMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.visible = false
			parts.append(m)
		narrow_strips[side] = parts
	# VAR: a ring and a dot where the ball touched, and the margin in words
	var vr := TorusMesh.new()
	vr.inner_radius = 0.045
	vr.outer_radius = 0.06
	vr.rings = 16
	vr.ring_segments = 4
	var_mark = add_mesh(world, vr, Vector3.ZERO, C_YELLOW)
	var_dot = add_disc(world, 0.022, Vector3.ZERO, Color(0.5, 0.5, 0.52))   # the ball's grey imprint
	var_text = Label3D.new()
	var_text.font = ui_font()
	var_text.font_size = 36
	var_text.pixel_size = 0.0011   # the VAR camera is right on top of the spot
	var_text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	var_text.outline_size = 8
	world.add_child(var_text)
	for n in [var_mark, var_dot, var_text]:
		n.visible = false
	for side in [PLAYER, AI]:
		var st := Label3D.new()
		st.font = ui_font()
		st.font_size = 48
		st.pixel_size = 0.0035
		st.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		st.modulate = Color(0.85, 0.88, 0.95)
		st.outline_size = 8
		st.text = "勺"
		st.visible = false
		world.add_child(st)
		spoon_tags[side] = st
	# 金蝉脱壳: the decoy ball, its shadow, its own landing ring and the 假 tag
	decoy_shadow = add_disc(world, 0.03, Vector3.ZERO, C_TABLE_SHADOW)
	decoy_mesh = add_sphere(world, 0.034, Vector3.ZERO, C_WHITE)
	decoy_marker = add_mesh(world, torus, Vector3.ZERO, C_YELLOW)
	decoy_tag = Label3D.new()
	decoy_tag.font = ui_font()
	decoy_tag.font_size = 48
	decoy_tag.pixel_size = 0.004
	decoy_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	decoy_tag.modulate = C_RED
	decoy_tag.outline_size = 8
	decoy_tag.text = "假"
	world.add_child(decoy_tag)
	for n in [decoy_shadow, decoy_mesh, decoy_marker, decoy_tag]:
		n.visible = false

	# heavy-ball warning: a pulsing halo on the ball (the answer card lives in the HUD)
	heavy_aura = add_sphere(world, 0.07, Vector3.ZERO, C_RED)
	var am := heavy_aura.material_override as StandardMaterial3D
	am.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	am.cull_mode = BaseMaterial3D.CULL_FRONT          # draw it as a shell around the ball
	heavy_aura.visible = false
	# heavy-ball effects: spin-coloured sparks shooting off it, and smoke rising off its path
	heavy_sparks = make_heavy_particles(36, 0.3, 0.028, Vector3(0.0, -2.0, 0.0), 1.6)
	heavy_smoke = make_heavy_particles(44, 0.8, 0.035, Vector3(0.0, 0.8, 0.0), 0.25)
	var smoke_ramp := heavy_smoke.color_ramp
	smoke_ramp.set_color(0, Color(C_WHITE, 0.8))
	smoke_ramp.set_color(1, Color(C_PALE, 0.0))

	build_scoreboard()
	commit_static()

	# footprint pool: dark sole marks that fade out
	var sole := BoxMesh.new()
	sole.size = Vector3(0.08, 0.002, 0.18)
	for i in 48:
		var fp := add_mesh(world, sole, Vector3.ZERO, Color(C_FLOOR_SHADOW, 0.0))
		(fp.material_override as StandardMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		fp.visible = false
		footprints.append(fp)
		print_age.append(PRINT_LIFE)
		print_ink.append(0.5)

	# rackets (no players) with floor shadows
	paddle_nodes[PLAYER] = make_paddle(C_YELLOW, PLAYER)
	paddle_nodes[AI] = make_paddle(C_WHITE, AI)
	for side in [PLAYER, AI]:
		racket_ghosts[side] = []
		for gi in GHOSTS:
			var ghost := Node3D.new()
			world.add_child(ghost)
			var gface := Node3D.new()
			gface.rotation_degrees = Vector3(65.0, 0.0, 0.0)
			ghost.add_child(gface)
			var disc := CylinderMesh.new()
			disc.top_radius = 0.085
			disc.bottom_radius = 0.085
			disc.height = 0.01
			disc.radial_segments = 12
			add_mesh(gface, disc, Vector3.ZERO, Color(C_WHITE, 0.45 - gi * 0.12))
			ghost.visible = false
			racket_ghosts[side].append(ghost)
	for side in [PLAYER, AI]:
		paddle_shadows[side] = add_disc(world, 0.09, Vector3.ZERO, C_FLOOR_SHADOW)

	cam = Camera3D.new()
	cam.fov = 46.0
	world.add_child(cam)
	cam.current = true
	update_camera(10.0)

	# optional depth outline pass (full-screen quad)
	var quad := QuadMesh.new()
	quad.size = Vector2(2.0, 2.0)
	quad.flip_faces = true
	var qmi := MeshInstance3D.new()
	qmi.mesh = quad
	qmi.extra_cull_margin = 16384.0
	qmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	outline_mat = ShaderMaterial.new()
	outline_mat.shader = OutlineShader
	outline_mat.set_shader_parameter("enabled", outline_on)
	outline_mat.set_shader_parameter("outline_color", C_INK)
	qmi.material_override = outline_mat
	world.add_child(qmi)


## Flip-card scoreboard on a stand beside the table, tipped back so it reads from
## above; it turns to face the camera (see place_scoreboard). Red strip = you, blue strip = AI, yellow lamp = who serves.
## Little cubes (they read as pixels in the low-res view) that fade out along a
## colour ramp; emitted in world space so they trail behind the moving ball.
func make_heavy_particles(amount: int, lifetime: float, size: float, gravity: Vector3, speed: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = amount
	p.lifetime = lifetime
	p.local_coords = false
	p.emitting = false
	var cube := BoxMesh.new()
	cube.size = Vector3.ONE * size
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cube.material = mat
	p.mesh = cube
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.03
	p.direction = Vector3.UP
	p.spread = 180.0
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.gravity = gravity
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.3
	var shrink := Curve.new()
	shrink.add_point(Vector2(0.0, 1.0))
	shrink.add_point(Vector2(1.0, 0.25))
	p.scale_amount_curve = shrink
	p.color_ramp = Gradient.new()
	world.add_child(p)
	return p


func build_scoreboard() -> void:
	var root := Node3D.new()
	root.position = Vector3(-2.3, 0.0, 0.3)
	root.scale = Vector3.ONE * 0.85
	world.add_child(root)
	scoreboard = root
	add_box(root, Vector3(1.0, 0.002, 0.3), Vector3(0.16, 0.007, 0.12), C_FLOOR_SHADOW)
	for sx in [-0.4, 0.4]:
		add_box(root, Vector3(0.04, 0.55, 0.04), Vector3(sx, 0.275, 0.0), C_DEEP)
	var board := Node3D.new()
	board.position = Vector3(0.0, 0.66, 0.0)
	board.rotation_degrees = Vector3(-62.0, 0.0, 0.0)
	scoreboard_face = board
	root.add_child(board)
	add_box(board, Vector3(1.0, 0.66, 0.05), Vector3.ZERO, C_PALE)
	for side in [PLAYER, AI]:
		var x := -0.24 if side == PLAYER else 0.24
		add_box(board, Vector3(0.44, 0.36, 0.01), Vector3(x, -0.1, 0.03), C_NAVY)
		add_box(board, Vector3(0.42, 0.006, 0.012), Vector3(x, -0.1, 0.036), C_DEEP)   # flip-card split
		var digits := Label3D.new()
		digits.font = ui_font()
		digits.font_size = 120
		digits.pixel_size = 0.0034
		digits.outline_size = 0
		digits.modulate = C_WHITE
		digits.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		digits.position = Vector3(x, -0.1, 0.04)
		digits.text = "0"
		board.add_child(digits)
		board_digits[side] = digits
		# colour strip instead of a name: too few pixels for text at this size
		add_box(board, Vector3(0.44, 0.07, 0.012), Vector3(x, 0.17, 0.03), C_RED if side == PLAYER else C_TABLE_LIGHT)
		board_serve[side] = add_sphere(board, 0.045, Vector3(x, 0.26, 0.04), C_YELLOW)
		var gl := Label3D.new()   # games won, on the colour strip
		gl.font = ui_font()
		gl.font_size = 24
		gl.pixel_size = 0.0034
		gl.outline_size = 0
		gl.modulate = C_WHITE
		gl.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		gl.position = Vector3(x, 0.17, 0.04)
		board.add_child(gl)
		board_games[side] = gl


## Low court barriers like a tournament: navy boards with a DHS-red band and a
## white pinstripe, a small gap at each corner.
func build_barriers() -> void:
	var h := 0.5
	var t := 0.04
	for sx in [-1.0, 1.0]:
		for seg in [-1.0, 1.0]:
			var length := COURT.y - 0.3
			var pos := Vector3(COURT.x * sx, 0.0, seg * (length * 0.5 + 0.15))
			add_static_box(Vector3(t, h, length), pos + Vector3(0.0, h * 0.5, 0.0), C_NAVY)
			add_static_box(Vector3(t + 0.005, 0.12, length), pos + Vector3(0.0, h * 0.62, 0.0), C_RED)
			add_static_box(Vector3(t + 0.006, 0.02, length), pos + Vector3(0.0, h * 0.4, 0.0), C_WHITE)
			add_static_box(Vector3(0.25, 0.002, length), pos + Vector3(-sx * 0.14, 0.006, 0.0), C_FLOOR_SHADOW)
	for sz in [-1.0, 1.0]:
		for seg in [-1.0, 1.0]:
			var length := COURT.x - 0.3
			var pos := Vector3(seg * (length * 0.5 + 0.15), 0.0, COURT.y * sz)
			add_static_box(Vector3(length, h, t), pos + Vector3(0.0, h * 0.5, 0.0), C_NAVY)
			add_static_box(Vector3(length, 0.12, t + 0.005), pos + Vector3(0.0, h * 0.62, 0.0), C_RED)
			add_static_box(Vector3(length, 0.02, t + 0.006), pos + Vector3(0.0, h * 0.4, 0.0), C_WHITE)


func make_checker() -> ImageTexture:
	var img := Image.create(2, 2, false, Image.FORMAT_RGB8)
	img.set_pixel(0, 0, C_WHITE)
	img.set_pixel(1, 1, C_WHITE)
	img.set_pixel(1, 0, C_DEEP)
	img.set_pixel(0, 1, C_DEEP)
	return ImageTexture.create_from_image(img)


func make_basket(at: Vector3) -> void:
	var h := 0.35
	add_static_box(Vector3(0.4, 0.002, 0.3), at + Vector3(0.1, 0.001, 0.08), C_FLOOR_SHADOW)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			add_static_box(Vector3(0.02, h, 0.02), at + Vector3(0.15 * sx, h * 0.5, 0.1 * sz), C_PALE)
	for sz in [-1.0, 1.0]:
		add_static_box(Vector3(0.32, 0.02, 0.02), at + Vector3(0.0, h, 0.1 * sz), C_WHITE)
	for sx in [-1.0, 1.0]:
		add_static_box(Vector3(0.02, 0.02, 0.22), at + Vector3(0.15 * sx, h, 0.0), C_WHITE)
	for i in 5:
		add_static(_sphere_mesh(0.022), at + Vector3(-0.1 + i * 0.05, h - 0.03, 0.03 * (i % 2)), C_YELLOW)


func make_paddle(color: Color, side: int) -> Node3D:
	var root := Node3D.new()
	world.add_child(root)
	var face := Node3D.new()
	face.rotation_degrees = Vector3(40.0, 0.0, 0.0)   # tipped up so the face reads from above
	face.name = "Face"
	root.add_child(face)
	var blade := CylinderMesh.new()
	blade.top_radius = 0.085
	blade.bottom_radius = 0.085
	blade.height = 0.014
	blade.radial_segments = 16
	var rubber := add_mesh(face, blade, Vector3.ZERO, C_RED)
	var rim := CylinderMesh.new()
	rim.top_radius = 0.097
	rim.bottom_radius = 0.097
	rim.height = 0.008
	rim.radial_segments = 16
	var rim_m := add_mesh(face, rim, Vector3(0.0, -0.006, 0.0), color)   # rim colour tells the two rackets apart
	var handle := add_box(face, Vector3(0.03, 0.012, 1.0), Vector3.ZERO, C_ORANGE)
	paddle_parts[side] = {"rubber": rubber, "handle": handle, "face": face, "rim": rim_m}
	return root


## The HUD is drawn into its own viewport at UI-unit resolution and shown with
## nearest filtering, so on high-DPI screens every panel edge, ring, bar and icon
## lands on the same chunky pixel grid as the pixel font instead of being smooth.
func build_hud() -> void:
	hud_vp = SubViewport.new()
	hud_vp.transparent_bg = true
	hud_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	hud_vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	hud_vp.size = Vector2i(get_viewport().get_visible_rect().size)
	add_child(hud_vp)
	var layer := CanvasLayer.new()
	add_child(layer)
	hud_screen = TextureRect.new()
	hud_screen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hud_screen.stretch_mode = TextureRect.STRETCH_SCALE
	hud_screen.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hud_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(hud_screen)
	hud_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud_screen.texture = hud_vp.get_texture()
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_vp.add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var font := ui_font()
	var theme := Theme.new()
	theme.default_font = font
	theme.default_font_size = 12
	root.theme = theme

	# layout: the score bar top centre with the status line under it; the last
	# stroke and the tip under it on the left; your card bottom left and the
	# opponent's top right (where each of you stands); spin gauge bottom right
	score_label = make_label(root, 12, Control.PRESET_TOP_WIDE, HORIZONTAL_ALIGNMENT_CENTER)
	score_label.visible = false   # its text goes into the score bar's status line
	score_bar = ScoreBar.new()
	root.add_child(score_bar)
	score_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	score_bar.offset_left = -290.0
	score_bar.offset_right = 290.0
	score_bar.offset_top = 6.0
	score_bar.offset_bottom = 66.0
	info_label = make_rich(root, 70.0)
	tip_label = make_rich(root, 92.0)
	tip_label.add_theme_color_override("default_color", C_YELLOW)
	for l in [info_label, tip_label]:
		l.offset_right = -300.0   # stop short of the opponent's card
		l.clip_contents = true
	for side in [PLAYER, AI]:
		var card := SideCard.new()
		root.add_child(card)
		if side == PLAYER:
			card.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
			card.offset_left = 12.0
			card.offset_right = 282.0
			card.offset_top = -186.0
			card.offset_bottom = -92.0
		else:
			card.accent = C_TABLE_LIGHT
			card.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
			card.offset_left = -282.0
			card.offset_right = -12.0
			card.offset_top = 74.0
			card.offset_bottom = 136.0
		side_cards[side] = card
	# 规则转移: a big SHIFT! with a cyan and a red copy split off it
	shift_word = Control.new()
	shift_word.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(shift_word)
	shift_word.set_anchors_and_offsets_preset(Control.PRESET_HCENTER_WIDE)
	shift_word.anchor_top = 0.09
	shift_word.anchor_bottom = 0.09
	for col in [C_SKY, C_RED, C_YELLOW]:
		var l := make_label(shift_word, 96, Control.PRESET_HCENTER_WIDE, HORIZONTAL_ALIGNMENT_CENTER)
		l.add_theme_constant_override("outline_size", 10)
		l.text = "SHIFT!"
		l.add_theme_color_override("font_color", col)
		l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	shift_word.visible = false
	banner_label = make_label(root, 24, Control.PRESET_CENTER, HORIZONTAL_ALIGNMENT_CENTER)
	banner_label.set_anchors_and_offsets_preset(Control.PRESET_HCENTER_WIDE)
	banner_label.anchor_top = 0.26
	banner_label.anchor_bottom = 0.26
	# answer card for heavy balls: drawn at screen resolution so the keypad stays readable
	solve_card = TextureRect.new()
	solve_card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	solve_card.stretch_mode = TextureRect.STRETCH_SCALE
	solve_card.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	solve_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	solve_card.size = Vector2(40.0, 30.0) * 2.0
	solve_card.visible = false
	root.add_child(solve_card)
	serve_meter = ServeMeter.new()
	serve_meter.visible = false
	root.add_child(serve_meter)
	for side in [PLAYER, AI]:
		var ring := StaminaRing.new()
		root.add_child(ring)
		stamina_rings[side] = ring

	# cinematic bars and a tag shown during replays
	for preset in [Control.PRESET_TOP_WIDE, Control.PRESET_BOTTOM_WIDE]:
		var lb := ColorRect.new()
		lb.color = Color(0.0, 0.0, 0.0, 0.85)
		lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lb.visible = false
		root.add_child(lb)
		lb.set_anchors_and_offsets_preset(preset)
		if preset == Control.PRESET_TOP_WIDE:
			lb.offset_bottom = 54.0
		else:
			lb.offset_top = -54.0
		letterbox.append(lb)
	replay_tag = make_label(root, 24, Control.PRESET_TOP_RIGHT, HORIZONTAL_ALIGNMENT_RIGHT)
	replay_tag.offset_left = -260.0
	replay_tag.offset_right = -20.0
	replay_tag.offset_top = 14.0
	replay_tag.add_theme_color_override("font_color", C_RED)
	replay_tag.visible = false

	var bar := ControlsBar.new()
	root.add_child(bar)
	bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_top = -56.0
	controls_bar = bar
	spin_gauge = SpinGauge.new()
	root.add_child(spin_gauge)
	spin_gauge.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	spin_gauge.offset_left = -266.0
	spin_gauge.offset_top = -184.0
	spin_gauge.offset_right = -16.0
	spin_gauge.offset_bottom = -66.0
	spin_gauge.pivot_offset = Vector2(250.0, 118.0)   # shrinks into the corner
	spin_gauge.scale = Vector2(0.8, 0.8)
	power_gauge = PowerGauge.new()
	root.add_child(power_gauge)
	power_gauge.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	power_gauge.offset_left = -386.0
	power_gauge.offset_top = -300.0
	power_gauge.offset_right = -16.0
	power_gauge.offset_bottom = -192.0
	power_gauge.visible = false   # replaced by the two side cards
	analysis_panel = AnalysisPanel.new()
	analysis_panel.main = self
	root.add_child(analysis_panel)
	analysis_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	power_arc = PowerArc.new()
	power_arc.visible = false
	root.add_child(power_arc)
	skill_wheel = SkillWheel.new()
	skill_wheel.slots = SKILL_SLOTS
	root.add_child(skill_wheel)
	skill_wheel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	club_ui = ClubUI.new()
	club_ui.main = self
	club_ui.visible = false
	root.add_child(club_ui)
	club_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## One-line rich text row for messages mixing words, spin icons, mouse icons and keycaps.
func make_rich(parent: Control, top: float) -> RichTextLabel:
	var l := RichTextLabel.new()
	parent.add_child(l)
	l.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	l.offset_top = top
	l.offset_left = 16.0
	l.offset_bottom = top + 26.0
	l.fit_content = true
	l.scroll_active = false
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	l.add_theme_font_size_override("normal_font_size", 12)
	l.add_theme_color_override("default_color", C_WHITE)
	l.add_theme_constant_override("outline_size", 4)
	l.add_theme_color_override("font_outline_color", C_INK)
	return l


## Fills a rich row. Parts: String (plain), Texture2D (icon at 1.3x),
## [text, Color] (coloured text) or {"key": "J"} (keycap).
## 界面信息 (Tab, or the settings): simple shows what you play by; full adds
## the stroke readout, key coaching, the other side's full card, the status
## extras and every key in the guide.
func hud_full() -> bool:
	return str(settings.get("hud", "simple")) == "full"


## The line naming each stroke and its spin: while learning (tutorial and
## drills), or with the full HUD.
func shot_readout() -> bool:
	return not drill.is_empty() or hud_full()


## Which keys answer the ball coming at you: on the two gentle assist levels,
## with the full HUD, and always while learning.
func coaching() -> bool:
	return not drill.is_empty() or hud_full() or int(settings.get("help", 1)) <= 1


const HUD_M := 12.0      # the HUD's margin from the screen edges and between panels
const CARD_W := 270.0
const GUIDE_W := 430.0   # the compact key guide
const GUIDE_H := 56.0


## Places the HUD on one grid: the score at the top, the other side's card
## top right, and along the bottom your card, the key guide and the spin gauge
## sitting on the same line (the full key guide takes the bottom row and the
## two lift above it). Cards grow with what they hold.
func layout_hud() -> void:
	var m := HUD_M
	var full := hud_full()
	var cb: Control = controls_bar
	cb.full = full
	var lift := 0.0
	if full:
		cb.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		cb.offset_left = 0.0
		cb.offset_right = 0.0
		if cb.visible:
			lift = GUIDE_H + 6.0
	else:
		cb.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		cb.offset_left = -GUIDE_W * 0.5
		cb.offset_right = GUIDE_W * 0.5
	cb.offset_top = -GUIDE_H - (0.0 if full else m)
	cb.offset_bottom = 0.0 if full else -m
	var me: Control = side_cards[PLAYER]
	me.offset_left = m
	me.offset_right = m + CARD_W
	me.offset_bottom = -m - lift
	me.offset_top = -m - lift - me.height()
	var them: Control = side_cards[AI]
	them.offset_left = -m - CARD_W
	them.offset_right = -m
	them.offset_top = m
	them.offset_bottom = m + them.height()
	spin_gauge.offset_right = -m
	spin_gauge.offset_bottom = -m - lift
	spin_gauge.offset_left = -m - 250.0
	spin_gauge.offset_top = -m - lift - 118.0
	score_bar.offset_top = m
	score_bar.offset_bottom = m + 60.0
	# the readout and the coaching line: a column on the left that stops short
	# of the score and wraps, the coaching under however tall the readout is
	var half: float = (score_bar.get_parent() as Control).size.x * 0.5
	for l in [info_label, tip_label]:
		l.offset_left = m
		l.offset_right = -(half + 300.0)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.offset_top = m
	info_label.offset_bottom = m + 26.0
	var ih: float = float(info_label.get_content_height()) if info_label.get_parsed_text() != "" else 0.0
	tip_label.offset_top = m + ih + 4.0
	tip_label.offset_bottom = tip_label.offset_top + 26.0


func rich(l: RichTextLabel, parts: Array) -> void:
	l.clear()
	for p in parts:
		if p is Texture2D:
			l.add_image(p, int(p.get_width() * 1.3), int(p.get_height() * 1.3), Color.WHITE, INLINE_ALIGNMENT_CENTER)
		elif p is Array:
			l.push_color(p[1])
			l.add_text(tr(p[0]))
			l.pop()
		elif p is Dictionary:
			l.push_bgcolor(C_WHITE)
			l.push_color(C_INK)
			l.add_text(" %s " % p.key)
			l.pop()
			l.pop()
		else:
			l.add_text(tr(str(p)))


func make_label(parent: Control, size: int, preset: int, align: int) -> Label:
	var l := Label.new()
	parent.add_child(l)
	l.set_anchors_and_offsets_preset(preset)
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", C_WHITE)
	l.add_theme_constant_override("outline_size", 4)
	l.add_theme_color_override("font_outline_color", C_INK)
	return l


## Spin as icons: top/back spin badge, side spin badge, rpm numbers in the spin's colour.
func spin_parts(w: Vector3, v: Vector3) -> Array:
	var top := w.dot(Sim.topspin_axis(v))
	var parts := []
	if top > 60.0:
		parts += [Icons.spin("top"), [" %d " % int(top * RAD_TO_RPM), C_ORANGE]]
	elif top < -60.0:
		parts += [Icons.spin("back"), [" %d " % int(-top * RAD_TO_RPM), C_SKY]]
	if absf(w.y) > 60.0:
		parts += [Icons.spin("side_l" if w.y > 0.0 else "side_r"), [" %d " % int(absf(w.y) * RAD_TO_RPM), C_YELLOW if w.y > 0.0 else C_VIOLET]]
	if parts.is_empty():
		parts += [Icons.spin("none"), ["  %.1f m/s" % v.length(), C_PALE]]
	else:
		parts += [["rpm   %.1f m/s" % v.length(), C_PALE]]
	return parts


func describe_incoming(what: String) -> void:
	var sw := bw if read_true else read_w   # what you can read of it
	if shot_readout():
		rich(info_label, [str(pname[AI]) + "  ", [what, C_YELLOW], "   →  "] + spin_parts(sw, bv) + ([] if read_true else [["  （看不清）", C_PALE]]))
	if autoplay or not coaching():
		tip_label.clear()   # watching: no coaching
		return
	var top := sw.dot(Sim.topspin_axis(bv))
	# how long to hold, and which column cancels the side spin
	var extra := ["     ", Icons.strength(0.0, spin_need(sw, bv))]
	if absf(sw.y) > MIN_SPIN:
		extra += ["     ", Icons.spin("side_l" if sw.y > 0.0 else "side_r"), "  →  ", {"key": "E D" if sw.y > 0.0 else "Q A"}, Icons.ok()]
	if top < -80.0:
		rich(tip_label, [Icons.spin("back"), "   →   ", {"key": "S"}, Icons.ok(), "  ", {"key": "W"}, Icons.ok(), "  ", {"key": "不按"}, Icons.no()] + extra)
	elif top > 120.0:
		rich(tip_label, [Icons.spin("top"), "   →   ", {"key": "不按"}, Icons.ok(), "  ", {"key": "W"}, Icons.ok(), "  ", {"key": "S"}, Icons.no()] + extra)
	else:
		rich(tip_label, [Icons.spin("none"), "   →   ", {"key": "W"}, Icons.ok(), "  ", {"key": "Q"}, {"key": "E"}, Icons.ok()] + extra)


## Footsteps and footprints for the (invisible) player standing behind the racket:
## a foot goes down every STEP_LEN of travel, alternating left / right of the line
## of movement; sharp stops and turns squeak.
func track_feet(side: int, old: Vector3, delta: float) -> void:
	var now: Vector3 = paddle_pos[side]
	var moved := Vector2(now.x - old.x, now.z - old.z)
	var v: Vector3 = paddle_vel[side]
	var run_v := Vector2(v.x, v.z)
	var accel := (run_v - (last_run_vel[side] as Vector2)).length() / maxf(delta, 1e-5)
	last_run_vel[side] = run_v
	squeak_cd[side] -= delta
	if accel > 25.0 and run_v.length() > 1.2 and squeak_cd[side] <= 0.0:
		squeak_cd[side] = 0.5
		var feet := Vector3(now.x, 0.0, now.z + side * 0.35)
		sfx.squeak(feet, accel)
		# skid: a long smear along the way the sole was sliding
		var slide := (last_run_vel[side] as Vector2).normalized() if run_v.length() > 0.1 else Vector2.UP
		stamp_print(feet + Vector3(randf_range(-0.05, 0.05), 0.0, randf_range(-0.05, 0.05)), slide,
				randf_range(-0.15, 0.15), Vector3(randf_range(0.9, 1.2), 1.0, randf_range(2.0, 2.8)), 0.6)
	step_dist[side] += moved.length()
	if step_dist[side] < step_next[side] or moved.length() < 0.0005:
		return
	step_dist[side] = 0.0
	step_next[side] = STEP_LEN * randf_range(0.8, 1.2)
	step_foot[side] = -step_foot[side]
	var foot := float(step_foot[side])
	var dir := moved.normalized()
	var perp := Vector2(-dir.y, dir.x)
	# feet a hip-width apart give or take, a little ahead / behind, toes turned out
	var lateral := (0.11 + randf_range(-0.03, 0.03)) * foot
	var ahead := randf_range(-0.03, 0.03)
	var at := Vector3(now.x + perp.x * lateral + dir.x * ahead, 0.007, now.z + side * 0.35 + perp.y * lateral + dir.y * ahead)
	var run := run_v.length()
	stamp_print(at, dir, foot * 0.12 + randf_range(-0.12, 0.12),
			Vector3(randf_range(0.85, 1.1), 1.0, randf_range(0.9, 1.15)), clampf(0.3 + run * 0.1 + randf_range(-0.05, 0.08), 0.25, 0.7))
	sfx.step(at, run)


## Leaves one sole mark: `dir` the way it points, `turn` extra yaw (radians),
## `size` scale (x width, z length), `ink` starting darkness.
func stamp_print(at: Vector3, dir: Vector2, turn: float, size: Vector3, ink: float) -> void:
	if at.z < 0.0:
		# the far side is further from the camera: bigger, darker prints so they
		# survive the low-res render instead of shrinking under a pixel
		size *= Vector3(1.7, 1.0, 1.7)
		ink = minf(ink * 1.35, 0.85)
	var i := print_next
	print_next = (print_next + 1) % footprints.size()
	var fp := footprints[i]
	fp.transform = Transform3D(Basis(Vector3.UP, atan2(dir.x, dir.y) + turn).scaled(size), Vector3(at.x, 0.007, at.z))
	print_age[i] = 0.0
	print_ink[i] = ink
	fp.visible = true


## Mouse ray from the current camera onto the horizontal plane at height `y`.
func mouse_on_floor(y: float) -> Variant:
	var win := get_viewport().get_visible_rect().size
	var sp := get_viewport().get_mouse_position() / win * Vector2(vp.size)
	var o := cam.project_ray_origin(sp)
	var d := cam.project_ray_normal(sp)
	if absf(d.y) < 1e-4:
		return null
	var t := (y - o.y) / d.y
	if t < 0.0:
		return null
	return o + d * t


## Camera rig: each mode gives a target eye / look-at point (and lens); the camera
## glides toward it so switching views and following the ball stay smooth.
## How far to pull the camera back: driven by how deep the players are or are
## about to be (rackets plus where they're heading to hit), and by rally length,
## so it opens up before a long loop-to-loop exchange runs off screen.
func rally_zoom() -> float:
	var deep := 0.0
	for side in [PLAYER, AI]:
		deep = maxf(deep, absf((paddle_pos[side] as Vector3).z))
		if not plan[side].is_empty():
			deep = maxf(deep, absf((plan[side].pos as Vector3).z))
		var pred: Dictionary = hit_pred[side]
		if ball_live and pred.ok and last_hitter == -side:
			var pts: PackedVector3Array = pred.pts
			deep = maxf(deep, absf(pts[pts.size() - 1].z))
	var z := 1.0 + 0.45 * clampf((deep - 1.9) / 1.3, 0.0, 1.0)
	if ball_live:
		z += 0.2 * clampf((rally - 6) / 14.0, 0.0, 1.0)
		# a loop on the way: someone is lining one up (AI plan, or you holding the top row)
		var looping := held_stroke().x == 1 and is_human(PLAYER)
		for side in [PLAYER, AI]:
			if not plan[side].is_empty() and plan[side].shot == Shot.LOOP:
				looping = true
		if looping:
			z += 0.15
	return z


## The view in use: yours, unless a 视角转移 has you stuck with another.
func view_now() -> int:
	return view_cam if hexes.view[PLAYER] > 0 and is_human(PLAYER) and replay.is_empty() else cam_mode


func update_camera(delta: float) -> void:
	# zoom out quickly when it opens up, ease back in slowly afterwards
	var want_zoom := rally_zoom()
	cam_zoom = lerpf(cam_zoom, want_zoom, 1.0 - exp(-(5.0 if want_zoom > cam_zoom else 0.6) * delta))
	if absf(cam_zoom - pixel_zoom) > 0.06:
		pixel_zoom = cam_zoom
		apply_pixel_scale()
	var zm := cam_zoom
	var ty := Sim.TABLE_Y
	var ball := Vector3(clampf(bp.x, -1.5, 1.5), clampf(bp.y, 0.0, 2.5), clampf(bp.z, -3.4, 3.4))
	var view := view_now()
	var pp: Vector3 = paddle_pos[PLAYER]
	var look := Vector3(0.0, ty, 0.15)
	var pos := look + Vector3(0.0, 6.6, 3.6) * zm
	var fov := 46.0
	var ortho := 0.0
	match view:
		0:
			# top-down, drifting toward the ball and swinging slightly, like Smash Court
			look += Vector3(ball.x * 0.25, 0.0, ball.z * 0.22)
			pos = look + Vector3(0.0, 6.6, 3.6).rotated(Vector3.UP, clampf(ball.x * 0.1, -0.1, 0.1)) * zm
		2:
			pos = Vector3(0.0, 2.3 * zm, 4.8 * zm)
			look = Vector3(0.0, 0.8, -0.6)
			fov = 50.0
		3:
			# TV broadcast: side-on, panning along the table with the ball
			look = Vector3(0.0, ty + 0.1, ball.z * 0.35)
			pos = Vector3(6.2 * zm, 2.8 * zm, look.z)
			fov = 44.0
		4:
			# isometric pixel-art view, orthographic
			look = Vector3(0.0, ty, 0.0)
			pos = look + Vector3(4.0, 5.0, 4.0)
			ortho = 6.8 * zm
		5:
			# low, over the player's shoulder, following where you stand
			pos = Vector3(pp.x * 0.7 + 0.25, 1.55, pp.z + 1.3)
			look = Vector3(pp.x * 0.3, 0.85, -1.4)
			fov = 64.0
		6:
			# chase cam behind and above the ball, looking down the table
			pos = Vector3(ball.x * 0.7, maxf(ball.y, ty) + 1.4 * zm, ball.z + 2.6 * zm)
			look = Vector3(ball.x * 0.5, ty, ball.z - 1.0)
			fov = 55.0
	if not replay.is_empty():
		ortho = 0.0
		if replay.kind == "var":
			# VAR: low close-up on the contact point from the side it happened on
			var f: Vector3 = replay.focus
			var sx := signf(f.x) if absf(f.x) > Sim.HALF_W - 0.15 else 1.0
			var sz := signf(f.z) if absf(f.z) > Sim.HALF_L - 0.15 else 0.6
			look = f + Vector3(0.0, 0.05, 0.0)
			pos = f + Vector3(0.95 * sx, 0.42, 0.8 * sz)
			fov = 30.0
		else:
			# highlight: TV side angle tracking the ball
			look = Vector3(ball.x * 0.3, ty + 0.1, ball.z * 0.55)
			pos = Vector3(5.2, 2.2, look.z * 0.7)
			fov = 40.0
	var k := 1.0 - exp(-(6.0 if view == 6 or not replay.is_empty() else 4.0) * delta)
	cam_pos = cam_pos.lerp(pos, k)
	cam_look = cam_look.lerp(look, k)
	cam.fov = fov
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL if ortho > 0.0 else Camera3D.PROJECTION_PERSPECTIVE
	if ortho > 0.0:
		cam.size = ortho
	var shake := Vector3.ZERO
	if cam_shake > 0.0:
		cam_shake = maxf(cam_shake - delta, 0.0)
		shake = Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), 0.0) * cam_shake * 0.12
	cam.look_at_from_position(cam_pos + shake, cam_look + shake * 0.5)
	place_scoreboard(delta)


func place_scoreboard(delta: float) -> void:
	if board_mode == view_now():
		return
	board_settle += delta
	if board_settle < 0.8 and board_mode != -1:
		return            # let the camera finish moving to the new view first
	board_mode = view_now()
	board_settle = 0.0
	var best := Vector3(-(Sim.HALF_W + 0.6), 0.0, 0.0)
	var best_score := -INF
	for c in board_candidates():
		var sc := board_view_score(c)
		if sc > best_score:
			best_score = sc
			best = c
	scoreboard.position = best
	var to_cam := cam.global_position - (best + Vector3(0.0, 0.56, 0.0))
	scoreboard.rotation.y = atan2(to_cam.x, to_cam.z)
	# tip it back as far as the camera is high, so it faces the lens from any view
	var elevation := atan2(to_cam.y, Vector2(to_cam.x, to_cam.z).length())
	scoreboard_face.rotation.x = -clampf(elevation, 0.0, deg_to_rad(70.0))


## Spots on the floor around the table: down both sides and past both ends, at
## two distances.
func board_candidates() -> Array:
	var out := []
	for gap in [0.6, 1.1]:
		for z in [-1.4, -0.7, 0.0, 0.7, 1.4]:
			out.append(Vector3(-(Sim.HALF_W + gap), 0.0, z))
			out.append(Vector3(Sim.HALF_W + gap, 0.0, z))
		for x in [-1.2, 0.0, 1.2]:
			out.append(Vector3(x, 0.0, -(Sim.HALF_L + gap)))
			out.append(Vector3(x, 0.0, Sim.HALF_L + gap))
	return out


## How well the board would read from the current camera: every corner on screen
## with a margin (big penalty otherwise), clear of the HUD panels and of the
## table, and preferably on the left.
func board_view_score(at: Vector3) -> float:
	var vs := Vector2(vp.size)
	var to_cam := cam.global_position - at
	var right := Vector3(to_cam.z, 0.0, -to_cam.x).normalized() * 0.42
	var score := 0.0
	var centre := Vector2.ZERO
	for pt in [at + Vector3(0.0, 0.05, 0.0), at + Vector3(0.0, 0.85, 0.0), at + right + Vector3(0.0, 0.5, 0.0), at - right + Vector3(0.0, 0.5, 0.0)]:
		if not cam.is_position_in_frustum(pt):
			score -= 100.0
			continue
		var uv := cam.unproject_position(pt) / vs
		centre += uv * 0.25
		if uv.x < 0.04 or uv.x > 0.96 or uv.y < 0.08 or uv.y > 0.88:
			score -= 40.0
	if centre.x > 0.68 and centre.y > 0.5:
		score -= 30.0                      # under the spin / power panels
	# keep clear of the table on screen
	var tmin := Vector2(INF, INF)
	var tmax := -tmin
	for cx in [-1.0, 1.0]:
		for cz in [-1.0, 1.0]:
			var t := cam.unproject_position(Vector3(cx * Sim.HALF_W, Sim.TABLE_Y, cz * Sim.HALF_L)) / vs
			tmin = tmin.min(t)
			tmax = tmax.max(t)
	if centre.x > tmin.x - 0.03 and centre.x < tmax.x + 0.03 and centre.y > tmin.y - 0.03 and centre.y < tmax.y + 0.03:
		score -= 25.0
	score += (1.0 - centre.x) * 10.0       # prefer the left side of the screen
	score -= at.length() * 0.5             # and close to the table
	return score


## Orange = topspin, sky blue = backspin, yellow = mostly side spin, white = dead ball.
func spin_color(w: Vector3, v: Vector3) -> Color:
	var top := w.dot(Sim.topspin_axis(v))
	if absf(w.y) > absf(top) and absf(w.y) > MIN_SPIN:
		return C_YELLOW if w.y > 0.0 else C_VIOLET
	if top > MIN_SPIN:
		return C_ORANGE
	if top < -MIN_SPIN:
		return C_SKY
	return C_WHITE


func update_spin_visuals(delta: float) -> void:
	# before a serve, show the spin being prepared (the server's held key, or the AI's tell)
	var vw := (bw if read_true else read_w) if ball_live else serve_preview
	var vv := bv if ball_live else Vector3(0.0, 0.0, -server)
	var col := spin_color(vw, vv)

	# trail through the ball's real recent positions, so Magnus curl shows as a bend
	if ball_live:
		trail_pts.push_front(bp)
		if trail_pts.size() > TRAIL_N + 1:
			trail_pts.resize(TRAIL_N + 1)
	else:
		trail_pts.clear()
	for i in TRAIL_N:
		var seg := trail_segs[i]
		seg.visible = i + 1 < trail_pts.size() and (decoy.is_empty() or decoy.revealed) and not trick.get("hidden", false)
		if not seg.visible:
			continue
		var a := trail_pts[i]
		var b := trail_pts[i + 1]
		var d := a - b
		if d.length() < 0.005:
			seg.visible = false
			continue
		var thick := 0.026 * (1.0 - float(i) / TRAIL_N) + 0.006
		var up := Vector3.UP if absf(d.normalized().y) < 0.95 else Vector3.RIGHT
		seg.transform = Transform3D(Basis.looking_at(d, up) * Basis.from_scale(Vector3(thick, thick, d.length())), (a + b) * 0.5)
		(seg.material_override as StandardMaterial3D).albedo_color = col if i < TRAIL_N * 2 / 3 else C_PALE

	# dots orbiting the ball in the plane perpendicular to the spin axis,
	# turning the same way as the ball (right-hand rule), slowed down to be readable
	var spin := vw.length()
	var show_orbit: bool = (ball_live or waiting_serve) and spin > MIN_SPIN and (decoy.is_empty() or decoy.revealed) and not trick.get("hidden", false)
	if show_orbit:
		orbit_phase += spin * ORBIT_RATE * delta
		var n := vw / spin
		var e1 := n.cross(Vector3.UP if absf(n.y) < 0.9 else Vector3.RIGHT).normalized()
		var e2 := n.cross(e1)
		for k in ORBIT_N:
			var ph := orbit_phase + k * TAU / ORBIT_N
			orbit_dots[k].position = bp + (e1 * cos(ph) + e2 * sin(ph)) * 0.075
			(orbit_dots[k].material_override as StandardMaterial3D).albedo_color = col
	for d in orbit_dots:
		d.visible = show_orbit

	for i in bursts.size():
		burst_age[i] += delta
		var b := bursts[i]
		b.visible = burst_age[i] < 0.6
		if b.visible:
			var grow := (0.18 + 0.35 * sqrt(burst_age[i] / 0.6)) * burst_scale[i]
			b.basis = Basis(Vector3.UP, burst_spin[i] * delta).orthonormalized() * b.basis.orthonormalized()
			b.basis = b.basis.scaled_local(Vector3.ONE * grow)

	var pg = power_gauge
	pg.grip_text = Tech.GRIPS[grip[PLAYER]].name
	pg.ai_grip_text = Tech.GRIPS[grip[AI]].name
	pg.desc = Tech.GRIPS[grip[PLAYER]].desc
	pg.level_text = ("%s/%s" % [lv().name, LEVELS[watch_level].name]) if autoplay else lv().name
	pg.names = ["你", "AI"]
	if not drill.is_empty():
		pg.names = [pname[PLAYER], "教练"]
		pg.level_text = ""
	elif in_tie_match:
		pg.names = [pname[PLAYER], pname[AI]]
		pg.level_text = ""
	pg.focus_cards = focus_cards
	pg.focus_active = focus_until_ms > 0
	# the AI swings as hard as its feet are set, within its stamina
	pg.settle = [settle[PLAYER], settle[AI]]
	# your power is how long you hold the stroke key; an AI-driven side (the
	# opponent, or your side when watching) swings as hard as its feet are set
	var mine_power: float = hold_power() if is_human(PLAYER) else settle[PLAYER]
	pg.power = [minf(mine_power, power_cap(PLAYER)), minf(settle[AI], power_cap(AI))]
	pg.stamina = [stamina[PLAYER] / 100.0, stamina[AI] / 100.0]
	pg.stamina_max = [max_stamina[PLAYER] / 100.0, max_stamina[AI] / 100.0]
	pg.target = spin_need(bw, bv) if ball_live and last_hitter == AI and not point_over else -1.0
	_update_cards()

	var g = spin_gauge
	g.top = vw.dot(Sim.topspin_axis(vv))
	g.side = vw.y
	g.top_color = C_ORANGE if g.top > 0.0 else C_SKY
	g.side_color = C_YELLOW if g.side > 0.0 else C_VIOLET


## Bounce ripple that spells out the spin: chevrons forward (topspin) or backward
## (backspin) along the flight, arrowheads running round the ring for side spin.
func spawn_burst(at: Vector3, v: Vector3, w: Vector3) -> void:
	var oldest := 0
	for i in bursts.size():
		if burst_age[i] > burst_age[oldest]:
			oldest = i
	var top := w.dot(Sim.topspin_axis(v))
	var top_kind := "none"
	if top > MIN_SPIN:
		top_kind = "top"
	elif top < -MIN_SPIN:
		top_kind = "back"
	var side_kind := "none"
	if absf(w.y) > MIN_SPIN:
		side_kind = "side_l" if w.y > 0.0 else "side_r"
	burst_age[oldest] = 0.0
	# turns the same way as the ball, faster the more it spins overall
	var need := spin_need(w, v)
	burst_spin[oldest] = signf(w.y) * lerpf(2.0, 14.0, need) if absf(w.y) > MIN_SPIN else 0.0
	burst_scale[oldest] = 1.0 + 0.7 * maxf(need - 0.3, 0.0)
	var b := bursts[oldest]
	var flat := Vector3(v.x, 0.0, v.z)
	var basis := Basis.looking_at(flat if flat.length() > 0.01 else Vector3.FORWARD, Vector3.UP)
	b.transform = Transform3D(basis, Vector3(at.x, ground_at(at) + 0.002, at.z))
	(b.material_override as StandardMaterial3D).albedo_texture = Icons.ripple(top_kind, side_kind)
	b.visible = true


## Starts a replay of recorded time [from, to]. `kind` "highlight" plays at half
## speed in a TV angle; "var" closes in on `info.pos`, slows right down around
## `info.t` and ends on a frozen frame with the verdict.
func start_replay(kind: String, from: float, to: float, info: Dictionary) -> void:
	end_focus()
	replay = {"kind": kind, "t": from, "to": to, "freeze": 0.0,
			"focus": info.get("pos", Vector3.ZERO), "focus_t": info.get("t", -1.0),
			"label": info.get("type", ""), "verdict": info.get("verdict", "")}
	replay_saved = {"bp": bp, "bv": bv, "bw": bw, "pp": paddle_pos[PLAYER], "pa": paddle_pos[AI], "live": ball_live,
			"banner": banner_label.text}
	replay_ev = 0
	while replay_ev < rec.events.size() and rec.events[replay_ev][0] < from:
		replay_ev += 1
	trail_pts.clear()
	for lb in letterbox:
		lb.visible = true
	replay_tag.visible = true
	replay_tag.text = "VAR · %s" % replay.label if kind == "var" else "● 回放 REPLAY"
	print("[replay] %s %s %s" % [kind, replay.label, replay.verdict])
	banner_label.text = "VAR 检查 · %s" % replay.label if kind == "var" else ""


## During a VAR replay: the rackets (and their shadows and afterimages) get out
## of the way, and once the replay reaches the contested moment the verdict
## shows: a ball that clipped the edge leaves an imprint on the table where it
## touched; one that missed leaves no mark, only the margin it missed by.
func var_overlay() -> void:
	var on: bool = not replay.is_empty() and replay.kind == "var"
	for side in [PLAYER, AI]:
		(paddle_nodes[side] as Node3D).visible = not on
		(paddle_shadows[side] as Node3D).visible = not on
		if on:
			for g in racket_ghosts[side]:
				g.visible = false
	var show: bool = on and replay.focus_t >= 0.0 and replay.t >= replay.focus_t - 0.02
	var touched: bool = show and replay.label == "擦边球"
	var_mark.visible = false
	var_dot.visible = touched
	var_text.visible = false   # no floating words: the imprint (or its absence) says it, the banner gives the verdict
	if not show:
		return
	var at: Vector3 = replay.focus
	var verdict: String = replay.verdict
	var col := C_YELLOW
	if replay.label == "擦边球":
		col = Color(0.3, 0.9, 0.4)
	elif replay.label == "压线争议":
		col = C_RED
	var y: float = Sim.TABLE_Y + 0.001 if replay.label != "擦网" else at.y   # on the table surface
	# the imprint stamps in: a quick grow to an oval, squashed along the flight
	var k := clampf((replay.t - replay.focus_t) / 0.06, 0.0, 1.0)
	var_dot.position = Vector3(at.x, y + 0.007, at.z)   # over the white lines (their top is 5 mm up)
	var_dot.scale = Vector3(1.0, 1.0, 1.5) * lerpf(0.2, 1.0, k)
	var_text.position = Vector3(at.x, y + 0.08, at.z)
	var_text.modulate = col
	var_text.text = {"擦边球": "擦边 · 有效", "压线争议": "出界", "擦网": "擦网"}.get(replay.label, "")
	var m := verdict.find("差 ")
	if m >= 0:
		var_text.text += "  " + verdict.substr(m).split("→")[0].strip_edges()


func start_var(info: Dictionary) -> void:
	start_replay("var", maxf(maxf(rally_start_t, info.t - 1.5), rec.earliest()), minf(info.t + 0.7, rec.clock), info)


func update_replay(delta: float) -> void:
	var speed := 0.5
	if replay.kind == "var":
		speed = 0.15 if absf(replay.t - replay.focus_t) < 0.3 else 0.6
	AudioServer.playback_speed_scale = clampf(0.45 + speed, 0.5, 1.0)
	if replay.t >= replay.to:
		# hold the last frame (VAR: with the verdict) before handing back to play
		replay.freeze += delta
		if replay.kind == "var":
			banner_label.text = "VAR 判定:  " + replay.verdict
		if replay.freeze > (2.0 if replay.kind == "var" else 0.5):
			end_replay()
		return
	replay.t = minf(replay.t + delta * speed, replay.to)
	var s := rec.sample(replay.t)
	if s.is_empty():
		end_replay()
		return
	bp = s[0]
	bv = s[1]
	bw = s[2]
	paddle_pos[PLAYER] = s[3]
	paddle_pos[AI] = s[4]
	ball_live = s[5]
	# the recorded sounds, at the replay's pace
	while replay_ev < rec.events.size() and rec.events[replay_ev][0] <= replay.t:
		var e: Array = rec.events[replay_ev]
		replay_ev += 1
		match e[1]:
			"hit":
				sfx.hit(e[2], e[4], e[3], 0.0, false)
			"table":
				sfx.table(e[2], e[3])
			"net":
				sfx.net(e[2])
			"floor":
				sfx.floor_bounce(e[2], e[3])


func end_replay() -> void:
	if replay.is_empty():
		return
	bp = replay_saved.bp
	bv = replay_saved.bv
	bw = replay_saved.bw
	paddle_pos[PLAYER] = replay_saved.pp
	paddle_pos[AI] = replay_saved.pa
	ball_live = replay_saved.live
	banner_label.text = replay_saved.banner.replace("VAR 检查中…", "").strip_edges() if replay.kind == "var" else replay_saved.banner
	var was_var: bool = replay.kind == "var"
	replay = {}
	trail_pts.clear()
	for lb in letterbox:
		lb.visible = false
	replay_tag.visible = false
	AudioServer.playback_speed_scale = 1.0
	if was_var:
		on_var_done()


## Which animation a stroke uses (stroke names carry a 正手/反手 prefix).
func swing_key(stroke_name: String) -> String:
	var n := stroke_name.trim_prefix("正手").trim_prefix("反手")
	if SWINGS.has(n):
		return n
	if n.ends_with("挡"):
		return "挡"
	if n in ["摆短", "劈长", "搓"]:
		return "搓"
	return "前冲弧圈"


## Racket pose this frame: [offset (lateral, up, toward net), close, roll].
## During a stroke it runs backswing -> follow-through -> back to ready; with the
## ball on its way it winds into the backswing of the stroke it is about to play.
func swing_pose(side: int, w_now: String, delta: float) -> Array:
	if swing[side] >= 0.0:
		var sw: Dictionary = SWINGS[swing_style[side]]
		var big: float = FH_BIG if sw.get("big", false) and w_now == "fh" else 1.0
		var yaw: Vector2 = sw.get("yaw", Vector2.ZERO)
		swing[side] += delta
		var t: float = swing[side] / float(sw.dur)
		if t >= 1.0:
			swing[side] = -1.0
		else:
			var a: Vector3
			var c: float
			var r: float
			var y: float
			if t < 0.7:
				var e := 1.0 - pow(1.0 - t / 0.7, 3.0)      # whip through, ease out
				a = (sw.start as Vector3).lerp(sw.end, e)
				c = lerpf(sw.close.x, sw.close.y, e)
				r = lerpf(sw.roll.x, sw.roll.y, e)
				y = lerpf(yaw.x, yaw.y, e)
			else:
				var back := (t - 0.7) / 0.3                   # recover to ready
				a = (sw.end as Vector3).lerp(Vector3.ZERO, back)
				c = lerpf(sw.close.y, 0.0, back)
				r = lerpf(sw.roll.y, 0.0, back)
				y = lerpf(yaw.y, 0.0, back)
			return [a * big, c, r, y * big]
	# preparing: wind into the backswing as the ball approaches
	if ball_live and not point_over and last_hitter == -side:
		var expect := "快挡"
		if is_human(side):
			var row := held_stroke().x
			expect = ("抽球" if bp.y > Sim.TABLE_Y + 0.15 else "前冲弧圈") if row == 1 else ("搓" if row == -1 else "挡")
		elif not plan[side].is_empty():
			match int(plan[side].shot):
				Shot.LOOP: expect = "前冲弧圈"
				Shot.SMASH: expect = "扣杀"
				Shot.PUSH: expect = "搓"
		var sw: Dictionary = SWINGS[swing_key(expect)]
		var gap := absf(bp.z - (paddle_pos[side] as Vector3).z)
		var prep := clampf(1.0 - gap / 1.6, 0.0, 1.0)
		var big: float = FH_BIG if sw.get("big", false) and w_now == "fh" else 1.0
		var yaw: Vector2 = sw.get("yaw", Vector2.ZERO)
		return [(sw.start as Vector3) * prep * big, sw.close.x * prep, sw.roll.x * prep, yaw.x * prep * big]
	return [Vector3.ZERO, 0.0, 0.0, 0.0]


func ground_at(p: Vector3) -> float:
	return Sim.TABLE_Y + 0.003 if Sim.on_table(p) and p.y >= Sim.TABLE_Y else 0.003


func update_visuals(delta: float) -> void:
	ball_mesh.position = bp
	_update_narrow_visuals(delta)
	_update_wall_visuals()
	for side in [PLAYER, AI]:
		var st: Label3D = spoon_tags[side]
		st.visible = hexes.spoon[side] > 0
		if st.visible:   # bobs over the racket while it is a spoon
			st.position = (paddle_pos[side] as Vector3) + Vector3(0.0, 0.28 + 0.03 * sin(elapsed * 5.0), 0.0)
	# 暗渡陈仓: only the shadow shows (slowed time lets you see the ball)
	ball_mesh.visible = not (trick.get("hidden", false) and focus_until_ms <= 0)
	_update_decoy_visuals()
	var g := ground_at(bp)
	ball_shadow.position = Vector3(bp.x, g, bp.z)
	(ball_shadow.material_override as StandardMaterial3D).albedo_color = C_TABLE_SHADOW if g > 0.1 else C_FLOOR_SHADOW
	ball_shadow.scale = Vector3.ONE * lerpf(1.2, 0.7, clampf((bp.y - g) * 2.0, 0.0, 1.0))

	update_spin_visuals(delta)
	for i in footprints.size():
		if not footprints[i].visible:
			continue
		print_age[i] += delta
		if print_age[i] >= PRINT_LIFE:
			footprints[i].visible = false
		else:
			(footprints[i].material_override as StandardMaterial3D).albedo_color = Color(C_INK, print_ink[i] * (1.0 - print_age[i] / PRINT_LIFE))

	for side in [PLAYER, AI]:
		var n: Node3D = paddle_nodes[side]
		var pp: Vector3 = paddle_pos[side]
		# show the wing the racket is getting ready for: where the ball will meet it
		var ref_x := pp.x
		var pred_s: Dictionary = hit_pred[side]
		if ball_live and last_hitter == -side and pred_s.ok:
			var at = Sim.point_at_z(pred_s.pts, pp.z)
			if at != null:
				ref_x = at.x
		var w_now := wing_for(side, ref_x)
		if not (ball_live and last_hitter == -side):
			w_now = wing[side]
		var hd := hand(side)
		wing_yaw[side] = lerpf(wing_yaw[side], (WING_TURN if w_now == "fh" else -WING_TURN) * hd, 1.0 - exp(-12.0 * delta))
		var pose := swing_pose(side, w_now, delta)
		var lat: float = pose[0].x * (1.0 if w_now == "fh" else -1.0) * side * hd    # right-handers: +x is the player's right
		n.position = pp + Vector3(lat, pose[0].y, -side * pose[0].z)
		var yaw_turn: float = pose[3] * (1.0 if w_now == "fh" else -1.0) * hd
		n.rotation = Vector3(-side * pose[1], wing_yaw[side] + yaw_turn, -pp.x * 0.3 * side + pose[2] * hd)
		# shakehand blades stand upright with the handle down; penhold lies flatter
		var face_tilt := 40.0 if grip[side] == "pen" else 65.0
		(paddle_parts[side].face as Node3D).rotation_degrees.x = face_tilt
		# afterimages trail a big swing so its arc reads even when the camera is far
		var hist: Array = racket_hist[side]
		hist.push_front(n.transform)
		if hist.size() > GHOSTS * 2 + 1:
			hist.resize(GHOSTS * 2 + 1)
		var trailing: bool = swing[side] >= 0.0 and SWINGS[swing_style[side]].get("big", false)
		for gi in GHOSTS:
			var ghost: Node3D = racket_ghosts[side][gi]
			var hi := (gi + 1) * 2
			ghost.visible = trailing and hi < hist.size()
			if ghost.visible:
				ghost.transform = hist[hi]
				(ghost.get_child(0) as Node3D).rotation_degrees.x = face_tilt
		n.scale = Vector3.ONE * PADDLE_SCALE[side]
		# red rubber on the forehand; shakehand and reverse penhold backhands use the
		# black back side, traditional penhold pushes with the same red face
		var parts: Dictionary = paddle_parts[side]
		var gd: Dictionary = Tech.GRIPS[grip[side]]
		var back: bool = w_now == "bh" and gd.bh_face == "back"
		(parts.rubber.material_override as StandardMaterial3D).albedo_color = C_NAVY if back else C_RED
		var hl := 0.11 if grip[side] == "shake" else 0.05
		parts.handle.scale = Vector3(1.0, 1.0, hl)
		parts.handle.position = Vector3(0.0, 0.0, (0.085 + hl * 0.5) * side)
		power_gauge.wing[0 if side == PLAYER else 1] = w_now
		side_cards[side].wing = w_now
		var sh: MeshInstance3D = paddle_shadows[side]
		var pg := ground_at(pp)
		sh.position = Vector3(pp.x + 0.03, pg, pp.z + 0.03)
		(sh.material_override as StandardMaterial3D).albedo_color = C_TABLE_SHADOW if pg > 0.1 else C_FLOOR_SHADOW

	var pred: Dictionary = hit_pred[PLAYER]
	hit_marker.visible = false
	# no landing ring while a hook or a stealth ball is in the air
	var tricked: bool = not trick.is_empty() and trick.kind in ["andu", "huima", "blink"] and trick.recv == PLAYER
	if assist and not autoplay and ball_live and not point_over and last_hitter == AI and pred.ok and not tricked:
		var at = Sim.point_at_z(pred.pts, (paddle_pos[PLAYER] as Vector3).z)
		if at != null:
			hit_marker.visible = true
			hit_marker.position = at
			hit_marker.scale = Vector3.ONE * marker_scale()
			# yellow = the ball will meet your racket, red = you'll miss it
			var pp: Vector3 = paddle_pos[PLAYER]
			var in_reach: bool = Vector2(at.x - pp.x, at.y - pp.y).length() <= player_reach()
			(hit_marker.material_override as StandardMaterial3D).albedo_color = C_YELLOW if in_reach else C_RED

	# stamina wheels ride beside each racket (right of it on screen)
	var swin := get_viewport().get_visible_rect().size
	for side in [PLAYER, AI]:
		var ring = stamina_rings[side]
		ring.value = stamina[side] / 100.0
		ring.cap = max_stamina[side] / 100.0
		ring.visible = not autoplay   # watching: keep the view clean
		var rsp := cam.unproject_position(paddle_pos[side]) / Vector2(vp.size) * swin
		ring.position = (rsp + Vector2(26.0, -ring.size.y * 0.5)).clamp(Vector2.ZERO, swin - ring.size)

	# the hold-strength arc, left of your racket, while a ball is coming at you
	var incoming_me: bool = ball_live and not point_over and last_hitter == AI
	power_arc.visible = is_human(PLAYER) and (incoming_me or windup_hold > 0.0) and not waiting_serve
	if power_arc.visible:
		var psp := cam.unproject_position(paddle_pos[PLAYER]) / Vector2(vp.size) * swin
		power_arc.position = (psp + Vector2(-power_arc.size.x - 22.0, -power_arc.size.y * 0.5)).clamp(Vector2.ZERO, swin - power_arc.size)
		power_arc.value = hold_power()
		var need := spin_need(bw, bv)
		var slack := power_slack(need)
		power_arc.band = Vector2(maxf(need - slack, 0.0), need + slack) if incoming_me and read_true else Vector2(-1.0, -1.0)
		var inside: bool = power_arc.band.x >= 0.0 and power_arc.value >= power_arc.band.x and power_arc.value <= power_arc.band.y
		if inside and not arc_in_band:
			sfx.tick(paddle_pos[PLAYER])
		arc_in_band = inside
	else:
		arc_in_band = false

	if serve_meter.visible:
		var msp := cam.unproject_position(bp + Vector3(0.0, 0.12, 0.0))
		var mwin := get_viewport().get_visible_rect().size
		var mwp := msp / Vector2(vp.size) * mwin
		serve_meter.position = (mwp - Vector2(serve_meter.size.x * 0.5, serve_meter.size.y + 24.0)).clamp(Vector2.ZERO, mwin - serve_meter.size)

	# an unread 金蝉脱壳 hides everything that would tell the real ball apart
	var veiled: bool = (not decoy.is_empty() and not decoy.revealed) or trick.get("hidden", false)
	var warn: bool = heavy and ball_live and not point_over and not veiled
	heavy_aura.visible = warn
	solve_card.visible = warn and last_hitter == AI and not autoplay and read_true
	heavy_sparks.emitting = warn
	heavy_smoke.emitting = warn
	if warn:
		heavy_sparks.position = bp
		heavy_smoke.position = bp
		var spark_col := spin_color(bw, bv)
		heavy_sparks.color_ramp.set_color(0, Color(spark_col, 1.0))
		heavy_sparks.color_ramp.set_color(1, Color(spark_col.lerp(C_WHITE, 0.5), 0.0))
		var pulse := 0.5 + 0.5 * sin(elapsed * 18.0)
		heavy_aura.position = bp
		heavy_aura.scale = Vector3.ONE * (1.0 + 0.5 * pulse)
		var am := heavy_aura.material_override as StandardMaterial3D
		am.albedo_color = Color(spin_color(bw, bv), 0.35 + 0.4 * pulse)
		var anchor := bp
		if pred.ok:
			# over where you'll meet it: your racket's depth, kept inside the hittable window
			var pts: PackedVector3Array = pred.pts
			var z := clampf((paddle_pos[PLAYER] as Vector3).z, pts[0].z, pts[pts.size() - 1].z)
			var at2 = Sim.point_at_z(pts, z)
			anchor = at2 if at2 != null else pts[pts.size() / 2]
		# beside and below the hit spot (window space), clear of the ball coming in from above
		var sp := cam.unproject_position(anchor)
		var win := get_viewport().get_visible_rect().size
		var wp := sp / Vector2(vp.size) * win
		var pos := wp + Vector2(48.0, 16.0)
		if pos.x + solve_card.size.x > win.x:
			pos.x = wp.x - 48.0 - solve_card.size.x
		solve_card.position = pos.clamp(Vector2.ZERO, win - solve_card.size)


## The decoy ball, its shadow and landing ring; seen through (or landed dead)
## it greys out under a 假 tag, a dead one lies flat and fades.
func _update_decoy_visuals() -> void:
	var on := not decoy.is_empty()
	decoy_mesh.visible = on
	decoy_shadow.visible = on
	decoy_tag.visible = on and decoy.revealed
	decoy_marker.visible = false
	if not on:
		return
	var p: Vector3 = decoy.p
	decoy_mesh.position = p
	decoy_mesh.scale = Vector3(1.3, 0.35, 1.3) if decoy.landed else Vector3.ONE
	(decoy_mesh.material_override as StandardMaterial3D).albedo_color = C_PALE.darkened(0.3) if decoy.revealed else C_WHITE
	var g := ground_at(p)
	decoy_shadow.position = Vector3(p.x, g, p.z)
	decoy_tag.position = p + Vector3(0.0, 0.16, 0.0)
	# a second yellow ring where the decoy "will" meet your racket
	if decoy.recv == PLAYER and not decoy.landed and not decoy.revealed and assist and not autoplay and decoy.pred.ok:
		var at = Sim.point_at_z(decoy.pred.pts, (paddle_pos[PLAYER] as Vector3).z)
		if at != null:
			decoy_marker.visible = true
			decoy_marker.position = at
			decoy_marker.scale = Vector3.ONE * marker_scale()


## The yellow ring grows with your reach as the camera rises, so it stays as easy
## to see and to line up as it is up close.
func marker_scale() -> float:
	return zoom_reach()


## 识破: in slowed time, a click on (or near) either ball tells you which is real.
func try_reveal(at: Vector2) -> bool:
	if decoy.is_empty() or decoy.revealed or focus_until_ms <= 0 or decoy.recv != PLAYER:
		return false
	var k := get_viewport().get_visible_rect().size / Vector2(vp.size)
	for p in [bp, decoy.p]:
		if (cam.unproject_position(p) * k).distance_to(at) < 48.0:
			decoy.revealed = true
			flash("识破！")
			return true
	return false


## Fills the score bar and the two side cards.
func _update_cards() -> void:
	var sb = score_bar
	var quick: bool = prof[PLAYER].is_empty() and drill.is_empty()
	sb.names = [pname[PLAYER], pname[AI]]
	sb.points = [score[PLAYER], score[AI]]
	sb.games = [games[PLAYER], games[AI]]
	sb.show_games = best_of > 1
	sb.serving = -1 if game_over or not (waiting_serve or ball_live) else (0 if server == PLAYER else 1)
	sb.status = score_label.text.strip_edges()
	sb.visible = drill.is_empty()
	var mine_power: float = hold_power() if is_human(PLAYER) else settle[PLAYER]
	for side in [PLAYER, AI]:
		var c = side_cards[side]
		var me: bool = side == PLAYER
		c.title = pname[side]
		if not prof[side].is_empty():
			c.sub = str(prof[side].name)
		elif not drill.is_empty():
			c.sub = ""
		else:
			c.sub = LEVELS[level_of(side)].name if not quick or not me or autoplay else lv().name
		c.grip_text = Tech.GRIPS[grip[side]].name
		c.settle = settle[side]
		c.power = minf(mine_power if me else settle[side], power_cap(side))
		c.target = power_gauge.target if me else -1.0
		c.stamina = stamina[side] / 100.0
		c.stamina_max = max_stamina[side] / 100.0
		c.cards = focus_cards if me else (ai_focus if skill_on() else 0)
		c.cards_max = FOCUS_MAX if me or skill_on() else 0
		c.focus_active = me and focus_until_ms > 0
		var lo: Array = loaded(side) if skill_on() and drill.is_empty() else []
		c.skills = lo.map(func(s): return s.name)
		c.keyed = me and is_human(PLAYER)
		c.compact = side == AI and not hud_full()
		var have: int = focus_cards if me else ai_focus
		c.spent = range(lo.size()).filter(func(i): return int(lo[i].cost) > have)
		var tag := ""
		if heavy and ball_live and not point_over and last_hitter == side:
			tag = "重球！"
		if hexes.giant[side] > 0:
			tag = "巨灵神拍 · 还剩 %d 分" % hexes.giant[side]
		elif hexes.spoon[side] > 0:
			tag = "勺子 · 还剩 %d 分" % hexes.spoon[side]
		elif hexes.narrow[side] > 0:
			tag = "半台收窄 · 还剩 %d 分" % hexes.narrow[side]
		elif hexes.gravity[side] > 0:
			tag = "球变重 · 还剩 %d 分" % hexes.gravity[side]
		elif hexes.view[side] > 0:
			tag = "视角错乱 · 还剩 %d 分" % hexes.view[side]
		if me and wall_armed[PLAYER]:
			tag = "铜墙铁壁 待发"
		if me and skill_armed != "":
			tag = "%s 待发" % SKILL_SLOTS.filter(func(s): return s.id == skill_armed)[0].name
		elif me and focus_until_ms > 0:
			tag = "专注中"
		c.tag = tag
		c.visible = drill.is_empty() or me
	layout_hud()


## The game's data analysis; play pauses while it is up.
func show_analysis() -> void:
	analysis_panel.visible = true


func hide_analysis() -> void:
	analysis_panel.visible = false
	if on_break and break_kind != "":
		club_ui.visible = true   # back to the coach panel


# ---------------------------------------------------------------- skill effects

## Shared one-shot puff: a burst of pixel smoke / sparks at `at`.
func fx_burst(at: Vector3, col: Color, amount: int, speed: float) -> void:
	var p := CPUParticles3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.035, 0.035)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.albedo_color = col
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	q.material = mat
	p.mesh = q
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = amount
	p.lifetime = 0.6
	p.direction = Vector3.UP
	p.spread = 180.0
	p.initial_velocity_min = speed * 0.5
	p.initial_velocity_max = speed
	p.gravity = Vector3(0.0, -1.5, 0.0)
	p.scale_amount_min = 0.8
	p.scale_amount_max = 2.2
	p.position = at
	world.add_child(p)
	p.emitting = true
	get_tree().create_timer(1.2).timeout.connect(p.queue_free)


## WebGL compiles a material's shader the first time something with it is
## drawn, which stalls that frame (a skill's first sparks, the decoy's first
## flight). Drawing every hidden thing and one of each effect for a couple of
## frames while the game loads moves those stalls to the start.
func prewarm_fx() -> void:
	var shown: Array = []
	var walk := func(n: Node, f: Callable) -> void:
		if n is VisualInstance3D and not n.visible:
			n.visible = true
			shown.append(n)
		for c in n.get_children():
			f.call(c, f)
	walk.call(world, walk)
	var under := Vector3(0.0, -0.3, 0.0)   # below the floor: drawn, never seen
	fx_burst(under, C_WHITE, 1, 0.0)
	fx_word(under, "·", C_WHITE)
	for i in 3:
		await get_tree().process_frame
	for n in shown:
		if is_instance_valid(n):
			n.visible = false


## A word that pops up over a spot and floats away.
func fx_word(at: Vector3, text: String, col: Color) -> void:
	var l := Label3D.new()
	l.font = ui_font()
	l.font_size = 48
	l.pixel_size = 0.004
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.modulate = col
	l.outline_size = 8
	l.text = text
	l.position = at
	l.scale = Vector3.ONE * 0.2
	world.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "scale", Vector3.ONE * 1.2, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(l, "position", at + Vector3(0.0, 0.35, 0.0), 1.0)
	tw.tween_property(l, "modulate:a", 0.0, 0.35)
	tw.tween_callback(l.queue_free)


## 偷梁换柱: the racket head shrinks into a silver spoon bowl with a puff of
## smoke and a springy wobble; turning back pops it out again.
func fx_spoon(side: int, on: bool) -> void:
	var parts: Dictionary = paddle_parts[side]
	var at: Vector3 = paddle_pos[side] + Vector3(0.0, 0.1, 0.0)
	fx_burst(at, Color(C_PALE, 0.9), 26, 0.9)
	fx_word(at + Vector3(0.0, 0.1, 0.0), "变勺子！" if on else "变回来", C_PALE if on else C_YELLOW)
	var target := Vector3(0.45, 1.0, 0.7) if on else Vector3.ONE
	for k in ["rubber", "rim"]:
		var n: Node3D = parts[k]
		var tw := n.create_tween()
		tw.tween_property(n, "scale", target * Vector3(1.4, 1.0, 1.4), 0.12)
		tw.tween_property(n, "scale", target, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	(parts.rubber.material_override as StandardMaterial3D).albedo_color = Color(0.82, 0.84, 0.88) if on else C_RED


## 乾坤挪移: the ball vanishes in a puff of sky-blue and is somewhere else,
## with a streak between the two.
func fx_blink(from: Vector3, to: Vector3) -> void:
	fx_burst(from, C_SKY, 18, 0.8)
	fx_burst(to, C_WHITE, 14, 0.6)
	for i in 5:
		fx_burst(from.lerp(to, (i + 0.5) / 5.0), Color(C_SKY, 0.7), 3, 0.2)
	fx_word(to + Vector3(0.0, 0.15, 0.0), "挪移！", C_SKY)


## 规则转移: SHIFT! slams in from the side, its cyan and red copies split off
## and snap back, then it slides out the other way.
func fx_shift() -> void:
	var ls := shift_word.get_children()
	shift_word.visible = true
	shift_word.modulate.a = 1.0
	shift_word.position.x = -220.0
	var tw := shift_word.create_tween()
	tw.tween_property(shift_word, "position:x", 0.0, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.9)
	tw.tween_property(shift_word, "position:x", 220.0, 0.2).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(shift_word, "modulate:a", 0.0, 0.2)
	tw.tween_callback(func(): shift_word.visible = false)
	for i in 2:
		var l: Label = ls[i]
		var off := Vector2(-5.0, 0.0) if i == 0 else Vector2(5.0, 0.0)
		l.position = off * 4.0
		var t2 := l.create_tween()
		t2.tween_property(l, "position", off, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## 斗转星移: a violet ring of sparks where the spin turned round.
func fx_flip(at: Vector3) -> void:
	fx_burst(at, C_VIOLET, 24, 1.0)
	fx_word(at + Vector3(0.0, 0.18, 0.0), "旋转反转！", C_VIOLET)


## 重力转移: the cursed racket sheds violet sparks downwards.
func fx_gravity(side: int) -> void:
	var at: Vector3 = paddle_pos[side] + Vector3(0.0, 0.1, 0.0)
	fx_burst(at, C_VIOLET, 22, 0.6)
	fx_word(at + Vector3(0.0, 0.15, 0.0), "球变重！", C_VIOLET)


## 视角转移: a jolt and a flash over the side that loses its bearings.
func fx_view(side: int) -> void:
	var at: Vector3 = paddle_pos[side] + Vector3(0.0, 0.15, 0.0)
	cam_shake = maxf(cam_shake, 0.4)
	fx_burst(at, C_SKY, 20, 0.9)
	fx_word(at + Vector3(0.0, 0.15, 0.0), "视角错乱！", C_SKY)


## 巨灵神拍: gold sparks, the racket face springs up to twice its size with a
## gold rim and a little camera jolt; when it wears off it shrinks back.
func fx_giant(side: int, on: bool) -> void:
	var parts: Dictionary = paddle_parts[side]
	var face: Node3D = parts.face
	var at: Vector3 = paddle_pos[side] + Vector3(0.0, 0.12, 0.0)
	fx_burst(at, C_YELLOW, 34 if on else 16, 1.2 if on else 0.7)
	fx_word(at + Vector3(0.0, 0.2, 0.0), "巨大化！" if on else "变回来", C_YELLOW)
	var tw := face.create_tween()
	if on:
		cam_shake = maxf(cam_shake, 0.35)
		tw.tween_property(face, "scale", Vector3.ONE * 2.4, 0.15).set_ease(Tween.EASE_OUT)
		tw.tween_property(face, "scale", Vector3.ONE * 2.0, 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	else:
		tw.tween_property(face, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	var rim := (parts.rim as MeshInstance3D).material_override as StandardMaterial3D
	if on:
		parts["rim_color"] = rim.albedo_color
		rim.albedo_color = C_YELLOW
	elif parts.has("rim_color"):
		rim.albedo_color = parts.rim_color


## 铜墙铁壁 goes up: near-instant, overshooting a touch before it settles;
## stars and smoke burst along the net and the camera jolts.
func raise_wall(from_side: int) -> void:
	sfx.fx("cast")
	wall_from = from_side
	if wall_tween != null:
		wall_tween.kill()
	wall_tween = create_tween()
	wall_tween.tween_property(self, "net_up", 1.18, 0.07).set_ease(Tween.EASE_OUT)
	wall_tween.tween_property(self, "net_up", 1.0, 0.12).set_trans(Tween.TRANS_SINE)
	cam_shake = maxf(cam_shake, 0.45)
	var top := Sim.TABLE_Y + Sim.NET_H + WALL_EXTRA
	for x in [-0.8, -0.4, 0.0, 0.4, 0.8]:
		fx_burst(Vector3(x, top, 0.0), C_YELLOW, 10, 1.4)                    # stars
		fx_burst(Vector3(x, Sim.TABLE_Y + Sim.NET_H, 0.0), Color(C_PALE, 0.7), 8, 0.5)   # smoke
	fx_word(Vector3(0.0, top + 0.18, 0.0), "铜墙铁壁！", C_YELLOW)
	flash("铜墙铁壁！")


## Back down with a jolt: a quick drop part of the way, a catch, then a
## bouncing settle; a little dust when it lands.
func lower_wall() -> void:
	if wall_from == 0:
		return
	wall_from = 0
	if wall_tween != null:
		wall_tween.kill()
	wall_tween = create_tween()
	wall_tween.tween_property(self, "net_up", 0.45, 0.06).set_ease(Tween.EASE_IN)
	wall_tween.tween_interval(0.09)
	wall_tween.tween_property(self, "net_up", 0.0, 0.32).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	wall_tween.tween_callback(func(): fx_burst(Vector3(0.0, Sim.TABLE_Y + Sim.NET_H, 0.0), Color(C_PALE, 0.6), 10, 0.4))


## The extension follows net_up, and the physics net with it.
func _update_wall_visuals() -> void:
	var h: float = WALL_EXTRA * maxf(net_up, 0.0)
	Sim.net_extra = h
	var on := h > 0.004
	for n in wall_nodes:
		n.visible = on
	if not on:
		return
	var base := Sim.TABLE_Y + Sim.NET_H
	wall_nodes[0].scale = Vector3(1.0, h, 1.0)
	wall_nodes[0].position = Vector3(0.0, base + h * 0.5, 0.0)
	wall_nodes[1].position = Vector3(0.0, base + h, 0.0)
	for k in [2, 3]:
		wall_nodes[k].scale = Vector3(1.0, h + 0.02, 1.0)
		wall_nodes[k].position.y = base + h * 0.5


## 缩地成寸 cast on `side`'s half: the camera jolts, sparks run along both edges.
func fx_narrow(side: int) -> void:
	cam_shake = 0.6
	for sx in [-1.0, 1.0]:
		for k in 4:
			fx_burst(Vector3(sx * (Sim.HALF_W - NARROW_CUT), Sim.TABLE_Y + 0.02, side * (0.2 + k * 0.35)), C_YELLOW, 8, 0.6)
	fx_word(Vector3(0.0, Sim.TABLE_Y + 0.25, side * Sim.HALF_L * 0.5), "缩地成寸！", C_RED)


## The red strips ease in and out over each narrowed half and pulse.
func _update_narrow_visuals(delta: float) -> void:
	for side in [PLAYER, AI]:
		var want: float = NARROW_CUT if hexes.narrow[side] > 0 else 0.0
		narrow_w[side] = move_toward(narrow_w[side], want, delta * 0.6)
		var w: float = narrow_w[side]
		var parts: Array = narrow_strips[side]
		for k in 4:
			var m: MeshInstance3D = parts[k]
			m.visible = w > 0.004
			if not m.visible:
				continue
			var sx := -1.0 if k % 2 == 0 else 1.0
			if k < 2:
				m.scale = Vector3(w / 0.01, 1.0, 1.0)
				m.position.x = sx * (Sim.HALF_W - w * 0.5)
				(m.material_override as StandardMaterial3D).albedo_color = Color(C_RED, 0.75 + 0.15 * sin(elapsed * 6.0))
			else:
				m.position.x = sx * (Sim.HALF_W - w)


func use_focus() -> void:
	if focus_cards <= 0 or focus_until_ms > 0 or game_over:
		return
	focus_cards -= 1
	focus_until_ms = Time.get_ticks_msec() + int(FOCUS_SECONDS * 1000.0)   # real time, not game time
	Engine.time_scale = FOCUS_SCALE
	sfx.focus(true)


func end_focus() -> void:
	var was_on := focus_until_ms > 0
	focus_until_ms = 0
	Engine.time_scale = 1.0
	if was_on:
		sfx.focus(false)
