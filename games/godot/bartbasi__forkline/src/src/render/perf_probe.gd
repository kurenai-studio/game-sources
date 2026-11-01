# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name PerfProbe
extends Node
## Debug builds only (docs/ARCHITECTURE.md 9.4). Every 2 seconds during a wave it prints one
## line: fps, 99th percentile frame time, the engine's process time, the script time of the
## map view, sim tick time when the battle screen reports it, draw calls, objects and live
## creatures. At the end of a wave it prints a summary over the whole wave. Read it on the
## phone with `adb logcat -s godot`. It switches itself off in release builds.

const REPORT_SECONDS: float = 2.0
const MAX_WAVE_FRAMES: int = 36000

## The last line printed, for tests.
var last_line: String = ""
var last_summary: String = ""

var _battle: Battle
var _view: MapView
var _frames: PackedFloat32Array = PackedFloat32Array()
var _wave_frames: PackedFloat32Array = PackedFloat32Array()
var _ticks_us: PackedInt32Array = PackedInt32Array()
var _wave_ticks_us: PackedInt32Array = PackedInt32Array()
var _since_report: float = 0.0
var _was_wave: bool = false
var _peak_live: int = 0


func _ready() -> void:
	if not OS.is_debug_build():
		set_process(false)


## Which battle and map view to report on. Both are optional.
func watch(battle: Battle, view: MapView = null) -> void:
	_battle = battle
	_view = view


## The battle screen may report how long one Battle.step() took. Without it the tick time
## shows as n/a; the process time still includes the sim.
func record_tick_usec(usec: int) -> void:
	_ticks_us.append(usec)
	if _wave_ticks_us.size() < MAX_WAVE_FRAMES * 3:
		_wave_ticks_us.append(usec)


func _process(delta: float) -> void:
	var in_wave: bool = _battle == null or _battle.phase == Battle.Phase.WAVE
	if in_wave:
		_frames.append(delta)
		if _wave_frames.size() < MAX_WAVE_FRAMES:
			_wave_frames.append(delta)
		if _battle != null:
			_peak_live = maxi(_peak_live, _battle.enemies.size())
		_since_report += delta
		if _since_report >= REPORT_SECONDS:
			_since_report = 0.0
			last_line = report_line()
			print(last_line)
			_frames = PackedFloat32Array()
			_ticks_us = PackedInt32Array()
	if _was_wave and not in_wave:
		last_summary = summary_line()
		print(last_summary)
		_wave_frames = PackedFloat32Array()
		_wave_ticks_us = PackedInt32Array()
		_peak_live = 0
	_was_wave = in_wave


## The line for the frames since the last report.
func report_line() -> String:
	var fps: int = int(Engine.get_frames_per_second())
	var live: int = _battle.enemies.size() if _battle != null else 0
	var window: Vector2i = DisplayServer.window_get_size()
	var line: String = "perf fps=%d p99=%.1fms worst=%.1fms process=%.1fms tick=%s sync=%.2fms events=%.2fms draws=%d objects=%d live=%d screen=%dx%d" % [
		fps, percentile(_frames, 0.99) * 1000.0, _max_of(_frames) * 1000.0,
		Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		_tick_text(_ticks_us),
		float(_view.last_sync_usec) / 1000.0 if _view != null else 0.0,
		float(_view.last_events_usec) / 1000.0 if _view != null else 0.0,
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
		live, window.x, window.y]
	return line


## The summary for a whole wave.
func summary_line() -> String:
	var total: float = 0.0
	for f: float in _wave_frames:
		total += f
	var mean: float = total / float(maxi(_wave_frames.size(), 1))
	return "perf wave frames=%d mean=%.1fms p99=%.1fms worst=%.1fms tick=%s peak_live=%d" % [
		_wave_frames.size(), mean * 1000.0, percentile(_wave_frames, 0.99) * 1000.0,
		_max_of(_wave_frames) * 1000.0, _tick_text(_wave_ticks_us), _peak_live]


## The value below which `q` (0 to 1) of the samples fall.
static func percentile(samples: PackedFloat32Array, q: float) -> float:
	if samples.is_empty():
		return 0.0
	var sorted: PackedFloat32Array = samples.duplicate()
	sorted.sort()
	return sorted[mini(sorted.size() - 1, int(float(sorted.size()) * q))]


static func _max_of(samples: PackedFloat32Array) -> float:
	var m: float = 0.0
	for f: float in samples:
		m = maxf(m, f)
	return m


static func _tick_text(ticks_us: PackedInt32Array) -> String:
	if ticks_us.is_empty():
		return "n/a"
	var total: int = 0
	var worst: int = 0
	for t: int in ticks_us:
		total += t
		worst = maxi(worst, t)
	var sorted: PackedInt32Array = ticks_us.duplicate()
	sorted.sort()
	var p99: int = sorted[mini(sorted.size() - 1, int(float(sorted.size()) * 0.99))]
	return "%.2f/%.2f/%.2fms(mean/p99/max)" % [float(total) / float(ticks_us.size()) / 1000.0, float(p99) / 1000.0, float(worst) / 1000.0]
