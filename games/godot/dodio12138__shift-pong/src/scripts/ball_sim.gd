extends RefCounted
## Table tennis ball physics: gravity, air drag, Magnus force and a spin-aware
## table bounce, plus trajectory solvers used by the rackets to aim shots.
## Coordinates: y up, table centred on the origin, length along z, net at z = 0.

const GRAVITY := Vector3(0.0, -9.81, 0.0)
const RADIUS := 0.02
const TABLE_Y := 0.76          # table surface height
const HALF_L := 1.37           # half table length (z)
const HALF_W := 0.7625         # half table width (x)
const NET_H := 0.1525
const NET_HALF_W := 0.915
const DRAG := 0.12             # 0.5 * rho * Cd * A / m
const MAGNUS := 0.0034         # Magnus coefficient: a = MAGNUS * (w x v)
const SPIN_DECAY := 0.15       # spin lost to air per second
const RESTITUTION := 0.88
const FRICTION := 0.22
const I_FACTOR := 2.0 / 3.0    # hollow sphere: I = 2/3 m r^2
const DT_PRED := 1.0 / 240.0
const DT_SOLVE := 1.0 / 120.0   # coarser step for the many trial flights in the shot solvers


static func accel(v: Vector3, w: Vector3) -> Vector3:
	return GRAVITY * g_k - DRAG * v.length() * v + MAGNUS * w.cross(v)


## 缩地成寸 (技能乒乓球) narrows one half: metres cut off each long edge.
static var cut_near := 0.0   # the +z half
static var cut_far := 0.0    # the -z half
static var net_extra := 0.0  # 铜墙铁壁: how far (m) the net is raised right now
## 重力转移: gravity on the ball in flight, times this. Only the flight and its
## prediction feel it; the shot solvers aim for normal gravity, so a shifted
## ball drops short of where it was aimed.
static var g_k := 1.0


static func on_table(p: Vector3) -> bool:
	return absf(p.x) <= HALF_W - (cut_near if p.z > 0.0 else cut_far) and absf(p.z) <= HALF_L


## Topspin axis for a ball travelling along `dir`: w = axis * amount, amount > 0 is topspin.
static func topspin_axis(dir: Vector3) -> Vector3:
	return Vector3.UP.cross(Vector3(dir.x, 0.0, dir.z).normalized())


## Spin-aware bounce: normal restitution plus Coulomb friction at the contact
## point, which converts between linear velocity and spin (topspin kicks forward,
## backspin checks up).
static func table_bounce(v: Vector3, w: Vector3) -> Array:
	var r := Vector3(0.0, -RADIUS, 0.0)
	var vt := Vector3(v.x, 0.0, v.z)
	var vc := vt + w.cross(r)
	vc.y = 0.0
	var jn := (1.0 + RESTITUTION) * -v.y
	var jt := Vector3.ZERO
	var slip := vc.length()
	if slip > 1e-5:
		# 0.4 * slip is the impulse that would reach pure rolling for a hollow sphere
		jt = -vc / slip * minf(0.4 * slip, FRICTION * jn)
	var nv := Vector3(vt.x, -v.y * RESTITUTION, vt.z) + jt
	var nw := w + r.cross(jt) / (I_FACTOR * RADIUS * RADIUS)
	return [nv, nw]


## Advances the ball one step. Returns {p, v, w, bounce, net}.
static func advance(p: Vector3, v: Vector3, w: Vector3, dt: float) -> Dictionary:
	var vm := v + accel(v, w) * (dt * 0.5)
	var np := p + vm * dt
	var nv := v + accel(vm, w) * dt
	var nw := w * exp(-SPIN_DECAY * dt)
	var bounce := false
	var net := false

	if signf(p.z) != signf(np.z) and absf(np.x) < NET_HALF_W \
			and np.y < TABLE_Y + NET_H + net_extra + RADIUS and np.y > TABLE_Y:
		net = true
		if np.y > TABLE_Y + NET_H + net_extra + RADIUS * 0.4:
			# clips the net cord and dribbles over
			nv = Vector3(nv.x * 0.5, absf(nv.y) * 0.4 + 0.4, nv.z * 0.35)
			nw *= 0.4
		else:
			np.z = signf(p.z) * RADIUS
			nv = Vector3(nv.x * 0.3, nv.y * 0.3, -nv.z * 0.12)
			nw *= 0.3

	if nv.y < 0.0 and np.y < TABLE_Y + RADIUS and p.y >= TABLE_Y + RADIUS - 0.05 and on_table(np):
		np.y = TABLE_Y + RADIUS
		var b := table_bounce(nv, nw)
		nv = b[0]
		nw = b[1]
		bounce = true
	elif nv.y < 0.0 and np.y < RADIUS:
		np.y = RADIUS
		nv = Vector3(nv.x * 0.85, -nv.y * 0.78, nv.z * 0.85)   # a ball on a hard floor keeps bouncing, faster and faster
		nw *= 0.6

	return {"p": np, "v": nv, "w": nw, "bounce": bounce, "net": net}


## Flies the ball until it bounces on the table or drops to table height.
static func landing(p: Vector3, v: Vector3, w: Vector3, max_t := 3.0) -> Dictionary:
	var f := _fly(p, v, w, max_t, INF)
	return {"pos": f[0], "v": f[1], "w": f[2], "net": f[3], "t": f[4], "on_table": f[5]}


## The solvers' trial flight: exactly the steps of advance() at DT_SOLVE, inlined
## with no per-step allocations. Returns [pos, v, w, net, t, on_table, clear]:
## `clear` is how high it crossed the net tape (-1 into the net, NAN if it
## stopped before the net), as net_clearance() would measure it. With a finite
## `reach` the flight also stops once it is cleanly over the net and has carried
## `reach` along `dir` — past the net nothing turns it back, so it can
## only go further from there, which is all the depth bisection needs to know.
static func _fly(p: Vector3, v: Vector3, w: Vector3, max_t: float, reach: float, dir := Vector3.ZERO) -> Array:
	const DT := DT_SOLVE
	var spin_k := exp(-SPIN_DECAY * DT)
	var p0 := p
	var t := 0.0
	var net := false
	var clear := NAN
	while t < max_t:
		var vm := v + (GRAVITY - DRAG * v.length() * v + MAGNUS * w.cross(v)) * (DT * 0.5)
		var np := p + vm * DT
		var nv := v + (GRAVITY - DRAG * vm.length() * vm + MAGNUS * w.cross(vm)) * DT
		var nw := w * spin_k
		var bounce := false
		var cross := signf(p.z) != signf(np.z)
		var hit_net := false
		if cross and absf(np.x) < NET_HALF_W and np.y < TABLE_Y + NET_H + net_extra + RADIUS and np.y > TABLE_Y:
			hit_net = true
			if np.y > TABLE_Y + NET_H + net_extra + RADIUS * 0.4:
				nv = Vector3(nv.x * 0.5, absf(nv.y) * 0.4 + 0.4, nv.z * 0.35)
				nw *= 0.4
			else:
				np.z = signf(p.z) * RADIUS
				nv = Vector3(nv.x * 0.3, nv.y * 0.3, -nv.z * 0.12)
				nw *= 0.3
		if nv.y < 0.0 and np.y < TABLE_Y + RADIUS and p.y >= TABLE_Y + RADIUS - 0.05 and on_table(np):
			np.y = TABLE_Y + RADIUS
			var b := table_bounce(nv, nw)
			nv = b[0]
			nw = b[1]
			bounce = true
		elif nv.y < 0.0 and np.y < RADIUS:
			np.y = RADIUS
			nv = Vector3(nv.x * 0.85, -nv.y * 0.78, nv.z * 0.85)
			nw *= 0.6
		if is_nan(clear) and (hit_net or cross) and t < 2.0:
			clear = -1.0 if hit_net else np.y - (TABLE_Y + NET_H + RADIUS)
		t += DT
		if hit_net:
			net = true
		if bounce:
			return [np, nv, nw, net, t, true, clear]
		p = np
		v = nv
		w = nw
		if v.y < 0.0 and p.y <= TABLE_Y + RADIUS:
			break
		if not net and signf(p.z) != signf(p0.z) and (p - p0).dot(dir) > reach:
			break
	return [p, v, w, net, t, false, clear]


## Finds a launch velocity that lands on `target` (x, z) with the given
## horizontal speed and spin. Bisects the vertical speed for depth, nudges the
## aim point to cancel side-spin curl, and slows down if the net gets in the way.
static func solve_shot(p0: Vector3, target: Vector3, speed: float, w: Vector3) -> Vector3:
	return _solve_shot(p0, target, speed, w)[0]


## solve_shot() plus the checked flight of the answer: [v, flight].
static func _solve_shot(p0: Vector3, target: Vector3, speed: float, w: Vector3) -> Array:
	var v := Vector3.ZERO
	var chk := []
	var s := speed
	# into the net at this pace: try a little more pace first (a slow ball from
	# far back needs it), then less
	var tries := [1.0, 1.15, 1.3, 0.85, 0.72, 0.6]
	for attempt in tries.size():
		s = speed * float(tries[attempt])
		var aim := target
		for it in 3:
			var to := Vector3(aim.x - p0.x, 0.0, aim.z - p0.z)
			var dist := to.length()
			var dir := to / maxf(dist, 0.001)
			var lo := -6.0
			var hi := 8.0
			for i in 14:
				var mid := (lo + hi) * 0.5
				var r := _fly(p0, dir * s + Vector3.UP * mid, w, 3.0, dist, dir)
				var d: float = (r[0] - p0).dot(dir)
				if d < dist:
					lo = mid
				else:
					hi = mid
			v = dir * s + Vector3.UP * ((lo + hi) * 0.5)
			chk = _fly(p0, v, w, 3.0, INF)
			var err := Vector3(target.x - chk[0].x, 0.0, target.z - chk[0].z)
			if err.length() < 0.03:
				break
			aim += err
		if not chk[3]:
			return [v, chk]
	return [v, chk]


## Height by which a flight clears the net tape (negative = into the net).
static func net_clearance(p0: Vector3, v: Vector3, w: Vector3) -> float:
	var p := p0
	var t := 0.0
	while t < 2.0:
		var r := advance(p, v, w, DT_SOLVE)
		if r.net:
			return -1.0
		if signf(p.z) != signf(r.p.z):
			return r.p.y - (TABLE_Y + NET_H + RADIUS)
		p = r.p
		v = r.v
		w = r.w
		t += DT_SOLVE
	return 1.0


## Flat drive: the fastest speed (up to `top_speed`) whose flight lands on
## `target` and still clears the net tape by `margin`, so the ball skims the net
## instead of looping over it. Slower always arcs higher, so bisect the speed.
static func solve_drive(p0: Vector3, target: Vector3, top_speed: float, w: Vector3, margin: float) -> Vector3:
	var a := _solve_shot(p0, target, top_speed, w)
	if _clearance(p0, a, w) >= margin and _lands(a, target):
		return a[0]
	var lo := 0.5
	var hi := 1.0
	var best = null   # the fallback is solved only if needed
	for i in 4:
		var mid := (lo + hi) * 0.5
		var m := _solve_shot(p0, target, top_speed * mid, w)
		if _clearance(p0, m, w) >= margin and _lands(m, target):
			lo = mid
			best = m[0]
		else:
			hi = mid
	# no flat drive both clears the net and stays on the table from here (a low
	# ball, too much pace): play it as a slower, arcing ball instead
	return best if best != null else solve_shot(p0, target, top_speed * 0.45, w)


## A _solve_shot() answer whose checked flight really lands on the table, near
## where it was aimed.
static func _lands(shot: Array, target: Vector3) -> bool:
	var f: Array = shot[1]
	return bool(f[5]) and not bool(f[3]) and Vector2(f[0].x - target.x, f[0].z - target.z).length() < 0.2


## Net clearance of a _solve_shot() answer, read off its checked flight when
## that flight got as far as the net.
static func _clearance(p0: Vector3, shot: Array, w: Vector3) -> float:
	var c: float = shot[1][6]
	return net_clearance(p0, shot[0], w) if is_nan(c) else c


## Serve: first bounce on the server's half at `first`, then it must carry over
## the net onto the receiver's half. Tries a few speeds around `base_speed`.
## A legal serve from `p0` with spin `w` for the server on `side` (the sign of
## its half): tries first-bounce depths (heavy backspin wants to bounce nearer
## the net, a fast topspin serve nearer the server's end), and if no speed works
## at any depth, eases the spin off. Returns [velocity, spin used, legal].
static func solve_serve_safe(p0: Vector3, x: float, side: float, w: Vector3, base_speed: float) -> Array:
	for k in [1.0, 0.75, 0.5]:
		for z in [1.0, 0.75, 1.2, 0.55]:
			var r := _serve_at(p0, Vector3(x, 0.0, z * side), w * k, base_speed)
			if r[1]:
				return [r[0], w * k, true]
	return [solve_serve(p0, Vector3(x, 0.0, side), w, base_speed), w, false]


static func solve_serve(p0: Vector3, first: Vector3, w: Vector3, base_speed: float) -> Vector3:
	return _serve_at(p0, first, w, base_speed)[0]


## One first-bounce target: [velocity, legal]; the first speed's answer when
## none is legal.
static func _serve_at(p0: Vector3, first: Vector3, w: Vector3, base_speed: float) -> Array:
	var to := Vector3(first.x - p0.x, 0.0, first.z - p0.z)
	var dist := to.length()
	var dir := to / maxf(dist, 0.001)
	var receiver_sign := -signf(first.z)
	var best := dir * base_speed
	for f in [1.0, 0.85, 1.15, 0.7, 1.3, 0.55, 1.5, 0.45]:
		var s: float = base_speed * f
		var lo := -6.0
		var hi := 3.0
		for i in 14:
			var mid := (lo + hi) * 0.5
			var r := _fly(p0, dir * s + Vector3.UP * mid, w, 3.0, dist, dir)
			var d: float = (r[0] - p0).dot(dir)
			if d < dist:
				lo = mid
			else:
				hi = mid
		var v := dir * s + Vector3.UP * ((lo + hi) * 0.5)
		if f == 1.0:
			best = v
		var r1 := landing(p0, v, w)
		if not r1.on_table:
			continue
		var r2 := landing(r1.pos, r1.v, r1.w)
		if r2.on_table and not r2.net and signf(r2.pos.z) == receiver_sign:
			return [v, true]
	return [best, false]


## The hittable window for `receiver`: ball positions from its first bounce on
## the receiver's half until a second bounce, it drops near the floor, or it flies
## far behind the table. The receiver may meet the ball anywhere along it —
## early on the rise, at the top, or late after backing off the table.
## `skip` ignores that many earlier bounces (the server's own bounce on a serve).
## `already`: the ball has just bounced on the receiver's side (re-reading it then).
static func predict_path(p: Vector3, v: Vector3, w: Vector3, receiver: int, skip: int, already := false) -> Dictionary:
	var t := 0.0
	var pts := PackedVector3Array()
	var bounced := already
	while t < 3.5:
		var r := advance(p, v, w, DT_PRED)
		p = r.p
		v = r.v
		w = r.w
		t += DT_PRED
		if r.bounce:
			if skip > 0:
				skip -= 1
				continue
			if bounced or signf(p.z) != float(receiver):
				break
			bounced = true
		if bounced:
			pts.append(p)
			if p.y < 0.25 or absf(p.z) > 3.2:
				break
		elif skip == 0 and p.y < TABLE_Y - 0.1:
			break
	return {"ok": pts.size() > 4, "pts": pts}


## Ball position where the path first reaches depth `z` (path runs toward ±z).
static func point_at_z(pts: PackedVector3Array, z: float) -> Variant:
	for i in range(1, pts.size()):
		var a := pts[i - 1]
		var b := pts[i]
		if (a.z - z) * (b.z - z) <= 0.0 and a.z != b.z:
			return a.lerp(b, (z - a.z) / (b.z - a.z))
	return null


static func apex_index(pts: PackedVector3Array) -> int:
	var best := 0
	for i in pts.size():
		if pts[i].y > pts[best].y:
			best = i
	return best
