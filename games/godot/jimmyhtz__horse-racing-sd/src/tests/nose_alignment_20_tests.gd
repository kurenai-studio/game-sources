extends SceneTree
var failures:=0
var checks:=0
func check(ok: bool, why: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		if failures<=12: printerr("FAIL: "+why)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var settings=load("res://core/game_settings.gd").new()
	var view=load("res://ui/track_view.gd").new(); view.preferences=settings.values; root.add_child(view)
	for layout in [[Vector2(640,480),2.0,44.0,0.6],[Vector2(1600,800),1.0,70.0,1.5],[Vector2(900,1200),2.0,70.0,1.0]]:
		view.size=layout[0]; view.preferences=settings.values.duplicate()
		view.preferences.horse_scale=layout[1]; view.preferences.lane_spacing=layout[2]; view.preferences.camera_height=layout[3]
		view.geometry.lane_width=layout[2]
		for tick in range(251):
			var progress:=float(tick)/250.0
			view.positions=[progress*1000,progress*1000,progress*1000,progress*1000,progress*1000]
			var reference: PackedVector2Array=view.nose_guide(0)
			for clock in [0.0,0.31]:
				view._animation_clock=clock
				for h in range(5):
					var line: PackedVector2Array=view.nose_guide(h)
					var nose: Vector2=view.horse_point(h)+view.nose_offset(h)
					var logical: Vector2=view.project(view.display_point(progress,h))
					check(nose.distance_to(logical)<0.01,"drawn nose equals logical progress at every lane and phase")
					check(line[0].distance_to(reference[0])<0.01 and line[1].distance_to(reference[1])<0.01,"tied horses share one cross-track line independent of lane and bounce")
					check(Geometry2D.get_closest_point_to_segment(nose,line[0],line[1]).distance_to(nose)<0.01,"guide crosses actual nose")
		# Previously horse 1 at 120 appeared ahead of horse 5 at 130.
		view.positions=[120.0,125.0,126.0,128.0,130.0]
		for h in range(5):
			var expected: Vector2=view.project(view.display_point(view.positions[h]/1000.0,h))
			check((view.horse_point(h)+view.nose_offset(h)).distance_to(expected)<0.01,"known leader order remains true on bend")
		view.positions=[1000.0,1000.0,1000.0,1000.0,1000.0]
		for h in range(5): check((view.horse_point(h)+view.nose_offset(h)).distance_to(view.project(view.display_finish_point(h)))<0.01,"nose meets finish at true crossing")
	view.positions=[300.0,300.0,300.0,300.0,300.0]; view.moving=true
	view._animation_clock=0; var first_body: Vector2=view.horse_point(0)
	view._animation_clock=.14
	check(first_body.distance_to(view.horse_point(0))>.1,"figure still bounces around its anchored nose")
	view.queue_free(); await process_frame
	print("Nose alignment 20: ",checks," checks; ",failures," failures"); quit(1 if failures else 0)
