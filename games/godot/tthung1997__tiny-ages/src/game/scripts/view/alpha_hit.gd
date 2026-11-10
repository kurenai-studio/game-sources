class_name AlphaHit
extends RefCounted
## Answers "is there something drawn under this point of a texture?" so hover can tell a prop from
## the empty part of its full-width art piece. Images are read once per texture and kept.

const ALPHA_SOLID: float = 0.5

var _images: Dictionary = {}


## Whether an opaque pixel lies within `reach` pixels of `local` (a point of the texture, in its own
## pixels). A little reach makes one-pixel-thin pieces (a rope, a post) possible to rest on.
func opaque_near(texture: Texture2D, local: Vector2, reach: int = 0) -> bool:
	var image: Image = _image_of(texture)
	if image == null:
		return false
	var cx: int = floori(local.x)
	var cy: int = floori(local.y)
	for y: int in range(maxi(cy - reach, 0), mini(cy + reach + 1, image.get_height())):
		for x: int in range(maxi(cx - reach, 0), mini(cx + reach + 1, image.get_width())):
			if image.get_pixel(x, y).a > ALPHA_SOLID:
				return true
	return false


func _image_of(texture: Texture2D) -> Image:
	if texture == null:
		return null
	var key: int = texture.get_instance_id()
	if not _images.has(key):
		var image: Image = texture.get_image()
		_images[key] = null if image == null or image.is_empty() else image
	return _images[key]
