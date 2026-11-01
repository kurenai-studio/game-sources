extends RichTextLabel


func _ready() -> void:
	text = "v: " + VersionData.get_version_label_string()

# TODO: Add more complex tooltip here.

func _on_meta_clicked(meta: Variant) -> void:
	OS.shell_open(meta)
