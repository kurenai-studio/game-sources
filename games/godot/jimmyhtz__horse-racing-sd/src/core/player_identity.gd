extends RefCounted

const PALETTES := [
	["Blue / white", "245bbb", "ffffff"], ["Red / cream", "ac293d", "fff0c4"],
	["Green / gold", "235e37", "ffcf4a"], ["Purple / silver", "652f88", "e4e6ed"],
	["Orange / navy", "f08b30", "101f46"], ["Turquoise / charcoal", "37c8c5", "14292c"],
	["Pink / black", "f3a6ce", "1f1522"], ["Yellow / violet", "f4e15c", "452052"],
	["White / crimson", "f5f5ef", "812344"], ["Black / lime", "202426", "bcf562"],
	["Brown / peach", "693f2a", "ffd1ad"], ["Indigo / cyan", "252955", "84e9ff"]
]
const AVATARS := ["Racecar","Dog","Horse","Ship","Hat","Star","Rocket","Train","Boot","Robot","Crown","Ball","Fox","Owl","Panda","Trophy","Guitar","Compass","Balloon","Dice"]

static func defaults() -> Array:
	var result: Array = []
	for i in range(8):
		result.append({"color":i,"avatar":AVATARS[i],"image":""})
	return result

static func validate(profiles: Array) -> String:
	if profiles.size() != 8:
		return "Eight player identities are required."
	var used := {}
	for profile in profiles:
		if not profile is Dictionary or not profile.get("color") is int or profile.color < 0 or profile.color >= PALETTES.size():
			return "Choose a color combination from the table."
		if used.has(profile.color):
			return "That color combination already belongs to another player."
		used[profile.color] = true
		if not profile.get("avatar") is String or profile.avatar not in AVATARS or not profile.get("image") is String:
			return "Choose a valid avatar."
		if not profile.image.is_empty() and decode_image(profile.image) == null:
			return "The stored player image is invalid."
	return ""

static func decode_image(encoded: String) -> Image:
	if encoded.length() > 262144 or encoded.length() % 4 != 0:
		return null
	var alphabet := RegEx.new()
	alphabet.compile("^[A-Za-z0-9+/]*={0,2}$")
	if alphabet.search(encoded) == null:
		return null
	var bytes := Marshalls.base64_to_raw(encoded)
	# Check PNG dimensions before handing the data to the decoder.
	if bytes.size() < 24 or bytes.slice(0,8) != PackedByteArray([137,80,78,71,13,10,26,10]):
		return null
	for offset in [16,20]:
		var dimension := (int(bytes[offset]) << 24) | (int(bytes[offset+1]) << 16) | (int(bytes[offset+2]) << 8) | bytes[offset+3]
		if dimension < 1 or dimension > 256:
			return null
	var image := Image.new()
	return image if image.load_png_from_buffer(bytes) == OK else null

static func image_from_file(path: String) -> Dictionary:
	var file := FileAccess.open(path,FileAccess.READ)
	if file == null or file.get_length() > 8388608:
		return {"ok":false,"error":"Choose an image no larger than 8 MB."}
	file.close()
	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		return {"ok":false,"error":"This image could not be opened. Choose PNG, JPG or WebP."}
	var ratio := 128.0 / maxf(image.get_width(),image.get_height())
	image.resize(maxi(1,roundi(image.get_width()*ratio)),maxi(1,roundi(image.get_height()*ratio)),Image.INTERPOLATE_LANCZOS)
	return {"ok":true,"image":Marshalls.raw_to_base64(image.save_png_to_buffer())}
