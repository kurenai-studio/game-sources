class_name Settings extends RefCounted
## The player's settings (GDD 15.1): sound on or off, and the selected skin.
## Plain data with change signals. SaveCodec reads and writes it, and the App
## listens for changes. It lives in src/save/ so the save code depends on
## nothing above core.

signal sound_changed(on: bool)
signal skin_changed(skin_id: StringName)

var sound_on: bool = true               # SOUND_DEFAULT (GDD 18)
var skin_id: StringName = &"gumdrop"    # SkinCatalog.DEFAULT_ID; save code never depends on skins


## Emits sound_changed only when the value changes.
func set_sound_on(on: bool) -> void:
	if on == sound_on:
		return
	sound_on = on
	sound_changed.emit(on)


## Emits skin_changed only when the value changes. Any id is stored as given;
## the App turns an unknown id into the default through SkinCatalog.get_skin.
func set_skin_id(id: StringName) -> void:
	if id == skin_id:
		return
	skin_id = id
	skin_changed.emit(id)
