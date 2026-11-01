class_name Links
extends RefCounted
## Addresses on the public website, opened in the system browser.

const SETTING := "algomind/network/site_url"


static func site(path: String) -> String:
	var base := String(ProjectSettings.get_setting(SETTING, "")).strip_edges().rstrip("/")
	return "%s/%s" % [base, path.trim_prefix("/")] if base.begins_with("https://") else ""


static func version() -> String:
	return String(ProjectSettings.get_setting("application/config/version", "0.0.0"))


## Opens a page of the website. Returns false when no site address is configured.
static func open(path: String) -> bool:
	var url := site(path)
	if url.is_empty():
		return false
	return OS.shell_open(url) == OK
