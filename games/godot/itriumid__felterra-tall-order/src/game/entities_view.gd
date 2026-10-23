class_name EntitiesView
extends Node2D
## Everything standing on the ground: the cats, the horde and the fallen, drawn back to front
## with a shadow under each, so height above the ground reads at a glance. Rounds in the air
## draw as short tracers.

## Muzzle flashes last this long, in seconds.
const FLASH_TIME := 0.05
## Ground covered by one full walk cycle, in meters: the frames step with the feet, so they
## never slide, and a body knocked through the air doesn't run.
const CAT_STRIDE := 0.42
const RAT_STRIDE := 0.24
const DOG_STRIDE := 0.6
const GIANT_STRIDE := 1.4

var arena: Arena
## Blood, or with it off, the same hits throwing up dust and fur instead.
var blood := true
## How bright each cat's muzzle is right now, 0 to 1, and the rounds counted at the last frame.
var flash := {}
var _rounds_seen := {}
## Droplets in the air, and the stains they leave: real particles, landing where they fall.
var _droplets: Array[Dictionary] = []
## Hits handed over since the last frame, to throw blood or dust for.
var _pending: Array[Dictionary] = []
## The areas already free, for props that show it (the airstrip's ribbon, cut).
var _freed_areas: Array[String] = []
## Chainsaw bars running this frame: their teeth are drawn moving along them.
var _running_chain: Array[Dictionary] = []
var _stains: Array[Dictionary] = []
const MOST_STAINS := 900
const STAIN_DRIES := 15.0
const STAIN_LASTS := 45.0
var _dust: Array[Dictionary] = []
## How long the view has run, for the drone's rotors, and the support rounds counted last frame.
var _clock := 0.0
var _support_rounds := {}
## How far each cat and creature has walked, and where it was last frame.
var _walked := {}
var _last := {}


## Hits from the simulation's steps since the last frame.
func take_events(events: Array[Dictionary]) -> void:
	_pending.append_array(events)


func _process(delta: float) -> void:
	for cat in arena.cats:
		var fired := 0
		for weapon in cat.weapons:
			fired += weapon.rounds_fired
		if fired != _rounds_seen.get(cat, 0):
			flash[cat] = 1.0
		_rounds_seen[cat] = fired
		flash[cat] = maxf(flash.get(cat, 0.0) - delta / FLASH_TIME, 0.0)
		if cat.dodging_for > 0.0 and not cat.body.airborne():
			_kick_dust(cat.body)
		var cannon: Support = cat.supports.get("set_down")
		if cannon != null and cannon.weapon != null:
			if cannon.weapon.rounds_fired != _support_rounds.get(cannon, cannon.weapon.rounds_fired):
				_puff(cannon)
			_support_rounds[cannon] = cannon.weapon.rounds_fired
	for machine in arena.machines:
		_exhaust(machine, delta)
	_clock += delta
	_settle_dust(delta)
	_bleed(delta)
	_pace()
	queue_redraw()


## Counts the ground each walker has covered on its feet.
func _pace() -> void:
	var walked := {}
	var last := {}
	var walkers: Array = arena.cats + arena.creatures + arena.giants
	for walker: Object in walkers:
		var body: Body = walker.body
		var moved: float = body.position.distance_to(_last.get(walker, body.position))
		walked[walker] = _walked.get(walker, 0.0) + (0.0 if body.airborne() else moved)
		last[walker] = body.position
	_walked = walked
	_last = last


func _frame(walker: Object, stride: float) -> int:
	if walker.body.velocity.length() < 0.1:
		return 0
	return int(_walked.get(walker, 0.0) / stride * 4.0) % 4


func _draw() -> void:
	var standing: Array[Array] = []
	for creature in arena.creatures:
		standing.append([creature.body.position.y, creature])
	for body in arena.fallen:
		standing.append([body.position.y, body])
	for cat in arena.cats:
		standing.append([cat.body.position.y, cat])
	for remains in arena.fading:
		standing.append([remains.body.position.y, remains])
	for giant in arena.giants:
		standing.append([giant.body.position.y, giant])
	for machine in arena.machines:
		standing.append([machine.body.position.y, machine])
	for structure in arena.structures:
		standing.append([structure.body.position.y, structure])
	for lever in arena.levers:
		standing.append([lever.position.y, {"lever": lever}])
	for rolling in arena.logs:
		standing.append([rolling.y, {"rolling": rolling}])
	for cat in arena.cats:
		for slot: String in cat.supports:
			var support: Support = cat.supports[slot]
			if support.deployed:
				standing.append([support.body.position.y, support])
	standing.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	for stain in _stains:
		draw_rect(Rect2(World.to_screen(stain.position), Vector2.ONE), Palette.BLOOD if stain.age < STAIN_DRIES else Palette.BLOOD_DRY)
	for piece in arena.pickups:
		standing.append([piece.body.position.y, piece])
	for cage in arena.cages:
		standing.append([cage.body.position.y if not cage.opened else cage.runner.position.y, cage])
	for cat in arena.cats:
		var mines: Support = cat.supports.get("set_down")
		if mines != null:
			for mine in mines.mines:
				var art := Sprites.MINE if mine.armed_in <= 0.0 else Sprites.MINE_ARMING
				draw_texture(Sprites.lit(art), World.to_screen(mine.body.position) - Vector2(4, 3))
	_draw_ground_hazards()
	_draw_props()
	for entry in standing:
		_draw_shadow(entry[1])
	for entry in standing:
		var thing: Variant = entry[1]
		if thing is Cat:
			_draw_cat(thing)
		elif thing is Support:
			_draw_support(thing)
		elif thing is LogLoader:
			_draw_loader(thing)
		elif thing is LoggingTruck:
			_draw_truck(thing)
		elif thing is Bulldozer:
			_draw_bulldozer(thing)
		elif thing is Helicopter:
			_draw_helicopter(thing)
		elif thing is Machine:
			_draw_machine(thing)
		elif thing is Cage:
			_draw_cage(thing)
		elif thing is Structure:
			_draw_structure(thing)
		elif thing is Dictionary and thing.has("lever"):
			_draw_lever(thing.lever)
		elif thing is Dictionary and thing.has("rolling"):
			_draw_rolling(thing.rolling)
		elif thing is Pickup:
			var art: String = Sprites.SALVAGE[absi(hash(thing)) % Sprites.SALVAGE.size()]
			var texture := Sprites.lit(art)
			draw_texture(texture, World.to_screen(thing.body.position, thing.body.height) - Vector2(texture.get_width() / 2, texture.get_height() - 1))
		elif thing is Giant:
			_draw_giant(thing)
			if thing.afflictions.has("burn"):
				_draw_flames(thing.body.position, 0.4, 6)
		elif thing is Creature:
			# Tripped, it's down on its side, drawn as the fallen are until it's up.
			if thing.kind == "rat_baron":
				var texture := Sprites.lit(Sprites.RAT_BARON[_frame(thing, RAT_STRIDE * 2.0) % 2], thing.body.velocity.x < 0.0, thing.tripped())
				var feet := Sprites.RAT_BARON_FEET
				if thing.body.velocity.x < 0.0:
					feet.x = texture.get_width() - 1 - feet.x
				draw_texture(texture, World.to_screen(thing.body.position, thing.body.height) - feet)
			elif thing.kind == "dog":
				_draw_dog(thing.body, _frame(thing, DOG_STRIDE), thing.tripped(), thing.state == Creature.State.CROUCHING)
			else:
				_draw_rat(thing.body, _frame(thing, RAT_STRIDE), thing.tripped())
			if thing.afflictions.has("burn"):
				_draw_flames(thing.body.position, thing.body.height + thing.body.tall, 3)
			elif thing.afflictions.has("poison"):
				draw_rect(Rect2(World.to_screen(thing.body.position, thing.body.tall + 0.12), Vector2(1, 1)), Palette.LEAF_LIGHT)
		elif thing is Body:
			if thing.kind == "rat_baron":
				var texture := Sprites.lit(Sprites.RAT_BARON[0], false, true)
				draw_texture(texture, World.to_screen(thing.position, thing.height) - Sprites.RAT_BARON_FEET)
			elif thing.kind == "dog":
				_draw_dog(thing, 1, true, false)
			else:
				_draw_rat(thing, 0, true)
		else:
			_draw_remains(entry[1])
	for speck in _dust:
		draw_rect(Rect2(World.to_screen(speck.position, speck.height), Vector2.ONE), Palette.SMOKE)
	for droplet in _droplets:
		draw_rect(Rect2(World.to_screen(droplet.position, droplet.height), Vector2.ONE), droplet.color)
	for shot in arena.shots:
		if shot.weapon != null and shot.weapon.name == "net_drone":
			# A net in flight, spread like a hand.
			var center := World.to_screen(shot.position, shot.height)
			for corner in [Vector2(-2, -2), Vector2(2, -2), Vector2(-2, 2), Vector2(2, 2)]:
				draw_line(center, center + corner, Palette.DRY_GRASS)
			continue
		if shot.falls:
			# A stone in flight, its shadow on the ground under it.
			draw_rect(Rect2(World.to_screen(shot.position), Vector2(2, 1)), Palette.GROUND_SHADOW)
			draw_rect(Rect2(World.to_screen(shot.position, shot.height) - Vector2(1, 1), Vector2(3, 3)), Palette.OUTLINE)
			draw_rect(Rect2(World.to_screen(shot.position, shot.height) - Vector2(1, 1), Vector2(2, 2)), Palette.STEEL)
		else:
			draw_line(World.to_screen(shot.previous, shot.previous_height), World.to_screen(shot.position, shot.height), Palette.SPARK)


func _draw_shadow(thing: Variant) -> void:
	if thing is Dictionary:
		return
	if thing is Giant:
		_draw_giant_shadow(thing)
		return
	if thing is Machine:
		_draw_machine_shadow(thing)
		return
	if thing is Cage:
		var cage: Cage = thing
		if not cage.opened:
			draw_rect(Rect2(World.to_screen(cage.body.position) + Vector2(-12, -1), Vector2(24, 3)), Palette.GROUND_SHADOW)
		return
	# Anything with a body casts a shadow from it: a cat, a creature, salvage, a structure.
	var body: Body = thing if thing is Body else thing.body
	# A pixel ellipse on the ground, narrower the higher the body is.
	var width := roundi(body.radius * 2.0 * World.PIXELS_PER_METER * clampf(1.0 - body.height, 0.5, 1.0))
	var center := World.to_screen(body.position)
	draw_rect(Rect2(center + Vector2(-width / 2 + 1, -1), Vector2(maxi(width - 2, 1), 3)), Palette.GROUND_SHADOW)
	draw_rect(Rect2(center + Vector2(-width / 2, 0), Vector2(width, 1)), Palette.GROUND_SHADOW)


func _draw_rat(body: Body, frame: int, fallen: bool) -> void:
	var facing_left := body.velocity.x < 0.0
	# The fallen lie belly up.
	var texture := Sprites.lit(Sprites.RAT_STRIDES[frame], facing_left, fallen)
	draw_texture(texture, _rat_corner(body, texture, facing_left) - Vector2(0, 0 if fallen else Sprites.RAT_LIFT[frame]))


## A dog: galloping, or bunched low before a lunge, or fallen on its back.
func _draw_dog(body: Body, frame: int, fallen: bool, crouching: bool) -> void:
	var facing_left := body.velocity.x < 0.0
	var art := Sprites.dog_art(2 if crouching else frame)
	var texture := Sprites.lit(art, facing_left, fallen)
	var feet := Sprites.DOG_FEET
	if facing_left:
		feet.x = texture.get_width() - 1 - feet.x
	var corner := World.to_screen(body.position, body.height) - feet
	if crouching:
		# Down on its haunches: the warning before the leap.
		corner.y += 4
	elif not fallen:
		corner.y -= Sprites.DOG_LIFT[frame]
	draw_texture(texture, corner)


## Remains crumbling away, a few more pixels gone each stage.
func _draw_remains(remains: Dictionary) -> void:
	var body: Body = remains.body
	var stage := clampi(int((1.0 - remains.left / Arena.FADE_TIME) * Sprites.STAGES), 0, Sprites.STAGES - 1) + 1
	var art: String = Sprites.dog_art(1) if body.kind == "dog" else Sprites.RAT_STRIDES[0]
	var texture := Sprites.crumbled(art, stage, false, true)
	draw_texture(texture, _rat_corner(body, texture, false))


func _rat_corner(body: Body, texture: Texture2D, facing_left: bool) -> Vector2:
	var feet := Sprites.RAT_FEET
	if facing_left:
		feet.x = texture.get_width() - 1 - feet.x
	return World.to_screen(body.position, body.height) - feet


func _draw_cat(cat: Cat) -> void:
	var feet := World.to_screen(cat.body.position, cat.body.height)
	var top_left := feet - Sprites.CAT_FEET
	if cat.dodging_for > 0.0:
		# Tucked into the roll.
		top_left.y += 3.0
	var facing := Sprites.cat_view(cat.facing)
	var view: String = facing[0]
	var flip: bool = facing[1]
	var frame := _frame(cat, CAT_STRIDE)
	var holds := _pose_holds(cat, view, flip, frame, top_left)
	for hold in holds:
		if hold.behind:
			_draw_hold(hold)
	_draw_pack(cat, view, flip, top_left, "behind")
	draw_texture(Sprites.lit(Sprites.coat(Sprites.cat_body_art(view, frame, Sprites.FEET.get(cat.gear.get("feet", ""), ""), Sprites.PAWS.get(cat.gear.get("paws", ""), "")), cat.coat, view), flip), top_left)
	var worn_on_body: String = cat.gear.get("body", "")
	if Sprites.BODIES.has(worn_on_body):
		draw_texture(Sprites.lit(Sprites.BODIES[worn_on_body][view], flip), top_left)
	for slot in ["neck", "waist", "eyes"]:
		var item: String = cat.gear.get(slot, "")
		if Sprites.WORN.has(item):
			draw_texture(Sprites.lit(Sprites.WORN[item][view], flip), top_left)
	_draw_pack(cat, view, flip, top_left, "over")
	var hat: String = cat.gear.get("head", "")
	if Sprites.HATS.has(hat):
		draw_texture(Sprites.lit(Sprites.HATS[hat]), top_left + Sprites.cat_anchor(view, flip, "head"))
	for hold in holds:
		if not hold.behind:
			_draw_hold(hold)


## The machine's shadow, its footprint on the ground; and while the boom swings out to bite, the
## head's shadow where it will come down, rimmed in hi-vis: the warning, like a boot's.
func _draw_machine_shadow(machine: Machine) -> void:
	if machine is Helicopter:
		# A shadow far below, smaller the higher it flies; its strafe marked on the ground.
		var shrink := clampf(1.0 - machine.body.height * 0.15, 0.5, 1.0)
		draw_colored_polygon(_footprint(machine, machine.body.position, machine.length * shrink, machine.width * shrink, 0.0), Palette.GROUND_SHADOW)
		if machine.state == Machine.State.AIMING:
			_draw_warning_strip(machine.strafe_from, machine.strafe_to, Helicopter.STRAFE_WIDTH * 2.0)
		return
	var corners := _footprint(machine, machine.body.position, machine.length + 0.2, machine.width + 0.2, 0.0)
	draw_colored_polygon(corners, Palette.GROUND_SHADOW)
	if machine is LoggingTruck and machine.state == Machine.State.AIMING:
		var line: PackedVector2Array = machine.charge_line()
		_draw_warning_strip(line[0], line[1], machine.width)
		return
	if machine is Bulldozer and machine.state == Machine.State.AIMING:
		_draw_warning_strip(machine.point(machine.length * 0.5, 0.0), machine.point(machine.length * 0.5 + Bulldozer.RAM_LENGTH, 0.0), machine.width + 0.4)
		return
	if machine is LogLoader and (machine.state == Machine.State.AIMING or machine.log_flying > 0.0):
		var center := World.to_screen(machine.bite_at)
		var across := LogLoader.SLAM_RADIUS * World.PIXELS_PER_METER
		var angle := 0.0
		while angle < TAU:
			draw_rect(Rect2((center + Vector2(cos(angle) * across, sin(angle) * across * 0.5)).round(), Vector2.ONE), Palette.HI_VIS)
			angle += 0.18
		return
	if machine.state in [Machine.State.AIMING, Machine.State.BITING]:
		var share := 1.0 - (machine.state_for / Machine.AIM_TIME if machine.state == Machine.State.AIMING else 0.0)
		# The shadow grows as the head closes in over him; its rim is dotted, like the saw's arc.
		var center := World.to_screen(machine.bite_at)
		var across := Machine.JAW_RADIUS * World.PIXELS_PER_METER * lerpf(0.6, 1.0, share)
		var down := across * 0.5
		for row in range(-int(down), int(down) + 1):
			var half := roundf(across * sqrt(maxf(1.0 - pow(row / down, 2.0), 0.0)))
			draw_rect(Rect2(center + Vector2(-half, row), Vector2(half * 2.0 + 1.0, 1)), Palette.GROUND_SHADOW)
		var angle := 0.0
		while angle < TAU:
			draw_rect(Rect2((center + Vector2(cos(angle) * (across + 1.0), sin(angle) * (down + 1.0))).round(), Vector2.ONE), Palette.HI_VIS)
			angle += 0.22


## A feller buncher, as boxes projected the way the scene is: two tracks, the deck over them, the
## engine housing behind and the cab in front, then the boom out to its head. Each box shows the
## faces turned toward the viewer, its left faces lit and its right ones shaded, light coming from
## the top left, and draws far to near. The treads step with the ground the tracks have run.
func _draw_machine(machine: Machine) -> void:
	var parts: Array[Dictionary] = []
	for across in [-0.75, 0.75]:
		parts.append({"box": [machine.point(0.0, across), Machine.LENGTH, 0.5, 0.0, 0.5], "colors": [Palette.STEEL, Palette.STEEL_DARK, Palette.STEEL_DARK], "treads": true})
	parts.append({"box": [machine.point(0.0, 0.0), 2.6, 1.7, 0.5, 1.05], "colors": [Palette.BRASS_LIGHT, Palette.BRASS_LIGHT, Palette.BRASS]})
	parts.append({"box": [machine.point(-0.85, 0.0), 0.9, 1.5, 1.05, 1.6], "colors": [Palette.BRASS_LIGHT, Palette.BRASS_LIGHT, Palette.BRASS]})
	parts.append({"box": [machine.point(-1.05, 0.5), 0.15, 0.15, 1.6, 2.0], "colors": [Palette.OUTLINE, Palette.STEEL_DARK, Palette.STEEL_DARK]})
	parts.append({"box": [machine.point(0.45, -0.35), 1.0, 0.95, 1.05, 2.0], "colors": [Palette.BRASS_LIGHT, Palette.STEEL_LIGHT, Palette.STEEL], "cab": true})
	# Lower boxes first, so what sits on the deck draws over it; at the same level, far to near.
	for part in parts:
		part.depth = float(part.box[3]) * 100.0 + (part.box[0] as Vector2).y
	parts.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.depth < b.depth)
	var boom_drawn := false
	var root_depth := 105.0 + machine.root().y
	for part in parts:
		# The boom rises from the deck's front: it draws among what's on the deck, by depth.
		if not boom_drawn and part.depth > root_depth:
			_draw_boom(machine)
			boom_drawn = true
		var face := _box(machine, part.box, part.colors, part.get("treads", false))
		if part.get("cab", false) and machine.standing() and not face.is_empty():
			# The operator, in hi-vis, behind the glass of the face turned toward the viewer.
			var seat := World.to_screen(face.ground, 1.5)
			draw_rect(Rect2(seat + Vector2(-2, -5), Vector2(4, 4)), Palette.SKIN)
			draw_rect(Rect2(seat + Vector2(-3, -1), Vector2(6, 5)), Palette.HI_VIS)
	if not boom_drawn:
		_draw_boom(machine)


## The boom from its root on the deck, up over an elbow and down to the head; the head with its
## saw disc and its jaws, open as it swings and shut once it's bitten; and the hydraulic joint on
## top, its hoses red, flashing while it's open to hits.
func _draw_boom(machine: Machine) -> void:
	var root := World.to_screen(machine.root(), Machine.ROOT_HEIGHT)
	var top := machine.head_height + 0.6
	var elbow_ground := machine.root().lerp(machine.head, 0.45)
	var elbow := World.to_screen(elbow_ground, maxf(Machine.ROOT_HEIGHT, top) + 0.5)
	var head_top := World.to_screen(machine.head, top)
	_thick(root, elbow, 5, Palette.BRASS, 0.0)
	_thick(elbow, head_top, 4, Palette.BRASS, 0.0)
	# The hydraulic ram along the boom's back.
	_thick(root + Vector2(0, -3), elbow + Vector2(0, -3), 2, Palette.STEEL_LIGHT, 0.0)
	var head_bottom := World.to_screen(machine.head, machine.head_height)
	_thick(head_top, head_bottom + Vector2(0, -3), 8, Palette.STEEL_DARK, 0.0)
	var shut := machine.state in [Machine.State.STUCK] or not machine.standing()
	var spread := 3 if shut else 9
	for side in [-1, 1]:
		_thick(head_bottom + Vector2(side * 3, -4), head_bottom + Vector2(side * spread, 0), 2, Palette.STEEL, 0.0)
	draw_rect(Rect2(head_bottom + Vector2(-4, -1), Vector2(8, 2)), Palette.STEEL_LIGHT)
	var joint := head_top + Vector2(0, -2)
	draw_rect(Rect2(joint - Vector2(3, 2), Vector2(6, 4)), Palette.OUTLINE)
	draw_rect(Rect2(joint - Vector2(2, 1), Vector2(4, 2)), Palette.SCARF_RED)
	if machine.exposed() and int(_clock * 8.0) % 2 == 0:
		draw_rect(Rect2(joint - Vector2(4, 3), Vector2(8, 6)), Palette.SPARK, false, 1.0)


## One box of the machine: [center over the ground, length along its heading, width across,
## bottom, top], in colors [top, lit side, shaded side]. Returns the face most turned toward the
## viewer, as {ground: its middle over the ground}, or nothing if none shows.
func _box(machine: Machine, box: Array, colors: Array, treads := false) -> Dictionary:
	var center: Vector2 = box[0]
	var bottom: float = box[3]
	var top: float = box[4]
	var ground := _footprint_ground(machine, center, box[1], box[2])
	var nearest := {}
	var nearest_y := 0.001
	for index in 4:
		var a: Vector2 = ground[index]
		var b: Vector2 = ground[(index + 1) % 4]
		var outward := (a + b) / 2.0 - center
		# Only the faces turned toward the viewer show.
		if outward.y <= 0.001:
			continue
		if outward.normalized().y > nearest_y:
			nearest_y = outward.normalized().y
			nearest = {"ground": (a + b) / 2.0}
		var face := PackedVector2Array([World.to_screen(a, bottom), World.to_screen(b, bottom), World.to_screen(b, top), World.to_screen(a, top)])
		draw_colored_polygon(face, colors[1] if outward.x < 0.0 else colors[2])
		draw_polyline(face + PackedVector2Array([face[0]]), Palette.OUTLINE)
	var lid := PackedVector2Array()
	for point in ground:
		lid.append(World.to_screen(point, top))
	draw_colored_polygon(lid, colors[0])
	draw_polyline(lid + PackedVector2Array([lid[0]]), Palette.OUTLINE)
	if treads:
		var along := machine.facing()
		var across := along.orthogonal() * (float(box[2]) * 0.5)
		var spacing := 0.25
		var shift := fposmod(machine.tracks_run, spacing)
		var offset := -float(box[1]) * 0.5 + shift
		while offset < float(box[1]) * 0.5:
			var at := center + along * offset
			draw_line(World.to_screen(at - across, top), World.to_screen(at + across, top), Palette.STEEL_DARK)
			offset += spacing
	return nearest


func _footprint_ground(machine: Machine, center: Vector2, length: float, width: float) -> Array[Vector2]:
	var along := machine.facing() * length * 0.5
	var across := machine.facing().orthogonal() * width * 0.5
	return [center + along + across, center + along - across, center - along - across, center - along + across]


func _footprint(machine: Machine, center: Vector2, length: float, width: float, height: float) -> PackedVector2Array:
	var corners := PackedVector2Array()
	for point in _footprint_ground(machine, center, length, width):
		corners.append(World.to_screen(point, height))
	return corners


## Exhaust out of the stack while it works: thicker and darker once it's broken, then thinning out.
func _exhaust(machine: Machine, delta: float) -> void:
	var working := machine.standing()
	var rate := 6.0 if working else 14.0 * clampf(1.0 - machine.broken_for / 20.0, 0.0, 1.0)
	if randf() > rate * delta:
		return
	_droplets.append({
		"position": machine.point(-1.05, 0.5), "height": 2.05, "rise": randf_range(0.4, 1.0),
		"velocity": Vector2(randf_range(-0.2, 0.2), randf_range(-0.3, -0.1)),
		"color": Palette.SMOKE if working else Palette.BURNT, "stains": false, "floats": true, "life": randf_range(1.0, 2.0),
	})


## A cage: the cat inside seen through its bars, a padlock on the front, and while the lock is
## being picked, how far along it is. Opened, the cat running home, its legs stepping with the
## ground it covers.
func _draw_cage(cage: Cage) -> void:
	if cage.opened:
		var running := Sprites.cat_view(cage.runner.velocity)
		var stride := Sprites.cat_body_art(running[0], int(cage.ran / CAT_STRIDE * 4.0) % 4)
		draw_texture(Sprites.lit(Sprites.coat(stride, cage.prisoner.coat), running[1]), World.to_screen(cage.runner.position) - Sprites.CAT_FEET)
		return
	var feet := World.to_screen(cage.body.position)
	var inside := Sprites.lit(Sprites.coat(Sprites.cat_body_art("side", 0), cage.prisoner.coat), absi(hash(cage)) % 2 == 0)
	draw_texture(inside, feet - Sprites.CAT_FEET)
	var box := Rect2(feet + Vector2(-13, -20), Vector2(26, 21))
	draw_rect(box.grow(1), Palette.OUTLINE, false, 1.0)
	draw_rect(Rect2(box.position, Vector2(box.size.x, 2)), Palette.STEEL_LIGHT)
	draw_rect(Rect2(box.position + Vector2(0, box.size.y - 2), Vector2(box.size.x, 2)), Palette.STEEL_DARK)
	var x := box.position.x
	while x <= box.end.x - 1:
		draw_rect(Rect2(Vector2(x, box.position.y + 2), Vector2(1, box.size.y - 4)), Palette.STEEL)
		x += 3
	# The padlock.
	draw_rect(Rect2(feet + Vector2(-3, -11), Vector2(6, 6)), Palette.OUTLINE)
	draw_rect(Rect2(feet + Vector2(-2, -10), Vector2(4, 4)), Palette.BRASS)
	draw_rect(Rect2(feet + Vector2(-2, -10), Vector2(4, 1)), Palette.BRASS_LIGHT)
	draw_rect(Rect2(feet + Vector2(-1, -13), Vector2(2, 2)), Palette.STEEL)
	if cage.picked > 0.0:
		var bar := Rect2(feet + Vector2(-12, -26), Vector2(24, 3))
		draw_rect(bar, Palette.GRAPHITE)
		draw_rect(Rect2(bar.position + Vector2(1, 1), Vector2(roundf(22 * cage.picked), 1)), Palette.LEAF_LIGHT)


## The log loader: tracks, deck and cab like the feller buncher's, and an arm out to its grapple,
## holding a log until it throws one; a thrown log arcs through the air to where it lands.
func _draw_loader(machine: LogLoader) -> void:
	_draw_tracked_body(machine, Palette.HI_VIS, Palette.HI_VIS, Palette.SCARF_RED)
	var root := World.to_screen(machine.root(), Machine.ROOT_HEIGHT)
	var grip := World.to_screen(machine.head, machine.head_height + 0.3)
	var elbow := World.to_screen(machine.root().lerp(machine.head, 0.5), maxf(Machine.ROOT_HEIGHT, machine.head_height) + 0.8)
	_thick(root, elbow, 5, Palette.SCARF_RED, 0.0)
	_thick(elbow, grip, 4, Palette.SCARF_RED, 0.0)
	var holding := machine.state in [Machine.State.DRIVING, Machine.State.AIMING, Machine.State.RAISING] and machine.standing()
	if holding:
		_draw_log(machine.head, machine.head_height, machine.facing().orthogonal())
	for side in [-1, 1]:
		_thick(grip, grip + Vector2(side * 4, 5), 2, Palette.STEEL, 0.0)
	if machine.log_flying > 0.0:
		var done := 1.0 - machine.log_flying / LogLoader.FLIGHT
		var at: Vector2 = machine.thrown_from.lerp(machine.bite_at, done)
		_draw_log(at, lerpf(LogLoader.LIFT_HEIGHT, 0.2, done) + sin(done * PI) * 1.5, Vector2.RIGHT.rotated(done * 6.0))
	_draw_joint(machine)


## A log: a trunk section, its end showing its rings.
func _draw_log(at: Vector2, height: float, across: Vector2) -> void:
	var from := World.to_screen(at - across * 0.7, height)
	var to := World.to_screen(at + across * 0.7, height)
	_thick(from, to, 5, Palette.BARK_LIGHT, 0.0)
	draw_rect(Rect2(to - Vector2(1, 1), Vector2(3, 3)), Palette.DRY_GRASS)


## The logging truck: its cab in front, the trailer behind stacked with trunks, on wheels. Wrecked,
## it's tipped over on its side, its load spilled.
func _draw_truck(machine: LoggingTruck) -> void:
	var tipped := not machine.standing()
	var lift := 0.0 if tipped else 0.35
	var parts: Array[Dictionary] = []
	for along in [-1.6, -0.4, 1.6]:
		for across in [-0.7, 0.7]:
			parts.append({"box": [machine.point(along, across), 0.6, 0.2, 0.0, 0.45], "colors": [Palette.STEEL_DARK, Palette.OUTLINE, Palette.OUTLINE]})
	parts.append({"box": [machine.point(-0.6, 0.0), 3.4, 1.5, lift, lift + 0.25], "colors": [Palette.STEEL, Palette.STEEL_DARK, Palette.STEEL_DARK]})
	parts.append({"box": [machine.point(1.6, 0.0), 1.3, 1.6, lift, lift + (0.9 if tipped else 1.5)], "colors": [Palette.HI_VIS, Palette.HI_VIS, Palette.SCARF_RED], "cab": true})
	for row in (0 if tipped else 2):
		for across in [-0.45, 0.0, 0.45]:
			parts.append({"box": [machine.point(-0.6, across + (0.22 if row == 1 else 0.0)), 3.2, 0.42, lift + 0.25 + row * 0.42, lift + 0.67 + row * 0.42], "colors": [Palette.BARK_LIGHT, Palette.BARK, Palette.BARK]})
	_draw_parts(machine, parts)
	if tipped:
		# Spilled trunks lying across the road.
		for index in 4:
			_draw_log(machine.point(-1.2 + index * 0.7, 1.4 + index * 0.2), 0.15, machine.facing())
	_draw_joint(machine)


## The bulldozer: tracks, a body and cab, the blade in front (raised as it warns), the exhaust
## stack, and its engine's grille at the back.
func _draw_bulldozer(machine: Bulldozer) -> void:
	_draw_tracked_body(machine, Palette.BRASS_LIGHT, Palette.BRASS_LIGHT, Palette.BRASS)
	var raised := 0.35 if machine.state == Machine.State.AIMING else 0.0
	var blade: Array[Dictionary] = [{"box": [machine.point(machine.length * 0.5 + 0.2, 0.0), 0.25, machine.width + 0.5, raised, raised + 0.7], "colors": [Palette.STEEL_LIGHT, Palette.STEEL, Palette.STEEL_DARK]}]
	_draw_parts(machine, blade)
	_draw_joint(machine)


## The helicopter: its shadow far below, the fuselage, the cockpit's glass, its tail boom, skids,
## and the rotor's blur. Shot down, it lies wrecked on its side.
func _draw_helicopter(machine: Helicopter) -> void:
	var height := machine.body.height
	var parts: Array[Dictionary] = []
	parts.append({"box": [machine.point(0.2, 0.0), 2.6, 1.2, height + 0.2, height + 1.2], "colors": [Palette.CREAM, Palette.CREAM, Palette.SMOKE]})
	parts.append({"box": [machine.point(1.4, 0.0), 0.5, 1.0, height + 0.35, height + 1.0], "colors": [Palette.STEEL_LIGHT, Palette.STEEL_LIGHT, Palette.STEEL]})
	parts.append({"box": [machine.point(-1.8, 0.0), 1.8, 0.25, height + 0.7, height + 0.95], "colors": [Palette.CREAM, Palette.CREAM, Palette.SMOKE]})
	parts.append({"box": [machine.point(0.2, 0.0), 2.6, 0.2, height + 0.55, height + 0.7], "colors": [Palette.HI_VIS, Palette.HI_VIS, Palette.SCARF_RED]})
	for across in [-0.55, 0.55]:
		parts.append({"box": [machine.point(0.2, across), 2.4, 0.08, height, height + 0.08], "colors": [Palette.STEEL_DARK, Palette.STEEL_DARK, Palette.STEEL_DARK]})
	_draw_parts(machine, parts)
	if machine.standing():
		# The main rotor, a ring of blur turning.
		var hub := World.to_screen(machine.point(0.2, 0.0), height + 1.35)
		var turn := _clock * 18.0
		for index in 24:
			var angle := turn + TAU * index / 24.0
			if index % 3 != 0:
				draw_rect(Rect2((hub + Vector2(cos(angle) * 46.0, sin(angle) * 18.0)).round(), Vector2.ONE), Palette.SMOKE)
		draw_line(hub - Vector2(cos(turn) * 46.0, sin(turn) * 18.0), hub + Vector2(cos(turn) * 46.0, sin(turn) * 18.0), Palette.STEEL_DARK)
	_draw_joint(machine)


## A tracked body for any machine: two tracks, a deck, the engine housing, and the cab with its
## operator, in the machine's own paint.
func _draw_tracked_body(machine: Machine, top: Color, lit: Color, shaded: Color) -> void:
	var length := machine.length
	var width := machine.width
	var parts: Array[Dictionary] = []
	for across in [-width * 0.375, width * 0.375]:
		parts.append({"box": [machine.point(0.0, across), length, width * 0.25, 0.0, 0.5], "colors": [Palette.STEEL, Palette.STEEL_DARK, Palette.STEEL_DARK], "treads": true})
	parts.append({"box": [machine.point(0.0, 0.0), length * 0.85, width * 0.85, 0.5, 1.05], "colors": [top, lit, shaded]})
	parts.append({"box": [machine.point(-length * 0.28, 0.0), length * 0.3, width * 0.75, 1.05, 1.6], "colors": [top, lit, shaded]})
	parts.append({"box": [machine.point(-length * 0.35, width * 0.25), 0.15, 0.15, 1.6, 2.0], "colors": [Palette.OUTLINE, Palette.STEEL_DARK, Palette.STEEL_DARK]})
	parts.append({"box": [machine.point(length * 0.15, -width * 0.18), length * 0.33, width * 0.48, 1.05, 2.0], "colors": [top, Palette.STEEL_LIGHT, Palette.STEEL], "cab": true})
	_draw_parts(machine, parts)


## Boxes drawn lower ones first, then far to near; a cab gets its operator behind the glass.
func _draw_parts(machine: Machine, parts: Array[Dictionary]) -> void:
	for part in parts:
		part.depth = float(part.box[3]) * 100.0 + (part.box[0] as Vector2).y
	parts.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.depth < b.depth)
	for part in parts:
		var face := _box(machine, part.box, part.colors, part.get("treads", false))
		if part.get("cab", false) and machine.standing() and not face.is_empty():
			var seat := World.to_screen(face.ground, float(part.box[3]) + 0.45)
			draw_rect(Rect2(seat + Vector2(-2, -5), Vector2(4, 4)), Palette.SKIN)
			draw_rect(Rect2(seat + Vector2(-3, -1), Vector2(6, 5)), Palette.HI_VIS)


## A machine's weak joint: red hoses, flashing while it's open to hits.
func _draw_joint(machine: Machine) -> void:
	if not machine.standing():
		return
	var at := World.to_screen(machine.joint.body.position, machine.joint.body.height + 0.2)
	draw_rect(Rect2(at - Vector2(3, 2), Vector2(6, 4)), Palette.OUTLINE)
	draw_rect(Rect2(at - Vector2(2, 1), Vector2(4, 2)), Palette.SCARF_RED)
	if machine.exposed() and int(_clock * 8.0) % 2 == 0:
		draw_rect(Rect2(at - Vector2(4, 3), Vector2(8, 6)), Palette.SPARK, false, 1.0)


## A warning marked on the ground in dotted hi-vis: a strip from one point to another, this wide.
func _draw_warning_strip(from: Vector2, to: Vector2, width: float) -> void:
	var along := to - from
	var across := along.orthogonal().normalized() * width * 0.5
	var steps := int(along.length() / 0.15)
	for step in steps:
		var at := from + along * float(step) / steps
		for side in [-1.0, 1.0]:
			if step % 2 == 0:
				draw_rect(Rect2(World.to_screen(at + across * side), Vector2.ONE), Palette.HI_VIS)


## An area's props: signs on their posts, and the airstrip's ribbon, strung for the ceremony and,
## once the area's free, hanging cut.
func _draw_props() -> void:
	if arena.area.is_empty():
		return
	for prop: Dictionary in arena.area.get("props", []):
		var at: Vector2 = prop.at
		if prop.kind == "sign":
			var lines: Array = prop.lines
			var width := 0
			for line: String in lines:
				width = maxi(width, PixelFont.width(line))
			var base := World.to_screen(at)
			var box := Rect2(base + Vector2(-width / 2 - 6, -30 - lines.size() * PixelFont.LINE_HEIGHT), Vector2(width + 12, lines.size() * PixelFont.LINE_HEIGHT + 6))
			for post_x in [box.position.x + 4, box.end.x - 6]:
				draw_rect(Rect2(Vector2(post_x, box.end.y), Vector2(2, base.y - box.end.y)), Palette.BARK)
			draw_rect(box.grow(1), Palette.OUTLINE)
			draw_rect(box, Palette.CREAM)
			draw_rect(Rect2(box.position, Vector2(box.size.x, 2)), Palette.HI_VIS)
			for index in lines.size():
				var text: String = lines[index]
				PixelFont.draw(self, Vector2(floorf(base.x - PixelFont.width(text) / 2.0), box.position.y + 4 + index * PixelFont.LINE_HEIGHT), text, Palette.CLOTH_SHADOW if index == 0 else Palette.STEEL_DARK)
		elif prop.kind == "ribbon":
			var left := World.to_screen(at + Vector2(-3.0, 0.0))
			var right := World.to_screen(at + Vector2(3.0, 0.0))
			for post in [left, right]:
				draw_rect(Rect2(post + Vector2(-1, -24), Vector2(2, 24)), Palette.STEEL)
			if arena.liberated or arena.area.id in _freed_areas:
				# Cut: each half hanging from its post.
				draw_line(left + Vector2(0, -22), left + Vector2(10, -2), Palette.SCARF_RED)
				draw_line(right + Vector2(0, -22), right + Vector2(-10, -2), Palette.SCARF_RED)
			else:
				draw_line(left + Vector2(0, -22), right + Vector2(0, -22), Palette.SCARF_RED)
				var middle := (left + right) / 2.0 + Vector2(0, -22)
				draw_colored_polygon(PackedVector2Array([middle, middle + Vector2(-5, -3), middle + Vector2(-5, 3)]), Palette.SCARF_RED)
				draw_colored_polygon(PackedVector2Array([middle, middle + Vector2(5, -3), middle + Vector2(5, 3)]), Palette.SCARF_RED)


## A structure of an area's goal: its art, a saw's blade spinning over its bench, and how much of
## it is left once it's hit.
func _draw_structure(structure: Structure) -> void:
	if not structure.alive():
		# Broken: a heap of what it was.
		var heap := World.to_screen(structure.body.position)
		for index in 10:
			draw_rect(Rect2(heap + Vector2((index * 7) % 15 - 7, -(index % 3)), Vector2(3, 1)), [Palette.BARK, Palette.STEEL_DARK, Palette.BURNT][index % 3])
		return
	var art: String = Sprites.STRUCTURES[structure.kind]
	var texture := Sprites.lit(art)
	var at := World.to_screen(structure.body.position) - Vector2(texture.get_width() / 2, texture.get_height() - 1)
	draw_texture(texture, at)
	if structure.kind == "saw":
		var hub := at + Vector2(texture.get_width() / 2, 0)
		var turn := structure.spun
		for tooth in 8:
			var angle := turn + TAU * tooth / 8.0
			draw_rect(Rect2((hub + Vector2(cos(angle) * 7.0, sin(angle) * 3.0)).round(), Vector2.ONE), Palette.STEEL_LIGHT)
		draw_rect(Rect2(hub - Vector2(1, 1), Vector2(3, 2)), Palette.STEEL)
	if structure.health < structure.most_health:
		var top := at + Vector2(texture.get_width() / 2 - 10, -5)
		draw_rect(Rect2(top, Vector2(20, 3)), Palette.GRAPHITE)
		draw_rect(Rect2(top + Vector2(1, 1), Vector2(roundf(18 * structure.health / structure.most_health), 1)), Palette.LEAF_LIGHT)


## A lever at the top of the slide, its stack of logs behind it: thrown as he pulls it.
func _draw_lever(lever: Dictionary) -> void:
	var base := World.to_screen(lever.position)
	for index in 3:
		_draw_log(lever.position + Vector2(0.0, -0.5 - index * 0.3), 0.15 + index * 0.05, Vector2.RIGHT * 3.0)
	var tilt: float = lever.picked if not lever.pulled else 1.0
	_thick(base, base + Vector2(lerpf(-6.0, 6.0, tilt), -14), 2, Palette.STEEL, 0.0)
	draw_rect(Rect2(base + Vector2(lerpf(-7.0, 5.0, tilt), -16), Vector2(3, 3)), Palette.SCARF_RED)
	if lever.picked > 0.0 and not lever.pulled:
		var bar := Rect2(base + Vector2(-12, -24), Vector2(24, 3))
		draw_rect(bar, Palette.GRAPHITE)
		draw_rect(Rect2(bar.position + Vector2(1, 1), Vector2(roundf(22 * lever.picked), 1)), Palette.LEAF_LIGHT)


## Logs let go: shifting before they roll, then rolling down the slope.
func _draw_rolling(rolling: Dictionary) -> void:
	var shake := Vector2((int(_clock * 30.0) % 2) * 2 - 1, 0) if rolling.wait > 0.0 else Vector2.ZERO
	for index in 3:
		var y: float = rolling.y - index * 0.25
		var from := World.to_screen(Vector2(rolling.from, y), 0.25) + shake
		var to := World.to_screen(Vector2(rolling.to, y), 0.25) + shake
		_thick(from, to, 6, Palette.BARK_LIGHT if index % 2 == 0 else Palette.BARK, 0.0)
		draw_rect(Rect2(to - Vector2(2, 2), Vector2(4, 4)), Palette.DRY_GRASS)


## His pack and what's on it, at one depth: behind him or over him. The cannon's tube shows only
## while it's on his back, and the drone only while it's docked on top.
func _draw_pack(cat: Cat, view: String, flip: bool, at: Vector2, depth: String) -> void:
	if cat.supports.is_empty():
		return
	var drone: Support = cat.supports.get("drone")
	# Docked, the drone sits on top of the pack: behind his head unless he's turned away.
	var drone_depth := "over" if view == "back" else "behind"
	if drone != null and drone.name == "layang_layang":
		drone = null
	if drone != null and not drone.deployed and depth == drone_depth and depth == "behind":
		_draw_docked(drone, view, flip, at)
	if Sprites.PACK[view].has(depth):
		draw_texture(Sprites.lit(Sprites.PACK[view][depth], flip), at)
	for slot: String in cat.supports:
		var support: Support = cat.supports[slot]
		if not Sprites.MOUNTS.has(support.name) or not Sprites.MOUNTS[support.name][view].has(depth):
			continue
		if support.name == "meriam_bambu" and (support.deployed or support.rebuilt_in > 0.0):
			continue
		draw_texture(Sprites.lit(Sprites.MOUNTS[support.name][view][depth], flip), at)
	if drone != null and not drone.deployed and depth == drone_depth and depth == "over":
		_draw_docked(drone, view, flip, at)


func _draw_docked(drone: Support, view: String, flip: bool, at: Vector2) -> void:
	# The bees' hive sits where a drone would dock.
	var art := Sprites.BEE_HIVE if drone.name == "bee_swarm" else Sprites.DRONE_DOCKED
	var dock: Vector2 = Sprites.DOCK[view]
	if flip:
		dock.x = 24 - dock.x - Sprites.image(art).get_width()
	draw_texture(Sprites.lit(art), at + dock)


## A support out on its own: the drone in the air, rotors spinning, or the cannon on its stand
## facing what it last fired at.
func _draw_support(support: Support) -> void:
	if support.name in ["gun_drone", "net_drone"]:
		var frame := int(_clock * 30.0) % 2
		var art: String = Sprites.DRONE_FRAMES[frame] if support.name == "gun_drone" else Sprites.swapped(Sprites.DRONE_FRAMES[frame], Sprites.NET_DRONE_COLORS)
		draw_texture(Sprites.lit(art), World.to_screen(support.body.position, support.body.height) - Vector2(5, 5))
	elif support.name == "layang_layang":
		# The string from his paw up to the kite, then the kite, tilting as it flies.
		var holder: Cat = null
		for cat in arena.cats:
			if cat.supports.get("drone") == support:
				holder = cat
		var kite_at := World.to_screen(support.body.position, support.body.height)
		if holder != null:
			# The string sagging from his paw to the kite.
			var points := PackedVector2Array()
			for share in range(0, 9):
				var along := share / 8.0
				points.append(World.to_screen(holder.body.position.lerp(support.body.position, along), Support.string_height_at(along)))
			draw_polyline(points, Palette.CREAM)
		draw_texture(Sprites.lit(Sprites.KITE, int(_clock * 2.0) % 2 == 0), kite_at - Vector2(4, 4))
	elif support.name == "bee_swarm":
		# The swarm in the air: bees, each a pixel or two of yellow and black, buzzing about where it is.
		var at := World.to_screen(support.body.position, support.body.height)
		for bee in 7:
			var wobble := Vector2(sin(_clock * 9.0 + bee * 2.1), cos(_clock * 11.0 + bee * 1.7)) * (2.0 + bee % 3)
			draw_rect(Rect2((at + wobble).round(), Vector2(2, 1)), Palette.BRASS_LIGHT if bee % 2 == 0 else Palette.OUTLINE)
	elif support.name == "alarm_drum":
		var art := Sprites.lit(Sprites.ALARM_DRUM)
		# Each beat jolts it.
		var jolt := Vector2(0, -1) if support.beats % 2 == 1 and fmod(_clock, 0.2) < 0.1 else Vector2.ZERO
		draw_texture(art, World.to_screen(support.body.position) - Vector2(art.get_width() / 2, art.get_height() - 1) + jolt)
	elif support.name == "snare":
		if support.snare_at.is_finite():
			var art := Sprites.lit(Sprites.SNARE)
			draw_texture(art, World.to_screen(support.snare_at) - Vector2(art.get_width() / 2, art.get_height() / 2))
	elif support.name == "radio":
		var at := World.to_screen(support.body.position) - Vector2(4, 8)
		draw_texture(Sprites.lit(Sprites.RADIO), at)
		# The sound going out: rings of notes, widening.
		var ring := fmod(_clock * 2.0, 1.0)
		for side in [-1, 1]:
			draw_rect(Rect2(at + Vector2(4 + side * (6 + ring * 8), -2 - ring * 4), Vector2(1, 2)), Palette.PINK)
	elif support.name == "meriam_bambu":
		var left := support.weapon.aim.x < 0.0
		var texture := Sprites.lit(Sprites.MERIAM_BAMBU, left)
		var feet := Vector2(texture.get_width() - 11, 10) if left else Vector2(10, 10)
		draw_texture(texture, World.to_screen(support.body.position) - feet)


## What lies on the ground: burning oil, nails, caltrops, and spike beds.
func _draw_ground_hazards() -> void:
	for fire in arena.fires:
		var count := int(fire.radius * 14.0)
		for index in count:
			var angle: float = TAU * index / count + fire.position.x
			var at: Vector2 = fire.position + Vector2.from_angle(angle) * fire.radius * (0.3 + 0.7 * fmod(index * 0.37, 1.0))
			_draw_flames(at, 0.0, 2)
	for hazard in arena.hazards:
		if hazard.kind == "nail":
			var at := World.to_screen(hazard.position)
			draw_rect(Rect2(at, Vector2(2, 1)), Palette.STEEL_LIGHT)
		elif hazard.kind == "caltrop":
			# A bent nail twisted into four points: one up, lit, and three splayed on the ground.
			var at := World.to_screen(hazard.position).floor()
			draw_rect(Rect2(at + Vector2(-1, 0), Vector2(3, 1)), Palette.STEEL)
			draw_rect(Rect2(at + Vector2(0, -1), Vector2(1, 1)), Palette.STEEL_LIGHT)
			draw_rect(Rect2(at + Vector2(0, 1), Vector2(1, 1)), Palette.STEEL_DARK)
		else:
			var art := Sprites.lit(Sprites.SPIKES)
			draw_texture(art, World.to_screen(hazard.position) - Vector2(art.get_width() / 2, art.get_height() - 1))


## Flames, flickering: a few palette pixels of fire rising off something burning.
func _draw_flames(at: Vector2, height: float, size: int) -> void:
	var base := World.to_screen(at, height)
	for flame in size:
		var flicker := (int(_clock * 12.0) + flame * 7 + int(at.x * 10.0)) % 4
		var x := (flame * 3) % (size * 2 + 1) - size
		draw_rect(Rect2(base + Vector2(x, -flicker - 1), Vector2(1, flicker + 1)), [Palette.SPARK, Palette.BRASS_LIGHT, Palette.HI_VIS, Palette.SCARF_RED][flicker])


## Smoke out of the cannon's mouth as it fires.
func _puff(cannon: Support) -> void:
	var mouth := cannon.body.position + cannon.weapon.aim * 0.3
	for index in 10:
		_droplets.append({
			"position": mouth, "height": 0.25, "rise": randf_range(0.6, 1.6),
			"velocity": cannon.weapon.aim * randf_range(0.5, 1.5) + Vector2(randf_range(-0.4, 0.4), randf_range(-0.4, 0.4)),
			"color": Palette.SMOKE if index % 3 else Palette.SPARK, "stains": false,
		})


## Where each arm reaches, and what it holds. A paw with a gun reaches toward what he's aiming at
## and jolts back as it fires; one with a blade follows the blade round its swing; an empty one
## swings against the stride.
## What he's holding and how. His first weapon is in his mouth, pointing where he aims (or where
## its blade is swinging). His tail curls up from its base and reaches out to hold the second; with
## nothing to hold, or bracing a two-handed weapon, it sways with his walk. Each is drawn behind him
## or over him, as the view puts it.
func _pose_holds(cat: Cat, view: String, flip: bool, frame: int, top_left: Vector2) -> Array[Dictionary]:
	var holds: Array[Dictionary] = []
	var mouth := top_left + Sprites.hold(view, flip, "mouth")
	var held: Weapon = cat.weapons[0] if not cat.weapons.is_empty() else null
	if held != null:
		var pointing := Vector2.from_angle(held.blade_angle) if held.swinging() else cat.aim
		holds.append({"at": (mouth + pointing * (2.0 if held.swinging() else 0.0)).round(), "weapon": held,
			"drawing": Sprites.gun_toward(held.name, pointing), "behind": view == "back" or pointing.y < -0.5, "tail": []})
	# The tail: up and back from its base, then out to what it holds, or swaying.
	var base := top_left + Sprites.hold(view, flip, "tail")
	var back := -1.0 if (view == "side" and not flip) else (1.0 if view == "side" else 0.0)
	var curl := base + Vector2(back * 2.0, -4.0)
	var gripped: Weapon = cat.weapons[1] if cat.weapons.size() > 1 else null
	var tip: Vector2
	if gripped != null:
		var aimed := Vector2.from_angle(gripped.blade_angle) if gripped.swinging() else cat.aim
		tip = (curl + aimed * (Sprites.TAIL_REACH - (2.0 if gripped.kind == Weapon.Kind.RANGED and flash.get(cat, 0.0) > 0.5 else 0.0))).round()
	else:
		var sway: float = [0.0, 1.0, 0.0, -1.0][frame] + sin(_clock * 2.0)
		tip = (curl + Vector2(back * 2.0 + sway, -3.0)).round()
	var tail := {"at": tip, "weapon": gripped, "drawing": Sprites.gun_toward(gripped.name, cat.aim) if gripped != null else {},
		"behind": view != "back", "tail": _limb(base, curl) + _limb(curl, tip), "fur": _tail_fur(cat)}
	holds.append(tail)
	return holds


## His tail's fur: his coat's, and black for Tompel, whose tail is.
func _tail_fur(cat: Cat) -> Color:
	if cat.coat == "tompel":
		return Palette.BLACK_FUR
	return Sprites.LEGEND[(Sprites.COATS.get(cat.coat, Sprites.COATS.orange) as String)[1]]


func _draw_hold(hold: Dictionary) -> void:
	var points: Array = hold.tail
	for point: Vector2 in points:
		draw_rect(Rect2(point - Vector2.ONE, Vector2(3, 3)), Palette.OUTLINE)
	for point: Vector2 in points:
		draw_rect(Rect2(point, Vector2.ONE), hold.fur)
	var weapon: Weapon = hold.weapon
	if weapon == null:
		return
	var drawing: Dictionary = hold.drawing
	var at: Vector2 = hold.at - drawing.grip
	draw_texture(drawing.texture, at)
	if weapon.swinging():
		_draw_smear(weapon, hold.at)
	elif weapon.kind == Weapon.Kind.RANGED and flash.get(arena.cats[0], 0.0) > 0.0:
		draw_rect(Rect2(at + drawing.muzzle - Vector2.ONE, Vector2(3, 3)), Palette.SPARK)


## The pixels of a limb from one point to another, one per step along it.
func _limb(from: Vector2, to: Vector2) -> Array[Vector2]:
	var points: Array[Vector2] = []
	var steps := maxi(int(from.distance_to(to)), 1)
	for step in steps + 1:
		points.append(from.lerp(to, float(step) / steps).round())
	return points


## The blade's path through the air, the last stretch of it: bright at the edge, fading back
## along the arc in palette steps.
func _draw_smear(weapon: Weapon, paw: Vector2) -> void:
	var radius := weapon.reach * World.PIXELS_PER_METER * 0.8
	var trail := 0.9
	var step := 0.07
	var traveled := 0.0
	while traveled < trail:
		var angle := weapon.blade_angle - weapon.swing_direction * traveled
		if weapon.swing_direction * (angle - weapon.swing_start) < 0.0:
			break
		var color := Palette.STEEL_LIGHT if traveled < 0.3 else (Palette.STEEL if traveled < 0.6 else Palette.SMOKE)
		draw_rect(Rect2((paw + Vector2.from_angle(angle) * radius).round(), Vector2.ONE), color)
		traveled += step


## Each hit throws droplets out along it and up. They fall under gravity and stain the ground
## where they land; stains dry, and in time are gone. With blood off, the same hits throw up
## dust and fur, which leave nothing.
func _bleed(delta: float) -> void:
	for event in _pending:
		if event.by in ["lunge", "rev", "cut", "leap", "poison", "fire", "trampled"]:
			continue
		if event.by == "snap" or event.by == "ignite":
			# A bamboo spear splitting, or oil catching: splinters or sparks thrown up.
			for index in 8:
				_droplets.append({
					"position": event.position, "height": 0.2, "rise": randf_range(0.6, 1.8),
					"velocity": Vector2.from_angle(randf() * TAU) * randf_range(0.3, 1.2),
					"color": (Palette.DRY_GRASS if index % 2 else Palette.MOSS) if event.by == "snap" else (Palette.SPARK if index % 2 else Palette.HI_VIS), "stains": false,
				})
			continue
		if event.by == "dust":
			# The dust he kicks up: a low cloud of it, as wide as it reaches, slow to settle.
			var radius: float = event.get("radius", 1.0)
			for index in int(26 * radius):
				_droplets.append({
					"position": event.position + Vector2.from_angle(randf() * TAU) * randf() * radius * 0.6, "height": 0.02,
					"rise": randf_range(0.3, 0.9), "velocity": Vector2.from_angle(randf() * TAU) * randf_range(0.2, 0.9) * radius,
					"color": Palette.DRY_GRASS if index % 3 == 0 else Palette.SMOKE, "stains": false,
				})
			continue
		if event.by == "beat":
			# A beat of the drum: a ring of dust thrown up off the ground, as wide as it shoves.
			var reach: float = event.get("radius", 1.5)
			for index in 20:
				var angle := TAU * index / 20.0
				_droplets.append({
					"position": event.position + Vector2.from_angle(angle) * 0.3, "height": 0.02, "rise": randf_range(0.2, 0.6),
					"velocity": Vector2.from_angle(angle) * reach * randf_range(1.6, 2.2), "color": Palette.SMOKE if index % 2 else Palette.DRY_GRASS, "stains": false,
				})
			continue
		if event.by == "snared":
			# The loop pulled tight: rattan fibers thrown up.
			for index in 6:
				_droplets.append({
					"position": event.position, "height": 0.05, "rise": randf_range(0.4, 1.0),
					"velocity": Vector2.from_angle(randf() * TAU) * randf_range(0.3, 0.8), "color": Palette.LEATHER_LIGHT, "stains": false,
				})
			continue
		if event.by == "slipstream":
			# A crewmate caught in his wake: a streak of air pulled along behind them.
			for index in 5:
				_droplets.append({
					"position": event.position - event.direction * (0.1 + index * 0.08), "height": 0.15 + (index % 2) * 0.1,
					"rise": 0.1, "velocity": event.direction * randf_range(1.0, 2.0), "color": Palette.OFF_WHITE, "stains": false,
				})
			continue
		if event.by == "strike_back":
			# Steel meeting what came for him: sparks all round, nothing that stains.
			for index in 14:
				_droplets.append({
					"position": event.position, "height": event.height, "rise": randf_range(0.2, 1.4),
					"velocity": Vector2.from_angle(TAU * index / 14.0) * randf_range(1.5, 3.0),
					"color": Palette.SPARK if index % 2 else Palette.STEEL_LIGHT, "stains": false,
				})
			continue
		if event.by == "blast":
			# Earth and smoke thrown up, and a flash, as wide as the blast; no blood of its own.
			var radius: float = event.get("radius", 1.0)
			for index in int(16 * radius) + 6:
				_droplets.append({
					"position": event.position, "height": 0.02, "rise": randf_range(1.0, 3.0),
					"velocity": Vector2.from_angle(randf() * TAU) * randf_range(0.5, 2.5) * radius,
					"color": [Palette.SMOKE, Palette.MUD_LIGHT, Palette.SPARK][index % 3], "stains": false,
				})
			continue
		if event.by == "crack" or event.by == "set_down":
			# Bamboo splitting, or set down on the ground: splinters, or a little dust.
			var cracking: bool = event.by == "crack"
			for index in 12 if cracking else 5:
				_droplets.append({
					"position": event.position, "height": 0.1, "rise": randf_range(0.5, 1.8),
					"velocity": Vector2.from_angle(randf() * TAU) * randf_range(0.3, 1.2),
					"color": (Palette.DRY_GRASS if index % 2 else Palette.MOSS) if cracking else Palette.SMOKE, "stains": false,
				})
			continue
		if event.by == "jaws_shut":
			# Wood chips and earth thrown up where the jaws came down.
			for index in 16:
				_droplets.append({
					"position": event.position, "height": 0.05, "rise": randf_range(0.8, 2.4),
					"velocity": Vector2.from_angle(randf() * TAU) * randf_range(0.4, 1.6),
					"color": [Palette.DRY_GRASS, Palette.MUD_LIGHT, Palette.BARK_LIGHT][index % 3], "stains": false,
				})
			continue
		if event.get("kind", "") == "machine" or event.get("kind", "") == "joint":
			# Steel throws sparks, not blood; the open joint bleeds dark hydraulic fluid.
			var fluid: bool = event.kind == "joint"
			for index in 6 if fluid else 4:
				_droplets.append({
					"position": event.position, "height": event.height, "rise": randf_range(0.3, 1.4),
					"velocity": event.direction * randf_range(-1.2, -0.3) + Vector2(randf_range(-0.8, 0.8), randf_range(-0.8, 0.8)),
					"color": Palette.BURNT if fluid else (Palette.SPARK if index % 2 else Palette.STEEL_LIGHT), "stains": false,
				})
			continue
		if event.by == "cage_open":
			for index in 8:
				_droplets.append({
					"position": event.position, "height": 0.3, "rise": randf_range(0.6, 1.6),
					"velocity": Vector2.from_angle(randf() * TAU) * randf_range(0.4, 1.2),
					"color": Palette.STEEL_LIGHT if index % 2 else Palette.SPARK, "stains": false,
				})
			continue
		if event.by == "pickup":
			for index in 3:
				_droplets.append({
					"position": event.position, "height": 0.15, "rise": randf_range(0.8, 1.4),
					"velocity": Vector2(randf_range(-0.3, 0.3), randf_range(-0.3, 0.3)), "color": Palette.SPARK, "stains": false,
				})
			continue
		if event.by == "landing":
			for index in 8:
				_droplets.append({
					"position": event.position, "height": 0.02, "rise": randf_range(0.4, 1.0),
					"velocity": Vector2.from_angle(randf() * TAU) * randf_range(0.4, 1.2),
					"color": Palette.SMOKE, "stains": false,
				})
			continue
		if event.by == "stomp" or event.by == "fall":
			# The ground thrown up: dust and clods, no blood.
			for index in 18:
				_droplets.append({
					"position": event.position, "height": 0.02, "rise": randf_range(0.8, 2.0),
					"velocity": Vector2.from_angle(randf() * TAU) * randf_range(0.5, 2.0),
					"color": Palette.SMOKE if index % 3 else Palette.MUD_LIGHT, "stains": false,
				})
			continue
		var count := 6 if event.killed else 3
		for index in count:
			var spray: Vector2 = event.direction * randf_range(0.4, 1.4) + Vector2(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5))
			_droplets.append({
				"position": event.position, "height": event.height, "velocity": spray, "rise": randf_range(0.4, 1.6),
				"color": Palette.BLOOD if blood else (Palette.RAT_LIGHT if index % 2 == 0 else Palette.SMOKE),
				"stains": blood,
			})
	_pending.clear()
	var flying: Array[Dictionary] = []
	for droplet in _droplets:
		if droplet.get("floats", false):
			# Smoke rises on warm air, drifts, and thins out.
			droplet.life -= delta
			droplet.height += droplet.rise * delta
			droplet.position += droplet.velocity * delta
			if droplet.life > 0.0:
				flying.append(droplet)
			continue
		droplet.rise -= Body.GRAVITY * delta
		droplet.height += droplet.rise * delta
		droplet.position += droplet.velocity * delta
		if droplet.height > 0.0:
			flying.append(droplet)
		elif droplet.stains:
			_stains.append({"position": droplet.position, "age": 0.0})
	_droplets = flying
	var lasting: Array[Dictionary] = []
	for stain in _stains:
		stain.age += delta
		if stain.age < STAIN_LASTS:
			lasting.append(stain)
	_stains = lasting
	while _stains.size() > MOST_STAINS:
		_stains.pop_front()


func _kick_dust(body: Body) -> void:
	for index in 2:
		_dust.append({
			"position": body.position + Vector2(randf_range(-0.08, 0.08), randf_range(-0.03, 0.03)),
			"height": 0.01, "velocity": Vector2(randf_range(-0.4, 0.4), randf_range(-0.2, 0.2)),
			"rise": randf_range(0.3, 0.8), "life": randf_range(0.25, 0.5),
		})


## Dust from a roll is real particles: thrown up, falling back, gone when it settles.
func _settle_dust(delta: float) -> void:
	var settling: Array[Dictionary] = []
	for speck in _dust:
		speck.life -= delta
		speck.rise -= Body.GRAVITY * 0.3 * delta
		speck.height = maxf(speck.height + speck.rise * delta, 0.0)
		speck.position += speck.velocity * delta
		if speck.life > 0.0:
			settling.append(speck)
	_dust = settling


## A giant's shadow, stretched along the ground as he falls; and while he winds up a stomp, the
## boot's shadow where it will land, rimmed in hi-vis: the warning.
func _draw_giant_shadow(giant: Giant) -> void:
	var feet := World.to_screen(giant.body.position)
	var lean := giant.fall_direction * Giant.TALL * sin(giant.fall_angle)
	var end := World.to_screen(giant.body.position + lean)
	_thick(feet, end, 8, Palette.GROUND_SHADOW, 0)
	draw_rect(Rect2(feet + Vector2(-11, -2), Vector2(22, 4)), Palette.GROUND_SHADOW)
	if giant.state == Giant.State.REVVING:
		# The saw's arc marked on the ground while he revs: the warning, like the boot's shadow.
		var angle := giant.sweep_center - Giant.SAW_ARC * 0.5
		while angle <= giant.sweep_center + Giant.SAW_ARC * 0.5:
			for reach in [Giant.SAW_REACH, Giant.SAW_REACH * 0.55]:
				draw_rect(Rect2(World.to_screen(giant.body.position + Vector2.from_angle(angle) * reach), Vector2.ONE), Palette.HI_VIS)
			angle += 0.07
	if giant.state == Giant.State.WINDING:
		var boot := World.to_screen(giant.foot)
		var size := Vector2(14, 6) * (1.0 - giant.foot_height / Giant.BOOT_HEIGHT * 0.3)
		draw_rect(Rect2(boot - size / 2.0 - Vector2.ONE, size + Vector2(2, 2)), Palette.HI_VIS, false, 1.0)
		draw_rect(Rect2(boot - size / 2.0, size), Palette.GROUND_SHADOW)


## A logging worker, built as a rig of joints in three dimensions (across his body, up it, and
## forward along the way he faces) and projected the way the scene is. The same rig shows his
## front walking toward the viewer, his back walking away, his side walking across, and
## foreshortens as he topples. Parts draw far to near, so the nearer leg covers the further.
## Legs stride with the ground he covers; arms swing against them.
func _draw_giant(giant: Giant) -> void:
	var phase: float = _walked.get(giant, 0.0) / GIANT_STRIDE * TAU
	var walking := giant.body.velocity.length() > 0.05
	var stride := sin(phase) * 0.32 if walking else 0.0
	var lift := maxf(cos(phase), 0.0) * 0.06 if walking else 0.0
	var dissolve := clampf((giant.fallen_for - (Arena.FELLED_LASTS - 1.5)) / 1.5, 0.0, 1.0)
	var hip := 0.92
	var shoulder := 1.42
	# Each foot: [across, up, forward]. The right boot comes up for a stomp.
	var right_foot := [0.12, lift, stride]
	var left_foot := [-0.12, maxf(-cos(phase), 0.0) * 0.06 if walking else 0.0, -stride]
	if giant.state == Giant.State.WINDING:
		right_foot = [0.12, giant.foot_height, 0.4]
	var parts: Array[Dictionary] = []
	for leg: Array in [[0.12, right_foot, Palette.CLOTH], [-0.12, left_foot, Palette.CLOTH_SHADOW]]:
		var foot: Array = leg[1]
		parts.append(_part(giant, [leg[0], hip, 0.0], foot, 6, leg[2]))
		parts.append(_part(giant, foot, [foot[0], foot[1], foot[2] + 0.14], 5, Palette.LEATHER_LIGHT if leg[0] > 0.0 else Palette.LEATHER))
	for arm: Array in [[0.25, -1.0, Palette.SKIN], [-0.25, 1.0, Palette.SKIN_SHADOW]]:
		# With a chainsaw, both hands are on it, held in front of him.
		var hand: Array = [arm[0] * 0.35, 0.95, 0.35] if giant.has_chainsaw() and giant.standing() else [arm[0] * 1.1, 0.86, stride * 0.6 * arm[1]]
		parts.append(_part(giant, [arm[0], shoulder, 0.0], hand, 4, arm[2]))
	if giant.has_chainsaw():
		_add_chainsaw(giant, parts)
		# Ear defenders over the hard hat's straps.
		for across in [-0.1, 0.1]:
			parts.append(_part(giant, [across, 1.57, 0.02], [across, 1.57, 0.02], 3, Palette.STEEL_DARK, 0.05, 4))
	parts.append(_part(giant, [0.0, hip, 0.0], [0.0, shoulder, 0.0], 14, Palette.HI_VIS))
	# The reflective band across the vest, the head, and the hard hat over it.
	parts.append(_part(giant, [0.0, 1.15, 0.0], [0.0, 1.15, 0.0], 14, Palette.STEEL_LIGHT, 0.01, 2))
	parts.append(_part(giant, [0.0, 1.5, 0.02], [0.0, 1.62, 0.02], 9, Palette.SKIN, 0.02))
	var hat := Palette.CLOTH_SHADOW if giant.kind == "handler" else Palette.BRASS_LIGHT
	parts.append(_part(giant, [0.0, 1.66, 0.02], [0.0, 1.7, 0.02], 11, hat, 0.03, 5))
	parts.append(_part(giant, [0.0, 1.64, -0.06], [0.0, 1.64, 0.16], 3, Palette.CLOTH if giant.kind == "handler" else Palette.BRASS, 0.04))
	if giant.kind == "handler":
		# The whistle on its cord at his chest.
		parts.append(_part(giant, [0.0, 1.4, 0.12], [0.0, 1.32, 0.12], 2, Palette.STEEL_LIGHT, 0.05))
	parts.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.depth < b.depth)
	for part in parts:
		_thick(part.from, part.to, part.width, part.color, dissolve, part.tall)
	for bar in _running_chain:
		var points := _limb(bar.from, bar.to)
		var shift := int(Time.get_ticks_msec() / 30) % 2
		for index in points.size():
			if (index + shift) % 2 == 0:
				draw_rect(Rect2(points[index] - Vector2(0, 2), Vector2.ONE), Palette.STEEL_LIGHT)
	_running_chain.clear()
	# Seen from the front, his eyes under the brim.
	if giant.facing.y > 0.35 and giant.standing():
		for across in [-0.04, 0.04]:
			draw_rect(Rect2(_giant_point(giant, across, 1.6, 0.09), Vector2.ONE), Palette.OUTLINE)
	if giant.standing() and giant.health < giant.most_health:
		var top := _giant_point(giant, 0.0, 1.88, 0.0)
		var share := giant.health / giant.most_health
		draw_rect(Rect2(top + Vector2(-12, 0), Vector2(24, 3)), Palette.GRAPHITE)
		draw_rect(Rect2(top + Vector2(-11, 1), Vector2(roundf(22 * share), 1)), Palette.HI_VIS)


## The chainsaw, from his hands to the tip of its bar: forward and down as he walks, raised as he
## revs, and low along the ground, following the sweep, as he cuts. The chain's teeth run along
## the bar while it's going.
func _add_chainsaw(giant: Giant, parts: Array[Dictionary]) -> void:
	if not giant.standing():
		return
	var handle_ground := _giant_ground(giant, 0.0, 0.95, 0.35)
	var handle_height := 0.95
	var tip_ground: Vector2
	var tip_height: float
	match giant.state:
		Giant.State.SWEEPING:
			var along := Vector2.from_angle(giant.saw_angle)
			handle_ground = giant.body.position + along * 0.4
			handle_height = 0.7
			tip_ground = giant.body.position + along * Giant.SAW_REACH
			tip_height = 0.2
		Giant.State.REVVING:
			tip_ground = _giant_ground(giant, 0.0, 1.25, 0.9)
			tip_height = 1.25
		_:
			tip_ground = _giant_ground(giant, 0.0, 0.7, 1.0)
			tip_height = 0.7
	var handle := World.to_screen(handle_ground, handle_height)
	var tip := World.to_screen(tip_ground, tip_height)
	var body_end := handle.lerp(tip, 0.25)
	var depth := (handle_ground.y + tip_ground.y) / 2.0 + 0.06
	parts.append({"from": handle, "to": body_end, "width": 6, "tall": 6, "color": Palette.HI_VIS, "depth": depth})
	parts.append({"from": body_end, "to": tip, "width": 3, "tall": 3, "color": Palette.STEEL, "depth": depth + 0.001})
	if giant.state in [Giant.State.REVVING, Giant.State.SWEEPING]:
		_running_chain.append({"from": body_end, "to": tip})


## A limb of the rig between two joints, with how near the viewer it is: further down the ground
## is nearer.
func _part(giant: Giant, from: Array, to: Array, width: int, color: Color, bias := 0.0, tall := 0) -> Dictionary:
	var middle := (_giant_ground(giant, from[0], from[1], from[2]) + _giant_ground(giant, to[0], to[1], to[2])) / 2.0
	return {
		"from": _giant_point(giant, from[0], from[1], from[2]), "to": _giant_point(giant, to[0], to[1], to[2]),
		"width": width, "tall": tall if tall > 0 else width, "color": color, "depth": middle.y + bias,
	}


## Where a joint stands over the ground: across his body, forward along his facing, and tipped
## over by his fall.
func _giant_ground(giant: Giant, across: float, up: float, forward: float) -> Vector2:
	var side := giant.facing.orthogonal()
	if side.y < 0.0:
		side = -side
	return giant.body.position + giant.facing * forward + side * across + giant.fall_direction * up * sin(giant.fall_angle)


func _giant_point(giant: Giant, across: float, up: float, forward: float) -> Vector2:
	return World.to_screen(_giant_ground(giant, across, up, forward), up * cos(giant.fall_angle))


## A thick limb from one point to another, outlined. Remains dissolving drop pixels in a fixed
## scatter as the stage goes from 0 to 1.
func _thick(from: Vector2, to: Vector2, width: int, color: Color, dissolve: float, tall := 0) -> void:
	var points := _limb(from, to)
	var size := Vector2(width, tall if tall > 0 else width)
	var half := size / 2.0
	for point in points:
		draw_rect(Rect2((point - half - Vector2.ONE).round(), size + Vector2(2, 2)), Palette.OUTLINE)
	for point in points:
		if dissolve > 0.0 and float(int(point.x * 7 + point.y * 13) % 17) / 17.0 < dissolve:
			continue
		draw_rect(Rect2((point - half).round(), size), color)
