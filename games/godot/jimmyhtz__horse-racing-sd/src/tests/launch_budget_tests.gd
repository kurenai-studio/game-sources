extends SceneTree
const Guard = preload("res://ui/instance_guard.gd")
const Budget = preload("res://ui/frame_budget.gd")
var failures := 0
func check(ok: bool, caption: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: "+caption)
func _initialize() -> void:
	var first := Guard.new()
	var second := Guard.new()
	check(first.acquire(0),"first launch acquires a free OS port")
	var port := first.listener.get_local_port()
	check(not second.acquire(port),"second launch is refused while the first owns its lock")
	first.release()
	check(second.acquire(port),"closing the first releases the lock")
	second.release()
	var prefs := {"frame_limit":"60","background_fps":15,"vsync":false}
	check(Budget.limit_for(prefs,true) == 60,"foreground cap")
	check(Budget.limit_for(prefs,false) == 15,"background cap")
	prefs.frame_limit = "30"
	prefs.background_fps = 60
	check(Budget.limit_for(prefs,false) == 30,"background never exceeds foreground")
	prefs.frame_limit = "Unlimited"
	check(Budget.limit_for(prefs,true) == 0 and Budget.limit_for(prefs,false) == 60,"unlimited foreground still has bounded background")
	var budget := Budget.new()
	budget.focused = false
	budget.configure(prefs)
	check(Engine.max_fps == 60,"settings reapply preserves background state")
	budget.free()
	print("LAUNCH AND FRAME BUDGET: %d failures" % failures)
	quit(0 if failures == 0 else 1)
