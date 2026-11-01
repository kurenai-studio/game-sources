class_name PlayCompletion
extends RefCounted
## What a solved level writes to the device: the progress, the program waiting for the server to
## verify, and a request to sync. Nothing here sends anything itself.


static func save(p: PlayScreen) -> void:
	var progress := p.app.progress
	var slug := str(p._entry["id"])
	var version := int(p._level["levelVersion"])
	if p._entry.has("daily"):
		# A daily is not part of the campaign: only its own result is kept and sent.
		var program: Array = p._tape.program().duplicate(true)
		progress.results.queue_daily(
			str(p._entry["daily"]), slug, version, program, p._tape.slots()
		)
		progress.results.save()
		p.app.request_sync()
		return
	if int(p._entry["number"]) == 1:
		progress.settings.set_tutorial_done(true)
	progress.record_completion(slug, version, p._tape.slots())
	progress.results.queue_result(slug, version, p._tape.program().duplicate(true), p._tape.slots())
	progress.save()
	progress.results.save()
	p.app.request_sync()
