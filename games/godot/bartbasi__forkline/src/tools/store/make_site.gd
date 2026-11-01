# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends SceneTree
## Builds the small static site for GitHub Pages from docs/store/privacy-policy.md
## and the short description in docs/store/listing.md. It writes:
##     index.html                   the home page
##     privacy-policy/index.html    the policy
##     .nojekyll                    empty, so GitHub serves the files as they are
## Run from the repo root, with no window needed:
##     godot --headless --path . --script res://tools/store/make_site.gd
## It writes to docs/store/site/. To write somewhere else (the store check does
## this to compare), add a folder:  -- --out=/some/folder
## The markdown reader knows only what the policy uses: headings, paragraphs,
## bullet lists and bold. Nothing here ships in the APK.

const POLICY_FILE: String = "res://docs/store/privacy-policy.md"
const LISTING_FILE: String = "res://docs/store/listing.md"
const DEFAULT_OUT: String = "res://docs/store/site"
const SHORT_DESC_HEADING: String = "## Short description"

const GAME_TITLE: String = "Forkline: Tower Defense"
const COPYRIGHT: String = "Copyright 2026 Play, Inc."
const MADE_BY: String = "Made by Bart Basi"
## The only outbound addresses on the site. They are plain links.
const SOURCE_URL: String = "https://github.com/bartbasi/forkline"
const BUILDS_URL: String = "https://github.com/bartbasi/forkline/releases"

## Inline CSS. No script, no font file, no image, nothing from another address.
## Light colors by default, dark through prefers-color-scheme. Link and text
## colors keep at least 4.5:1 against their background.
const CSS: String = """
:root { color-scheme: light dark; }
html { background: #ffffff; }
body { margin: 0 auto; padding: 1rem 1.25rem 3rem; max-width: 40rem; background: #ffffff; color: #1b1b1b;
  font-family: system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
  font-size: 1.0625rem; line-height: 1.6; }
h1 { font-size: 1.7rem; line-height: 1.25; margin: 1.5rem 0 0.75rem; }
h2 { font-size: 1.25rem; line-height: 1.3; margin: 2rem 0 0.5rem; }
p, ul { margin: 0.75rem 0; }
li { margin: 0.4rem 0; }
a { color: #0b4f9c; text-decoration: underline; }
nav, footer { color: #4a4a4a; font-size: 0.95rem; }
footer { margin-top: 2.5rem; padding-top: 1rem; border-top: 1px solid #c9c9c9; }
@media (prefers-color-scheme: dark) {
  html, body { background: #15171b; color: #ececec; }
  a { color: #8fbcff; }
  nav, footer { color: #b8b8b8; }
  footer { border-top-color: #3a3d44; }
}
"""


func _init() -> void:
	var out_dir: String = _out_dir()
	var policy_md: String = FileAccess.get_file_as_string(POLICY_FILE)
	var short_desc: String = _short_description(FileAccess.get_file_as_string(LISTING_FILE))
	if policy_md.is_empty() or short_desc.is_empty():
		push_error("make_site: could not read the policy or the short description.")
		quit(1)
		return
	var policy_title: String = _first_heading(policy_md)
	var ok: bool = true
	ok = _write(out_dir.path_join("index.html"), _home_page(short_desc)) and ok
	ok = _write(out_dir.path_join("privacy-policy/index.html"), _policy_page(policy_title, policy_md)) and ok
	ok = _write(out_dir.path_join(".nojekyll"), "") and ok
	if not ok:
		quit(1)
		return
	print("Site written to ", out_dir)
	quit(0)


func _out_dir() -> String:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			return arg.substr(6)
	return ProjectSettings.globalize_path(DEFAULT_OUT)


func _write(path: String, text: String) -> bool:
	var err: Error = DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if err != OK:
		push_error("make_site: cannot make the folder for %s (error %d)." % [path, err])
		return false
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("make_site: cannot write %s." % path)
		return false
	file.store_string(text)
	file.close()
	return true


## The first fenced block under the short description heading in listing.md.
func _short_description(listing: String) -> String:
	var in_heading: bool = false
	var in_fence: bool = false
	var lines: PackedStringArray = []
	for line: String in listing.split("\n"):
		if line.begins_with(SHORT_DESC_HEADING):
			in_heading = true
		elif in_heading and line.begins_with("```"):
			if in_fence:
				break
			in_fence = true
		elif in_heading and in_fence:
			lines.append(line)
	return " ".join(lines).strip_edges()


func _first_heading(md: String) -> String:
	for line: String in md.split("\n"):
		if line.begins_with("# "):
			return line.substr(2).strip_edges()
	return GAME_TITLE


## Plain text to HTML text. Only the characters that matter in HTML.
func _escape(text: String) -> String:
	return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;")


## Escapes the text, then turns **bold** into <strong>.
func _inline(text: String) -> String:
	var re: RegEx = RegEx.new()
	re.compile("\\*\\*(.+?)\\*\\*")
	return re.sub(_escape(text), "<strong>$1</strong>", true)


## Headings, paragraphs, bullet lists. A paragraph is the lines up to a blank line.
func _markdown_to_html(md: String) -> String:
	var html: PackedStringArray = []
	var para: PackedStringArray = []
	var in_list: bool = false
	for raw: String in md.split("\n"):
		var line: String = raw.strip_edges(false, true)
		if line.begins_with("- "):
			_flush_paragraph(html, para)
			if not in_list:
				html.append("<ul>")
				in_list = true
			html.append("<li>%s</li>" % _inline(line.substr(2)))
			continue
		if in_list:
			html.append("</ul>")
			in_list = false
		if line.is_empty():
			_flush_paragraph(html, para)
		elif line.begins_with("## "):
			_flush_paragraph(html, para)
			html.append("<h2>%s</h2>" % _inline(line.substr(3)))
		elif line.begins_with("# "):
			_flush_paragraph(html, para)
			html.append("<h1>%s</h1>" % _inline(line.substr(2)))
		else:
			para.append(line)
	_flush_paragraph(html, para)
	if in_list:
		html.append("</ul>")
	return "\n".join(html)


func _flush_paragraph(html: PackedStringArray, para: PackedStringArray) -> void:
	if para.is_empty():
		return
	html.append("<p>%s</p>" % _inline(" ".join(para)))
	para.clear()


func _page(title: String, body: String) -> String:
	return """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>%s</title>
<style>%s</style>
</head>
<body>
%s
</body>
</html>
""" % [_escape(title), CSS, body]


func _home_page(short_desc: String) -> String:
	var body: String = "\n".join([
		"<h1>%s</h1>" % _escape(GAME_TITLE),
		"<p>%s</p>" % _escape(short_desc),
		"<ul>",
		"<li><a href=\"%s\">Source code</a></li>" % SOURCE_URL,
		"<li><a href=\"%s\">Test builds</a></li>" % BUILDS_URL,
		"<li><a href=\"privacy-policy/\">Privacy policy</a></li>",
		"</ul>",
		"<footer>",
		"<p>%s<br>%s</p>" % [_escape(COPYRIGHT), _escape(MADE_BY)],
		"</footer>",
	])
	return _page(GAME_TITLE, body)


func _policy_page(title: String, policy_md: String) -> String:
	var body: String = "\n".join([
		"<nav><a href=\"../\">%s</a></nav>" % _escape(GAME_TITLE),
		_markdown_to_html(policy_md),
	])
	return _page(title, body)
