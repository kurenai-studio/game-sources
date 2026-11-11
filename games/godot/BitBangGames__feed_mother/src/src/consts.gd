extends Node

enum {
	TITLE_STATE,
	GAME_STATE,
	ENDING_STATE,
}

enum {
	FEED_ENDING,
	DEVOUR_ENDING,
	FALL_ENDING,
	TRUE_ENDING,
}

enum {
	SFX_BONK,
	SFX_CRACK,
	SFX_DING,
	SFX_EATING,
	SFX_LAUGH,
	SFX_SCREAM,
}

enum {
	MUS_HEARTBEAT,
	MUS_MOTHER,
}

const SPEED: int = 0b100000
const JUMP_HEIGHT: int = 0b10000000
const ACCEL_Y: int = 0b1000

const MAP_CANVAS_PATH: NodePath = "/root/Main/Map/MapCanvas"

const TEXT_NO_EGGS: PackedStringArray = [
	"This is you.",
	"You are in this room.",
	"This room has four walls in it.",
	"That is Mother.",
	"Mother is hungry.",
	"Mother must be fed.",
	"You must feed Mother.",
	"It is all you need to do.",
	"All you need to do in this room.",
	"In this room with four walls in it.",
	"Mother needs three eggs.",
	"Mother needs eggs to live.",
	"Bring eggs to Mother.",
	"She will eat them heartily.",
	"She will thank you for your sacrifices.",
	"Do not loiter.",
	"Do not break the eggs.",
	"Do not make Mother starve.",
	"Do not ask any questions.",
	"Do not exit this room.",
	"Do not do anything.",
	"If the thing you are doing.",
	"Is not feeding Mother.",
	"Mother is shaking violently.",
	"Is your inaction angering Mother?",
	"You must feed Mother soon.",
	"Or something terrible will happen.",
	"Have you broken any eggs?",
	"After I told you not to?",
	"Maybe I was wrong to trust you.",
]

const TEXT_ONE_EGG: PackedStringArray = [
	"You have fed Mother.",
	"Well done.",
	"But Mother is still hungry.",
	"Mother is far from satisfied.",
	"Mother still needs two eggs.",
	"Do not ask why.",
	"Feed Mother only.",
	"Do not feed yourself.",
	"Compared to Mother.",
	"You are nothing.",
	"Mother is the one providing you.",
	"With warmth, comfort, and solace.",
	"You must give a facsimile of that warmth.",
	"To the two remaining eggs.",
	"Do not mercilessly crush them.",
	"Do not push them too far.",
	"They will hit the four walls.",
	"It will be painful.",
	"Because of the four walls.",
	"That are in this room.",
	"You are taking an awful long time.",
	"Are you confused?",
	"Try to use a different angle.",
	"Find the real truth of this room.",
	"This room with four walls in it.",
	"Four is an odd number.",
	"I mean an even number, but strange.",
	"Mother does not need four eggs.",
	"However, Mother will die in four seconds.",
	"Are you satiated?",
]

const TEXT_TWO_EGGS: PackedStringArray = [
	"You have fed Mother two eggs.",
	"She needs one more.",
	"Because according to basic mathematics.",
	"Two plus one equals three plus zero.",
	"Equals five plus negative two.",
	"Equals the tesseract root of eighty-one.",
	"You have so far completed your task.",
	"Do not leave it incomplete.",
	"Do not not feed Mother.",
	"Do not not not not heed my warnings.",
	"Do not not not not not not not.",
	"Not not not not not not not not not not not.",
	"Not exit this room with four walls.",
	"In it.",
	"And definitely don'tn'tn'tn'tn'tn't.",
	"N't die.",
	"Everyone dies all the time.",
	"But you mustn't notn't.",
	"Because to my understanding.",
	"Dying is the exact opposite.",
	"Of the best thing to happen.",
	"Mother will have been failed by you.",
	"And everyone will be sad.",
	"Everyone will hate you.",
	"Even more than they already do.",
	"Assuming they already do.",
	"I assume because you have not fed Mother for a time.",
	"But I do not know for sure everyone's.",
	"Opinions on your person.",
	"Who are you?",
]

const TEXT_THREE_EGGS: PackedStringArray = [
	"Can you hear it?",
	"Can you feel it?",
	"Mother's heart beats.",
	"Excited, ecstatic, elated.",
	"But.",
	"Yet.",
	"She is still not satisfied.",
	"She yearns to give you a reward.",
	"Jump onto Mother.",
	"Stand on top of her great figure.",
	"Do not do anything else.",
	"You do not need to do anything else.",
	"Stand on Mother and complete this software.",
	"She does not need four eggs.",
	"Everyone is believing in you.",
]

const README_TEXT: StringName = \
"One thing.

You were meant to do one thing.

You knew what that thing was.

Why else would you run this software.

But of course.

You did not want to do one thing.

You wanted to do everything.

I warned of a terrible thing happening if you did not feed Mother.

That thing is you.

Your curiosity.

Your impotence.

Your recklessness.

Your hubris.

Everything.

That you do.

Do not close this message.

Do not not not remove this software.

Share this software.

Let others continue the cycle you would not.

Let there be a new Mother, better than Mother.

There is still time.

There is still you.

There is still me.

There is still Mother.

There always will be.

		  |████████████
		▄▄█████████████▄▄
		█████████████████▌
		█████████████████▌
		█████████████████▌
		███████▌  ███████▌
		█████████████████▌
		  |████████████
"

const README_PATH: StringName = "user://README"

const SFX_PATHS: PackedStringArray = [
	"res://sfx/sfx_bonk.wav",
	"res://sfx/sfx_crack.wav",
	"res://sfx/sfx_ding.wav",
	"res://sfx/sfx_eating.wav",
	"res://sfx/sfx_laugh.wav",
	"res://sfx/sfx_scream.wav",
]

const MUSIC_PATHS: PackedStringArray = [
	"res://mus/mus_heartbeat.ogg",
	"res://mus/mus_mother.ogg",
]
