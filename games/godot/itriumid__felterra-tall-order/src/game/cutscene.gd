class_name Cutscene
extends RefCounted
## A scripted scene: lines written out one after another, each held a moment, while something
## plays under them (he walks into the village, say). A line is told over the scene, or said by a
## cat in it, in a bubble over them. Whoever is watching is always in charge of
## it: Enter finishes the line being written, or moves on to the next; Escape skips the whole
## scene. Lines can move on by themselves, or wait for Enter, as the settings say, so nobody has to
## read against a clock.
##
## A line can name a voice recording to play with it. There are none yet; when there are, a line
## with one is held until it's been heard, and moving on stops it.

## How fast a line is written out, in letters a second, and how long it stays once it is.
const LETTERS := 30.0
const HOLD := 2.4

## The lines, as {text, voice, by, mood}: voice is a recording's path, or ""; by is who says it, a
## cat in the scene, or "" for the story told over it; mood is how they say it, for their portrait.
var lines: Array[Dictionary] = []
## Whether lines wait for Enter instead of moving on by themselves.
var waits := false
## The line on now, and how long it's been showing.
var line := 0
var showing_for := 0.0
var skipped := false
## How long the voice for the line on now lasts, once one is playing (0 while none is).
var voice_lasts := 0.0


## Lines are text, told over the scene, or {text, by, mood} for a line a cat says.
func _init(texts: Array = [], lines_wait := false) -> void:
	for each: Variant in texts:
		if each is Dictionary:
			lines.append({"text": each.text, "voice": each.get("voice", ""), "by": each.get("by", ""), "mood": each.get("mood", "neutral")})
		else:
			lines.append({"text": str(each), "voice": "", "by": "", "mood": "neutral"})
	waits = lines_wait


## How the line on now is said, for the speaker's portrait: "neutral", "happy", and so on.
func mood() -> String:
	return "neutral" if done() else lines[line].mood


## Who says the line on now, or "" if it's told over the scene, or nothing's on.
func speaker() -> String:
	return "" if done() else lines[line].by


## Done: every line told, or the whole scene skipped.
func done() -> bool:
	return skipped or line >= lines.size()


## The line on now, as far as it's been written.
func written() -> String:
	if done():
		return ""
	var text: String = lines[line].text
	return text.left(mini(int(showing_for * LETTERS), text.length()))


## Whether the line on now has been written out in full.
func finished_writing() -> bool:
	return done() or showing_for * LETTERS >= (lines[line].text as String).length()


## How long the whole scene takes if it's left to run: what something playing under it, like a
## walk, can be paced to.
func length() -> float:
	var total := 0.0
	for each in lines:
		total += (each.text as String).length() / LETTERS + HOLD
	return total


## Moves the scene along: time passing, and what was pressed. Hurrying finishes the line being
## written, or moves on from one that's done; skipping ends the scene.
func step(delta: float, hurry: bool, skip: bool) -> void:
	if done():
		return
	if skip:
		skipped = true
		return
	showing_for += delta
	if hurry:
		if not finished_writing():
			showing_for = (lines[line].text as String).length() / LETTERS
		else:
			_next()
		return
	var held := maxf(HOLD, voice_lasts)
	if not waits and showing_for >= (lines[line].text as String).length() / LETTERS + held:
		_next()


func _next() -> void:
	line += 1
	showing_for = 0.0
	voice_lasts = 0.0
