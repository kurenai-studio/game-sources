extends RefCounted
signal playback_event(kind: String, details: Dictionary)
## Windows clips use the game's audio output and expose actual spoken duration.
## Only presentation text is passed to a local worker. Race randomness is never used.
static var cached: Array = []
static var loaded := false
const WORKER_RESOURCE := "res://scripts/Synthesize-Speech.ps1"
var player: AudioStreamPlayer
var worker := -1
var manifest := ""
var pending := {}
var deferred_clips: Array = []
var streams := {}
var failure := ""
var _poll := 0.0
var _elapsed := 0.0
var _playing_clip := {}
var _playback_started_us := 0
func attach(owner: Node) -> void:
	player = AudioStreamPlayer.new()
	owner.add_child(player)
	player.finished.connect(func(): finish_playback("completed"))
func finish_playback(reason: String) -> void:
	if _playing_clip.is_empty(): return
	var details: Dictionary=_playing_clip.duplicate()
	details.merge({"reason":reason,"elapsed_seconds":(Time.get_ticks_usec()-_playback_started_us)/1000000.0})
	_playing_clip.clear()
	playback_event.emit("audio_clip_ended",details)
func clip_output() -> bool:
	return OS.get_name() == "Windows" and DisplayServer.get_name() != "headless" and is_instance_valid(player)
func voices() -> Array:
	if not loaded and DisplayServer.get_name() != "headless":
		cached=DisplayServer.tts_get_voices()
		cached.sort_custom(func(a,b):
			var ae: bool=str(a.language).begins_with("en")
			var be: bool=str(b.language).begins_with("en")
			return ae if ae!=be else str(a.id)<str(b.id))
		loaded=not cached.is_empty()
	return cached.duplicate(true)
func key(text: String, voice: String, rate: float) -> String:
	return ("speech-v5|"+voice+"|"+str(snappedf(rate,0.01))+"|"+text).sha256_text()
func path_for(clip: Dictionary) -> String:
	return ProjectSettings.globalize_path("user://speech-cache/"+key(clip.text,clip.voice,clip.rate)+".wav")
func stream_for(clip: Dictionary) -> AudioStreamWAV:
	var path := path_for(clip)
	if streams.has(path): return streams[path]
	if not FileAccess.file_exists(path): return null
	var stream := AudioStreamWAV.load_from_file(path)
	if stream != null and stream.get_length()>0.01: streams[path]=stream
	return stream
func prepare(clips: Array) -> void:
	if not clip_output(): return
	var todo: Array = []
	var seen := {}
	for clip in clips:
		if clip.voice.is_empty(): continue
		var path := path_for(clip)
		if seen.has(path) or stream_for(clip) != null: continue
		seen[path]=true
		var job: Dictionary=clip.duplicate()
		for installed in voices():
			if installed.id==clip.voice: job.voice_name=installed.name
		job.path=path
		todo.append(job)
	if todo.is_empty(): return
	if worker>0:
		deferred_clips.append_array(todo)
		return
	_start_worker(todo)

func _start_worker(todo: Array, source: String = WORKER_RESOURCE, cache_dir: String = "user://speech-cache") -> void:
	failure=""
	var script_bytes := FileAccess.get_file_as_bytes(source)
	if script_bytes.is_empty():
		failure="The Windows speech worker is missing or unreadable. Subtitles remain available."
		return
	var cache := ProjectSettings.globalize_path(cache_dir)
	if DirAccess.make_dir_recursive_absolute(cache) != OK:
		failure="The speech cache folder could not be created. Subtitles remain available."
		return
	manifest=cache.path_join("request-%d-%d.json" % [OS.get_process_id(),Time.get_ticks_usec()])
	# PowerShell needs a real file. Copy this batch's worker out of the resource pack
	# and pass its path and the manifest path as separate arguments.
	var script_path := manifest+".ps1"
	var script_file := FileAccess.open(script_path,FileAccess.WRITE)
	if script_file == null or not script_file.store_buffer(script_bytes):
		if script_file != null: script_file.close()
		failure="The Windows speech worker could not be written to the speech cache. Subtitles remain available."
		_cleanup_request()
		return
	script_file.close()
	var file := FileAccess.open(manifest,FileAccess.WRITE)
	if file == null or not file.store_string(JSON.stringify({"clips":todo})):
		if file != null: file.close()
		failure="The speech request could not be written to the speech cache. Subtitles remain available."
		_cleanup_request()
		return
	file.close()
	var powershell := OS.get_environment("SystemRoot").path_join("System32/WindowsPowerShell/v1.0/powershell.exe")
	if powershell.is_absolute_path() and FileAccess.file_exists(powershell):
		worker=OS.create_process(powershell,["-NoProfile","-NonInteractive","-WindowStyle","Hidden","-ExecutionPolicy","Bypass","-File",script_path,"-Manifest",manifest],false)
	_elapsed=0.0
	if worker<0:
		failure="The Windows speech worker could not start. Subtitles remain available."
		_cleanup_request()
	else: playback_event.emit("speech_preparation_started",{"clips":todo.size()})

func _cleanup_request() -> void:
	if manifest.is_empty(): return
	for path in [manifest,manifest+".ps1",manifest+".done"]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	manifest=""

func preparing() -> bool:
	return worker>0 or not deferred_clips.is_empty()
func tick(delta: float) -> void:
	_poll+=delta
	_elapsed+=delta
	if worker>0 and _poll>=0.1:
		_poll=0.0
		if not OS.is_process_running(worker):
			worker=-1
			if FileAccess.file_exists(manifest+".done"):
				var report=JSON.parse_string(FileAccess.get_file_as_string(manifest+".done").trim_prefix("\ufeff"))
				if not report is Dictionary or not report.get("errors") is Array:
					failure="The Windows speech worker returned an unreadable result."
				elif not report.errors.is_empty():
					failure="Windows could not prepare one or more voice clips."
			else: failure="Windows speech worker ended without audio confirmation."
			playback_event.emit("speech_preparation_ended",{"seconds":_elapsed,"error":failure})
			_cleanup_request()
			if not deferred_clips.is_empty():
				var next := deferred_clips.duplicate()
				deferred_clips.clear()
				prepare(next)
		elif _elapsed>30.0:
			OS.kill(worker)
			worker=-1
			deferred_clips.clear()
			pending.clear()
			failure="Voice preparation timed out. Subtitles remain available."
			playback_event.emit("speech_preparation_ended",{"seconds":_elapsed,"error":failure})
			_cleanup_request()
	if not pending.is_empty():
		var stream := stream_for(pending)
		if stream != null:
			player.stream=stream
			player.volume_db=linear_to_db(maxf(float(pending.volume)/100.0,0.00001))
			player.play()
			_playing_clip=pending.duplicate()
			_playing_clip["duration_seconds"]=stream.get_length()
			_playback_started_us=Time.get_ticks_usec()
			playback_event.emit("audio_clip_started",_playing_clip.duplicate())
			pending.clear()
		elif not preparing(): pending.clear()
func ready_clip(text: String, voice: String, rate: float) -> bool:
	return not clip_output() or stream_for({"text":text,"voice":voice,"rate":rate}) != null

func duration(text: String, voice: String, rate: float) -> float:
	var clip := {"text":text,"voice":voice,"rate":rate}
	var stream := stream_for(clip) if clip_output() else null
	# Conservative cold-cache estimate. Actual Windows clip length wins once prepared.
	return stream.get_length() if stream != null else maxf(0.65,float(text.split(" ",false).size())/(2.6*rate)+0.45)
func speaking() -> bool:
	if clip_output(): return not pending.is_empty() or player.playing
	return DisplayServer.tts_is_speaking() if not voices().is_empty() else false
func stop() -> void:
	finish_playback("stopped")
	pending.clear()
	if is_instance_valid(player): player.stop()
	if not voices().is_empty(): DisplayServer.tts_stop()
func say(text: String, voice: String, volume: int, rate: float) -> void:
	if voice.is_empty(): return
	stop()
	if clip_output():
		pending={"text":text,"voice":voice,"rate":rate,"volume":volume}
		prepare([pending])
		tick(0.0)
	else: DisplayServer.tts_speak(text,voice,volume,1.0,rate,0,true)
func shutdown() -> void:
	stop()
	deferred_clips.clear()
	if worker>0 and OS.is_process_running(worker): OS.kill(worker)
	worker=-1
	_cleanup_request()
