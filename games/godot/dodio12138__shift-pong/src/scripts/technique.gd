extends RefCounted
## Grips, forehand/backhand wings and power generation. Turns "which button,
## which wing, when, how prepared" into a concrete stroke: name, speed, spin,
## depth and how much the incoming spin and a rushed swing throw it off.

# Shot ids mirror main.gd's Shot enum.
const BLOCK := 0
const LOOP := 1
const PUSH := 2
const SMASH := 3

## speed / spin multiply the stroke, ctrl < 1 means bigger errors on that wing.
## early: extra pace when taking the ball on the rise. fh_bias: how far into the
## backhand side the player still steps round to use the forehand (metres).
## bh_face: which rubber the backhand uses ("back" or "front" for traditional penhold).
const GRIPS := {
	"shake": {
		"name": "横拍",
		"fh": {"speed": 1.0, "spin": 1.0, "ctrl": 1.0},
		"bh": {"speed": 0.96, "spin": 0.95, "ctrl": 0.97},
		"early": 1.0, "wrist": 1.0, "fh_bias": 0.0, "bh_reach": 1.0,
		"bh_block": "快挡", "flick": true, "bh_face": "back",
		"desc": "正反手均衡, 反手可台内拧拉",
	},
	"pen": {
		"name": "直拍推挡",
		"fh": {"speed": 1.07, "spin": 0.95, "ctrl": 1.02},
		"bh": {"speed": 0.8, "spin": 0.65, "ctrl": 0.82},
		"early": 1.1, "wrist": 1.18, "fh_bias": 0.14, "bh_reach": 0.88,
		"bh_block": "推挡", "flick": false, "bh_face": "front",
		"desc": "正手快攻凶, 台内搓摆转; 反手推挡快稳但拉不动, 多侧身",
	},
	"rpb": {
		"name": "直拍横打",
		"fh": {"speed": 1.06, "spin": 0.97, "ctrl": 1.0},
		"bh": {"speed": 0.92, "spin": 0.9, "ctrl": 0.9},
		"early": 1.06, "wrist": 1.12, "fh_bias": 0.06, "bh_reach": 0.95,
		"bh_block": "快挡", "flick": true, "bh_face": "back",
		"desc": "正手凶, 反手用背面横打, 介于两者之间",
	},
}
const GRIP_ORDER := ["shake", "pen", "rpb"]


## ctx keys: shot, grip, wing ("fh"/"bh"), timing ("early"/"peak"/"late"),
## s_in (incoming topspin rad/s), in_speed, over_table, low, drive_ok (ball sits
## up close enough to the table to be driven flat), settle (0..1 how set the feet
## were), windup (0..1 how much backswing).
static func stroke(ctx: Dictionary) -> Dictionary:
	var g: Dictionary = GRIPS[ctx.grip]
	var wing: Dictionary = g[ctx.wing]
	var bh: bool = ctx.wing == "bh"
	var s_in: float = ctx.s_in
	var timing: String = ctx.timing
	var settle: float = ctx.settle
	var windup: float = ctx.windup
	var r := {"name": "", "speed": 5.0, "top": 0.0, "side": 0.0, "depth": 0.85,
			"k_top": 0.0, "k_back": 0.0, "wobble": 1.0, "notes": [],
			"net_margin": -1.0, "boost": 1.0}
	# net_margin >= 0: hit as fast as `speed * boost` allows while still clearing the
	# net tape by that much (flat, driving trajectories); < 0: fixed speed, natural arc

	match int(ctx.shot):
		LOOP:
			r.k_top = 0.0006
			r.k_back = 0.0005
			if bh and g.flick and ctx.over_table and (s_in < -60.0 or ctx.get("flick", false)) and timing != "late":
				# banana flick: wrist-driven sidespin topspin from over the table
				r.name = "拧拉"
				r.speed = 5.6; r.top = 300.0; r.side = 160.0; r.depth = 0.9
				r.net_margin = 0.15; r.boost = 1.15
			elif ctx.drive_ok and s_in > -60.0 and s_in < 320.0:
				# ball up and neither heavy backspin nor heavy topspin (that one
				# gets looped back: driven flat it flies long): hit through it
				r.name = "抽球"
				r.speed = 13.0; r.top = 140.0; r.depth = 1.22; r.k_top = 0.0007
				r.net_margin = 0.03
			elif s_in < -80.0 or ctx.low:
				# slow, heavy loop to lift backspin or a ball taken low
				r.name = "高吊弧圈"
				r.speed = 6.2; r.top = 450.0; r.depth = 1.0
			elif timing == "early" and ctx.over_table:
				# short swing that uses the incoming pace
				r.name = "快带"
				r.speed = 7.6; r.top = 260.0; r.depth = 1.0; r.k_top = 0.00045
				r.net_margin = 0.10; r.boost = 1.2
			else:
				r.name = "前冲弧圈"
				r.speed = 8.6; r.top = 320.0; r.depth = 1.05
				r.net_margin = 0.18; r.boost = 1.3
			r.speed *= lerpf(0.88, 1.1, windup)
			r.top *= lerpf(0.85, 1.1, windup) * wing.spin
		SMASH:
			r.net_margin = 0.05
			r.name = "扣杀"
			r.speed = 11.0; r.top = 90.0; r.depth = 0.95
			r.k_top = 0.0005; r.k_back = 0.0005
			r.speed *= lerpf(0.85, 1.08, windup)
		BLOCK:
			# no swing of its own: borrows the incoming pace
			r.speed = clampf(float(ctx.in_speed) * 0.55, 3.6, 8.0)
			r.top = 40.0 + maxf(s_in, 0.0) * 0.35
			r.k_top = 0.0012; r.k_back = 0.0022
			r.name = g.bh_block if bh else "快挡"
			if bh and ctx.grip == "pen":
				# penhold push-block: flat, fast and very stable against topspin
				r.speed *= 1.15; r.top = 15.0; r.k_top *= 0.7
			r.notes.append("借力")
		PUSH:
			r.k_top = 0.0025; r.k_back = 0.0005
			if timing == "early" and ctx.over_table:
				r.name = "摆短"
				r.speed = 2.4; r.top = -200.0; r.depth = 0.42
			elif ctx.get("far", false):
				# pushed from well back it is really a long chop: more pace, less bite
				r.name = "劈长"
				r.speed = 5.0; r.top = -200.0; r.depth = 1.0
			else:
				r.name = "劈长"
				r.speed = 3.6; r.top = -270.0; r.depth = 0.95
			r.top *= g.wrist
			r.wobble *= 0.6   # a push is a control stroke: the steadiest one there is

	r.name = ("反手" if bh else "正手") + r.name
	if int(ctx.shot) != BLOCK:
		r.speed *= wing.speed
	if timing == "early":
		r.speed *= g.early
	r.k_top /= wing.ctrl
	r.k_back /= wing.ctrl
	r.wobble /= wing.ctrl

	# feet set and weight transferred (蹬地转腰) = full power and control;
	# hitting on the run = arm only
	if int(ctx.shot) != BLOCK:
		r.speed *= lerpf(0.82, 1.06, settle)
	r.wobble *= lerpf(1.7, 0.85, settle)
	if settle > 0.8:
		r.notes.append("到位发力")
	elif settle < 0.4:
		r.notes.append("被动")
	if int(ctx.shot) in [LOOP, SMASH]:
		if windup > 0.8:
			r.notes.append("引拍充分")
		elif windup < 0.3:
			r.notes.append("没引拍")
	return r
