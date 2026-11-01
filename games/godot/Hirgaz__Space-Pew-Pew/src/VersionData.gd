class_name VersionData
extends Object

static var VERSION_MAJOR : int = 0
static var VERSION_MINOR : int = 1
static var VERSION_PATCH : int = 0
static var VERSION_STATUS : String = "beta"

static var VERSION_HASH : String = ""

static var REPOSITORY_URL : String = "https://github.com/Hirgaz/Space-Pew-Pew"


static func get_version_label_string() -> String:
	var hash_string := "unknown"
	var hash_url := REPOSITORY_URL
	if not VERSION_HASH.is_empty():
		hash_string = VERSION_HASH.left(9)
		hash_url = "%s/tree/%s" % [ REPOSITORY_URL, VERSION_HASH ]
	return "%d.%d.%d%s ([url tooltip=\"Visit Source\" href=\"%s\"]%s[/url])" % [ VERSION_MAJOR, VERSION_MINOR, VERSION_PATCH, "" if VERSION_STATUS.is_empty() else ("." + VERSION_STATUS), hash_url, hash_string ]

# TODO: Add a more complex tooltip.
