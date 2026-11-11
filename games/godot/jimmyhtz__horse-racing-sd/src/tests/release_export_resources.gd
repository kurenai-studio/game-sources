extends RefCounted

const Avatar = preload("res://ui/player_avatar.gd")
const Identity = preload("res://core/player_identity.gd")
const Support = preload("res://ui/support_panel.gd")

static func failures(owner: Node) -> Array[String]:
	var errors: Array[String] = []
	for name in Identity.AVATARS:
		var icon: Texture2D = Avatar.icon(name)
		if icon == null or icon.get_width() < 1 or icon.get_height() < 1:
			errors.append("Built-in avatar is missing: " + name)

	var avatar := Avatar.new()
	var sample := Image.create_empty(3, 2, false, Image.FORMAT_RGBA8)
	sample.fill(Color.RED)
	avatar.configure({"avatar": "Dog", "image": Marshalls.raw_to_base64(sample.save_png_to_buffer())})
	if avatar.texture == null or avatar.texture.get_size() != Vector2(3, 2):
		errors.append("The uploaded PNG no longer takes precedence over the built-in avatar.")
	avatar.free()

	var support := Support.new()
	owner.add_child(support)
	support.configuration.paypal_me = ""
	var dialog := support.show_amount(5)
	var qr := dialog.find_child("PayPalQR", true, false) as TextureRect
	if qr == null or qr.texture == null or qr.texture.get_width() < 37:
		errors.append("The fallback PayPal QR texture is missing.")
	support.queue_free()
	return errors
