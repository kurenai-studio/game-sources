# The "Comment jouer" cards (see how_to_play_view.gd), as plain data: one
# short caption each, and a little script of steps a ghost finger acts
# out on a mini board, looping — the rules shown, not explained.
#
# Pure data, no drawing: adding, removing or reordering a card is an edit
# here, never in the animation code.
#
# Each card is a Dictionary:
#   "caption": the one line shown above the animation.
#   "rows":    how many board rows the mini board shows.
#   "hand":    the tiles in the hand, left to right ("" = no hand).
#   "tray":    true to show the "À rendre" tray beside the hand.
#   "refill":  tiles that slide into the hand after an "end_turn" step.
#   "slots":   how many tiles the hand makes room for (default: as many
#              as "hand" has) — more, for tiles swapped into it.
#   "hand_buttons": true to show "Trier", "Tout jaune", "Tout vert"
#              under the hand.
#   "steps":   what happens, in order (see below).
#
# Tiles are written as plain letters; each one is a real tile from the
# game's 117 (see tile_pool.gd), so its corner shows its real other face.
# A lowercase letter is a tile showing its green face. "backs" overrides
# the other face of some letters of a word, by index (e.g. an L that
# flips to F).
#
# Steps:
#   {"word": "MAISON", "row": r, "col": c, "backs": {0: "F"}} — tiles
#       appear at once, popping in one after another ("backs" optional).
#   {"drag": i, "to": [r, c]}  — the finger drags hand tile i onto a cell;
#       onto a tile, the two swap: that one slides into the hand.
#   {"box": [[r, c], [r, c]], "grab": [r, c], "to": [r, c]} — the finger
#       draws the dotted box between two cells (the first one empty), then
#       drags the tiles inside by the one at "grab" to "to".
#   {"arrange": i, "before": j} — the finger drags hand tile i to just
#       before hand tile j (as the hand starts out).
#   {"button": "Trier"}        — the finger taps a button under the hand.
#   {"reset": true}            — the finger taps "Recommencer": the card
#       goes back to how it started.
#   {"tap": [r, c]}            — the finger taps a board tile: it flips.
#   {"float": "+21", "at": [r, c]} — a score floats up from a cell.
#   {"discard": i}             — the finger drags hand tile i to the tray.
#   {"end_turn": true}         — the finger taps "Fin du tour": the tray
#       empties and the "refill" tiles slide into the hand's gaps.
#   {"wait": seconds}
class_name HowToPlayCards
extends RefCounted

const CARDS := [
	{
		"caption": "13 mots de 9 lettres",
		"rows": 13,
		"hand": "",
		"steps":
		[
			{"word": "PERROQUET", "row": 0, "col": 0},
			{"word": "JARDINIER", "row": 1, "col": 0},
			{"word": "AMBULANCE", "row": 2, "col": 0},
			{"word": "SIFFLEREZ", "row": 3, "col": 0},
			{"word": "KARLFELDT", "row": 4, "col": 0},
			{"word": "WISIGOTHE", "row": 5, "col": 0},
			{"word": "DANGEREUX", "row": 6, "col": 0},
			{"word": "SYMPHONIE", "row": 7, "col": 0},
			{"word": "COUTERAIS", "row": 8, "col": 0},
			{"word": "BOMBONNES", "row": 9, "col": 0},
			{"word": "SURVIVENT", "row": 10, "col": 0},
			{"word": "ACCEPTEES", "row": 11, "col": 0},
			{"word": "ASTIQUENT", "row": 12, "col": 0},
			{"wait": 1.5},
		],
	},
	{
		"caption": "Posez un mot sur une ligne, à partir de la première colonne",
		"rows": 3,
		"hand": "MAISONRT",
		"steps":
		[
			{"drag": 0, "to": [1, 0]},
			{"drag": 1, "to": [1, 1]},
			{"drag": 2, "to": [1, 2]},
			{"drag": 3, "to": [1, 3]},
			{"drag": 4, "to": [1, 4]},
			{"drag": 5, "to": [1, 5]},
			{"float": "+21", "at": [1, 2]},
			{"wait": 1.5},
		],
	},
	{
		"caption": "Touchez une lettre pour la retourner",
		"rows": 3,
		"hand": "",
		"steps":
		[
			{"word": "LAIT", "row": 1, "col": 0, "backs": {0: "F"}},
			{"wait": 0.8},
			{"tap": [1, 0]},
			{"wait": 1.2},
			{"tap": [1, 0]},
			{"wait": 0.8},
		],
	},
	{
		"caption": "Allongez les mots : les dernières lettres rapportent plus",
		"rows": 3,
		"hand": "NEERT",
		"steps":
		[
			{"word": "MAISON", "row": 1, "col": 0},
			{"wait": 0.6},
			{"drag": 0, "to": [1, 6]},
			{"float": "+7", "at": [1, 6]},
			{"drag": 1, "to": [1, 7]},
			{"float": "+8", "at": [1, 7]},
			{"drag": 2, "to": [1, 8]},
			{"float": "+9", "at": [1, 8]},
			{"wait": 1.5},
		],
	},
	{
		"caption": "Le jaune rapporte, le vert coûte",
		"rows": 3,
		"hand": "",
		"steps":
		[
			{"word": "PERROQUET", "row": 0, "col": 0},
			{"float": "+50", "at": [0, 4]},
			{"wait": 0.6},
			{"word": "JARdINIER", "row": 2, "col": 0},
			{"float": "−5", "at": [2, 3]},
			{"wait": 1.5},
		],
	},
	{
		"caption": "Posée sur une lettre, elle l'échange : l'autre revient dans la main",
		"rows": 3,
		"hand": "R",
		"slots": 2,
		"steps":
		[
			{"word": "MAISON", "row": 1, "col": 0},
			{"wait": 0.6},
			{"drag": 0, "to": [1, 0]},
			{"wait": 1.5},
		],
	},
	{
		"caption": "Encadrez des lettres pour les déplacer, puis remplissez les cases vidées",
		"rows": 3,
		"hand": "PAR",
		"steps":
		[
			{"word": "TOUT", "row": 1, "col": 0},
			{"wait": 0.6},
			{"box": [[0, 0], [2, 3]], "grab": [1, 0], "to": [1, 3]},
			{"drag": 0, "to": [1, 0]},
			{"drag": 1, "to": [1, 1]},
			{"drag": 2, "to": [1, 2]},
			{"float": "+18", "at": [1, 3]},
			{"wait": 1.5},
		],
	},
	{
		"caption": "« Recommencer » remet tout comme au début du tour",
		"rows": 3,
		"hand": "RT",
		"slots": 3,
		"steps":
		[
			{"word": "MAISON", "row": 1, "col": 0},
			{"wait": 0.5},
			{"drag": 0, "to": [1, 0]},
			{"tap": [1, 1]},
			{"wait": 0.4},
			{"reset": true},
			{"wait": 1.2},
		],
	},
	{
		"caption": "Rangez votre main : glissez, triez, tout en jaune ou en vert",
		"rows": 1,
		"hand": "TRAMPOLI",
		"hand_buttons": true,
		"steps":
		[
			{"arrange": 7, "before": 0},
			{"wait": 0.4},
			{"button": "Trier"},
			{"wait": 0.6},
			{"button": "Tout vert"},
			{"wait": 0.8},
			{"button": "Tout jaune"},
			{"wait": 1.2},
		],
	},
	{
		"caption": "Rendez des lettres, piochez-en d'autres",
		"rows": 2,
		"hand": "KAWEQIRT",
		"tray": true,
		"refill": "SL",
		"steps":
		[
			{"discard": 0},
			{"discard": 2},
			{"wait": 0.4},
			{"end_turn": true},
			{"wait": 1.5},
		],
	},
]
