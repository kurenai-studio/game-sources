## Procedural silhouette rig + animation. Gameplay never calls into this node: it only listens to
## the parent's signals, so an artist can replace the node named "Visual" with Spine/AnimatedSprite2D.
class_name CharacterVisual
extends Node2D

@export var rig: RigDef
@export var tuning: AnimationTuning

var _facing := 1
var _velocity := Vector2.ZERO
var _run_ratio := 0.0
var _on_floor := true
var _moving := false
var _state: StringName = &"idle"
var _phase := 0.0
var _time := 0.0
var _lean := 0.0
var _crouch := 0.0
## 0..1 while climbing onto a ledge (from the controller), -1 otherwise.
var _climb_t := -1.0
## Crate being held: distance to its near face and the height of its top (see PlayerController.grab_contact); -1 = none.
var _grab_dist := -1.0
var _grab_top := 0.0
var _grab_crouch := 0.0
var _squash := Vector2.ZERO
var _squash_vel := Vector2.ZERO

var _hip: Bone2D
var _thigh: Array[Bone2D] = []
var _shin: Array[Bone2D] = []
var _foot_bone: Array[Bone2D] = []
var _upper_arm: Array[Bone2D] = []
var _fore_arm: Array[Bone2D] = []
var _foot := PackedVector2Array([Vector2.ZERO, Vector2.ZERO])
var _arm_angle := PackedFloat32Array([PI * 0.5, PI * 0.5])
var _arm_vel := PackedFloat32Array([0.0, 0.0])


func _ready() -> void:
	_build()
	var body := get_parent()
	_listen(body, &"moved", _on_moved)
	_listen(body, &"state_changed", _on_state_changed)
	_listen(body, &"landed", _on_landed)
	_listen(body, &"climb_progress", _on_climb_progress)
	_listen(body, &"grab_contact", _on_grab_contact)


func _listen(body: Node, signal_name: StringName, handler: Callable) -> void:
	if body.has_signal(signal_name):
		body.connect(signal_name, handler)


func _on_moved(velocity: Vector2, run_ratio: float, facing: int, on_floor: bool) -> void:
	_velocity = velocity
	_run_ratio = clampf(run_ratio, 0.0, 1.0)
	_facing = facing
	_on_floor = on_floor


func _on_grab_contact(distance: float, top: float) -> void:
	_grab_dist = distance
	_grab_top = top


func _on_climb_progress(t: float) -> void:
	_climb_t = t


func _on_state_changed(state: StringName) -> void:
	_state = state
	if state != &"climb":
		_climb_t = -1.0
	if state == &"jump":
		_squash = Vector2(-1.0, 1.0) * tuning.jump_stretch
		_squash_vel = Vector2.ZERO


func _on_landed(impact_speed: float) -> void:
	if impact_speed > tuning.land_min_speed:
		_crouch = tuning.land_crouch * clampf(impact_speed / tuning.squash_ref_speed, 0.3, 1.0)
	_squash = Vector2(1.0, -1.0) * tuning.land_squash * clampf(impact_speed / tuning.squash_ref_speed, 0.0, 1.0)
	_squash_vel = Vector2.ZERO


func _process(delta: float) -> void:
	_time += delta
	_moving = _on_floor and absf(_velocity.x) > 4.0
	if _moving:
		var step := lerpf(tuning.step_min, tuning.step_max, _run_ratio)
		_phase = fposmod(_phase + absf(_velocity.x) * delta / (4.0 * step) * TAU, TAU)
	_animate_body(delta)
	for i in 2:
		_animate_leg(i, delta)
		_animate_arm(i, delta)


func _animate_body(delta: float) -> void:
	var rest_y := -_hip_height()
	var bob := absf(sin(_phase)) * tuning.hip_bob * _run_ratio if _moving else 0.0
	var breathe := 0.0 if _moving or not _on_floor else sin(_time * tuning.breathe_rate * TAU) * tuning.breathe_amount
	if _state == &"die":
		_crouch = move_toward(_crouch, tuning.die_drop, 220.0 * delta)  # crumple, and stay down
	else:
		_crouch = move_toward(_crouch, 0.0, tuning.land_recover_speed * delta)
	_grab_crouch = move_toward(_grab_crouch, tuning.grab_crouch if _grab_dist >= 0.0 else 0.0, 60.0 * delta)
	_hip.position.y = rest_y - bob + breathe + _crouch + _grab_crouch  # feet stay planted, so the knees bend
	_lean = lerpf(_lean, _lean_target(), 1.0 - exp(-tuning.limb_smoothing * delta))
	_squash_vel += (-_squash * tuning.squash_stiffness - _squash_vel * tuning.squash_damping) * delta
	_squash += _squash_vel * delta
	scale = Vector2(_facing * (1.0 + _squash.x), 1.0 + _squash.y)
	rotation = _lean * _facing


func _lean_target() -> float:
	match _state:
		&"climb":  # hangs straight, chest comes over the edge while mantling, upright again on top
			return deg_to_rad(tuning.climb_lean_deg) * sin(PI * smoothstep(0.3, 1.0, maxf(_climb_t, 0.0)))
		&"die":
			return deg_to_rad(tuning.die_lean_deg)
		&"push":
			return deg_to_rad(tuning.push_lean_deg)
		&"pull":
			return deg_to_rad(-tuning.pull_lean_deg)
	return deg_to_rad(tuning.lean_deg) * _run_ratio


func _animate_leg(i: int, delta: float) -> void:
	var side := 1.0 if i == 0 else -1.0
	var ground := -_hip.position.y - rig.ankle_height
	var goal: Vector2
	if _state == &"hang":  # legs dangle and sway
		goal = Vector2(tuning.air_foot_spread * side * 0.5 + sin(_time * 2.2 + i) * 3.0, rig.leg_length() * tuning.fall_leg_reach)
	elif _state == &"climb":
		goal = _climb_leg_goal(i, ground)
	elif not _on_floor:
		var reach := tuning.jump_leg_reach if _velocity.y < 0.0 else tuning.fall_leg_reach
		goal = Vector2(tuning.air_foot_spread * side * 0.5, rig.leg_length() * reach)
	elif _moving:
		var p := _phase + PI * i
		var step := lerpf(tuning.step_min, tuning.step_max, _run_ratio)
		goal = Vector2(cos(p) * step, ground - maxf(-sin(p), 0.0) * tuning.step_height)
	else:
		goal = Vector2(tuning.idle_foot_spread * side * 0.5, ground)
	_foot[i] = _foot[i].lerp(goal, 1.0 - exp(-tuning.limb_smoothing * delta))
	var angles := TwoBoneIK.solve(rig.upper_leg, rig.lower_leg, _foot[i])
	_thigh[i].rotation = angles.x
	_shin[i].rotation = angles.y
	_foot_bone[i].rotation = -(angles.x + angles.y)  # keep the shoe flat whatever the leg does


## Ledge climb legs: dangle while hanging, scramble against the wall while pulling up, front knee onto the edge, stand.
func _climb_leg_goal(i: int, ground: float) -> Vector2:
	var t := maxf(_climb_t, 0.0)
	var reach := rig.leg_length()
	if t < 0.3:
		return Vector2(tuning.air_foot_spread * (0.5 if i == 0 else -0.5) + sin(_time * 2.2 + i) * 3.0, reach * tuning.fall_leg_reach)
	if t < 0.65:
		var kick := sin(_time * 14.0 + PI * i)
		return Vector2(10.0 + kick * tuning.climb_kick, reach * (0.72 + 0.06 * kick))
	if t < 0.85:
		return Vector2(16.0, reach * 0.42) if i == 0 else Vector2(-6.0, reach * 0.78)
	return Vector2(tuning.idle_foot_spread * (0.5 if i == 0 else -0.5), ground)


## Ledge climb arms: hold the edge overhead while hanging and pulling, then push down on the top, then relax.
func _climb_arm_target() -> float:
	var t := maxf(_climb_t, 0.0)
	var target := lerpf(deg_to_rad(tuning.climb_arm_deg), deg_to_rad(tuning.climb_push_arm_deg), smoothstep(0.62, 0.85, t))
	return lerpf(target, PI * 0.5, smoothstep(0.8, 1.0, t))


func _animate_arm(i: int, delta: float) -> void:
	var target := PI * 0.5
	if _state == &"climb":
		target = _climb_arm_target()
	elif _state == &"hang":
		target = deg_to_rad(tuning.climb_arm_deg)
	elif _grab_dist >= 0.0:
		_reach_for_crate(i)
		return
	elif not _on_floor:
		target -= deg_to_rad(tuning.air_arm_raise_deg)
	elif _moving:
		target += cos(_phase + PI * i) * deg_to_rad(tuning.arm_swing_deg) * _run_ratio
	_arm_vel[i] += ((target - _arm_angle[i]) * tuning.arm_spring_stiffness - _arm_vel[i] * tuning.arm_spring_damping) * delta
	_arm_angle[i] += _arm_vel[i] * delta
	_upper_arm[i].rotation = _arm_angle[i]
	var bend := deg_to_rad(tuning.elbow_bend_deg) * (1.0 + _run_ratio)
	if _state == &"climb":  # elbows fold while pulling up
		bend = deg_to_rad(tuning.climb_elbow_deg) * sin(PI * smoothstep(0.3, 0.9, maxf(_climb_t, 0.0)))
	_fore_arm[i].rotation = -bend


## Both hands on the crate's near face, the second a little lower so they do not sit on top of each other.
func _reach_for_crate(i: int) -> void:
	# The crate face is placed in world axes: this node is leaned and flipped, so its own axes would skew the target.
	var hand := global_position + Vector2(_grab_dist * _facing, -(_grab_top - tuning.grab_hand_drop - 5.0 * i))
	var arm := _upper_arm[i]
	var angles := TwoBoneIK.solve(rig.upper_arm, rig.lower_arm, arm.get_parent().to_local(hand) - arm.position, -1.0)
	_arm_angle[i] = angles.x  # hand the pose back to the spring from where it ends
	_arm_vel[i] = 0.0
	arm.rotation = angles.x
	_fore_arm[i].rotation = angles.y


func _build() -> void:
	var skeleton := Skeleton2D.new()
	skeleton.name = &"Skeleton"
	add_child(skeleton)
	_hip = _bone(skeleton, &"Hip", Vector2(0.0, -_hip_height()))
	var torso := rig.torso_size
	# Pajama shirt: narrow shoulders, hem flaring over the hips.
	_poly(_hip, &"Torso", PackedVector2Array([
		Vector2(-torso.x * 0.62, 5.0), Vector2(-torso.x * 0.5, -torso.y * 0.4), Vector2(-torso.x * 0.4, -torso.y),
		Vector2(torso.x * 0.4, -torso.y), Vector2(torso.x * 0.5, -torso.y * 0.4), Vector2(torso.x * 0.62, 5.0),
	]))
	_build_head(_bone(_hip, &"Head", Vector2(0.0, -torso.y)))
	var knee_w := lerpf(rig.thigh_width, rig.ankle_width, 0.5)
	var elbow_w := lerpf(rig.arm_width, rig.wrist_width, 0.5)
	for i in 2:
		var thigh := _bone(_hip, StringName("Thigh%d" % i), Vector2.ZERO)
		var shin := _bone(thigh, StringName("Shin%d" % i), Vector2(rig.upper_leg, 0.0))
		var foot := _bone(shin, StringName("Foot%d" % i), Vector2(rig.lower_leg, 0.0))
		_poly(thigh, &"ThighShape", _taper(rig.upper_leg, rig.thigh_width, knee_w))
		_poly(shin, &"ShinShape", _taper(rig.lower_leg, knee_w, rig.ankle_width))
		_poly(foot, &"Shoe", _shoe())
		var arm := _bone(_hip, StringName("Arm%d" % i), Vector2(0.0, -torso.y * 0.92))
		var fore := _bone(arm, StringName("Fore%d" % i), Vector2(rig.upper_arm, 0.0))
		_poly(arm, &"ArmShape", _taper(rig.upper_arm, rig.arm_width, elbow_w))
		_poly(fore, &"ForeShape", _taper(rig.lower_arm, elbow_w, rig.wrist_width))
		_poly(fore, &"Hand", _circle(Vector2(rig.lower_arm, 0.0), rig.hand_radius, 8))
		_thigh.append(thigh)
		_shin.append(shin)
		_foot_bone.append(foot)
		_upper_arm.append(arm)
		_fore_arm.append(fore)


func _hip_height() -> float:
	return rig.leg_length() * tuning.stance + rig.ankle_height


func _build_head(head: Bone2D) -> void:
	var r := rig.head_radius
	var center := Vector2(0.0, -r * 0.8)
	_poly(head, &"HeadShape", _circle(center, r, 14))
	var hair := PackedVector2Array()
	for k in rig.hair_spikes * 2 + 1:
		var angle := deg_to_rad(-200.0 + 220.0 * k / (rig.hair_spikes * 2))
		hair.append(center + Vector2.from_angle(angle) * r * (1.3 if k % 2 == 1 else 0.95))
	_poly(head, &"Hair", hair)
	var eye := _poly(head, &"Eye", PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(4.0, 0.0), Vector2(4.0, 2.5), Vector2(0.0, 2.5),
	]))
	eye.position = center + Vector2(r * 0.35, -r * 0.1)
	eye.color = rig.eye_color
	var glow := CanvasItemMaterial.new()
	glow.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	eye.material = glow


## Rounded start (radius w0/2 at the joint) tapering to width w1 at `length`, pointing along +x.
func _taper(length: float, w0: float, w1: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in 5:
		pts.append(Vector2.from_angle(-PI * 0.5 - PI * k / 4.0) * w0 * 0.5)
	pts.append(Vector2(length, w1 * 0.5))
	pts.append(Vector2(length, -w1 * 0.5))
	return pts


## Shoe in ankle space: sole on y = ankle_height, toe forward (+x).
func _shoe() -> PackedVector2Array:
	var h := rig.ankle_height
	return PackedVector2Array([
		Vector2(-4.0, -2.0), Vector2(3.0, -2.0), Vector2(rig.shoe_length * 0.7, h * 0.3),
		Vector2(rig.shoe_length, h), Vector2(-5.0, h),
	])


func _circle(center: Vector2, radius: float, points: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in points:
		pts.append(center + Vector2.from_angle(TAU * k / points) * radius)
	return pts


func _bone(parent: Node, bone_name: StringName, pos: Vector2) -> Bone2D:
	var bone := Bone2D.new()
	bone.name = bone_name
	bone.position = pos
	bone.rest = Transform2D(0.0, pos)
	bone.set_autocalculate_length_and_angle(false)
	parent.add_child(bone)
	return bone


func _poly(parent: Node, poly_name: StringName, points: PackedVector2Array) -> Polygon2D:
	var poly := Polygon2D.new()
	poly.name = poly_name
	poly.color = rig.color
	poly.polygon = points
	parent.add_child(poly)
	return poly
