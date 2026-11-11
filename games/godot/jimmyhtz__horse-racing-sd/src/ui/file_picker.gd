extends RefCounted
## Use the native chooser where Godot supports it. The Desktop is an OS hint.
static func make() -> FileDialog:
	var dialog := FileDialog.new()
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.use_native_dialog = true
	var desktop := OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP).replace("\\", "/")
	if not desktop.is_empty() and DirAccess.open(desktop) != null:
		dialog.current_dir = desktop
	return dialog
