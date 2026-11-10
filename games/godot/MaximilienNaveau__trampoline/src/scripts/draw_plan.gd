# How many tiles a player may hold, keyed by number of players (see
# doc/RULES.md's "Turns and draws"). The rules' first draw — 13 tiles for
# 2 players, 12 for 3, 11 for 4 — is also the most a player ever holds:
# each turn starts by refilling the hand back up to it from the shared
# bag, for as long as the bag has tiles. Solo play holds 9, one full word.
class_name DrawPlan
extends RefCounted

const _HAND_SIZE := {1: 9, 2: 13, 3: 12, 4: 11}


# The most tiles one player may hold in a game of `number_of_players`.
static func hand_size(number_of_players: int) -> int:
	return _HAND_SIZE[number_of_players]
