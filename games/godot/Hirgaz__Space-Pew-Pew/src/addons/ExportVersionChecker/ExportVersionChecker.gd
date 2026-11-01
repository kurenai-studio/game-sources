@tool
class_name ExportVersionCheckerPlugin
extends EditorExportPlugin


static func _get_git_data() -> String:
	# TODO: Clean this up.

	# Try to look for `.git` information.

	# Identify the global path for `res://.git`.
	var git_hash := ""
	var git_folder : String = ProjectSettings.globalize_path("res://.git")

	# First check for a submodule path, with `.git` being "gitdir: <dir>" pointing to the pat of the submodule.
	if FileAccess.file_exists(git_folder):
		var git_file := FileAccess.open(git_folder, FileAccess.READ)
		if not git_file:
			return ""
		var module_folder := git_file.get_line().strip_edges()
		git_file = null
		if module_folder.begins_with("gitdir: "):
			var root_path := module_folder.substr(8)
			if root_path.is_relative_path():
				git_folder = git_folder.path_join(root_path).simplify_path()
			else:
				git_folder = root_path

	# Now `.git` should be a directory, look for a `HEAD` file in it.
	if FileAccess.file_exists(git_folder.path_join("HEAD")):
		var git_file := FileAccess.open(git_folder.path_join("HEAD"), FileAccess.READ)
		if not git_file:
			return ""
		var head := git_file.get_line().strip_edges()
		git_file = null

		# File should either be "ref: <ref>" or a plain hash string, if the former we need to look further.
		if head.begins_with("ref: "):
			var ref := head.substr(5)

			print("H Ref: ", ref)

			var parts := git_folder.split("/")
			print("P: ", parts)
			# If this is a git worktree instead of a clone.
			if parts.size() > 2 and parts[-2] == "worktrees":
				git_folder = String("/").join(parts.slice(0, -2))
			head = git_folder.path_join(ref)
			var packedrefs := git_folder.path_join("packed-refs")
			if FileAccess.file_exists(head):
				git_file = FileAccess.open(head, FileAccess.READ)
				if not git_file:
					return ""
				git_hash = git_file.get_line().strip_edges()
				git_file = null
			elif FileAccess.file_exists(packedrefs):
				# Search packed refs.
				git_file = FileAccess.open(packedrefs, FileAccess.READ)
				if not git_file:
					return ""
				while not git_file.eof_reached():
					var line := git_file.get_line()

					if line.begins_with("#"):
						continue

					var line_parts := line.split(" ", true, 2)
					if line_parts.size() == 2 and ref == line_parts[1]:
						git_hash = line_parts[0]
						break
			else:
				return ""
		else:
			git_hash = head

	return git_hash


func _export_file(path: String, type: String, features: PackedStringArray) -> void:
	if path == "res://VersionData.gd":
		var contents := FileAccess.get_file_as_string(path)
		var git_hash := _get_git_data()
		if git_hash.is_empty():
			print_verbose("Export Version Checker, fetching version failed.")
			return

		const VERSION_HASH_BASE : String = "static var VERSION_HASH : String = "

		var start = contents.find(VERSION_HASH_BASE)
		if start == -1:
			return

		var end = contents.find("\n", start)
		if end == -1:
			return

		contents = contents.substr(0, start + VERSION_HASH_BASE.length()) + "\"" + git_hash + "\"" + contents.substr(end)

		print_verbose("Export Version Checker, exporting with hash: ", git_hash)

		add_file(path, contents.to_utf8_buffer(), true)


func _get_name() -> String:
	return "Export Version Checker"


func _get_customization_configuration_hash() -> int:
	return get_export_preset().get_customized_files().hash()
