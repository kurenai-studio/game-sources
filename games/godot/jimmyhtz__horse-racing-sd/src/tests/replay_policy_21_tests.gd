extends SceneTree
var failures:=0
func check(ok: bool, why: String):
	if not ok: failures+=1;printerr("FAIL: "+why)
func _init():
	var policy=load("res://core/replay_policy.gd")
	# Existing signature remains callable while new component-aware API is added.
	var config: Dictionary=policy.configuration(20)
	check(config.get("calibration","")=="conditional-gap-v2","replay no longer uses the old 100-race threshold")
	check(config.get("samples",0)>=8192,"independent replay reference has adequate calibration size")
	for component in range(4):
		for prefs in [{"race_spread":0.0,"race_lead_changes":0.0},{"race_spread":1.0,"race_lead_changes":0.5},{"race_spread":1.5,"race_lead_changes":1.0}]:
			var previous:=0.0
			for target in [1,10,20,30]:
				var active: Dictionary=policy.configuration(target,prefs,component)
				check(active.threshold>=previous,"higher frequency has a nondecreasing gap cutoff")
				previous=active.threshold
				check(absf(policy.calibrated_fraction(active)-target/100.0)<0.00001,"quantile with ties matches reference target")
				var changed: Dictionary=prefs.duplicate()
				changed.replay_lengths=3.0;changed.replay_seconds=10.0;changed.horse_scale=2.0
				check(active==policy.configuration(target,changed,component),"travel, duration and horse artwork do not suppress a qualified replay")
	var close: Dictionary={"first":0,"second":1,"positions":[1050.0,1000.0,999.9,980.0,970.0],"seed":"replay-21"}
	var chosen: Dictionary=policy.decide(close,policy.configuration(20,{"race_spread":1.0,"race_lead_changes":0.5},0))
	check(chosen.replay and chosen.third==2,"actual closest challenger is the replay subject")
	close.positions=[1000.1,1000.0,900.0,880.0,870.0]
	check(not policy.decide(close,config).replay,"first-second closeness cannot trigger a replay")
	print("Replay21 baseline failures=",failures)
	quit(1 if failures else 0)
