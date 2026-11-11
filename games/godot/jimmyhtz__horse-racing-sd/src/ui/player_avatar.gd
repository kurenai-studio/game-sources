extends Control
const Identity = preload("res://core/player_identity.gd")
static var built_in_textures: Dictionary={}
var profile: Dictionary
var texture: Texture2D

func _init() -> void:
	custom_minimum_size=Vector2(44,44)
	mouse_filter=MOUSE_FILTER_IGNORE

static func icon(avatar: String) -> Texture2D:
	if avatar not in Identity.AVATARS: return null
	if built_in_textures.has(avatar): return built_in_textures[avatar]
	var result := ResourceLoader.load("res://assets/avatars/"+avatar.to_lower()+".svg", "Texture2D") as Texture2D
	if result != null: built_in_textures[avatar]=result
	return result

func configure(value: Dictionary) -> void:
	profile=value
	texture=null
	if not profile.image.is_empty():
		var image:=Identity.decode_image(profile.image)
		if image!=null: texture=ImageTexture.create_from_image(image)
	if texture==null: texture=icon(profile.avatar)
	queue_redraw()

func _draw() -> void:
	if texture==null: return
	var side:=minf(size.x,size.y)
	var aspect:=texture.get_size().x/texture.get_size().y
	var target:=Vector2(side,side/aspect) if aspect>=1 else Vector2(side*aspect,side)
	draw_texture_rect(texture,Rect2((size-target)*0.5,target),false)
