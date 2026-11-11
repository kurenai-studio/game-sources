extends Node
## Local, cumulative per-game diagnostics. No PIN text or external computer activity.
var game_id := ""
var directory := ""
var run_id := ""
var error := ""
var _thread := Thread.new()
var _mutex := Mutex.new()
var _wake := Semaphore.new()
var _jobs: Array = []
var _events: Array = []
var _frames: Array = []
var _seconds := 0.0
var _sequence := 0
var _pending := 0
var _running := false
var _worker_us := 0
var _last_phase := ""
var _engine_logger: Logger

static func clean(value: Variant) -> Variant:
	if value is Dictionary:
		var result := {}
		for key in value:
			var lowered := str(key).to_lower()
			if lowered in ["pin","confirm","password","credentials","image","operator_pin","rtp_pin","seed","race_seed"] or "secret" in lowered: continue
			result[str(key)]=clean(value[key])
		return result
	if value is Array:
		var result: Array=[]
		for item in value: result.append(clean(item))
		return result
	return value

func begin(id: String) -> void:
	shutdown()
	game_id=id
	directory=ProjectSettings.globalize_path("user://diagnostics/"+id.validate_filename())
	DirAccess.make_dir_recursive_absolute(directory)
	run_id=str(Time.get_unix_time_from_system()).replace(".","-")+"-"+Crypto.new().generate_random_bytes(4).hex_encode()
	_running=true
	_thread=Thread.new()
	var status := _thread.start(_write_loop)
	if status!=OK: error="Diagnostic writer could not start"; _running=false; return
	_engine_logger=preload("res://core/diagnostic_errors.gd").new()
	_engine_logger.sink=record
	OS.add_logger(_engine_logger)
	record("run_opened",{"version":ProjectSettings.get_setting("application/config/version"),"engine":Engine.get_version_info(),"os":OS.get_name(),"cpu":OS.get_processor_name(),"processors":OS.get_processor_count(),"gpu":RenderingServer.get_video_adapter_name(),"renderer":RenderingServer.get_current_rendering_method(),"memory":OS.get_memory_info(),"frame_columns":["delta_seconds","phase","playback_seconds","positions","process_seconds","memory_bytes","draw_calls"]})

func record(kind: String, details: Dictionary={}) -> void:
	if not _running: return
	_mutex.lock()
	_events.append({"time_us":Time.get_ticks_usec(),"utc":Time.get_datetime_string_from_system(true),"kind":kind,"data":clean(details)})
	_mutex.unlock()

func frame(delta: float, phase: String, positions: Array, playback_time: float) -> void:
	if not _running: return
	if phase!=_last_phase:
		record("display_phase",{"from":_last_phase,"to":phase}); _last_phase=phase
	_frames.append([delta,phase,playback_time,positions.duplicate(),Performance.get_monitor(Performance.TIME_PROCESS),int(Performance.get_monitor(Performance.MEMORY_STATIC)),int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))])
	_seconds+=delta
	if _seconds>=1.0:
		var maximum := 0.0
		for sample in _frames: maximum=maxf(maximum,sample[0])
		record("frame_batch",{"fps":_frames.size()/_seconds,"worst_frame_ms":maximum*1000.0,"samples":_frames,"writer_us":_worker_us})
		_frames=[]; _seconds=0.0
		queue_flush()

func queue_flush() -> void:
	if not _running: return
	_mutex.lock()
	if not _events.is_empty():
		_sequence+=1
		_jobs.append({"path":directory.path_join("%s-%06d.jsonl.gz" % [run_id,_sequence]),"events":_events})
		_events=[]
		_pending+=1
		_wake.post()
	_mutex.unlock()

func _write_loop() -> void:
	while true:
		_wake.wait()
		_mutex.lock()
		var job: Dictionary = _jobs.pop_front() if not _jobs.is_empty() else {}
		var running := _running
		_mutex.unlock()
		if job.is_empty():
			if not running: break
			continue
		var started := Time.get_ticks_usec()
		var lines := PackedStringArray()
		for event in job.events: lines.append(JSON.stringify(event))
		var bytes := ("\n".join(lines)+"\n").to_utf8_buffer().compress(FileAccess.COMPRESSION_GZIP)
		var file := FileAccess.open(job.path+".tmp",FileAccess.WRITE)
		var failure := ""
		if file==null: failure="Diagnostic log could not be written"
		else:
			file.store_buffer(bytes); file.flush()
			if file.get_error()!=OK: failure="Diagnostic disk write failed"
			file.close()
			if failure.is_empty() and DirAccess.rename_absolute(job.path+".tmp",job.path)!=OK: failure="Diagnostic chunk could not be finalized"
		_mutex.lock()
		_worker_us=Time.get_ticks_usec()-started
		if not failure.is_empty(): error=failure
		_pending-=1
		_mutex.unlock()

func flush() -> void:
	if not _frames.is_empty():
		record("frame_batch",{"samples":_frames}); _frames=[]; _seconds=0.0
	queue_flush()
	if not _running: return
	while true:
		_mutex.lock(); var waiting := _pending; _mutex.unlock()
		if waiting==0: break
		OS.delay_msec(1)

func export_bundle(path: String, state: Dictionary) -> bool:
	flush()
	if not error.is_empty(): return false
	var zip := ZIPPacker.new()
	if zip.open(path)!=OK: error="Could not create diagnostic export"; return false
	var manifest := {"format":"race-diagnostics-1","game_id":game_id,"exported_utc":Time.get_datetime_string_from_system(true),"snapshot":clean(state),"coverage":"Cumulative from checkpoint 0.15 installation. Earlier races have accounting summaries only. Each frame and each logical movement is recorded separately. PINs, credentials, images and fresh race seeds are excluded."}
	var ok := _zip_file(zip,"manifest.json",JSON.stringify(manifest).to_utf8_buffer())
	var files := DirAccess.get_files_at(directory)
	files.sort()
	for file in files:
		if not file.ends_with(".jsonl.gz"): continue
		var compressed := FileAccess.get_file_as_bytes(directory.path_join(file))
		var decoded := compressed.decompress_dynamic(268435456,FileAccess.COMPRESSION_GZIP)
		if decoded.is_empty(): ok=false; break
		ok=_zip_file(zip,"events/"+file.trim_suffix(".gz"),decoded) and ok
	ok=zip.close()==OK and ok
	if not ok: error="Diagnostic export did not finish"
	return ok

func _zip_file(zip: ZIPPacker, name: String, bytes: PackedByteArray) -> bool:
	if zip.start_file(name)!=OK: return false
	var ok := zip.write_file(bytes)==OK
	return zip.close_file()==OK and ok

func shutdown() -> void:
	if not _running: return
	if _engine_logger!=null:
		OS.remove_logger(_engine_logger); _engine_logger=null
	record("run_closed",{})
	flush()
	_mutex.lock(); _running=false; _mutex.unlock()
	_wake.post()
	_thread.wait_to_finish()

func _exit_tree() -> void: shutdown()
