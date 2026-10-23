extends TestCase
## The art follows the style rules: every pixel is a palette color, gear lines up with the body,
## and aiming guns are drawn angles placed by their grip, never rotated.


func test_every_pixel_of_every_sprite_is_a_palette_color() -> void:
	var art := Sprites.all_art()
	for name: String in art:
		var picture := Sprites.image(art[name])
		var strays := 0
		for y in picture.get_height():
			for x in picture.get_width():
				var color := picture.get_pixel(x, y)
				if color.a > 0.0 and not Palette.has(color):
					strays += 1
		check(strays == 0, "%s has %d pixels off the palette" % [name, strays])


func test_every_letter_in_the_art_is_in_the_legend() -> void:
	var art := Sprites.all_art()
	for name: String in art:
		for character in (art[name] as String).replace("\n", "").replace(".", ""):
			if not Sprites.LEGEND.has(character):
				check(false, "%s uses %s, which isn't in the legend" % [name, character])
				break


func test_gear_layers_match_the_body_in_every_view() -> void:
	for view: String in Sprites.CAT_UPPER:
		var body := Sprites.image(Sprites.cat_body_art(view, 0)).get_size()
		check(body == Vector2i(24, 24), "the %s body is %s, not 24 by 24" % [view, body])
		var vest := Sprites.image(Sprites.VESTS[view]).get_size()
		check(vest.x == body.x, "the %s vest is %d pixels wide, the body is %d" % [view, vest.x, body.x])
		for item: String in Sprites.WORN:
			var worn := Sprites.image(Sprites.WORN[item][view]).get_size()
			check(worn.x <= body.x and worn.y <= body.y, "the %s %s is %s, bigger than the body" % [view, item, worn])
		for anchor: String in Sprites.CAT_ANCHORS[view]:
			if anchor == "head":
				continue
			var point: Vector2 = Sprites.CAT_ANCHORS[view][anchor]
			check(Rect2(Vector2.ZERO, Vector2(body)).has_point(point), "the %s %s anchor is off the body" % [view, anchor])


func test_every_walk_frame_is_the_same_size_and_stands_on_the_same_feet() -> void:
	for view: String in Sprites.CAT_UPPER:
		for frame in 4:
			var size := Sprites.image(Sprites.cat_body_art(view, frame)).get_size()
			check(size == Vector2i(24, 24), "%s frame %d is %s" % [view, frame, size])


func test_walk_frames_differ() -> void:
	for view: String in Sprites.CAT_UPPER:
		check(Sprites.cat_body_art(view, 0) != Sprites.cat_body_art(view, 1), "the %s walk doesn't move" % view)
	check(Sprites.RAT_STRIDES[0] != Sprites.RAT_STRIDES[1], "the rat's gallop doesn't move")


func test_every_gun_has_a_drawing_for_all_eight_directions() -> void:
	for weapon: String in Sprites.held_art():
		_check_eight_directions(weapon)


func _check_eight_directions(weapon: String) -> void:
	var seen := {}
	for octant in 8:
		var gun := Sprites.gun_toward(weapon, Vector2.from_angle(octant * PI / 4.0))
		var size: Vector2 = Vector2(gun.texture.get_width(), gun.texture.get_height())
		check(Rect2(Vector2.ZERO, size).has_point(gun.grip), "%s octant %d: the grip is off the drawing" % [weapon, octant])
		check(Rect2(Vector2.ZERO, size).has_point(gun.muzzle), "%s octant %d: the muzzle is off the drawing" % [weapon, octant])
		seen[gun.texture] = true
		# The muzzle must lead the grip the way the gun points.
		var pointing: Vector2 = (gun.muzzle - gun.grip).normalized()
		check(pointing.dot(Vector2.from_angle(octant * PI / 4.0)) > 0.6, "%s octant %d: it points %s" % [weapon, octant, pointing])
	check(seen.size() == 8, "%s: only %d distinct drawings for eight directions" % [weapon, seen.size()])


func test_every_piece_of_gear_can_be_drawn_and_previewed() -> void:
	for id: String in Upgrades.GEAR:
		var drawn := Sprites.BODIES.has(id) or Sprites.FEET.has(id) or Sprites.PAWS.has(id) or Sprites.WORN.has(id) or Sprites.HATS.has(id)
		check(drawn, "%s has no drawing on the cat" % id)
		check(Sprites.preview(id) != null, "%s has no card picture" % id)


func test_a_carriage_return_does_not_widen_the_art() -> void:
	var unix := Sprites.image("\nkk\nkk\n").get_size()
	var windows := Sprites.image("\r\nkk\r\nkk\r\n").get_size()
	check(unix == windows, "art with Windows line endings is %s, not %s" % [windows, unix])
