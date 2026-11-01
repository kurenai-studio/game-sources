extends "res://tools/directions/shared/direction_tokens.gd"
## Slate: editorial and exact. A built in skin. Mirrors docs/DESIGN_SYSTEM.md,
## section "Slate"; change the document first, then this file.
##
## Owner: senior-graphic-designer. Artists read these values; they do not
## edit this file.


func _init() -> void:
	id = "slate"
	display_name = "Slate"
	font_family = FAMILY_SYSTEM

	palette = {
		# Shared roles
		"bg": Color("#0B0C0E"),
		"surface": Color("#181A1C"),
		"surface_raised": Color("#212326"),
		"line": Color("#36383B"),
		"ink": Color("#F5F2E9"),
		"ink_muted": Color("#A1A5AB"),
		"ink_dark": Color("#0E0F12"),
		"accent": Color("#FA5D36"),
		"accent_pressed": Color("#E14D28"),
		"disabled_ink": Color("#7D8085"),
		"chain": Color("#F5F2E9"),
		"target": Color("#FA5D36"),
		"joinable": Color("#F5F2E9"),
		"scrim": Color("#0B0C0ED1"),
		"badge": Color("#FA5D36"),
		"badge_ink": Color("#0E0F12"),
		# Extras
		"chain_edge": Color("#0E0F12"),
	}

	# Slabs (2 to 64): dark fills in hues that stay rich when dark, lightness
	# alternating, number in a bright tint of the same hue. Blocks (128 up):
	# solid color with a black number. Each step jumps far round the hue
	# wheel. Hues 15 to 55 degrees are kept for the vermilion accent.
	tile_fill = [
		Color("#115D1C"), # 2 forest slab
		Color("#1E327D"), # 4 navy slab
		Color("#7F1F26"), # 8 oxblood slab
		Color("#156561"), # 16 teal slab
		Color("#4F1F6C"), # 32 aubergine slab
		Color("#6E4B0F"), # 64 bronze slab
		Color("#F59E33"), # 128 amber
		Color("#49F6FB"), # 256 cyan
		Color("#F74AD8"), # 512 magenta
		Color("#C2FC44"), # 1024 lime
		Color("#9191F6"), # 2K periwinkle
		Color("#F9CB3D"), # 4K gold
		Color("#39C4F8"), # 8K sky
		Color("#F75EA7"), # 16K pink
		Color("#48FAB4"), # 32K mint
		Color("#AF83F6"), # 64K lilac
		Color("#F5F2E9"), # 128K paper
	]
	var dark: Color = Color("#0E0F12")
	tile_ink = [
		Color("#95F198"), # 2
		Color("#C9D7F9"), # 4
		Color("#F9CAC8"), # 8
		Color("#58F3EA"), # 16
		Color("#E5CCF9"), # 32
		Color("#F9D097"), # 64
		dark, dark, dark, dark, dark, dark, dark, dark, dark, dark, dark,
	]
	# The color cycle above 131072 (DESIGN_SYSTEM.md 3.3): the whole ramp.
	tile_cycle = PackedInt32Array([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16])
	# Tier 1 slab, 2 block, 3 block with the inner hairline frame (32K up).
	tile_tier = PackedInt32Array([1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3])
	beyond_tier = 3

	text_pairs = [
		pair("Score and HUD numbers on the background", "ink", "bg"),
		pair("Labels, secondary numbers, toggle OFF", "ink_muted", "bg"),
		pair("Signal label, for example OUT OF MOVES", "accent", "bg"),
		pair("Booster name and cost, disabled", "disabled_ink", "bg"),
		pair("Paper fill: active booster, selected chip, toggle ON", "ink_dark", "ink"),
		pair("Badges and the targeting hint bar", "badge_ink", "badge"),
		pair("Primary button", "ink_dark", "accent"),
		pair("Primary button, pressed", "ink_dark", "accent_pressed"),
		pair("Text on surface: sheets, chips, pressed rows", "ink", "surface"),
		pair("Labels on surface", "ink_muted", "surface"),
		pair("Text on raised surface: pressed chips and buttons", "ink", "surface_raised"),
		pair("Labels on raised surface", "ink_muted", "surface_raised"),
		# 2026-10-13: the Free cost on a pressed column.
		pair("Free cost and its star, pressed column", "accent", "surface"),
	]

	# Type: system font (Roboto on Android), grotesk, left aligned.
	type_roles = {
		"display": {"size": 184, "weight": 700, "tracking": -4, "case": CASE_NONE},
		"title": {"size": 72, "weight": 700, "tracking": -1, "case": CASE_NONE},
		"body": {"size": 44, "weight": 500, "tracking": 0, "case": CASE_NONE},
		"label": {"size": 30, "weight": 600, "tracking": 4, "case": CASE_UPPER},
		"tile": {"weight": 700, "tracking": -1, "case": CASE_NONE},
		"heading": {"size": 30, "weight": 700, "tracking": 4, "case": CASE_UPPER},
		"reading": {"size": 42, "weight": 400, "tracking": 0, "case": CASE_NONE},
	}
	tile_number_scale = PackedFloat32Array([0.40, 0.40, 0.33, 0.31])

	shape = {
		# Shared names. Lengths in px on the 1080 px base canvas unless noted.
		"board_margin": 44.0,
		"board_gap": 10.0,
		"board_padding": 0.0,
		"tile_radius": 0.032,        # fraction of the tile side, 6 px at 190 px
		"label_fit": 0.78,
		"display_fit_min": 76.0,     # 96 until 2026-10-21: a 15 character score fits (DESIGN_SYSTEM.md 14.2)
		"preview_scale": 0.59,       # preview tile in the header, fraction of the board tile
		"special_from": 32768.0,
		"chain_width": 8.0,
		"chain_ring": 6.0,           # paper frame inside chained tiles
		"joinable_ring": 2.0,        # frame inside joinable tiles
		"target_ring": 6.0,          # corner brackets, thickness
		"space_xs": 8.0,
		"space_s": 20.0,
		"space_m": 40.0,
		"space_l": 64.0,
		"space_xl": 104.0,
		"touch_min": 160.0,         # 48 dp on 18:9 phones, 51 dp on the Fold5 cover (DESIGN_SYSTEM.md 2.7)
		"radius_button": 4.0,
		"radius_card": 0.0,
		"radius_chip": 4.0,
		"hairline": 2.0,
		"hud_height": 350.0,         # header plus the context row
		"bar_height": 192.0,         # strip; the hint lives in the HUD context row
		"hint_height": 112.0,
		"button_height": 160.0,       # at least touch_min (2.7)
		"row_height": 148.0,
		"icon_booster": 66.0,
		"icon_hud": 72.0,
		"icon_stroke": 2.0,
		"toggle_w": 132.0,
		"toggle_h": 64.0,
		"toggle_knob": 44.0,
		"notice_height": 112.0,      # the notice takes the HUD context row
		"notice_tile_scale": 0.5,
		"notice_strike": 2.0,
		"star_icon": 36.0,          # the HUD counter's star box, on the caption line
		"reading_line_spacing": 14.0,  # px added between reading role lines
		"scroll_bar": 4.0,          # drawn width of the reading screens' scroll indicator
		# Extras
		"number_inset": 0.11,        # number sits top left, this far in
		"number_plate": 6.0,         # px: on chained tiles, a plate of the tile fill round the whole label
		"line_edge": 3.0,            # dark edge each side of the chain line
		"node_size": 24.0,
		"joinable_node_stroke": 3.0, # hollow node on joinable tiles
		"selected_frame": 4.0,       # target frame inside Swap's selected tile
		"target_bracket": 0.30,      # arm length, fraction of the tile side
		"special_inset": 0.06,
		"frame_inset": 0.03,        # chained and joinable frames sit this far inside the tile edge, fraction of the side
		"flash_cut": 0.05,
		"strip_height": 192.0,
		"toggle_knob_inset": 10.0,
		"focus_width": 4.0,
		"focus_gap": 4.0,
	}

	motion = {
		"spawn": {"duration": 0.14, "trans": Tween.TRANS_EXPO, "ease": Tween.EASE_OUT, "from_scale_y": 0.0, "stagger": 0.0},
		"fall": {"duration": 0.16, "trans": Tween.TRANS_QUART, "ease": Tween.EASE_OUT},
		"chain_add": {"duration": 0.06, "trans": Tween.TRANS_LINEAR, "ease": Tween.EASE_IN_OUT},
		"chain_remove": {"duration": 0.06, "trans": Tween.TRANS_LINEAR, "ease": Tween.EASE_IN_OUT},
		"joinable_in": {"duration": 0.06, "trans": Tween.TRANS_LINEAR, "ease": Tween.EASE_IN_OUT},
		"merge_travel": {"duration": 0.12, "trans": Tween.TRANS_QUART, "ease": Tween.EASE_IN},
		"merge_pop": {"duration": 0.16, "trans": Tween.TRANS_EXPO, "ease": Tween.EASE_OUT, "flash": 1.0},
		"clear": {"duration": 0.14, "trans": Tween.TRANS_EXPO, "ease": Tween.EASE_IN},
		"clear_notice": {"duration": 0.12, "trans": Tween.TRANS_EXPO, "ease": Tween.EASE_OUT, "hold": 1.6, "out": 0.12},
		"press": {"duration": 0.04, "trans": Tween.TRANS_LINEAR, "ease": Tween.EASE_IN_OUT},
		"button_press": {"duration": 0.04, "trans": Tween.TRANS_LINEAR, "ease": Tween.EASE_IN_OUT},
		"button_release": {"duration": 0.10, "trans": Tween.TRANS_QUART, "ease": Tween.EASE_OUT},
		"dialog_in": {"duration": 0.24, "trans": Tween.TRANS_EXPO, "ease": Tween.EASE_OUT, "from_offset": 32.0, "from_alpha": 0.0},
		"dialog_out": {"duration": 0.12, "trans": Tween.TRANS_QUART, "ease": Tween.EASE_IN},
		"screen_fade": {"duration": 0.12, "trans": Tween.TRANS_LINEAR, "ease": Tween.EASE_IN_OUT},
		# Duration 0 means no pulse: Slate's selected tile holds still.
		"target_pulse": {"duration": 0.0, "trans": Tween.TRANS_LINEAR, "ease": Tween.EASE_IN_OUT},
		"score_count": {"duration": 0.24, "trans": Tween.TRANS_QUART, "ease": Tween.EASE_OUT},
		"skin_switch": {"duration": 0.16, "trans": Tween.TRANS_LINEAR, "ease": Tween.EASE_IN_OUT},
		# The counter's paper flash; Slate has no flight.
		"star_earn": {"duration": 0.16, "trans": Tween.TRANS_LINEAR, "ease": Tween.EASE_IN_OUT},
		"star_convert": {"duration": 0.16, "trans": Tween.TRANS_LINEAR, "ease": Tween.EASE_IN_OUT},
	}

	_add_phase1_aliases()


## Phase 1 names that the prototype components in tools/directions still
## read. Not part of the schema; remove when the prototypes are retired.
func _add_phase1_aliases() -> void:
	palette["rule"] = palette["line"]
	shape["gap"] = shape["board_gap"]
	shape["line_width"] = shape["chain_width"]
	shape["chain_frame"] = shape["chain_ring"]
	shape["number_knockout"] = shape["number_plate"]
	shape["target_bracket_width"] = shape["target_ring"]
	shape["rule_width"] = shape["hairline"]
	shape["preview_tile"] = 112.0
	shape["button_radius"] = shape["radius_button"]
	shape["booster_icon"] = shape["icon_booster"]
	shape["hud_icon"] = shape["icon_hud"]
	shape["toggle_track_w"] = shape["toggle_w"]
	shape["toggle_track_h"] = shape["toggle_h"]
