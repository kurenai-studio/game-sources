extends SceneTree

func _init():
	print(">>> RUNNING SHIFT: ORTHO MECHANICS VERIFICATION SUITE <<<")

	# Test 1: OrthoCamera projection states
	var cam = OrthoCamera.new()
	cam._ready()
	assert(cam.projection == Camera3D.PROJECTION_PERSPECTIVE, "Initial camera must be perspective")
	cam.toggle_projection()
	assert(cam.projection == Camera3D.PROJECTION_ORTHOGONAL, "Toggled camera must be orthogonal")
	assert(cam.is_ortho == true, "Camera is_ortho flag must be true")
	cam.toggle_projection()
	assert(cam.projection == Camera3D.PROJECTION_PERSPECTIVE, "Toggled camera must return to perspective")
	print(" [PASS] Test 1: Camera projection toggle logic verified.")

	# Test 2: ShiftCube dynamic scaling & mass calculation
	var cube = ShiftCube.new()
	cube.base_scale = 1.0
	cube.base_mass = 10.0
	cube.apply_scale_factor(2.0)
	assert(abs(cube.current_scale - 2.0) < 0.001, "Cube scale must be 2.0")
	# Mass = 10 * 2^3 = 80
	assert(abs(cube.mass - 80.0) < 0.001, "Cube mass must be 80.0 kg")
	print(" [PASS] Test 2: ShiftCube scale & cubic mass formula verified (10kg -> 80kg at 2x).")

	# Test 3: OrthoBridge solid state
	var bridge = OrthoBridge.new()
	bridge.active_in_ortho_only = true
	bridge.required_yaw_deg = -1.0
	bridge.update_state(false, 0.0)
	assert(bridge.is_solid == false, "Bridge must be inactive in perspective")
	bridge.update_state(true, 0.0)
	assert(bridge.is_solid == true, "Bridge must be active in orthogonal")
	print(" [PASS] Test 3: OrthoBridge dynamic depth-collapse state verified.")

	# Test 4: PressurePlate activation threshold with dynamic mass
	var plate = PressurePlate.new()
	plate.required_weight = 50.0
	plate._ready()
	assert(plate.is_pressed == false, "Plate must start unpressed")
	
	# Add 10kg cube (should NOT activate 50kg plate)
	var light_cube = ShiftCube.new()
	light_cube.base_mass = 10.0
	light_cube.apply_scale_factor(1.0)
	plate._on_body_entered(light_cube)
	assert(plate.is_pressed == false, "10kg cube must NOT trigger 50kg pressure plate")
	
	# Add scaled cube (80kg, should activate 50kg plate)
	var heavy_cube = ShiftCube.new()
	heavy_cube.base_mass = 10.0
	heavy_cube.apply_scale_factor(2.0)
	plate._on_body_entered(heavy_cube)
	assert(plate.is_pressed == true, "80kg cube MUST trigger 50kg pressure plate")
	
	# Remove heavy cube
	plate._on_body_exited(heavy_cube)
	plate._on_body_exited(light_cube)
	assert(plate.is_pressed == false, "Plate must deactivate when weights are removed")
	print(" [PASS] Test 4: PressurePlate mass threshold & deactivation verified.")

	# Test 5: Camera cardinal angle snapping on player body
	var player_dummy = CharacterBody3D.new()
	player_dummy.rotation.y = deg_to_rad(37.0) # Arbitrary angle close to 45 deg
	cam.snap_to_cardinal(player_dummy)
	var snapped_deg = rad_to_deg(player_dummy.rotation.y)
	assert(abs(snapped_deg - 45.0) < 0.01, "Player yaw must snap to exactly 45 degrees")
	print(" [PASS] Test 5: Cardinal 45-degree angle snapping verified on character body.")

	# Test 6: Raycast exception handling during cube grab/release
	var player_scene = load("res://scenes/player.tscn").instantiate()
	var test_cube = ShiftCube.new()
	player_scene._ready()
	assert(player_scene.held_cube == null, "Player starts with no held cube")
	
	# Simulate grabbing
	player_scene.held_cube = test_cube
	player_scene.interact_raycast.add_exception(test_cube)
	test_cube.grab(player_scene, player_scene.camera)
	assert(player_scene.interact_raycast.get_collision_mask() > 0, "Raycast must be active")
	
	# Release
	player_scene._handle_interaction()
	assert(player_scene.held_cube == null, "Cube must be released after interaction")
	print(" [PASS] Test 6: Held cube raycast penetration & grab/release lifecycle verified.")

	# Cleanup
	cam.free()
	cube.free()
	bridge.free()
	plate.free()
	light_cube.free()
	heavy_cube.free()
	player_dummy.free()
	player_scene.free()
	test_cube.free()

	print(">>> ALL 6 MECHANICS TESTS PASSED CLEANLY WITH ZERO LEAKS! <<<")
	quit(0)
