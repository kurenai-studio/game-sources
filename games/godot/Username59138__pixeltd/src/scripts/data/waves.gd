class_name Waves
extends RefCounted
## Handmade waves, one list per difficulty (like TDS). After the last wave, Continue switches to the
## generator in Defs.build_wave().
##
## A wave is a list of groups: [enemy, count, gap, at] plus any modifiers, e.g. [enemy, count, gap, at, "lead"]
##   enemy  enemy id from Defs.ENEMIES; its HP is fixed there, every map and difficulty uses the same
##   count  how many
##   gap    seconds between two enemies of the group
##   at     seconds after the wave starts when the group's first enemy comes out
##   "bloated"  Defs.BLOATED_HP times the HP (bounty grows with it)
##   "lead"     only towers that pierce lead can hurt it
## A wave with a boss type (Defs.BOSS_TYPES) in it is a boss wave.

const LISTS := {
	"light": [
		[["slime", 2, 0.55, 0.0]],   # 1
		[["slime", 3, 0.55, 0.0], ["rat", 2, 0.35, 2.6]],   # 2
		[["goblin", 2, 0.6, 0.0], ["rat", 1, 0.35, 2.1]],   # 3
		[["goblin", 3, 0.6, 0.0], ["skeleton", 1, 0.6, 2.7]],   # 4
		[["skeleton", 2, 0.6, 0.0], ["goblin", 2, 0.6, 2.1], ["bat", 3, 0.3, 3.1]],   # 5
		[["wolf", 3, 0.45, 0.0], ["skeleton", 2, 0.6, 2.4]],   # 6
		[["goblin", 4, 0.6, 0.0, "bloated"], ["wolf", 3, 0.45, 3.3], ["imp", 1, 0.6, 4.3]],   # 7
		[["ironclad", 2, 0.9, 0.0], ["wolf", 4, 0.45, 1.0], ["skeleton", 3, 0.6, 3.85, "bloated"]],   # 8
		[["bat", 6, 0.3, 0.0], ["imp", 4, 0.6, 3.0], ["berserker", 1, 1.1, 4.0], ["skeleton", 3, 0.6, 6.3]],   # 9
		[["wolf", 5, 0.45, 0.0, "bloated"], ["ironclad", 4, 0.9, 3.3], ["berserker", 3, 1.1, 4.3], ["shaman", 1, 1.4, 5.3], ["ogre", 1, 2.2, 8.0]],   # 10
		[["ghost", 3, 0.8, 0.0, "bloated"], ["berserker", 4, 1.1, 3.1], ["ironclad", 4, 0.9, 4.1, "bloated"]],   # 11
		[["skeleton", 5, 0.6, 0.0, "bloated"], ["imp", 5, 0.6, 1.0], ["shaman", 1, 1.4, 4.9], ["ogre", 2, 2.2, 5.9]],   # 12
		[["wolf", 6, 0.45, 0.0, "bloated"], ["ghost", 4, 0.8, 1.0, "bloated"], ["berserker", 5, 1.1, 4.9], ["harpy", 2, 2.0, 5.9]],   # 13
		[["ironclad", 6, 0.9, 0.0, "bloated"], ["berserker", 5, 1.1, 1.0, "bloated"], ["shaman", 2, 1.4, 6.9], ["slime_king", 1, 1.8, 7.9]],   # 14
		[["imp", 8, 0.6, 0.0, "bloated"], ["ogre", 3, 2.2, 1.0], ["shaman", 3, 1.4, 6.9], ["slime_king", 3, 1.8, 7.9]],   # 15
		[["bat", 10, 0.3, 0.0, "bloated"], ["ghost", 6, 0.8, 1.0, "bloated"], ["berserker", 4, 1.1, 6.5], ["harpy", 5, 2.0, 7.5]],   # 16
		[["berserker", 8, 1.1, 0.0, "bloated"], ["shaman", 3, 1.4, 1.0], ["troll", 2, 1.8, 9.2], ["ogre", 3, 2.2, 10.2, "bloated"]],   # 17
		[["ironclad", 10, 0.9, 0.0, "bloated"], ["slime_king", 4, 1.8, 1.0, "bloated"], ["ogre", 1, 2.2, 9.6, "bloated"]],   # 18
		[["berserker", 8, 1.1, 0.0, "bloated"], ["ghost", 6, 0.8, 1.0, "bloated"], ["shaman", 3, 1.4, 9.2], ["troll", 5, 1.8, 10.2], ["harpy", 3, 2.0, 18.9, "bloated"]],   # 19
		[["skeleton", 10, 0.6, 0.0, "bloated"], ["ironclad", 10, 0.9, 1.0, "bloated"], ["ogre", 3, 2.2, 10.6, "bloated"], ["troll", 4, 1.8, 11.6], ["golem", 2, 6.0, 12.6]],   # 20
	],
	"medium": [
		[["slime", 2, 0.55, 0.0]],   # 1
		[["slime", 3, 0.55, 0.0], ["rat", 2, 0.35, 2.6]],   # 2
		[["goblin", 2, 0.6, 0.0], ["rat", 2, 0.35, 2.1]],   # 3
		[["goblin", 3, 0.6, 0.0], ["skeleton", 2, 0.6, 2.7]],   # 4
		[["skeleton", 2, 0.6, 0.0], ["goblin", 2, 0.6, 2.1], ["bat", 3, 0.3, 3.1]],   # 5
		[["wolf", 3, 0.45, 0.0], ["skeleton", 2, 0.6, 2.4]],   # 6
		[["goblin", 5, 0.6, 0.0, "bloated"], ["wolf", 3, 0.45, 3.9], ["imp", 2, 0.6, 4.9]],   # 7
		[["ironclad", 2, 0.9, 0.0], ["wolf", 5, 0.45, 1.0], ["skeleton", 3, 0.6, 4.3, "bloated"]],   # 8
		[["bat", 8, 0.3, 0.0], ["imp", 5, 0.6, 3.6], ["berserker", 2, 1.1, 4.6], ["skeleton", 3, 0.6, 7.5]],   # 9
		[["wolf", 6, 0.45, 0.0, "bloated"], ["ironclad", 5, 0.9, 3.75], ["berserker", 3, 1.1, 4.75], ["shaman", 1, 1.4, 5.75], ["ogre", 1, 2.2, 8.85]],   # 10
		[["ghost", 3, 0.8, 0.0, "bloated"], ["berserker", 5, 1.1, 3.1], ["ironclad", 5, 0.9, 4.1, "bloated"]],   # 11
		[["skeleton", 6, 0.6, 0.0, "bloated"], ["imp", 6, 0.6, 1.0], ["shaman", 2, 1.4, 5.5], ["ogre", 2, 2.2, 6.5]],   # 12
		[["wolf", 8, 0.45, 0.0, "bloated"], ["ghost", 5, 0.8, 1.0, "bloated"], ["berserker", 6, 1.1, 5.7], ["harpy", 2, 2.0, 6.7]],   # 13
		[["ironclad", 8, 0.9, 0.0, "bloated"], ["berserker", 6, 1.1, 1.0, "bloated"], ["shaman", 2, 1.4, 8.0], ["slime_king", 2, 1.8, 9.0]],   # 14
		[["imp", 10, 0.6, 0.0, "bloated"], ["ogre", 4, 2.2, 1.0], ["shaman", 3, 1.4, 9.1], ["slime_king", 3, 1.8, 10.1]],   # 15
		[["bat", 13, 0.3, 0.0, "bloated"], ["ghost", 8, 0.8, 1.0, "bloated"], ["berserker", 5, 1.1, 8.1], ["harpy", 6, 2.0, 9.1]],   # 16
		[["berserker", 10, 1.1, 0.0, "bloated"], ["shaman", 3, 1.4, 1.0], ["troll", 2, 1.8, 11.4], ["ogre", 3, 2.2, 12.4, "bloated"]],   # 17
		[["ironclad", 13, 0.9, 0.0, "bloated"], ["slime_king", 5, 1.8, 1.0, "bloated"], ["ogre", 2, 2.2, 12.3, "bloated"]],   # 18
		[["berserker", 10, 1.1, 0.0, "bloated"], ["ghost", 8, 0.8, 1.0, "bloated"], ["shaman", 3, 1.4, 11.4], ["troll", 6, 1.8, 12.4], ["harpy", 3, 2.0, 22.9, "bloated"]],   # 19
		[["skeleton", 13, 0.6, 0.0, "bloated"], ["ironclad", 13, 0.9, 1.0, "bloated"], ["ogre", 3, 2.2, 13.3, "bloated"], ["troll", 5, 1.8, 14.3], ["golem", 1, 6.0, 15.3]],   # 20
		[["bat", 16, 0.27, 0.0, "bloated"], ["ghost", 10, 0.72, 1.0, "bloated"], ["harpy", 8, 1.8, 8.98, "bloated"], ["gargoyle", 3, 1.44, 9.98], ["troll", 2, 1.62, 23.08]],   # 21
		[["ironclad", 16, 0.81, 0.0, "bloated"], ["ogre", 10, 1.98, 1.0, "bloated"], ["troll", 5, 1.62, 20.32], ["dark_knight", 2, 1.8, 21.32]],   # 22
		[["imp", 16, 0.54, 0.0, "bloated"], ["ghost", 13, 0.72, 1.0, "bloated"], ["troll", 8, 1.62, 11.14], ["shaman", 5, 1.26, 12.14], ["wraith", 8, 1.08, 23.98], ["gargoyle", 2, 1.44, 24.98]],   # 23
		[["ironclad", 16, 0.81, 0.0, "bloated"], ["slime_king", 8, 1.62, 1.0, "bloated"], ["shaman", 6, 1.26, 13.84], ["troll", 6, 1.62, 14.84], ["gargoyle", 3, 1.44, 24.44]],   # 24
		[["harpy", 6, 1.8, 0.0, "bloated"], ["ogre", 10, 1.98, 1.0, "bloated"], ["troll", 8, 1.62, 20.32], ["dark_knight", 6, 1.8, 21.32], ["mammoth", 2, 2.7, 33.16]],   # 25
		[["ironclad", 13, 0.81, 0.0, "bloated"], ["ogre", 10, 1.98, 1.0, "bloated"], ["troll", 10, 1.62, 20.32], ["dark_knight", 8, 1.8, 21.32]],   # 26
		[["ghost", 13, 0.72, 0.0, "bloated"], ["wraith", 19, 1.08, 1.0], ["troll", 13, 1.62, 21.94, "bloated"]],   # 27
		[["bat", 16, 0.27, 0.0, "bloated"], ["harpy", 13, 1.8, 1.0, "bloated"], ["gargoyle", 16, 1.44, 24.1], ["wraith", 6, 1.08, 25.1]],   # 28
		[["berserker", 19, 0.99, 0.0, "bloated"], ["shaman", 8, 1.26, 1.0], ["ogre", 16, 1.98, 19.32, "bloated"], ["dark_knight", 11, 1.8, 20.32], ["mammoth", 5, 2.7, 50.52]],   # 29
		[["ironclad", 16, 0.81, 0.0, "bloated"], ["troll", 16, 1.62, 1.0], ["harpy", 10, 1.8, 26.8, "bloated"], ["dark_knight", 8, 1.8, 27.8], ["bone_dragon", 1, 6.0, 28.8]],   # 30
	],
	"difficult": [
		[["slime", 3, 0.55, 0.0]],   # 1
		[["slime", 4, 0.55, 0.0], ["rat", 3, 0.35, 3.15]],   # 2
		[["goblin", 3, 0.6, 0.0], ["rat", 2, 0.35, 2.7]],   # 3
		[["goblin", 4, 0.6, 0.0], ["skeleton", 2, 0.6, 3.3]],   # 4
		[["skeleton", 3, 0.6, 0.0], ["goblin", 3, 0.6, 2.7], ["bat", 4, 0.3, 3.7]],   # 5
		[["wolf", 4, 0.45, 0.0], ["skeleton", 3, 0.6, 2.85]],   # 6
		[["goblin", 6, 0.6, 0.0, "bloated"], ["wolf", 4, 0.45, 4.5], ["imp", 2, 0.6, 5.5]],   # 7
		[["ironclad", 3, 0.9, 0.0], ["wolf", 6, 0.45, 1.0], ["skeleton", 4, 0.6, 4.75, "bloated"]],   # 8
		[["bat", 10, 0.3, 0.0], ["imp", 6, 0.6, 4.2], ["berserker", 2, 1.1, 5.2], ["skeleton", 4, 0.6, 8.7]],   # 9
		[["wolf", 8, 0.45, 0.0, "bloated"], ["ironclad", 6, 0.9, 4.65], ["berserker", 4, 1.1, 5.65], ["shaman", 1, 1.4, 6.65], ["ogre", 1, 2.2, 10.65]],   # 10
		[["ghost", 4, 0.8, 0.0, "bloated"], ["berserker", 6, 1.1, 3.9], ["ironclad", 6, 0.9, 4.9, "bloated"]],   # 11
		[["skeleton", 8, 0.6, 0.0, "bloated", "lead"], ["imp", 8, 0.6, 1.0], ["shaman", 2, 1.4, 6.7], ["ogre", 3, 2.2, 7.7]],   # 12
		[["wolf", 10, 0.45, 0.0, "bloated"], ["ghost", 6, 0.8, 1.0, "bloated"], ["berserker", 8, 1.1, 6.5], ["harpy", 3, 2.0, 7.5]],   # 13
		[["ironclad", 10, 0.9, 0.0, "bloated", "lead"], ["berserker", 8, 1.1, 1.0, "bloated"], ["shaman", 3, 1.4, 10.2], ["slime_king", 2, 1.8, 11.2]],   # 14
		[["imp", 12, 0.6, 0.0, "bloated"], ["ogre", 5, 2.2, 1.0], ["shaman", 4, 1.4, 11.3], ["slime_king", 4, 1.8, 12.3]],   # 15
		[["bat", 16, 0.3, 0.0, "bloated"], ["ghost", 10, 0.8, 1.0, "bloated"], ["berserker", 6, 1.1, 9.7, "lead"], ["harpy", 8, 2.0, 10.7]],   # 16
		[["berserker", 12, 1.1, 0.0, "bloated"], ["shaman", 4, 1.4, 1.0], ["troll", 3, 1.8, 13.6], ["ogre", 4, 2.2, 14.6, "bloated"]],   # 17
		[["ironclad", 16, 0.9, 0.0, "bloated"], ["slime_king", 6, 1.8, 1.0, "bloated"], ["ogre", 2, 2.2, 15.0, "bloated", "lead"]],   # 18
		[["berserker", 12, 1.1, 0.0, "bloated"], ["ghost", 10, 0.8, 1.0, "bloated"], ["shaman", 4, 1.4, 13.6], ["troll", 8, 1.8, 14.6], ["harpy", 4, 2.0, 28.7, "bloated"]],   # 19
		[["skeleton", 16, 0.6, 0.0, "bloated"], ["ironclad", 16, 0.9, 1.0, "bloated"], ["ogre", 4, 2.2, 16.0, "bloated"], ["troll", 6, 1.8, 17.0, "lead"], ["golem", 1, 6.0, 27.5]],   # 20
		[["bat", 20, 0.27, 0.0, "bloated"], ["ghost", 12, 0.72, 1.0, "bloated"], ["harpy", 10, 1.8, 10.42, "bloated"], ["gargoyle", 4, 1.44, 11.42], ["troll", 2, 1.62, 28.12]],   # 21
		[["ironclad", 20, 0.81, 0.0, "bloated"], ["ogre", 12, 1.98, 1.0, "bloated", "lead"], ["troll", 6, 1.62, 24.28], ["dark_knight", 2, 1.8, 25.28]],   # 22
		[["imp", 20, 0.54, 0.0, "bloated"], ["ghost", 16, 0.72, 1.0, "bloated"], ["troll", 10, 1.62, 13.3], ["shaman", 6, 1.26, 14.3], ["wraith", 10, 1.08, 29.38], ["gargoyle", 3, 1.44, 30.38]],   # 23
		[["ironclad", 20, 0.81, 0.0, "bloated"], ["slime_king", 10, 1.62, 1.0, "bloated"], ["shaman", 8, 1.26, 17.08], ["troll", 8, 1.62, 18.08, "lead"], ["gargoyle", 4, 1.44, 30.92]],   # 24
		[["harpy", 8, 1.8, 0.0, "bloated"], ["ogre", 12, 1.98, 1.0, "bloated"], ["troll", 10, 1.62, 24.28], ["dark_knight", 8, 1.8, 25.28, "lead"], ["mammoth", 2, 2.7, 40.36]],   # 25
		[["ironclad", 16, 0.81, 0.0, "bloated"], ["ogre", 12, 1.98, 1.0, "bloated", "lead"], ["troll", 12, 1.62, 24.28], ["dark_knight", 10, 1.8, 25.28]],   # 26
		[["ghost", 16, 0.72, 0.0, "bloated"], ["wraith", 24, 1.08, 1.0], ["troll", 16, 1.62, 27.34, "bloated"]],   # 27
		[["bat", 20, 0.27, 0.0, "bloated"], ["harpy", 16, 1.8, 1.0, "bloated"], ["gargoyle", 20, 1.44, 29.5, "lead"], ["wraith", 8, 1.08, 30.5]],   # 28
		[["berserker", 24, 0.99, 0.0, "bloated"], ["shaman", 10, 1.26, 1.0], ["ogre", 20, 1.98, 24.27, "bloated"], ["dark_knight", 14, 1.8, 25.27, "lead"], ["mammoth", 6, 2.7, 63.39]],   # 29
		[["ironclad", 20, 0.81, 0.0, "bloated"], ["troll", 20, 1.62, 1.0, "lead"], ["harpy", 12, 1.8, 33.28, "bloated"], ["dark_knight", 10, 1.8, 34.28], ["bone_dragon", 1, 6.0, 54.58]],   # 30
		[["imp", 20, 0.54, 0.0, "bloated"], ["slime_king", 16, 1.62, 1.0, "bloated"], ["troll", 20, 1.62, 26.8, "bloated", "lead"], ["gargoyle", 16, 1.44, 27.8]],   # 31
		[["ghost", 24, 0.72, 0.0, "bloated"], ["wraith", 30, 1.08, 1.0], ["ogre", 20, 1.98, 33.82, "bloated"], ["mammoth", 8, 2.7, 34.82, "lead"]],   # 32
		[["berserker", 30, 0.99, 0.0, "bloated"], ["shaman", 12, 1.26, 1.0], ["dark_knight", 30, 1.8, 30.21, "lead"], ["troll", 16, 1.62, 31.21, "bloated"]],   # 33
		[["bat", 40, 0.27, 0.0, "bloated"], ["harpy", 20, 1.8, 1.0, "bloated"], ["gargoyle", 30, 1.44, 36.7, "bloated", "lead"]],   # 34
		[["ironclad", 30, 0.81, 0.0, "bloated"], ["mammoth", 12, 2.7, 1.0, "lead"], ["dark_knight", 15, 1.8, 32.2, "bloated"], ["mammoth", 4, 2.7, 33.2, "bloated"]],   # 35
		[["ghost", 30, 0.72, 0.0, "bloated"], ["wraith", 30, 1.08, 1.0, "bloated"], ["troll", 30, 1.62, 33.82, "bloated", "lead"], ["gargoyle", 10, 1.44, 34.82, "bloated"]],   # 36
		[["shaman", 16, 1.26, 0.0], ["slime_king", 24, 1.62, 1.0, "bloated"], ["troll", 30, 1.62, 39.76, "bloated"], ["mammoth", 10, 2.7, 40.76, "lead"]],   # 37
		[["berserker", 30, 0.99, 0.0, "bloated"], ["harpy", 12, 1.8, 1.0, "bloated"], ["gargoyle", 30, 1.44, 30.21, "bloated"], ["dark_knight", 25, 1.8, 31.21, "bloated", "lead"]],   # 38
		[["ironclad", 40, 0.81, 0.0, "bloated"], ["dark_knight", 10, 1.8, 1.0, "bloated"], ["mammoth", 18, 2.7, 33.09, "bloated", "lead"], ["golem", 2, 6.0, 34.09, "bloated"]],   # 39
		[["gargoyle", 8, 1.44, 0.0, "bloated"], ["dark_knight", 10, 1.8, 1.0, "bloated"], ["mammoth", 12, 2.7, 18.7, "bloated", "lead"], ["demon", 1, 6.0, 19.7]],   # 40
	],
	"hardcore": [
		[["slime", 4, 0.55, 0.0]],   # 1
		[["slime", 5, 0.55, 0.0], ["rat", 4, 0.35, 3.7]],   # 2
		[["goblin", 4, 0.6, 0.0], ["rat", 2, 0.35, 3.3]],   # 3
		[["goblin", 5, 0.6, 0.0], ["skeleton", 2, 0.6, 3.9]],   # 4
		[["skeleton", 4, 0.6, 0.0], ["goblin", 4, 0.6, 3.3], ["bat", 5, 0.3, 4.3]],   # 5
		[["wolf", 5, 0.45, 0.0], ["skeleton", 4, 0.6, 3.3]],   # 6
		[["goblin", 8, 0.6, 0.0, "bloated"], ["wolf", 5, 0.45, 5.7], ["imp", 2, 0.6, 6.7]],   # 7
		[["ironclad", 4, 0.9, 0.0], ["wolf", 8, 0.45, 1.0], ["skeleton", 5, 0.6, 5.65, "bloated"]],   # 8
		[["bat", 12, 0.3, 0.0], ["imp", 8, 0.6, 4.8], ["berserker", 2, 1.1, 5.8], ["skeleton", 5, 0.6, 10.5]],   # 9
		[["wolf", 10, 0.45, 0.0, "bloated"], ["ironclad", 8, 0.9, 5.55], ["berserker", 5, 1.1, 6.55], ["shaman", 1, 1.4, 7.55], ["ogre", 1, 2.2, 13.35]],   # 10
		[["ghost", 5, 0.8, 0.0, "bloated"], ["berserker", 8, 1.1, 4.7], ["ironclad", 8, 0.9, 5.7, "bloated"]],   # 11
		[["skeleton", 10, 0.6, 0.0, "bloated", "lead"], ["imp", 10, 0.6, 1.0], ["shaman", 2, 1.4, 7.9], ["ogre", 4, 2.2, 8.9]],   # 12
		[["wolf", 12, 0.45, 0.0, "bloated"], ["ghost", 8, 0.8, 1.0, "bloated"], ["berserker", 10, 1.1, 8.1], ["harpy", 4, 2.0, 9.1]],   # 13
		[["ironclad", 12, 0.9, 0.0, "bloated", "lead"], ["berserker", 10, 1.1, 1.0, "bloated"], ["shaman", 4, 1.4, 12.4], ["slime_king", 2, 1.8, 13.4]],   # 14
		[["imp", 15, 0.6, 0.0, "bloated"], ["ogre", 6, 2.2, 1.0], ["shaman", 5, 1.4, 13.5], ["slime_king", 5, 1.8, 14.5]],   # 15
		[["bat", 20, 0.3, 0.0, "bloated"], ["ghost", 12, 0.8, 1.0, "bloated"], ["berserker", 8, 1.1, 11.3, "lead"], ["harpy", 10, 2.0, 12.3]],   # 16
		[["berserker", 15, 1.1, 0.0, "bloated"], ["shaman", 5, 1.4, 1.0], ["troll", 4, 1.8, 16.9], ["ogre", 5, 2.2, 17.9, "bloated"]],   # 17
		[["ironclad", 20, 0.9, 0.0, "bloated"], ["slime_king", 8, 1.8, 1.0, "bloated"], ["ogre", 2, 2.2, 18.6, "bloated", "lead"]],   # 18
		[["berserker", 15, 1.1, 0.0, "bloated"], ["ghost", 12, 0.8, 1.0, "bloated"], ["shaman", 5, 1.4, 16.9], ["troll", 10, 1.8, 17.9], ["harpy", 5, 2.0, 35.6, "bloated"]],   # 19
		[["skeleton", 20, 0.6, 0.0, "bloated"], ["ironclad", 20, 0.9, 1.0, "bloated"], ["ogre", 5, 2.2, 19.6, "bloated"], ["troll", 8, 1.8, 20.6, "lead"], ["golem", 1, 6.0, 21.6, "bloated"]],   # 20
		[["bat", 25, 0.27, 0.0, "bloated"], ["ghost", 15, 0.72, 1.0, "bloated"], ["harpy", 12, 1.8, 12.58, "bloated"], ["gargoyle", 5, 1.44, 13.58], ["troll", 2, 1.62, 33.88]],   # 21
		[["ironclad", 25, 0.81, 0.0, "bloated"], ["ogre", 15, 1.98, 1.0, "bloated", "lead"], ["troll", 8, 1.62, 30.22], ["dark_knight", 2, 1.8, 31.22]],   # 22
		[["imp", 25, 0.54, 0.0, "bloated"], ["ghost", 20, 0.72, 1.0, "bloated"], ["troll", 12, 1.62, 16.18], ["shaman", 8, 1.26, 17.18], ["wraith", 12, 1.08, 35.5], ["gargoyle", 4, 1.44, 36.5]],   # 23
		[["ironclad", 25, 0.81, 0.0, "bloated"], ["slime_king", 12, 1.62, 1.0, "bloated"], ["shaman", 10, 1.26, 20.94], ["troll", 10, 1.62, 21.94, "lead"], ["gargoyle", 5, 1.44, 38.02]],   # 24
		[["harpy", 10, 1.8, 0.0, "bloated"], ["ogre", 15, 1.98, 1.0, "bloated"], ["troll", 12, 1.62, 30.22], ["dark_knight", 10, 1.8, 31.22, "lead"], ["mammoth", 2, 2.7, 49.54]],   # 25
		[["ironclad", 20, 0.81, 0.0, "bloated"], ["ogre", 15, 1.98, 1.0, "bloated", "lead"], ["troll", 15, 1.62, 30.22], ["dark_knight", 12, 1.8, 31.22]],   # 26
		[["ghost", 20, 0.72, 0.0, "bloated"], ["wraith", 30, 1.08, 1.0], ["troll", 20, 1.62, 33.82, "bloated"]],   # 27
		[["bat", 25, 0.27, 0.0, "bloated"], ["harpy", 20, 1.8, 1.0, "bloated"], ["gargoyle", 25, 1.44, 36.7, "lead"], ["wraith", 10, 1.08, 37.7]],   # 28
		[["berserker", 30, 0.99, 0.0, "bloated"], ["shaman", 12, 1.26, 1.0], ["ogre", 25, 1.98, 30.21, "bloated"], ["dark_knight", 18, 1.8, 31.21, "lead"], ["mammoth", 8, 2.7, 79.23]],   # 29
		[["ironclad", 25, 0.81, 0.0, "bloated"], ["troll", 25, 1.62, 1.0, "lead"], ["harpy", 15, 1.8, 41.38, "bloated"], ["dark_knight", 12, 1.8, 42.38], ["bone_dragon", 1, 6.0, 43.38, "bloated"]],   # 30
		[["imp", 25, 0.54, 0.0, "bloated"], ["slime_king", 20, 1.62, 1.0, "bloated"], ["troll", 25, 1.62, 33.28, "bloated", "lead"], ["gargoyle", 20, 1.44, 34.28]],   # 31
		[["ghost", 30, 0.72, 0.0, "bloated"], ["wraith", 38, 1.08, 1.0], ["ogre", 25, 1.98, 42.46, "bloated"], ["mammoth", 10, 2.7, 43.46, "lead"]],   # 32
		[["berserker", 38, 0.99, 0.0, "bloated"], ["shaman", 15, 1.26, 1.0], ["dark_knight", 38, 1.8, 38.13, "lead"], ["troll", 20, 1.62, 39.13, "bloated"]],   # 33
		[["bat", 50, 0.27, 0.0, "bloated"], ["harpy", 25, 1.8, 1.0, "bloated"], ["gargoyle", 38, 1.44, 45.7, "bloated", "lead"]],   # 34
		[["ironclad", 38, 0.81, 0.0, "bloated"], ["mammoth", 15, 2.7, 1.0, "lead"], ["dark_knight", 19, 1.8, 40.3, "bloated"], ["mammoth", 5, 2.7, 41.3, "bloated"]],   # 35
		[["ghost", 38, 0.72, 0.0, "bloated"], ["wraith", 38, 1.08, 1.0, "bloated"], ["troll", 38, 1.62, 42.46, "bloated", "lead"], ["gargoyle", 12, 1.44, 43.46, "bloated"]],   # 36
		[["shaman", 20, 1.26, 0.0], ["slime_king", 30, 1.62, 1.0, "bloated"], ["troll", 38, 1.62, 49.48, "bloated"], ["mammoth", 12, 2.7, 50.48, "lead"]],   # 37
		[["berserker", 38, 0.99, 0.0, "bloated"], ["harpy", 15, 1.8, 1.0, "bloated"], ["gargoyle", 38, 1.44, 38.13, "bloated"], ["dark_knight", 31, 1.8, 39.13, "bloated", "lead"]],   # 38
		[["ironclad", 50, 0.81, 0.0, "bloated"], ["dark_knight", 12, 1.8, 1.0, "bloated"], ["mammoth", 22, 2.7, 41.19, "bloated", "lead"], ["golem", 3, 6.0, 42.19, "bloated"]],   # 39
		[["gargoyle", 10, 1.44, 0.0, "bloated"], ["dark_knight", 12, 1.8, 1.0, "bloated"], ["mammoth", 15, 2.7, 22.3, "bloated", "lead"], ["demon", 2, 6.0, 23.3, "bloated"]],   # 40
	],
	"ultracore": [
		[["slime", 4, 0.55, 0.0]],   # 1
		[["slime", 6, 0.55, 0.0], ["rat", 4, 0.35, 4.25]],   # 2
		[["goblin", 4, 0.6, 0.0], ["rat", 3, 0.35, 3.3]],   # 3
		[["goblin", 6, 0.6, 0.0], ["skeleton", 3, 0.6, 4.5]],   # 4
		[["skeleton", 4, 0.6, 0.0], ["goblin", 4, 0.6, 3.3], ["bat", 6, 0.3, 4.3]],   # 5
		[["wolf", 6, 0.45, 0.0], ["skeleton", 4, 0.6, 3.75]],   # 6
		[["goblin", 9, 0.6, 0.0, "bloated"], ["wolf", 6, 0.45, 6.3], ["imp", 3, 0.6, 7.3]],   # 7
		[["ironclad", 4, 0.9, 0.0], ["wolf", 9, 0.45, 1.0], ["skeleton", 6, 0.6, 6.1, "bloated"]],   # 8
		[["bat", 15, 0.3, 0.0], ["imp", 9, 0.6, 5.7], ["berserker", 3, 1.1, 6.7], ["skeleton", 6, 0.6, 12.0]],   # 9
		[["wolf", 12, 0.45, 0.0, "bloated"], ["ironclad", 9, 0.9, 6.45], ["berserker", 6, 1.1, 7.45], ["shaman", 2, 1.4, 8.45], ["ogre", 2, 2.2, 15.15, "lead"]],   # 10
		[["ghost", 6, 0.8, 0.0, "bloated"], ["berserker", 9, 1.1, 5.5], ["ironclad", 9, 0.9, 6.5, "bloated"]],   # 11
		[["skeleton", 12, 0.6, 0.0, "bloated", "lead"], ["imp", 12, 0.6, 1.0], ["shaman", 3, 1.4, 9.1], ["ogre", 4, 2.2, 10.1, "lead"]],   # 12
		[["wolf", 15, 0.45, 0.0, "bloated"], ["ghost", 9, 0.8, 1.0, "bloated"], ["berserker", 12, 1.1, 8.9], ["harpy", 4, 2.0, 9.9]],   # 13
		[["ironclad", 15, 0.9, 0.0, "bloated", "lead"], ["berserker", 12, 1.1, 1.0, "bloated"], ["shaman", 4, 1.4, 14.6], ["slime_king", 3, 1.8, 15.6]],   # 14
		[["imp", 18, 0.6, 0.0, "bloated"], ["ogre", 8, 2.2, 1.0, "lead"], ["shaman", 6, 1.4, 17.9], ["slime_king", 6, 1.8, 18.9]],   # 15
		[["bat", 24, 0.3, 0.0, "bloated"], ["ghost", 15, 0.8, 1.0, "bloated"], ["berserker", 9, 1.1, 13.7, "lead"], ["harpy", 12, 2.0, 14.7]],   # 16
		[["berserker", 18, 1.1, 0.0, "bloated"], ["shaman", 6, 1.4, 1.0], ["troll", 4, 1.8, 20.2, "lead"], ["ogre", 6, 2.2, 21.2, "bloated", "lead"]],   # 17
		[["ironclad", 24, 0.9, 0.0, "bloated"], ["slime_king", 9, 1.8, 1.0, "bloated"], ["ogre", 3, 2.2, 22.2, "bloated", "lead"]],   # 18
		[["berserker", 18, 1.1, 0.0, "bloated"], ["ghost", 15, 0.8, 1.0, "bloated"], ["shaman", 6, 1.4, 20.2], ["troll", 12, 1.8, 21.2, "lead"], ["harpy", 6, 2.0, 42.5, "bloated"]],   # 19
		[["skeleton", 24, 0.6, 0.0, "bloated"], ["ironclad", 24, 0.9, 1.0, "bloated"], ["ogre", 6, 2.2, 23.2, "bloated", "lead"], ["troll", 9, 1.8, 24.2, "lead"], ["golem", 2, 6.0, 25.2]],   # 20
		[["bat", 30, 0.27, 0.0, "bloated"], ["ghost", 18, 0.72, 1.0, "bloated"], ["harpy", 15, 1.8, 14.74, "bloated"], ["gargoyle", 6, 1.44, 15.74, "lead"], ["troll", 3, 1.62, 41.44, "lead"]],   # 21
		[["ironclad", 30, 0.81, 0.0, "bloated"], ["ogre", 18, 1.98, 1.0, "bloated", "lead"], ["troll", 9, 1.62, 36.16, "lead"], ["dark_knight", 3, 1.8, 37.16, "lead"]],   # 22
		[["imp", 30, 0.54, 0.0, "bloated"], ["ghost", 24, 0.72, 1.0, "bloated"], ["troll", 15, 1.62, 19.06, "lead"], ["shaman", 9, 1.26, 20.06], ["wraith", 15, 1.08, 43.24, "lead"], ["gargoyle", 4, 1.44, 44.24, "lead"]],   # 23
		[["ironclad", 30, 0.81, 0.0, "bloated"], ["slime_king", 15, 1.62, 1.0, "bloated"], ["shaman", 12, 1.26, 25.18], ["troll", 12, 1.62, 26.18, "lead"], ["gargoyle", 6, 1.44, 45.5, "lead"]],   # 24
		[["harpy", 12, 1.8, 0.0, "bloated"], ["ogre", 18, 1.98, 1.0, "bloated", "lead"], ["troll", 15, 1.62, 36.16, "lead"], ["dark_knight", 12, 1.8, 37.16, "lead"], ["mammoth", 3, 2.7, 60.34, "lead"]],   # 25
		[["ironclad", 24, 0.81, 0.0, "bloated"], ["ogre", 18, 1.98, 1.0, "bloated", "lead"], ["troll", 18, 1.62, 36.16, "lead"], ["dark_knight", 15, 1.8, 37.16, "lead"]],   # 26
		[["ghost", 24, 0.72, 0.0, "bloated"], ["wraith", 36, 1.08, 1.0, "lead"], ["troll", 24, 1.62, 40.3, "bloated", "lead"]],   # 27
		[["bat", 30, 0.27, 0.0, "bloated"], ["harpy", 24, 1.8, 1.0, "bloated"], ["gargoyle", 30, 1.44, 43.9, "lead"], ["wraith", 12, 1.08, 44.9, "lead"]],   # 28
		[["berserker", 36, 0.99, 0.0, "bloated"], ["shaman", 15, 1.26, 1.0], ["ogre", 30, 1.98, 36.15, "bloated", "lead"], ["dark_knight", 21, 1.8, 37.15, "lead"], ["mammoth", 9, 2.7, 95.07, "lead"]],   # 29
		[["ironclad", 30, 0.81, 0.0, "bloated"], ["troll", 30, 1.62, 1.0, "lead"], ["harpy", 18, 1.8, 49.48, "bloated"], ["dark_knight", 15, 1.8, 50.48, "lead"], ["bone_dragon", 1, 6.0, 51.48, "bloated"]],   # 30
		[["imp", 30, 0.54, 0.0, "bloated"], ["slime_king", 24, 1.62, 1.0, "bloated"], ["troll", 30, 1.62, 39.76, "bloated", "lead"], ["gargoyle", 24, 1.44, 40.76, "lead"]],   # 31
		[["ghost", 36, 0.72, 0.0, "bloated"], ["wraith", 45, 1.08, 1.0, "lead"], ["ogre", 30, 1.98, 50.02, "bloated", "lead"], ["mammoth", 12, 2.7, 51.02, "lead"]],   # 32
		[["berserker", 45, 0.99, 0.0, "bloated"], ["shaman", 18, 1.26, 1.0], ["dark_knight", 45, 1.8, 45.06, "lead"], ["troll", 24, 1.62, 46.06, "bloated", "lead"]],   # 33
		[["bat", 60, 0.27, 0.0, "bloated"], ["harpy", 30, 1.8, 1.0, "bloated"], ["gargoyle", 45, 1.44, 54.7, "bloated", "lead"]],   # 34
		[["ironclad", 45, 0.81, 0.0, "bloated"], ["mammoth", 18, 2.7, 1.0, "lead"], ["dark_knight", 22, 1.8, 48.4, "bloated", "lead"], ["mammoth", 6, 2.7, 49.4, "bloated", "lead"]],   # 35
		[["ghost", 45, 0.72, 0.0, "bloated"], ["wraith", 45, 1.08, 1.0, "bloated", "lead"], ["troll", 45, 1.62, 50.02, "bloated", "lead"], ["gargoyle", 15, 1.44, 51.02, "bloated", "lead"]],   # 36
		[["shaman", 24, 1.26, 0.0], ["slime_king", 36, 1.62, 1.0, "bloated"], ["troll", 45, 1.62, 59.2, "bloated", "lead"], ["mammoth", 15, 2.7, 60.2, "lead"]],   # 37
		[["berserker", 45, 0.99, 0.0, "bloated"], ["harpy", 18, 1.8, 1.0, "bloated"], ["gargoyle", 45, 1.44, 45.06, "bloated", "lead"], ["dark_knight", 38, 1.8, 46.06, "bloated", "lead"]],   # 38
		[["ironclad", 60, 0.81, 0.0, "bloated"], ["dark_knight", 15, 1.8, 1.0, "bloated", "lead"], ["mammoth", 27, 2.7, 49.29, "bloated", "lead"], ["golem", 3, 6.0, 50.29, "bloated"]],   # 39
		[["gargoyle", 12, 1.44, 0.0, "bloated", "lead"], ["dark_knight", 15, 1.8, 1.0, "bloated", "lead"], ["mammoth", 18, 2.7, 27.7, "bloated", "lead"], ["titan", 1, 6.0, 28.7]],   # 40
	],
}


## {"spawns": [[time, enemy, hp multiplier, modifiers], ...] sorted by time, "boss": bool}, or {} past the end.
static func build(diff_id: String, wave: int) -> Dictionary:
	var list: Array = LISTS.get(diff_id, [])
	if wave < 1 or wave > list.size():
		return {}
	var spawns: Array = []
	var boss := false
	for g in list[wave - 1]:
		var mods: Array = g.slice(4)
		for i in int(g[1]):
			spawns.append([float(g[3]) + i * float(g[2]), g[0], Defs.BLOATED_HP if mods.has("bloated") else 1.0, mods])
		if Defs.BOSS_TYPES.has(g[0]):
			boss = true
	spawns.sort_custom(func(a, b): return a[0] < b[0])
	return {"spawns": spawns, "boss": boss}


static func count(diff_id: String) -> int:
	return (LISTS.get(diff_id, []) as Array).size()


## The generator after Continue scales HP up; this extra factor makes its first waves about as tough as the
## last handmade waves instead of dropping back. Compared on the second to last wave, bosses left out: the
## generator thins out the rest of a boss wave.
static func endless_factor(diff: Dictionary, seed_base: int) -> float:
	var n := count(diff["id"]) - 1
	if n < 1:
		return 1.0
	var mine := 0.0
	for sp in build(diff["id"], n)["spawns"]:
		if not Defs.BOSS_TYPES.has(sp[1]):
			mine += float(Defs.ENEMIES[sp[1]]["hp"]) * float(sp[2])
	var gen := 0.0
	for sp in Defs.build_wave(n, n + 1, seed_base)["spawns"]:
		if not Defs.BOSS_TYPES.has(sp[1]):
			gen += float(Defs.ENEMIES[sp[1]]["hp"])
	gen *= float(diff["hp"]) * Defs.enemy_hp_scale(n)
	if mine <= 0.0 or gen <= 0.0:
		return 1.0
	return maxf(1.0, mine / gen)
