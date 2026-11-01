# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Project wide rules from CLAUDE.md: the source file header and the license files.

const HEADER_LINE_1: String = "# Forkline. Copyright 2026 Play, Inc."
const HEADER_LINE_2: String = "# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE."
const GPL_MD5: String = "1ebbd3e34237af26da5dc08a4e440464"
const SOURCE_EXTENSIONS: PackedStringArray = ["gd", "gdshader"]
const SKIPPED_DIRS: PackedStringArray = [".godot", ".git", ".claude", "android", "build", "docs"]


func test_every_source_file_starts_with_the_header() -> void:
	var files: PackedStringArray = PackedStringArray()
	_collect_sources("res://", files)
	assert_true(files.size() > 0, "found no source files")
	for path: String in files:
		var lines: PackedStringArray = FileAccess.get_file_as_string(path).split("\n")
		var ok: bool = lines.size() >= 2 and lines[0].strip_edges() == HEADER_LINE_1 and lines[1].strip_edges() == HEADER_LINE_2
		assert_true(ok, "%s does not start with the two line header" % path)


func test_license_is_the_official_gpl_text() -> void:
	assert_eq(FileAccess.get_md5("res://LICENSE"), GPL_MD5)


func test_notice_has_the_copyright_line_and_attribution() -> void:
	var notice: String = FileAccess.get_file_as_string("res://NOTICE")
	assert_true(notice.contains("Copyright 2026 Play, Inc."), "copyright line")
	assert_true(notice.contains("Designed and written by Bart Basi, with assistance from Claude."), "credit")


func _collect_sources(dir_path: String, out: PackedStringArray) -> void:
	for sub_dir: String in DirAccess.get_directories_at(dir_path):
		if SKIPPED_DIRS.has(sub_dir):
			continue
		_collect_sources(dir_path.path_join(sub_dir), out)
	for file_name: String in DirAccess.get_files_at(dir_path):
		if SOURCE_EXTENSIONS.has(file_name.get_extension()):
			out.append(dir_path.path_join(file_name))
