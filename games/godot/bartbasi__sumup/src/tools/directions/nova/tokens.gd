extends "res://tools/directions/shared/direction_tokens.gd"
## Nova: tiles are stars. A built in skin. Mirrors docs/DESIGN_SYSTEM.md,
## section "Nova"; change the document first, then this file.
##
## Owner: senior-graphic-designer. Artists read these values; they do not
## edit this file.


func _init() -> void:
	id = "nova"
	display_name = "Nova"
	font_family = FAMILY_OUTFIT

	palette = {
		# Shared roles
		"bg": Color("#040819"),
		"surface": Color("#10162F"),
		"surface_raised": Color("#1F2646"),
		"line": Color("#52628C"),
		"ink": Color("#F7F9FF"),
		"ink_muted": Color("#ABB7D5"),
		"ink_dark": Color("#060C20"),
		"accent": Color("#49EAF2"),
		"accent_pressed": Color("#17D0D8"),
		"disabled_ink": Color("#848C9F"),
		"chain": Color("#FFFFFF"),
		"target": Color("#49EAF2"),
		"joinable": Color("#FFFFFF"),
		"scrim": Color("#040819DB"),
		"badge": Color("#49EAF2"),
		"badge_ink": Color("#060C20"),
		# Extras
		"bg_glow": Color("#181942"),
		"star": Color("#FFFFFF"),
		"accent_violet": Color("#9264EF"),
	}

	# Every value is a different kind of star. Dark orbs (white numbers) and
	# light orbs (dark numbers) alternate, and each step jumps far round the
	# hue wheel, so neighbors never look alike. Glow grows with value.
	tile_fill = [
		Color("#D01D21"), # 2 red dwarf
		Color("#FED33F"), # 4 yellow star
		Color("#1957D2"), # 8 blue giant
		Color("#2AF0D5"), # 16 aqua nebula
		Color("#CA13B3"), # 32 magenta nebula
		Color("#FDA669"), # 64 orange giant
		Color("#693AD4"), # 128 violet
		Color("#9BF461"), # 256 aurora green
		Color("#D31D4B"), # 512 crimson
		Color("#7ECFFD"), # 1024 ice
		Color("#9129C8"), # 2K purple
		Color("#F7E04F"), # 4K gold
		Color("#0D7C59"), # 8K emerald
		Color("#FD8DC5"), # 16K rose
		Color("#0A65AD"), # 32K deep blue
		Color("#FEBC72"), # 64K supernova
		Color("#FAFCFF"), # 128K white hole
	]
	var dark: Color = Color("#060C20")
	var light: Color = Color("#F7F9FF")
	tile_ink = [
		light, dark, light, dark, light, dark, light, dark, light, dark,
		light, dark, light, dark, light, dark, dark,
	]
	# The color cycle above 131072 (DESIGN_SYSTEM.md 3.3): every position but
	# 1 yellow star, so 64K supernova never sits three steps from it.
	tile_cycle = PackedInt32Array([0, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16])
	# Tier 1 (2 to 1K), 2 (2K to 16K, wider glow), 3 (32K up, corona rays).
	tile_tier = PackedInt32Array([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3])
	beyond_tier = 3

	text_pairs = [
		pair("Score on the lightest part of the backdrop", "ink", "bg_glow"),
		pair("Labels on the lightest part of the backdrop", "ink_muted", "bg_glow"),
		pair("Labels on the darkest part of the backdrop", "ink_muted", "bg"),
		pair("Booster cost, targeting", "accent", "bg_glow"),
		pair("Booster cost, disabled", "disabled_ink", "bg_glow"),
		pair("Disabled button or chip on a sheet", "disabled_ink", "surface"),
		pair("Badges: suggested, new best, clear notice", "badge_ink", "badge"),
		pair("Primary button and selected chip", "ink_dark", "accent"),
		pair("Primary button, pressed", "ink_dark", "accent_pressed"),
		pair("Sheet and card text", "ink", "surface"),
		pair("Sheet and card labels", "ink_muted", "surface"),
		pair("Rows and chips on a sheet", "ink", "surface_raised"),
		pair("Labels on rows and chips", "ink_muted", "surface_raised"),
		pair("Text over the scrim, worst case over a white hole tile", "ink", "scrim", "tile:131072"),
		pair("Labels over the scrim, worst case over a white hole tile", "ink_muted", "scrim", "tile:131072"),
	]

	# Type: Outfit, light for the big numbers, semibold on orbs, lowercase labels.
	type_roles = {
		"display": {"size": 148, "weight": 300, "tracking": 0, "case": CASE_NONE},
		"title": {"size": 68, "weight": 300, "tracking": 0, "case": CASE_NONE},
		"body": {"size": 44, "weight": 400, "tracking": 0, "case": CASE_NONE},
		"label": {"size": 32, "weight": 400, "tracking": 3, "case": CASE_LOWER},
		"tile": {"weight": 600, "tracking": 0, "case": CASE_NONE},
		"heading": {"size": 50, "weight": 300, "tracking": 0, "case": CASE_NONE},
		"reading": {"size": 42, "weight": 400, "tracking": 0, "case": CASE_NONE},
	}
	tile_number_scale = PackedFloat32Array([0.46, 0.42, 0.37, 0.315])

	shape = {
		# Shared names. Lengths in px on the 1080 px base canvas unless noted.
		"board_margin": 44.0,
		"board_gap": 22.0,           # between orbs at the base width (orb_scale 0.89 of the pitch; was 24 at 0.88, DESIGN_SYSTEM.md 2.4)
		"board_padding": 0.0,
		"tile_radius": 0.5,          # circle
		"label_fit": 0.82,           # widest label, fraction of the orb diameter
		"display_fit_min": 80.0,
		"preview_scale": 0.54,       # preview orb, fraction of the orb diameter
		"special_from": 32768.0,
		"chain_width": 12.0,         # beam core, drawn under the orbs
		"chain_ring": 8.0,           # white rim on chained orbs
		"joinable_ring": 3.0,        # thin white orbit on joinable orbs
		"target_ring": 4.0,          # dashed cyan orbit under the finger
		"space_xs": 12.0,
		"space_s": 28.0,
		"space_m": 44.0,
		"space_l": 72.0,
		"space_xl": 112.0,
		"touch_min": 160.0,         # 48 dp on 18:9 phones, 51 dp on the Fold5 cover (DESIGN_SYSTEM.md 2.7)
		"radius_button": 72.0,       # pill
		"radius_card": 64.0,         # sheet top corners
		"radius_chip": 72.0,
		"hairline": 2.0,
		"hud_height": 200.0,
		"bar_height": 254.0,
		"hint_height": 64.0,
		"button_height": 160.0,       # at least touch_min (2.7)
		"row_height": 144.0,
		"icon_booster": 80.0,
		"icon_hud": 72.0,
		"icon_stroke": 1.5,
		"toggle_w": 124.0,
		"toggle_h": 64.0,
		"toggle_knob": 40.0,
		"notice_height": 80.0,
		"notice_tile_scale": 0.6,
		"notice_strike": 2.0,
		"star_icon": 32.0,          # the HUD counter's star box, on the best line
		"reading_line_spacing": 12.0,  # px added between reading role lines
		"scroll_bar": 4.0,          # drawn width of the reading screens' scroll indicator
		# Extras
		"orb_scale": 0.89,            # 56.3 dp on the Fold5 cover screen (QA6-05, DESIGN_SYSTEM.md 2.4)
		"rim_width": 4.0,
		"rim_lighten": 0.35,
		"glow_alpha_low": 0.10,
		"glow_alpha_high": 0.55,
		"glow_spread_low": 1.12,
		"glow_spread_high": 1.55,
		"beam_glow_width": 44.0,
		"beam_glow_alpha": 0.28,
		"orbit_offset": 0.10,
		"joinable_orbit": 0.05,      # joinable orbit radius = orb radius times (1 + this)
		"joinable_glow": 1.25,
		"ray_count": 12.0,
		"ray_inner": 1.08,
		"ray_outer": 1.24,
		"ray_width": 3.0,
		"ray_lighten": 0.35,         # ray color = fill.lightened(ray_lighten)
		"ray_alpha": 0.6,
		"dark_rim_from": 131072.0,   # from this value the chained rim is ink_dark (white on the white hole vanishes)
		"spawn_bloom": 0.6,
		"chain_glow": 1.4,
		"target_glow": 1.5,
		"orbit_dashes": 24.0,
		"orbit_dash_fill": 0.55,
		"orbit_breath": 0.05,
		"orbit_turn": 0.08,
		"ring_button": 136.0,
		"ring_width": 3.0,
		"disabled_ring_alpha": 0.35,
		"disabled_ring_dashes": 16.0,
		"disabled_icon_alpha": 0.6,
		"star_count": 70.0,
		"star_alpha_max": 0.35,
		"star_alpha_min": 0.08,
		"star_size_min": 1.5,
		"star_size_max": 3.5,
		"star_seed": 20261010.0,
		"star_clearance": 24.0,
		"backdrop_glow_x": 0.5,
		"backdrop_glow_y": 0.26,
		"backdrop_glow_radius": 0.95,
		"hud_ring": 96.0,
		"icon_spark": 1.0,
		"icon_fit": 0.86,
		"icon_glow_alpha": 0.4,
		"ring_glow_spread": 1.45,
		"ring_glow_alpha": 0.75,
		"focus_gap": 6.0,
		"toggle_glow_spread": 1.9,
		"toggle_glow_alpha": 0.6,
	}

	motion = {
		"spawn": {"duration": 0.34, "trans": Tween.TRANS_SINE, "ease": Tween.EASE_OUT, "from_scale": 0.55, "from_alpha": 0.0, "stagger": 0.04},
		"fall": {"duration": 0.26, "trans": Tween.TRANS_CUBIC, "ease": Tween.EASE_OUT},
		"chain_add": {"duration": 0.16, "trans": Tween.TRANS_SINE, "ease": Tween.EASE_OUT},
		"chain_remove": {"duration": 0.16, "trans": Tween.TRANS_SINE, "ease": Tween.EASE_OUT},
		"joinable_in": {"duration": 0.20, "trans": Tween.TRANS_SINE, "ease": Tween.EASE_OUT},
		"merge_travel": {"duration": 0.24, "trans": Tween.TRANS_CUBIC, "ease": Tween.EASE_IN_OUT},
		"merge_pop": {"duration": 0.40, "trans": Tween.TRANS_SINE, "ease": Tween.EASE_OUT, "peak_glow": 1.8},
		"clear": {"duration": 0.36, "trans": Tween.TRANS_SINE, "ease": Tween.EASE_IN, "sparks": 8.0, "to_scale": 0.4, "spark_reach": 0.7, "spark_size": 8.0},
		"clear_notice": {"duration": 0.40, "trans": Tween.TRANS_SINE, "ease": Tween.EASE_OUT, "hold": 1.8, "out": 0.30, "from_offset": 16.0, "from_alpha": 0.0},
		"press": {"duration": 0.10, "trans": Tween.TRANS_SINE, "ease": Tween.EASE_OUT},
		"button_press": {"duration": 0.10, "trans": Tween.TRANS_SINE, "ease": Tween.EASE_OUT, "press_scale": 0.96},
		"button_release": {"duration": 0.24, "trans": Tween.TRANS_SINE, "ease": Tween.EASE_OUT},
		"dialog_in": {"duration": 0.44, "trans": Tween.TRANS_SINE, "ease": Tween.EASE_OUT, "from_alpha": 0.0, "from_scale": 0.96},
		"dialog_out": {"duration": 0.28, "trans": Tween.TRANS_SINE, "ease": Tween.EASE_IN},
		"screen_fade": {"duration": 0.36, "trans": Tween.TRANS_SINE, "ease": Tween.EASE_IN_OUT},
		"target_pulse": {"duration": 1.60, "trans": Tween.TRANS_SINE, "ease": Tween.EASE_IN_OUT, "alpha_low": 0.45},
		"score_count": {"duration": 0.60, "trans": Tween.TRANS_SINE, "ease": Tween.EASE_OUT},
		"skin_switch": {"duration": 0.40, "trans": Tween.TRANS_SINE, "ease": Tween.EASE_IN_OUT},
		"star_earn": {"duration": 0.44, "trans": Tween.TRANS_SINE, "ease": Tween.EASE_IN_OUT, "delay": 0.10, "from_alpha": 0.0, "stagger": 0.08, "peak_glow": 1.8},
		"star_convert": {"duration": 0.40, "trans": Tween.TRANS_SINE, "ease": Tween.EASE_OUT, "peak_glow": 2.0, "from_offset": 8.0, "empty": 0.40},
	}

	_add_phase1_aliases()


## Phase 1 names that the prototype components in tools/directions still
## read. Not part of the schema; remove when the prototypes are retired.
func _add_phase1_aliases() -> void:
	palette["ring"] = palette["line"]
	shape["beam_width"] = shape["chain_width"]
	shape["chain_rim_width"] = shape["chain_ring"]
	shape["orbit_width"] = shape["target_ring"]
	shape["sheet_radius"] = shape["radius_card"]
	shape["booster_icon"] = shape["icon_booster"]
	shape["hud_icon"] = shape["icon_hud"]
	shape["divider_width"] = shape["hairline"]
	shape["toggle_track_w"] = shape["toggle_w"]
	shape["toggle_track_h"] = shape["toggle_h"]
