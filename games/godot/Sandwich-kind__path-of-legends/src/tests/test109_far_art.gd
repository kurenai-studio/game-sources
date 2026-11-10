extends SceneTree
func _initialize() -> void:
	var out := "/tmp/claude-0/st/far/"
	var imgs := {"ice": FarArt.ice_backdrop(2600, 940), "storm": FarArt.storm_backdrop(2600, 940),
			"lava": FarArt.lava_backdrop(2600, 940), "throne": FarArt.throne_backdrop(2600, 940)}
	for k in imgs:
		var im: Image = imgs[k]
		im.resize(im.get_width() * 2, im.get_height() * 2, Image.INTERPOLATE_NEAREST)
		im.save_png(out + "bg_" + k + ".png")
	print("ok")
	quit()
