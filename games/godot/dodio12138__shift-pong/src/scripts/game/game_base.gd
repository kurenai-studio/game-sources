extends Node
## Layer 1 of the game script (main.gd extends game_modes <- game_match <-
## game_arena <- this): every constant and piece of state, the small rule
## helpers everything reads, and empty hooks the upper layers fill in.
## Pixel-art 3D table tennis, top-down "Smash Court" look: flat unshaded teal
## palette, near-overhead camera that drifts with the ball. Spin is made visible:
## coloured curving trail, dots orbiting the ball about its spin axis
## and a HUD gauge.
## The 3D scene renders into a low-res SubViewport which is upscaled with
## nearest filtering and snapped to a fixed palette on screen.

const Sim := preload("res://scripts/ball_sim.gd")
const PostShader := preload("res://shaders/pixel_post.gdshader")
const OutlineShader := preload("res://shaders/outline.gdshader")
const SpinGauge := preload("res://scripts/spin_gauge.gd")
const PowerGauge := preload("res://scripts/power_gauge.gd")
const Tech := preload("res://scripts/technique.gd")
const Icons := preload("res://scripts/icons.gd")
const ControlsBar := preload("res://scripts/controls_bar.gd")
const ServeMeter := preload("res://scripts/serve_meter.gd")
const StaminaRing := preload("res://scripts/stamina_ring.gd")
const Sfx := preload("res://scripts/sfx.gd")
const Recorder := preload("res://scripts/replay.gd")
const Roster := preload("res://scripts/roster.gd")
const Tie := preload("res://scripts/team_tie.gd")
const ClubUI := preload("res://scripts/club_ui.gd")
const Tour := preload("res://scripts/tour.gd")
const CupRun := preload("res://scripts/cup_run.gd")
const ShiftRun := preload("res://scripts/shift_run.gd")
const SkillWheel := preload("res://scripts/skill_wheel.gd")
const PowerArc := preload("res://scripts/power_arc.gd")
const ScoreBar := preload("res://scripts/score_bar.gd")
const SideCard := preload("res://scripts/side_card.gd")
const AnalysisPanel := preload("res://scripts/analysis_panel.gd")
const People := preload("res://scripts/people.gd")
const Gear := preload("res://scripts/gear.gd")

enum Shot { BLOCK, LOOP, PUSH, SMASH }
const SHOT_NAMES := ["挡", "弧圈", "搓", "扣杀"]

const PLAYER := 1   # near side, +z
const AI := -1      # far side, -z
const PADDLE_SCALE := {1: 1.25, -1: 1.1}   # drawn size only; the hit radius stays forgiving
## Difficulty: pace and spin of every stroke, how hard spin you fail to cancel
## throws the return off, how fast the AI moves and how well it reads spin, your
## racket's hit radius, how often the AI plays tactically (tactic: share of
## strokes where it targets weaknesses, attacks chances and runs serve patterns),
## and stroke precision (scales the random error of every shot).
const LEVELS := [
	# 休闲: slow, light spin, sends it back down the middle, no tricks (gentle)
	{"name": "休闲", "speed": 0.7, "spin": 0.55, "kick": 0.3, "ai_speed": 2.0, "ai_read": 0.5, "ai_err": 0.55, "reach": 0.38, "tactic": 0.0, "precision": 1.15, "ai_reach": 0.13, "gentle": true},
	{"name": "入门", "speed": 0.85, "spin": 0.8, "kick": 0.5, "ai_speed": 2.3, "ai_read": 0.6, "ai_err": 0.6, "reach": 0.34, "tactic": 0.1, "precision": 1.3, "ai_reach": 0.14},
	{"name": "业余", "speed": 1.0, "spin": 1.0, "kick": 1.0, "ai_speed": 2.8, "ai_read": 0.75, "ai_err": 0.45, "reach": 0.30, "tactic": 0.3, "precision": 1.0, "ai_reach": 0.16},
	{"name": "专业", "speed": 1.25, "spin": 1.25, "kick": 1.7, "ai_speed": 4.0, "ai_read": 0.85, "ai_err": 0.3, "reach": 0.26, "tactic": 0.7, "precision": 0.75, "ai_reach": 0.19},
	{"name": "世界级", "speed": 1.55, "spin": 1.5, "kick": 2.4, "ai_speed": 5.2, "ai_read": 0.97, "ai_err": 0.08, "reach": 0.23, "tactic": 0.95, "precision": 0.42, "ai_reach": 0.22},
]
## 操作辅助 (a setting, in every mode): your racket's reach (x the standard 0.30),
## how strongly your feet are drawn to where the ball is going (0..1 of the
## left/right gap closed for you), how much of a missed serve release still
## sprays the ball, and whether the match eases off when you fall well behind
## (quick play and stand-alone cups only).
const HELP_LEVELS := [
	{"name": "休闲", "reach": 1.35, "magnet": 0.45, "serve": 0.0, "adapt": true, "desc": "自动跟球、发球不失误、落后时 AI 放水"},
	{"name": "新手", "reach": 1.15, "magnet": 0.22, "serve": 0.35, "adapt": true, "desc": "帮你往球的方向靠、发球更稳、落后时 AI 放水"},
	{"name": "标准", "reach": 1.0, "magnet": 0.0, "serve": 1.0, "adapt": false, "desc": "全靠自己跑位和发球"},
	{"name": "硬核", "reach": 0.8, "magnet": 0.0, "serve": 1.2, "adapt": false, "desc": "拍面更小、发球更容易偏"},
]
const REACH_STD := 0.30
const SPIN_REF := 420.0     # rad/s of incoming spin that takes a full-strength hold to cancel
const WINDUP_FULL := 0.65   # seconds of holding a stroke key for full strength
## Stamina (0..100). Big swings, long serve charges and running drain it; it comes
## back slowly in a rally and quickly between points. It caps how much power you
## can put into a stroke or serve — so a tired player can't cancel heavy spin.
const STAMINA_REGEN_RALLY := 3.5
const STAMINA_REGEN_SET := 3.0    # extra per second while standing set (feet planted)
const STAMINA_REGEN_REST := 10.0
const STAMINA_RUN := 0.8          # per metre moved, any time (pacing about costs too)
const FATIGUE := 0.035            # share of every point of stamina spent that comes off the max for good
const MIN_MAX_STAMINA := 55.0
const HEAVY_NEED := 0.55    # balls needing at least this much get the warning aura and answer card
## Stroke animations, one per technique. Poses are racket offsets from where it
## meets the ball: x = across the body (+ = out to the hitting wing's side), y = up,
## z = toward the net. A stroke goes from `start` (backswing, also shown as the
## ball comes in) to `end` (follow-through); `close` tilts the face (+ closed over
## the ball, - open underneath); `roll` twists the wrist; `yaw` turns the racket
## with the body (handle sweeps from back-right round to front-left on a forehand).
## "big" strokes swing FH_BIG times wider on the forehand (the full-body forehand
## drive / smash / loop) and leave afterimages.
const FH_BIG := 1.7
const GHOSTS := 3
const WING_TURN := 0.9          # racket yaw (rad) when set for the forehand; minus for the backhand
const SWINGS := {
	"抽球": {"start": Vector3(0.20, 0.02, -0.18), "end": Vector3(-0.22, 0.06, 0.28), "close": Vector2(0.1, 0.35), "roll": Vector2.ZERO, "yaw": Vector2(0.9, -0.8), "dur": 0.2, "big": true},
	"扣杀": {"start": Vector3(0.14, 0.22, -0.18), "end": Vector3(-0.2, -0.04, 0.32), "close": Vector2(0.2, 0.8), "roll": Vector2.ZERO, "yaw": Vector2(0.7, -0.7), "dur": 0.18, "big": true},
	"前冲弧圈": {"start": Vector3(0.16, -0.14, -0.14), "end": Vector3(-0.14, 0.22, 0.2), "close": Vector2(0.3, 1.0), "roll": Vector2.ZERO, "yaw": Vector2(0.6, -0.6), "dur": 0.22, "big": true},
	"高吊弧圈": {"start": Vector3(0.06, -0.18, -0.04), "end": Vector3(-0.04, 0.30, 0.08), "close": Vector2(0.4, 1.2), "roll": Vector2.ZERO, "dur": 0.22},
	"快带": {"start": Vector3(0.05, -0.03, -0.05), "end": Vector3(-0.06, 0.08, 0.12), "close": Vector2(0.3, 0.7), "roll": Vector2.ZERO, "dur": 0.12},
	"拧拉": {"start": Vector3(0.04, -0.02, -0.03), "end": Vector3(-0.04, 0.10, 0.10), "close": Vector2(0.3, 0.6), "roll": Vector2(-1.0, 0.8), "dur": 0.14},
	"挡": {"start": Vector3(0.0, 0.0, -0.03), "end": Vector3(0.0, 0.0, 0.10), "close": Vector2(0.2, 0.25), "roll": Vector2.ZERO, "dur": 0.1},
	"搓": {"start": Vector3(0.03, 0.05, -0.04), "end": Vector3(-0.02, -0.03, 0.12), "close": Vector2(-0.7, -0.9), "roll": Vector2.ZERO, "dur": 0.14},
}
const PIXEL_HEIGHTS := [360, 270, 180, 144, 100]   # low-res render height per pixel-size step
const RAD_TO_RPM := 60.0 / TAU
## Stroke keys laid out like the spin they put on the ball: top row = topspin
## (loop, smash on a high ball), bottom row = backspin (push), left / right column
## adds left / right side spin. Value: [row (1 top, -1 back), side (+1 left, -1 right)].
## Left / right mouse buttons act as W / S; nothing held = block.
const STROKE_KEYS := {KEY_Q: [1, 1], KEY_W: [1, 0], KEY_E: [1, -1], KEY_A: [-1, 1], KEY_S: [-1, 0], KEY_D: [-1, -1]}
const SIDE_KEY_SPIN := 220.0
const SERVE_CHARGE_FULL := 1.5   # seconds of holding for the most spin a serve can carry
const SERVE_TELL := 0.7        # the AI shows its serve spin this long before serving
const CAM_MODES := ["俯视跟随", "俯视固定", "背后", "侧面转播", "等角像素", "球员视角", "跟球"]
const TIMING_NAMES := {"early": "上升期", "peak": "高点期", "late": "下降期"}
# flat palette (matches shaders/pixel_post.gdshader)
const C_DEEP := Color(0.050, 0.110, 0.290)
const C_FLOOR_SHADOW := Color(0.360, 0.070, 0.085)
const C_FLOOR := Color(0.560, 0.120, 0.130)
const C_FLOOR_LIGHT := Color(0.660, 0.190, 0.180)
const C_TABLE_SHADOW := Color(0.070, 0.230, 0.500)
const C_TABLE := Color(0.100, 0.330, 0.660)
const C_TABLE_LIGHT := Color(0.220, 0.460, 0.780)
const C_WHITE := Color(0.960, 0.960, 0.940)
const C_PALE := Color(0.720, 0.780, 0.860)
const C_YELLOW := Color(0.980, 0.800, 0.250)
const C_ORANGE := Color(0.980, 0.520, 0.150)
const C_RED := Color(0.900, 0.080, 0.120)
const C_NAVY := Color(0.070, 0.090, 0.200)
const C_INK := Color(0.040, 0.050, 0.100)
const C_SKY := Color(0.420, 0.820, 0.980)
const C_VIOLET := Color(0.776, 0.478, 0.949)
const COURT := Vector2(4.2, 5.6)   # half-size of the red court inside the barriers (x, z)

# spin visualisation
const TRAIL_N := 14
const ORBIT_N := 3
const ORBIT_RATE := 0.05      # displayed orbit rad/s per real rad/s of spin
const MIN_SPIN := 40.0

var pixel_scale_idx := 0
var level_idx := 2
var watch_level := 2        # level of the AI playing your side when watching (K)
var autoplay := false
var screenshot_path := ""
var shot_on_heavy := false   # debug: take the screenshot when a heavy-ball warning is up
var heavy_frames := 0
var serve_demo := false      # debug: fake holding E on your serve, then screenshot the meter
var shot_on_var := false     # debug: screenshot a VAR replay at its slow-motion moment
var shot_on_style := ""      # debug: screenshot mid-swing of this stroke animation
var elapsed := 0.0
# focus cards: lose two points in a row to earn one (at most FOCUS_MAX a game);
# T spends one to slow time down for a few real-time seconds
const FOCUS_MAX := 5
const FOCUS_SECONDS := 3.5
const FOCUS_SCALE := 0.35
var focus_cards := 0
var focus_granted := 0
var lose_streak := 0
var adapt := 0.0              # how far the match is easing off for you (-0.4..1), see adapt_on
var adapt_carry := 0.0        # what a heavy defeat carries into the next game
var adapt_cache := {}         # the AI's eased parameters: {src, a, d}
var last_stroke := {PLAYER: "", AI: ""}   # each side's latest stroke name (for the coach's tip)
var focus_until_ms := 0
var assist := true
var post_mode := 1
var outline_on := false
var cam_mode := 0
var cam_pos := Vector3(0.0, 7.4, 3.8)
var cam_look := Vector3(0.0, Sim.TABLE_Y, 0.15)
var cam_zoom := 1.0           # >1 pulls the camera back and up for long, deep rallies
var pixel_zoom := 1.0         # cam_zoom as last applied to the render resolution (stepped)

var vp: SubViewport
var world: Node3D
var screen: TextureRect
var cam: Camera3D
var ball_mesh: MeshInstance3D
var ball_shadow: MeshInstance3D
var trail_segs: Array[MeshInstance3D] = []
var trail_pts: Array[Vector3] = []
var orbit_dots: Array[MeshInstance3D] = []
var orbit_phase := 0.0
var bursts: Array[MeshInstance3D] = []
var burst_age: Array[float] = []
var burst_spin: Array[float] = []   # yaw rate, so side-spin ripples visibly turn
var burst_scale: Array[float] = []  # heavier balls leave bigger ripples
var spin_gauge: Control
var controls_bar: Control
var power_gauge: Control
var paddle_parts := {}
var racket_ghosts := {}     # side -> afterimage nodes trailing a big swing
var racket_hist := {1: [], -1: []}   # recent racket transforms, newest first
var hit_marker: MeshInstance3D
var hud_screen: TextureRect       # shows the HUD viewport over the 3D view
var heavy_aura: MeshInstance3D
var heavy_sparks: CPUParticles3D
var heavy_smoke: CPUParticles3D
var solve_card: TextureRect   # HUD-resolution card that follows the 3D hit point
var heavy := false          # the ball in flight is a heavy one (either direction)
var paddle_nodes := {}
var paddle_shadows := {}
var post_mat: ShaderMaterial
var hud_vp: SubViewport        # the HUD's own low-res canvas
var shift_word: Control        # 规则转移's SHIFT! over the table
var static_pos := PackedVector3Array()   # scenery being gathered into one mesh (see add_static)
var static_col := PackedColorArray()
var static_idx := PackedInt32Array()
var outline_mat: ShaderMaterial
var score_label: Label              # status text, shown under the score bar
var score_bar: Control
var side_cards := {}               # side -> SideCard
var analysis_panel: Control        # the game's data analysis (I)
# this game's data for the analysis panel: where each side hit from, where its
# balls landed, stroke mix / wing / timing, ball speed and spin, the lead
# after every point, skills used
var gstats := {}
var _font: Font
var board_digits := {}
var board_serve := {}
var board_games := {}
var scoreboard: Node3D
var scoreboard_face: Node3D   # the board itself, tilted to face the camera
var info_label: RichTextLabel
var tip_label: RichTextLabel
var banner_label: Label

# ball state: position, velocity, angular velocity (rad/s)
var bp := Vector3.ZERO
var bv := Vector3.ZERO
var bw := Vector3.ZERO
var ball_live := false

# rules
var score := {PLAYER: 0, AI: 0}
var first_server := PLAYER
var server := PLAYER
var waiting_serve := true
var serve_timer := 0.0
var point_over := false
var point_timer := 0.0
var game_over := false
var last_hitter := 0
var serve_bounce_pending := false
var bounced_receiver := false
var missed := {PLAYER: false, AI: false}
var rally := 0

# rackets
var paddle_pos := {PLAYER: Vector3(0.0, 1.0, 1.55), AI: Vector3(0.0, 1.0, -1.65)}
var paddle_vel := {PLAYER: Vector3.ZERO, AI: Vector3.ZERO}
var hit_pred := {PLAYER: {"ok": false}, AI: {"ok": false}}
var react_timer := {PLAYER: 0.0, AI: 0.0}
var aim_err := {PLAYER: Vector3.ZERO, AI: Vector3.ZERO}
var swing := {PLAYER: -1.0, AI: -1.0}            # seconds into the current stroke animation, -1 = none
var swing_style := {PLAYER: "挡", AI: "挡"}       # key into SWINGS
var plan := {PLAYER: {}, AI: {}}   # AI-controlled racket: {"shot", "pos", "timing"}
var serve_x := 0.0
# serve preview: hold a stroke key to pick the spin (shown around the ball), release to serve
var serve_hold := 0.0
var serve_held := Vector2i.ZERO
var serve_armed := false   # keys must be released once after the point starts
var serve_meter: Control
var stamina_rings := {}     # side -> wheel drawn next to that racket
var sfx: Node
# replays: everything is recorded; B replays the last rally, contentious calls get VAR
const EDGE_BALL := 0.015      # a bounce this close to the table edge counts as an edge ball
const NEAR_MISS := 0.03       # missing the table by less than this is a close call
var rec = Recorder.new()
var replay := {}              # active replay, empty when playing
var replay_saved := {}        # live state to restore after a replay
var replay_ev := 0            # next recorded sound event to play
var rally_start_t := 0.0
var last_hit_t := 0.0
var var_flag := {}            # contentious moment in the current rally (edge / net / near miss)
var pending_var := {}         # VAR check waiting for the frames after the point to be recorded
## VAR is a challenge: on a close call (edge ball, ball just off the line) the
## umpire calls it, sometimes wrongly, and the side the call went against may ask
## for the replay. Each side has CHALLENGES per game; an upheld one is kept.
const CHALLENGES := 2
const UMP_ERR := 0.3          # how often the umpire gets a close one wrong
var challenges := {PLAYER: CHALLENGES, AI: CHALLENGES}
var var_call := {}            # the call waiting on a challenge: {w, r, tw, tr, flag, by, wrong, wait, review}
var last_rally := {}          # {from, to} for the B replay
var letterbox: Array[ColorRect] = []
var replay_tag: Label
# footwork: the player stands behind the racket; every STEP_LEN of travel plants a foot
const STEP_LEN := 0.42
const PRINT_LIFE := 5.0
var footprints: Array[MeshInstance3D] = []
var print_age: Array[float] = []
var print_ink: Array[float] = []      # how dark each print starts (a harder push leaves a darker mark)
var print_next := 0
var step_dist := {PLAYER: 0.0, AI: 0.0}
var step_next := {PLAYER: STEP_LEN, AI: STEP_LEN}   # stride length until the next foot, varies per step
var step_foot := {PLAYER: 1.0, AI: 1.0}
var last_run_vel := {PLAYER: Vector2.ZERO, AI: Vector2.ZERO}
var squeak_cd := {PLAYER: 0.0, AI: 0.0}
var serve_phase := 0.0       # needle swing phase
var serve_zone_t := 0.0      # sweet-zone drift phase
var serve_preview := Vector3.ZERO
var ai_serve_kind := "none"
var ai_serve_side := 0.0
# serve deception (发接发心理战): the AI's tell can show a fake spin; you see the
# ball's spin only as well as your receive reads it until it bounces on your side
var ai_tell_kind := "none"         # what the AI's serving motion shows
var ai_tell_side := 0.0
var serve_fake := {PLAYER: false, AI: false}   # this point's serve was a feint
var read_true := true              # you see the ball's real spin
var read_w := Vector3.ZERO         # the spin you think it has when you don't
var read_clarity := 1.0            # how well you read the serve you are receiving

# grips and power generation
var grip := {PLAYER: "shake", AI: "pen"}
var wing := {PLAYER: "fh", AI: "fh"}
var wing_yaw := {PLAYER: 0.0, AI: 0.0}
var settle := {PLAYER: 1.0, AI: 1.0}   # 0..1, how set the feet are (到位)
var stamina := {PLAYER: 100.0, AI: 100.0}
var max_stamina := {PLAYER: 100.0, AI: 100.0}   # wears down over the game and never recovers
# AI tactics
var weak := {PLAYER: {"fh": 0.0, "bh": 0.0}, AI: {"fh": 0.0, "bh": 0.0}}   # points lost per wing
var passive_at_hit := {PLAYER: false, AI: false}   # was this side rushed on its last stroke
var serve_attack := {PLAYER: false, AI: false}     # served short backspin, looking to attack ball three
var press_count := {PLAYER: 0, AI: 0}              # balls pressed to the opponent's backhand in a row
var ai_serve_attack := false
var tactic_name := ""
var windup_hold := 0.0                   # seconds the player has held a stroke button (引拍)

# team mode (团体赛)
var tie = null                     # the team tie in progress (Tie), null when there is none
var in_tie_match := false          # a tie match is on (not quick play or the menu's demo rally)
var prof := {PLAYER: {}, AI: {}}   # match parameters from each player's ratings; empty = difficulty levels
var pname := {PLAYER: "你", AI: "AI"}   # display names
var best_of := 1
var games := {PLAYER: 0, AI: 0}
var game_scores: Array = []
var match_first_server := PLAYER
var orders := {PLAYER: "", AI: ""}  # coach's instruction to each side's player (Tie.ORDERS)
var timeouts := {PLAYER: 1, AI: 1}  # one per match each
var timeout_req := 0               # side that called a timeout, taken once the point ends
var errors := {PLAYER: 0, AI: 0}   # points given away (out / into the net) this game
var run := {PLAYER: 0, AI: 0}      # points won in a row
var break_kind := ""               # "game" between games, "timeout" during one
var on_break := false              # play is paused with the coach panel up
var club_ui: Control
var ui_page := ""                  # debug: open the menu on this page
var tie_auto := false              # debug: play a whole tie hands-off
var duel: Array = []               # [your player, opponent] of the match being played
var boss_id := ""                  # set while a boss challenge is on
var boss_auto := ""                # debug: play this boss hands-off and quit
# the player's settings, and the legends beaten so far
var settings := {"volume": 8, "pixel": 0, "cam": 0, "legend": true, "skill_mode": true, "help": 1, "lang": "en", "beaten": [],
		"loadout": ["jinchan", "blink", "giant", "gravity"], "run_best": 0, "tut_offered": false, "music": true, "hud": "simple"}
const LANGS := [["en", "English"], ["zh", "简体中文"], ["ja", "日本語"]]
const SETTINGS_PATH := "user://settings.cfg"
var mstats := {}                   # this match's technical stats per side, plus rally lengths
var cup_run = null                 # a stand-alone cup (CupRun) from the title screen
var cup_solo_match := false        # the match being played is your singles-cup match
var shift_run = null               # SHIFT RUN in progress (ShiftRun)
var run_match := false             # the match being played is a SHIFT RUN stage
var game_to := 11                  # points to win a game (a run plays to 7)
var run_auto := false              # debug (--run-auto): play SHIFT RUN stages hands-off, print and quit

# 技能乒乓球 (skill mode, a switch in the settings): five focus cards a game for
# each side, spent on over-the-top skills picked from the skill wheel (hold
# Shift, or the middle mouse button). 金蝉脱壳: the stroke sends a real ball and a decoy that looks the
# same and lands dead (no bounce); you only know which is which when one lands,
# unless in slowed time (时间慢流) you click a ball to see through it (识破).
const SKILL_SLOTS := [
	{"id": "jinchan", "name": "金蝉脱壳", "desc": "下一板打出一真一假两个球，假球落台不弹", "cost": 1},
	{"id": "andu", "name": "暗渡陈仓", "desc": "过网后球隐身，只剩影子，落台才现形", "cost": 1},
	{"id": "huima", "name": "回马枪", "desc": "球先往外大幅拐出，再钩回来；落点圈落台前不显示", "cost": 1},
	{"id": "bianshu", "name": "鬼步变速", "desc": "球在空中先变慢、再突然加速，打乱节奏", "cost": 1},
	{"id": "blink", "name": "乾坤挪移", "desc": "过网后球突然瞬移到另一条线上", "cost": 1},
	{"id": "flip", "name": "斗转星移", "desc": "球落到对方台面后旋转瞬间反过来：上旋变下旋", "cost": 1},
	{"id": "spoon", "name": "偷梁换柱", "desc": "对方球拍变成勺子，击球范围减半（本分和下一分）", "cost": 2},
	{"id": "narrow", "name": "缩地成寸", "desc": "收窄自己半台，对方打到红区算出界（本分和下一分）", "cost": 2},
	{"id": "giant", "name": "巨灵神拍", "desc": "自己球拍巨大化：击球范围、力量更大，角度更刁（本分和下一分）", "cost": 2},
	{"id": "wall", "name": "铜墙铁壁", "desc": "准备好：对方下一次击球或发球的一瞬间，球网猛地升高", "cost": 2},
	{"id": "gravity", "name": "重力转移", "desc": "对方打出的球变重，落得更快、容易下网（本分和下一分）", "cost": 2},
	{"id": "view", "name": "视角转移", "desc": "打乱对方的视角，看不准来球（本分和下一分）", "cost": 2},
]
const WHEEL_SCALE := 0.25          # time runs this slow while the wheel is open
const STROKE_SKILLS := ["jinchan", "andu", "huima", "bianshu", "blink", "flip"]   # the ones that ride on a stroke
const HEX_SKILLS := ["spoon", "narrow", "giant", "gravity", "view"]   # spells on a side for this point and the next
## Each side takes four skills into a match (the loadout); the wheel and the
## number keys only hold those, and the AI only casts its own four.
const LOADOUT_SIZE := 4
var loadout := {PLAYER: [], AI: []}
var loadout_arg: Array = []        # debug (--loadout=a,b,c,d): both sides take these
const HOOK_SWING := 0.6            # 回马枪: how far out (m) the ball swings before hooking back
const SPOON_REACH := 0.5           # 偷梁换柱: a spoon's hitting area against a racket's
const NARROW_CUT := 0.24           # 缩地成寸: metres off each long edge of the half
const HEX_POINTS := 2              # both last this point and the next
const GIANT_REACH := 1.8           # 巨灵神拍: a giant racket's hitting area against a normal one
const GIANT_POWER := 1.15
const GIANT_ANGLE := 1.35          # placement pushed this much further out towards the sidelines
const WALL_EXTRA := 0.34           # 铜墙铁壁: the net goes up this much (to about half a metre)
const BLINK_SHIFT := 0.5           # 乾坤挪移: how far (m) the ball jumps sideways
const GRAVITY_SHIFT := 1.12        # 重力转移: gravity on the cursed side's balls, times this
## 规则转移: in a skill match, every fourth point the rules shift for both sides
## for the next two points, one of these at random.
const RULE_SHIFT_EVERY := 4
const RULE_SHIFTS := {"giant": "双方巨拍", "spoon": "双方勺子", "narrow": "双方半台收窄", "gravity": "双方球变重", "view": "双方视角错乱"}
var skill_armed := ""              # your skill ready for the next stroke
var skill_debug := false           # debug: skill mode on for this run
var no_save := false               # debug (--nosave): this run writes no saves or settings
var power_arc: Control             # hold-strength arc beside your racket
var arc_in_band := false           # for the click when the hold enters the right strength
var menu_from := "practice"        # the menu page the current quick match / tutorial was started from
var last_drill: Array = []         # start_drill's arguments, for 再练一组
var skill_test := false            # 技能对轰 (training ground): both sides' focus never runs out, the AI casts far more
var spells_debug := false         # debug (--spells): point-start spells far more often, for footage
var clean := false                 # debug (--clean): footage mode, no key hints, timestamps for cutting
var human_sim := false             # debug (--human-sim): your side's AI hits with a human's random hold strength
var ai_focus := 0                  # the far side's focus cards in skill mode
var decoy := {}                    # the 金蝉脱壳 decoy in flight: {p, v, w, recv, pred, landed, dead_t, revealed, fooled}
# the other stroke skills on the ball in flight: {kind "andu" | "huima" | "bianshu",
# recv, z0, zl (where it lands), t, T (flight time), dir, off, hidden, fooled}
var trick := {}
# spells on a side, in points left: spoon = that side's racket is a spoon,
# narrow = that side's half of the table is narrowed
var hexes := {"spoon": {PLAYER: 0, AI: 0}, "narrow": {PLAYER: 0, AI: 0}, "giant": {PLAYER: 0, AI: 0},
		"gravity": {PLAYER: 0, AI: 0}, "view": {PLAYER: 0, AI: 0}}
var view_cam := 0                  # 视角转移 on you: the view you're stuck with meanwhile
var serve_hints := 3               # serves left that still show which keys serve what
var narrow_strips := {}            # side -> [left, right, left edge line, right edge line]
var narrow_w := {PLAYER: 0.0, AI: 0.0}   # drawn width of the red strips, easing to the target
var cam_shake := 0.0
var wall_armed := {PLAYER: false, AI: false}   # 铜墙铁壁 waiting for the other side's stroke
var wall_from := 0                 # side whose ball the raised net is waiting for; 0 = down
var net_up := 0.0                  # 0 down .. 1 fully raised (animated; the physics follows it)
var wall_tween: Tween
var wall_nodes: Array = []         # the net extension: body, top tape, two posts
var spoon_tags := {}               # side -> the 勺 floating over a spooned racket
var var_mark: MeshInstance3D       # VAR: ring over the contested spot
var var_dot: MeshInstance3D
var var_text: Label3D
var decoy_mesh: MeshInstance3D
var decoy_shadow: MeshInstance3D
var decoy_marker: MeshInstance3D
var decoy_tag: Label3D
var skill_wheel: Control
var tour = null                    # the clubs and players (Tour) of quick ties and the training ground

# training drills (训练): a feeder sends balls, you return them, nobody plays the point out
const DRILLS := {
	"multi": {"name": "多球调动", "balls": 20, "attr": "foot", "max": 2,
			"desc": "正反手两个大角来回喂快球，越喂越快。回上台 1 分，回到底线 2 分。练步法"},
	"target": {"name": "定点打靶", "balls": 15, "attr": "", "max": 3,
			"desc": "对面台上亮一个靶子，打进靶 3 分，上台 1 分。练正手或反手（看你多用哪边）"},
	"receive": {"name": "接发球", "balls": 15, "attr": "receive", "max": 2,
			"desc": "教练发各种上下旋、侧旋球，接上台 2 分。看清来球的旋转提示。练接发"},
	"tutorial": {"name": "新手教学", "balls": 999, "attr": "", "max": 1, "desc": ""},
}
# the tutorial's stages: what is fed (top / side spin in rad/s; "serve" = you
# serve), how many good ones move you on, and the two lines of instruction
const TUTORIAL := [
	{"title": "接上旋", "top": 220.0, "side": 0.0, "need": 3,
			"text": "对面喂上旋（橙色），鼠标移动站位\n按住 W 拉回去，或者不按直接挡"},
	{"title": "接下旋", "top": -260.0, "side": 0.0, "need": 3,
			"text": "下旋（蓝色）会往下沉\n按 S 搓回去（搓自己会吃转，轻按就行），或按住 W 拉起来"},
	{"title": "抵消侧旋", "top": 120.0, "side": 200.0, "need": 3,
			"text": "侧旋会拐弯，回球也会偏\n左侧旋用右列 E / D，右侧旋用左列 Q / A"},
	{"title": "发力和重球", "top": 430.0, "side": 0.0, "need": 2,
			"text": "按住击球键，球拍左边的弧线会变长\n长到绿色区段（会响一声）就松手：白=不够 红=过头"},
	{"title": "发球", "serve": true, "need": 3,
			"text": "按住 W（上旋）或 S（下旋）看力度条\n指针落在亮区时松手，把球发到对面"},
	{"title": "SHIFT 技能", "top": 220.0, "side": 0.0, "need": 2, "skills": true,
			"text": "按住 Shift 打开技能轮盘，指向「乾坤挪移」后松开\n再把球回过去：它会在半空瞬移换线"},
]
const TUTORIAL_LOADOUT := ["blink", "flip", "huima", "jinchan"]   # the skill lesson's four
var tut_level_backup := -1         # your difficulty level, restored when the tutorial ends

var drill := {}                    # the drill running: {kind, player, n, score, fh, bh, resolved, next_t, target}
var drill_mark: MeshInstance3D     # the target circle
var drill_auto := ""               # debug: run this drill hands-off and quit
var drill_result := {}             # last finished drill, for the menu
var gear_debug := ""               # debug: put this rubber on both sides of your first player
const SAVE_PATH := "user://progress.cfg"


## Fusion Pixel 12px (OFL, fonts/CREDITS.md), drawn crisp: no anti-aliasing and
## only whole-number multiples of its 12px design size.
func ui_font() -> Font:
	if _font == null:
		var f: FontFile = load("res://fonts/fusion-pixel-12px-zh_hans.otf.woff2")
		f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		f.hinting = TextServer.HINTING_NONE
		f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
		f.fixed_size = 12
		f.fixed_size_scale_mode = TextServer.FIXED_SIZE_SCALE_INTEGER_ONLY
		_font = f
	return _font


## Right-handed players: balls on your right half of the table go to the forehand.
## Penholders step round further to use the forehand.
func wing_for(side: int, x: float) -> String:
	var bias: float = Tech.GRIPS[grip[side]].fh_bias + (0.22 if has_trait(side, "fh_heavy") else 0.0)
	return "fh" if x * side * hand(side) > -0.04 - bias else "bh"


## Most power (0..1) the player can put into a stroke or serve with the stamina left.
func power_cap(side: int) -> float:
	return lerpf(0.45, 1.0, stamina[side] / 100.0)


## How much the racket's reach grows as the camera rises and pulls back: up there
## the racket and ball look smaller and every step is a longer guess, so it grows
## a little faster than the table shrinks on screen.
func zoom_reach() -> float:
	return 1.0 + (cam_zoom - 1.0) * 1.5


## Your hit radius: the 操作辅助 setting's, widened as the camera pulls back and
## while the match is easing off for you.
func player_reach() -> float:
	return REACH_STD * float(help().reach) * zoom_reach() * (1.0 + (0.2 * maxf(adapt, 0.0) if adapt_on() else 0.0))


## The 操作辅助 level in force (the tutorial always gets the most help).
func help() -> Dictionary:
	if drill.get("kind", "") == "tutorial":
		return HELP_LEVELS[0]
	return HELP_LEVELS[clampi(int(settings.get("help", 1)), 0, HELP_LEVELS.size() - 1)]


## Whether the match quietly eases off when you fall behind: only with that help
## on, only in quick play and stand-alone cups (never against a legend).
func adapt_on() -> bool:
	return bool(help().adapt) and is_human(PLAYER) and drill.is_empty() and boss_id == "" \
			and (prof[AI].is_empty() or cup_run != null)


## Footage mode: a frame-stamped line for picking clips (skills, points).
func mv_log(what: String) -> void:
	if clean:
		print("[mv] %d %s" % [Engine.get_process_frames(), what])


## A VAR replay has finished (layer 3 settles the challenge).
func on_var_done() -> void:
	pass


## A passing message on the banner (skill names, setting changes): it clears
## itself after `secs` unless something else has been written there since.
func flash(text: String, secs := 1.6) -> void:
	banner_label.text = text
	get_tree().create_timer(secs, true, false, true).timeout.connect(func():   # real seconds, slow motion or not
		if banner_label.text == text:
			banner_label.text = "")


func lv() -> Dictionary:
	return LEVELS[level_idx]


## Level index for a side: when watching, your side's AI has its own level.
func level_of(side: int) -> int:
	return watch_level if side == PLAYER and autoplay else level_idx


func lv_of(side: int) -> Dictionary:
	var d: Dictionary = prof[side] if not prof[side].is_empty() else LEVELS[level_of(side)]
	if side == AI and adapt != 0.0 and adapt_on():
		return eased(d)
	return d


## The AI's parameters with the match easing off by `adapt` (negative: tightening
## up when you're running away with it): sprays more, moves and reads slower,
## plays fewer tactics, a bit less pace and spin.
func eased(src: Dictionary) -> Dictionary:
	if not adapt_cache.is_empty() and is_same(adapt_cache.src, src) and absf(float(adapt_cache.a) - adapt) < 0.02:
		return adapt_cache.d
	var a := adapt
	var d := src.duplicate()
	for k in ["precision", "prec_fh", "prec_bh"]:
		if d.has(k):
			d[k] = float(d[k]) * (1.0 + 0.5 * a)
	d.ai_err = clampf(float(d.ai_err) * (1.0 + 0.6 * a), 0.0, 0.9)
	d.ai_speed = float(d.ai_speed) * (1.0 - 0.2 * a)
	d.ai_reach = float(d.ai_reach) * (1.0 - 0.15 * a)
	d.ai_read = clampf(float(d.ai_read) * (1.0 - 0.2 * a), 0.0, 1.0)
	d.tactic = float(d.tactic) * (1.0 - 0.6 * maxf(a, 0.0))
	d.speed = float(d.speed) * (1.0 - 0.15 * maxf(a, 0.0))
	d.spin = float(d.spin) * (1.0 - 0.25 * maxf(a, 0.0))
	adapt_cache = {"src": src, "a": a, "d": d}
	return d


## The blade and rubbers a side plays with (Gear.resolve); quick play uses a
## standard looper's set-up.
func gear(side: int) -> Dictionary:
	var g = lv_of(side).get("gear")
	return g if g != null else Gear.resolve({"style": "loop", "grip": grip[side]})


## Boss signature traits (Roster.BOSSES).
func has_trait(side: int, t: String) -> bool:
	return t in lv_of(side).get("traits", [])


## 1 right-handed, -1 left-handed: mirrors which side the forehand is on.
func hand(side: int) -> float:
	return float(lv_of(side).get("hand", 1))


## Nerves: on tight points late in a game (more so in the deciding game) a
## player's errors grow, less for a strong mental rating.
func pressure(side: int) -> float:
	if prof[side].is_empty():
		return 1.0
	var a: int = score[PLAYER]
	var b: int = score[AI]
	if maxi(a, b) < 9 or absi(a - b) > 2:
		return 1.0
	if has_trait(side, "clutch"):
		return 0.75    # big points make him sharper
	var k: float = 0.6 * (1.0 - float(prof[side].nerve)) * (1.8 if has_trait(side, "choke") else 1.0)
	if best_of > 1 and games[PLAYER] == best_of / 2 and games[AI] == best_of / 2:
		k *= 1.5
	return 1.0 + k


## How much incoming spin there is to cancel, 0..1 of a full-strength hold.
func spin_need(w: Vector3, v: Vector3) -> float:
	return clampf(Vector2(w.dot(Sim.topspin_axis(v)), w.y).length() / SPIN_REF, 0.08, 1.0)


func is_human(side: int) -> bool:
	return side == PLAYER and not autoplay


## Currently held stroke: x = row (1 topspin, -1 backspin, 0 none), y = side (+1 left, -1 right).
func held_stroke() -> Vector2i:
	var row := 0
	var sd := 0
	for k in STROKE_KEYS:
		if Input.is_key_pressed(k):
			row = STROKE_KEYS[k][0]
			sd += STROKE_KEYS[k][1]
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		row = 1
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		row = -1
	return Vector2i(row, clampi(sd, -1, 1))


## One fixed scoreboard spot per view: after a view change, once the camera has
## glided into place, the board is set down once on the floor under the
## lower-left of the screen, facing the camera, and then stays put while that
## view's camera follows the ball or zooms.
var board_mode := -1
var board_settle := 0.0


# ---------------------------------------------------------------- hooks for upper layers

## Your hold strength (0..1): eases in, so the start of the hold is finer.
func hold_power() -> float:
	return pow(clampf(windup_hold / WINDUP_FULL, 0.0, 1.0), 1.3)


## How far from the right strength still counts as cancelling the spin (half
## width of the green band): judged against at least 35% strength, so a
## lightly spinning ball forgives a firm hit.
static func power_slack(need: float) -> float:
	return 0.3 * maxf(need, 0.35)


## A side's loadout as skill slots (id, name, desc, cost), in loadout order.
func loaded(side: int) -> Array:
	var out := []
	for id in loadout[side]:
		for s in SKILL_SLOTS:
			if s.id == id:
				out.append(s)
	return out


## 技能乒乓球 is switched on and this is a real match (not a drill or the tutorial).
func skill_on() -> bool:
	if drill.get("kind", "") == "tutorial":
		return bool(drill.get("skills", false))   # the tutorial's skill lesson
	return (skill_test or run_match or bool(settings.get("skill_mode", false))) and drill.is_empty()


## Drill mode (game_modes): your return bounced on the far half.
func drill_landed() -> void:
	pass


## Drill mode (game_modes): the ball went wrong; `feed_fault` = the feeder missed.
func drill_missed(_feed_fault: bool) -> void:
	pass
