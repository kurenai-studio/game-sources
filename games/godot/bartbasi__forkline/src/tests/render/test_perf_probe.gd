# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## PerfProbe: the percentile, the report line while a wave plays, and the wave summary.

const Fx: GDScript = preload("res://tests/render/render_fixtures.gd")


func test_percentile() -> void:
	var samples: PackedFloat32Array = PackedFloat32Array()
	for i: int in 100:
		samples.append(float(i + 1))
	assert_near(PerfProbe.percentile(samples, 0.99), 100.0)
	assert_near(PerfProbe.percentile(samples, 0.5), 51.0)
	assert_near(PerfProbe.percentile(PackedFloat32Array(), 0.99), 0.0)


func test_reports_during_a_wave_and_summarizes_after() -> void:
	var b: Battle = Fx.battle("r1_l1")
	var probe: PerfProbe = PerfProbe.new()
	probe.watch(b)
	probe.record_tick_usec(120)
	probe.record_tick_usec(300)
	b.start_next_wave()
	for i: int in 130:
		probe._process(1.0 / 60.0)
	assert_true(probe.last_line.begins_with("perf fps="), probe.last_line)
	assert_true(probe.last_line.contains("p99=16.7ms"), probe.last_line)
	assert_true(probe.last_line.contains("live="))
	assert_true(probe.last_line.contains("draws="))
	assert_true(probe.last_line.contains("tick=0.21/"), probe.last_line)
	var guard: int = 0
	while b.phase == Battle.Phase.WAVE and guard < 8000:
		b.step()
		guard += 1
	probe._process(1.0 / 60.0)
	assert_true(probe.last_summary.begins_with("perf wave frames=130"), probe.last_summary)
	probe.free()


func test_tick_time_is_n_a_until_reported() -> void:
	var b: Battle = Fx.battle("r1_l1")
	var probe: PerfProbe = PerfProbe.new()
	probe.watch(b)
	assert_true(probe.report_line().contains("tick=n/a"))
	probe.free()
