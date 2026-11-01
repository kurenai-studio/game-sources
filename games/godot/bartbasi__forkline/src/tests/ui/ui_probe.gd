# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends RefCounted
## Helpers for the UI tests. Load it with preload; it has no class name.


## Stands in for the phone: remembers every address handed to it.
class Recorder extends RefCounted:
	var urls: Array[String] = []

	func record(url: String) -> void:
		urls.append(url)
