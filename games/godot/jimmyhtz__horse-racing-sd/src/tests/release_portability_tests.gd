extends SceneTree

const Backend = preload("res://ui/speech_backend.gd")
const Picker = preload("res://ui/file_picker.gd")
const SOURCE := "res://scripts/Synthesize-Speech.ps1"
const PACKED_SOURCE := "res://release-portability-pack-only/worker.ps1"
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

func run() -> void:
	var scratch := ProjectSettings.globalize_path("user://portability test %d" % OS.get_process_id())
	DirAccess.make_dir_recursive_absolute(scratch)
	var pack_path := scratch.path_join("pack test.pck")
	var packer := PCKPacker.new()
	check(packer.pck_start(pack_path) == OK, "start isolated pack")
	check(packer.add_file(PACKED_SOURCE, SOURCE) == OK, "add worker to isolated pack")
	check(packer.flush() == OK, "write isolated pack")
	check(ProjectSettings.load_resource_pack(pack_path), "mount isolated pack")
	var packed_bytes := FileAccess.get_file_as_bytes(PACKED_SOURCE)
	check(not packed_bytes.is_empty() and packed_bytes == FileAccess.get_file_as_bytes(SOURCE), "read packaged worker bytes")

	var picker := Picker.make()
	check(picker.use_native_dialog and picker.access == FileDialog.ACCESS_FILESYSTEM, "use native chooser when available")
	var desktop := OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP)
	if DirAccess.open(desktop) != null:
		var expected := desktop.replace("\\", "/").trim_suffix("/")
		var actual := picker.current_dir.replace("\\", "/").trim_suffix("/")
		if OS.get_name() == "Windows":
			expected = expected.to_lower()
			actual = actual.to_lower()
		check(actual == expected, "give chooser the OS Desktop as the starting location: %s vs %s" % [actual, expected])
	else:
		check(not picker.current_dir.is_empty(), "leave the default directory when the OS Desktop is inaccessible")
	picker.free()

	var backend: RefCounted = Backend.new()
	check(backend.has_method("_start_worker"), "backend can stage and launch a packed worker")
	if backend.has_method("_start_worker") and OS.get_name() == "Windows":
		backend.call("_start_worker", [], "res://missing-release-worker.ps1", scratch)
		check("missing" in backend.failure.to_lower() and not backend.preparing(), "missing script reports a readable error")
		check(DirAccess.get_files_at(scratch).size() == 1, "missing worker leaves no temporary request files")
		var blocked := scratch.path_join("blocked cache")
		var file := FileAccess.open(blocked, FileAccess.WRITE)
		file.close()
		backend.call("_start_worker", [], PACKED_SOURCE, blocked)
		check("cache" in backend.failure.to_lower() and not backend.preparing(), "invalid cache reports a readable error")
		DirAccess.remove_absolute(blocked)
		var todo: Array = []
		for argument in OS.get_cmdline_user_args():
			if argument.begins_with("--sapi-voice="):
				todo.append({"text": "The race is ready.", "voice": argument.trim_prefix("--sapi-voice="), "rate": 1.1, "path": scratch.path_join("spoken clip.wav")})
		backend.call("_start_worker", todo, PACKED_SOURCE, scratch)
		var request: String = backend.manifest
		check(backend.preparing(), "native process starts from packed resource")
		check(not request.is_empty() and FileAccess.get_file_as_bytes(request + ".ps1") == packed_bytes, "staged file matches packaged worker")
		for step in range(100):
			if not backend.preparing(): break
			await create_timer(0.1).timeout
			backend.tick(0.1)
		check(not backend.preparing() and backend.failure.is_empty(), "PowerShell read its staged script and manifest at paths with spaces: " + backend.failure)
		check(not FileAccess.file_exists(request) and not FileAccess.file_exists(request + ".ps1") and not FileAccess.file_exists(request + ".done"), "completed worker removes request files")
		if not todo.is_empty():
			var spoken := AudioStreamWAV.load_from_file(todo[0].path)
			check(spoken != null and spoken.get_length() > 0.0, "Windows SAPI produced a WAV with measured duration")
			DirAccess.remove_absolute(todo[0].path)
		backend.shutdown()
	DirAccess.remove_absolute(pack_path)
	DirAccess.remove_absolute(scratch)
	print("Release portability failures: ", failures)
	quit(1 if failures else 0)
