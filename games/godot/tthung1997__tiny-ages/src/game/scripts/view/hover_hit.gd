class_name HoverHit
extends RefCounted
## What the pointer is resting on in the world: a stable `key` (so the same thing is recognised from
## one look to the next), the `text` a tooltip says, and the draw order `z` it was found at.

var key: StringName = &""
var text: String = ""
var z: int = 0


static func make(p_key: StringName, p_text: String, p_z: int) -> HoverHit:
	var hit: HoverHit = HoverHit.new()
	hit.key = p_key
	hit.text = p_text
	hit.z = p_z
	return hit


## The one in front: the later of two at the same depth wins, so a villager listed after the props
## beats a prop at the same foot row. Either may be null.
static func in_front(current: HoverHit, candidate: HoverHit) -> HoverHit:
	if candidate == null:
		return current
	if current == null or candidate.z >= current.z:
		return candidate
	return current
