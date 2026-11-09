extends SceneTree

func _init():
	print(">>> RUNNING NIGHT SHIFT AT SITE-42 VERIFICATION SUITE <<<")

	# Test 1: FacilityManager time & ticket progression
	var fac = FacilityManager.new()
	fac._ready()
	assert(fac.get_formatted_time() == "12:00 AM", "Initial shift time must be 12:00 AM")
	fac.resolve_ticket(1)
	assert(fac.get_formatted_time() == "01:30 AM", "Time after ticket 1 must be 01:30 AM")
	fac.resolve_ticket(2)
	assert(fac.get_formatted_time() == "03:30 AM", "Time after ticket 2 must be 03:30 AM")
	fac.resolve_ticket(3)
	assert(fac.get_formatted_time() == "06:00 AM", "Time after ticket 3 must be 06:00 AM")
	assert(fac.are_all_tasks_done() == true, "All 3 maintenance tickets must be done")
	assert(fac.tickets[3]["status"] == "AVAILABLE", "Ticket 4 (Exit) must be AVAILABLE at 06:00 AM")
	print(" [PASS] Test 1: Facility Graveyard Shift timeline (12:00 -> 06:00 AM) verified.")

	# Test 2: ShiftDoorway unanchored vs quantum anchored by Polaroid
	var door = ShiftDoorway.new()
	door.doorway_id = "test_door"
	door.is_anchored = false
	
	# Initial shift when unanchored
	var shifted_success = door.trigger_shift()
	assert(shifted_success == true, "Unanchored door must shift successfully")
	assert(door.is_shifted == true, "Door state must be shifted")
	
	# Anchor the door via Polaroid
	door.set_anchored(true)
	assert(door.is_anchored == true, "Door must now be anchored")
	var shift_blocked = door.trigger_shift()
	assert(shift_blocked == false, "Anchored door MUST reject shifting!")
	print(" [PASS] Test 2: ShiftDoorway quantum anchoring via Polaroid photograph verified.")

	# Test 3: CoolantValve stabilization
	var valve = CoolantValve.new()
	valve.turns_required = 3
	valve.interact()
	assert(valve.is_complete == false, "Valve should not be complete after 1 turn")
	valve.interact()
	valve.interact()
	assert(valve.is_complete == true, "Valve must be complete after 3 turns")
	print(" [PASS] Test 3: CoolantValve maintenance interaction verified.")

	# Test 4: PowerCell pickup and PowerSocket insertion
	var socket = PowerSocket.new()
	var cell = PowerCell.new()
	assert(socket.is_powered == false, "Socket must start unpowered")
	var insert_res = socket.insert_cell()
	assert(insert_res == true, "Cell must insert successfully into socket")
	assert(socket.is_powered == true, "Socket must be powered after insertion")
	var second_insert = socket.insert_cell()
	assert(second_insert == false, "Socket cannot accept a second power cell")
	print(" [PASS] Test 4: PowerCell & PowerSocket circuit restoration verified.")

	# Test 5: OverrideConsole activation
	var console = OverrideConsole.new()
	assert(console.is_activated == false, "Console must start unactivated")
	console.interact()
	assert(console.is_activated == true, "Console must be activated after interaction")
	print(" [PASS] Test 5: Containment Wing 04 OverrideConsole latch override verified.")

	# Test 6: Polaroid Camera Tool aim and photograph capture
	var cam_tool = PolaroidCameraTool.new()
	assert(cam_tool.is_aiming == false, "Camera tool must start lowered")
	cam_tool.set_aim(true)
	assert(cam_tool.is_aiming == true, "Camera tool must be aiming")
	var photo = cam_tool.snap_photo("02:15 AM")
	assert(photo.has("title"), "Photo must have title metadata")
	assert(photo["time"] == "02:15 AM", "Photo timestamp must match facility time")
	print(" [PASS] Test 6: Polaroid Camera tool viewfinder and snapshot capture verified.")

	# Test 7: Full shift loop completion & extraction punch-out
	var state = {"finished": false}
	fac.shift_completed.connect(func(): state["finished"] = true)
	fac.complete_shift()
	assert(state["finished"] == true, "Full graveyard shift completion must trigger extraction!")
	print(" [PASS] Test 7: Full 06:00 AM extraction and time clock completion verified.")

	# Cleanup
	fac.free()
	door.free()
	valve.free()
	socket.free()
	cell.free()
	console.free()
	cam_tool.free()

	print(">>> ALL 7 SITE-42 MECHANICS TESTS PASSED CLEANLY! <<<")
	quit(0)
