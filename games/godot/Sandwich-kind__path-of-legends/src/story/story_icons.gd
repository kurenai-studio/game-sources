class_name StoryIcons
# ---------- Значки Истории (32×32) ----------
# Предметы инвентаря, способности из свитков и кнопки управления героя.
# Рисуются кодом теми же кистями, что и значки легенд (AbilityIcons).


static func draw(id: String):
	var im := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var steel := Color(0.78, 0.8, 0.86)
	var dsteel := Color(0.52, 0.54, 0.60)
	var wood := Color(0.58, 0.38, 0.2)
	var leather := Color(0.55, 0.36, 0.22)
	var gold := Color(1.0, 0.8, 0.3)
	match id:
		# ----- одежда и броня -----
		"leather_shirt":
			_shirt(im, leather, leather.darkened(0.25))
			AbilityIcons._line(im, Vector2(16, 9), Vector2(16, 18), leather.darkened(0.4), 1)
		"chainmail":
			_shirt(im, dsteel, dsteel.darkened(0.3))
			for y in range(8, 27, 2):
				for x in range(7 + (y % 4) / 2, 26, 2):
					if im.get_pixel(x, y).a > 0.0:
						AbilityIcons._px(im, x, y, steel)
			AbilityIcons._rect(im, 8, 24, 16, 2, Color(0.35, 0.22, 0.12))
		"leather_pants":
			_pants(im, Color(0.40, 0.28, 0.18))
		"guard_greaves":
			_pants(im, Color(0.30, 0.30, 0.36))
			AbilityIcons._rect(im, 9, 17, 5, 4, steel)
			AbilityIcons._rect(im, 18, 17, 5, 4, steel)
		"iron_helm":
			AbilityIcons._disc(im, 16, 17, 10, dsteel)
			AbilityIcons._rect(im, 6, 17, 21, 11, Color(0, 0, 0, 0))
			AbilityIcons._rect(im, 6, 16, 20, 3, steel)
			AbilityIcons._rect(im, 15, 17, 3, 9, steel)                  # наносник
			AbilityIcons._rect(im, 6, 18, 4, 9, dsteel.darkened(0.15))
			AbilityIcons._rect(im, 22, 18, 4, 9, dsteel.darkened(0.15))
			AbilityIcons._px(im, 12, 10, Color(1, 1, 1))
		"leather_boots":
			for x0 in [5, 17]:
				AbilityIcons._rect(im, x0, 6, 7, 16, Color(0.32, 0.20, 0.12))
				AbilityIcons._rect(im, x0, 20, 11, 6, Color(0.32, 0.20, 0.12))
				AbilityIcons._rect(im, x0, 6, 7, 2, Color(0.45, 0.30, 0.18))
				AbilityIcons._rect(im, x0, 25, 11, 1, Color(0.18, 0.12, 0.08))
		"leather_gloves":
			for x0 in [4, 17]:
				AbilityIcons._rect(im, x0, 12, 10, 13, Color(0.45, 0.30, 0.18))
				for k in 4:
					AbilityIcons._rect(im, x0 + k * 2 + 1, 7 + (k % 2), 2, 6, Color(0.45, 0.30, 0.18))
				AbilityIcons._rect(im, x0, 22, 10, 3, Color(0.35, 0.22, 0.12))
		"traveler_cape":
			AbilityIcons._poly(im, PackedVector2Array([Vector2(10, 4), Vector2(22, 4), Vector2(28, 28), Vector2(4, 28)]), Color(0.25, 0.35, 0.55))
			AbilityIcons._poly(im, PackedVector2Array([Vector2(14, 4), Vector2(18, 4), Vector2(17, 28), Vector2(15, 28)]), Color(0.20, 0.28, 0.45))
			AbilityIcons._rect(im, 10, 4, 12, 3, gold)
		"copper_ring":
			AbilityIcons._ring(im, 16, 18, 8, Color(0.85, 0.5, 0.28), 3.0)
			AbilityIcons._disc(im, 16, 9, 4, Color(0.4, 0.8, 1.0))
			AbilityIcons._px(im, 15, 8, Color(1, 1, 1))
		"fang_amulet":
			AbilityIcons._line(im, Vector2(6, 4), Vector2(16, 16), Color(0.45, 0.30, 0.18), 1)
			AbilityIcons._line(im, Vector2(26, 4), Vector2(16, 16), Color(0.45, 0.30, 0.18), 1)
			AbilityIcons._poly(im, PackedVector2Array([Vector2(12, 15), Vector2(20, 15), Vector2(16, 29)]), Color(0.95, 0.92, 0.82))
			AbilityIcons._disc(im, 16, 15, 3, Color(0.8, 0.2, 0.2))
		# ----- оружие -----
		"short_sword", "h_sword":
			AbilityIcons._line(im, Vector2(9, 23), Vector2(26, 6), steel, 3)
			AbilityIcons._line(im, Vector2(10, 23), Vector2(26, 7), Color(1, 1, 1), 1)
			AbilityIcons._line(im, Vector2(6, 19), Vector2(13, 26), Color(0.8, 0.6, 0.25), 2)
			AbilityIcons._line(im, Vector2(4, 28), Vector2(9, 23), Color(0.4, 0.25, 0.12), 2)
		"rogue_dagger", "h_dagger":
			AbilityIcons._poly(im, PackedVector2Array([Vector2(13, 18), Vector2(25, 6), Vector2(27, 8), Vector2(16, 20)]), steel)
			AbilityIcons._line(im, Vector2(15, 19), Vector2(25, 8), Color(1, 1, 1), 1)
			AbilityIcons._line(im, Vector2(10, 16), Vector2(17, 23), dsteel, 2)
			AbilityIcons._line(im, Vector2(6, 26), Vector2(12, 20), Color(0.25, 0.16, 0.12), 3)
		"hunting_bow", "h_bow":
			for y in range(3, 29):
				var bx := 9 + int(7.0 * sin(PI * (y - 3) / 25.0))
				AbilityIcons._rect(im, bx, y, 2, 1, wood)
			AbilityIcons._line(im, Vector2(9, 3), Vector2(9, 28), Color(0.95, 0.93, 0.85), 1)
			AbilityIcons._rect(im, 14, 14, 2, 4, Color(0.3, 0.45, 0.25))
		"sling", "h_sling":
			AbilityIcons._line(im, Vector2(4, 4), Vector2(14, 20), Color(0.55, 0.4, 0.22), 1)
			AbilityIcons._line(im, Vector2(28, 4), Vector2(18, 20), Color(0.55, 0.4, 0.22), 1)
			AbilityIcons._disc(im, 16, 22, 6, leather)
			AbilityIcons._disc(im, 16, 21, 3, Color(0.6, 0.6, 0.62))
		"h_fist":
			AbilityIcons._rect(im, 9, 10, 15, 13, Color(0.93, 0.74, 0.58))
			for k in 4:
				AbilityIcons._rect(im, 9 + k * 4, 8, 3, 5, Color(0.98, 0.82, 0.66))
			AbilityIcons._rect(im, 6, 14, 4, 7, Color(0.88, 0.68, 0.52))
			AbilityIcons._rect(im, 10, 22, 13, 5, Color(0.55, 0.38, 0.24))
		"h_noranged":
			AbilityIcons._ring(im, 16, 16, 10, Color(0.8, 0.8, 0.8, 0.5), 2.0)
			AbilityIcons._line(im, Vector2(9, 23), Vector2(23, 9), Color(0.8, 0.8, 0.8, 0.5), 2)
		"h_interact":
			AbilityIcons._rect(im, 9, 12, 13, 14, Color(0.93, 0.74, 0.58))
			AbilityIcons._rect(im, 12, 3, 4, 12, Color(0.98, 0.82, 0.66))             # указательный палец
			AbilityIcons._rect(im, 17, 9, 3, 5, Color(0.93, 0.74, 0.58))
			AbilityIcons._rect(im, 21, 11, 3, 5, Color(0.93, 0.74, 0.58))
			AbilityIcons._rect(im, 6, 15, 4, 6, Color(0.88, 0.68, 0.52))
			AbilityIcons._ring(im, 14, 5, 5, gold, 1.5)
		# ----- снаряды -----
		"arrows":
			for k in 3:
				var x := 9 + k * 6
				AbilityIcons._line(im, Vector2(x, 28), Vector2(x + 4, 8), wood, 1)
				AbilityIcons._poly(im, PackedVector2Array([Vector2(x + 2, 9), Vector2(x + 5, 2), Vector2(x + 7, 10)]), steel)
				AbilityIcons._rect(im, x - 1, 24, 3, 4, Color(0.9, 0.3, 0.2))
		"stones":
			for c in [[10, 20, 5], [21, 22, 5], [16, 13, 5]]:
				AbilityIcons._disc(im, c[0], c[1], c[2], Color(0.55, 0.55, 0.58))
				AbilityIcons._px(im, c[0] - 1, c[1] - 2, Color(0.8, 0.8, 0.82))
		# ----- свитки -----
		"scroll_fireball", "scroll_dash", "scroll_heal", "scroll_rage":
			var seals := {"scroll_fireball": Color(1.0, 0.45, 0.15), "scroll_dash": Color(0.6, 0.85, 1.0),
					"scroll_heal": Color(0.45, 1.0, 0.5), "scroll_rage": Color(0.85, 0.2, 0.25)}
			var seal: Color = seals[id]
			AbilityIcons._rect(im, 6, 7, 20, 18, Color(0.93, 0.86, 0.66))
			AbilityIcons._rect(im, 4, 5, 24, 4, Color(0.80, 0.70, 0.48))
			AbilityIcons._rect(im, 4, 23, 24, 4, Color(0.80, 0.70, 0.48))
			for y in [12, 15, 18]:
				AbilityIcons._rect(im, 9, y, 14, 1, Color(0.55, 0.42, 0.28))
			AbilityIcons._disc(im, 22, 20, 4, seal)
			AbilityIcons._px(im, 21, 19, seal.lightened(0.5))
		# ----- зелья -----
		"potion_hp", "potion_mana":
			var liq := Color(0.9, 0.15, 0.2) if id == "potion_hp" else Color(0.25, 0.45, 1.0)
			AbilityIcons._disc(im, 16, 20, 9, Color(0.75, 0.85, 0.9, 0.6))
			AbilityIcons._disc(im, 16, 21, 7, liq)
			AbilityIcons._rect(im, 13, 5, 6, 8, Color(0.75, 0.85, 0.9, 0.6))
			AbilityIcons._rect(im, 12, 3, 8, 3, Color(0.55, 0.38, 0.2))
			AbilityIcons._px(im, 13, 17, Color(1, 1, 1))
			AbilityIcons._px(im, 12, 18, Color(1, 1, 1))
		# ----- ключ -----
		"old_key":
			AbilityIcons._ring(im, 9, 10, 6, Color(0.70, 0.55, 0.30), 3.0)
			AbilityIcons._line(im, Vector2(13, 14), Vector2(26, 27), Color(0.70, 0.55, 0.30), 2)
			AbilityIcons._rect(im, 21, 23, 3, 5, Color(0.70, 0.55, 0.30))
			AbilityIcons._rect(im, 25, 20, 3, 4, Color(0.70, 0.55, 0.30))
			AbilityIcons._px(im, 6, 7, Color(1, 0.9, 0.6))
		# ----- способности -----
		"s_fireball":
			AbilityIcons._disc(im, 18, 14, 9, Color(1.0, 0.45, 0.1))
			AbilityIcons._disc(im, 19, 13, 5, Color(1.0, 0.85, 0.35))
			for k in 3:
				AbilityIcons._line(im, Vector2(4 + k * 2, 26 - k * 5), Vector2(12, 18 - k * 2), Color(1.0, 0.55, 0.15, 0.6 + k * 0.1), 2)
		"s_dash":
			for k in 3:
				AbilityIcons._line(im, Vector2(4, 10 + k * 6), Vector2(16, 10 + k * 6), Color(1, 1, 1, 0.3 + k * 0.2), 1)
			AbilityIcons._poly(im, PackedVector2Array([Vector2(14, 6), Vector2(28, 16), Vector2(14, 26), Vector2(18, 16)]), Color(0.6, 0.85, 1.0))
		"s_heal":
			AbilityIcons._disc(im, 16, 16, 12, Color(0.3, 0.75, 0.4, 0.5))
			AbilityIcons._rect(im, 13, 6, 6, 20, Color(0.55, 1.0, 0.6))
			AbilityIcons._rect(im, 6, 13, 20, 6, Color(0.55, 1.0, 0.6))
			AbilityIcons._rect(im, 14, 7, 2, 18, Color(0.9, 1.0, 0.9))
		"s_rage":
			AbilityIcons._poly(im, PackedVector2Array([Vector2(6, 28), Vector2(8, 10), Vector2(12, 16), Vector2(16, 3), Vector2(20, 16), Vector2(24, 10), Vector2(26, 28)]), Color(0.85, 0.15, 0.15))
			AbilityIcons._poly(im, PackedVector2Array([Vector2(11, 28), Vector2(13, 18), Vector2(16, 22), Vector2(19, 18), Vector2(21, 28)]), Color(1.0, 0.6, 0.2))
			AbilityIcons._rect(im, 12, 22, 3, 2, Color(1, 1, 0.8))
			AbilityIcons._rect(im, 18, 22, 3, 2, Color(1, 1, 0.8))
		_:
			return null
	return im

static func _shirt(im: Image, c: Color, dark: Color) -> void:
	AbilityIcons._poly(im, PackedVector2Array([Vector2(10, 5), Vector2(22, 5), Vector2(29, 11), Vector2(25, 15), Vector2(24, 27),
			Vector2(8, 27), Vector2(7, 15), Vector2(3, 11)]), c)
	AbilityIcons._poly(im, PackedVector2Array([Vector2(13, 5), Vector2(19, 5), Vector2(16, 9)]), dark)
	AbilityIcons._rect(im, 3, 11, 4, 2, dark)
	AbilityIcons._rect(im, 25, 11, 4, 2, dark)

static func _pants(im: Image, c: Color) -> void:
	AbilityIcons._rect(im, 8, 4, 16, 6, c)
	AbilityIcons._rect(im, 8, 9, 7, 19, c)
	AbilityIcons._rect(im, 17, 9, 7, 19, c)
	AbilityIcons._rect(im, 8, 4, 16, 2, Color(0.3, 0.2, 0.12))
	AbilityIcons._px(im, 16, 5, Color(0.9, 0.8, 0.35))
