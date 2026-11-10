class_name PixelArtFactory
extends RefCounted

const ROOT := "res://assets/ninja_adventure/"


static func build_assets() -> Dictionary:
	var enemies := {
		"ghost": _atlas_row(ROOT + "actors/ghost.png", Vector2i(16, 16), 0, 4),
		"paper": _atlas_row(ROOT + "actors/paper.png", Vector2i(16, 16), 0, 4),
		"stone": _atlas_row(ROOT + "actors/stone.png", Vector2i(16, 16), 0, 4),
		"lantern": _atlas_row(ROOT + "actors/lantern.png", Vector2i(16, 16), 0, 4),
		"jiangshi": _atlas_row(ROOT + "actors/jiangshi.png", Vector2i(16, 16), 0, 4),
		"splitter": _atlas_row(ROOT + "actors/splitter.png", Vector2i(16, 16), 0, 4),
		"wisp": _atlas_row(ROOT + "actors/wisp.png", Vector2i(16, 16), 0, 4),
		"algae_drowned": _atlas_row(ROOT + "actors/axolot.png", Vector2i(16, 16), 0, 4),
		"river_lantern": _atlas_row(ROOT + "actors/butterfly_blue.png", Vector2i(16, 16), 0, 4),
		"headless_boatman": _atlas_row(ROOT + "actors/kappa_green.png", Vector2i(16, 16), 0, 4),
		"soul_netter": _atlas_row(ROOT + "actors/octopus_green.png", Vector2i(16, 16), 0, 4),
		"leech_medium": _atlas_row(ROOT + "actors/fish.png", Vector2i(16, 16), 0, 4),
		"snow_stalker": _atlas_row(ROOT + "actors/bear.png", Vector2i(16, 16), 0, 4),
		"ice_coffin": _atlas_row(ROOT + "actors/spider_yellow.png", Vector2i(16, 16), 0, 4),
		"gale_wraith": _atlas_row(ROOT + "actors/bat_blue.png", Vector2i(16, 16), 0, 4),
		"frost_jailer": _atlas_row(ROOT + "actors/mouse_black.png", Vector2i(16, 16), 0, 4),
	}
	var bosses := [
		_atlas_row(ROOT + "bosses/demon_cyclop.png", Vector2i(50, 50), 0, 5),
		_atlas_row(ROOT + "bosses/giant_spirit.png", Vector2i(50, 50), 0, 5),
		_atlas_row(ROOT + "bosses/giant_samurai.png", Vector2i(48, 48), 0, 12),
		_atlas_row(ROOT + "bosses/squid_green.png", Vector2i(76, 79), 0, 4),
		_atlas_row(ROOT + "bosses/tengu_blue.png", Vector2i(68, 68), 0, 6),
	]
	var floors := [
		_tiled_floor(ROOT + "tiles/field.png", Rect2i(16, 64, 16, 16)),
		_tiled_floor(ROOT + "tiles/field.png", Rect2i(16, 112, 16, 16)),
		_tiled_floor(ROOT + "tiles/interior_floor.png", Rect2i(192, 224, 16, 16)),
		_tiled_floor(ROOT + "tiles/water_village.png", Rect2i(112, 224, 16, 16)),
		_tiled_floor(ROOT + "tiles/snow_mountain.png", Rect2i(16, 16, 16, 16)),
	]
	return {
		"player": _atlas_row(ROOT + "actors/player_walk.png", Vector2i(32, 32), 0, 4),
		"enemies": enemies,
		"bosses": bosses,
		"weapons": {
			"sword": load(ROOT + "items/sword.png"),
			"talisman": load(ROOT + "items/talisman.png"),
			"coin": load(ROOT + "items/coin.png"),
			"paper_doll": load(ROOT + "items/book.png"),
			"orb": load(ROOT + "items/wand.png"),
			"tide_gourd": load(ROOT + "items/axe.png"),
			"ferry_oar": load(ROOT + "items/lance.png"),
			"nether_lotus": load(ROOT + "items/sai.png"),
			"ice_needles": load(ROOT + "items/bow.png"),
			"frost_stele": load(ROOT + "items/hammer.png"),
			"snow_umbrella": load(ROOT + "items/whip.png"),
			"judge_brush": load(ROOT + "equipment/weapon_kunai.png"),
			"soul_lantern": load(ROOT + "equipment/weapon_magic.png"),
			"chest": load(ROOT + "items/chest.png"),
		},
		"equipment": {
			"weapon": [
				load(ROOT + "equipment/weapon_sword.png"),
				load(ROOT + "equipment/weapon_talisman.png"),
				load(ROOT + "equipment/weapon_thunder.png"),
				load(ROOT + "equipment/charm.png"),
				load(ROOT + "equipment/weapon_coin.png"),
				load(ROOT + "equipment/weapon_orb.png"),
				load(ROOT + "equipment/weapon_arrow.png"),
				load(ROOT + "equipment/weapon_kunai.png"),
				load(ROOT + "equipment/weapon_magic.png"),
			],
			"head": load(ROOT + "equipment/head.png"),
			"robe": load(ROOT + "equipment/robe.png"),
			"belt": load(ROOT + "equipment/belt.png"),
			"boots": load(ROOT + "equipment/boots.png"),
			"charm": load(ROOT + "equipment/charm.png"),
		},
		"equipment_new": {
			"head": [load(ROOT + "equipment/head_vision.png"), load(ROOT + "equipment/head_alchemy.png"), load(ROOT + "equipment/head_necromancy.png")],
			"robe": [load(ROOT + "equipment/robe_defense.png"), load(ROOT + "equipment/robe_camouflage.png"), load(ROOT + "equipment/robe_counter.png")],
			"belt": [load(ROOT + "equipment/belt_attack.png"), load(ROOT + "equipment/belt_luck.png"), load(ROOT + "equipment/belt_upgrade.png")],
			"boots": [load(ROOT + "equipment/boots_mist.png"), load(ROOT + "equipment/boots_permutation.png"), load(ROOT + "equipment/boots_water.png")],
			"charm": [load(ROOT + "equipment/charm_darkness.png"), load(ROOT + "equipment/charm_fire.png"), load(ROOT + "equipment/charm_water.png")],
		},
		"audio": {
			"weapon": load(ROOT + "audio/weapon.wav"),
			"weapon_sword": load(ROOT + "audio/weapon.wav"),
			"weapon_talisman": load(ROOT + "audio/weapon_talisman.wav"),
			"weapon_thunder": load(ROOT + "audio/weapon_thunder.wav"),
			"weapon_bell": load(ROOT + "audio/weapon_bell.wav"),
			"weapon_coin": load(ROOT + "audio/weapon_coin.wav"),
			"weapon_orb": load(ROOT + "audio/weapon_orb.wav"),
			"weapon_chain": load(ROOT + "audio/weapon_chain.wav"),
			"weapon_banner": load(ROOT + "audio/weapon_banner.wav"),
			"weapon_paper_doll": load(ROOT + "audio/weapon_paper_doll.wav"),
			"weapon_mirror": load(ROOT + "audio/weapon_mirror.wav"),
			"weapon_tide_gourd": load(ROOT + "audio/weapon_tide_gourd.wav"),
			"weapon_ferry_oar": load(ROOT + "audio/weapon_ferry_oar.wav"),
			"weapon_nether_lotus": load(ROOT + "audio/weapon_nether_lotus.wav"),
			"weapon_ice_needles": load(ROOT + "audio/weapon_ice_needles.wav"),
			"weapon_frost_stele": load(ROOT + "audio/weapon_frost_stele.wav"),
			"weapon_snow_umbrella": load(ROOT + "audio/weapon_snow_umbrella.wav"),
			"weapon_judge_brush": load(ROOT + "audio/weapon_talisman.wav"),
			"weapon_soul_lantern": load(ROOT + "audio/weapon_nether_lotus.wav"),
			"evolution": load(ROOT + "audio/evolution.wav"),
			"hit": load(ROOT + "audio/hit.wav"),
			"death": load(ROOT + "audio/death.wav"),
			"hurt": load(ROOT + "audio/hurt.wav"),
			"pickup": load(ROOT + "audio/pickup.wav"),
			"level_up": load(ROOT + "audio/level_up.wav"),
			"purchase": load(ROOT + "audio/purchase.wav"),
			"boss": load(ROOT + "audio/boss.wav"),
			"menu": load(ROOT + "audio/menu.wav"),
			"music": load(ROOT + "audio/fight.ogg"),
			"stage_music": [
				load(ROOT + "audio/stage_village.ogg"),
				load(ROOT + "audio/stage_grave.ogg"),
				load(ROOT + "audio/stage_temple.ogg"),
				load(ROOT + "audio/stage_water_village.ogg"),
				load(ROOT + "audio/stage_snow_mountain.ogg"),
			],
			"stage_ambient": [
				load(ROOT + "audio/ambient_village.wav"),
				load(ROOT + "audio/ambient_grave.wav"),
				load(ROOT + "audio/ambient_temple.wav"),
				load(ROOT + "audio/ambient_water_village.wav"),
				load(ROOT + "audio/ambient_snow_mountain.wav"),
			],
		},
		"floors": floors,
		"menu_background": _menu_background(floors[0]),
		"ui": {
			"button_normal": load(ROOT + "ui/button_normal.png"),
			"button_hover": load(ROOT + "ui/button_hover.png"),
			"button_pressed": load(ROOT + "ui/button_pressed.png"),
			"button_disabled": load(ROOT + "ui/button_disabled.png"),
			"panel": load(ROOT + "ui/panel.png"),
			"inventory_cell": load(ROOT + "ui/inventory_cell.png"),
			"progress_health": load(ROOT + "ui/progress_health.png"),
			"progress_white": load(ROOT + "ui/progress_white.png"),
		},
	}


static func _atlas_row(path: String, frame_size: Vector2i, row: int, count: int) -> Array[AtlasTexture]:
	var texture: Texture2D = load(path)
	var frames: Array[AtlasTexture] = []
	for column in count:
		var frame := AtlasTexture.new()
		frame.atlas = texture
		frame.region = Rect2(column * frame_size.x, row * frame_size.y, frame_size.x, frame_size.y)
		frames.append(frame)
	return frames


static func _tiled_floor(path: String, region: Rect2i) -> ImageTexture:
	var source: Texture2D = load(path)
	var source_image := source.get_image()
	var tile := source_image.get_region(region)
	var image := Image.create(1800, 1200, false, Image.FORMAT_RGBA8)
	for y in range(0, 1200, 16):
		for x in range(0, 1800, 16):
			image.blit_rect(tile, Rect2i(0, 0, 16, 16), Vector2i(x, y))
	return ImageTexture.create_from_image(image)


static func _menu_background(floor_texture: ImageTexture) -> ImageTexture:
	var image := floor_texture.get_image().get_region(Rect2i(0, 0, 640, 360))
	var village: Texture2D = load(ROOT + "tiles/village_abandoned.png")
	var village_image := village.get_image()
	image.fill_rect(Rect2i(250, 0, 142, 360), Color("494331"))
	image.fill_rect(Rect2i(210, 205, 235, 155), Color("514735"))
	for y in range(8, 360, 16):
		var offset := 8 if y % 32 == 0 else 0
		for x in range(258 + offset, 390, 24):
			image.fill_rect(Rect2i(x, y, 5, 3), Color("625640"))
	_blend_scaled(image, village_image, Rect2i(221, 0, 52, 100), Vector2i(448, 37), 2)
	_blend_scaled(image, village_image, Rect2i(190, 112, 72, 78), Vector2i(315, 184), 2)
	_blend_scaled(image, village_image, Rect2i(0, 96, 65, 56), Vector2i(-8, 190), 2)
	_blend_scaled(image, village_image, Rect2i(63, 145, 47, 47), Vector2i(548, 244), 2)
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			image.set_pixel(x, y, Color(color.r * 0.48, color.g * 0.55, color.b * 0.62, color.a))
	return ImageTexture.create_from_image(image)


static func _blend_scaled(target: Image, source: Image, source_rect: Rect2i, position: Vector2i, scale: int) -> void:
	var sprite := source.get_region(source_rect)
	sprite.resize(sprite.get_width() * scale, sprite.get_height() * scale, Image.INTERPOLATE_NEAREST)
	target.blend_rect(sprite, Rect2i(Vector2i.ZERO, sprite.get_size()), position)
