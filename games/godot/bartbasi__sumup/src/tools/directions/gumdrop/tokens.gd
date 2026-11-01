extends "res://tools/directions/shared/direction_tokens.gd"
## Gumdrop: tactile candy. The default skin. Mirrors docs/DESIGN_SYSTEM.md,
## section "Gumdrop"; change the document first, then this file.
##
## Owner: senior-graphic-designer. Artists read these values; they do not
## edit this file.


func _init() -> void:
	id = "gumdrop"
	display_name = "Gumdrop"
	font_family = FAMILY_OUTFIT

	palette = {
		# Shared roles
		"bg": Color("#150820"),
		"surface": Color("#2B183D"),
		"surface_raised": Color("#3F2956"),
		"line": Color("#3F2956"),
		"ink": Color("#FFF7FC"),
		"ink_muted": Color("#D3BDE5"),
		"ink_dark": Color("#1C0D2B"),
		"accent": Color("#FF63B2"),
		"accent_pressed": Color("#EB4B9F"),
		"disabled_ink": Color("#A39AAE"),
		"chain": Color("#FFF7FC"),
		"target": Color("#FFF7FC"),
		"joinable": Color("#FFDC4F"),
		"scrim": Color("#150820C7"),
		"badge": Color("#FFDC4F"),
		"badge_ink": Color("#1C0D2B"),
		# Extras
		"tray": Color("#20112F"),
		"slot": Color("#2A1A3A"),
		"surface_lip": Color("#090213"),
		"accent_lip": Color("#A9246E"),
		"badge_lip": Color("#BF9007"),
		"disabled_surface": Color("#1D1625"),
		"target_edge": Color("#1C0D2B"),
		"shine": Color("#FFFFFF"),
	}

	# Categorical ramp: each step jumps far round the hue wheel, so any four
	# values in play look different. Chroma rises by tier, so big tiles are the
	# most vivid on the board. Every number is ink_dark.
	tile_fill = [
		Color("#8FFFD0"), # 2 mint
		Color("#B681EF"), # 4 lavender
		Color("#FFE47D"), # 8 lemon
		Color("#5DAFF1"), # 16 sky
		Color("#F37069"), # 32 coral
		Color("#32F3FC"), # 64 aqua
		Color("#F721B6"), # 128 hot pink
		Color("#AAFA2E"), # 256 lime
		Color("#6A88FA"), # 512 periwinkle
		Color("#FB8822"), # 1024 tangerine
		Color("#3BBEFE"), # 2K azure
		Color("#FE4F6D"), # 4K cherry
		Color("#5EFF8F"), # 8K spring green
		Color("#D056FF"), # 16K grape
		Color("#2FA9FF"), # 32K electric blue
		Color("#FDF1FC"), # 64K pearl
		Color("#F7C243"), # 128K gold
	]
	var dark: Color = Color("#1C0D2B")
	tile_ink = [dark, dark, dark, dark, dark, dark, dark, dark, dark, dark, dark, dark, dark, dark, dark, dark, dark]
	# The color cycle above 131072 (DESIGN_SYSTEM.md 3.3): every position but
	# 2 lemon and 3 sky: 128K gold would sit three steps from lemon, and sky
	# four steps from 32K electric blue.
	tile_cycle = PackedInt32Array([0, 1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16])
	# Tier 1 sorbet (2 to 32), 2 candy (64 to 1K), 3 neon with shine (2K to
	# 32K), 4 special with the candy rim (64K up). Lip height grows by tier.
	tile_tier = PackedInt32Array([1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 4, 4])
	beyond_tier = 4

	text_pairs = [
		pair("Score and HUD numbers on the background", "ink", "bg"),
		pair("HUD labels on the background", "ink_muted", "bg"),
		pair("Pill, dock and card text", "ink", "surface"),
		pair("Pill, dock and card labels", "ink_muted", "surface"),
		pair("Booster cost, secondary buttons, chips", "ink", "surface_raised"),
		pair("Labels on raised surfaces", "ink_muted", "surface_raised"),
		pair("Booster cost, targeting", "ink_dark", "accent"),
		pair("Booster cost, disabled", "disabled_ink", "disabled_surface"),
		pair("Badges: hint pill, suggested, new best, clear notice", "badge_ink", "badge"),
		pair("Primary button and selected chip", "ink_dark", "accent"),
		pair("Primary button, pressed", "ink_dark", "accent_pressed"),
		pair("Text straight on the scrim, worst case over a pearl tile", "ink", "scrim", "tile:65536"),
		# 2026-10-13: stars, free boosters and the wordmark.
		pair("Free cost and its star on a booster face", "badge", "surface_raised"),
		pair("Star counter star on the star pill", "badge", "surface"),
		pair("Wordmark Up on the backdrop", "accent", "bg"),
	]

	# Type: Outfit, heavy, sentence case.
	type_roles = {
		"display": {"size": 120, "weight": 900, "tracking": -1, "case": CASE_NONE},
		"title": {"size": 76, "weight": 900, "tracking": 0, "case": CASE_NONE},
		"body": {"size": 46, "weight": 700, "tracking": 0, "case": CASE_NONE},
		"label": {"size": 34, "weight": 700, "tracking": 1, "case": CASE_NONE},
		"tile": {"weight": 900, "tracking": 0, "case": CASE_NONE},
		"heading": {"size": 54, "weight": 900, "tracking": 0, "case": CASE_NONE},
		"reading": {"size": 42, "weight": 500, "tracking": 0, "case": CASE_NONE},
	}
	tile_number_scale = PackedFloat32Array([0.48, 0.44, 0.36, 0.31])

	shape = {
		# Shared names. Lengths in px on the 1080 px base canvas unless noted.
		"board_margin": 36.0,
		"board_gap": 16.0,
		"board_padding": 18.0,       # tray padding
		"tile_radius": 0.30,         # fraction of the tile side
		"label_fit": 0.88,           # widest label, fraction of the tile side
		"display_fit_min": 76.0,     # the score shrinks to fit, never below this
		"preview_scale": 0.46,       # preview mini tile, fraction of the tile side
		"special_from": 65536.0,
		"chain_width": 30.0,         # rope, drawn under the tiles
		"chain_ring": 7.0,           # white ring on chained tiles
		"joinable_ring": 6.0,        # lemon ring on joinable tiles
		"target_ring": 9.0,          # ring under the finger in targeting
		"space_xs": 12.0,
		"space_s": 24.0,
		"space_m": 36.0,
		"space_l": 56.0,
		"space_xl": 88.0,
		"touch_min": 160.0,         # 48 dp on 18:9 phones, 51 dp on the Fold5 cover (DESIGN_SYSTEM.md 2.7)
		"radius_button": 44.0,
		"radius_card": 60.0,
		"radius_chip": 40.0,
		"hairline": 4.0,
		"hud_height": 255.0,
		"bar_height": 272.0,         # dock plus the hint row above it
		"hint_height": 88.0,
		"button_height": 160.0,       # at least touch_min (2.7)
		"row_height": 144.0,
		"icon_booster": 84.0,
		"icon_hud": 64.0,           # in the 96 px HUD button face
		"icon_stroke": 3.5,          # on the 24 unit icon grid
		"toggle_w": 140.0,
		"toggle_h": 76.0,
		"toggle_knob": 54.0,
		"notice_height": 88.0,
		"notice_tile_scale": 0.6,   # mini tiles in the clear notice, share of notice_height
		"notice_strike": 4.0,       # strike line across them
		"star_icon": 56.0,          # the HUD counter's star box
		"reading_line_spacing": 10.0,  # px added between reading role lines
		"scroll_bar": 8.0,          # drawn width of the reading screens' scroll indicator
		# Extras
		"tray_radius": 60.0,
		"lip_darken": 0.34,          # lip color = fill.darkened(lip_darken)
		"lip_t1": 0.060,             # lip depth by tier, fraction of the tile side
		"lip_t2": 0.075,
		"lip_t3": 0.090,
		"lip_t4": 0.090,
		"lip_pressed": 0.020,
		"joinable_lift": 0.030,      # joinable tiles rise by this
		"target_lift": 0.040,        # Swap's selected tile rises by this
		"shine_alpha": 0.35,
		"shine_from_tier": 3.0,
		"shine_inset": 0.05,         # shine arc: inset from the face edge, fraction of the side
		"shine_width": 0.045,        # and its width
		"preview_ring": 6.0,
		"target_edge_width": 4.0,
		"special_rim_width": 8.0,
		"special_rim_segments": 16.0,
		"hud_top_row": 96.0,
		"hud_button_face": 96.0,     # pause button face in the HUD
		"pill_height": 96.0,
		"pill_radius": 48.0,
		"button_lip": 10.0,
		"button_lip_pressed": 3.0,
		"active_raise": 6.0,
		"dock_height": 184.0,
		"dock_radius": 64.0,
		"focus_width": 5.0,
		"focus_gap": 6.0,
		"toggle_knob_lip": 5.0,
	}

	motion = {
		"spawn": {"duration": 0.24, "trans": Tween.TRANS_BACK, "ease": Tween.EASE_OUT, "from_scale": 0.2, "stagger": 0.03},
		"fall": {"duration": 0.26, "trans": Tween.TRANS_BACK, "ease": Tween.EASE_OUT, "squash": 0.12},
		"chain_add": {"duration": 0.10, "trans": Tween.TRANS_QUAD, "ease": Tween.EASE_OUT, "press_scale": 0.94},
		"chain_remove": {"duration": 0.10, "trans": Tween.TRANS_QUAD, "ease": Tween.EASE_OUT},
		"joinable_in": {"duration": 0.12, "trans": Tween.TRANS_SINE, "ease": Tween.EASE_OUT},
		"merge_travel": {"duration": 0.18, "trans": Tween.TRANS_BACK, "ease": Tween.EASE_IN},
		"merge_pop": {"duration": 0.28, "trans": Tween.TRANS_ELASTIC, "ease": Tween.EASE_OUT, "peak_scale": 1.22},
		"clear": {"duration": 0.28, "trans": Tween.TRANS_BACK, "ease": Tween.EASE_IN, "burst_dots": 6.0, "burst_dot_size": 0.07, "burst_reach": 0.6, "burst_fade": 0.36},
		"clear_notice": {"duration": 0.30, "trans": Tween.TRANS_BACK, "ease": Tween.EASE_OUT, "hold": 1.6, "out": 0.20, "from_scale": 0.6},
		"press": {"duration": 0.08, "trans": Tween.TRANS_QUAD, "ease": Tween.EASE_OUT},
		"button_press": {"duration": 0.08, "trans": Tween.TRANS_QUAD, "ease": Tween.EASE_OUT, "press_scale": 0.92},
		"button_release": {"duration": 0.30, "trans": Tween.TRANS_BACK, "ease": Tween.EASE_OUT},
		"dialog_in": {"duration": 0.42, "trans": Tween.TRANS_BACK, "ease": Tween.EASE_OUT, "from_offset": 240.0},
		"dialog_out": {"duration": 0.20, "trans": Tween.TRANS_QUAD, "ease": Tween.EASE_IN},
		"screen_fade": {"duration": 0.22, "trans": Tween.TRANS_SINE, "ease": Tween.EASE_IN_OUT},
		"target_pulse": {"duration": 0.90, "trans": Tween.TRANS_SINE, "ease": Tween.EASE_IN_OUT, "wobble_degrees": 4.0},
		"score_count": {"duration": 0.50, "trans": Tween.TRANS_CUBIC, "ease": Tween.EASE_OUT},
		"skin_switch": {"duration": 0.30, "trans": Tween.TRANS_SINE, "ease": Tween.EASE_IN_OUT},
		"star_earn": {"duration": 0.40, "trans": Tween.TRANS_SINE, "ease": Tween.EASE_IN_OUT, "delay": 0.10, "from_scale": 0.4, "stagger": 0.10},
		"star_convert": {"duration": 0.18, "trans": Tween.TRANS_BACK, "ease": Tween.EASE_IN, "from_scale": 0.2, "empty": 0.12},
	}

	_add_phase1_aliases()


## Phase 1 names that the prototype components in tools/directions still
## read. Not part of the schema; remove when the prototypes are retired.
func _add_phase1_aliases() -> void:
	palette["ink_soft"] = palette["ink_muted"]
	palette["divider"] = palette["line"]
	palette["lemon"] = palette["badge"]
	palette["lemon_lip"] = palette["badge_lip"]
	shape["gap"] = shape["board_gap"]
	shape["tray_padding"] = shape["board_padding"]
	shape["lip_depth"] = shape["lip_t2"]
	shape["rope_width"] = shape["chain_width"]
	shape["ring_width"] = shape["chain_ring"]
	shape["target_ring_width"] = shape["target_ring"]
	shape["card_radius"] = shape["radius_card"]
	shape["button_radius"] = shape["radius_button"]
	shape["divider_width"] = shape["hairline"]
	shape["booster_icon"] = shape["icon_booster"]
	shape["hud_icon"] = shape["icon_hud"]
	shape["toggle_track_w"] = shape["toggle_w"]
	shape["toggle_track_h"] = shape["toggle_h"]
