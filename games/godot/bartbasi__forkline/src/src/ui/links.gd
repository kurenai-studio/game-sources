# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name Links
extends RefCounted
## Every address the app hands to another app on the phone (docs/ARCHITECTURE.md
## section 8). Each address is a constant written once. This is the only file
## that opens one, and it opens only these. The app itself sends nothing.

const COFFEE_URL: String = "https://buymeacoffee.com/playinc"
const SOURCE_URL: String = "https://github.com/bartbasi/forkline"
## How the About screen writes the source address.
const SOURCE_SHOWN: String = "github.com/bartbasi/forkline"
const FEEDBACK_EMAIL: String = "bartbasi@gmail.com"

## Who opens a link. Empty means the phone. Tests put a recorder here and set
## it back to Callable() when they finish.
static var opener: Callable = Callable()


## Hands one of our own addresses to the opener, or to the phone. Anything else
## is refused. A failure to open shows nothing.
static func open(url: String) -> void:
	if not is_ours(url):
		return
	if opener.is_valid():
		opener.call(url)
		return
	var _result: Error = OS.shell_open(url)


## True for the two web addresses and for exactly the feedback draft this app
## builds right now. A draft with anything added or changed is refused.
static func is_ours(url: String) -> bool:
	if url == COFFEE_URL or url == SOURCE_URL:
		return true
	return url == feedback_url(version(), device_text())


static func open_coffee() -> void:
	open(COFFEE_URL)


static func open_source() -> void:
	open(SOURCE_URL)


static func send_feedback() -> void:
	open(feedback_url(version(), device_text()))


## The app version from the project settings, or "" when none is set.
static func version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", ""))


## Phone model and Android version, for the feedback draft.
static func device_text() -> String:
	return "%s, %s %s" % [OS.get_model_name(), OS.get_name(), OS.get_version_alias()]


## The email draft. `uri_encode` turns & ? # = and line breaks into escapes, so
## a strange model name cannot add a recipient or a header.
static func feedback_url(app_version: String, device: String) -> String:
	var subject: String = "Forkline feedback (version %s)" % app_version
	var body: String = "\n\n\nSent from Forkline %s on %s" % [app_version, device]
	return "mailto:%s?subject=%s&body=%s" % [FEEDBACK_EMAIL, subject.uri_encode(), body.uri_encode()]
