class_name SceneProps
extends RefCounted
## Pieces of the world that show because of what the settlement has chosen or earned, not because
## a building of that name stands: the sown plot and the pen the age turn leaves behind, and later
## whatever an answer or a milestone puts on the ground. Pure and headless: the view asks which
## are shown and draws them (docs/ages.md V10, B10).
##
## Each prop is a full-width art piece named like the others; `name` is what hover says (the
## tooltip names the thing and nothing more); `at_x` is the left edge of its
## sprite in camp pixels (-384 is the west page), `z` is its draw order, and `kind` and `key` say
## what the world must hold. Mirrors tools/art/settled_camp.js: change both together. The camp's
## big static pieces (cliff, pine, mammoth) are drawn at z 10, so a prop meant to stand behind them
## uses a lower z.
##
## Keeping the world tidy (docs/ages.md B10). A prop belongs to a `place` (`WorldLayout.PLACES`: a
## yard, the river bank, the west village), and its art must sit inside it. Three optional fields:
## `alt_of` (an alternative to another prop, which is never shown with it, so they may share
## ground), `overlays` (drawn on top of another prop on purpose), `behind` (a backdrop that stands
## behind the others, a wall, so they may cover it) and, so an age can simplify what
## the last one built, `replaced_by` (hidden while that prop, or any of an array of them, is
## shown), `from_era` (shown only from
## that era order on) and `until_era` (hidden once the world's era order reaches it).
## `test_scene_props.gd` checks every one of them. `at_y` is how far the sprite is lifted onto its
## lane (see `WorldLayout.BUILDINGS`), and the art's own rows are shifted with it.
##
## The signature building: a prop of `Kind.ALWAYS` waits for nothing the group did, only for its
## `from_era` (never a flag, an achievement or a hint, docs/ages.md P8). Only the Cave Age's pennant
## is one now; each later age's big landmark replaces the cave's cliff itself and is drawn into
## `static_back`, not a prop.

enum Kind {
	## Append new kinds at the end.
	FLAG, ## `key` is a world flag.
	ACHIEVEMENT, ## `key` is an earned achievement.
	BUILDING, ## `key` is a completed building id.
	ALWAYS, ## Waits for nothing but its `from_era`: the cave keeping up with the ages. `key` is unused.
}

const PROPS: Dictionary = {
	# The village at the forest's edge (west page): the Settled Age's houses, plot, pen, kiln, well
	# and the crafts around them.
	&"west_pen": {
		"name": "Goat pen", "at_x": -384.0, "at_y": -10, "z": 67, "place": &"west_village",
		"kind": Kind.FLAG, "key": &"path_herding", "replaced_by": &"farmstead_herd",
	},
	# The clay pots stand in front of the cave mouth, where the fire is: the art was drawn in the
	# west village, so the sprite sits 166 px to the east of its page.
	&"pots": {
		"name": "Clay pots", "at_x": -166.0, "at_y": -5, "z": 74, "place": &"cave_mouth",
		"kind": Kind.ACHIEVEMENT, "key": &"fired_clay", "replaced_by": &"potters_yard",
	},
	&"cloth_line": {
		"name": "Drying cloth", "at_x": -384.0, "at_y": -5, "z": 70, "place": &"west_village",
		"kind": Kind.ACHIEVEMENT, "key": &"woven_cloth", "replaced_by": &"weavers_row",
	},
	&"cloth_dyed": {
		"name": "Dyed cloth", "at_x": -384.0, "at_y": -5, "z": 71, "place": &"west_village",
		"kind": Kind.FLAG, "key": &"dyed_cloth", "overlays": &"cloth_line",
		"replaced_by": &"weavers_row_dyed",
	},
	&"loom": {
		"name": "Loom", "at_x": -384.0, "at_y": -5, "z": 74, "place": &"west_village",
		"kind": Kind.FLAG, "key": &"loom", "replaced_by": &"weavers_row",
	},
	# The wall runs along the back lane behind the village, from the forest's edge to the cave's
	# flank (`tools/art/settled_camp.js`), so it joins two things.
	&"low_wall": {
		"name": "Low wall", "at_x": -384.0, "z": 63, "place": &"west_village",
		"kind": Kind.FLAG, "key": &"low_wall", "behind": true,
		"replaced_by": [&"town_wall", &"rampart"],
	},
	&"hens": {
		"name": "Hens", "at_x": -384.0, "at_y": -5, "z": 74, "place": &"west_village",
		"kind": Kind.FLAG, "key": &"hens", "until_era": 2,
	},
	&"west_kiln": {
		"name": "Kiln", "at_x": -384.0, "at_y": -12, "z": 67, "place": &"west_village",
		"kind": Kind.FLAG, "key": &"kiln", "replaced_by": &"potters_yard",
	},
	&"west_well": {
		"name": "Well", "at_x": -384.0, "at_y": -5, "z": 74, "place": &"west_village",
		"kind": Kind.FLAG, "key": &"well_dug", "replaced_by": &"water_court",
	},
	&"west_roof_a": {
		"name": "Village roof", "at_x": -384.0, "at_y": -6, "z": 67, "place": &"west_village",
		"kind": Kind.ACHIEVEMENT, "key": &"a_village",
	},
	&"west_roof_b": {
		"name": "Village roof", "at_x": -384.0, "at_y": -5, "z": 67, "place": &"west_village",
		"kind": Kind.ACHIEVEMENT, "key": &"a_village",
	},
	# The Bronze Age tidies what the Settled Age scattered: one piece for each yard, and a town
	# wall for the low one (docs/ages.md B10). Each hides the pieces it replaces.
	&"potters_yard": {
		"name": "Potter's yard", "at_x": -384.0, "at_y": -12, "z": 67, "place": &"west_village",
		"kind": Kind.ACHIEVEMENT, "key": &"fired_clay", "from_era": 2,
	},
	&"weavers_row": {
		"name": "Weaver's row", "at_x": -384.0, "at_y": -12, "z": 67, "place": &"west_village",
		"kind": Kind.ACHIEVEMENT, "key": &"woven_cloth", "from_era": 2,
	},
	&"weavers_row_dyed": {
		"name": "Dyed cloth", "at_x": -384.0, "at_y": -12, "z": 68, "place": &"west_village",
		"kind": Kind.FLAG, "key": &"dyed_cloth", "from_era": 2, "overlays": &"weavers_row",
	},
	&"town_wall": {
		"name": "Town wall", "at_x": -384.0, "z": 63, "place": &"west_village",
		"kind": Kind.FLAG, "key": &"town_wall", "behind": true, "from_era": 2,
		"replaced_by": &"rampart",
	},
	&"flax_beaten": {
		"name": "Beaten flax", "at_x": -384.0, "at_y": -5, "z": 74, "place": &"west_village",
		"kind": Kind.FLAG, "key": &"flax_beaten", "alt_of": &"flax_thread",
		"replaced_by": &"weavers_row",
	},
	# The yard in front of the cave, beside the knapping spot.
	&"green_stones": {
		"name": "Green stones", "at_x": 0.0, "at_y": -4, "z": 75, "place": &"cave_yard",
		"kind": Kind.FLAG, "key": &"green_stone", "until_era": 2,
	},
	&"clay_pits": {
		"name": "Clay pits", "at_x": 0.0, "at_y": -4, "z": 74, "place": &"cave_yard",
		"kind": Kind.ACHIEVEMENT, "key": &"fired_clay", "replaced_by": &"potters_yard",
	},
	# The river (docs/ages.md V13): the crossing runs over the camp page and the east page, so it
	# is two pieces; the rest sits on the near bank and in the shallows (camp page), or on the
	# flats (east page). Mirrors tools/art/cave_river.js and settled_camp.js.
	&"crossing_stones": {
		"name": "Stepping stones", "at_x": 0.0, "z": 70, "place": &"river_bank",
		"kind": Kind.FLAG, "key": &"stepping_stones", "replaced_by": &"crossing_planks",
	},
	&"east_crossing_stones": {
		"name": "Stepping stones", "at_x": 384.0, "z": 70, "place": &"east_shore",
		"kind": Kind.FLAG, "key": &"stepping_stones", "replaced_by": &"east_crossing_planks",
	},
	&"crossing_log": {
		"name": "Log bridge", "at_x": 0.0, "z": 70, "place": &"river_bank",
		"kind": Kind.FLAG, "key": &"log_bridge", "alt_of": &"crossing_stones",
		"replaced_by": &"crossing_planks",
	},
	&"east_crossing_log": {
		"name": "Log bridge", "at_x": 384.0, "z": 70, "place": &"east_shore",
		"kind": Kind.FLAG, "key": &"log_bridge", "alt_of": &"east_crossing_stones",
		"replaced_by": &"east_crossing_planks",
	},
	&"river_trap": {
		"name": "Willow fish trap", "at_x": 0.0, "z": 72, "place": &"river_bank",
		"kind": Kind.FLAG, "key": &"fish_trap", "replaced_by": &"quay_boats",
	},
	&"reed_bundles": {
		"name": "Reed bundles", "at_x": 0.0, "z": 74, "place": &"river_bank",
		"kind": Kind.FLAG, "key": &"reed_beds",
	},
	&"flax_thread": {
		"name": "Flax soaking", "at_x": 0.0, "z": 72, "place": &"river_bank",
		"kind": Kind.FLAG, "key": &"flax_thread", "replaced_by": &"quay_boats",
	},
	&"river_bank": {
		"name": "Flood bank", "at_x": 0.0, "z": 60, "place": &"river_bank",
		"kind": Kind.FLAG, "key": &"river_bank", "behind": true,
	},
	&"boat_dugout": {
		"name": "Dugout canoe", "at_x": 0.0, "z": 71, "place": &"river_bank",
		"kind": Kind.FLAG, "key": &"dugout_canoe", "replaced_by": &"quay_boats",
	},
	&"boat_raft": {
		"name": "Reed raft", "at_x": 0.0, "z": 71, "place": &"river_bank",
		"kind": Kind.FLAG, "key": &"reed_raft", "alt_of": &"boat_dugout", "replaced_by": &"quay_boats",
	},
	&"east_tide_weir": {
		"name": "Stone weir", "at_x": 384.0, "z": 77, "place": &"east_shore",
		"kind": Kind.FLAG, "key": &"tide_weir",
	},
	# The coast's work, on the spit (the east page was the emptiest): what the group does with the
	# sea once it has had it, each shown by the flag that says it was done.
	&"east_salt_pans": {
		"name": "Salt pans", "at_x": 384.0, "z": 74, "place": &"east_shore",
		"kind": Kind.FLAG, "key": &"salt",
	},
	&"east_shell_heap": {
		"name": "Shell heap", "at_x": 384.0, "z": 76, "place": &"east_shore",
		"kind": Kind.FLAG, "key": &"shellfish_gathered",
	},
	&"east_driftwood_stack": {
		"name": "Driftwood stack", "at_x": 384.0, "z": 74, "place": &"east_shore",
		"kind": Kind.FLAG, "key": &"driftwood_gathered",
	},
	&"east_tide_baskets": {
		"name": "Tide baskets", "at_x": 384.0, "z": 76, "place": &"east_shore",
		"kind": Kind.FLAG, "key": &"tide_baskets",
	},
	&"east_sail": {
		"name": "Trading ship", "at_x": 384.0, "z": 60, "place": &"east_shore",
		"kind": Kind.FLAG, "key": &"far_shore",
		"replaced_by": [&"east_deep_ship", &"east_harbour"],
	},
	# What the Bronze Age's roads put on the ground (docs/ages.md): a market, a cart, donkeys, a
	# hard road, and the boats tied up at the quay in place of the ones afloat in the shallows.
	&"crossing_planks": {
		"name": "Plank bridge", "at_x": 0.0, "z": 70, "place": &"river_bank",
		"kind": Kind.FLAG, "key": &"road_laid", "from_era": 2,
	},
	&"east_crossing_planks": {
		"name": "Plank bridge", "at_x": 384.0, "z": 70, "place": &"east_shore",
		"kind": Kind.FLAG, "key": &"road_laid", "from_era": 2,
	},
	&"market_stalls": {
		"name": "Market stalls", "at_x": -384.0, "at_y": -3, "z": 67, "place": &"west_market",
		"kind": Kind.FLAG, "key": &"market_day", "from_era": 2, "replaced_by": &"market_arcade",
	},
	# The other two roads to a town share the market's spot: only one was ever taken.
	&"council_ring": {
		"name": "Council ring", "at_x": -384.0, "at_y": -3, "z": 67, "place": &"west_market",
		"kind": Kind.FLAG, "key": &"council", "from_era": 2, "alt_of": &"market_stalls",
		"replaced_by": &"market_arcade",
	},
	&"tally_post": {
		"name": "Tally post", "at_x": -384.0, "at_y": -3, "z": 67, "place": &"west_market",
		"kind": Kind.FLAG, "key": &"tally", "from_era": 2, "alt_of": &"market_stalls",
		"replaced_by": [&"writing_post", &"market_arcade"],
	},
	# One tidy farmstead for each way of life (the plot, scarecrow and hens; the patch and the pen).
	&"farmstead_herd": {
		"name": "Sheepfold", "at_x": -384.0, "at_y": -12, "z": 67, "place": &"west_village",
		"kind": Kind.FLAG, "key": &"path_herding", "from_era": 2,
	},
	&"cart": {
		"name": "Cart", "at_x": -384.0, "at_y": -2, "z": 77, "place": &"west_market",
		"kind": Kind.FLAG, "key": &"cart", "from_era": 2, "replaced_by": &"market_arcade",
	},
	&"donkeys": {
		"name": "Donkeys", "at_x": -384.0, "at_y": -2, "z": 77, "place": &"west_market",
		"kind": Kind.FLAG, "key": &"donkeys", "from_era": 2, "replaced_by": &"market_arcade",
	},
	# The Bronze Age's road runs from the west edge to the bridge in five flat pieces, one per place it
	# crosses (as the Classical street does, which replaces each in turn).
	&"road_market": {
		"name": "Road", "at_x": -384.0, "z": 54, "place": &"west_market",
		"kind": Kind.FLAG, "key": &"road_laid", "from_era": 2, "behind": true, "ground": true,
		"replaced_by": &"paved_street_market",
	},
	&"road_west": {
		"name": "Road", "at_x": -384.0, "z": 54, "place": &"west_village",
		"kind": Kind.FLAG, "key": &"road_laid", "from_era": 2, "behind": true, "ground": true,
		"replaced_by": &"paved_street_west",
	},
	&"road_hall": {
		"name": "Road", "at_x": 0.0, "z": 54, "place": &"cave_mouth",
		"kind": Kind.FLAG, "key": &"road_laid", "from_era": 2, "behind": true, "ground": true,
		"replaced_by": &"paved_street_hall",
	},
	&"road_camp": {
		"name": "Road", "at_x": 0.0, "z": 54, "place": &"cave_yard",
		"kind": Kind.FLAG, "key": &"road_laid", "from_era": 2, "behind": true, "ground": true,
		"replaced_by": &"paved_street",
	},
	&"road_bank": {
		"name": "Road", "at_x": 0.0, "z": 54, "place": &"river_bank",
		"kind": Kind.FLAG, "key": &"road_laid", "from_era": 2, "behind": true, "ground": true,
		"replaced_by": &"paved_street_bank",
	},
	&"quay_boats": {
		"name": "Boats at the quay", "at_x": 0.0, "z": 73, "place": &"river_bank",
		"kind": Kind.BUILDING, "key": &"quay", "from_era": 2,
	},
	# What the Iron Age puts on the ground (docs/ages.md, "What Iron tidies"; tools/art/iron_camp.js).
	# The Bronze wall is redrawn as a rampart, the tally post as a writing post and the trading
	# ship as a deep-keeled one; the rest is new.
	&"rampart": {
		"name": "Rampart", "at_x": -384.0, "z": 63, "place": &"west_village",
		"kind": Kind.FLAG, "key": &"hill_fort", "behind": true, "from_era": 3,
	},
	&"slag_heap": {
		"name": "Slag heap", "at_x": 0.0, "z": 77, "place": &"cave_yard",
		"kind": Kind.ACHIEVEMENT, "key": &"first_bloom", "from_era": 3,
	},
	&"shearing_pen": {
		"name": "Shearing pen", "at_x": -384.0, "z": 78, "place": &"west_village",
		"kind": Kind.FLAG, "key": &"iron_shears", "from_era": 3,
	},
	# The coin tray is a small trestle in the gap between the market and the weavers' row (the
	# stalls, the council ring and the tally post all end at x 55), so it lies on none of them.
	&"coin_tray": {
		"name": "Coin tray", "at_x": -384.0, "z": 68, "place": &"west_village",
		"kind": Kind.FLAG, "key": &"coin_struck", "from_era": 3, "replaced_by": &"market_arcade",
	},
	# The tally post's bench and cords are gone: a writing post stands at the market's left edge,
	# beside the stalls or the council ring, with its foot behind the cart.
	&"writing_post": {
		"name": "Writing post", "at_x": -384.0, "z": 66, "place": &"west_market",
		"kind": Kind.FLAG, "key": &"letters", "from_era": 3,
		"replaced_by": [&"law_pillar", &"market_arcade"],
	},
	&"standing_stone": {
		"name": "Standing stone", "at_x": 0.0, "z": 78, "place": &"river_bank",
		"kind": Kind.FLAG, "key": &"standing_stone", "from_era": 3,
	},
	&"east_deep_ship": {
		"name": "Ship", "at_x": 384.0, "z": 60, "place": &"east_shore",
		"kind": Kind.FLAG, "key": &"known_abroad", "from_era": 3, "replaced_by": &"east_harbour",
	},
	&"east_beacon": {
		"name": "Beacon", "at_x": 384.0, "z": 77, "place": &"east_shore",
		"kind": Kind.FLAG, "key": &"beacon_lit", "from_era": 3, "replaced_by": &"east_harbour",
	},
	# The Cave Age's own pennant, on the cliff above the cave: it shows from the first day and goes
	# when the age turns, because the cliff itself is replaced by the next age's signature building
	# (`static_back` in each age's art folder, docs/ages.md, "One signature building per age").
	&"cave_standard_cave": {
		"name": "Standard", "at_x": 0.0, "z": 22, "place": &"cave_cliff",
		"kind": Kind.ALWAYS, "key": &"", "from_era": 0, "until_era": 1,
	},
	# Decor: the bushes, rocks, stumps and driftwood the world is dressed with. Each is its own piece
	# (`"decor": true`, kind `ALWAYS`, always shown) in a prop space like any prop, and ranked below every
	# prop (`LanePieces`, rank 5), so the first thing hidden when props need the room. Art: tools/art/
	# cave_strip.js and cave_pages.js (`decor_camp_<n>`, `west_decor_<n>`, `east_decor_<n>`).
	&"decor_camp_0": {
		"name": "Rocks", "at_x": 0.0, "z": 72, "place": &"cave_yard", "decor": true,
		"kind": Kind.ALWAYS, "key": &"",
	},
	&"decor_camp_1": {
		"name": "Rocks", "at_x": 0.0, "z": 72, "place": &"cave_yard", "decor": true,
		"kind": Kind.ALWAYS, "key": &"",
	},
	&"west_decor_0": {
		"name": "Stump", "at_x": -384.0, "z": 72, "place": &"west_village", "decor": true,
		"kind": Kind.ALWAYS, "key": &"",
	},
	&"west_decor_1": {
		"name": "Stump", "at_x": -384.0, "z": 72, "place": &"west_village", "decor": true,
		"kind": Kind.ALWAYS, "key": &"",
	},
	&"west_decor_2": {
		"name": "Fallen log", "at_x": -384.0, "z": 72, "place": &"west_village", "decor": true,
		"kind": Kind.ALWAYS, "key": &"",
	},
	&"west_decor_3": {
		"name": "Bush", "at_x": -384.0, "z": 72, "place": &"west_village", "decor": true,
		"kind": Kind.ALWAYS, "key": &"",
	},
	&"west_decor_4": {
		"name": "Bush", "at_x": -384.0, "z": 72, "place": &"west_village", "decor": true,
		"kind": Kind.ALWAYS, "key": &"",
	},
	&"west_decor_5": {
		"name": "Bush", "at_x": -384.0, "z": 72, "place": &"west_village", "decor": true,
		"kind": Kind.ALWAYS, "key": &"",
	},
	&"west_decor_6": {
		"name": "Rocks", "at_x": -384.0, "z": 72, "place": &"west_village", "decor": true,
		"kind": Kind.ALWAYS, "key": &"",
	},
	&"west_decor_7": {
		"name": "Rocks", "at_x": -384.0, "z": 72, "place": &"west_village", "decor": true,
		"kind": Kind.ALWAYS, "key": &"",
	},
	&"east_decor_0": {
		"name": "Rocks", "at_x": 384.0, "z": 72, "place": &"east_shore", "decor": true,
		"kind": Kind.ALWAYS, "key": &"",
	},
	&"east_decor_1": {
		"name": "Rocks", "at_x": 384.0, "z": 72, "place": &"east_shore", "decor": true,
		"kind": Kind.ALWAYS, "key": &"",
	},
	&"east_decor_2": {
		"name": "Bush", "at_x": 384.0, "z": 72, "place": &"east_shore", "decor": true,
		"kind": Kind.ALWAYS, "key": &"",
	},
	&"east_decor_3": {
		"name": "Bush", "at_x": 384.0, "z": 72, "place": &"east_shore", "decor": true,
		"kind": Kind.ALWAYS, "key": &"",
	},
	&"east_decor_4": {
		"name": "Driftwood", "at_x": 384.0, "z": 72, "place": &"east_shore", "decor": true,
		"kind": Kind.ALWAYS, "key": &"",
	},
	&"east_decor_5": {
		"name": "Driftwood", "at_x": 384.0, "z": 72, "place": &"east_shore", "decor": true,
		"kind": Kind.ALWAYS, "key": &"",
	},
	# The Classical Age (docs/ages.md, "Classical Age"): what its milestones put on the ground. Each
	# one folds older pieces into a tidier whole (`replaced_by` on the old ones), so the town gets
	# denser in what it is, not just in how many things it has. Art: tools/art/classical_camp.js.
	# The street runs from the west edge to the bridge. It is one road in five pieces, one per place it
	# crosses; it is flat on the ground (`ground`), so it is not counted in a page's budget.
	&"paved_street_market": {
		"name": "Paved street", "at_x": -384.0, "z": 54, "place": &"west_market",
		"kind": Kind.ACHIEVEMENT, "key": &"paved_streets", "from_era": 4, "behind": true, "ground": true,
	},
	&"paved_street_west": {
		"name": "Paved street", "at_x": -384.0, "z": 54, "place": &"west_village",
		"kind": Kind.ACHIEVEMENT, "key": &"paved_streets", "from_era": 4, "behind": true, "ground": true,
	},
	&"paved_street_hall": {
		"name": "Paved street", "at_x": 0.0, "z": 54, "place": &"cave_mouth",
		"kind": Kind.ACHIEVEMENT, "key": &"paved_streets", "from_era": 4, "behind": true, "ground": true,
	},
	&"paved_street": {
		"name": "Paved street", "at_x": 0.0, "z": 54, "place": &"cave_yard",
		"kind": Kind.ACHIEVEMENT, "key": &"paved_streets", "from_era": 4, "behind": true, "ground": true,
	},
	&"paved_street_bank": {
		"name": "Paved street", "at_x": 0.0, "z": 54, "place": &"river_bank",
		"kind": Kind.ACHIEVEMENT, "key": &"paved_streets", "from_era": 4, "behind": true, "ground": true,
	},
	&"water_court": {
		"name": "Water court", "at_x": -384.0, "z": 74, "place": &"west_village",
		"kind": Kind.ACHIEVEMENT, "key": &"water_from_afar", "from_era": 4,
	},
	&"law_pillar": {
		"name": "Law pillar", "at_x": -384.0, "z": 66, "place": &"west_market",
		"kind": Kind.ACHIEVEMENT, "key": &"written_law", "from_era": 4,
		"replaced_by": &"market_arcade",
	},
	&"market_arcade": {
		"name": "Market arcade", "at_x": -384.0, "z": 67, "place": &"west_market",
		"kind": Kind.ACHIEVEMENT, "key": &"the_square", "from_era": 4,
	},
	&"east_theatre": {
		"name": "Theatre", "at_x": 384.0, "z": 67, "place": &"east_shore",
		"kind": Kind.ACHIEVEMENT, "key": &"lamp_and_stage", "from_era": 4,
	},
	&"east_harbour": {
		"name": "Harbour", "at_x": 384.0, "z": 60, "place": &"east_shore",
		"kind": Kind.ACHIEVEMENT, "key": &"wider_world", "from_era": 4,
	},
}


static func ids() -> Array[StringName]:
	var found: Array[StringName] = []
	for id: StringName in PROPS:
		found.append(id)
	return found


## Whether a prop is decor (a bush, a rock): always shown, the first thing hidden for room.
static func is_decor(id: StringName) -> bool:
	return PROPS.get(id, {}).get("decor", false)


static func z_of(id: StringName) -> int:
	return int(PROPS[id]["z"])


static func at_x_of(id: StringName) -> float:
	return float(PROPS[id]["at_x"])


## How far a prop's sprite is lifted onto its lane (negative is up; the art keeps its rows, and the
## sprite moves). 0 for a piece drawn where it stands.
static func at_y_of(id: StringName) -> float:
	return float(PROPS[id].get("at_y", 0))


## The place a prop belongs to (`WorldLayout.PLACES`), or "" for an unknown prop.
static func place_of(id: StringName) -> StringName:
	if not PROPS.has(id):
		return &""
	return PROPS[id].get("place", &"")


## What the player sees on hover; every prop must have one (a test enforces it).
static func name_of(id: StringName) -> String:
	if not PROPS.has(id):
		return ""
	return String(PROPS[id].get("name", ""))


## Whether the world shows a prop: it holds what the prop waits for, the age has not outgrown it
## (`until_era`), and nothing that replaces it is shown (`replaced_by`).
static func is_shown(id: StringName, world: WorldState) -> bool:
	return is_shown_in(PROPS, id, world)


## `is_shown` over any table of props (so the rules can be tested without a real one).
static func is_shown_in(props: Dictionary, id: StringName, world: WorldState) -> bool:
	if not props.has(id):
		return false
	var prop: Dictionary = props[id]
	if prop.has("from_era") and world.era_order < int(prop["from_era"]):
		return false
	if prop.has("until_era") and world.era_order >= int(prop["until_era"]):
		return false
	if prop.has("replaced_by"):
		for replacer: StringName in replacements_of(prop):
			if is_shown_in(props, replacer, world):
				return false
	return holds(prop["kind"], prop["key"], world)


## The props that can take a prop's place: its `replaced_by` is one id, or an array of them (the
## low wall gives way to the town wall and to the rampart).
static func replacements_of(prop: Dictionary) -> Array[StringName]:
	var found: Array[StringName] = []
	var raw: Variant = prop.get("replaced_by", [])
	if raw is Array:
		for id: StringName in raw:
			found.append(id)
	else:
		found.append(raw)
	return found


## Whether the world holds what a prop of this `kind` and `key` waits for.
static func holds(kind: Kind, key: StringName, world: WorldState) -> bool:
	match kind:
		Kind.FLAG:
			return world.has_flag(key)
		Kind.ACHIEVEMENT:
			return world.has_achievement(key)
		Kind.BUILDING:
			return world.has_building(key)
		Kind.ALWAYS:
			return true
	return false


## Every prop the world currently shows, but for decor: a bush or a rock is always there and is no
## prop the group earned (see `is_decor`).
static func shown(world: WorldState) -> Array[StringName]:
	var found: Array[StringName] = []
	for id: StringName in PROPS:
		if not is_decor(id) and is_shown(id, world):
			found.append(id)
	return found
