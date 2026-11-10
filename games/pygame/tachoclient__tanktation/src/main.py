import pygame, random, sys, math, os
from array import array
from pygame.locals import *
# Initialize Pygame

pygame.init()
# Set up the display
 
frame_x = 1280
frame_y = 720
game_window = pygame.display.set_mode((frame_x, frame_y))
pygame.display.set_caption('Tanktation')
clock = pygame.time.Clock()
fps = 60

# Colors
white = (255, 255, 255)
red = (255, 0, 0)
black = (0, 0, 0)
green = (0, 255, 0)
ltgr = (144, 238, 144)
yellow = (255, 255, 0)
blue = (0, 0, 255)
ltbl = (173, 216, 230)

# Biomes
PLAINS = {
    "bg": (0, 150, 0),
    "rock": (120, 120, 120),
    "crate_base": (170, 130, 60),
    "crate_mid": (190, 150, 70),
    "crate_top": (210, 170, 80),
    "marker": (255, 220, 120),
    "params": {
        "speed": 1.0,
        "damage": 1.0,
        "spread": 1.0,
        "heat_cool": 1.0,
        "heat_max": 1.0,
        "fuel": 1.0,
    },
}
DESERT = {
    "bg": (194, 162, 96),
    "rock": (164, 128, 72),
    "crate_base": (176, 124, 56),
    "crate_mid": (196, 140, 68),
    "crate_top": (214, 156, 78),
    "marker": (255, 236, 140),
    "params": {
        "speed": 0.95,
        "damage": 1.05,
        "spread": 1.15,
        "heat_cool": 0.9,
        "heat_max": 0.9,
        "fuel": 1.15,
    },
}
SNOW = {
    "bg": (210, 224, 232),
    "rock": (160, 176, 186),
    "crate_base": (170, 170, 170),
    "crate_mid": (190, 190, 190),
    "crate_top": (210, 210, 210),
    "marker": (120, 160, 200),
    "params": {
        "speed": 0.92,
        "damage": 1.0,
        "spread": 1.05,
        "heat_cool": 1.1,
        "heat_max": 1.05,
        "fuel": 1.05,
    },
}
CITY = {
    "bg": (60, 60, 70),
    "rock": (90, 90, 100),
    "crate_base": (120, 110, 90),
    "crate_mid": (140, 130, 110),
    "crate_top": (160, 150, 130),
    "marker": (200, 180, 120),
    "params": {
        "speed": 1.05,
        "damage": 1.0,
        "spread": 0.95,
        "heat_cool": 1.0,
        "heat_max": 1.0,
        "fuel": 1.0,
    },
}
VOLCANIC = {
    "bg": (80, 40, 30),
    "rock": (110, 70, 50),
    "crate_base": (150, 90, 60),
    "crate_mid": (170, 110, 70),
    "crate_top": (190, 130, 80),
    "marker": (255, 160, 80),
    "params": {
        "speed": 0.98,
        "damage": 1.1,
        "spread": 1.1,
        "heat_cool": 0.85,
        "heat_max": 0.9,
        "fuel": 1.2,
    },
}
tan = (214, 193, 138)
dk_tan = (170, 150, 100)
sand = (232, 214, 170)
rock_gray = (120, 120, 120)

# Infantry roles
INF_ROLE_STATS = {
    "mg": {"hp": 18, "spd": 80, "rng": 220, "cd": 260, "dmg": 2.0, "spd_b": 420},
    "smg": {"hp": 14, "spd": 95, "rng": 160, "cd": 160, "dmg": 1.5, "spd_b": 480},
    "at": {"hp": 20, "spd": 70, "rng": 300, "cd": 1800, "dmg": 42.0, "spd_b": 260},
    "sniper": {"hp": 12, "spd": 75, "rng": 360, "cd": 900, "dmg": 14.0, "spd_b": 600},
    "rifleman": {"hp": 16, "spd": 86, "rng": 250, "cd": 540, "dmg": 4.0, "spd_b": 560},
    "engineer": {"hp": 16, "spd": 74, "rng": 0, "cd": 900, "dmg": 0.0, "spd_b": 0},
    "medic": {"hp": 14, "spd": 82, "rng": 230, "cd": 620, "dmg": 3.0, "spd_b": 540},
}
INF_LABELS = {"mg": "MG", "smg": "SMG", "at": "AT", "sniper": "SN", "rifleman": "RFL", "engineer": "ENG", "medic": "MED"}

WEATHER_EFFECTS = {
    "clear": {"speed": 1.0, "accel": 1.0, "turn": 1.0, "spread": 1.0, "damage": 1.0, "reload": 1.0, "fuel": 1.0, "heat_cool": 1.0, "wind": 0.0},
    "rain":  {"speed": 0.95, "accel": 0.9, "turn": 0.92, "spread": 1.15, "damage": 0.95, "reload": 1.1, "fuel": 1.05, "heat_cool": 0.9, "wind": 0.22},
    "snow":  {"speed": 0.90, "accel": 0.85, "turn": 0.90, "spread": 1.10, "damage": 0.95, "reload": 1.1, "fuel": 1.1, "heat_cool": 0.95, "wind": 0.18},
    "sand":  {"speed": 0.92, "accel": 0.88, "turn": 0.90, "spread": 1.20, "damage": 0.90, "reload": 1.15, "fuel": 1.12, "heat_cool": 0.85, "wind": 0.28},
    "ash":   {"speed": 0.90, "accel": 0.85, "turn": 0.88, "spread": 1.25, "damage": 0.85, "reload": 1.2, "fuel": 1.15, "heat_cool": 0.8, "wind": 0.24},
}

# Variables
max_hp = 300
bullet_limit = 20
bullet_damage = 35
bull_spd = 500.0   # pixels per second
bull_rld = 2000  # milliseconds
day_cycle_ms = 240000
day_start_hour = 6
night_dark_alpha = 190
default_music_vol = 1.0
default_sfx_vol = 0.8
engine_smoke_life = 1800
track_mark_life = 6000
casing_life = 1500
shield_cooldown_ms = 15000
shield_duration_ms = 4000
shield_strength = 0.35
em_pulse_cooldown = 18000
em_pulse_duration = 3500
weather_cycle_ms = 90000
wind_base_speed = 45.0
light_cache_ms = 45
max_weather_particles = 450
light_cache_surface = None
light_cache_time = 0
light_cache_alpha = None
ai_think_ms = 180
ai_offscreen_margin = 120
ai_despawn_ms = 26000
ai_despawn_dist = 520
ai_fps_floor = 45.0
ai_max_infantry_team = 18
ai_crowd_threshold = 16
ai_crowd_step = 8
spawn_budget_infantry = 4
spawn_budget_vehicles = 1
kill_feed_life_ms = 5200
kill_feed_max = 8
QUALITY_PRESETS = ["BALANCED", "PERFORMANCE", "CINEMATIC"]
current_quality_mode = "PERFORMANCE"
GAME_MODE_CURRENT = "FFA"
KOTH_CENTER = (frame_x // 2, frame_y // 2)
KOTH_RADIUS = 130
SIEGE_GREEN_BASE = (140, frame_y // 2)
SIEGE_BLUE_BASE = (frame_x - 140, frame_y // 2)
ROUND_MODE_BAG = []
barracks_hp_max = 900
barracks_w = 250
barracks_h = 150
auto_low_enter_fps = 28.0
auto_low_exit_fps = 40.0
auto_low_hold_ms = 3000
auto_low_trigger_ms = 900
mg_damage = 0.5
infantry_mg_scale = 8.0
mg_spd = 700.0
mg_rld = 80  # milliseconds
mg_spread = 1.0  # degrees
mg_tracer_len = 18
mg_tracer_color = (255, 240, 120)
mg_heat_per_shot = 0.1
mg_heat_cool = 0.8     # heat units per second
mg_heat_max = 1.5
mg_heat_spread = 8.0  # extra degrees at max heat
crit_hit_chance = 0.18
crit_engine_bias = 0.58
armor_front_mult = {"AP": 0.75, "HE": 0.9, "ATGM": 1.0}
armor_side_mult = {"AP": 0.9, "HE": 0.95, "ATGM": 1.0}
armor_rear_mult = {"AP": 1.2, "HE": 1.1, "ATGM": 1.0}
ricochet_chance = {"AP": 0.28, "HE": 0.08, "ATGM": 0.0}
overheat_reset = 0.6   # heat level to re-enable firing
cannon_ap_max = 16
cannon_he_max = 10
cannon_atgm_max = 4
mg_ammo_max = 500
fuel_max = 500.0
fuel_burn = 6.0  # units per second at full speed
shake_duration = 0.18
shake_mag = 4
hit_pause_ms = 25
recoil_kick = 6.0
recoil_return = 18.0  # pixels per second
mg_heat_color = (255, 80, 80)
turn_spd = 180.0   # degrees per second
accel = 600.0      # pixels per second^2
decel = 500.0      # pixels per second^2
max_fwd = 220.0    # pixels per second
max_rev = 140.0    # pixels per second
turn_accel = 720.0   # degrees per second^2
turn_decel = 600.0   # degrees per second^2
max_turn = 180.0     # degrees per second
airdrop_interval_min = 8.0
airdrop_interval_max = 14.0
airdrop_size = 12
airdrop_wave_size = 3
airdrop_despawn_ms = 12000
speed_upg_step = 0.12
damage_upg_step = 0.18
spread_upg_step = 0.15
upg_cap = 2.0
smoke_cd_ms = 6000
smoke_duration_ms = 8000
smoke_radius = 140
smoke_ammo_max = 3
armor_buff_ms = 8000
rapid_buff_ms = 8000
mine_spawn_min = 9.0
mine_spawn_max = 15.0
mine_despawn_ms = 20000
mine_damage = 28
mine_radius = 18
mine_sign_radius = 42
melee_range = 13
knife_damage = 5.0
bayonet_damage = 8.0
melee_cd_ms = 700
repair_vehicle_range = 32
repair_vehicle_amount = 8.0
medic_range = 34
medic_heal_amount = 5.0
support_cd_ms = 900
ditch_fill_ms = 4200
ditch_trap_speed = 35.0
intercept_round_chance = {"AP": 0.08, "HE": 0.18, "ATGM": 0.75, "mg": 0.55, "drone": 0.65}
smoke_puff_count = 14
smoke_puff_spread = 22
smoke_fade_in = 700
smoke_miss_chance = 0.65
smoke_aim_jitter = 8.0
repair_cd_ms = 12000
repair_amount = 20
repair_ammo_max = 2
repair_ring_ms = 400
infantry_spawn_min = 2
infantry_spawn_max = 4
infantry_bullet_limit = 60
mortar_flight_ms = 900
mortar_min_r = 2
mortar_max_r = 8
mortar_blast_r = 55
infantry_wave_min = 10.0
infantry_wave_max = 16.0
tank_lives_max = 3
TEAM_CLASS_OPTIONS = ["MBT", "TD"]
spawn_protect_ms = 10000
kill_cd_ms = 1200
spawn_ring_r = 26
apc_hp = 140
apc_speed = 60.0
apc_range = 260.0
apc_fire_cd = 220
apc_fire_dmg = 1.2
apc_fire_spd = 520.0
apc_deploy_cd = 6000
apc_deploy_count = 2
apc_avoid_dist = 22
jeep_hp = 80
jeep_speed = 90.0
jeep_range = 220.0
jeep_fire_cd = 180
jeep_fire_dmg = 0.9
jeep_fire_spd = 560.0
jeep_w = 30
jeep_h = 18
humvee_hp = 110
humvee_speed = 75.0
humvee_range = 240.0
humvee_fire_cd = 200
humvee_fire_dmg = 1.0
humvee_fire_spd = 540.0
humvee_w = 36
humvee_h = 22
infantry_tank_dmg_scale = 0.4
infantry_manned_scale = 0.6
apc_w = 42
apc_h = 28
ram_dmg_scale = 0.10
ram_speed_thresh = 60.0
obstacle_ram_scale = 0.5
apc_at_cd = 2600
apc_at_dmg = 220.0  # increased to make APC ATGMs impactful against armor
apc_at_spd = 300.0
apc_at_ammo_max = 4
max_ai_vehicles = 5
supply_drone_cd = 18000
attack_drone_cd = 22000
supply_drone_spd = 150.0
attack_drone_spd = 210.0
drone_avoid_dist = 30
supply_drone_arm_ms = 1100
supply_drone_collect_ms = 700
attack_drone_arm_ms = 1200
attack_drone_dive_ms = 700
attack_drone_damage = 32.0
atgm_visual_scale = 1.8
td_turret_forward_offset = 10.0
# Ballistic model (2.5D): x/y are horizontal plane, z is shell height above ground.
# We ignore vertical drag and use standard z(t)=z0+vz*t-0.5*g*t^2 dynamics.
shell_gravity = 180.0
shell_vz_default = 42.0
mg_ballistic_gravity = 28.0

CANNON_TYPES = {
    "AP": {"dmg": 1.2, "spd": 520.0, "blast": 0.45, "homing": False, "turn": 0.0, "hp": 4, "cd": 1.0, "wind": 0.35},
    "HE": {"dmg": 0.95, "spd": 440.0, "blast": 0.95, "homing": False, "turn": 0.0, "hp": 2, "cd": 1.15, "wind": 0.45},
    "ATGM": {"dmg": 2.4, "spd": 300.0, "blast": 0.8, "homing": True, "turn": 140.0, "hp": 2, "cd": 2.6, "wind": 0.12},
}

BOSS_HP_MULT = 10.0
BOSS_ONSLAUGHT_HP_MULT = 12.5
BOSS_DAMAGE = max_hp * 0.5

CLASS_CANNON_PROFILE = {
    "MBT": {"reload_mul": 1.0, "damage_mul": 1.0, "ap_label": "APFSDS", "ap_short": "SABOT"},
    "TD": {"reload_mul": 1.35, "damage_mul": 1.45, "ap_label": "HVAP", "ap_short": "HVAP"},
}

BOSS_MODIFIERS = [
    {
        "name": "Onslaught",
        "description": "2.5x more reinforcements, boss has 12.5x HP and MBT reload speed.",
        "reinforcement_mul": 2.5,
        "boss_hp_mult": BOSS_ONSLAUGHT_HP_MULT,
        "boss_reload_mul": 1.0,
        "airdrop_mul": 1.0,
    },
    {
        "name": "One Life",
        "description": "Players have only one tank life each.",
        "player_lives": 1,
    },
    {
        "name": "Supply Surplus",
        "description": "Airdrop wave size is doubled.",
        "airdrop_mul": 2.0,
    },
    {
        "name": "Enraged",
        "description": "Boss shells hit harder.",
        "boss_dmg_mult": 1.25,
    },
]

# Sprites
def procedural_sprite(kind, max_dim):
    """Tiny asset-free sprites so the game still runs when tank PNGs are absent."""
    surf = pygame.Surface((max(8, max_dim), max(8, max_dim)), pygame.SRCALPHA)
    cx = max_dim // 2
    cy = max_dim // 2
    def poly(points, color, width=0):
        pygame.draw.polygon(surf, color, [(cx + x, cy + y) for x, y in points], width)
    if 'chassis' in kind:
        team = (40, 180, 75) if 'gr_' in kind else (35, 150, 230) if 'bl_' in kind else (190, 60, 50)
        poly([(-28,-18),(24,-18),(32,-10),(32,12),(24,18),(-28,18),(-34,10),(-34,-10)], (22,22,22))
        poly([(-24,-15),(22,-15),(28,-8),(28,10),(21,15),(-24,15),(-29,8),(-29,-8)], team)
        pygame.draw.rect(surf, (60,60,60), (cx-25, cy-23, 50, 6))
        pygame.draw.rect(surf, (60,60,60), (cx-25, cy+17, 50, 6))
        pygame.draw.rect(surf, tuple(max(0, c-50) for c in team), (cx-13, cy-9, 26, 18))
    elif 'td_turret' in kind:
        team = (45, 210, 80) if 'gr_' in kind else (120, 175, 230) if 'bl_' in kind else (220, 80, 65)
        poly([(-18,-12),(10,-16),(30,-6),(28,8),(7,15),(-18,10),(-24,0)], (25,25,25))
        poly([(-16,-10),(9,-14),(27,-5),(25,7),(6,12),(-16,8),(-21,0)], team)
        pygame.draw.rect(surf, (30,30,30), (cx+18, cy-3, 42, 6))
        pygame.draw.rect(surf, (215,205,160), (cx+14, cy-4, 10, 8))
    elif 'turret' in kind:
        team = (40, 190, 75) if 'gr_' in kind else (120, 175, 230) if 'bl_' in kind else (220, 80, 65)
        poly([(-16,-10),(12,-12),(22,-3),(20,8),(-10,12),(-18,3)], (25,25,25))
        poly([(-14,-8),(10,-10),(19,-2),(17,6),(-9,9),(-15,2)], team)
        pygame.draw.rect(surf, (30,30,30), (cx+15, cy-2, 34, 4))
    elif 'atgm' in kind:
        pygame.draw.polygon(surf, (230,230,230), [(cx+18,cy),(cx-10,cy-6),(cx-16,cy),(cx-10,cy+6)])
        pygame.draw.rect(surf, (210,55,45), (cx-6, cy-4, 12, 8))
        pygame.draw.polygon(surf, (255,210,60), [(cx-16,cy),(cx-25,cy-4),(cx-25,cy+4)])
    elif 'he' in kind:
        pygame.draw.polygon(surf, (255,220,80), [(cx+15,cy),(cx-12,cy-6),(cx-18,cy),(cx-12,cy+6)])
        pygame.draw.rect(surf, (70,180,90), (cx-10, cy-5, 18, 10))
    elif 'ap' in kind or 'bullet' in kind:
        pygame.draw.polygon(surf, (235,235,210), [(cx+18,cy),(cx-15,cy-4),(cx-18,cy),(cx-15,cy+4)])
        pygame.draw.rect(surf, (255,210,60), (cx-12, cy-3, 16, 6))
    elif 'muzzle' in kind:
        for r, col in [(24,(255,210,40,120)), (14,(255,245,150,180)), (7,(255,255,255,230))]:
            pygame.draw.circle(surf, col, (cx, cy), r)
        for a in range(0, 360, 45):
            pygame.draw.line(surf, (255,220,50,210), (cx,cy), (cx+int(math.cos(math.radians(a))*32), cy+int(math.sin(math.radians(a))*32)), 3)
    else:
        pygame.draw.rect(surf, (220,220,220), (cx-8, cy-2, 16, 4))
    return surf

def load_sprite(path, max_dim, *, force_colorkey=False, colorkey_rgb=None):
    if not os.path.exists(path):
        return procedural_sprite(os.path.basename(path).lower(), max_dim)
    image = pygame.image.load(path)
    if image.get_alpha() is not None:
        image = image.convert_alpha()
    else:
        image = image.convert()
        if force_colorkey:
            key = colorkey_rgb if colorkey_rgb is not None else image.get_at((0, 0))
            image.set_colorkey(key)
    w, h = image.get_size()
    if max(w, h) > max_dim:
        scale = max_dim / float(max(w, h))
        image = pygame.transform.smoothscale(image, (int(w * scale), int(h * scale)))
    return image

def load_sprite_optional(path, max_dim, fallback=None, *, force_colorkey=False, colorkey_rgb=None):
    try:
        if os.path.exists(path):
            return load_sprite(path, max_dim, force_colorkey=force_colorkey, colorkey_rgb=colorkey_rgb)
    except Exception:
        pass
    return fallback

TANK_MAX_DIM = 110
TURRET_MAX_DIM = 240
TD_TURRET_MAX_DIM = 200
BULLET_MAX_DIM = 50
MUZZLE_MAX_DIM = 80
EXPLOSION_MAX_DIM = 140
TANK_HITBOX_SCALE = 0.62
TURRET_HITBOX_SCALE = 0.6
OBSTACLE_HITBOX_INSET = 8

def safe_shrink_rect(rect, inset):
    """Return a rect shrunk by inset but never inverted. Keeps at least 4px in width/height."""
    if rect is None:
        return rect
    iw = max(0, min(inset, max(0, rect.width - 4)))
    ih = max(0, min(inset, max(0, rect.height - 4)))
    try:
        return rect.inflate(-iw, -ih)
    except Exception:
        return rect
GR_CHASSIS_SCALE = 0.85
BL_CHASSIS_SCALE = 0.75
GR_TURRET_SCALE = 0.80
BL_TURRET_SCALE = 0.70

white_key = (255, 255, 255)
bl_ch = load_sprite('assets/sprites/tanks/bl_chassis.png', TANK_MAX_DIM, force_colorkey=True, colorkey_rgb=white_key)
gr_ch = load_sprite('assets/sprites/tanks/gr_chassis.png', TANK_MAX_DIM, force_colorkey=True, colorkey_rgb=white_key)
bl_tr = load_sprite('assets/sprites/tanks/bl_turret.png', TURRET_MAX_DIM, force_colorkey=True, colorkey_rgb=white_key)
gr_tr = load_sprite('assets/sprites/tanks/gr_turret.png', TURRET_MAX_DIM, force_colorkey=True, colorkey_rgb=white_key)
bl_td_tr = load_sprite_optional('assets/sprites/tanks/bl_td_turret.png', TD_TURRET_MAX_DIM, fallback=bl_tr, force_colorkey=True, colorkey_rgb=white_key)
gr_td_tr = load_sprite_optional('assets/sprites/tanks/gr_td_turret.png', TD_TURRET_MAX_DIM, fallback=gr_tr, force_colorkey=True, colorkey_rgb=white_key)

# Manual scale to normalize visuals between teams
bl_ch = pygame.transform.smoothscale(
    bl_ch, (int(bl_ch.get_width() * BL_CHASSIS_SCALE), int(bl_ch.get_height() * BL_CHASSIS_SCALE))
)
gr_ch = pygame.transform.smoothscale(
    gr_ch, (int(gr_ch.get_width() * GR_CHASSIS_SCALE), int(gr_ch.get_height() * GR_CHASSIS_SCALE))
)
bl_tr = pygame.transform.smoothscale(
    bl_tr, (int(bl_tr.get_width() * BL_TURRET_SCALE), int(bl_tr.get_height() * BL_TURRET_SCALE))
)
gr_tr = pygame.transform.smoothscale(
    gr_tr, (int(gr_tr.get_width() * GR_TURRET_SCALE), int(gr_tr.get_height() * GR_TURRET_SCALE))
)

boss_ch = pygame.transform.smoothscale(gr_ch, (int(gr_ch.get_width() * 1.35), int(gr_ch.get_height() * 1.35)))
boss_tr = pygame.transform.smoothscale(gr_td_tr, (int(gr_td_tr.get_width() * 1.20), int(gr_td_tr.get_height() * 1.20)))
bl_td_tr = pygame.transform.smoothscale(
    bl_td_tr, (int(bl_td_tr.get_width() * BL_TURRET_SCALE), int(bl_td_tr.get_height() * BL_TURRET_SCALE))
)
gr_td_tr = pygame.transform.smoothscale(
    gr_td_tr, (int(gr_td_tr.get_width() * GR_TURRET_SCALE), int(gr_td_tr.get_height() * GR_TURRET_SCALE))
)
bull = load_sprite_optional('assets/sprites/tanks/bullet.png', BULLET_MAX_DIM, fallback=None, force_colorkey=True, colorkey_rgb=white_key)
apfsds_round = load_sprite_optional('assets/sprites/tanks/apfsds.png', BULLET_MAX_DIM, fallback=bull, force_colorkey=True, colorkey_rgb=white_key)
ap_round = load_sprite_optional('assets/sprites/tanks/ap.png', BULLET_MAX_DIM, fallback=apfsds_round if apfsds_round is not None else bull, force_colorkey=True, colorkey_rgb=white_key)
he_round = load_sprite_optional('assets/sprites/tanks/he.png', BULLET_MAX_DIM, fallback=ap_round if ap_round is not None else bull, force_colorkey=True, colorkey_rgb=white_key)
if bull is None:
    bull = ap_round if ap_round is not None else apfsds_round
if bull is None:
    bull = pygame.Surface((12, 4), pygame.SRCALPHA)
    pygame.draw.rect(bull, (220, 220, 220), (0, 0, 12, 4))
atgm_round = load_sprite_optional('assets/sprites/tanks/atgm.png', BULLET_MAX_DIM, fallback=None, force_colorkey=True, colorkey_rgb=white_key)
muzzle = load_sprite('assets/sprites/tanks/muzzle_flash.png', MUZZLE_MAX_DIM, force_colorkey=True, colorkey_rgb=white_key)
explosion = load_sprite('assets/sprites/tanks/muzzle_flash.png', EXPLOSION_MAX_DIM, force_colorkey=True, colorkey_rgb=white_key)
pygame.mixer.set_num_channels(999999)

# Fonts
ocr = pygame.font.SysFont('OCR A Extended', 28)
ocr_big = pygame.font.SysFont('OCR A Extended', 64)
ipa = pygame.font.SysFont('Impact', 30)
title_font = pygame.font.SysFont('Impact', 64)
sub_font = pygame.font.SysFont('OCR A Extended', 22)
hud_font = pygame.font.SysFont('OCR A Extended', 20)

mg_sound = None
explosion_sound = None
cannon_sound = None
hit_sound = None
try:
    if os.path.exists('assets/audio/music.mp3'):
        pygame.mixer.music.load('assets/audio/music.mp3') # credit to kevin macleod
        pygame.mixer.music.set_volume(default_music_vol)
        pygame.mixer.music.play(-1)  # -1 means loop forever
except Exception:
    pass

# Sounds
def make_tone(freq, duration, volume=0.5):
    sample_rate = 44100
    n_samples = int(sample_rate * duration)
    buf = array('h')
    amp = int(32767 * volume)
    for i in range(n_samples):
        t = i / sample_rate
        val = int(amp * math.sin(2 * math.pi * freq * t))
        buf.append(val)
    return pygame.mixer.Sound(buffer=buf)

try:
    if pygame.mixer.get_init() is None:
        pygame.mixer.init()
    mixer_info = pygame.mixer.get_init()
    audio_dir = os.path.join("ASSETS", "audio")
    cannon_path = os.path.join(audio_dir, "cannon.mp3")
    mg_path = os.path.join(audio_dir, "mg.mp3")
    hit_path = os.path.join(audio_dir, "explosion.mp3")
    if os.path.exists(cannon_path) and os.path.exists(mg_path) and os.path.exists(hit_path):
        cannon_sound = pygame.mixer.Sound(cannon_path)
        mg_sound = pygame.mixer.Sound(mg_path)
        hit_sound = pygame.mixer.Sound(hit_path)
        explosion_sound = hit_sound
        cannon_sound.set_volume(1.0)
        hit_sound.set_volume(0.85)
        mg_sound.set_volume(0.25)
    else:
        cannon_sound = make_tone(90, 0.25, 0.6)
        mg_sound = make_tone(420, 0.05, 0.25)
        hit_sound = make_tone(180, 0.08, 0.4)
        explosion_sound = hit_sound
        cannon_sound.set_volume(1.0)
        hit_sound.set_volume(0.85)
        mg_sound.set_volume(0.25)
except Exception:
    cannon_sound = None
    mg_sound = None
    hit_sound = None
    explosion_sound = None


# Functions
def blit_rotate_center(surf, image, center, angle):
    rotated_image = pygame.transform.rotate(image, angle)
    new_rect = rotated_image.get_rect(center=image.get_rect(center=center).center)
    surf.blit(rotated_image, new_rect.topleft)

def draw_text(surf, font, text, color, pos):
    text_surface = font.render(text, True, color)
    text_rect = text_surface.get_rect(center=pos)
    surf.blit(text_surface, text_rect)

def draw_health_bar(surf, x, y, hp, max_health):
    ratio = hp / max_health
    pygame.draw.rect(surf, red, (x, y, 100, 10))
    pygame.draw.rect(surf, green, (x, y, 100 * ratio, 10))

def draw_heat_bar(surf, x, y, heat, max_heat, now_ms):
    ratio = 0 if max_heat <= 0 else min(1.0, heat / max_heat)
    pygame.draw.rect(surf, (60, 60, 60), (x, y, 80, 6))
    if heat >= max_heat:
        pulse = 0.5 + 0.5 * math.sin(now_ms / 120.0)
        color = (255, int(80 + 120 * pulse), 0)
    else:
        color = (255, 140, 0)
    pygame.draw.rect(surf, color, (x, y, 80 * ratio, 6))

def draw_reload_bar(surf, x, y, reload_left_ratio):
    ratio = max(0.0, min(1.0, reload_left_ratio))
    pygame.draw.rect(surf, (40, 40, 50), (x, y, 80, 6))
    fill_w = int(80 * ratio)
    if fill_w > 0:
        pygame.draw.rect(surf, (120, 200, 255), (x, y, fill_w, 6))

def reload_left_ratio(now_ms, last_shot_ms, reload_ms):
    return max(0.0, min(1.0, (reload_ms - (now_ms - last_shot_ms)) / max(reload_ms, 1)))

def apply_smoke_jitter(angle_deg, target_in_smoke):
    if target_in_smoke:
        return angle_deg + random.uniform(-smoke_aim_jitter, smoke_aim_jitter)
    return angle_deg

def armor_hit_multiplier(bullet, tank_angle):
    if bullet.get('type') != 'cannon':
        return 1.0, False
    ammo = bullet.get('ammo_type', 'AP')
    if ammo == "ATGM":
        return 1.0, False
    incoming = (bullet.get('angle', 0.0) + 180) % 360
    delta = abs((incoming - tank_angle + 540) % 360 - 180)
    if delta <= 40:
        mult = armor_front_mult.get(ammo, 1.0)
        ricochet = random.random() < ricochet_chance.get(ammo, 0.0)
    elif delta >= 140:
        mult = armor_rear_mult.get(ammo, 1.0)
        ricochet = False
    else:
        mult = armor_side_mult.get(ammo, 1.0)
        ricochet = random.random() < (ricochet_chance.get(ammo, 0.0) * 0.4)
    return mult, ricochet

def draw_repair_rings(surf, rings, now_ms, off_x, off_y):
    for ring in rings:
        age = now_ms - ring['t']
        if age <= repair_ring_ms:
            t = age / repair_ring_ms
            r = int(18 + 28 * t)
            alpha = int(200 * (1 - t))
            s = pygame.Surface((r * 2, r * 2), pygame.SRCALPHA)
            pygame.draw.circle(s, (120, 220, 120, alpha), (r, r), r, 2)
            surf.blit(s, (ring['x'] - r + off_x, ring['y'] - r + off_y))

def draw_blowouts(surf, blowouts, now_ms, off_x, off_y):
    for b in blowouts:
        age = now_ms - b['t']
        if age <= 420:
            t = age / 420.0
            lift = -30 * t
            spin = 180 * t
            img = gr_tr if b['team'] == 'green' else bl_tr
            blit_rotate_center(surf, img, (b['x'] + off_x, b['y'] + off_y + lift), b['angle'] + spin)

def draw_spawn_shield(surf, x, y, now_ms, off_x, off_y):
    pulse = 0.5 + 0.5 * math.sin(now_ms / 140.0)
    alpha = int(120 + 80 * pulse)
    r = spawn_ring_r
    s = pygame.Surface((r * 2, r * 2), pygame.SRCALPHA)
    pygame.draw.circle(s, (120, 200, 255, alpha), (r, r), r, 2)
    surf.blit(s, (x - r + off_x, y - r + off_y))

def draw_vehicle_body(surf, x, y, w, h, angle_deg, color, kind):
    pad = 10
    body = pygame.Surface((w + pad * 2, h + pad * 2), pygame.SRCALPHA)
    ox, oy = pad, pad
    dark = (22, 24, 22)
    trim = (min(color[0] + 45, 255), min(color[1] + 45, 255), min(color[2] + 45, 255))
    shadow = (0, 0, 0, 80)
    pygame.draw.ellipse(body, shadow, (ox - 2, oy + h - 3, w + 4, 8))
    pygame.draw.rect(body, color, (ox, oy, w, h), border_radius=3)
    pygame.draw.rect(body, dark, (ox, oy, w, h), 1, border_radius=3)
    if kind == "apc":
        pygame.draw.rect(body, (42, 42, 42), (ox - 2, oy + 3, 5, h - 6), border_radius=2)
        pygame.draw.rect(body, (42, 42, 42), (ox + w - 3, oy + 3, 5, h - 6), border_radius=2)
        for wx in (6, w // 2, w - 7):
            pygame.draw.circle(body, (18, 18, 18), (ox + wx, oy + h - 4), 3)
            pygame.draw.circle(body, (90, 90, 90), (ox + wx, oy + h - 4), 1)
        cabin = (int(ox + w * 0.28), int(oy + 3), int(w * 0.44), int(h * 0.28))
        pygame.draw.rect(body, trim, cabin, border_radius=2)
        pygame.draw.rect(body, dark, cabin, 1, border_radius=2)
        pygame.draw.line(body, (35, 35, 35), (ox + 5, oy + h // 2), (ox + w - 5, oy + h // 2), 1)
        pygame.draw.rect(body, (28, 28, 28), (ox + 5, oy + h - 8, w - 10, 3))
    elif kind == "humvee":
        for wx in (5, w - 6):
            pygame.draw.circle(body, (18, 18, 18), (ox + wx, oy + 4), 3)
            pygame.draw.circle(body, (18, 18, 18), (ox + wx, oy + h - 4), 3)
        cabin = (int(ox + w * 0.34), int(oy + 4), int(w * 0.32), int(h - 8))
        pygame.draw.rect(body, trim, cabin, border_radius=2)
        pygame.draw.line(body, (35, 35, 35), (ox + 5, oy + h // 2), (ox + w - 5, oy + h // 2), 1)
    else:
        for wx in (5, w - 6):
            pygame.draw.circle(body, (18, 18, 18), (ox + wx, oy + 3), 3)
            pygame.draw.circle(body, (18, 18, 18), (ox + wx, oy + h - 3), 3)
        cabin = (int(ox + w * 0.24), int(oy + 4), int(w * 0.38), int(h - 8))
        pygame.draw.rect(body, trim, cabin, border_radius=2)
        pygame.draw.rect(body, (35, 35, 35), (ox + w - 8, oy + 4, 4, h - 8))
    rotated = pygame.transform.rotate(body, angle_deg)
    surf.blit(rotated, rotated.get_rect(center=(int(x), int(y))))

def draw_vehicle_turret(surf, x, y, angle_deg, team, kind):
    ang = math.radians(angle_deg)
    px = -math.sin(ang)
    py = -math.cos(ang)
    base = (35, 38, 35)
    team_col = (95, 240, 95) if team == 'green' else (95, 150, 255)
    if kind == "apc":
        barrel_len = 25
        pygame.draw.line(surf, (8, 8, 8), (int(x), int(y)), (int(x + math.cos(ang) * barrel_len), int(y - math.sin(ang) * barrel_len)), 5)
        pygame.draw.line(surf, (70, 70, 70), (int(x), int(y)), (int(x + math.cos(ang) * barrel_len), int(y - math.sin(ang) * barrel_len)), 3)
        rail_a = (x + px * 7, y + py * 7)
        rail_b = (x + px * 7 + math.cos(ang) * 18, y + py * 7 - math.sin(ang) * 18)
        pygame.draw.line(surf, (120, 90, 40), (int(rail_a[0]), int(rail_a[1])), (int(rail_b[0]), int(rail_b[1])), 4)
        pygame.draw.circle(surf, base, (int(x), int(y)), 7)
        pygame.draw.circle(surf, team_col, (int(x), int(y)), 4)
    elif kind == "humvee":
        barrel_len = 20
        pygame.draw.line(surf, (10, 10, 10), (int(x), int(y)), (int(x + math.cos(ang) * barrel_len), int(y - math.sin(ang) * barrel_len)), 4)
        pygame.draw.line(surf, (80, 80, 80), (int(x), int(y)), (int(x + math.cos(ang) * barrel_len), int(y - math.sin(ang) * barrel_len)), 2)
        pygame.draw.circle(surf, base, (int(x), int(y)), 6)
        pygame.draw.circle(surf, team_col, (int(x), int(y)), 3)
    else:
        barrel_len = 16
        pygame.draw.line(surf, (10, 10, 10), (int(x), int(y)), (int(x + math.cos(ang) * barrel_len), int(y - math.sin(ang) * barrel_len)), 3)
        pygame.draw.circle(surf, base, (int(x), int(y)), 4)
        pygame.draw.circle(surf, team_col, (int(x), int(y)), 2)

def draw_infantry(surf, infantry, off_x, off_y):
    for unit in infantry:
        x = unit['x'] + off_x
        y = unit['y'] + off_y
        base = (80, 220, 80) if unit['team'] == 'green' else (80, 120, 220)
        if unit['role'] == 'at':
            color = (base[0], base[1], 60)
        elif unit['role'] == 'sniper':
            color = (200, 200, 200)
        elif unit['role'] == 'smg':
            color = (base[0], base[1], base[2])
        elif unit['role'] == 'mortar':
            color = base  # fallback, should never appear
        else:
            color = (base[0], base[1], base[2] + 20 if base[2] < 235 else base[2])
        pygame.draw.circle(surf, color, (int(x), int(y)), 5)
        pygame.draw.circle(surf, (20, 20, 20), (int(x), int(y)), 5, 1)
        # Weapon indicator (tiny line) oriented to target
        if unit['role'] in ["mg", "smg"]:
            gun_len = 7
        elif unit['role'] == "sniper":
            gun_len = 9
        elif unit['role'] == "at":
            gun_len = 8
        else:
            gun_len = 6
        ang = math.radians(unit.get('angle', 0))
        back_x = x - math.cos(ang) * 4
        back_y = y + math.sin(ang) * 4
        pygame.draw.rect(surf, (45, 70, 45) if unit['team'] == 'green' else (45, 55, 80),
                         (int(back_x - 3), int(back_y - 3), 6, 6))
        arm_x = -math.sin(ang) * 4
        arm_y = -math.cos(ang) * 4
        pygame.draw.line(surf, (35, 35, 35), (int(x - arm_x), int(y - arm_y)), (int(x + arm_x), int(y + arm_y)), 2)
        gx = x + math.cos(ang) * gun_len
        gy = y - math.sin(ang) * gun_len
        weapon_col = (55, 55, 55) if unit['role'] != 'at' else (105, 95, 55)
        pygame.draw.line(surf, weapon_col, (int(x), int(y)), (int(gx), int(gy)), 2 if unit['role'] != 'at' else 3)
        pygame.draw.circle(surf, (230, 220, 180), (int(x + math.cos(ang) * 2), int(y - math.sin(ang) * 2)), 2)
        # Health bar
        hp_ratio = max(0.0, min(1.0, unit['hp'] / max(1, unit.get('hp_max', unit['hp']))))
        bar_w = 16
        bar_h = 3
        bx = int(x - bar_w // 2)
        by = int(y + 7)
        pygame.draw.rect(surf, (60, 0, 0), (bx, by, bar_w, bar_h))
        pygame.draw.rect(surf, (40, 200, 40), (bx, by, int(bar_w * hp_ratio), bar_h))
        label = INF_LABELS.get(unit['role'], "INF")
        draw_text(surf, sub_font, label, white, (int(x), int(y - 12)))
        # Team dot above label
        dot_color = (90, 240, 90) if unit['team'] == 'green' else (90, 140, 255)
        pygame.draw.circle(surf, dot_color, (int(x), int(y - 22)), 3)

def draw_apcs(surf, apcs, off_x, off_y):
    for apc in apcs:
        x = apc['x'] + off_x
        y = apc['y'] + off_y
        color = (70, 170, 70) if apc['team'] == 'green' else (70, 100, 200)
        draw_vehicle_body(surf, x, y, apc_w, apc_h, apc.get('angle', 0), color, "apc")
        draw_vehicle_turret(surf, x, y - 2, apc.get('turret_angle', apc.get('angle', 0)), apc['team'], "apc")
        # Rear troop ramp and ATGM ammo hint.
        rear_ang = math.radians(apc.get('angle', 0) + 180)
        rx = x + math.cos(rear_ang) * (apc_w * 0.42)
        ry = y - math.sin(rear_ang) * (apc_w * 0.42)
        pygame.draw.line(surf, (25, 25, 25), (int(rx - 5), int(ry)), (int(rx + 5), int(ry)), 2)
        if apc.get('at_ammo', 0) > 0:
            draw_text(surf, hud_font, f"AT:{apc.get('at_ammo', 0)}", (240, 210, 120), (int(x), int(y + apc_h // 2 + 13)))
        # APC health bar
        ratio = max(0.0, min(1.0, apc['hp'] / max(1, apc['hp_max'])))
        pygame.draw.rect(surf, (60, 0, 0), (x - apc_w // 2, y + apc_h // 2 + 2, apc_w, 3))
        pygame.draw.rect(surf, (40, 200, 40), (x - apc_w // 2, y + apc_h // 2 + 2, apc_w * ratio, 3))
        draw_text(surf, hud_font, "APC", white, (int(x), int(y - 14)))

def draw_jeeps(surf, jeeps, off_x, off_y):
    for jeep in jeeps:
        x = jeep['x'] + off_x
        y = jeep['y'] + off_y
        color = (70, 170, 70) if jeep['team'] == 'green' else (70, 100, 200)
        draw_vehicle_body(surf, x, y, jeep_w, jeep_h, jeep.get('angle', 0), color, "jeep")
        draw_vehicle_turret(surf, x + 1, y, jeep.get('turret_angle', jeep.get('angle', 0)), jeep['team'], "jeep")
        pygame.draw.line(surf, (230, 230, 230), (int(x - 5), int(y - 3)), (int(x + 4), int(y - 3)), 1)
        ratio = max(0.0, min(1.0, jeep['hp'] / max(1, jeep['hp_max'])))
        pygame.draw.rect(surf, (60, 0, 0), (x - jeep_w // 2, y + jeep_h // 2 + 2, jeep_w, 3))
        pygame.draw.rect(surf, (40, 200, 40), (x - jeep_w // 2, y + jeep_h // 2 + 2, jeep_w * ratio, 3))
        draw_text(surf, hud_font, "JEEP", white, (int(x), int(y - 12)))

def draw_humvees(surf, humvees, off_x, off_y):
    for hv in humvees:
        x = hv['x'] + off_x
        y = hv['y'] + off_y
        color = (70, 170, 70) if hv['team'] == 'green' else (70, 100, 200)
        draw_vehicle_body(surf, x, y, humvee_w, humvee_h, hv.get('angle', 0), color, "humvee")
        draw_vehicle_turret(surf, x, y, hv.get('turret_angle', hv.get('angle', 0)), hv['team'], "humvee")
        pygame.draw.rect(surf, (30, 30, 30), (int(x - 7), int(y + 4), 14, 3))
        ratio = max(0.0, min(1.0, hv['hp'] / max(1, hv['hp_max'])))
        pygame.draw.rect(surf, (60, 0, 0), (x - humvee_w // 2, y + humvee_h // 2 + 2, humvee_w, 3))
        pygame.draw.rect(surf, (40, 200, 40), (x - humvee_w // 2, y + humvee_h // 2 + 2, humvee_w * ratio, 3))
        draw_text(surf, hud_font, "HMV", white, (int(x), int(y - 12)))

def draw_drones(surf, drones, off_x, off_y, kind, now_ms):
    for d in drones:
        x = d['x'] + off_x
        y = d['y'] + off_y
        base = (95, 230, 95) if d['team'] == 'green' else (95, 150, 255)
        # Arc-like "above ground" visual trajectory (ATGM-style feel).
        t0 = d.get('spawn_t', now_ms)
        age = max(0, now_ms - t0)
        cycle = attack_drone_dive_ms if kind == "attack" else supply_drone_collect_ms
        p = max(0.0, min(1.0, age / max(1, cycle)))
        alt_scale = 0.75 + 0.45 * math.sin(math.pi * p)
        r = int((5 if kind == "supply" else 6) * alt_scale)
        r = max(3, r)
        pygame.draw.circle(surf, base, (int(x), int(y)), r)
        pygame.draw.circle(surf, (20, 20, 20), (int(x), int(y)), r, 1)
        pygame.draw.line(surf, (220, 220, 220), (int(x - r - 2), int(y)), (int(x + r + 2), int(y)), 1)
        pygame.draw.line(surf, (220, 220, 220), (int(x), int(y - r - 2)), (int(x), int(y + r + 2)), 1)
        draw_text(surf, hud_font, "SD" if kind == "supply" else "AD", white, (int(x), int(y - 10)))

def spawn_infantry_wave(team, anchor_x, anchor_y, now_ms):
    formation = random.choice(["line", "wedge"])
    count = random.randint(4, 6)
    roles = list(INF_ROLE_STATS.keys())
    units = []
    for i in range(count):
        role = random.choice(roles)
        offset_y = (i - (count - 1) / 2) * 12
        offset_x = 0
        if formation == "wedge":
            offset_x = abs(i - (count - 1) / 2) * -6
        units.append({
            'x': max(10, min(frame_x - 10, anchor_x + offset_x)),
            'y': max(10, min(frame_y - 10, anchor_y + offset_y)),
            'team': team,
            'role': role,
            'hp': INF_ROLE_STATS[role]['hp'],
            'hp_max': INF_ROLE_STATS[role]['hp'],
            'last_shot': 0,
            'mortar_err': random.uniform(-60, 60) if role == 'mortar' else 0.0,
            'protect_until': now_ms + spawn_protect_ms,
            'spawn_t': now_ms,
            'last_active': now_ms,
            'vx': 0.0,
            'vy': 0.0,
        })
    return units

# Horde mode removed.

def draw_hud(surf, team, x, y, hp, ammo_ap, ammo_he, ammo_atgm, ammo_mg, fuel, smoke_ammo, repair_ammo, lives, now_ms, ammo_type=None, buffs=None, unit_class="MBT", gun_azimuth=None, gun_elev=None):
    color = (80, 220, 80) if team == "GREEN" else (80, 120, 220)
    hud_w, hud_h = 210, 340
    hud_bg = pygame.Surface((hud_w, hud_h), pygame.SRCALPHA)
    hud_bg.fill((0, 0, 0, 140))
    hx = x - hud_w // 2
    hy = y - 18
    # Instant pulse / flash effect
    flash_on = (now_ms // 160) % 2 == 0
    glow_alpha = 90 if flash_on else 30
    border_alpha = 140 if flash_on else 70
    pygame.draw.rect(surf, (255, 255, 255, glow_alpha), (hx - 2, hy - 2, hud_w + 4, hud_h + 4), 3, border_radius=6)
    surf.blit(hud_bg, (hx, hy))
    pygame.draw.rect(surf, (255, 255, 255, border_alpha), (hx, hy, hud_w, hud_h), 1, border_radius=6)
    draw_text(surf, sub_font, team, color, (x, y))
    line_start = y + 18
    line_h = 20
    safe_ap = max(0, ammo_ap)
    safe_he = max(0, ammo_he)
    safe_atgm = max(0, ammo_atgm)
    safe_mg = max(0, ammo_mg)
    safe_smoke = max(0, smoke_ammo)
    safe_repair = max(0, repair_ammo)
    safe_lives = max(0, lives)
    draw_text(surf, hud_font, f"HP: {int(hp)}", white, (x, line_start + line_h * 0))
    ap_label = ammo_display_label("AP", unit_class)
    draw_text(surf, hud_font, f"{ap_label}: {safe_ap}", white, (x, line_start + line_h * 1))
    draw_text(surf, hud_font, f"HE: {safe_he}", white, (x, line_start + line_h * 2))
    draw_text(surf, hud_font, f"ATGM: {safe_atgm}", white, (x, line_start + line_h * 3))
    draw_text(surf, hud_font, f"MG: {safe_mg}", white, (x, line_start + line_h * 4))
    draw_text(surf, hud_font, f"Fuel: {fuel:.0f}", white, (x, line_start + line_h * 5))
    draw_text(surf, hud_font, f"Smoke: {safe_smoke}", white, (x, line_start + line_h * 6))
    draw_text(surf, hud_font, f"Repair: {safe_repair}", white, (x, line_start + line_h * 7))
    draw_text(surf, hud_font, f"Lives: {safe_lives}", white, (x, line_start + line_h * 8))
    if gun_azimuth is not None:
        az = ((gun_azimuth + 180.0) % 360.0) - 180.0
        if gun_elev is None:
            draw_text(surf, hud_font, f"Gun Az: {az:+.0f}deg", white, (x, line_start + line_h * 9))
        else:
            draw_text(surf, hud_font, f"Gun Az: {az:+.0f}deg", white, (x, line_start + line_h * 9))
            draw_text(surf, hud_font, f"Gun El: {gun_elev:+.1f}deg", white, (x, line_start + line_h * 10))
    if ammo_type:
        ammo_line = 11 if gun_azimuth is not None and gun_elev is not None else 10 if gun_azimuth is not None else 9
        draw_text(surf, hud_font, f"Ammo: {ammo_type}", white, (x, line_start + line_h * ammo_line))
        # Ammo selector mini-GUI
        labels = ["AP", "HE", "ATGM"]
        bx = hx + 10
        by = line_start + line_h * (ammo_line + 1) - 4
        for lab in labels:
            box = pygame.Rect(bx, by, 48, 16)
            active = (lab == ammo_type)
            pygame.draw.rect(surf, (40, 40, 40), box)
            pygame.draw.rect(surf, (255, 255, 255, 180) if active else (120, 120, 120, 120), box, 2)
            draw_text(surf, hud_font, ammo_short_label(lab, unit_class), (240, 240, 240) if active else (160, 160, 160), (bx + 24, by + 8))
            bx += 52
    if buffs and isinstance(buffs, list):
        buff_text = " | ".join(buffs)
        draw_text(surf, hud_font, f"Buffs: {buff_text}", white, (x, line_start + line_h * 12))

def draw_weather(surf, particles, weather_type):
    if weather_type == "clear":
        return
    for p in particles:
        x = p['x']
        y = p['y']
        if weather_type == "rain":
            pygame.draw.line(surf, (170, 180, 200), (x, y), (x - 2, y + 8), 1)
        elif weather_type == "snow":
            pygame.draw.circle(surf, (240, 240, 255), (int(x), int(y)), 2)
        elif weather_type == "sand":
            pygame.draw.circle(surf, (200, 170, 120), (int(x), int(y)), 2)
        elif weather_type == "ash":
            pygame.draw.circle(surf, (110, 110, 110), (int(x), int(y)), 2)

def draw_warning_hud(surf, team, x, y, ammo_c, fuel_empty, lives, now_ms, offline=False, ammo_mg=1):
    color = (80, 220, 80) if team == "GREEN" else (80, 120, 220)
    hud_w, hud_h = 210, 90
    hud_bg = pygame.Surface((hud_w, hud_h), pygame.SRCALPHA)
    hud_bg.fill((0, 0, 0, 140))
    hx = x - hud_w // 2
    hy = y - 10
    pygame.draw.rect(surf, (255, 255, 255, 40), (hx - 2, hy - 2, hud_w + 4, hud_h + 4), 2, border_radius=6)
    surf.blit(hud_bg, (hx, hy))
    pygame.draw.rect(surf, (255, 255, 255, 70), (hx, hy, hud_w, hud_h), 1, border_radius=6)
    line_h = 20
    line_y = y + 8
    if offline and (now_ms // 200) % 2 == 0:
        draw_text(surf, hud_font, "OFFLINE", (200, 200, 200), (x, line_y))
        line_y += line_h
    if lives == 1 and (now_ms // 200) % 2 == 0:
        draw_text(surf, hud_font, "LAST LIFE", (255, 180, 60), (x, line_y))
        line_y += line_h
    if ammo_c == 0 and (now_ms // 200) % 2 == 0:
        draw_text(surf, hud_font, "CANNON EMPTY", (255, 200, 80), (x, line_y))
        line_y += line_h
    if fuel_empty and (now_ms // 160) % 2 == 0:
        draw_text(surf, hud_font, "FUEL EMPTY", (255, 80, 80), (x, line_y))
    if ammo_mg == 0 and (now_ms // 200) % 2 == 0:
        line_y += line_h
        draw_text(surf, hud_font, "MG EMPTY", (255, 160, 0), (x, line_y))

def draw_mode_hud(surf, mode_data):
    if not mode_data:
        return
    mode = mode_data.get("mode", "FFA")
    bar_x = 90
    bar_y = 5
    bar_w = frame_x - 180
    bar_h = 12
    pygame.draw.rect(surf, (20, 20, 24), (bar_x, bar_y, bar_w, bar_h))
    if mode == "KOTH":
        score = max(-100.0, min(100.0, mode_data.get("score", 0.0)))
        owner = mode_data.get("control")
        mid_x = bar_x + bar_w // 2
        fill_w = int((abs(score) / 100.0) * (bar_w // 2))
        if score > 0:
            pygame.draw.rect(surf, (70, 210, 70), (mid_x, bar_y, fill_w, bar_h))
        elif score < 0:
            pygame.draw.rect(surf, (90, 140, 255), (mid_x - fill_w, bar_y, fill_w, bar_h))
        pygame.draw.line(surf, (180, 180, 180), (mid_x, bar_y), (mid_x, bar_y + bar_h), 1)
        border_col = (210, 210, 210)
        if owner == "green":
            border_col = (120, 255, 120)
        elif owner == "blue":
            border_col = (130, 180, 255)
        pygame.draw.rect(surf, border_col, (bar_x, bar_y, bar_w, bar_h), 1)
    elif mode == "SIEGE":
        gr_base = max(0.0, mode_data.get("gr_base", 0.0))
        bl_base = max(0.0, mode_data.get("bl_base", 0.0))
        max_base = float(max(1, mode_data.get("base_max", barracks_hp_max)))
        gr_ratio = max(0.0, min(1.0, gr_base / max_base))
        bl_ratio = max(0.0, min(1.0, bl_base / max_base))
        half = bar_w // 2
        mid_x = bar_x + half
        gr_w = int(half * gr_ratio)
        bl_w = int(half * bl_ratio)
        pygame.draw.rect(surf, (70, 210, 70), (mid_x - gr_w, bar_y, gr_w, bar_h))
        pygame.draw.rect(surf, (90, 140, 255), (mid_x, bar_y, bl_w, bar_h))
        pygame.draw.line(surf, (180, 180, 180), (mid_x, bar_y), (mid_x, bar_y + bar_h), 1)
        pygame.draw.rect(surf, (230, 210, 160), (bar_x, bar_y, bar_w, bar_h), 1)
    elif mode == "BOSS":
        boss_hp = max(0.0, mode_data.get("boss_hp", 0.0))
        boss_hp_max = max(1.0, mode_data.get("boss_hp_max", 1.0))
        boss_ratio = max(0.0, min(1.0, boss_hp / boss_hp_max))
        pygame.draw.rect(surf, (50, 15, 15), (bar_x, bar_y, bar_w, bar_h))
        pygame.draw.rect(surf, (210, 80, 80), (bar_x, bar_y, int(bar_w * boss_ratio), bar_h))
        pygame.draw.rect(surf, (255, 255, 255), (bar_x, bar_y, bar_w, bar_h), 1)
        mods = mode_data.get("modifiers", [])
        if mods:
            draw_text(surf, hud_font, "MODS: " + ", ".join(mods), white, (frame_x // 2, bar_y + bar_h + 12))
    else:
        gr_pool = max(0.0, mode_data.get("gr_pool", 0.0))
        bl_pool = max(0.0, mode_data.get("bl_pool", 0.0))
        # FFA: each side is normalized to its own full life pool (independent gauges).
        max_pool = float(max_hp * max(1, tank_lives_max))
        gr_ratio = max(0.0, min(1.0, gr_pool / max_pool))
        bl_ratio = max(0.0, min(1.0, bl_pool / max_pool))
        half = bar_w // 2
        mid_x = bar_x + half
        gr_w = int(half * gr_ratio)
        bl_w = int(half * bl_ratio)
        # Green grows from center to left, Blue grows from center to right.
        pygame.draw.rect(surf, (70, 210, 70), (mid_x - gr_w, bar_y, gr_w, bar_h))
        pygame.draw.rect(surf, (90, 140, 255), (mid_x, bar_y, bl_w, bar_h))
        pygame.draw.line(surf, (180, 180, 180), (mid_x, bar_y), (mid_x, bar_y + bar_h), 1)
        pygame.draw.rect(surf, (210, 210, 210), (bar_x, bar_y, bar_w, bar_h), 1)

def draw_boss(surf, boss, shake_x, shake_y):
    if not boss or boss.get('hp', 0) <= 0:
        return
    x = int(boss['x'] + shake_x)
    y = int(boss['y'] + shake_y)
    draw_tank(surf, x, y, boss_ch, boss.get('angle', 0), boss_tr, boss.get('turret_angle', 0))
    hp_ratio = max(0.0, min(1.0, boss.get('hp', 0) / max(1.0, boss.get('hp_max', 1.0))))
    bar_w = 160
    bar_h = 10
    pygame.draw.rect(surf, (40, 10, 10), (x - bar_w // 2, y - 80, bar_w, bar_h))
    pygame.draw.rect(surf, (220, 80, 80), (x - bar_w // 2, y - 80, int(bar_w * hp_ratio), bar_h))
    pygame.draw.rect(surf, (255, 255, 255), (x - bar_w // 2, y - 80, bar_w, bar_h), 1)
    draw_text(surf, sub_font, "RED BOSS", (255, 180, 180), (x, y - 96))


def draw_barracks(surf, base, shake_x, shake_y, obstacles=None):
    x = int(base['x'] + shake_x)
    y = int(base['y'] + shake_y)
    w = int(base.get('w', barracks_w))
    h = int(base.get('h', barracks_h))
    hp = max(0.0, base.get('hp', 0.0))
    hp_max = max(1.0, base.get('hp_max', barracks_hp_max))
    team = base.get('team', 'green')
    fill_col = (90, 170, 85) if team == 'green' else (90, 120, 190)
    roof_col = (125, 220, 120) if team == 'green' else (130, 170, 240)
    outline_col = (20, 20, 20)

    body = pygame.Rect(x - w // 2, y - h // 2, w, h)
    roof = pygame.Rect(body.x + 10, body.y + 10, body.w - 20, body.h - 20)
    pygame.draw.rect(surf, fill_col, body, border_radius=10)
    pygame.draw.rect(surf, outline_col, body, 2, border_radius=10)
    pygame.draw.rect(surf, roof_col, roof, border_radius=8)
    pygame.draw.rect(surf, outline_col, roof, 1, border_radius=8)

    # Tents around the compound
    tent_w = max(20, int(w * 0.18))
    tent_h = max(16, int(h * 0.12))
    tent_positions = [
        (body.left + 18, body.top + 18),
        (body.right - tent_w - 18, body.top + 18),
        (body.left + 18, body.bottom - tent_h - 18),
        (body.right - tent_w - 18, body.bottom - tent_h - 18),
    ]
    for tx, ty in tent_positions:
        tent = pygame.Rect(tx, ty, tent_w, tent_h)
        pygame.draw.rect(surf, (190, 150, 100), tent)
        pygame.draw.polygon(surf, (150, 110, 70), [
            (tx, ty),
            (tx + tent_w // 2, ty - tent_h // 2),
            (tx + tent_w, ty)
        ])
        pygame.draw.line(surf, outline_col, (tx + 4, ty + 2), (tx + 4, ty + tent_h - 4), 1)
        pygame.draw.line(surf, outline_col, (tx + tent_w - 4, ty + 2), (tx + tent_w - 4, ty + tent_h - 4), 1)

    # Gate/hinge marker on the south face
    gate = pygame.Rect(body.centerx - 12, body.bottom - 16, 24, 12)
    pygame.draw.rect(surf, (75, 75, 80), gate)
    pygame.draw.rect(surf, outline_col, gate, 1)

    # Perimeter walls
    for wall in base.get('walls', []):
        if wall.get('hp', 0) <= 0:
            continue
        rect = wall['rect']
        ratio = max(0.0, min(1.0, wall.get('hp', 0.0) / max(1.0, wall.get('hp_max', 1.0))))
        wall_col = (150, int(110 * ratio + 45 * (1 - ratio)), int(70 * ratio + 35 * (1 - ratio)))
        pygame.draw.rect(surf, wall_col, (rect.x + shake_x, rect.y + shake_y, rect.w, rect.h))
        pygame.draw.rect(surf, outline_col, (rect.x + shake_x, rect.y + shake_y, rect.w, rect.h), 1)
        if ratio < 0.5:
            pygame.draw.line(surf, (70, 70, 70),
                (rect.x + shake_x + 2, rect.y + shake_y + rect.h // 2),
                (rect.x + shake_x + rect.w - 2, rect.y + shake_y + rect.h // 2), 2)

    # Base health bar
    bar_w = w
    bar_h = 8
    bar_x = body.x
    bar_y = body.y - 14
    pygame.draw.rect(surf, (30, 30, 35), (bar_x + shake_x, bar_y + shake_y, bar_w, bar_h))
    pygame.draw.rect(
        surf,
        (90, 220, 90) if team == 'green' else (110, 150, 255),
        (bar_x + shake_x, bar_y + shake_y, int(bar_w * (hp / hp_max)), bar_h)
    )
    pygame.draw.rect(surf, (220, 220, 220), (bar_x + shake_x, bar_y + shake_y, bar_w, bar_h), 1)


def create_barracks_wall_segments(base):
    w = int(base.get('w', barracks_w))
    h = int(base.get('h', barracks_h))
    bx = int(base.get('x', 0))
    by = int(base.get('y', 0))
    wall_thick = max(8, min(18, int(min(w, h) * 0.05)))
    seg_per_side = 4
    seg_w = float(w) / seg_per_side
    segs = []
    for i in range(seg_per_side):
        sx = int(bx - w / 2 + i * seg_w)
        sy = int(by - h / 2 - wall_thick)
        segs.append(pygame.Rect(sx, sy, int(math.ceil(seg_w)), wall_thick))
    for i in range(seg_per_side):
        sx = int(bx - w / 2 + i * seg_w)
        sy = int(by + h / 2)
        segs.append(pygame.Rect(sx, sy, int(math.ceil(seg_w)), wall_thick))
    seg_h = float(h) / seg_per_side
    for i in range(seg_per_side):
        sx = int(bx - w / 2 - wall_thick)
        sy = int(by - h / 2 + i * seg_h)
        segs.append(pygame.Rect(sx, sy, wall_thick, int(math.ceil(seg_h))))
    for i in range(seg_per_side):
        sx = int(bx + w / 2)
        sy = int(by - h / 2 + i * seg_h)
        segs.append(pygame.Rect(sx, sy, wall_thick, int(math.ceil(seg_h))))
    hp = max(45.0, base.get('hp_max', barracks_hp_max) * 0.1)
    walls = []
    for rect in segs:
        walls.append({'rect': rect, 'hp': hp, 'hp_max': hp, 'otype': 'barracks_wall', 'base': base})
    return walls

def get_settings_icon_rect():
    size = 22
    x = frame_x // 2 + 160
    y = 12
    return pygame.Rect(x, y, size, size)

def get_settings_panel_rect():
    panel_w, panel_h = 420, 300
    x = frame_x // 2 - panel_w // 2
    y = 60
    return pygame.Rect(x, y, panel_w, panel_h)

def get_settings_slider_rects():
    panel = get_settings_panel_rect()
    left = panel.x + 190
    top = panel.y + 54
    w = 190
    h = 12
    gap = 32
    return {
        "music": pygame.Rect(left, top + gap * 0, w, h),
        "sfx": pygame.Rect(left, top + gap * 1, w, h),
        "day_speed": pygame.Rect(left, top + gap * 2, w, h),
        "night_dark": pygame.Rect(left, top + gap * 3, w, h),
    }

def draw_settings_icon(surf):
    rect = get_settings_icon_rect()
    cx = rect.centerx
    cy = rect.centery
    pygame.draw.circle(surf, (230, 230, 230), (cx, cy), 9, 2)
    pygame.draw.circle(surf, (230, 230, 230), (cx, cy), 2)
    for ang in range(0, 360, 45):
        rad = math.radians(ang)
        x1 = cx + math.cos(rad) * 6
        y1 = cy + math.sin(rad) * 6
        x2 = cx + math.cos(rad) * 11
        y2 = cy + math.sin(rad) * 11
        pygame.draw.line(surf, (230, 230, 230), (x1, y1), (x2, y2), 2)

def draw_settings_panel(surf, settings):
    if not settings:
        return
    panel = get_settings_panel_rect()
    x, y, panel_w, panel_h = panel.x, panel.y, panel.w, panel.h
    bg = pygame.Surface((panel_w, panel_h), pygame.SRCALPHA)
    bg.fill((0, 0, 0, 160))
    surf.blit(bg, (x, y))
    pygame.draw.rect(surf, (220, 220, 220), (x, y, panel_w, panel_h), 1)
    line = 28
    draw_text(surf, hud_font, "SETTINGS", white, (frame_x // 2, y + 18))
    label_x = x + 28
    draw_text(surf, hud_font, f"Music Vol: {settings['music']:.2f}", white, (label_x + 70, y + 18 + line * 1))
    draw_text(surf, hud_font, f"SFX Vol:   {settings['sfx']:.2f}", white, (label_x + 70, y + 18 + line * 2))
    draw_text(surf, hud_font, f"Day Speed: {settings['day_speed']:.2f}", white, (label_x + 70, y + 18 + line * 3))
    draw_text(surf, hud_font, f"Night Dark:{int(settings['night_dark'])}", white, (label_x + 70, y + 18 + line * 4))
    draw_text(surf, hud_font, f"Weather: {'ON' if settings['weather'] else 'OFF'}", white, (label_x + 70, y + 18 + line * 5))
    draw_text(surf, hud_font, f"Particles: {'ON' if settings['particles'] else 'OFF'}", white, (label_x + 70, y + 18 + line * 6))
    draw_text(surf, hud_font, f"Quality: {settings.get('quality', 'BALANCED')}", white, (label_x + 70, y + 18 + line * 7))
    draw_text(surf, hud_font, f"Auto Low: {'ON' if settings.get('auto_low', False) else 'OFF'}", white, (label_x + 70, y + 18 + line * 8))

    sliders = get_settings_slider_rects()
    def draw_slider(rect, value, vmin, vmax):
        pygame.draw.rect(surf, (70, 70, 70), rect)
        pygame.draw.rect(surf, (200, 200, 200), rect, 1)
        t = (value - vmin) / max(vmax - vmin, 0.001)
        t = max(0.0, min(1.0, t))
        knob_x = rect.x + int(t * rect.w)
        pygame.draw.circle(surf, (230, 230, 230), (knob_x, rect.centery), 7)

    draw_slider(sliders["music"], settings["music"], 0.0, 1.5)
    draw_slider(sliders["sfx"], settings["sfx"], 0.0, 1.5)
    draw_slider(sliders["day_speed"], settings["day_speed"], 0.5, 2.0)
    draw_slider(sliders["night_dark"], settings["night_dark"], 80, 230)

def draw_engine_smoke(surf, particles, now_ms, off_x, off_y):
    for p in particles:
        age = now_ms - p['t']
        if age < 0 or age > p['life']:
            continue
        alpha = max(0, 180 - int(180 * (age / p['life'])))
        r = 3 + int(10 * (age / p['life']))
        s = pygame.Surface((r * 2, r * 2), pygame.SRCALPHA)
        pygame.draw.circle(s, (80, 80, 80, alpha), (r, r), r)
        surf.blit(s, (p['x'] + off_x - r, p['y'] + off_y - r))

def draw_track_marks(surf, marks, now_ms, off_x, off_y):
    for m in marks:
        age = now_ms - m['t']
        if age < 0 or age > track_mark_life:
            continue
        alpha = max(0, 120 - int(120 * (age / track_mark_life)))
        col = (30, 30, 30, alpha)
        s = pygame.Surface((frame_x, frame_y), pygame.SRCALPHA)
        pygame.draw.line(s, col, (m['x1'] + off_x, m['y1'] + off_y), (m['x2'] + off_x, m['y2'] + off_y), 2)
        surf.blit(s, (0, 0))

def draw_casings(surf, casings, now_ms, off_x, off_y):
    for c in casings:
        age = now_ms - c['t']
        if age < 0 or age > casing_life:
            continue
        x = c['x'] + c['vx'] * (age / 1000.0)
        y = c['y'] + c['vy'] * (age / 1000.0)
        pygame.draw.circle(surf, (160, 120, 60), (int(x + off_x), int(y + off_y)), 2)

def draw_tank(surf, x, y, chassis_img, chassis_angle, turret_img, turret_angle):
    blit_rotate_center(surf, chassis_img, (x, y), chassis_angle)
    if turret_img is not None:
        blit_rotate_center(surf, turret_img, (x, y), turret_angle)

def get_collision_rect(image, center, angle, scale):
    w, h = image.get_size()
    w = max(1, int(w * scale))
    h = max(1, int(h * scale))
    temp = pygame.Surface((w, h), pygame.SRCALPHA)
    rotated = pygame.transform.rotate(temp, angle)
    return rotated.get_rect(center=center)

def draw_muzzle_flashes(surf, flashes, now_ms, off_x, off_y):
    for flash in flashes:
        age = now_ms - flash['t']
        if age <= 100:
            phase = max(0.0, min(1.0, age / 100.0))
            pulse = math.sin(math.pi * phase)  # fade in/out
            img = muzzle
            scale = flash.get('scale', 1.0) * (0.7 + 0.6 * pulse)
            w, h = muzzle.get_size()
            img = pygame.transform.smoothscale(muzzle, (int(w * scale), int(h * scale)))
            img.set_alpha(int(255 * pulse))
            blit_rotate_center(surf, img, (flash['x'] + off_x, flash['y'] + off_y), flash['angle'])

def draw_explosions(surf, explosions, now_ms, off_x, off_y):
    for boom in explosions:
        age = now_ms - boom['t']
        if age <= 180:
            radius = boom.get('r', mortar_blast_r * 0.7)
            radius_scale = max(0.5, radius / max(1.0, mortar_blast_r))
            scale = (0.6 + (age / 180.0) * 0.8) * radius_scale
            w, h = explosion.get_size()
            scaled = pygame.transform.smoothscale(explosion, (int(w * scale), int(h * scale)))
            blit_rotate_center(surf, scaled, (boom['x'] + off_x, boom['y'] + off_y), boom['angle'])

def draw_airdrops(surf, drops, off_x, off_y, now_ms, theme, *, draw_parachute=True, draw_crates=True):
    for drop in drops:
        x = drop['x'] + off_x
        y = drop['y'] + off_y
        land_x = drop['x'] + off_x
        land_y = drop['y'] + off_y

        t = max(0.0, min(1.0, (now_ms - drop['spawn']) / 5000.0))
        scale = 1.0 - 0.55 * t  # starts visible, shrinks to infantry-scale

        if draw_crates:
            # Layered 2D crate (rectangle) - stays in place, scales down
            base = pygame.Rect(x - 6 * scale, y - 4 * scale, 12 * scale, 8 * scale)
            mid = pygame.Rect(x - 5 * scale, y - 5 * scale, 10 * scale, 7 * scale)
            top = pygame.Rect(x - 4 * scale, y - 6 * scale, 8 * scale, 6 * scale)
            pygame.draw.rect(surf, theme['crate_base'], base)
            pygame.draw.rect(surf, theme['crate_mid'], mid)
            pygame.draw.rect(surf, theme['crate_top'], top)
            pygame.draw.rect(surf, (80, 60, 10), base, 2)
            pygame.draw.rect(surf, (80, 60, 10), mid, 2)
            pygame.draw.rect(surf, (80, 60, 10), top, 2)

            label = "AS" if drop['type'] == "airstrike" else drop['type'][0].upper()
            draw_text(surf, ocr, label, (60, 40, 0), (x, y + 16))
            if drop['landed']:
                # Landing marker (drawn after crate)
                pygame.draw.circle(surf, theme['marker'], (int(land_x), int(land_y)), 10, 2)
                pygame.draw.circle(surf, (120, 80, 20), (int(land_x), int(land_y)), 3)

        if draw_parachute and not drop['landed']:
            # Top-down parachute canopy (drawn last so it's on top)
            r = int(16 * scale)
            pygame.draw.circle(surf, (220, 220, 220), (int(x), int(y)), r)
            pygame.draw.circle(surf, (180, 180, 180), (int(x), int(y)), r, 2)
            pygame.draw.line(surf, (200, 200, 200), (x - r * 0.5, y), (x, y + r * 0.35), 2)
            pygame.draw.line(surf, (200, 200, 200), (x + r * 0.5, y), (x, y + r * 0.35), 2)

def draw_smoke(surf, smokes, now_ms, off_x, off_y):
    for sm in smokes:
        age = now_ms - sm['t']
        if age < 0:
            continue
        if age <= smoke_duration_ms:
            # Ease in opacity then dissipate
            if age < smoke_fade_in:
                alpha_frac = age / max(smoke_fade_in, 1)
            else:
                alpha_frac = max(0.0, 1 - (age - smoke_fade_in) / max(smoke_duration_ms - smoke_fade_in, 1))
            alpha = max(0, min(255, int(230 * alpha_frac)))

            # Growth slowed when opacity is lower (square-cube-ish)
            growth_scale = max(0.2, alpha_frac)
            r = int(sm['r0'] + (smoke_radius - sm['r0']) * (age / smoke_duration_ms) * growth_scale)
            r = max(2, r)
            s = pygame.Surface((r * 2, r * 2), pygame.SRCALPHA)
            pygame.draw.circle(s, (120, 120, 120, alpha), (r, r), r)
            surf.blit(s, (sm['x'] - r + off_x, sm['y'] - r + off_y))

def smoke_puff_radius(sm, now_ms):
    age = now_ms - sm['t']
    if age < 0 or age > smoke_duration_ms:
        return 0
    if age < smoke_fade_in:
        alpha_frac = age / max(smoke_fade_in, 1)
    else:
        alpha_frac = max(0.0, 1 - (age - smoke_fade_in) / max(smoke_duration_ms - smoke_fade_in, 1))
    growth_scale = max(0.2, alpha_frac)
    r = int(sm['r0'] + (smoke_radius - sm['r0']) * (age / smoke_duration_ms) * growth_scale)
    return max(2, r)

def is_in_smoke(x, y, smokes, now_ms):
    for sm in smokes:
        r = smoke_puff_radius(sm, now_ms)
        if r <= 0:
            continue
        if math.hypot(x - sm['x'], y - sm['y']) <= r:
            return True
    return False

def respawn_tank(spawn_pos, now_ms):
    return {
        'hp': max_hp,
        'x': spawn_pos[0],
        'y': spawn_pos[1],
        'vel': 0.0,
        'chassis_av': 0.0,
        'cannon_ap': cannon_ap_max,
        'cannon_he': cannon_he_max,
        'cannon_atgm': cannon_atgm_max,
        'mg_ammo': mg_ammo_max,
        'fuel': fuel_max,
        'mg_heat': 0.0,
        'overheat': False,
        'smoke_ammo': smoke_ammo_max,
        'repair_ammo': repair_ammo_max,
        'protect_until': now_ms + spawn_protect_ms,
        'engine_dmg': 0.0,
        'turret_dmg': 0.0,
    }

def cycle_ammo_type(current):
    keys = list(CANNON_TYPES.keys())
    if current not in keys:
        return keys[0]
    idx = keys.index(current)
    return keys[(idx + 1) % len(keys)]

def cycle_quality_mode(current):
    if current not in QUALITY_PRESETS:
        return QUALITY_PRESETS[0]
    idx = QUALITY_PRESETS.index(current)
    return QUALITY_PRESETS[(idx + 1) % len(QUALITY_PRESETS)]

def push_kill_feed(feed, text, color, now_ms):
    feed.append({"t": now_ms, "text": text, "color": color})
    if len(feed) > kill_feed_max:
        del feed[0:len(feed) - kill_feed_max]

def pick_round_mode():
    global ROUND_MODE_BAG
    # Persist round-mode cycle across app restarts so no mode feels "missing".
    mode_state_path = os.path.join(".", ".tanktation_mode_cycle.txt")
    mode_cycle = ["FFA", "KOTH", "SIEGE", "BOSS"]
    try:
        if os.path.exists(mode_state_path):
            with open(mode_state_path, "r", encoding="utf-8") as f:
                prev = f.read().strip()
            if prev in mode_cycle:
                idx = mode_cycle.index(prev)
                mode = mode_cycle[(idx + 1) % len(mode_cycle)]
                with open(mode_state_path, "w", encoding="utf-8") as f:
                    f.write(mode)
                return mode
    except Exception:
        pass
    if not ROUND_MODE_BAG:
        ROUND_MODE_BAG = mode_cycle[:]
        random.shuffle(ROUND_MODE_BAG)
    mode = ROUND_MODE_BAG.pop()
    try:
        with open(mode_state_path, "w", encoding="utf-8") as f:
            f.write(mode)
    except Exception:
        pass
    return mode

def total_cannon_ammo(ap, he, atgm):
    return ap + he + atgm

def ammo_count_by_type(ammo_type, ap, he, atgm):
    if ammo_type == "AP":
        return ap
    if ammo_type == "HE":
        return he
    if ammo_type == "ATGM":
        return atgm
    return 0

def spend_ammo(ammo_type, ap, he, atgm):
    if ammo_type == "AP":
        return max(0, ap - 1), he, atgm
    if ammo_type == "HE":
        return ap, max(0, he - 1), atgm
    if ammo_type == "ATGM":
        return ap, he, max(0, atgm - 1)
    return ap, he, atgm

def ensure_ammo_type(current, ap, he, atgm):
    if current == "AP" and ap > 0:
        return current
    if current == "HE" and he > 0:
        return current
    if current == "ATGM" and atgm > 0:
        return current
    for t in ("AP", "HE", "ATGM"):
        if (t == "AP" and ap > 0) or (t == "HE" and he > 0) or (t == "ATGM" and atgm > 0):
            return t
    return current

def cannon_reload_ms(ammo_type, base_ms):
    spec = CANNON_TYPES.get(ammo_type, CANNON_TYPES["AP"])
    return int(base_ms * spec.get("cd", 1.0))

def class_cannon_profile(unit_class):
    return CLASS_CANNON_PROFILE.get(unit_class, CLASS_CANNON_PROFILE["MBT"])

def ammo_display_label(ammo_type, unit_class):
    if ammo_type == "AP":
        return class_cannon_profile(unit_class).get("ap_label", "AP")
    return ammo_type

def ammo_short_label(ammo_type, unit_class):
    if ammo_type == "AP":
        return class_cannon_profile(unit_class).get("ap_short", "AP")
    return ammo_type

def point_segment_dist(px, py, x1, y1, x2, y2):
    dx = x2 - x1
    dy = y2 - y1
    if dx == 0 and dy == 0:
        return math.hypot(px - x1, py - y1)
    t = ((px - x1) * dx + (py - y1) * dy) / (dx * dx + dy * dy)
    t = max(0.0, min(1.0, t))
    cx = x1 + t * dx
    cy = y1 + t * dy
    return math.hypot(px - cx, py - cy)

def obstacle_height(obs):
    otype = obs.get('otype', '')
    if otype == 'building':
        return 100.0
    if otype == 'tree':
        return 10.0
    if otype == 'volcano':
        return 90.0
    if otype == 'rock':
        return 5.0
    if otype == 'trench':
        return 2.0
    if otype == 'ditch':
        return 1.0
    if otype == 'emplacement':
        return 8.0
    return 20.0

def rect_poly(cx, cy, length, width, angle_deg):
    rad = math.radians(angle_deg)
    fx, fy = math.cos(rad), math.sin(rad)
    px, py = -fy, fx
    return [
        (cx - fx * length / 2 - px * width / 2, cy - fy * length / 2 - py * width / 2),
        (cx + fx * length / 2 - px * width / 2, cy + fy * length / 2 - py * width / 2),
        (cx + fx * length / 2 + px * width / 2, cy + fy * length / 2 + py * width / 2),
        (cx - fx * length / 2 + px * width / 2, cy - fy * length / 2 + py * width / 2),
    ]

def points_rect(points, inset=0):
    rect = pygame.Rect(points[0], (0, 0))
    for p in points[1:]:
        rect.union_ip(pygame.Rect(p, (0, 0)))
    if inset:
        rect.inflate_ip(-inset, -inset)
    return rect

def vehicle_height(vehicle):
    vtype = vehicle.get('type', 'apc')
    if vtype == 'apc':
        return 38.0
    if vtype == 'humvee':
        return 30.0
    if vtype == 'jeep':
        return 24.0
    return 30.0

def tank_height():
    return 44.0

def line_of_sight_clear(x1, y1, x2, y2, obstacles, ignore_low=True):
    for obs in obstacles:
        if ignore_low and obstacle_height(obs) <= 10.0:
            continue
        rect = obs.get('rect')
        if rect and rect.clipline(x1, y1, x2, y2):
            return False
    return True

def predict_round_impact(start_x, start_y, angle_deg, elev_deg, ammo_type, obstacles, blockers=None):
    if ammo_type == "ATGM":
        return None
    spec = CANNON_TYPES.get(ammo_type, CANNON_TYPES["AP"])
    speed = spec["spd"]
    angle = math.radians(angle_deg)
    elev = math.radians(max(0.0, min(60.0, elev_deg)))
    horiz = speed * math.cos(elev)
    vx = math.cos(angle) * horiz
    vy = -math.sin(angle) * horiz
    z = 6.0
    vz = speed * math.sin(elev)
    step = 0.045
    x = start_x
    y = start_y
    for _ in range(180):
        x += vx * step
        y += vy * step
        z += vz * step
        vz -= shell_gravity * step
        if x < 0 or x > frame_x or y < 0 or y > frame_y:
            return (max(0, min(frame_x, x)), max(0, min(frame_y, y)))
        for obs in obstacles:
            rect = obs.get('rect')
            if rect and rect.collidepoint(x, y) and z <= obstacle_height(obs):
                return (x, y)
        if blockers:
            for rect, height in blockers:
                if rect.collidepoint(x, y) and z <= height:
                    return (x, y)
        if z <= 0:
            return (x, y)
    return None

def draw_impact_marker(surf, x, y, color, off_x=0.0, off_y=0.0):
    cx = int(x + off_x)
    cy = int(y + off_y)
    outline = (8, 8, 8)
    pygame.draw.circle(surf, outline, (cx, cy), 13, 3)
    pygame.draw.circle(surf, color, (cx, cy), 13, 2)
    pygame.draw.circle(surf, outline, (cx, cy), 5, 2)
    pygame.draw.circle(surf, color, (cx, cy), 5, 1)
    pygame.draw.line(surf, outline, (cx - 21, cy), (cx - 8, cy), 4)
    pygame.draw.line(surf, outline, (cx + 8, cy), (cx + 21, cy), 4)
    pygame.draw.line(surf, outline, (cx, cy - 21), (cx, cy - 8), 4)
    pygame.draw.line(surf, outline, (cx, cy + 8), (cx, cy + 21), 4)
    pygame.draw.line(surf, color, (cx - 20, cy), (cx - 8, cy), 2)
    pygame.draw.line(surf, color, (cx + 8, cy), (cx + 20, cy), 2)
    pygame.draw.line(surf, color, (cx, cy - 20), (cx, cy - 8), 2)
    pygame.draw.line(surf, color, (cx, cy + 8), (cx, cy + 20), 2)

def build_cannon_bullet(owner, x, y, angle_deg, damage_mult, ammo_type, owner_class="MBT", elev_deg=0.0):
    spec = CANNON_TYPES.get(ammo_type, CANNON_TYPES["AP"])
    rad = math.radians(angle_deg)
    speed = spec["spd"]
    elev_rad = math.radians(max(0.0, min(60.0, elev_deg)))
    horiz_speed = speed * math.cos(elev_rad)
    vz0 = speed * math.sin(elev_rad)
    target_team = "blue" if owner == "green" else "green"
    z0 = 6.0
    return {
        'x': x,
        'y': y,
        'vx': math.cos(rad) * horiz_speed,
        'vy': -math.sin(rad) * horiz_speed,
        'angle': angle_deg,
        'damage': bullet_damage * spec["dmg"] * damage_mult,
        'scale': 1.0,
        'explode': True,
        'blast_r': mortar_blast_r * spec["blast"],
        'homing': spec["homing"],
        'turn_rate': spec["turn"],
        'type': 'cannon',
        'owner': owner,
        'owner_class': owner_class,
        'hp': spec.get("hp", 3),
        'ammo_type': ammo_type,
        'target_team': target_team,
        'wind_scale': spec.get("wind", 0.35),
        'elev': elev_deg,
        'z': z0,
        'vz': vz0,
        'gravity': shell_gravity,
        # Keep synchronized trajectory tracks (x/y/z) for deterministic ballistic logic.
        'path_x': array('f', [float(x)]),
        'path_y': array('f', [float(y)]),
        'path_z': array('f', [float(z0)]),
    }

def draw_atgm(surf, x, y, angle_deg, scale=1.0):
    ang = math.radians(angle_deg)
    length = 22 * scale
    width = 9 * scale
    nose_x = x + math.cos(ang) * length * 0.6
    nose_y = y - math.sin(ang) * length * 0.6
    tail_x = x - math.cos(ang) * length * 0.4
    tail_y = y + math.sin(ang) * length * 0.4
    perp_x = math.cos(ang + math.pi / 2) * width * 0.5
    perp_y = -math.sin(ang + math.pi / 2) * width * 0.5
    pts = [
        (nose_x, nose_y),
        (tail_x + perp_x, tail_y + perp_y),
        (tail_x - perp_x, tail_y - perp_y),
    ]
    pygame.draw.polygon(surf, (240, 180, 80), pts)
    pygame.draw.circle(surf, (120, 90, 40), (int(tail_x), int(tail_y)), max(2, int(2 * scale)))

    # Exhaust puff
    puff_len = 10 * scale
    puff_x = tail_x - math.cos(ang) * puff_len
    puff_y = tail_y + math.sin(ang) * puff_len
    puff = pygame.Surface((18, 18), pygame.SRCALPHA)
    pygame.draw.circle(puff, (170, 170, 170, 120), (9, 9), 6)
    surf.blit(puff, (puff_x - 9, puff_y - 9))

def draw_bullet(surf, bullet):
    if bullet.get('ammo_type') == "ATGM":
        if atgm_round is not None:
            img = atgm_round
            if bullet.get('scale') is not None:
                w, h = atgm_round.get_size()
                img = pygame.transform.smoothscale(atgm_round, (int(w * bullet['scale'] * atgm_visual_scale), int(h * bullet['scale'] * atgm_visual_scale)))
            bullet_img = pygame.transform.rotate(img, bullet['angle'])
            rect = bullet_img.get_rect(center=(bullet['x'], bullet['y']))
            surf.blit(bullet_img, rect.topleft)
        else:
            draw_atgm(surf, bullet['x'], bullet['y'], bullet['angle'], bullet.get('scale', 1.0) * atgm_visual_scale)
        return
    ammo_t = bullet.get('ammo_type')
    if ammo_t == "AP":
        img = apfsds_round if bullet.get('owner_class', "MBT") == "MBT" else ap_round
    elif ammo_t == "HE":
        img = he_round
    else:
        img = bull
    if bullet.get('scale') is not None:
        w, h = img.get_size()
        img = pygame.transform.smoothscale(img, (int(w * bullet['scale']), int(h * bullet['scale'])))
    bullet_img = pygame.transform.rotate(img, bullet['angle'])
    rect = bullet_img.get_rect(center=(bullet['x'], bullet['y']))
    surf.blit(bullet_img, rect.topleft)

def handle_bullets(bullets, gr_rect, bl_rect, obstacles, infantry, vehicles, now_ms, dt, gr_in_smoke, bl_in_smoke, gr_protect_until=0, bl_protect_until=0, gr_angle=0.0, bl_angle=180.0, wind_vec=(0.0, 0.0), boss=None):
    next_bullets = []
    green_hits = 0
    blue_hits = 0
    green_damage = 0.0
    blue_damage = 0.0
    explosions = []
    track_marks = []
    casings = []
    cannon_hit = False
    crit_events = []
    # Wind drift disabled for ballistics: projectile spin/angular momentum dominates in-game.

    for bullet in bullets:
        if 'z' not in bullet:
            bullet['z'] = 1.5
        if 'vz' not in bullet:
            bullet['vz'] = 0.0
        if 'gravity' not in bullet:
            bullet['gravity'] = 0.0
        if bullet.get('homing'):
            tx, ty = (bl_rect.centerx, bl_rect.centery) if bullet['owner'] == 'green' else (gr_rect.centerx, gr_rect.centery)
            dx = tx - bullet['x']
            dy = ty - bullet['y']
            desired = math.degrees(math.atan2(-dy, dx))
            cur = math.degrees(math.atan2(-bullet['vy'], bullet['vx']))
            turn = bullet.get('turn_rate', 0.0) * dt
            delta = (desired - cur + 540) % 360 - 180
            if abs(delta) > turn:
                cur += turn if delta > 0 else -turn
            else:
                cur = desired
            speed = math.hypot(bullet['vx'], bullet['vy'])
            rad = math.radians(cur)
            bullet['vx'] = math.cos(rad) * speed
            bullet['vy'] = -math.sin(rad) * speed
            bullet['angle'] = cur
        # Homing for APC ATGMs
        if bullet.get('type') == 'apc_at':
            target_obj = bullet.get('target_obj')
            target_kind = bullet.get('target_kind')
            target_team = bullet.get('target_team')
            if target_obj is not None and target_obj.get('hp', 0) > 0:
                tx = target_obj['x']
                ty = target_obj['y']
            elif target_kind == 'tank':
                if target_team == 'blue':
                    tx, ty = bl_rect.centerx, bl_rect.centery
                else:
                    tx, ty = gr_rect.centerx, gr_rect.centery
            else:
                tx, ty = None, None
            if tx is not None:
                dx = tx - bullet['x']
                dy = ty - bullet['y']
                desired = math.degrees(math.atan2(-dy, dx))
                cur = math.degrees(math.atan2(-bullet['vy'], bullet['vx']))
                turn = 120.0 * dt
                delta = (desired - cur + 540) % 360 - 180
                if abs(delta) > turn:
                    cur += turn if delta > 0 else -turn
                else:
                    cur = desired
                speed = math.hypot(bullet['vx'], bullet['vy'])
                rad = math.radians(cur)
                bullet['vx'] = math.cos(rad) * speed
                bullet['vy'] = -math.sin(rad) * speed
                bullet['angle'] = cur

        old_x = bullet['x']
        old_y = bullet['y']
        bullet['x'] += bullet['vx'] * dt
        bullet['y'] += bullet['vy'] * dt
        # ATGMs maintain guided flight altitude; they do not arc into the ground.
        is_atgm_guided = bullet.get('ammo_type') == "ATGM" or bullet.get('type') == 'apc_at'
        if is_atgm_guided:
            bullet['gravity'] = 0.0
            bullet['vz'] = 0.0
            bullet['z'] = max(24.0, bullet.get('z', 24.0))
        else:
            bullet['z'] += bullet['vz'] * dt
            bullet['vz'] -= bullet.get('gravity', 0.0) * dt
        if 'path_x' in bullet:
            bullet['path_x'].append(float(bullet['x']))
            bullet['path_y'].append(float(bullet['y']))
            bullet['path_z'].append(float(bullet['z']))
        if bullet['x'] < -80 or bullet['x'] > frame_x + 80 or bullet['y'] < -80 or bullet['y'] > frame_y + 80:
            continue
        if bullet['z'] <= 0 and not is_atgm_guided:
            if bullet.get('explode', False):
                explosions.append({'x': bullet['x'], 'y': bullet['y'], 'angle': 0, 't': now_ms, 'r': bullet.get('blast_r')})
                cannon_hit = True
            continue
        tracer_tail = None
        if bullet.get('type') == 'mg':
            mag = math.hypot(bullet['vx'], bullet['vy'])
            if mag > 0:
                tracer_tail = (
                    bullet['x'] - (bullet['vx'] / mag) * mg_tracer_len,
                    bullet['y'] - (bullet['vy'] / mag) * mg_tracer_len
                )
        bullet_rect = bull.get_rect(center=(bullet['x'], bullet['y']))
        min_x = min(old_x, bullet['x']) - 4
        min_y = min(old_y, bullet['y']) - 4
        max_x = max(old_x, bullet['x']) + 4
        max_y = max(old_y, bullet['y']) + 4
        swept_rect = pygame.Rect(min_x, min_y, max_x - min_x, max_y - min_y)

        boss_rect = None
        if boss and boss.get('hp', 0) > 0:
            boss_rect = get_collision_rect(boss_ch, (boss['x'], boss['y']), boss.get('angle', 0), TANK_HITBOX_SCALE * 1.15)
            if bullet['owner'] in ('green', 'blue') and GAME_MODE_CURRENT == 'BOSS':
                if bullet_rect.colliderect(boss_rect) or swept_rect.colliderect(boss_rect):
                    if bullet.get('z', 0.0) > tank_height() * 1.4:
                        pass
                    else:
                        damage_to_boss = bullet['damage'] * (1.25 if bullet.get('ammo_type') == 'ATGM' else 1.0)
                        boss['hp'] = max(0.0, boss.get('hp', 0.0) - damage_to_boss)
                        if bullet.get('explode', False):
                            explosions.append({'x': bullet['x'], 'y': bullet['y'], 'angle': 0, 't': now_ms, 'r': bullet.get('blast_r')})
                            cannon_hit = True
                        continue

        hit_obstacle = False
        is_atgm = bullet.get('ammo_type') == "ATGM"
        can_contact_detonate = bullet.get('type') == 'cannon' and not is_atgm
        for obs in obstacles:
            if swept_rect.colliderect(obs['rect']) or bullet_rect.colliderect(obs['rect']):
                if bullet.get('z', 0.0) > obstacle_height(obs):
                    continue
                if obs.get('hp') is not None:
                    damage_to_obs = bullet.get('damage', 0.0)
                    if is_atgm:
                        damage_to_obs *= 1.8
                    obs['hp'] = max(0.0, obs['hp'] - damage_to_obs)
                    if obs['hp'] <= 0:
                        explosions.append({'x': bullet['x'], 'y': bullet['y'], 'angle': 0, 't': now_ms, 'r': max(12, bullet.get('blast_r', 12))})
                        cannon_hit = True
                        hit_obstacle = True
                    else:
                        if can_contact_detonate or bullet['explode']:
                            explosions.append({'x': bullet['x'], 'y': bullet['y'], 'angle': 0, 't': now_ms, 'r': bullet.get('blast_r')})
                            cannon_hit = True
                            hit_obstacle = True
                        else:
                            if bullet.get('hp') is not None:
                                bullet['hp'] -= 1
                                if bullet['hp'] <= 0:
                                    hit_obstacle = True
                            else:
                                hit_obstacle = True
                else:
                    if is_atgm:
                        if obs.get('otype') == 'building':
                            explosions.append({'x': bullet['x'], 'y': bullet['y'], 'angle': 0, 't': now_ms, 'r': bullet.get('blast_r')})
                            cannon_hit = True
                            hit_obstacle = True
                        else:
                            continue
                    elif not bullet.get('homing'):
                        if can_contact_detonate or bullet['explode']:
                            explosions.append({'x': bullet['x'], 'y': bullet['y'], 'angle': 0, 't': now_ms, 'r': bullet.get('blast_r')})
                            cannon_hit = True
                            hit_obstacle = True
                        else:
                            if bullet.get('hp') is not None:
                                bullet['hp'] -= 1
                                if bullet['hp'] <= 0:
                                    hit_obstacle = True
                            else:
                                hit_obstacle = True
                break
        if hit_obstacle:
            continue

        hit_inf = False
        if not is_atgm:
            for unit in infantry:
                if unit.get('protect_until', 0) > now_ms:
                    continue
                unit_rect = pygame.Rect(unit['x'] - 7, unit['y'] - 7, 14, 14)
                if bullet.get('z', 0.0) > 18.0:
                    continue
                near_line = False
                if bullet.get('type') == 'mg':
                    near_line = point_segment_dist(unit['x'], unit['y'], old_x, old_y, bullet['x'], bullet['y']) <= 9
                tracer_hit = False
                if tracer_tail is not None:
                    tracer_hit = unit_rect.clipline(tracer_tail[0], tracer_tail[1], bullet['x'], bullet['y'])
                if unit_rect.colliderect(swept_rect) or tracer_hit or \
                   near_line or \
                   math.hypot(unit['x'] - bullet['x'], unit['y'] - bullet['y']) <= 7 or \
                   math.hypot(unit['x'] - old_x, unit['y'] - old_y) <= 7:
                    if bullet['explode']:
                        dmg = bullet['damage']
                    else:
                        dmg = bullet['damage'] * (infantry_mg_scale if bullet.get('type') == 'mg' else 0.6)
                    unit['hp'] -= dmg
                    if can_contact_detonate or bullet['explode']:
                        explosions.append({'x': bullet['x'], 'y': bullet['y'], 'angle': 0, 't': now_ms, 'r': bullet.get('blast_r')})
                        cannon_hit = True
                    hit_inf = True
                    break
            if not hit_inf:
                for veh in vehicles:
                    if veh.get('protect_until', 0) > now_ms:
                        continue
                    vr = apc_rect(veh)
                    if bullet.get('z', 0.0) > vehicle_height(veh):
                        continue
                    tracer_hit = False
                    if tracer_tail is not None:
                        tracer_hit = vr.clipline(tracer_tail[0], tracer_tail[1], bullet['x'], bullet['y'])
                    if vr.colliderect(bullet_rect) or vr.colliderect(swept_rect) or tracer_hit:
                        veh['hp'] -= bullet['damage'] if bullet['explode'] else bullet['damage'] * 0.6
                        if can_contact_detonate or bullet['explode']:
                            explosions.append({'x': bullet['x'], 'y': bullet['y'], 'angle': 0, 't': now_ms, 'r': bullet.get('blast_r')})
                            cannon_hit = True
                        hit_inf = True
                        break
            if hit_inf:
                continue

        if bullet['owner'] == 'green':
            if GAME_MODE_CURRENT == 'BOSS':
                continue
            tracer_hit = False
            if tracer_tail is not None:
                tracer_hit = bl_rect.clipline(tracer_tail[0], tracer_tail[1], bullet['x'], bullet['y'])
            if bullet_rect.colliderect(bl_rect) or swept_rect.colliderect(bl_rect) or tracer_hit:
                if bullet.get('z', 0.0) > tank_height():
                    continue
                if bl_protect_until > now_ms:
                    continue
                if bl_in_smoke and random.random() < smoke_miss_chance:
                    continue
                mult, ricochet = armor_hit_multiplier(bullet, bl_angle)
                if ricochet:
                    explosions.append({'x': bullet['x'], 'y': bullet['y'], 'angle': 0, 't': now_ms, 'r': 10})
                    continue
                blue_hits += 1
                blue_damage += bullet['damage'] * mult
                if bullet.get('type') == 'cannon' and random.random() < crit_hit_chance:
                    severity = 0.18 if bullet.get('ammo_type') == "HE" else 0.24
                    system = "engine" if random.random() < crit_engine_bias else "turret"
                    crit_events.append({'team': 'blue', 'system': system, 'amount': severity})
                if can_contact_detonate or bullet['explode']:
                    explosions.append({'x': bullet['x'], 'y': bullet['y'], 'angle': 0, 't': now_ms, 'r': bullet.get('blast_r')})
                    cannon_hit = True
                continue
        else:
            if bullet['owner'] == 'blue' and GAME_MODE_CURRENT == 'BOSS':
                continue
            tracer_hit = False
            if tracer_tail is not None:
                tracer_hit = gr_rect.clipline(tracer_tail[0], tracer_tail[1], bullet['x'], bullet['y'])
            if bullet_rect.colliderect(gr_rect) or swept_rect.colliderect(gr_rect) or tracer_hit:
                if bullet.get('z', 0.0) > tank_height():
                    continue
                if gr_protect_until > now_ms:
                    continue
                if gr_in_smoke and random.random() < smoke_miss_chance:
                    continue
                mult, ricochet = armor_hit_multiplier(bullet, gr_angle)
                if ricochet:
                    explosions.append({'x': bullet['x'], 'y': bullet['y'], 'angle': 0, 't': now_ms, 'r': 10})
                    continue
                green_hits += 1
                green_damage += bullet['damage'] * mult
                if bullet.get('type') == 'cannon' and random.random() < crit_hit_chance:
                    severity = 0.18 if bullet.get('ammo_type') == "HE" else 0.24
                    system = "engine" if random.random() < crit_engine_bias else "turret"
                    crit_events.append({'team': 'green', 'system': system, 'amount': severity})
                if can_contact_detonate or bullet['explode']:
                    explosions.append({'x': bullet['x'], 'y': bullet['y'], 'angle': 0, 't': now_ms, 'r': bullet.get('blast_r')})
                    cannon_hit = True
                continue
        if bullet_rect.right < 0 or bullet_rect.left > frame_x or bullet_rect.bottom < 0 or bullet_rect.top > frame_y:
            continue

        next_bullets.append(bullet)

    # Bullet-bullet collisions
    to_remove = set()
    bullet_rects = [bull.get_rect(center=(b['x'], b['y'])) for b in next_bullets]
    for i in range(len(next_bullets)):
        if i in to_remove:
            continue
        for j in range(i + 1, len(next_bullets)):
            if j in to_remove:
                continue
            if bullet_rects[i].colliderect(bullet_rects[j]):
                bx = (next_bullets[i]['x'] + next_bullets[j]['x']) * 0.5
                by = (next_bullets[i]['y'] + next_bullets[j]['y']) * 0.5
                for idx in (i, j):
                    b = next_bullets[idx]
                    b_is_atgm = b.get('ammo_type') == "ATGM"
                    if b.get('hp') is not None:
                        b['hp'] -= 1
                        if b['hp'] <= 0:
                            if b['explode']:
                                explosions.append({'x': bx, 'y': by, 'angle': 0, 't': now_ms})
                                cannon_hit = True
                            to_remove.add(idx)
                    else:
                        if b['explode']:
                            explosions.append({'x': bx, 'y': by, 'angle': 0, 't': now_ms})
                            cannon_hit = True
                        to_remove.add(idx)
                break

    if to_remove:
        next_bullets = [b for idx, b in enumerate(next_bullets) if idx not in to_remove]

    obstacles[:] = [o for o in obstacles if o.get('hp') is None or o.get('hp', 0) > 0]
    return next_bullets, green_hits, blue_hits, green_damage, blue_damage, explosions, cannon_hit, crit_events

def handle_infantry_bullets(bullets, infantry, gr_rect, bl_rect, obstacles, vehicles, now_ms, dt, gr_in_smoke, bl_in_smoke, gr_protect_until=0, bl_protect_until=0, wind_vec=(0.0, 0.0)):
    next_bullets = []
    explosions = []
    cannon_hit = False
    green_damage = 0.0
    blue_damage = 0.0
    # Wind drift disabled for ballistics/projectiles.
    for bullet in bullets:
        if 'z' not in bullet:
            bullet['z'] = 1.5
        if 'vz' not in bullet:
            bullet['vz'] = 0.0
        if 'gravity' not in bullet:
            bullet['gravity'] = 0.0
        old_x = bullet['x']
        old_y = bullet['y']
        bullet['x'] += bullet['vx'] * dt
        bullet['y'] += bullet['vy'] * dt
        is_atgm_guided = bullet.get('type') == 'apc_at' or bullet.get('ammo_type') == "ATGM"
        if is_atgm_guided:
            bullet['gravity'] = 0.0
            bullet['vz'] = 0.0
            bullet['z'] = max(24.0, bullet.get('z', 24.0))
        else:
            bullet['z'] += bullet['vz'] * dt
            bullet['vz'] -= bullet.get('gravity', 0.0) * dt
        if 'path_x' in bullet:
            bullet['path_x'].append(float(bullet['x']))
            bullet['path_y'].append(float(bullet['y']))
            bullet['path_z'].append(float(bullet['z']))
        if bullet['x'] < -80 or bullet['x'] > frame_x + 80 or bullet['y'] < -80 or bullet['y'] > frame_y + 80:
            continue
        if bullet['z'] <= 0 and not is_atgm_guided:
            if bullet.get('explode'):
                explosions.append({'x': bullet['x'], 'y': bullet['y'], 'angle': 0, 't': now_ms, 'r': bullet.get('blast_r')})
                cannon_hit = True
            continue
        tracer_tail = None
        if bullet.get('type') in ('apc_mg', 'jeep', 'humvee', 'bullet'):
            mag = math.hypot(bullet['vx'], bullet['vy'])
            if mag > 0:
                tracer_tail = (
                    bullet['x'] - (bullet['vx'] / mag) * 12,
                    bullet['y'] - (bullet['vy'] / mag) * 12
                )
        b_rect = pygame.Rect(bullet['x'] - 2, bullet['y'] - 2, 4, 4)
        min_x = min(old_x, bullet['x']) - 2
        min_y = min(old_y, bullet['y']) - 2
        max_x = max(old_x, bullet['x']) + 2
        max_y = max(old_y, bullet['y']) + 2
        swept_rect = pygame.Rect(min_x, min_y, max_x - min_x, max_y - min_y)
        hit_obstacle = False
        for obs in obstacles:
            if b_rect.colliderect(obs['rect']) or swept_rect.colliderect(obs['rect']):
                if bullet.get('z', 0.0) > obstacle_height(obs):
                    continue
                if obs.get('hp') is not None:
                    damage_to_obs = bullet.get('damage', 0.0)
                    if bullet.get('type') == 'apc_at':
                        damage_to_obs *= 1.8
                    obs['hp'] = max(0.0, obs['hp'] - damage_to_obs)
                    if obs['hp'] <= 0:
                        explosions.append({'x': bullet['x'], 'y': bullet['y'], 'angle': 0, 't': now_ms, 'r': max(8, bullet.get('blast_r', 8))})
                        hit_obstacle = True
                    else:
                        hit_obstacle = True
                else:
                    if bullet.get('type') == 'apc_at':
                        if obs.get('otype') == 'building':
                            explosions.append({'x': bullet['x'], 'y': bullet['y'], 'angle': 0, 't': now_ms, 'r': bullet.get('blast_r')})
                            hit_obstacle = True
                        else:
                            continue
                    else:
                        hit_obstacle = True
                break
        if hit_obstacle:
            continue

        tracer_hit = False
        if tracer_tail is not None:
            tracer_hit = gr_rect.clipline(tracer_tail[0], tracer_tail[1], bullet['x'], bullet['y'])
        if b_rect.colliderect(gr_rect) or swept_rect.colliderect(gr_rect) or tracer_hit:
            if bullet.get('z', 0.0) > tank_height():
                continue
            if bullet.get('type') == 'apc_at' and bullet.get('target_team') != "green":
                pass
            elif gr_protect_until <= now_ms and not (gr_in_smoke and random.random() < smoke_miss_chance):
                green_damage += bullet['damage']
                if bullet.get('explode'):
                    explosions.append({'x': bullet['x'], 'y': bullet['y'], 'angle': 0, 't': now_ms, 'r': bullet.get('blast_r')})
                continue
        tracer_hit = False
        if tracer_tail is not None:
            tracer_hit = bl_rect.clipline(tracer_tail[0], tracer_tail[1], bullet['x'], bullet['y'])
        if b_rect.colliderect(bl_rect) or swept_rect.colliderect(bl_rect) or tracer_hit:
            if bullet.get('z', 0.0) > tank_height():
                continue
            if bullet.get('type') == 'apc_at' and bullet.get('target_team') != "blue":
                pass
            elif bl_protect_until <= now_ms and not (bl_in_smoke and random.random() < smoke_miss_chance):
                blue_damage += bullet['damage']
                if bullet.get('explode'):
                    explosions.append({'x': bullet['x'], 'y': bullet['y'], 'angle': 0, 't': now_ms, 'r': bullet.get('blast_r')})
                continue

        hit_infantry = False
        if bullet.get('type') != 'apc_at' or bullet.get('target_kind') == "infantry":
            for unit in infantry:
                if unit.get('protect_until', 0) > now_ms:
                    continue
                if bullet.get('type') == 'apc_at' and bullet.get('target_obj') is not unit:
                    continue
                if bullet.get('z', 0.0) > 18.0:
                    continue
                unit_rect = pygame.Rect(unit['x'] - 6, unit['y'] - 6, 12, 12)
                tracer_hit = False
                if tracer_tail is not None:
                    tracer_hit = unit_rect.clipline(tracer_tail[0], tracer_tail[1], bullet['x'], bullet['y'])
                if tracer_hit or \
                   math.hypot(unit['x'] - bullet['x'], unit['y'] - bullet['y']) <= 6 or \
                   math.hypot(unit['x'] - old_x, unit['y'] - old_y) <= 6:
                    unit['hp'] -= bullet['damage']
                    hit_infantry = True
                    if bullet.get('explode'):
                        explosions.append({'x': bullet['x'], 'y': bullet['y'], 'angle': 0, 't': now_ms, 'r': bullet.get('blast_r')})
                    break
        if hit_infantry:
            continue

        hit_vehicle = False
        if vehicles and (bullet.get('type') != 'apc_at' or bullet.get('target_kind') == "vehicle"):
            for veh in vehicles:
                if veh.get('protect_until', 0) > now_ms:
                    continue
                if bullet.get('type') == 'apc_at' and bullet.get('target_obj') is not veh:
                    continue
                if bullet.get('z', 0.0) > vehicle_height(veh):
                    continue
                vr = apc_rect(veh)
                tracer_hit = False
                if tracer_tail is not None:
                    tracer_hit = vr.clipline(tracer_tail[0], tracer_tail[1], bullet['x'], bullet['y'])
                if vr.colliderect(b_rect) or vr.colliderect(swept_rect) or tracer_hit:
                    veh['hp'] -= bullet['damage']
                    hit_vehicle = True
                    if bullet.get('explode'):
                        explosions.append({'x': bullet['x'], 'y': bullet['y'], 'angle': 0, 't': now_ms, 'r': bullet.get('blast_r')})
                    break
        if hit_vehicle:
            continue

        if b_rect.right < 0 or b_rect.left > frame_x or b_rect.bottom < 0 or b_rect.top > frame_y:
            continue
        next_bullets.append(bullet)
    obstacles[:] = [o for o in obstacles if o.get('hp') is None or o.get('hp', 0) > 0]
    return next_bullets, green_damage, blue_damage, explosions, cannon_hit

def closest_point_on_rect(rect, x, y):
    cx = min(max(x, rect.left), rect.right)
    cy = min(max(y, rect.top), rect.bottom)
    return cx, cy

def projectile_intercept_chance(projectile):
    if projectile.get('ammo_type') == "ATGM" or projectile.get('type') == 'apc_at':
        return intercept_round_chance.get("ATGM", 0.75)
    if projectile.get('type') == 'mg':
        return intercept_round_chance.get("mg", 0.55)
    if projectile.get('type') == 'bullet':
        return 0.35
    return intercept_round_chance.get(projectile.get('ammo_type', "HE"), 0.18)

def try_intercept_air_target(target, bullets, infantry_bullets, now_ms, explosions):
    """Attack drones fly like ATGMs: rounds can swat them down, but AP/HE are unreliable."""
    tx, ty = target['x'], target['y']
    for collection in (bullets, infantry_bullets):
        for proj in collection:
            if proj.get('owner') == target.get('team'):
                continue
            px, py = proj.get('x', -9999), proj.get('y', -9999)
            if math.hypot(px - tx, py - ty) > 20:
                continue
            high_enough = proj.get('z', 0.0) >= 18.0 or proj.get('elev', 0.0) >= 14.0 or proj.get('ammo_type') == "ATGM"
            if not high_enough:
                continue
            if random.random() <= projectile_intercept_chance(proj):
                proj['spent'] = True
                explosions.append({'x': tx, 'y': ty, 'angle': 0, 't': now_ms, 'r': 32})
                return True
    return False

def update_infantry(infantry, grx, gry, blx, bly, obstacles, smokes, now_ms, dt, gr_tank_dead=False, bl_tank_dead=False, gr_spawn=(120,240), bl_spawn=(1160,240), weather_effects=None, think=True, crowd_scale=1.0, commander_teams=None):
    roles = INF_ROLE_STATS
    shots = []
    flashes = []
    remaining = []
    w = weather_effects or WEATHER_EFFECTS["clear"]
    w_speed = w["speed"]
    w_spread = w["spread"]
    w_damage = w["damage"]
    w_reload = w["reload"] * crowd_scale
    for unit in infantry:
        if unit['hp'] <= 0:
            continue
        offscreen = unit['x'] < -ai_offscreen_margin or unit['x'] > frame_x + ai_offscreen_margin or unit['y'] < -ai_offscreen_margin or unit['y'] > frame_y + ai_offscreen_margin
        if offscreen:
            unit['x'] += unit.get('vx', 0.0) * dt
            unit['y'] += unit.get('vy', 0.0) * dt
            remaining.append(unit)
            continue
        if not think:
            unit['x'] += unit.get('vx', 0.0) * dt
            unit['y'] += unit.get('vy', 0.0) * dt
            unit['x'] = max(10, min(frame_x - 10, unit['x']))
            unit['y'] = max(10, min(frame_y - 10, unit['y']))
            remaining.append(unit)
            continue
        info = roles[unit['role']]

        # Target selection with priority
        # Sample enemy list under heavy load to reduce O(n^2)
        step = max(1, int(crowd_scale * 2))
        enemy_infantry = [infantry[i] for i in range(0, len(infantry), step) if infantry[i]['team'] != unit['team']]
        if unit['team'] == 'green':
            enemy_tank_pos = (blx, bly) if not bl_tank_dead else None
            fallback = (bl_spawn[0], bl_spawn[1]) if bl_tank_dead else None
        else:
            enemy_tank_pos = (grx, gry) if not gr_tank_dead else None
            fallback = (gr_spawn[0], gr_spawn[1]) if gr_tank_dead else None

        if unit['role'] in ['at']:
            if enemy_tank_pos:
                target = enemy_tank_pos
            elif enemy_infantry:
                target = (enemy_infantry[0]['x'], enemy_infantry[0]['y'])
            else:
                target = fallback
        else:
            if enemy_infantry:
                target = (enemy_infantry[0]['x'], enemy_infantry[0]['y'])
            elif enemy_tank_pos:
                target = enemy_tank_pos
            else:
                target = fallback

        if target is None:
            remaining.append(unit)
            continue

        cmd = unit.get('cmd')
        if commander_teams and unit['team'] in commander_teams and cmd is not None:
            cmd_x, cmd_y = cmd
            best_enemy = None
            best_d = 1e9
            for e in enemy_infantry:
                d = math.hypot(e['x'] - cmd_x, e['y'] - cmd_y)
                if d < best_d:
                    best_d = d
                    best_enemy = (e['x'], e['y'])
            if unit['team'] == 'green' and not bl_tank_dead:
                d = math.hypot(blx - cmd_x, bly - cmd_y)
                if d < best_d:
                    best_d = d
                    best_enemy = (blx, bly)
            if unit['team'] == 'blue' and not gr_tank_dead:
                d = math.hypot(grx - cmd_x, gry - cmd_y)
                if d < best_d:
                    best_d = d
                    best_enemy = (grx, gry)
            if best_enemy is not None and best_d <= 260:
                target = best_enemy
            else:
                target = (cmd_x, cmd_y)
        dx = target[0] - unit['x']
        dy = target[1] - unit['y']
        dist = math.hypot(dx, dy)
        if dist > 0:
            unit['angle'] = math.degrees(math.atan2(-dy, dx))

        # Check line of sight to target
        # Count enemy vs friendly to determine aggression
        if crowd_scale > 1.35:
            friendly_count = sum(1 for i in range(0, len(infantry), step) if infantry[i]['team'] == unit['team'])
            enemy_count = sum(1 for i in range(0, len(infantry), step) if infantry[i]['team'] != unit['team'])
            friendly_count *= step
            enemy_count *= step
        else:
            friendly_count = sum(1 for u in infantry if u['team'] == unit['team'])
            enemy_count = sum(1 for u in infantry if u['team'] != unit['team'])
        outnumber_enemy = friendly_count > enemy_count

        # Check line of sight to target
        has_los = True
        blocking_obs = None
        for obs in obstacles:
            if obs['rect'].clipline(unit['x'], unit['y'], target[0], target[1]):
                has_los = False
                blocking_obs = obs
                break

        move_x = 0.0
        move_y = 0.0

        in_cover = False
        if not has_los and blocking_obs is not None and not outnumber_enemy:
            # Find best cover point — side of obstacle facing unit
            cx, cy = closest_point_on_rect(blocking_obs['rect'], unit['x'], unit['y'])
            # Offset slightly away from obstacle edge to stand behind it
            cover_dx = unit['x'] - cx
            cover_dy = unit['y'] - cy
            cover_d = math.hypot(cover_dx, cover_dy)
            if cover_d > 0:
                cover_x = cx + (cover_dx / cover_d) * 14
                cover_y = cy + (cover_dy / cover_d) * 14
            else:
                cover_x = unit['x']
                cover_y = unit['y']
            cover_x = max(10, min(frame_x - 10, cover_x))
            cover_y = max(10, min(frame_y - 10, cover_y))
            to_cover_x = cover_x - unit['x']
            to_cover_y = cover_y - unit['y']
            to_cover_d = math.hypot(to_cover_x, to_cover_y)
            if to_cover_d > 6:
                # Move to cover
                move_x += (to_cover_x / to_cover_d) * info['spd'] * w_speed
                move_y += (to_cover_y / to_cover_d) * info['spd'] * w_speed
            else:
                in_cover = True

        if has_los or in_cover:
            # Advance if out of range, hold position if in range and in cover
            if dist > info['rng'] * 0.85:
                if dist > 0:
                    move_x += (dx / dist) * info['spd'] * w_speed
                    move_y += (dy / dist) * info['spd'] * w_speed
            elif dist < info['rng'] * 0.4 and not in_cover:
                # Back up if too close and not in cover
                if dist > 0:
                    move_x -= (dx / dist) * info['spd'] * 0.5 * w_speed
                    move_y -= (dy / dist) * info['spd'] * 0.5 * w_speed

        # KOTH objective pressure: all AI infantry except AT specialists push/hold hill.
        if GAME_MODE_CURRENT == "KOTH" and unit['role'] != 'at':
            hx, hy = KOTH_CENTER
            hd_x = hx - unit['x']
            hd_y = hy - unit['y']
            hd = math.hypot(hd_x, hd_y)
            if hd > KOTH_RADIUS * 0.72 and hd > 0:
                move_x += (hd_x / hd) * info['spd'] * 1.15 * w_speed
                move_y += (hd_y / hd) * info['spd'] * 1.15 * w_speed
        elif GAME_MODE_CURRENT == "SIEGE":
            bx, by = SIEGE_BLUE_BASE if unit['team'] == 'green' else SIEGE_GREEN_BASE
            bd_x = bx - unit['x']
            bd_y = by - unit['y']
            bd = math.hypot(bd_x, bd_y)
            if bd > info['rng'] * 0.8 and bd > 0:
                move_x += (bd_x / bd) * info['spd'] * 1.08 * w_speed
                move_y += (bd_y / bd) * info['spd'] * 1.08 * w_speed

        # Obstacle avoidance — don't walk into rocks
        if crowd_scale <= 1.5:
            for obs in obstacles:
                rect = obs['rect']
                ocx, ocy = closest_point_on_rect(rect, unit['x'], unit['y'])
                ddx = unit['x'] - ocx
                ddy = unit['y'] - ocy
                d = math.hypot(ddx, ddy)
                if d < 16 and d > 0:
                    move_x += (ddx / d) * info['spd'] * 1.2 * w_speed
                    move_y += (ddy / d) * info['spd'] * 1.2 * w_speed

        # Separation from friendly units
        if crowd_scale <= 1.35:
            for other in infantry:
                if other is unit:
                    continue
                if other['team'] != unit['team']:
                    continue
                sep_dx = unit['x'] - other['x']
                sep_dy = unit['y'] - other['y']
                sep_d = math.hypot(sep_dx, sep_dy)
                if sep_d < 14 and sep_d > 0:
                    move_x += (sep_dx / sep_d) * info['spd'] * 0.6 * w_speed
                    move_y += (sep_dy / sep_d) * info['spd'] * 0.6 * w_speed

        if move_x != 0 or move_y != 0:
            mag = math.hypot(move_x, move_y)
            unit['vx'] = (move_x / mag) * info['spd'] * w_speed
            unit['vy'] = (move_y / mag) * info['spd'] * w_speed
            unit['x'] += unit['vx'] * dt
            unit['y'] += unit['vy'] * dt
            unit['last_active'] = now_ms
        else:
            unit['vx'] = 0.0
            unit['vy'] = 0.0
        unit['x'] = max(10, min(frame_x - 10, unit['x']))
        unit['y'] = max(10, min(frame_y - 10, unit['y']))

        # Only fire if has line of sight or is AT (fires regardless)
        can_fire = has_los or unit['role'] == 'at'
        if can_fire and dist <= info['rng'] and (now_ms - unit['last_shot']) >= info['cd'] * w_reload:
            if dist > 0:
                vx = (dx / dist) * info['spd_b'] * w_speed
                vy = (dy / dist) * info['spd_b'] * w_speed
            else:
                vx, vy = 0.0, 0.0
            unit['angle'] = math.degrees(math.atan2(-dy, dx)) if dist > 0 else unit.get('angle', 0.0)
            if is_in_smoke(target[0], target[1], smokes, now_ms):
                jitter = math.radians(random.uniform(-smoke_aim_jitter * w_spread, smoke_aim_jitter * w_spread))
                cos_j = math.cos(jitter)
                sin_j = math.sin(jitter)
                vx, vy = (vx * cos_j - vy * sin_j), (vx * sin_j + vy * cos_j)
            shot_type = 'apc_at' if unit['role'] == 'at' else 'bullet'
            target_team = "blue" if unit['team'] == "green" else "green"
            shots.append({
                'x': unit['x'],
                'y': unit['y'],
                'vx': vx,
                'vy': vy,
                'damage': info['dmg'] * w_damage,
                'owner': unit['team'],
                'type': shot_type,
                'role': unit['role'],
                'explode': unit['role'] == 'at',
                'blast_r': 40 if unit['role'] == 'at' else 0,
                'target_team': target_team,
                'target_kind': 'tank',
                'ammo_type': "ATGM" if unit['role'] == 'at' else None,
                'z': 28.0 if unit['role'] == 'at' else 1.5,
                't0': now_ms,
                'wind_scale': 0.7,
            })
            if unit['role'] == 'at':
                flashes.append({
                    'x': unit['x'],
                    'y': unit['y'],
                    'angle': math.degrees(math.atan2(-vy, vx)) if dist > 0 else 0,
                    't': now_ms,
                    'scale': 0.5,
                })
            if mg_sound:
                mg_sound.play()
            unit['last_shot'] = now_ms
            unit['last_active'] = now_ms
        remaining.append(unit)
    return remaining, shots, flashes

def update_apcs(apcs, grx, gry, blx, bly, obstacles, smokes, now_ms, dt, gr_tank_dead=False, bl_tank_dead=False, infantry=None, reinforcements_enabled=True, vehicles=None, weather_effects=None, think=True, crowd_scale=1.0, reinf_green=True, reinf_blue=True, commander_teams=None):
    shots = []
    new_infantry = []
    remaining = []
    w = weather_effects or WEATHER_EFFECTS["clear"]
    w_speed = w["speed"]
    w_damage = w["damage"]
    w_reload = w["reload"] * crowd_scale
    for apc in apcs:
        if apc['hp'] <= 0:
            continue
        offscreen = apc['x'] < -ai_offscreen_margin or apc['x'] > frame_x + ai_offscreen_margin or apc['y'] < -ai_offscreen_margin or apc['y'] > frame_y + ai_offscreen_margin
        if offscreen:
            apc['x'] += apc.get('vx', 0.0) * dt
            apc['y'] += apc.get('vy', 0.0) * dt
            remaining.append(apc)
            continue
        if not think:
            apc['x'] += apc.get('vx', 0.0) * dt
            apc['y'] += apc.get('vy', 0.0) * dt
            remaining.append(apc)
            continue
        # Big guns: tank > vehicles > infantry
        enemy_inf = [u for u in infantry if u['team'] != apc['team']] if infantry else []
        if apc['team'] == 'green' and not bl_tank_dead:
            target = (blx, bly)
        elif apc['team'] == 'blue' and not gr_tank_dead:
            target = (grx, gry)
        elif enemy_inf:
            target = (enemy_inf[0]['x'], enemy_inf[0]['y'])
        else:
            target = (blx, bly) if apc['team'] == 'green' else (grx, gry)
        cmd = apc.get('cmd')
        if commander_teams and apc['team'] in commander_teams and cmd is not None:
            cmd_x, cmd_y = cmd
            best_enemy = None
            best_d = 1e9
            for e in enemy_inf:
                d = math.hypot(e['x'] - cmd_x, e['y'] - cmd_y)
                if d < best_d:
                    best_d = d
                    best_enemy = (e['x'], e['y'])
            if apc['team'] == 'green' and not bl_tank_dead:
                d = math.hypot(blx - cmd_x, bly - cmd_y)
                if d < best_d:
                    best_d = d
                    best_enemy = (blx, bly)
            if apc['team'] == 'blue' and not gr_tank_dead:
                d = math.hypot(grx - cmd_x, gry - cmd_y)
                if d < best_d:
                    best_d = d
                    best_enemy = (grx, gry)
            if best_enemy is not None and best_d <= 380:
                target = best_enemy
            else:
                target = cmd
        dx = target[0] - apc['x']
        dy = target[1] - apc['y']
        dist = math.hypot(dx, dy)
        move_x = 0.0
        move_y = 0.0
        if dist > 0:
            target_ang = math.degrees(math.atan2(-dy, dx))
            apc['angle'] = target_ang
            apc['turret_angle'] = approach_angle(apc.get('turret_angle', target_ang), target_ang, 140 * dt * w_speed)
        if GAME_MODE_CURRENT == "KOTH":
            hx, hy = KOTH_CENTER
            hdx = hx - apc['x']
            hdy = hy - apc['y']
            hdist = math.hypot(hdx, hdy)
            if hdist > KOTH_RADIUS * 0.78 and hdist > 0:
                move_x += (hdx / hdist) * apc_speed * 1.1 * w_speed
                move_y += (hdy / hdist) * apc_speed * 1.1 * w_speed
        elif GAME_MODE_CURRENT == "SIEGE":
            bx, by = SIEGE_BLUE_BASE if apc['team'] == 'green' else SIEGE_GREEN_BASE
            bdx = bx - apc['x']
            bdy = by - apc['y']
            bdist = math.hypot(bdx, bdy)
            if bdist > apc_range * 0.7 and bdist > 0:
                move_x += (bdx / bdist) * apc_speed * 1.06 * w_speed
                move_y += (bdy / bdist) * apc_speed * 1.06 * w_speed
        elif dist > apc_range * 0.8:
            if dist > 0:
                target_ang = math.degrees(math.atan2(-dy, dx))
                diff = (target_ang - apc['angle'] + 540) % 360 - 180
                apc['angle'] = (apc['angle'] + math.copysign(min(abs(diff), 120 * dt * w_speed), diff)) % 360
                move_x += (dx / dist) * apc_speed * w_speed
                move_y += (dy / dist) * apc_speed * w_speed

        if crowd_scale <= 1.4:
            for obs in obstacles:
                rect = obs['rect']
                cx, cy = closest_point_on_rect(rect, apc['x'], apc['y'])
                ddx = apc['x'] - cx
                ddy = apc['y'] - cy
                d = math.hypot(ddx, ddy)
                if d < apc_avoid_dist and d > 0:
                    move_x += (ddx / d) * apc_speed * w_speed
                    move_y += (ddy / d) * apc_speed * w_speed

        if move_x != 0 or move_y != 0:
            mag = math.hypot(move_x, move_y)
            apc['vx'] = (move_x / mag) * apc_speed * w_speed
            apc['vy'] = (move_y / mag) * apc_speed * w_speed
            apc['x'] += apc['vx'] * dt
            apc['y'] += apc['vy'] * dt
            apc['last_active'] = now_ms
        else:
            apc['vx'] = 0.0
            apc['vy'] = 0.0

        # Suppressive fire
        if dist <= apc_range and (now_ms - apc['last_shot']) >= apc_fire_cd * w_reload:
            if dist > 0:
                vx = (dx / dist) * apc_fire_spd * w_speed
                vy = (dy / dist) * apc_fire_spd * w_speed
            else:
                vx, vy = 0.0, 0.0
            if is_in_smoke(target[0], target[1], smokes, now_ms):
                jitter = math.radians(random.uniform(-smoke_aim_jitter, smoke_aim_jitter))
                cos_j = math.cos(jitter)
                sin_j = math.sin(jitter)
                vx, vy = (vx * cos_j - vy * sin_j), (vx * sin_j + vy * cos_j)
            shots.append({
                'x': apc['x'],
                'y': apc['y'],
                'vx': vx,
                'vy': vy,
                'damage': apc_fire_dmg * w_damage,
                'owner': apc['team'],
                'type': 'apc_mg',
                'explode': False,
                'wind_scale': 0.55,
            })
            apc['last_shot'] = now_ms
            apc['last_active'] = now_ms

        # AT missile (prioritize tanks, then APC > humvee > jeep > infantry)
        if dist <= apc_range * 1.1 and apc.get('at_ammo', 0) > 0 and (now_ms - apc.get('last_at', 0)) >= apc_at_cd * w_reload:
            at_target = None
            target_team = None
            target_obj = None
            target_kind = None
            if apc['team'] == 'green' and not bl_tank_dead:
                at_target = (blx, bly)
                target_team = "blue"
                target_kind = "tank"
            elif apc['team'] == 'blue' and not gr_tank_dead:
                at_target = (grx, gry)
                target_team = "green"
                target_kind = "tank"
            else:
                enemy_veh = []
                if vehicles:
                    for v in vehicles:
                        if v['team'] != apc['team'] and v['hp'] > 0:
                            enemy_veh.append(v)
                if enemy_veh:
                    priority = {"apc": 3, "humvee": 2, "jeep": 1}
                    enemy_veh.sort(key=lambda v: priority.get(v.get('type', ''), 0), reverse=True)
                    target_obj = enemy_veh[0]
                    target_kind = "vehicle"
                    at_target = (target_obj['x'], target_obj['y'])
                else:
                    enemy_inf = [u for u in infantry if u['team'] != apc['team']] if infantry else []
                    if enemy_inf:
                        target_obj = enemy_inf[0]
                        target_kind = "infantry"
                        at_target = (target_obj['x'], target_obj['y'])
            if at_target is None:
                at_target = (target[0], target[1])
            at_dx = at_target[0] - apc['x']
            at_dy = at_target[1] - apc['y']
            at_dist = math.hypot(at_dx, at_dy)
            if at_dist > 0:
                vx = (at_dx / at_dist) * apc_at_spd * w_speed
                vy = (at_dy / at_dist) * apc_at_spd * w_speed
            else:
                vx, vy = 0.0, 0.0
            ang = math.atan2(-at_dy, at_dx) if at_dist > 0 else 0.0
            # Spawn from a side-mounted tube (not the barrel)
            spawn_x = apc['x'] + math.cos(ang) * -6 + math.cos(ang + math.pi / 2) * 8
            spawn_y = apc['y'] - math.sin(ang) * -6 - math.sin(ang + math.pi / 2) * 8
            shots.append({
                'x': spawn_x,
                'y': spawn_y,
                'vx': vx,
                'vy': vy,
                'angle': math.degrees(ang),
                'damage': apc_at_dmg * w_damage,
                'owner': apc['team'],
                'type': 'apc_at',
                'ammo_type': 'ATGM',
                'explode': True,
                'len': 18,
                'wid': 8,
                'scale': 1.35,
                'target_team': target_team,
                'target_obj': target_obj,
                'target_kind': target_kind,
                'wind_scale': 0.12,
            })
            apc['last_at'] = now_ms
            apc['at_ammo'] = max(0, apc.get('at_ammo', 0) - 1)
            apc['last_active'] = now_ms

        # Deploy infantry from APC position
        team_reinf_ok = reinf_green if apc['team'] == 'green' else reinf_blue
        if reinforcements_enabled and team_reinf_ok and (now_ms - apc['last_drop']) >= apc_deploy_cd:
            for _ in range(apc_deploy_count):
                role = random.choice(list(INF_ROLE_STATS.keys()))
                new_infantry.append({
                    'x': apc['x'] + random.uniform(-18, 18),
                    'y': apc['y'] + random.uniform(-18, 18),
                    'team': apc['team'],
                    'role': role,
                    'hp': INF_ROLE_STATS[role]['hp'],
                    'hp_max': INF_ROLE_STATS[role]['hp'],
                    'last_shot': 0,
                    'mortar_err': random.uniform(-60, 60) if role == 'mortar' else 0.0,
                    'protect_until': now_ms + spawn_protect_ms,
                    'spawn_t': now_ms,
                    'last_active': now_ms,
                    'vx': 0.0,
                    'vy': 0.0,
                })
            apc['last_drop'] = now_ms
        remaining.append(apc)
    return remaining, shots, new_infantry

def update_jeeps(jeeps, grx, gry, blx, bly, obstacles, smokes, now_ms, dt, gr_tank_dead=False, bl_tank_dead=False, infantry=None, weather_effects=None, think=True, crowd_scale=1.0, commander_teams=None):
    shots = []
    remaining = []
    w = weather_effects or WEATHER_EFFECTS["clear"]
    w_speed = w["speed"]
    w_damage = w["damage"]
    w_reload = w["reload"] * crowd_scale
    for jeep in jeeps:
        if jeep['hp'] <= 0:
            continue
        offscreen = jeep['x'] < -ai_offscreen_margin or jeep['x'] > frame_x + ai_offscreen_margin or jeep['y'] < -ai_offscreen_margin or jeep['y'] > frame_y + ai_offscreen_margin
        if offscreen:
            jeep['x'] += jeep.get('vx', 0.0) * dt
            jeep['y'] += jeep.get('vy', 0.0) * dt
            remaining.append(jeep)
            continue
        if not think:
            jeep['x'] += jeep.get('vx', 0.0) * dt
            jeep['y'] += jeep.get('vy', 0.0) * dt
            remaining.append(jeep)
            continue
        # Small arms: infantry > vehicles > tank
        enemy_inf = [u for u in infantry if u['team'] != jeep['team']] if infantry else []
        if enemy_inf:
            target = (enemy_inf[0]['x'], enemy_inf[0]['y'])
        elif jeep['team'] == 'green' and not bl_tank_dead:
            target = (blx, bly)
        elif jeep['team'] == 'blue' and not gr_tank_dead:
            target = (grx, gry)
        else:
            target = (blx, bly) if jeep['team'] == 'green' else (grx, gry)
        cmd = jeep.get('cmd')
        if commander_teams and jeep['team'] in commander_teams and cmd is not None:
            cmd_x, cmd_y = cmd
            best_enemy = None
            best_d = 1e9
            for e in enemy_inf:
                d = math.hypot(e['x'] - cmd_x, e['y'] - cmd_y)
                if d < best_d:
                    best_d = d
                    best_enemy = (e['x'], e['y'])
            if jeep['team'] == 'green' and not bl_tank_dead:
                d = math.hypot(blx - cmd_x, bly - cmd_y)
                if d < best_d:
                    best_d = d
                    best_enemy = (blx, bly)
            if jeep['team'] == 'blue' and not gr_tank_dead:
                d = math.hypot(grx - cmd_x, gry - cmd_y)
                if d < best_d:
                    best_d = d
                    best_enemy = (grx, gry)
            if best_enemy is not None and best_d <= 340:
                target = best_enemy
            else:
                target = cmd
        dx = target[0] - jeep['x']
        dy = target[1] - jeep['y']
        dist = math.hypot(dx, dy)
        move_x = 0.0
        move_y = 0.0
        if dist > 0:
            target_ang = math.degrees(math.atan2(-dy, dx))
            jeep['turret_angle'] = approach_angle(jeep.get('turret_angle', target_ang), target_ang, 160 * dt * w_speed)
        if GAME_MODE_CURRENT == "KOTH":
            hx, hy = KOTH_CENTER
            hdx = hx - jeep['x']
            hdy = hy - jeep['y']
            hdist = math.hypot(hdx, hdy)
            if hdist > KOTH_RADIUS * 0.82 and hdist > 0:
                move_x += (hdx / hdist) * jeep_speed * 1.1 * w_speed
                move_y += (hdy / hdist) * jeep_speed * 1.1 * w_speed
        elif GAME_MODE_CURRENT == "SIEGE":
            bx, by = SIEGE_BLUE_BASE if jeep['team'] == 'green' else SIEGE_GREEN_BASE
            bdx = bx - jeep['x']
            bdy = by - jeep['y']
            bdist = math.hypot(bdx, bdy)
            if bdist > jeep_range * 0.7 and bdist > 0:
                move_x += (bdx / bdist) * jeep_speed * 1.05 * w_speed
                move_y += (bdy / bdist) * jeep_speed * 1.05 * w_speed
        elif dist > jeep_range * 0.9:
            if dist > 0:
                diff = (target_ang - jeep.get('angle', 0) + 540) % 360 - 180
                jeep['angle'] = (jeep.get('angle', 0) + math.copysign(min(abs(diff), 120 * dt * w_speed), diff)) % 360
                move_x += (dx / dist) * jeep_speed * w_speed
                move_y += (dy / dist) * jeep_speed * w_speed
        if crowd_scale <= 1.4:
            for obs in obstacles:
                rect = obs['rect']
                cx, cy = closest_point_on_rect(rect, jeep['x'], jeep['y'])
                ddx = jeep['x'] - cx
                ddy = jeep['y'] - cy
                d = math.hypot(ddx, ddy)
                if d < apc_avoid_dist and d > 0:
                    move_x += (ddx / d) * jeep_speed * w_speed
                    move_y += (ddy / d) * jeep_speed * w_speed
        if move_x != 0 or move_y != 0:
            mag = math.hypot(move_x, move_y)
            jeep['vx'] = (move_x / mag) * jeep_speed * w_speed
            jeep['vy'] = (move_y / mag) * jeep_speed * w_speed
            jeep['x'] += jeep['vx'] * dt
            jeep['y'] += jeep['vy'] * dt
            jeep['last_active'] = now_ms
        else:
            jeep['vx'] = 0.0
            jeep['vy'] = 0.0
        if dist <= jeep_range and (now_ms - jeep['last_shot']) >= jeep_fire_cd * w_reload:
            if dist > 0:
                vx = (dx / dist) * jeep_fire_spd * w_speed
                vy = (dy / dist) * jeep_fire_spd * w_speed
            else:
                vx, vy = 0.0, 0.0
            if is_in_smoke(target[0], target[1], smokes, now_ms):
                jitter = math.radians(random.uniform(-smoke_aim_jitter, smoke_aim_jitter))
                cos_j = math.cos(jitter)
                sin_j = math.sin(jitter)
                vx, vy = (vx * cos_j - vy * sin_j), (vx * sin_j + vy * cos_j)
            shots.append({
                'x': jeep['x'],
                'y': jeep['y'],
                'vx': vx,
                'vy': vy,
                'damage': jeep_fire_dmg * w_damage,
                'owner': jeep['team'],
                'type': 'jeep',
                'explode': False,
                'wind_scale': 0.65,
            })
            jeep['last_shot'] = now_ms
            jeep['last_active'] = now_ms
        remaining.append(jeep)
    return remaining, shots

def update_humvees(humvees, grx, gry, blx, bly, obstacles, smokes, now_ms, dt, gr_tank_dead=False, bl_tank_dead=False, infantry=None, weather_effects=None, think=True, crowd_scale=1.0, commander_teams=None):
    shots = []
    remaining = []
    w = weather_effects or WEATHER_EFFECTS["clear"]
    w_speed = w["speed"]
    w_damage = w["damage"]
    w_reload = w["reload"] * crowd_scale
    for hv in humvees:
        if hv['hp'] <= 0:
            continue
        offscreen = hv['x'] < -ai_offscreen_margin or hv['x'] > frame_x + ai_offscreen_margin or hv['y'] < -ai_offscreen_margin or hv['y'] > frame_y + ai_offscreen_margin
        if offscreen:
            hv['x'] += hv.get('vx', 0.0) * dt
            hv['y'] += hv.get('vy', 0.0) * dt
            remaining.append(hv)
            continue
        if not think:
            hv['x'] += hv.get('vx', 0.0) * dt
            hv['y'] += hv.get('vy', 0.0) * dt
            remaining.append(hv)
            continue
        # Small arms: infantry > vehicles > tank
        enemy_inf = [u for u in infantry if u['team'] != hv['team']] if infantry else []
        if enemy_inf:
            target = (enemy_inf[0]['x'], enemy_inf[0]['y'])
        elif hv['team'] == 'green' and not bl_tank_dead:
            target = (blx, bly)
        elif hv['team'] == 'blue' and not gr_tank_dead:
            target = (grx, gry)
        else:
            target = (blx, bly) if hv['team'] == 'green' else (grx, gry)
        cmd = hv.get('cmd')
        if commander_teams and hv['team'] in commander_teams and cmd is not None:
            cmd_x, cmd_y = cmd
            best_enemy = None
            best_d = 1e9
            for e in enemy_inf:
                d = math.hypot(e['x'] - cmd_x, e['y'] - cmd_y)
                if d < best_d:
                    best_d = d
                    best_enemy = (e['x'], e['y'])
            if hv['team'] == 'green' and not bl_tank_dead:
                d = math.hypot(blx - cmd_x, bly - cmd_y)
                if d < best_d:
                    best_d = d
                    best_enemy = (blx, bly)
            if hv['team'] == 'blue' and not gr_tank_dead:
                d = math.hypot(grx - cmd_x, gry - cmd_y)
                if d < best_d:
                    best_d = d
                    best_enemy = (grx, gry)
            if best_enemy is not None and best_d <= 340:
                target = best_enemy
            else:
                target = cmd
        dx = target[0] - hv['x']
        dy = target[1] - hv['y']
        dist = math.hypot(dx, dy)
        move_x = 0.0
        move_y = 0.0
        if dist > 0:
            target_ang = math.degrees(math.atan2(-dy, dx))
            hv['turret_angle'] = approach_angle(hv.get('turret_angle', target_ang), target_ang, 150 * dt * w_speed)
        if GAME_MODE_CURRENT == "KOTH":
            hx, hy = KOTH_CENTER
            hdx = hx - hv['x']
            hdy = hy - hv['y']
            hdist = math.hypot(hdx, hdy)
            if hdist > KOTH_RADIUS * 0.82 and hdist > 0:
                move_x += (hdx / hdist) * humvee_speed * 1.1 * w_speed
                move_y += (hdy / hdist) * humvee_speed * 1.1 * w_speed
        elif GAME_MODE_CURRENT == "SIEGE":
            bx, by = SIEGE_BLUE_BASE if hv['team'] == 'green' else SIEGE_GREEN_BASE
            bdx = bx - hv['x']
            bdy = by - hv['y']
            bdist = math.hypot(bdx, bdy)
            if bdist > humvee_range * 0.7 and bdist > 0:
                move_x += (bdx / bdist) * humvee_speed * 1.05 * w_speed
                move_y += (bdy / bdist) * humvee_speed * 1.05 * w_speed
        elif dist > humvee_range * 0.9:
            if dist > 0:
                diff = (target_ang - hv.get('angle', 0) + 540) % 360 - 180
                hv['angle'] = (hv.get('angle', 0) + math.copysign(min(abs(diff), 120 * dt * w_speed), diff)) % 360
                move_x += (dx / dist) * humvee_speed * w_speed
                move_y += (dy / dist) * humvee_speed * w_speed
        if crowd_scale <= 1.4:
            for obs in obstacles:
                rect = obs['rect']
                cx, cy = closest_point_on_rect(rect, hv['x'], hv['y'])
                ddx = hv['x'] - cx
                ddy = hv['y'] - cy
                d = math.hypot(ddx, ddy)
                if d < apc_avoid_dist and d > 0:
                    move_x += (ddx / d) * humvee_speed * w_speed
                    move_y += (ddy / d) * humvee_speed * w_speed
        if move_x != 0 or move_y != 0:
            mag = math.hypot(move_x, move_y)
            hv['vx'] = (move_x / mag) * humvee_speed * w_speed
            hv['vy'] = (move_y / mag) * humvee_speed * w_speed
            hv['x'] += hv['vx'] * dt
            hv['y'] += hv['vy'] * dt
            hv['last_active'] = now_ms
        else:
            hv['vx'] = 0.0
            hv['vy'] = 0.0
        if dist <= humvee_range and (now_ms - hv['last_shot']) >= humvee_fire_cd * w_reload:
            if dist > 0:
                vx = (dx / dist) * humvee_fire_spd * w_speed
                vy = (dy / dist) * humvee_fire_spd * w_speed
            else:
                vx, vy = 0.0, 0.0
            if is_in_smoke(target[0], target[1], smokes, now_ms):
                jitter = math.radians(random.uniform(-smoke_aim_jitter, smoke_aim_jitter))
                cos_j = math.cos(jitter)
                sin_j = math.sin(jitter)
                vx, vy = (vx * cos_j - vy * sin_j), (vx * sin_j + vy * cos_j)
            shots.append({
                'x': hv['x'],
                'y': hv['y'],
                'vx': vx,
                'vy': vy,
                'damage': humvee_fire_dmg * w_damage,
                'owner': hv['team'],
                'type': 'humvee',
                'explode': False,
                'wind_scale': 0.6,
            })
            hv['last_shot'] = now_ms
            hv['last_active'] = now_ms
        remaining.append(hv)
    return remaining, shots

def gr_move(grx, gry, angle, vel, dt):
    rad = math.radians(angle)
    grx += math.cos(rad) * vel * dt
    gry -= math.sin(rad) * vel * dt
    return grx, gry

def bl_move(blx, bly, angle, vel, dt):
    rad = math.radians(angle)
    blx += math.cos(rad) * vel * dt
    bly -= math.sin(rad) * vel * dt
    return blx, bly

def clamp_position(x, y, rect):
    if rect.left < 0:
        x -= rect.left
    if rect.right > frame_x:
        x -= (rect.right - frame_x)
    if rect.top < 0:
        y -= rect.top
    if rect.bottom > frame_y:
        y -= (rect.bottom - frame_y)
    return x, y

def apc_rect(apc):
    t = apc.get('type', 'apc')
    if t == 'jeep':
        w, h = jeep_w, jeep_h
    elif t == 'humvee':
        w, h = humvee_w, humvee_h
    else:
        w, h = apc_w, apc_h
    return pygame.Rect(apc['x'] - w // 2, apc['y'] - h // 2, w, h)

def tank_forward(angle_deg):
    rad = math.radians(angle_deg)
    return math.cos(rad), -math.sin(rad)

def approach_angle(current, target, max_step):
    delta = (target - current + 540) % 360 - 180
    if abs(delta) <= max_step:
        return target
    return (current + max_step * (1 if delta > 0 else -1)) % 360

def make_obstacles(theme):
    obstacles = []
    rock_color = theme['rock']

    def add_rocks(count, x_range=(180,1100), y_range=(140, frame_y-140), scale_range=(0.4,0.6)):
        rock_shapes = [
            [(0,0),(70,-10),(110,30),(90,80),(10,70)],
            [(0,0),(80,-20),(120,40),(90,100),(20,80)],
            [(0,0),(60,-15),(90,20),(70,70),(10,60)],
            [(0,0),(75,-5),(115,35),(95,90),(15,75)],
        ]
        for _ in range(count):
            pts = random.choice(rock_shapes)
            scale = random.uniform(*scale_range)
            angle = random.uniform(0,360)
            tx = random.randint(*x_range)
            ty = random.randint(*y_range)
            scaled = [(p[0]*scale, p[1]*scale) for p in pts]
            rad = math.radians(angle)
            cos_a, sin_a = math.cos(rad), math.sin(rad)
            rotated = [(x*cos_a - y*sin_a + tx, x*sin_a + y*cos_a + ty) for x,y in scaled]
            rect = pygame.Rect(rotated[0],(0,0))
            for p in rotated[1:]:
                rect.union_ip(pygame.Rect(p,(0,0)))
            rect.inflate_ip(-OBSTACLE_HITBOX_INSET, -OBSTACLE_HITBOX_INSET)
            obstacles.append({'points': rotated, 'rect': rect, 'color': rock_color, 'otype': 'rock'})

    def add_fieldworks():
        trench_col = (95, 70, 45) if theme is DESERT else (65, 55, 45)
        ditch_col = (45, 35, 28)
        count = random.randint(1, 2)
        for _ in range(count):
            for _try in range(35):
                cx = random.randint(230, frame_x - 230)
                cy = random.randint(150, frame_y - 130)
                if math.hypot(cx - 120, cy - 240) < 180 or math.hypot(cx - 1160, cy - 240) < 180:
                    continue
                angle = random.choice([0, 18, -18, 162, 198]) + random.uniform(-8, 8)
                length = random.randint(210, 330)
                width = random.randint(24, 32)
                pts = rect_poly(cx, cy, length, width, angle)
                rect = points_rect(pts)
                if any(rect.colliderect(o['rect']) and o.get('otype') in ('building', 'crater') for o in obstacles):
                    continue
                obstacles.append({'points': pts, 'rect': rect, 'color': trench_col, 'otype': 'trench',
                                  'angle': angle, 'width': width, 'length': length})
                # One MG firing step/emplacement per trench.
                em_ang = angle if random.random() < 0.5 else angle + 180
                ex = cx + math.cos(math.radians(angle)) * random.uniform(-length * 0.28, length * 0.28)
                ey = cy + math.sin(math.radians(angle)) * random.uniform(-length * 0.28, length * 0.28)
                epts = rect_poly(ex, ey, 30, 18, angle)
                obstacles.append({'points': epts, 'rect': points_rect(epts), 'color': trench_col, 'otype': 'emplacement',
                                  'angle': angle, 'turret_angle': em_ang, 'last_shot': 0, 'operator': None})
                break
        if random.random() < 0.55:
            for _try in range(35):
                cx = random.randint(240, frame_x - 240)
                cy = random.randint(150, frame_y - 130)
                if math.hypot(cx - 120, cy - 240) < 190 or math.hypot(cx - 1160, cy - 240) < 190:
                    continue
                angle = random.uniform(-25, 25)
                length = random.randint(230, 360)
                width = random.randint(26, 34)
                pts = rect_poly(cx, cy, length, width, angle)
                rect = points_rect(pts)
                if any(rect.colliderect(o['rect']) and o.get('otype') in ('building', 'crater') for o in obstacles):
                    continue
                obstacles.append({'points': pts, 'rect': rect, 'color': ditch_col, 'otype': 'ditch',
                                  'angle': angle, 'width': width, 'length': length, 'fill': 0.0})
                break

    def add_trees(tree_type, count, x_range=(80,1200), y_range=(60, frame_y-60)):
        for _ in range(count):
            for _try in range(30):
                tx = random.randint(*x_range)
                ty = random.randint(*y_range)
                if math.hypot(tx-120, ty-240) < 110: continue
                if math.hypot(tx-1160, ty-240) < 110: continue
                # Check not overlapping existing obstacles
                tr = pygame.Rect(tx-10, ty-10, 20, 20)
                if any(tr.colliderect(o['rect']) for o in obstacles): continue
                obstacles.append({
                    'points': [(tx,ty)],
                    'rect': tr,
                    'color': rock_color,
                    'otype': 'tree',
                    'tree_type': tree_type,
                    'tx': tx, 'ty': ty,
                })
                break

    def add_city_district(cx, cy, block_count=6, spread=180, congestion=0.55):
        building_patterns = [
            [(0,0,1.0,1.0)],
            [(-0.27,0,0.42,1.0),(0.27,0,0.42,1.0)],
            [(0,-0.27,1.0,0.42),(0,0.27,1.0,0.42)],
            [(-0.27,-0.27,0.42,0.42),(0.27,-0.27,0.42,0.42),
             (-0.27, 0.27,0.42,0.42),(0.27, 0.27,0.42,0.42)],
        ]
        used_rects = []
        attempts = 0
        placed = 0
        while placed < block_count and attempts < 80:
            attempts += 1
            bw = random.randint(40, 80)
            bh = random.randint(35, 70)
            bx = cx + random.randint(-spread, spread)
            by = cy + random.randint(-int(spread*0.6), int(spread*0.6))
            bx = max(40, min(frame_x-40, bx))
            by = max(40, min(frame_y-40, by))
            if math.hypot(bx-120, by-320) < 140: continue
            if math.hypot(bx-1160, by-320) < 140: continue
            check = pygame.Rect(bx - bw//2 - 12, by - bh//2 - 12, bw+24, bh+24)
            if any(check.colliderect(r) for r in used_rects): continue
            pattern = random.choice(building_patterns)
            for (ox,oy,sw,sh) in pattern:
                bldg_w = max(10, int(bw*sw) - 8)
                bldg_h = max(10, int(bh*sh) - 8)
                bldg_cx = bx + ox*bw*0.5
                bldg_cy = by + oy*bh*0.5
                x0 = bldg_cx - bldg_w//2
                y0 = bldg_cy - bldg_h//2
                rect = pygame.Rect(int(x0), int(y0), bldg_w, bldg_h)
                pts = [(rect.left,rect.top),(rect.right,rect.top),
                       (rect.right,rect.bottom),(rect.left,rect.bottom)]
                hit_rect = rect.inflate(-4,-4)
                obstacles.append({'points': pts, 'rect': hit_rect,
                                   'color': rock_color, 'otype': 'building'})
            used_rects.append(check)
            placed += 1

    # ── VOLCANIC ─────────────────────────────────────────────────────────────
    if theme is VOLCANIC:
        # Central crater
        crater_cx, crater_cy = frame_x//2, frame_y//2
        crater_visual_r = 130
        crater_hitbox_r = 72
        crater_pts_count = 16
        crater_pts = []
        for i in range(crater_pts_count):
            ang = math.radians(i * 360 / crater_pts_count)
            jitter = random.uniform(0.88, 1.12)
            crater_pts.append((
                crater_cx + math.cos(ang) * crater_visual_r * jitter,
                crater_cy + math.sin(ang) * crater_visual_r * jitter,
            ))
        crater_rect = pygame.Rect(crater_cx - crater_hitbox_r, crater_cy - crater_hitbox_r,
                                  crater_hitbox_r*2, crater_hitbox_r*2)
        crater_rect.inflate_ip(-28, -28)
        obstacles.append({'points': crater_pts, 'rect': crater_rect,
                           'color': (60, 20, 10), 'otype': 'crater'})
        # Lava rocks scattered around
        add_rocks(8, x_range=(100,1180), y_range=(80,frame_y-80), scale_range=(0.3,0.55))

    # ── CITY ─────────────────────────────────────────────────────────────────
    elif theme is CITY:
        road_xs = [320, 640, 960]
        road_ys = [180, 360, 540]
        road_w  = 90

        col_spans = [(0,320),(320,640),(640,960),(960,1280)]
        row_spans = [(0,180),(180,360),(360,540),(540,720)]
        block_defs = []
        for (x0,x1) in col_spans:
            for (y0,y1) in row_spans:
                bcx = (x0 + x1) // 2
                bcy = (y0 + y1) // 2
                bw  = (x1 - x0) - road_w
                bh  = (y1 - y0) - road_w
                if bw > 20 and bh > 20:
                    block_defs.append((bcx, bcy, bw, bh))

        building_patterns = [
            [(0,0,1.0,1.0)],
            [(-0.27,0,0.42,1.0),(0.27,0,0.42,1.0)],
            [(0,-0.27,1.0,0.42),(0,0.27,1.0,0.42)],
            [(-0.27,-0.27,0.42,0.42),(0.27,-0.27,0.42,0.42),
             (-0.27, 0.27,0.42,0.42),(0.27, 0.27,0.42,0.42)],
            [(-0.27,-0.27,0.42,0.42),(0.27,-0.27,0.42,0.42),(-0.27,0.27,0.42,0.42)],
            [(0,-0.27,0.88,0.42),(-0.27,0.27,0.42,0.42),(0.27,0.27,0.42,0.42)],
            [(0,-0.38,0.88,0.20),(0,0.38,0.88,0.20),(-0.38,0,0.20,0.56),(0.38,0,0.20,0.56)],
        ]
        spawn_safe = [(120,240,180),(1160,240,180)]
        for (bcx,bcy,bw,bh) in block_defs:
            if any(math.hypot(bcx-sx,bcy-sy)<sr for sx,sy,sr in spawn_safe): continue
            pattern = random.choice(building_patterns)
            inset = 10
            for (ox,oy,sw,sh) in pattern:
                bldg_w = max(14, int(bw*sw) - inset*2)
                bldg_h = max(14, int(bh*sh) - inset*2)
                bldg_cx = bcx + ox*bw*0.5
                bldg_cy = bcy + oy*bh*0.5
                x0b = bldg_cx - bldg_w//2
                y0b = bldg_cy - bldg_h//2
                rect = pygame.Rect(int(x0b),int(y0b),bldg_w,bldg_h)
                pts = [(rect.left,rect.top),(rect.right,rect.top),
                       (rect.right,rect.bottom),(rect.left,rect.bottom)]
                obstacles.append({'points': pts, 'rect': rect.inflate(-4,-4),
                                   'color': rock_color, 'otype': 'building'})

        # Scatter rocks in streets
        for _ in range(5):
            for _try in range(30):
                rx = random.randint(30, frame_x-30)
                ry = random.randint(30, frame_y-30)
                if math.hypot(rx-120,ry-320)<140: continue
                if math.hypot(rx-1160,ry-320)<140: continue
                scale = random.uniform(0.15,0.25)
                angle = random.uniform(0,360)
                base_pts = [(0,0),(70,-10),(110,30),(90,80),(10,70)]
                scaled = [(p[0]*scale,p[1]*scale) for p in base_pts]
                rad = math.radians(angle)
                cos_a, sin_a = math.cos(rad), math.sin(rad)
                rotated = [(x*cos_a-y*sin_a+rx, x*sin_a+y*cos_a+ry) for x,y in scaled]
                rect = pygame.Rect(rotated[0],(0,0))
                for p in rotated[1:]: rect.union_ip(pygame.Rect(p,(0,0)))
                rect.inflate_ip(-OBSTACLE_HITBOX_INSET,-OBSTACLE_HITBOX_INSET)
                obstacles.append({'points': rotated, 'rect': rect,
                                   'color': rock_color, 'otype': 'rock'})
                break

    # ── PLAINS / DESERT / SNOW ────────────────────────────────────────────────
    else:
        # Random scattered rocks
        add_rocks(6)

        # Trees — biome dependent
        if theme is PLAINS:
            add_trees('oak', random.randint(6,10))
        elif theme is DESERT:
            add_trees('palm', random.randint(2,4))
        elif theme is SNOW:
            add_trees('pine', random.randint(7,12))

        # Random small city district (shanty town / outpost)
        if random.random() < 0.7:
            margin = 120
            cx = random.randint(margin, frame_x-margin)
            cy = random.randint(margin, frame_y-margin)
            # Keep away from both spawns
            for _ in range(40):
                if math.hypot(cx-120,cy-240)>200 and math.hypot(cx-1160,cy-240)>200:
                    break
                cx = random.randint(margin, frame_x-margin)
                cy = random.randint(margin, frame_y-margin)
            add_city_district(cx, cy,
                block_count=random.randint(4,8),
                spread=random.randint(120,200))
        add_fieldworks()

    return obstacles

def draw_window(grx, gry, blx, bly, gr_hp, bl_hp, gr_heat, bl_heat, heat_max, gr_chassis_angle, gr_turret_angle, bl_chassis_angle, bl_turret_angle, bullets, infantry_bullets, infantry, apcs, jeeps, humvees, supply_drones, attack_drones, repair_rings, blowouts, muzzle_flashes, explosions, obstacles, airdrops, smokes, mines, now_ms, gr_ammo_ap, gr_ammo_he, gr_ammo_atgm, gr_ammo_mg, bl_ammo_ap, bl_ammo_he, bl_ammo_atgm, bl_ammo_mg, gr_fuel, bl_fuel, gr_smoke_ammo, bl_smoke_ammo, gr_repair_ammo, bl_repair_ammo, gr_lives, bl_lives, gr_ammo_type, bl_ammo_type, gr_reload_left, bl_reload_left, gr_protect_until, bl_protect_until, shake_x, shake_y, gr_recoil, bl_recoil, gr_turret_recoil, bl_turret_recoil, theme, night_alpha, clock_text, weather_type, weather_particles, engine_smoke, track_marks, casings, night_vision, settings_open=False, settings_data=None, gr_buffs=None, bl_buffs=None, hide_gr_turret=False, hide_bl_turret=False, hide_gr_tank=False, hide_bl_tank=False, perf_data=None, kill_feed=None, quality_mode="BALANCED", koth_data=None, siege_data=None, boss_data=None, selected_units=None, gr_class="MBT", bl_class="MBT", gr_gun_elev=0.0, bl_gun_elev=0.0):
    perf_mode = quality_mode in ("PERFORMANCE", "AUTO-LOW")
    game_window.fill(theme['bg']) # background
    if koth_data and koth_data.get("mode") == "KOTH":
        hx, hy, hr = koth_data["x"], koth_data["y"], koth_data["r"]
        ring_col = (230, 220, 120)
        ctrl = koth_data.get("control")
        if ctrl == "green":
            ring_col = (120, 240, 120)
        elif ctrl == "blue":
            ring_col = (120, 170, 255)
        pygame.draw.circle(game_window, (0, 0, 0), (int(hx + shake_x), int(hy + shake_y)), hr, 2)
        pygame.draw.circle(game_window, ring_col, (int(hx + shake_x), int(hy + shake_y)), hr - 2, 2)
        # Central short flag mast: flag rises for green, lowers for blue by capture score.
        score = max(-100.0, min(100.0, koth_data.get("score", 0.0)))
        mast_h = 42
        mast_top = int(hy + shake_y - mast_h // 2)
        mast_x = int(hx + shake_x)
        bg = theme.get('bg', (60, 60, 60))
        lum = (bg[0] * 0.299 + bg[1] * 0.587 + bg[2] * 0.114)
        mast_col = (20, 20, 20) if lum > 130 else (240, 240, 240)
        mast_outline = (245, 245, 245) if lum <= 130 else (10, 10, 10)
        pygame.draw.line(game_window, mast_outline, (mast_x, mast_top), (mast_x, mast_top + mast_h), 5)
        pygame.draw.line(game_window, mast_col, (mast_x, mast_top), (mast_x, mast_top + mast_h), 3)
        # Any full capture raises that team's flag. Neutral/no capture lowers it.
        t = abs(score) / 100.0
        flag_y = int(mast_top + mast_h - t * mast_h)
        owner = koth_data.get("control")
        if owner == "green":
            flag_col = (70, 220, 70)
        elif owner == "blue":
            flag_col = (90, 140, 255)
        else:
            flag_col = (240, 240, 240)
        pygame.draw.rect(game_window, flag_col, (mast_x + 2, flag_y - 6, 18, 10))
        pygame.draw.rect(game_window, (20, 20, 20), (mast_x + 2, flag_y - 6, 18, 10), 1)

    # Street / road underlays (drawn before buildings, no collision)
    has_buildings = any(o.get('otype') == 'building' for o in obstacles)
    if has_buildings:
        street_color = (max(theme['bg'][0]-18,0), max(theme['bg'][1]-18,0), max(theme['bg'][2]-18,0))
        curb_color   = (min(theme['bg'][0]+28,255), min(theme['bg'][1]+28,255), min(theme['bg'][2]+28,255))
        dash_col     = (min(street_color[0]+30,255), min(street_color[1]+30,255), min(street_color[2]+30,255))
        if theme is CITY:
            road_xs = [320, 640, 960]
            road_ys = [180, 360, 540]
            road_w  = 90
            inter_half = road_w // 2
            for rx in road_xs:
                pygame.draw.rect(game_window, street_color,
                    (rx - road_w//2 + shake_x, shake_y, road_w, frame_y))
                pygame.draw.line(game_window, curb_color,
                    (rx - road_w//2 + shake_x, shake_y), (rx - road_w//2 + shake_x, frame_y + shake_y), 2)
                pygame.draw.line(game_window, curb_color,
                    (rx + road_w//2 + shake_x, shake_y), (rx + road_w//2 + shake_x, frame_y + shake_y), 2)
                y = shake_y
                while y < frame_y + shake_y:
                    # Keep intersection centers clean: no lane dashes through junction boxes.
                    if any(abs((y - shake_y) - ry) <= inter_half for ry in road_ys):
                        y += 24
                        continue
                    pygame.draw.line(game_window, dash_col,
                        (rx + shake_x, int(y)), (rx + shake_x, int(y + 14)), 1)
                    y += 24
            for ry in road_ys:
                pygame.draw.rect(game_window, street_color,
                    (shake_x, ry - road_w//2 + shake_y, frame_x, road_w))
                pygame.draw.line(game_window, curb_color,
                    (shake_x, ry - road_w//2 + shake_y), (frame_x + shake_x, ry - road_w//2 + shake_y), 2)
                pygame.draw.line(game_window, curb_color,
                    (shake_x, ry + road_w//2 + shake_y), (frame_x + shake_x, ry + road_w//2 + shake_y), 2)
                x = shake_x
                while x < frame_x + shake_x:
                    # Keep intersection centers clean: no lane dashes through junction boxes.
                    if any(abs((x - shake_x) - rx) <= inter_half for rx in road_xs):
                        x += 24
                        continue
                    pygame.draw.line(game_window, dash_col,
                        (int(x), ry + shake_y), (int(x + 14), ry + shake_y), 1)
                    x += 24
            # Redraw intersection pads to remove any residual crossing artifacts and keep junctions readable.
            for rx in road_xs:
                for ry in road_ys:
                    ix = rx - inter_half + shake_x
                    iy = ry - inter_half + shake_y
                    pygame.draw.rect(game_window, street_color, (ix, iy, road_w, road_w))
                    c = 10
                    # Corner curb hints (L-shapes) so intersections still read as road edges.
                    pygame.draw.line(game_window, curb_color, (ix, iy), (ix + c, iy), 2)
                    pygame.draw.line(game_window, curb_color, (ix, iy), (ix, iy + c), 2)
                    pygame.draw.line(game_window, curb_color, (ix + road_w, iy), (ix + road_w - c, iy), 2)
                    pygame.draw.line(game_window, curb_color, (ix + road_w, iy), (ix + road_w, iy + c), 2)
                    pygame.draw.line(game_window, curb_color, (ix, iy + road_w), (ix + c, iy + road_w), 2)
                    pygame.draw.line(game_window, curb_color, (ix, iy + road_w), (ix, iy + road_w - c), 2)
                    pygame.draw.line(game_window, curb_color, (ix + road_w, iy + road_w), (ix + road_w - c, iy + road_w), 2)
                    pygame.draw.line(game_window, curb_color, (ix + road_w, iy + road_w), (ix + road_w, iy + road_w - c), 2)
        else:
            # Outpost — dirt paths between buildings, no ring road
            bldg_obs = [o for o in obstacles if o.get('otype') == 'building']
            if len(bldg_obs) >= 2:
                for i in range(len(bldg_obs) - 1):
                    ax = bldg_obs[i]['rect'].centerx + shake_x
                    ay = bldg_obs[i]['rect'].centery + shake_y
                    bx2 = bldg_obs[i+1]['rect'].centerx + shake_x
                    by2 = bldg_obs[i+1]['rect'].centery + shake_y
                    pygame.draw.line(game_window, street_color,
                        (int(ax), int(ay)), (int(bx2), int(by2)), 10)
            # else:
            # # Outpost — just draw short dirt paths between buildings, no ring road
            # bldg_obs = [o for o in obstacles if o.get('otype') == 'building']
            # if len(bldg_obs) >= 2:
            #     for i in range(len(bldg_obs) - 1):
            #         ax = bldg_obs[i]['rect'].centerx + shake_x
            #         ay = bldg_obs[i]['rect'].centery + shake_y
            #         bx2 = bldg_obs[i+1]['rect'].centerx + shake_x
            #         by2 = bldg_obs[i+1]['rect'].centery + shake_y
            #         pygame.draw.line(game_window, street_color,
            #             (int(ax), int(ay)), (int(bx2), int(by2)), 10)
            #     pygame.draw.circle(game_window, street_color,
            #         (int(dcx+shake_x), int(dcy+shake_y)), max_r, 18)
            #     pygame.draw.circle(game_window, curb_color,
            #         (int(dcx+shake_x), int(dcy+shake_y)), max_r-9, 1)
            #     pygame.draw.circle(game_window, curb_color,
            #         (int(dcx+shake_x), int(dcy+shake_y)), max_r+9, 1)

    # Obstacles
    for obs in obstacles:
        otype = obs.get('otype', 'rock')
        pts = [(p[0] + shake_x, p[1] + shake_y) for p in obs['points']]

        if otype == 'tree':
            tx = obs['tx'] + shake_x
            ty = obs['ty'] + shake_y
            tt = obs.get('tree_type', 'oak')
            if tt == 'oak':
                # Shadow
                shadow = pygame.Surface((52, 26), pygame.SRCALPHA)
                pygame.draw.ellipse(shadow, (0,0,0,40), (0,0,52,26))
                game_window.blit(shadow, (int(tx-20), int(ty)))
                # Trunk
                pygame.draw.rect(game_window, (90,55,20), (int(tx-4), int(ty-4), 8, 8))
                # Canopy — layered circles top-down
                pygame.draw.circle(game_window, (20,75,20),  (int(tx), int(ty)), 26)
                pygame.draw.circle(game_window, (35,110,35), (int(tx), int(ty)), 22)
                pygame.draw.circle(game_window, (50,145,50), (int(tx)-4, int(ty)-4), 14)
                pygame.draw.circle(game_window, (70,180,70), (int(tx)-6, int(ty)-6), 7)
                pygame.draw.circle(game_window, (110,220,110),(int(tx)-7, int(ty)-7), 3)

            elif tt == 'palm':
                # Shadow
                shadow = pygame.Surface((50, 22), pygame.SRCALPHA)
                pygame.draw.ellipse(shadow, (0,0,0,35), (0,0,50,22))
                game_window.blit(shadow, (int(tx-10), int(ty+4)))
                # Trunk top
                pygame.draw.circle(game_window, (130,95,45), (int(tx), int(ty)), 6)
                pygame.draw.circle(game_window, (155,115,55), (int(tx), int(ty)), 4)
                # Fronds — fixed length, tapered polygons that darken toward tip
                frond_length = 24
                frond_angles = [i * 60 for i in range(6)]
                for ang_deg in frond_angles:
                    rad = math.radians(ang_deg)
                    # Base point (wide, bright end near trunk)
                    base_w = 4
                    perp = math.radians(ang_deg + 90)
                    bx1 = tx + math.cos(perp) * base_w
                    by1 = ty + math.sin(perp) * base_w
                    bx2 = tx - math.cos(perp) * base_w
                    by2 = ty - math.sin(perp) * base_w
                    # Tip point (narrow, dark end)
                    tip_x = tx + math.cos(rad) * frond_length
                    tip_y = ty + math.sin(rad) * frond_length
                    # Draw as filled triangle: base two corners → tip
                    pygame.draw.polygon(game_window, (35,100,25), [
                        (int(bx1), int(by1)),
                        (int(bx2), int(by2)),
                        (int(tip_x), int(tip_y)),
                    ])
                    # Midrib line — slightly brighter
                    mid_x = tx + math.cos(rad) * (frond_length * 0.55)
                    mid_y = ty + math.sin(rad) * (frond_length * 0.55)
                    pygame.draw.line(game_window, (70,160,50),
                        (int(tx), int(ty)), (int(mid_x), int(mid_y)), 2)
                # Centre highlight
                pygame.draw.circle(game_window, (200,170,80), (int(tx), int(ty)), 3)

            elif tt == 'pine':
                # Shadow
                shadow = pygame.Surface((48, 22), pygame.SRCALPHA)
                pygame.draw.ellipse(shadow, (0,0,0,40), (0,0,48,22))
                game_window.blit(shadow, (int(tx-24), int(ty-2)))
                # Concentric rings — top-down pine canopy
                pygame.draw.circle(game_window, (12,50,15),  (int(tx), int(ty)), 22)
                pygame.draw.circle(game_window, (18,70,22),  (int(tx), int(ty)), 18)
                pygame.draw.circle(game_window, (26,90,30),  (int(tx), int(ty)), 14)
                pygame.draw.circle(game_window, (36,115,40), (int(tx), int(ty)), 9)
                pygame.draw.circle(game_window, (50,140,55), (int(tx), int(ty)), 5)
                # Spiky outer points
                for i in range(10):
                    ang = math.radians(i * 36)
                    px = tx + math.cos(ang) * 21
                    py = ty + math.sin(ang) * 21
                    pygame.draw.circle(game_window, (12,50,15), (int(px), int(py)), 5)
                # Centre trunk
                pygame.draw.circle(game_window, (90,58,25), (int(tx), int(ty)), 3)

        elif otype == 'crater':
            pygame.draw.polygon(game_window, (100,35,10), pts)
            cx_c = int(sum(p[0] for p in pts)/len(pts))
            cy_c = int(sum(p[1] for p in pts)/len(pts))
            pulse = int(20 + 12 * math.sin(pygame.time.get_ticks() / 300.0))
            pygame.draw.circle(game_window, (220, 80+pulse, 0), (cx_c, cy_c), 28)
            pygame.draw.circle(game_window, (255, 160+pulse//2, 20), (cx_c, cy_c), 16)
            pygame.draw.circle(game_window, (255, 220, 80), (cx_c, cy_c), 7)
            for i in range(8):
                ang = math.radians(i*45 + pygame.time.get_ticks()//800 % 360)
                x1 = cx_c + int(math.cos(ang)*18)
                y1 = cy_c + int(math.sin(ang)*18)
                x2 = cx_c + int(math.cos(ang)*30)
                y2 = cy_c + int(math.sin(ang)*30)
                pygame.draw.line(game_window, (180,60,0), (x1,y1), (x2,y2), 2)

        elif otype == 'building':
            r = obs['rect']
            rx2 = r.left + shake_x
            ry2 = r.top + shake_y
            rw = r.width
            rh = r.height

            # ── Drop shadow (offset south-east, drawn first) ──────────────────
            shadow_off = 5
            shadow_surf = pygame.Surface((rw + shadow_off*2, rh + shadow_off*2), pygame.SRCALPHA)
            pygame.draw.rect(shadow_surf, (0,0,0,55),
                (shadow_off, shadow_off, rw, rh), border_radius=2)
            game_window.blit(shadow_surf, (int(rx2 - shadow_off + shadow_off*2),
                                           int(ry2 - shadow_off + shadow_off*2)))

            # ── Roof (flat top — main fill) ───────────────────────────────────
            roof_base = theme['rock']
            roof_mid  = (min(roof_base[0]+18,255), min(roof_base[1]+18,255), min(roof_base[2]+18,255))
            roof_hi   = (min(roof_base[0]+35,255), min(roof_base[1]+35,255), min(roof_base[2]+35,255))
            dark_edge = (max(roof_base[0]-25,0),   max(roof_base[1]-25,0),   max(roof_base[2]-25,0))
            pygame.draw.rect(game_window, roof_base, (int(rx2), int(ry2), rw, rh))

            # ── Fake 3-D extruded faces (south + east are in shadow) ──────────
            depth = 5   # pixel depth of extrusion
            # South face (darker — underside)
            south = pygame.Surface((rw, depth), pygame.SRCALPHA)
            south.fill((*dark_edge, 200))
            game_window.blit(south, (int(rx2), int(ry2 + rh)))
            # East face (slightly less dark)
            east_col = (max(roof_base[0]-15,0), max(roof_base[1]-15,0), max(roof_base[2]-15,0))
            east = pygame.Surface((depth, rh + depth), pygame.SRCALPHA)
            east.fill((*east_col, 200))
            game_window.blit(east, (int(rx2 + rw), int(ry2)))

            # ── Roof detail: lighter gradient strip on north edge ─────────────
            pygame.draw.rect(game_window, roof_hi,  (int(rx2),      int(ry2),      rw, 3))
            pygame.draw.rect(game_window, roof_mid, (int(rx2),      int(ry2+3),    rw, 3))
            # Left edge highlight
            pygame.draw.rect(game_window, roof_hi,  (int(rx2),      int(ry2),      3, rh))

            # ── Windows on each face edge (top-down perspective) ──────────────
            win_size  = 4
            win_gap   = 5
            edge_pad  = 5
            win_lit   = (min(roof_base[0]+70,255), min(roof_base[1]+70,255), min(roof_base[2]+70,255))
            win_dark  = (max(roof_base[0]-20,0),   max(roof_base[1]-20,0),   max(roof_base[2]-20,0))

            # North face windows (top edge of roof rect)
            x = rx2 + edge_pad
            while x + win_size <= rx2 + rw - edge_pad:
                lit = int(x*3 + ry2*7) % 4 != 0
                pygame.draw.rect(game_window, win_lit if lit else win_dark,
                    (int(x), int(ry2 + 1), win_size, win_size))
                x += win_size + win_gap

            # South face windows (bottom edge)
            x = rx2 + edge_pad
            while x + win_size <= rx2 + rw - edge_pad:
                lit = int(x*5 + ry2*3) % 4 != 0
                pygame.draw.rect(game_window, win_lit if lit else win_dark,
                    (int(x), int(ry2 + rh - 1 - win_size), win_size, win_size))
                x += win_size + win_gap

            # West face windows (left edge)
            y = ry2 + edge_pad
            while y + win_size <= ry2 + rh - edge_pad:
                lit = int(rx2*7 + y*3) % 4 != 0
                pygame.draw.rect(game_window, win_lit if lit else win_dark,
                    (int(rx2 + 1), int(y), win_size, win_size))
                y += win_size + win_gap

            # East face windows (right edge)
            y = ry2 + edge_pad
            while y + win_size <= ry2 + rh - edge_pad:
                lit = int(rx2*3 + y*11) % 4 != 0
                pygame.draw.rect(game_window, win_lit if lit else win_dark,
                    (int(rx2 + rw - 1 - win_size), int(y), win_size, win_size))
                y += win_size + win_gap

            # ── Rooftop details ───────────────────────────────────────────────
            # HVAC box
            if rw > 24 and rh > 24:
                hw = max(6, rw//4)
                hh = max(5, rh//5)
                hx2 = int(rx2 + rw//2 - hw//2)
                hy2 = int(ry2 + rh//2 - hh//2)
                pygame.draw.rect(game_window, roof_hi, (hx2, hy2, hw, hh))
                pygame.draw.rect(game_window, dark_edge, (hx2, hy2, hw, hh), 1)
                # HVAC south shadow face
                pygame.draw.rect(game_window, dark_edge, (hx2, hy2+hh, hw, 2))
            # Corner vent dots
            if rw > 18 and rh > 18:
                for vx2, vy2 in [(rx2+7, ry2+7), (rx2+rw-9, ry2+7),
                                  (rx2+7, ry2+rh-9), (rx2+rw-9, ry2+rh-9)]:
                    pygame.draw.circle(game_window, dark_edge, (int(vx2), int(vy2)), 2)
                    pygame.draw.circle(game_window, roof_hi,   (int(vx2)-1, int(vy2)-1), 1)

            # ── Outer roof border ─────────────────────────────────────────────
            pygame.draw.rect(game_window, dark_edge, (int(rx2), int(ry2), rw, rh), 1)

        else:
            # Rock
            pygame.draw.polygon(game_window, theme['rock'], pts)
    if not perf_mode:
        draw_track_marks(game_window, track_marks, now_ms, shake_x, shake_y)
    # Ground layer: crates without parachutes
    draw_airdrops(game_window, airdrops, shake_x, shake_y, now_ms, theme, draw_parachute=False)
    if siege_data and siege_data.get("mode") == "SIEGE":
        if siege_data.get("green"):
            draw_barracks(game_window, siege_data["green"], shake_x, shake_y, obstacles)
        if siege_data.get("blue"):
            draw_barracks(game_window, siege_data["blue"], shake_x, shake_y, obstacles)
    if boss_data and boss_data.get("hp", 0) > 0:
        draw_boss(game_window, boss_data, shake_x, shake_y)

    gr_recoil_x = -math.cos(math.radians(gr_turret_angle)) * gr_recoil
    gr_recoil_y = math.sin(math.radians(gr_turret_angle)) * gr_recoil
    bl_recoil_x = -math.cos(math.radians(bl_turret_angle)) * bl_recoil
    bl_recoil_y = math.sin(math.radians(bl_turret_angle)) * bl_recoil

    gr_turret_rx = -math.cos(math.radians(gr_turret_angle)) * gr_turret_recoil
    gr_turret_ry = math.sin(math.radians(gr_turret_angle)) * gr_turret_recoil
    bl_turret_rx = -math.cos(math.radians(bl_turret_angle)) * bl_turret_recoil
    bl_turret_ry = math.sin(math.radians(bl_turret_angle)) * bl_turret_recoil
    gr_turret_img = gr_td_tr if gr_class == "TD" else gr_tr
    bl_turret_img = bl_td_tr if bl_class == "TD" else bl_tr

    # Tanks layer
    gr_turret_off = td_turret_forward_offset if gr_class == "TD" else 0.0
    bl_turret_off = td_turret_forward_offset if bl_class == "TD" else 0.0
    gr_turret_cx = grx + shake_x + math.cos(math.radians(gr_turret_angle)) * gr_turret_off
    gr_turret_cy = gry + shake_y - math.sin(math.radians(gr_turret_angle)) * gr_turret_off
    bl_turret_cx = blx + shake_x + math.cos(math.radians(bl_turret_angle)) * bl_turret_off
    bl_turret_cy = bly + shake_y - math.sin(math.radians(bl_turret_angle)) * bl_turret_off
    if not hide_gr_tank:
        draw_tank(
            game_window,
            grx + shake_x + gr_recoil_x, gry + shake_y + gr_recoil_y,
            gr_ch, gr_chassis_angle,
            None, gr_turret_angle
        )
    if not hide_bl_tank:
        draw_tank(
            game_window,
            blx + shake_x + bl_recoil_x, bly + shake_y + bl_recoil_y,
            bl_ch, bl_chassis_angle,
            None, bl_turret_angle
        )
    # Turret base + recoil overlay
    if not hide_gr_tank and not hide_gr_turret:
        blit_rotate_center(game_window, gr_turret_img, (gr_turret_cx, gr_turret_cy), gr_turret_angle)
    if not hide_bl_tank and not hide_bl_turret:
        blit_rotate_center(game_window, bl_turret_img, (bl_turret_cx, bl_turret_cy), bl_turret_angle)
    if not hide_gr_tank and not hide_gr_turret:
        blit_rotate_center(game_window, gr_turret_img, (gr_turret_cx + gr_turret_rx, gr_turret_cy + gr_turret_ry), gr_turret_angle)
    if not hide_bl_tank and not hide_bl_turret:
        blit_rotate_center(game_window, bl_turret_img, (bl_turret_cx + bl_turret_rx, bl_turret_cy + bl_turret_ry), bl_turret_angle)

    # Infantry + AI vehicles layer
    draw_infantry(game_window, infantry, shake_x, shake_y)
    draw_apcs(game_window, apcs, shake_x, shake_y)
    draw_jeeps(game_window, jeeps, shake_x, shake_y)
    draw_humvees(game_window, humvees, shake_x, shake_y)
    draw_drones(game_window, supply_drones, shake_x, shake_y, "supply", now_ms)
    draw_drones(game_window, attack_drones, shake_x, shake_y, "attack", now_ms)
    if selected_units:
        for s in selected_units:
            if s.get('hp', 0) <= 0:
                continue
            rad = 10 if "role" in s else 16
            pygame.draw.circle(game_window, (255, 245, 120), (int(s['x'] + shake_x), int(s['y'] + shake_y)), rad, 2)

    # Predicted ballistic impact markers for the main guns.
    vehicle_blockers = [(apc_rect(v), vehicle_height(v)) for v in (apcs + jeeps + humvees) if v.get('hp', 0) > 0]
    gr_tank_blocker = (get_collision_rect(gr_ch, (grx, gry), gr_chassis_angle, TANK_HITBOX_SCALE), tank_height())
    bl_tank_blocker = (get_collision_rect(bl_ch, (blx, bly), bl_chassis_angle, TANK_HITBOX_SCALE), tank_height())
    if not hide_gr_tank and gr_ammo_type != "ATGM":
        muzzle_offset = gr_turret_img.get_width() * 0.5
        sx = gr_turret_cx - shake_x + math.cos(math.radians(gr_turret_angle)) * muzzle_offset
        sy = gr_turret_cy - shake_y - math.sin(math.radians(gr_turret_angle)) * muzzle_offset
        blockers = vehicle_blockers + ([] if hide_bl_tank else [bl_tank_blocker])
        impact = predict_round_impact(sx, sy, gr_turret_angle, gr_gun_elev, gr_ammo_type, obstacles, blockers)
        if impact:
            draw_impact_marker(game_window, impact[0], impact[1], (80, 255, 80), shake_x, shake_y)
    if not hide_bl_tank and bl_ammo_type != "ATGM":
        muzzle_offset = bl_turret_img.get_width() * 0.5
        sx = bl_turret_cx - shake_x + math.cos(math.radians(bl_turret_angle)) * muzzle_offset
        sy = bl_turret_cy - shake_y - math.sin(math.radians(bl_turret_angle)) * muzzle_offset
        blockers = vehicle_blockers + ([] if hide_gr_tank else [gr_tank_blocker])
        impact = predict_round_impact(sx, sy, bl_turret_angle, bl_gun_elev, bl_ammo_type, obstacles, blockers)
        if impact:
            draw_impact_marker(game_window, impact[0], impact[1], (80, 150, 255), shake_x, shake_y)

    # Projectiles layer
    for bullet in bullets:
        if bullet.get('type') == 'mg':
            vx = bullet['vx']
            vy = bullet['vy']
            mag = math.hypot(vx, vy)
            if mag > 0:
                tx = bullet['x'] - (vx / mag) * mg_tracer_len
                ty = bullet['y'] - (vy / mag) * mg_tracer_len
                pygame.draw.line(game_window, mg_tracer_color, (bullet['x'] + shake_x, bullet['y'] + shake_y), (tx + shake_x, ty + shake_y), 2)
        bullet_draw = dict(bullet)
        bullet_draw['x'] = bullet['x'] + shake_x
        bullet_draw['y'] = bullet['y'] + shake_y
        draw_bullet(game_window, bullet_draw)
    for ib in infantry_bullets:
        if ib.get('type') == 'apc_at':
            # Use shared ATGM sprite pipeline so APC missiles match tank ATGMs.
            ang = math.degrees(math.atan2(-ib['vy'], ib['vx']))
            ib_draw = dict(ib)
            ib_draw['x'] = ib['x'] + shake_x
            ib_draw['y'] = ib['y'] + shake_y
            ib_draw['angle'] = ang
            ib_draw['ammo_type'] = "ATGM"
            draw_bullet(game_window, ib_draw)
        elif ib.get('type') == 'apc_mg':
            vx = ib['vx']
            vy = ib['vy']
            mag = math.hypot(vx, vy)
            if mag > 0:
                tx = ib['x'] - (vx / mag) * 10
                ty = ib['y'] - (vy / mag) * 10
                pygame.draw.line(game_window, (230, 230, 230), (ib['x'] + shake_x, ib['y'] + shake_y), (tx + shake_x, ty + shake_y), 2)
        else:
            vx = ib.get('vx', 0.0)
            vy = ib.get('vy', 0.0)
            mag = math.hypot(vx, vy)
            if mag > 0:
                tx = ib['x'] - (vx / mag) * 14
                ty = ib['y'] - (vy / mag) * 14
                pygame.draw.line(game_window, mg_tracer_color, (ib['x'] + shake_x, ib['y'] + shake_y), (tx + shake_x, ty + shake_y), 2)
                pygame.draw.circle(game_window, (255, 250, 200), (int(ib['x'] + shake_x), int(ib['y'] + shake_y)), 2)
            else:
                pygame.draw.circle(game_window, (200, 200, 200), (int(ib['x'] + shake_x), int(ib['y'] + shake_y)), 2)

    # FX layer
    if gr_protect_until > now_ms and not hide_gr_tank:
        draw_spawn_shield(game_window, grx, gry, now_ms, shake_x, shake_y)
    if bl_protect_until > now_ms and not hide_bl_tank:
        draw_spawn_shield(game_window, blx, bly, now_ms, shake_x, shake_y)
    draw_muzzle_flashes(game_window, muzzle_flashes, now_ms, shake_x, shake_y)
    draw_explosions(game_window, explosions, now_ms, shake_x, shake_y)
    draw_blowouts(game_window, blowouts, now_ms, shake_x, shake_y)
    draw_repair_rings(game_window, repair_rings, now_ms, shake_x, shake_y)
    draw_smoke(game_window, smokes, now_ms, shake_x, shake_y)
    if not perf_mode:
        draw_engine_smoke(game_window, engine_smoke, now_ms, shake_x, shake_y)
        draw_casings(game_window, casings, now_ms, shake_x, shake_y)
    # World-space bars (stay with tanks)
    if not hide_gr_tank:
        draw_health_bar(game_window, grx - 50, gry - 60, gr_hp, max_hp)
        draw_heat_bar(game_window, grx - 40, gry - 44, gr_heat, heat_max, now_ms)
        draw_reload_bar(game_window, grx - 40, gry - 38, gr_reload_left)
    if not hide_bl_tank:
        draw_health_bar(game_window, blx - 50, bly - 60, bl_hp, max_hp)
        draw_heat_bar(game_window, blx - 40, bly - 44, bl_heat, heat_max, now_ms)
        draw_reload_bar(game_window, blx - 40, bly - 38, bl_reload_left)

    # Parachute layer (top of world)
    draw_airdrops(game_window, airdrops, shake_x, shake_y, now_ms, theme, draw_crates=False)

    # Time-of-day darkening overlay (kept in sync with TOD labels).
    if night_alpha > 0 and not night_vision:
        fog = pygame.Surface((frame_x, frame_y), pygame.SRCALPHA)
        fog.fill((0, 0, 0, int(max(0, min(255, night_alpha)))))
        game_window.blit(fog, (0, 0))

    # Weather layer (over world, under HUD)
    if not perf_mode:
        draw_weather(game_window, weather_particles, weather_type)

    # Re-draw selection/cursors after night+weather so they stay visible in dark scenes.
    if selected_units:
        for s in selected_units:
            if s.get('hp', 0) <= 0:
                continue
            sx = int(s['x'] + shake_x)
            sy = int(s['y'] + shake_y)
            rad = 10 if "role" in s else 16
            pygame.draw.circle(game_window, (20, 20, 20), (sx, sy), rad + 1, 3)
            pygame.draw.circle(game_window, (255, 245, 120), (sx, sy), rad, 2)

    # HUD layer (always on top)
    draw_hud(game_window, "GREEN", 110, 40, gr_hp, gr_ammo_ap, gr_ammo_he, gr_ammo_atgm, gr_ammo_mg, gr_fuel, gr_smoke_ammo, gr_repair_ammo, gr_lives, now_ms, gr_ammo_type, gr_buffs, gr_class, gr_turret_angle, gr_gun_elev)
    draw_hud(game_window, "BLUE", frame_x - 110, 40, bl_hp, bl_ammo_ap, bl_ammo_he, bl_ammo_atgm, bl_ammo_mg, bl_fuel, bl_smoke_ammo, bl_repair_ammo, bl_lives, now_ms, bl_ammo_type, bl_buffs, bl_class, bl_turret_angle, bl_gun_elev)
    draw_warning_hud(game_window, "GREEN", 110, 280, total_cannon_ammo(gr_ammo_ap, gr_ammo_he, gr_ammo_atgm), gr_fuel <= 0, gr_lives, now_ms, hide_gr_tank, gr_ammo_mg)
    draw_warning_hud(game_window, "BLUE", frame_x - 110, 280, total_cannon_ammo(bl_ammo_ap, bl_ammo_he, bl_ammo_atgm), bl_fuel <= 0, bl_lives, now_ms, hide_bl_tank, bl_ammo_mg)
    if clock_text:
        draw_text(game_window, hud_font, clock_text, white, (frame_x // 2, 28))
    draw_mode_hud(game_window, koth_data)
    draw_settings_icon(game_window)
    if settings_open:
        draw_settings_panel(game_window, settings_data)
    # Radar removed per UX request to keep HUD cleaner and reduce overlap.
    if perf_data:
        panel_w, panel_h = 220, 162
        px, py = 12, frame_y - panel_h - 12
        panel = pygame.Surface((panel_w, panel_h), pygame.SRCALPHA)
        panel.fill((0, 0, 0, 160))
        game_window.blit(panel, (px, py))
        pygame.draw.rect(game_window, (200, 200, 200), (px, py, panel_w, panel_h), 1)
        line = 0
        lh = 18
        draw_text(game_window, hud_font, f"FPS: {perf_data.get('fps', 0):.0f}", white, (px + 90, py + 10 + line * lh)); line += 1
        draw_text(game_window, hud_font, f"Units: {perf_data.get('inf', 0)}", white, (px + 90, py + 10 + line * lh)); line += 1
        draw_text(game_window, hud_font, f"Vehicles: {perf_data.get('veh', 0)}", white, (px + 90, py + 10 + line * lh)); line += 1
        draw_text(game_window, hud_font, f"Bullets: {perf_data.get('bul', 0)}", white, (px + 90, py + 10 + line * lh)); line += 1
        draw_text(game_window, hud_font, f"Inf Bul: {perf_data.get('ibul', 0)}", white, (px + 90, py + 10 + line * lh)); line += 1
        draw_text(game_window, hud_font, f"Weather: {perf_data.get('weather', 0)}", white, (px + 90, py + 10 + line * lh)); line += 1
        draw_text(game_window, hud_font, f"AI Step: {perf_data.get('think_ms', 0)}ms", white, (px + 90, py + 10 + line * lh)); line += 1
        draw_text(game_window, hud_font, f"Quality: {quality_mode}", white, (px + 90, py + 10 + line * lh)); line += 1
    if kill_feed:
        fy = 100 if not settings_open else 500
        fx = frame_x // 2
        for item in kill_feed[-6:]:
            age = now_ms - item.get("t", now_ms)
            if age > kill_feed_life_ms:
                continue
            fade = max(0.25, 1.0 - age / max(kill_feed_life_ms, 1))
            col = item.get("color", white)
            col = (int(col[0] * fade), int(col[1] * fade), int(col[2] * fade))
            draw_text(game_window, hud_font, item.get("text", ""), col, (fx, fy))
            fy += 18
    pygame.display.update()

def welcome_screen():
    game_window.fill((20, 40, 40))
    draw_text(game_window, title_font, "TANKTATION", white, (frame_x//2, frame_y//2 - 120))
    draw_text(game_window, sub_font, "Green Controls:", white, (frame_x//2, frame_y//2 - 70))
    draw_text(game_window, sub_font, "Move W/S  Rotate A/D  Elev Q/E  Cannon LMB", white, (frame_x//2, frame_y//2 - 40))
    draw_text(game_window, sub_font, "MG RMB  Smoke MMB  Repair F  Ammo Z", white, (frame_x//2, frame_y//2 - 18))
    draw_text(game_window, sub_font, "Blue Controls:", white, (frame_x//2, frame_y//2 + 18))
    draw_text(game_window, sub_font, "Move Up/Down  Rotate Left/Right  Elev ' /  Cannon Enter", white, (frame_x//2, frame_y//2 + 48))
    draw_text(game_window, sub_font, "MG Right Shift  Smoke RCtrl  Repair RAlt  Ammo Period(.)", white, (frame_x//2, frame_y//2 + 70))
    draw_text(game_window, sub_font, "Class system: MBT (balanced) or TD (heavier gun)", white, (frame_x//2, frame_y//2 + 102))
    draw_text(game_window, sub_font, "", white, (frame_x//2, frame_y//2))
    draw_text(game_window, sub_font, "PvC: R Restart | Esc Leave | X Scuttle | F2 Night Vision | F3 Debug | F4 Quality", white, (frame_x//2, frame_y//2 + 170))
    draw_text(game_window, sub_font, "Press any key to start", green, (frame_x//2, frame_y//2 + 200))
    pygame.display.update()

    while True:
        for event in pygame.event.get():
            if event.type == pygame.KEYDOWN:
                return True
            if event.type == pygame.QUIT:
                return False

def mode_screen():
    game_window.fill((20, 40, 40))
    draw_text(game_window, title_font, "SELECT MODE", white, (frame_x//2, frame_y//2 - 120))
    draw_text(game_window, sub_font, "1: PvP (Blue is player)", white, (frame_x//2, frame_y//2 - 10))
    draw_text(game_window, sub_font, "2: PvC (Blue is AI)", white, (frame_x//2, frame_y//2 + 20))
    draw_text(game_window, sub_font, "Press 1 or 2", green, (frame_x//2, frame_y//2 + 90))
    pygame.display.update()

    while True:
        for event in pygame.event.get():
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_1:
                    return "pvp"
                if event.key == pygame.K_2:
                    return "pvc"
            if event.type == pygame.QUIT:
                return None

def pick_weather(biome_name):
    if biome_name == "desert":
        options = ["clear", "sand", "sand", "clear"]
    elif biome_name == "snow":
        options = ["clear", "snow", "snow", "clear"]
    elif biome_name == "city":
        options = ["clear", "rain", "rain", "clear"]
    elif biome_name == "volcanic":
        options = ["clear", "ash", "ash", "clear"]
    else:
        options = ["clear", "rain", "clear", "rain"]
    return random.choice(options)

def difficulty_screen():
    game_window.fill((20, 40, 40))
    draw_text(game_window, title_font, "AI DIFFICULTY", white, (frame_x//2, frame_y//2 - 120))
    draw_text(game_window, sub_font, "1: Easy", white, (frame_x//2, frame_y//2 - 10))
    draw_text(game_window, sub_font, "2: Normal", white, (frame_x//2, frame_y//2 + 20))
    draw_text(game_window, sub_font, "3: Hard", white, (frame_x//2, frame_y//2 + 50))
    draw_text(game_window, sub_font, "Press 1/2/3", green, (frame_x//2, frame_y//2 + 110))
    pygame.display.update()

    while True:
        for event in pygame.event.get():
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_1:
                    return "easy"
                if event.key == pygame.K_2:
                    return "normal"
                if event.key == pygame.K_3:
                    return "hard"
            if event.type == pygame.QUIT:
                return None

def reinforcement_screen():
    game_window.fill((20, 40, 40))
    draw_text(game_window, title_font, "REINFORCEMENTS", white, (frame_x//2, frame_y//2 - 120))
    draw_text(game_window, sub_font, "1: ON (Infantry + Vehicles)", white, (frame_x//2, frame_y//2 - 10))
    draw_text(game_window, sub_font, "2: OFF (Tank Duel Only)", white, (frame_x//2, frame_y//2 + 20))
    draw_text(game_window, sub_font, "Press 1 or 2", green, (frame_x//2, frame_y//2 + 90))
    pygame.display.update()

    while True:
        for event in pygame.event.get():
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_1:
                    return True
                if event.key == pygame.K_2:
                    return False
            if event.type == pygame.QUIT:
                return None

def team_class_screen(mode="pvp"):
    gr_idx = 0
    bl_idx = 0
    if mode == "pvc":
        bl_idx = 0
    while True:
        game_window.fill((20, 40, 40))
        draw_text(game_window, title_font, "UNIT SELECTION", white, (frame_x // 2, 120))
        pygame.draw.rect(game_window, (180, 180, 180), (180, 170, frame_x - 360, 220), 1)
        pygame.draw.line(game_window, (120, 120, 120), (frame_x // 2, 170), (frame_x // 2, 390), 1)
        draw_text(game_window, sub_font, "GREEN", (80, 220, 80), (frame_x // 2 - 230, 205))
        draw_text(game_window, sub_font, "BLUE", (90, 140, 240), (frame_x // 2 + 230, 205))
        draw_text(game_window, ocr, TEAM_CLASS_OPTIONS[gr_idx], white, (frame_x // 2 - 230, 285))
        draw_text(game_window, ocr, TEAM_CLASS_OPTIONS[bl_idx], white, (frame_x // 2 + 230, 285))
        draw_text(game_window, sub_font, "Green: A/D", white, (frame_x // 2 - 230, 345))
        if mode == "pvp":
            draw_text(game_window, sub_font, "Blue: Left/Right", white, (frame_x // 2 + 230, 345))
        else:
            draw_text(game_window, sub_font, "Blue AI: AUTO MBT/TD", white, (frame_x // 2 + 230, 345))
        draw_text(game_window, sub_font, "Press Enter to continue", green, (frame_x // 2, 450))
        draw_text(game_window, sub_font, "Pick class: MBT (balanced) or TD (slow reload, high damage)", white, (frame_x // 2, 485))
        pygame.display.update()

        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                return None
            if event.type != pygame.KEYDOWN:
                continue
            if event.key == pygame.K_RETURN:
                return TEAM_CLASS_OPTIONS[gr_idx], TEAM_CLASS_OPTIONS[bl_idx]
            if event.key == pygame.K_a:
                gr_idx = (gr_idx - 1) % len(TEAM_CLASS_OPTIONS)
            elif event.key == pygame.K_d:
                gr_idx = (gr_idx + 1) % len(TEAM_CLASS_OPTIONS)
            elif mode == "pvp":
                if event.key == pygame.K_LEFT:
                    bl_idx = (bl_idx - 1) % len(TEAM_CLASS_OPTIONS)
                elif event.key == pygame.K_RIGHT:
                    bl_idx = (bl_idx + 1) % len(TEAM_CLASS_OPTIONS)

def loading_screen(duration_ms=900):
    start = pygame.time.get_ticks()
    pulse = 0
    while pygame.time.get_ticks() - start < duration_ms:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()
        game_window.fill((10, 18, 22))
        draw_text(game_window, title_font, "TANKTATION", (200, 200, 200), (frame_x//2, frame_y//2 - 60))
        dots = "." * ((pulse // 10) % 4)
        draw_text(game_window, sub_font, f"LOADING{dots}", (160, 200, 200), (frame_x//2, frame_y//2 + 10))
        pygame.display.update()
        pulse += 1
        pygame.time.delay(16)

def win_screen(winner_text, stats):
    pygame.mixer.music.fadeout(1000)
    game_window.fill((20, 40, 40))
    if "Green" in winner_text:
        title_color = (90, 220, 90)
    elif "Blue" in winner_text:
        title_color = (90, 140, 240)
    else:
        title_color = (200, 200, 200)
    draw_text(game_window, ocr_big, winner_text, title_color, (frame_x//2, frame_y//2 - 140))
    draw_text(game_window, sub_font, "Press R to play again", white, (frame_x//2, frame_y//2 + 200))
    draw_text(game_window, sub_font, "Press Esc to quit", white, (frame_x//2, frame_y//2 + 240))

    # Stats
    left_x = frame_x // 2 - 170
    right_x = frame_x // 2 + 170
    y0 = frame_y // 2 - 10
    line_h = 26

    draw_text(game_window, ocr, "GREEN", (80, 220, 80), (left_x, y0 - 30))
    draw_text(game_window, ocr, "BLUE", (80, 120, 220), (right_x, y0 - 30))

    for i, (label, g_val, b_val) in enumerate(stats):
        y = y0 + i * line_h
        draw_text(game_window, sub_font, label, white, (frame_x // 2, y))
        draw_text(game_window, sub_font, g_val, white, (left_x, y))
        draw_text(game_window, sub_font, b_val, white, (right_x, y))
    pygame.display.update()

    while True:
        for event in pygame.event.get():
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_r:
                    pygame.mixer.music.play(-1)
                    return True
                if event.key == pygame.K_ESCAPE:
                    pygame.mixer.music.play(-1)
                    return False
            if event.type == pygame.QUIT:
                return False

def run_game(mode="pvp", ai_level="normal", reinforcements_enabled=True, gr_class="MBT", bl_class="MBT"):
    loading_screen()
    global current_quality_mode, light_cache_ms, GAME_MODE_CURRENT, KOTH_CENTER, KOTH_RADIUS, SIEGE_GREEN_BASE, SIEGE_BLUE_BASE
    gr_tank_dead = False
    bl_tank_dead = False
    clock = pygame.time.Clock()
    show_perf = False
    quality_mode = "PERFORMANCE"
    current_quality_mode = quality_mode
    grx, gry = 120, 240
    blx, bly = 1160, 240
    gr_spawn = (120, 240)
    bl_spawn = (1160, 240)
    gr_hp = max_hp
    bl_hp = max_hp
    gr_lives = tank_lives_max
    bl_lives = tank_lives_max
    gr_protect_until = 0
    bl_protect_until = 0
    gr_dead_until = 0
    bl_dead_until = 0
    gr_death_fx_until = 0
    bl_death_fx_until = 0
    gr_turret_angle = 0
    bl_turret_angle = 180
    gr_turret_elev = 4.0
    bl_turret_elev = 4.0
    gr_turret_elev_target = 4.0
    bl_turret_elev_target = 4.0
    gr_chassis_angle = 0
    bl_chassis_angle = 180
    gr_vel = 0.0
    bl_vel = 0.0
    gr_chassis_av = 0.0
    bl_chassis_av = 0.0
    gr_turret_av = 0.0
    bl_turret_av = 0.0
    gr_engine_dmg = 0.0
    bl_engine_dmg = 0.0
    gr_turret_dmg = 0.0
    bl_turret_dmg = 0.0
    last_tank_died_time = 0
    
    bullets = []
    infantry_bullets = []
    infantry = []
    apcs = []
    jeeps = []
    humvees = []
    supply_drones = []
    attack_drones = []
    pending_infantry = []
    pending_vehicles = []
    repair_rings = []
    blowouts = []
    muzzle_flashes = []
    explosions = []
    engine_smoke = []
    track_marks = []
    casings = []
    theme = random.choice([PLAINS, DESERT, SNOW, CITY, VOLCANIC])
    if theme is PLAINS:
        biome_name = "plains"
    elif theme is DESERT:
        biome_name = "desert"
    elif theme is SNOW:
        biome_name = "snow"
    elif theme is CITY:
        biome_name = "city"
    else:
        biome_name = "volcanic"
    biome = theme["params"]
    obstacles = make_obstacles(theme)
    biome_speed = biome["speed"]
    biome_damage = biome["damage"]
    biome_spread = biome["spread"]
    biome_heat_cool = biome["heat_cool"]
    biome_heat_max = mg_heat_max * biome["heat_max"]
    biome_fuel = biome["fuel"]
    last_green_shot = 0
    last_blue_shot = 0
    last_green_mg = 0
    last_blue_mg = 0
    last_green_mg_sound = 0
    last_blue_mg_sound = 0

    running = True
    winner = None
    start_time = pygame.time.get_ticks()
    round_mode = pick_round_mode()
    hill_x = frame_x // 2
    hill_y = frame_y // 2
    hill_r = 250
    gr_barracks = {"team": "green", "x": 140, "y": frame_y // 2, "w": barracks_w, "h": barracks_h, "hp": barracks_hp_max, "hp_max": barracks_hp_max}
    bl_barracks = {"team": "blue", "x": frame_x - 140, "y": frame_y // 2, "w": barracks_w, "h": barracks_h, "hp": barracks_hp_max, "hp_max": barracks_hp_max}
    SIEGE_GREEN_BASE = (gr_barracks["x"], gr_barracks["y"])
    SIEGE_BLUE_BASE = (bl_barracks["x"], bl_barracks["y"])
    gr_barracks_rect = pygame.Rect(gr_barracks["x"] - barracks_w // 2, gr_barracks["y"] - barracks_h // 2, barracks_w, barracks_h)
    bl_barracks_rect = pygame.Rect(bl_barracks["x"] - barracks_w // 2, bl_barracks["y"] - barracks_h // 2, barracks_w, barracks_h)
    GAME_MODE_CURRENT = round_mode
    KOTH_CENTER = (hill_x, hill_y)
    KOTH_RADIUS = hill_r
    koth_target_ms = 5 * 60 * 1000
    gr_hill_ms = 0.0
    bl_hill_ms = 0.0
    gr_hill_ammo_acc = 0.0
    bl_hill_ammo_acc = 0.0
    koth_score = 0.0
    hill_owner = None
    hill_capture_rate = 8.0
    if round_mode == "KOTH":
        # KOTH uses objective victory, so lives are effectively infinite.
        gr_lives = 999
        bl_lives = 999
        # Always keep the hill in the exact center and clear a playable capture zone.
        hill_x = frame_x // 2
        hill_y = frame_y // 2
        # In volcanic biome, clear a bigger zone so the volcano/crater never blocks KOTH flow.
        hill_clear_pad = 140 if theme is VOLCANIC else 90
        kept_obs = []
        for obs in obstacles:
            r = obs.get('rect')
            if r is None:
                kept_obs.append(obs)
                continue
            # Approximate rect-circle overlap by nearest-point distance.
            nx = min(max(hill_x, r.left), r.right)
            ny = min(max(hill_y, r.top), r.bottom)
            d = math.hypot(nx - hill_x, ny - hill_y)
            if d <= (hill_r + hill_clear_pad):
                continue
            kept_obs.append(obs)
        obstacles = kept_obs
    elif round_mode == "SIEGE":
        kept_obs = []
        clear_pad = 36
        for obs in obstacles:
            r = obs.get('rect')
            if r is None:
                kept_obs.append(obs)
                continue
            if r.inflate(clear_pad * 2, clear_pad * 2).colliderect(gr_barracks_rect) or r.inflate(clear_pad * 2, clear_pad * 2).colliderect(bl_barracks_rect):
                continue
            kept_obs.append(obs)
        obstacles = kept_obs

        # Add destructible perimeter wall segments around each SIEGE base.
        gr_barracks['walls'] = create_barracks_wall_segments(gr_barracks)
        obstacles.extend(gr_barracks['walls'])
        bl_barracks['walls'] = create_barracks_wall_segments(bl_barracks)
        obstacles.extend(bl_barracks['walls'])
    gr_shots = 0
    bl_shots = 0
    gr_hits = 0
    bl_hits = 0
    gr_damage_dealt = 0.0
    bl_damage_dealt = 0.0
    gr_streak = 0
    bl_streak = 0
    gr_best_streak = 0
    bl_best_streak = 0
    gr_mg_heat = 0.0
    bl_mg_heat = 0.0
    gr_overheat = False
    bl_overheat = False
    gr_ammo_ap = cannon_ap_max
    gr_ammo_he = cannon_he_max
    gr_ammo_atgm = cannon_atgm_max
    bl_ammo_ap = cannon_ap_max
    bl_ammo_he = cannon_he_max
    bl_ammo_atgm = cannon_atgm_max
    gr_ammo_type = "AP"
    bl_ammo_type = "AP"
    gr_mg_ammo = mg_ammo_max
    bl_mg_ammo = mg_ammo_max
    gr_fuel = fuel_max
    bl_fuel = fuel_max
    shake_timer = 0.0
    hit_pause_until = 0
    gr_recoil = 0.0
    bl_recoil = 0.0
    gr_turret_recoil = 0.0
    bl_turret_recoil = 0.0
    gr_speed_mult = 1.0
    bl_speed_mult = 1.0
    gr_damage_mult = 1.0
    bl_damage_mult = 1.0
    gr_spread_mult = 1.0
    bl_spread_mult = 1.0
    airdrops = []
    smokes = []
    mines = []
    gr_repair_ammo = repair_ammo_max
    bl_repair_ammo = repair_ammo_max
    last_gr_repair = -repair_cd_ms
    last_bl_repair = -repair_cd_ms
    next_airdrop_time = pygame.time.get_ticks() + int(random.uniform(airdrop_interval_min, airdrop_interval_max) * 1000)
    next_infantry_time = pygame.time.get_ticks() + int(random.uniform(infantry_wave_min, infantry_wave_max) * 1000)
    next_comeback_time = pygame.time.get_ticks() + 18000
    next_mine_time = pygame.time.get_ticks() + int(random.uniform(mine_spawn_min, mine_spawn_max) * 1000)
    next_supply_drone = pygame.time.get_ticks() + 7000
    next_attack_drone = pygame.time.get_ticks() + 9000
    first_shot_fired = False
    last_green_smoke = -smoke_cd_ms
    last_blue_smoke = -smoke_cd_ms
    gr_smoke_ammo = smoke_ammo_max
    bl_smoke_ammo = smoke_ammo_max
    last_scuttle_tap = -9999
    gr_armor_until = 0
    bl_armor_until = 0
    gr_rapid_until = 0
    bl_rapid_until = 0
    commander_teams = set()

    if mode == "pvc":
        bl_class = random.choice(["MBT", "TD"])

    if gr_class == "TD":
        gr_hp = int(max_hp * 0.75)
        gr_damage_mult *= 1.35
        gr_speed_mult *= 0.9
        gr_mg_ammo = min(gr_mg_ammo, 220)
    if bl_class == "TD":
        bl_hp = int(max_hp * 0.75)
        bl_damage_mult *= 1.35
        bl_speed_mult *= 0.9
        bl_mg_ammo = min(bl_mg_ammo, 220)

    ai_profiles = {
        "easy": {"cannon_cd": 1.35, "mg_cd": 1.35, "aim_jitter": 6.0, "damage": 0.85, "move": 0.9},
        "normal": {"cannon_cd": 1.0, "mg_cd": 1.0, "aim_jitter": 3.0, "damage": 1.0, "move": 1.0},
        "hard": {"cannon_cd": 0.85, "mg_cd": 0.85, "aim_jitter": 1.5, "damage": 1.1, "move": 1.05},
    }
    if mode != "pvc":
        ai_level = "normal"
    ai_profile = ai_profiles.get(ai_level, ai_profiles["normal"])
    ai_cannon_cd = int(bull_rld * ai_profile["cannon_cd"])
    ai_mg_cd = int(mg_rld * ai_profile["mg_cd"])
    ai_aim_jitter = ai_profile["aim_jitter"]
    ai_damage_mult = ai_profile["damage"]
    ai_move_mult = ai_profile["move"]

    weather_type = pick_weather(biome_name)
    next_weather_change = pygame.time.get_ticks() + weather_cycle_ms
    weather_particles = []
    weather_spawn_accum = 0.0
    weather_wind_dir = random.uniform(0, 360)
    weather_wind_strength = WEATHER_EFFECTS.get(weather_type, WEATHER_EFFECTS["clear"]).get("wind", 0.0)
    last_ai_think = 0
    ai_orbit_dir = random.choice([-1, 1])
    ai_next_orbit_swap = pygame.time.get_ticks() + random.randint(1800, 3600)
    ai_suppress_until = 0
    ai_retreat_until = 0
    ai_last_target_kind = "tank"

    settings_open = False
    dragging_slider = None
    night_vision = False
    music_vol = default_music_vol
    sfx_vol = default_sfx_vol
    weather_enabled = False
    day_speed_mult = 1.0
    night_dark_setting = night_dark_alpha
    particle_enabled = False
    kill_feed = []
    auto_low_active = False
    auto_low_release_at = 0
    low_fps_accum_ms = 0.0
    push_kill_feed(kill_feed, f"ROUND MODE: {round_mode}", (230, 230, 150), pygame.time.get_ticks())
    if round_mode == "SIEGE":
        push_kill_feed(kill_feed, "OBJECTIVE: DESTROY ENEMY BARRACKS", (255, 220, 150), pygame.time.get_ticks())
    push_kill_feed(kill_feed, f"GREEN CLASS: {gr_class}", (130, 255, 130), pygame.time.get_ticks())
    push_kill_feed(kill_feed, f"BLUE CLASS: {bl_class}", (140, 180, 255), pygame.time.get_ticks())

    while running:
        raw_dt = clock.tick(fps) / 1000.0
        now = pygame.time.get_ticks()
        paused = now < hit_pause_until
        dt = 0.0 if paused else raw_dt
        fps_now = (1.0 / raw_dt) if raw_dt > 0 else fps
        if fps_now < auto_low_enter_fps:
            low_fps_accum_ms += raw_dt * 1000.0
        else:
            low_fps_accum_ms = max(0.0, low_fps_accum_ms - raw_dt * 900.0)
        if (not auto_low_active) and low_fps_accum_ms >= auto_low_trigger_ms:
            auto_low_active = True
            auto_low_release_at = now + auto_low_hold_ms
            push_kill_feed(kill_feed, "AUTO LOW ENABLED", (255, 180, 120), now)
        if auto_low_active and now >= auto_low_release_at and fps_now > auto_low_exit_fps and low_fps_accum_ms < 200.0:
            auto_low_active = False
            push_kill_feed(kill_feed, "AUTO LOW DISABLED", (170, 255, 170), now)

        active_quality = "PERFORMANCE" if auto_low_active else quality_mode
        if active_quality == "PERFORMANCE":
            ai_think_base = 360
            quality_particle_cap = 80
            quality_spawn_inf = 1
            quality_spawn_veh = 1
            light_cache_ms = 160
            ai_max_veh_cap = 3
            ai_max_inf_cap = 10
        elif active_quality == "CINEMATIC":
            ai_think_base = 140
            quality_particle_cap = 520
            quality_spawn_inf = 5
            quality_spawn_veh = 2
            light_cache_ms = 36
            ai_max_veh_cap = max_ai_vehicles
            ai_max_inf_cap = ai_max_infantry_team
        else:
            ai_think_base = ai_think_ms
            quality_particle_cap = max_weather_particles
            quality_spawn_inf = spawn_budget_infantry
            quality_spawn_veh = spawn_budget_vehicles
            light_cache_ms = 60
            ai_max_veh_cap = max_ai_vehicles
            ai_max_inf_cap = ai_max_infantry_team
        runtime_reinf = reinforcements_enabled
        green_reinf_alive = runtime_reinf and (gr_lives > 0) and (not gr_tank_dead) and gr_hp > 0
        blue_reinf_alive = runtime_reinf and (bl_lives > 0) and (not bl_tank_dead) and bl_hp > 0
        ai_scale = max(0.4, min(1.0, fps_now / ai_fps_floor))
        ai_think_interval = int(ai_think_base / max(ai_scale, 0.45))
        ai_think = (now - last_ai_think) >= ai_think_interval
        if ai_think:
            last_ai_think = now
        ai_max_veh = min(ai_max_veh_cap, max(1, int(max_ai_vehicles * ai_scale)))
        ai_max_inf = min(ai_max_inf_cap, max(6, int(ai_max_infantry_team * ai_scale)))
        gr_ammo_type = ensure_ammo_type(gr_ammo_type, gr_ammo_ap, gr_ammo_he, gr_ammo_atgm)
        bl_ammo_type = ensure_ammo_type(bl_ammo_type, bl_ammo_ap, bl_ammo_he, bl_ammo_atgm)
        elapsed_ms = now - start_time
        cycle_t = ((elapsed_ms * day_speed_mult) % day_cycle_ms) / max(day_cycle_ms, 1)
        hour = (day_start_hour + cycle_t * 24.0) % 24.0
        hour_i = int(hour)
        minute_i = int((hour - hour_i) * 60)
        if 5 <= hour < 12:
            day_state = "Morning"
            # Fade from dawn darkness (05:00) to bright day (12:00).
            t = (hour - 5.0) / 7.0
            night_alpha = int(night_dark_setting * max(0.0, 1.0 - t))
        elif 12 <= hour < 18:
            day_state = "Afternoon"
            night_alpha = 0
        else:
            day_state = "Evening"
            # Evening/night darkness: ramps up after 18:00 and stays dark until 05:00.
            if hour >= 18:
                t = min(1.0, (hour - 18.0) / 3.0)  # reach full dark by ~21:00
            else:
                t = 1.0
            night_alpha = int(night_dark_setting * t)
        weather_label = "" if weather_type == "clear" else weather_type.upper()
        clock_text = f"{hour_i:02d}:{minute_i:02d}  {day_state}" + (f"  {weather_label}" if weather_label else "")
        q_label = "A" if auto_low_active else active_quality[0]
        clock_text += f"  Q:{q_label}"
        gr_hp_ratio = max(0.0, min(1.0, gr_hp / max_hp))
        bl_hp_ratio = max(0.0, min(1.0, bl_hp / max_hp))
        hill_control = None
        hill_capturing = None
        if round_mode == "KOTH":
            g_units = 0
            b_units = 0
            if (not gr_tank_dead) and math.hypot(grx - hill_x, gry - hill_y) <= hill_r:
                g_units += 1
            if (not bl_tank_dead) and math.hypot(blx - hill_x, bly - hill_y) <= hill_r:
                b_units += 1
            g_units += sum(1 for u in infantry if u['team'] == 'green' and math.hypot(u['x'] - hill_x, u['y'] - hill_y) <= hill_r)
            b_units += sum(1 for u in infantry if u['team'] == 'blue' and math.hypot(u['x'] - hill_x, u['y'] - hill_y) <= hill_r)
            g_units += sum(1 for v in apcs + jeeps + humvees if v['team'] == 'green' and math.hypot(v['x'] - hill_x, v['y'] - hill_y) <= hill_r)
            b_units += sum(1 for v in apcs + jeeps + humvees if v['team'] == 'blue' and math.hypot(v['x'] - hill_x, v['y'] - hill_y) <= hill_r)
            unit_diff = g_units - b_units
            if unit_diff > 0:
                hill_capturing = "green"
            elif unit_diff < 0:
                hill_capturing = "blue"
            cap_delta = max(-36.0, min(36.0, unit_diff * hill_capture_rate * dt))
            koth_score = max(-100.0, min(100.0, koth_score + cap_delta))
            prev_owner = hill_owner
            # Neutral band: hill is neutral when control drops below 50%.
            if hill_owner == "green" and koth_score < 50.0:
                hill_owner = None
            elif hill_owner == "blue" and koth_score > -50.0:
                hill_owner = None
            if hill_owner is None:
                if koth_score >= 50.0:
                    hill_owner = "green"
                elif koth_score <= -50.0:
                    hill_owner = "blue"
            if hill_owner != prev_owner:
                if hill_owner == "green":
                    push_kill_feed(kill_feed, "HILL CAPTURED: GREEN", (120, 255, 120), now)
                elif hill_owner == "blue":
                    push_kill_feed(kill_feed, "HILL CAPTURED: BLUE", (130, 180, 255), now)
                elif prev_owner is not None:
                    push_kill_feed(kill_feed, "HILL LOST", (220, 220, 220), now)
            hill_control = hill_owner
            dt_ms = dt * 1000.0
            if hill_owner == "green":
                gr_hill_ms += dt_ms
                gr_hill_ammo_acc += dt_ms
            elif hill_owner == "blue":
                bl_hill_ms += dt_ms
                bl_hill_ammo_acc += dt_ms
            # Ammo replenish per minute while controlling hill
            while gr_hill_ammo_acc >= 60000:
                gr_hill_ammo_acc -= 60000
                gr_ammo_ap = min(cannon_ap_max, gr_ammo_ap + 1)
                gr_ammo_he = min(cannon_he_max, gr_ammo_he + 1)
                gr_ammo_atgm = min(cannon_atgm_max, gr_ammo_atgm + 1)
                gr_mg_ammo = min(mg_ammo_max, gr_mg_ammo + 20)
            while bl_hill_ammo_acc >= 60000:
                bl_hill_ammo_acc -= 60000
                bl_ammo_ap = min(cannon_ap_max, bl_ammo_ap + 1)
                bl_ammo_he = min(cannon_he_max, bl_ammo_he + 1)
                bl_ammo_atgm = min(cannon_atgm_max, bl_ammo_atgm + 1)
                bl_mg_ammo = min(mg_ammo_max, bl_mg_ammo + 20)
            clock_text += f"  MODE:KOTH G:{int(gr_hill_ms/1000)} B:{int(bl_hill_ms/1000)}"
        elif round_mode == "SIEGE":
            clock_text += f"  MODE:SIEGE G:{int(max(0, gr_barracks['hp']))} B:{int(max(0, bl_barracks['hp']))}"
        else:
            clock_text += "  MODE:FFA"
        gr_koth_dmg = 1.18 if hill_control == "green" else 1.0
        bl_koth_dmg = 1.18 if hill_control == "blue" else 1.0
        gr_damage_factor = 0.6 + 0.4 * gr_hp_ratio
        bl_damage_factor = 0.6 + 0.4 * bl_hp_ratio
        gr_move_factor = 0.7 + 0.3 * gr_hp_ratio
        bl_move_factor = 0.7 + 0.3 * bl_hp_ratio
        gr_turn_factor = 0.7 + 0.3 * gr_hp_ratio
        bl_turn_factor = 0.7 + 0.3 * bl_hp_ratio
        gr_reload_mult = 1.0 + (1.0 - gr_hp_ratio) * 0.6
        bl_reload_mult = 1.0 + (1.0 - bl_hp_ratio) * 0.6
        gr_spread_damage = (1.0 - gr_hp_ratio) * 6.0
        bl_spread_damage = (1.0 - bl_hp_ratio) * 6.0
        gr_engine_mult = max(0.55, 1.0 - gr_engine_dmg * 0.35)
        bl_engine_mult = max(0.55, 1.0 - bl_engine_dmg * 0.35)
        gr_turret_mult = max(0.5, 1.0 - gr_turret_dmg * 0.45)
        bl_turret_mult = max(0.5, 1.0 - bl_turret_dmg * 0.45)
        gr_reload_mult *= (1.0 + gr_turret_dmg * 0.45)
        bl_reload_mult *= (1.0 + bl_turret_dmg * 0.45)

        if weather_enabled and now >= next_weather_change:
            weather_type = pick_weather(biome_name)
            next_weather_change = now + weather_cycle_ms
            if weather_type == "clear":
                weather_particles = []
            weather_wind_dir = random.uniform(0, 360)
            weather_wind_strength = WEATHER_EFFECTS.get(weather_type, WEATHER_EFFECTS["clear"]).get("wind", 0.0)
        if not weather_enabled:
            weather_type = "clear"
            weather_particles = []
            weather_wind_strength = 0.0

        effects = WEATHER_EFFECTS.get(weather_type, WEATHER_EFFECTS["clear"])
        weather_speed = effects["speed"]
        weather_accel = effects["accel"]
        weather_turn = effects["turn"]
        weather_spread = effects["spread"]
        weather_damage = effects["damage"]
        weather_reload = effects["reload"]
        weather_fuel = effects["fuel"]
        weather_heat_cool = effects["heat_cool"]
        weather_wind_strength = effects.get("wind", weather_wind_strength)
        wind_rad = math.radians(weather_wind_dir)
        wind_vec = (math.cos(wind_rad) * weather_wind_strength * wind_base_speed,
                    -math.sin(wind_rad) * weather_wind_strength * wind_base_speed)
        weather_wind_dir = (weather_wind_dir + (random.random() - 0.5) * 8.0 * dt) % 360

        gr_class_prof = class_cannon_profile(gr_class)
        bl_class_prof = class_cannon_profile(bl_class)
        gr_base_cannon = bull_rld * gr_class_prof.get("reload_mul", 1.0) * (0.6 if gr_rapid_until > now else 1.0) * weather_reload * gr_reload_mult
        gr_cannon_cd = cannon_reload_ms(gr_ammo_type, gr_base_cannon)
        base_bl_cannon = (ai_cannon_cd if mode == "pvc" else bull_rld) * bl_class_prof.get("reload_mul", 1.0) * (0.6 if bl_rapid_until > now else 1.0) * weather_reload * bl_reload_mult
        bl_cannon_cd = cannon_reload_ms(bl_ammo_type, base_bl_cannon)

        spawn_rate = 0.0
        if weather_type == "rain":
            spawn_rate = 280.0
        elif weather_type == "snow":
            spawn_rate = 120.0
        elif weather_type == "sand":
            spawn_rate = 180.0
        elif weather_type == "ash":
            spawn_rate = 140.0
        if not particle_enabled:
            spawn_rate = 0.0

        weather_spawn_accum += spawn_rate * dt
        spawn_count = int(weather_spawn_accum)
        if spawn_count > 0:
            weather_spawn_accum -= spawn_count
            for _ in range(spawn_count):
                weather_particles.append({
                    'x': random.uniform(0, frame_x),
                    'y': random.uniform(-40, 0),
                })
            if len(weather_particles) > quality_particle_cap:
                weather_particles = weather_particles[-quality_particle_cap:]

        next_weather_particles = []
        for p in weather_particles:
            # Wind influence (weather particles drift with wind)
            p['x'] += wind_vec[0] * dt
            p['y'] += wind_vec[1] * dt
            if weather_type == "rain":
                p['x'] += -60 * dt
                p['y'] += 520 * dt
            elif weather_type == "snow":
                p['x'] += random.uniform(-10, 10) * dt
                p['y'] += 80 * dt
            elif weather_type == "sand":
                p['x'] += 120 * dt
                p['y'] += 140 * dt
            elif weather_type == "ash":
                p['x'] += 30 * dt
                p['y'] += 110 * dt
            if -60 <= p['x'] <= frame_x + 60 and -60 <= p['y'] <= frame_y + 60:
                next_weather_particles.append(p)
        weather_particles = next_weather_particles

        pygame.mixer.music.set_volume(music_vol)
        if mg_sound:
            mg_sound.set_volume(0.5 * sfx_vol)
        if explosion_sound:
            explosion_sound.set_volume(0.9 * sfx_vol)
        if cannon_sound:
            cannon_sound.set_volume(0.9 * sfx_vol)
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()
            elif event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
                clicked_settings = get_settings_icon_rect().collidepoint(event.pos)
                if clicked_settings:
                    settings_open = not settings_open
                if settings_open and get_settings_panel_rect().collidepoint(event.pos):
                    sliders = get_settings_slider_rects()
                    for key, rect in sliders.items():
                        if rect.collidepoint(event.pos):
                            dragging_slider = key
                            break
                if settings_open and dragging_slider is None:
                    # Toggle weather / particles when clicking their label row
                    panel = get_settings_panel_rect()
                    if panel.collidepoint(event.pos):
                        my = event.pos[1]
                        line = 28
                        if abs(my - (panel.y + 18 + line * 5)) <= 10:
                            weather_enabled = not weather_enabled
                        if abs(my - (panel.y + 18 + line * 6)) <= 10:
                            particle_enabled = not particle_enabled
                        if abs(my - (panel.y + 18 + line * 7)) <= 10:
                            quality_mode = cycle_quality_mode(quality_mode)
                            current_quality_mode = quality_mode
                            push_kill_feed(kill_feed, f"QUALITY {quality_mode}", (255, 220, 140), now)
                if (not clicked_settings) and (not settings_open or not get_settings_panel_rect().collidepoint(event.pos)) and (not gr_tank_dead) and ammo_count_by_type(gr_ammo_type, gr_ammo_ap, gr_ammo_he, gr_ammo_atgm) > 0 and len(bullets) < bullet_limit and (now - last_green_shot) >= gr_cannon_cd:
                    gr_protect_until = 0
                    first_shot_fired = True
                    muzzle_offset = gr_tr.get_width() * 0.5
                    bl_target_smoke = is_in_smoke(blx, bly, smokes, now)
                    cannon_spread = 1.5 * weather_spread + gr_spread_damage
                    fire_angle = gr_turret_angle + random.uniform(-cannon_spread, cannon_spread)
                    fire_angle = apply_smoke_jitter(fire_angle, bl_target_smoke)
                    gr_rad = math.radians(fire_angle)
                    bullets.append(build_cannon_bullet(
                        'green',
                        grx + math.cos(gr_rad) * muzzle_offset,
                        gry - math.sin(gr_rad) * muzzle_offset,
                        fire_angle,
                        gr_damage_mult * biome_damage * weather_damage * gr_damage_factor * gr_koth_dmg * gr_class_prof.get("damage_mul", 1.0),
                        gr_ammo_type,
                        gr_class,
                        gr_turret_elev
                    ))
                    gr_shots += 1
                    gr_ammo_ap, gr_ammo_he, gr_ammo_atgm = spend_ammo(gr_ammo_type, gr_ammo_ap, gr_ammo_he, gr_ammo_atgm)
                    gr_ammo_type = ensure_ammo_type(gr_ammo_type, gr_ammo_ap, gr_ammo_he, gr_ammo_atgm)
                    gr_recoil = recoil_kick
                    gr_turret_recoil = recoil_kick * 0.9
                    shake_timer = max(shake_timer, shake_duration)
                    if cannon_sound:
                        cannon_sound.play()
                    muzzle_flashes.append({
                        'x': grx + math.cos(gr_rad) * muzzle_offset,
                        'y': gry - math.sin(gr_rad) * muzzle_offset,
                        'angle': fire_angle,
                        't': now,
                        'scale': 1.0,
                    })
                    last_green_shot = now
            elif event.type == pygame.MOUSEBUTTONDOWN and event.button == 2:
                if not gr_tank_dead and gr_smoke_ammo > 0 and (now - last_green_smoke) >= smoke_cd_ms:
                    for i in range(smoke_puff_count):
                        smokes.append({
                            'x': grx + random.uniform(-smoke_puff_spread, smoke_puff_spread),
                            'y': gry + random.uniform(-smoke_puff_spread, smoke_puff_spread),
                            't': now + i * 40,
                            'r0': random.randint(6, 12),
                        })
                    last_green_smoke = now
                    gr_smoke_ammo -= 1
            elif event.type == pygame.KEYDOWN:
                if mode == "pvc":
                    if event.key == pygame.K_r:
                        return ("RESTART", None)
                    if event.key == pygame.K_ESCAPE:
                        return ("LEAVE", None)
                    if event.key == pygame.K_x:
                        if (now - last_scuttle_tap) <= 450 and not gr_tank_dead and gr_lives > 0 and gr_hp > 0:
                            gr_hp = 0
                            gr_protect_until = 0
                            last_scuttle_tap = -9999
                        else:
                            last_scuttle_tap = now
                if event.key == pygame.K_z:
                    gr_ammo_type = ensure_ammo_type(cycle_ammo_type(gr_ammo_type), gr_ammo_ap, gr_ammo_he, gr_ammo_atgm)
                if mode != "pvc" and event.key == pygame.K_PERIOD:
                    bl_ammo_type = ensure_ammo_type(cycle_ammo_type(bl_ammo_type), bl_ammo_ap, bl_ammo_he, bl_ammo_atgm)
                if event.key == pygame.K_F2:
                    night_vision = not night_vision
                if event.key == pygame.K_F3:
                    show_perf = not show_perf
                    push_kill_feed(kill_feed, f"DEBUG {'ON' if show_perf else 'OFF'}", (180, 220, 255), now)
                if event.key == pygame.K_F4:
                    quality_mode = cycle_quality_mode(quality_mode)
                    current_quality_mode = quality_mode
                    push_kill_feed(kill_feed, f"QUALITY {quality_mode}", (255, 220, 140), now)
                if event.key == pygame.K_RETURN and not bl_tank_dead and ammo_count_by_type(bl_ammo_type, bl_ammo_ap, bl_ammo_he, bl_ammo_atgm) > 0 and len(bullets) < bullet_limit and (now - last_blue_shot) >= bl_cannon_cd:
                    bl_protect_until = 0
                    first_shot_fired = True
                    muzzle_offset = bl_tr.get_width() * 0.5
                    gr_target_smoke = is_in_smoke(grx, gry, smokes, now)
                    cannon_spread = 1.5 * weather_spread + bl_spread_damage
                    fire_angle = bl_turret_angle + random.uniform(-cannon_spread, cannon_spread)
                    fire_angle = apply_smoke_jitter(fire_angle, gr_target_smoke)
                    bl_rad = math.radians(fire_angle)
                    bullets.append(build_cannon_bullet(
                        'blue',
                        blx + math.cos(bl_rad) * muzzle_offset,
                        bly - math.sin(bl_rad) * muzzle_offset,
                        fire_angle,
                        bl_damage_mult * biome_damage * weather_damage * bl_damage_factor * bl_koth_dmg * bl_class_prof.get("damage_mul", 1.0),
                        bl_ammo_type,
                        bl_class,
                        bl_turret_elev
                    ))
                    bl_shots += 1
                    bl_ammo_ap, bl_ammo_he, bl_ammo_atgm = spend_ammo(bl_ammo_type, bl_ammo_ap, bl_ammo_he, bl_ammo_atgm)
                    bl_ammo_type = ensure_ammo_type(bl_ammo_type, bl_ammo_ap, bl_ammo_he, bl_ammo_atgm)
                    bl_recoil = recoil_kick
                    bl_turret_recoil = recoil_kick * 0.9
                    shake_timer = max(shake_timer, shake_duration)
                    if cannon_sound:
                        cannon_sound.play()
                    muzzle_flashes.append({
                        'x': blx + math.cos(bl_rad) * muzzle_offset,
                        'y': bly - math.sin(bl_rad) * muzzle_offset,
                        'angle': bl_turret_angle,
                        't': now,
                        'scale': 1.0,
                    })
                    last_blue_shot = now
                if settings_open and event.key == pygame.K_ESCAPE:
                    settings_open = False
                elif event.key == pygame.K_RCTRL:
                    if not bl_tank_dead and bl_smoke_ammo > 0 and (now - last_blue_smoke) >= smoke_cd_ms:
                        for i in range(smoke_puff_count):
                            smokes.append({
                                'x': blx + random.uniform(-smoke_puff_spread, smoke_puff_spread),
                                'y': bly + random.uniform(-smoke_puff_spread, smoke_puff_spread),
                                't': now + i * 40,
                                'r0': random.randint(6, 12),
                            })
                        last_blue_smoke = now
                        bl_smoke_ammo -= 1
                elif event.key == pygame.K_f:
                    if not gr_tank_dead and gr_repair_ammo > 0 and (now - last_gr_repair) >= repair_cd_ms:
                        gr_hp = min(max_hp, gr_hp + repair_amount)
                        gr_engine_dmg = max(0.0, gr_engine_dmg - 0.35)
                        gr_turret_dmg = max(0.0, gr_turret_dmg - 0.35)
                        repair_rings.append({'x': grx, 'y': gry, 't': now})
                        gr_repair_ammo -= 1
                        last_gr_repair = now
                elif event.key == pygame.K_RALT:
                    if not bl_tank_dead and bl_repair_ammo > 0 and (now - last_bl_repair) >= repair_cd_ms:
                        bl_hp = min(max_hp, bl_hp + repair_amount)
                        bl_engine_dmg = max(0.0, bl_engine_dmg - 0.35)
                        bl_turret_dmg = max(0.0, bl_turret_dmg - 0.35)
                        repair_rings.append({'x': blx, 'y': bly, 't': now})
                        bl_repair_ammo -= 1
                        last_bl_repair = now
            elif event.type == pygame.MOUSEBUTTONUP and event.button == 1:
                dragging_slider = None
            elif event.type == pygame.MOUSEMOTION and dragging_slider and settings_open:
                sliders = get_settings_slider_rects()
                rect = sliders.get(dragging_slider)
                if rect:
                    t = (event.pos[0] - rect.x) / max(rect.w, 1)
                    t = max(0.0, min(1.0, t))
                    if dragging_slider == "music":
                        music_vol = 0.0 + t * 1.5
                    elif dragging_slider == "sfx":
                        sfx_vol = 0.0 + t * 1.5
                    elif dragging_slider == "day_speed":
                        day_speed_mult = 0.5 + t * 1.5
                    elif dragging_slider == "night_dark":
                        night_dark_setting = 80 + t * 150

        keys_pressed = pygame.key.get_pressed()
        mouse_pressed = pygame.mouse.get_pressed()
        prev_grx, prev_gry = grx, gry
        prev_blx, prev_bly = blx, bly
        prev_gr_turret_angle = gr_turret_angle
        prev_bl_turret_angle = bl_turret_angle

        moving_green = (keys_pressed[pygame.K_w] or keys_pressed[pygame.K_s])
        moving_blue = keys_pressed[pygame.K_UP] or keys_pressed[pygame.K_DOWN]
        ai_move_dir = 0

        gr_turn_input = 0
        if keys_pressed[pygame.K_a]:
            gr_turn_input += 1
        if keys_pressed[pygame.K_d]:
            gr_turn_input -= 1

        bl_turn_input = 0
        if mode == "pvc":
            # PvC tank brain: pick a target, keep a useful range, evade incoming fire,
            # and only commit to objectives when it is not about to get punished.
            threat_score = 0.0
            for b in bullets:
                if b.get('owner') != 'green':
                    continue
                bx = b.get('x', blx)
                by = b.get('y', bly)
                bvx = b.get('vx', 0.0)
                bvy = b.get('vy', 0.0)
                to_ai_x = blx - bx
                to_ai_y = bly - by
                dist_to_b = math.hypot(to_ai_x, to_ai_y)
                closing = (bvx * to_ai_x + bvy * to_ai_y) > 0
                if closing and dist_to_b < 260:
                    threat_score += 2.0 if b.get('type') == 'cannon' else 0.45
            if threat_score >= 1.7:
                ai_retreat_until = max(ai_retreat_until, now + 900)
                if bl_smoke_ammo > 0 and (now - last_blue_smoke) >= smoke_cd_ms:
                    for i in range(smoke_puff_count):
                        smokes.append({
                            'x': blx + random.uniform(-smoke_puff_spread, smoke_puff_spread),
                            'y': bly + random.uniform(-smoke_puff_spread, smoke_puff_spread),
                            't': now + i * 40,
                            'r0': random.randint(6, 12),
                        })
                    last_blue_smoke = now
                    bl_smoke_ammo -= 1

            target_candidates = []
            if not gr_tank_dead:
                target_candidates.append(("tank", grx, gry, 1000.0))
            for v in apcs + jeeps + humvees:
                if v.get('team') == 'green' and v.get('hp', 0) > 0:
                    priority = {"apc": 420.0, "humvee": 260.0, "jeep": 190.0}.get(v.get('type'), 160.0)
                    target_candidates.append(("vehicle", v['x'], v['y'], priority))
            if infantry:
                for u in infantry:
                    if u.get('team') == 'green' and u.get('hp', 0) > 0:
                        priority = 170.0 if u.get('role') == 'at' else 80.0
                        target_candidates.append(("infantry", u['x'], u['y'], priority))
            if GAME_MODE_CURRENT == "SIEGE":
                target_candidates.append(("objective", gr_barracks['x'], gr_barracks['y'], 720.0))
            if not target_candidates:
                target_candidates.append(("fallback", grx, gry, 1.0))

            best = None
            best_score = -1e9
            for kind, tx, ty, priority in target_candidates:
                d = max(1.0, math.hypot(tx - blx, ty - bly))
                los_bonus = 160.0 if line_of_sight_clear(blx, bly, tx, ty, obstacles) else -80.0
                objective_bonus = 260.0 if GAME_MODE_CURRENT == "KOTH" and kind == "tank" and math.hypot(tx - KOTH_CENTER[0], ty - KOTH_CENTER[1]) <= KOTH_RADIUS * 1.2 else 0.0
                score = priority + los_bonus + objective_bonus - d * 0.22
                if score > best_score:
                    best_score = score
                    best = (kind, tx, ty)
            ai_last_target_kind, ai_target_x, ai_target_y = best
            dx = ai_target_x - blx
            dy = ai_target_y - bly
            dist = math.hypot(dx, dy)
            has_los = line_of_sight_clear(blx, bly, ai_target_x, ai_target_y, obstacles)
            target_angle = (math.degrees(math.atan2(-dy, dx))) % 360
            # turret tracks target smoothly
            turret_turn_spd = (230.0 if has_los else 165.0) * weather_turn * bl_turn_factor
            tdiff = (target_angle - bl_turret_angle + 540) % 360 - 180
            max_step = turret_turn_spd * dt
            if abs(tdiff) > max_step:
                bl_turret_angle = (bl_turret_angle + max_step * (1 if tdiff > 0 else -1)) % 360
            else:
                bl_turret_angle = target_angle

            if now >= ai_next_orbit_swap:
                ai_orbit_dir *= -1
                ai_next_orbit_swap = now + random.randint(1600, 3600)

            # Chassis steering target: objective-aware, but fights from a standoff range.
            move_target_x, move_target_y = ai_target_x, ai_target_y
            desired_range = 330 if bl_class == "TD" else 260
            if GAME_MODE_CURRENT == "KOTH":
                hx, hy = KOTH_CENTER
                hdist = math.hypot(blx - hx, bly - hy)
                hill_enemy = math.hypot(ai_target_x - hx, ai_target_y - hy) <= KOTH_RADIUS * 1.15
                if hdist > KOTH_RADIUS * 0.78 and (not hill_enemy or threat_score < 1.0):
                    move_target_x, move_target_y = hx, hy
                    desired_range = 120
            elif GAME_MODE_CURRENT == "SIEGE" and ai_last_target_kind == "objective":
                desired_range = 360
            if not has_los and ai_last_target_kind != "objective":
                # Slide toward a side angle to reacquire line of sight instead of tailgating.
                side = math.radians(target_angle + ai_orbit_dir * 58)
                move_target_x = blx + math.cos(side) * 180
                move_target_y = bly - math.sin(side) * 180
            mdx = move_target_x - blx
            mdy = move_target_y - bly
            move_angle = (math.degrees(math.atan2(-mdy, mdx))) % 360
            # chassis steers toward move target
            diff = (move_angle - bl_chassis_angle + 540) % 360 - 180
            if abs(diff) > 8:
                bl_turn_input = 1 if diff > 0 else -1
            move_dist = math.hypot(mdx, mdy)
            # AI ammo selection
            if ai_last_target_kind in ("infantry", "objective"):
                pref = ("HE", "AP", "ATGM")
            elif not has_los:
                pref = ("HE", "AP", "ATGM")
            elif dist > 360:
                pref = ("ATGM", "AP", "HE")
            elif dist < 180:
                pref = ("AP", "HE", "ATGM")
            else:
                pref = ("AP", "ATGM", "HE")
            for t in pref:
                if ammo_count_by_type(t, bl_ammo_ap, bl_ammo_he, bl_ammo_atgm) > 0:
                    bl_ammo_type = t
                    break
            bl_ammo_type = ensure_ammo_type(bl_ammo_type, bl_ammo_ap, bl_ammo_he, bl_ammo_atgm)

            turret_aligned = abs((target_angle - bl_turret_angle + 540) % 360 - 180) <= (10 if has_los else 18)
            if has_los and dist <= 440 and (not turret_aligned or (now - last_blue_shot) < bl_cannon_cd * 0.72):
                ai_suppress_until = max(ai_suppress_until, now + 450)

            if now < ai_retreat_until:
                ai_move_dir = -1
                bl_turn_input = ai_orbit_dir if abs(diff) < 35 else bl_turn_input
            elif GAME_MODE_CURRENT == "KOTH" and move_target_x == KOTH_CENTER[0] and move_target_y == KOTH_CENTER[1]:
                if move_dist > KOTH_RADIUS * 0.56:
                    ai_move_dir = 1
                else:
                    ai_move_dir = 0
            else:
                if dist > desired_range + 70:
                    ai_move_dir = 1
                elif dist < desired_range - 55:
                    ai_move_dir = -1
                else:
                    ai_move_dir = 1 if random.random() < 0.35 else 0
                    bl_turn_input = ai_orbit_dir
            # Look ahead and steer around hard cover instead of driving straight into it.
            if ai_move_dir != 0:
                fwd_x, fwd_y = tank_forward(bl_chassis_angle)
                probe_x = blx + fwd_x * ai_move_dir * 74
                probe_y = bly + fwd_y * ai_move_dir * 74
                probe = get_collision_rect(bl_ch, (probe_x, probe_y), bl_chassis_angle, TANK_HITBOX_SCALE)
                blocking = None
                for obs in obstacles:
                    if obstacle_height(obs) <= 5.0:
                        continue
                    if probe.colliderect(obs['rect']):
                        blocking = obs
                        break
                if blocking is not None:
                    cx, cy = blocking['rect'].center
                    away = (math.degrees(math.atan2(-(bly - cy), blx - cx))) % 360
                    left_diff = abs((away + 55 - bl_chassis_angle + 540) % 360 - 180)
                    right_diff = abs((away - 55 - bl_chassis_angle + 540) % 360 - 180)
                    bl_turn_input = 1 if left_diff < right_diff else -1
                    ai_move_dir = -1 if math.hypot(blx - cx, bly - cy) < 95 else 1
            moving_blue = ai_move_dir != 0
        else:
            if keys_pressed[pygame.K_LEFT]:
                bl_turn_input += 1
            if keys_pressed[pygame.K_RIGHT]:
                bl_turn_input -= 1

        # Turret elevation control (gradual):
        # Green: Q up, E down. Blue: ' up, / down.
        elev_step = 26.0 * dt
        if keys_pressed[pygame.K_e]:
            gr_turret_elev_target += elev_step
        if keys_pressed[pygame.K_q]:
            gr_turret_elev_target -= elev_step
        if keys_pressed[pygame.K_QUOTE]:
            bl_turret_elev_target += elev_step
        if keys_pressed[pygame.K_SLASH]:
            bl_turret_elev_target -= elev_step
        gr_turret_elev_target = max(0.0, min(50.0, gr_turret_elev_target))
        bl_turret_elev_target = max(0.0, min(50.0, bl_turret_elev_target))

        elev_rate = 64.0 * dt
        gr_turret_elev += max(-elev_rate, min(elev_rate, gr_turret_elev_target - gr_turret_elev))
        bl_turret_elev += max(-elev_rate, min(elev_rate, bl_turret_elev_target - bl_turret_elev))

        gr_turn_accel_eff = turn_accel * weather_turn * gr_turn_factor
        gr_turn_decel_eff = turn_decel * weather_turn * gr_turn_factor
        gr_max_turn_eff = max_turn * weather_turn * gr_turn_factor
        bl_turn_accel_eff = turn_accel * weather_turn * bl_turn_factor
        bl_turn_decel_eff = turn_decel * weather_turn * bl_turn_factor
        bl_max_turn_eff = max_turn * weather_turn * bl_turn_factor
        gr_turret_accel_eff = gr_turn_accel_eff * gr_turret_mult
        gr_turret_decel_eff = gr_turn_decel_eff * gr_turret_mult
        gr_turret_max_eff = gr_max_turn_eff * gr_turret_mult
        bl_turret_accel_eff = bl_turn_accel_eff * bl_turret_mult
        bl_turret_decel_eff = bl_turn_decel_eff * bl_turret_mult
        bl_turret_max_eff = bl_max_turn_eff * bl_turret_mult
        gr_turn_accel_eff *= gr_engine_mult
        gr_turn_decel_eff *= gr_engine_mult
        gr_max_turn_eff *= gr_engine_mult
        bl_turn_accel_eff *= bl_engine_mult
        bl_turn_decel_eff *= bl_engine_mult
        bl_max_turn_eff *= bl_engine_mult

        # Turret rotation always responds to A/D (or Left/Right)
        if gr_turn_input != 0:
            gr_turret_av = max(-gr_turret_max_eff, min(gr_turret_max_eff, gr_turret_av + gr_turn_input * gr_turret_accel_eff * dt))
        else:
            if gr_turret_av > 0:
                gr_turret_av = max(0, gr_turret_av - gr_turret_decel_eff * dt)
            elif gr_turret_av < 0:
                gr_turret_av = min(0, gr_turret_av + gr_turret_decel_eff * dt)

        if bl_turn_input != 0:
            bl_turret_av = max(-bl_turret_max_eff, min(bl_turret_max_eff, bl_turret_av + bl_turn_input * bl_turret_accel_eff * dt))
        else:
            if bl_turret_av > 0:
                bl_turret_av = max(0, bl_turret_av - bl_turret_decel_eff * dt)
            elif bl_turret_av < 0:
                bl_turret_av = min(0, bl_turret_av + bl_turret_decel_eff * dt)

        can_turn_green = gr_fuel > 0
        can_turn_blue = bl_fuel > 0

        # Chassis only turns when moving (W/S or Up/Down) and has fuel
        if can_turn_green and moving_green and gr_turn_input != 0:
            gr_chassis_av = max(-gr_max_turn_eff, min(gr_max_turn_eff, gr_chassis_av + gr_turn_input * gr_turn_accel_eff * dt))
        else:
            if gr_chassis_av > 0:
                gr_chassis_av = max(0, gr_chassis_av - gr_turn_decel_eff * dt)
            elif gr_chassis_av < 0:
                gr_chassis_av = min(0, gr_chassis_av + gr_turn_decel_eff * dt)

        if can_turn_blue and moving_blue and bl_turn_input != 0:
            bl_chassis_av = max(-bl_max_turn_eff, min(bl_max_turn_eff, bl_chassis_av + bl_turn_input * bl_turn_accel_eff * dt))
        else:
            if bl_chassis_av > 0:
                bl_chassis_av = max(0, bl_chassis_av - bl_turn_decel_eff * dt)
            elif bl_chassis_av < 0:
                bl_chassis_av = min(0, bl_chassis_av + bl_turn_decel_eff * dt)

        if not can_turn_green:
            gr_chassis_av = 0.0
        if not can_turn_blue:
            bl_chassis_av = 0.0

        gr_chassis_angle = (gr_chassis_angle + gr_chassis_av * dt) % 360
        bl_chassis_angle = (bl_chassis_angle + bl_chassis_av * dt) % 360
        gr_turret_angle = (gr_turret_angle + gr_turret_av * dt) % 360
        bl_turret_angle = (bl_turret_angle + bl_turret_av * dt) % 360

        gr_max_fwd = max_fwd * gr_speed_mult * biome_speed * weather_speed * gr_move_factor * gr_engine_mult
        gr_max_rev = max_rev * gr_speed_mult * biome_speed * weather_speed * gr_move_factor * gr_engine_mult
        gr_accel = accel * gr_speed_mult * biome_speed * weather_accel * gr_move_factor * gr_engine_mult
        gr_decel = decel * gr_speed_mult * biome_speed * weather_accel * gr_move_factor * gr_engine_mult
        bl_max_fwd = max_fwd * bl_speed_mult * biome_speed * weather_speed * bl_move_factor * bl_engine_mult * (ai_move_mult if mode == "pvc" else 1.0)
        bl_max_rev = max_rev * bl_speed_mult * biome_speed * weather_speed * bl_move_factor * bl_engine_mult * (ai_move_mult if mode == "pvc" else 1.0)
        bl_accel = accel * bl_speed_mult * biome_speed * weather_accel * bl_move_factor * bl_engine_mult * (ai_move_mult if mode == "pvc" else 1.0)
        bl_decel = decel * bl_speed_mult * biome_speed * weather_accel * bl_move_factor * bl_engine_mult * (ai_move_mult if mode == "pvc" else 1.0)

        if keys_pressed[pygame.K_w]:
            gr_vel = min(gr_max_fwd, gr_vel + gr_accel * dt)
        elif keys_pressed[pygame.K_s]:
            gr_vel = max(-gr_max_rev, gr_vel - gr_accel * dt)
        else:
            if gr_vel > 0:
                gr_vel = max(0, gr_vel - gr_decel * dt)
            elif gr_vel < 0:
                gr_vel = min(0, gr_vel + gr_decel * dt)

        if mode == "pvc":
            if ai_move_dir > 0:
                bl_vel = min(bl_max_fwd, bl_vel + bl_accel * dt)
            elif ai_move_dir < 0:
                bl_vel = max(-bl_max_rev, bl_vel - bl_accel * dt)
            else:
                if bl_vel > 0:
                    bl_vel = max(0, bl_vel - bl_decel * dt)
                elif bl_vel < 0:
                    bl_vel = min(0, bl_vel + bl_decel * dt)
        elif keys_pressed[pygame.K_UP]:
            bl_vel = min(bl_max_fwd, bl_vel + bl_accel * dt)
        elif keys_pressed[pygame.K_DOWN]:
            bl_vel = max(-bl_max_rev, bl_vel - bl_accel * dt)
        else:
            if bl_vel > 0:
                bl_vel = max(0, bl_vel - bl_decel * dt)
            elif bl_vel < 0:
                bl_vel = min(0, bl_vel + bl_decel * dt)

        # Cool MG heat
        gr_heat_cool_eff = mg_heat_cool * biome_heat_cool * weather_heat_cool * (0.7 + 0.3 * gr_hp_ratio)
        bl_heat_cool_eff = mg_heat_cool * biome_heat_cool * weather_heat_cool * (0.7 + 0.3 * bl_hp_ratio)
        gr_mg_heat = max(0.0, gr_mg_heat - gr_heat_cool_eff * dt)
        bl_mg_heat = max(0.0, bl_mg_heat - bl_heat_cool_eff * dt)
        if gr_overheat and gr_mg_heat <= overheat_reset * biome_heat_max:
            gr_overheat = False
        if bl_overheat and bl_mg_heat <= overheat_reset * biome_heat_max:
            bl_overheat = False

        # Fuel burn
        gr_fuel = max(0.0, gr_fuel - (abs(gr_vel) / max(gr_max_fwd, 0.5)) * fuel_burn * biome_fuel * weather_fuel * (1.0 + (1.0 - gr_hp_ratio) * 0.3) * dt)
        bl_fuel = max(0.0, bl_fuel - (abs(bl_vel) / max(bl_max_fwd, 0.5)) * fuel_burn * biome_fuel * weather_fuel * (1.0 + (1.0 - bl_hp_ratio) * 0.3) * dt)
        gr_engine_dmg = max(0.0, gr_engine_dmg - 0.006 * dt)
        bl_engine_dmg = max(0.0, bl_engine_dmg - 0.006 * dt)
        gr_turret_dmg = max(0.0, gr_turret_dmg - 0.005 * dt)
        bl_turret_dmg = max(0.0, bl_turret_dmg - 0.005 * dt)
        if gr_fuel <= 80:
            gr_protect_until = 0
        if bl_fuel <= 80:
            bl_protect_until = 0

        # Recoil decay
        gr_recoil = max(0.0, gr_recoil - recoil_return * raw_dt)
        bl_recoil = max(0.0, bl_recoil - recoil_return * raw_dt)
        gr_turret_recoil = max(0.0, gr_turret_recoil - recoil_return * raw_dt)
        bl_turret_recoil = max(0.0, bl_turret_recoil - recoil_return * raw_dt)

        # MG auto-fire (hold trigger)
        if not gr_tank_dead and mouse_pressed[2] and not gr_overheat and gr_mg_ammo > 0 and (now - last_green_mg) >= mg_rld:
            gr_protect_until = 0
            first_shot_fired = True
            spread_amt = (mg_spread * gr_spread_mult * biome_spread * weather_spread) + (gr_mg_heat / max(biome_heat_max, 0.01)) * mg_heat_spread + gr_spread_damage
            spread = random.uniform(-spread_amt, spread_amt)
            bl_target_smoke = is_in_smoke(blx, bly, smokes, now)
            mg_angle = apply_smoke_jitter(gr_turret_angle + spread, bl_target_smoke)
            mg_rad = math.radians(mg_angle)
            mg_elev_rad = math.radians(gr_turret_elev)
            mg_horiz = mg_spd * math.cos(mg_elev_rad)
            muzzle_offset = gr_tr.get_width() * 0.15
            side_offset = gr_ch.get_width() * 0.12
            bullets.append({
                'x': grx + math.cos(mg_rad) * muzzle_offset - math.sin(mg_rad) * side_offset,
                'y': gry - math.sin(mg_rad) * muzzle_offset - math.cos(mg_rad) * side_offset,
                'vx': math.cos(mg_rad) * mg_horiz,
                'vy': -math.sin(mg_rad) * mg_horiz,
                'angle': mg_angle,
                'damage': mg_damage * gr_damage_mult * biome_damage * weather_damage * gr_damage_factor * gr_koth_dmg,
                'scale': 0.6,
                'explode': False,
                'type': 'mg',
                'owner': 'green',
                'wind_scale': 0.6,
                'z': 4.0,
                'vz': mg_spd * math.sin(mg_elev_rad),
                'gravity': mg_ballistic_gravity,
            })
            gr_shots += 1
            gr_mg_ammo -= 1
            muzzle_flashes.append({
                'x': grx + math.cos(mg_rad) * muzzle_offset - math.sin(mg_rad) * side_offset,
                'y': gry - math.sin(mg_rad) * muzzle_offset - math.cos(mg_rad) * side_offset,
                'angle': mg_angle,
                't': now,
                'scale': 0.6,
            })
            last_green_mg = now
            gr_mg_heat = min(mg_heat_max, gr_mg_heat + mg_heat_per_shot)
            if gr_mg_heat >= biome_heat_max:
                gr_overheat = True
            if mg_sound and (now - last_green_mg_sound) >= 60:
                mg_sound.play()
                last_green_mg_sound = now

        if mode == "pvc":
            # AI MG
            ai_mg_should_fire = ('has_los' in locals() and has_los and 'turret_aligned' in locals() and (turret_aligned or now < ai_suppress_until or ai_last_target_kind == "infantry"))
            if ai_mg_should_fire and not bl_tank_dead and not bl_overheat and bl_mg_ammo > 0 and (now - last_blue_mg) >= ai_mg_cd:
                bl_protect_until = 0
                first_shot_fired = True
                spread_amt = (mg_spread * bl_spread_mult * biome_spread * weather_spread) + (bl_mg_heat / max(biome_heat_max, 0.01)) * mg_heat_spread + bl_spread_damage
                spread = random.uniform(-spread_amt, spread_amt)
                target_smoke = is_in_smoke(ai_target_x, ai_target_y, smokes, now) if 'ai_target_x' in locals() else (gr_target_smoke if 'gr_target_smoke' in locals() else False)
                suppress_jitter = ai_aim_jitter * (1.8 if now < ai_suppress_until and not turret_aligned else 1.0)
                mg_angle = apply_smoke_jitter(bl_turret_angle + spread + random.uniform(-suppress_jitter, suppress_jitter), target_smoke)
                mg_rad = math.radians(mg_angle)
                mg_elev_rad = math.radians(bl_turret_elev)
                mg_horiz = mg_spd * math.cos(mg_elev_rad)
                muzzle_offset = bl_tr.get_width() * 0.15
                side_offset = bl_ch.get_width() * 0.12
                bullets.append({
                    'x': blx + math.cos(mg_rad) * muzzle_offset - math.sin(mg_rad) * side_offset,
                    'y': bly - math.sin(mg_rad) * muzzle_offset - math.cos(mg_rad) * side_offset,
                    'vx': math.cos(mg_rad) * mg_horiz,
                    'vy': -math.sin(mg_rad) * mg_horiz,
                    'angle': mg_angle,
                    'damage': mg_damage * bl_damage_mult * biome_damage * weather_damage * bl_damage_factor * bl_koth_dmg * ai_damage_mult,
                    'scale': 0.6,
                    'explode': False,
                    'type': 'mg',
                    'owner': 'blue',
                    'wind_scale': 0.6,
                    'z': 4.0,
                    'vz': mg_spd * math.sin(mg_elev_rad),
                    'gravity': mg_ballistic_gravity,
                })
                bl_shots += 1
                bl_mg_ammo -= 1
                muzzle_flashes.append({
                    'x': blx + math.cos(mg_rad) * muzzle_offset - math.sin(mg_rad) * side_offset,
                    'y': bly - math.sin(mg_rad) * muzzle_offset - math.cos(mg_rad) * side_offset,
                    'angle': mg_angle,
                    't': now,
                    'scale': 0.6,
                })
                last_blue_mg = now
                bl_mg_heat = min(mg_heat_max, bl_mg_heat + mg_heat_per_shot)
                if bl_mg_heat >= biome_heat_max:
                    bl_overheat = True
                if mg_sound and (now - last_blue_mg_sound) >= 60:
                    mg_sound.play()
                last_blue_mg_sound = now
            # AI smoke / repair
            if bl_hp < 40 and bl_smoke_ammo > 0 and (now - last_blue_smoke) >= smoke_cd_ms:
                for i in range(smoke_puff_count):
                    smokes.append({
                        'x': blx + random.uniform(-smoke_puff_spread, smoke_puff_spread),
                        'y': bly + random.uniform(-smoke_puff_spread, smoke_puff_spread),
                        't': now + i * 40,
                        'r0': random.randint(6, 12),
                    })
                last_blue_smoke = now
                bl_smoke_ammo -= 1
            if bl_hp < 60 and bl_repair_ammo > 0 and (now - last_bl_repair) >= repair_cd_ms:
                bl_hp = min(max_hp, bl_hp + repair_amount)
                bl_engine_dmg = max(0.0, bl_engine_dmg - 0.35)
                bl_turret_dmg = max(0.0, bl_turret_dmg - 0.35)
                repair_rings.append({'x': blx, 'y': bly, 't': now})
                bl_repair_ammo -= 1
                last_bl_repair = now
        elif not bl_tank_dead and keys_pressed[pygame.K_RSHIFT] and not bl_overheat and bl_mg_ammo > 0 and (now - last_blue_mg) >= mg_rld:
            bl_protect_until = 0
            first_shot_fired = True
            spread_amt = (mg_spread * bl_spread_mult * biome_spread * weather_spread) + (bl_mg_heat / max(biome_heat_max, 0.01)) * mg_heat_spread + bl_spread_damage
            spread = random.uniform(-spread_amt, spread_amt)
            gr_target_smoke = is_in_smoke(grx, gry, smokes, now)
            mg_angle = apply_smoke_jitter(bl_turret_angle + spread, gr_target_smoke)
            mg_rad = math.radians(mg_angle)
            mg_elev_rad = math.radians(bl_turret_elev)
            mg_horiz = mg_spd * math.cos(mg_elev_rad)
            muzzle_offset = bl_tr.get_width() * 0.15
            side_offset = bl_ch.get_width() * 0.12
            bullets.append({
                'x': blx + math.cos(mg_rad) * muzzle_offset - math.sin(mg_rad) * side_offset,
                'y': bly - math.sin(mg_rad) * muzzle_offset - math.cos(mg_rad) * side_offset,
                'vx': math.cos(mg_rad) * mg_horiz,
                'vy': -math.sin(mg_rad) * mg_horiz,
                'angle': mg_angle,
                'damage': mg_damage * bl_damage_mult * biome_damage * weather_damage * bl_damage_factor * bl_koth_dmg,
                'scale': 0.6,
                'explode': False,
                'type': 'mg',
                'owner': 'blue',
                'wind_scale': 0.6,
                'z': 4.0,
                'vz': mg_spd * math.sin(mg_elev_rad),
                'gravity': mg_ballistic_gravity,
            })
            bl_shots += 1
            bl_mg_ammo -= 1
            muzzle_flashes.append({
                'x': blx + math.cos(mg_rad) * muzzle_offset - math.sin(mg_rad) * side_offset,
                'y': bly - math.sin(mg_rad) * muzzle_offset - math.cos(mg_rad) * side_offset,
                'angle': mg_angle,
                't': now,
                'scale': 0.6,
            })
            last_blue_mg = now
            bl_mg_heat = min(mg_heat_max, bl_mg_heat + mg_heat_per_shot)
            if bl_mg_heat >= biome_heat_max:
                bl_overheat = True
            if mg_sound and (now - last_blue_mg_sound) >= 60:
                mg_sound.play()
                last_blue_mg_sound = now

        if gr_fuel > 0 and not gr_tank_dead:
            grx, gry = gr_move(grx, gry, gr_chassis_angle, gr_vel, dt)
        else:
            gr_vel = 0.0
        if bl_fuel > 0 and not bl_tank_dead:
            blx, bly = bl_move(blx, bly, bl_chassis_angle, bl_vel, dt)
        else:
            bl_vel = 0.0

        # AI cannon
        if mode == "pvc":
            bl_ammo_type = ensure_ammo_type(bl_ammo_type, bl_ammo_ap, bl_ammo_he, bl_ammo_atgm)
            # AI auto-elevation: solve for the angle that brings z to 0 at target distance.
            ai_target_dist = max(1.0, dist)
            if bl_ammo_type != "ATGM":
                spec = CANNON_TYPES.get(bl_ammo_type, CANNON_TYPES["AP"])
                v = spec["spd"]
                z0 = 6.0
                g = shell_gravity
                best_elev = bl_turret_elev
                best_err = 1e9
                for elev_test_deg in range(0, 51, 1):
                    elev_rad = math.radians(elev_test_deg)
                    horiz = v * math.cos(elev_rad)
                    if horiz < 1.0:
                        continue
                    t_flight = ai_target_dist / horiz
                    z_land = z0 + v * math.sin(elev_rad) * t_flight - 0.5 * g * t_flight * t_flight
                    err = abs(z_land)
                    if err < best_err:
                        best_err = err
                        best_elev = float(elev_test_deg)
                bl_turret_elev_target = best_elev
            else:
                bl_turret_elev_target = 0.0
            ai_cannon_clear = ('has_los' in locals() and has_los and 'turret_aligned' in locals() and turret_aligned)
            if ai_cannon_clear and not bl_tank_dead and ammo_count_by_type(bl_ammo_type, bl_ammo_ap, bl_ammo_he, bl_ammo_atgm) > 0 and len(bullets) < bullet_limit and (now - last_blue_shot) >= bl_cannon_cd:
                bl_protect_until = 0
                first_shot_fired = True
                muzzle_offset = bl_tr.get_width() * 0.5
                cannon_spread = 1.5 * weather_spread + bl_spread_damage + ai_aim_jitter
                fire_angle = bl_turret_angle + random.uniform(-cannon_spread, cannon_spread)
                fire_angle = apply_smoke_jitter(fire_angle, is_in_smoke(ai_target_x, ai_target_y, smokes, now))
                bl_rad = math.radians(fire_angle)
                bullets.append(build_cannon_bullet(
                    'blue',
                    blx + math.cos(bl_rad) * muzzle_offset,
                    bly - math.sin(bl_rad) * muzzle_offset,
                    fire_angle,
                    bl_damage_mult * biome_damage * weather_damage * bl_damage_factor * bl_koth_dmg * ai_damage_mult * bl_class_prof.get("damage_mul", 1.0),
                    bl_ammo_type,
                    bl_class,
                    bl_turret_elev
                ))
                bl_shots += 1
                bl_ammo_ap, bl_ammo_he, bl_ammo_atgm = spend_ammo(bl_ammo_type, bl_ammo_ap, bl_ammo_he, bl_ammo_atgm)
                bl_ammo_type = ensure_ammo_type(bl_ammo_type, bl_ammo_ap, bl_ammo_he, bl_ammo_atgm)
                bl_recoil = recoil_kick
                bl_turret_recoil = recoil_kick * 0.9
                shake_timer = max(shake_timer, shake_duration)
                if cannon_sound:
                    cannon_sound.play()
                muzzle_flashes.append({
                    'x': blx + math.cos(bl_rad) * muzzle_offset,
                    'y': bly - math.sin(bl_rad) * muzzle_offset,
                    'angle': bl_turret_angle,
                    't': now,
                    'scale': 1.0,
                })
                last_blue_shot = now

        # Spawn airdrops
        if now >= next_airdrop_time:
            for _ in range(airdrop_wave_size):
                drop_type = random.choice(["ammo", "fuel", "speed", "damage", "spread", "armor", "rapid", "repair", "airstrike"])
                airdrops.append({
                    'x': random.randint(200, 1080),
                    'y': random.randint(100, frame_y - 100),
                    'type': drop_type,
                    'spawn': now,
                    'landed': False,
                    'land_time': None,
                })
            next_airdrop_time = now + int(random.uniform(airdrop_interval_min, airdrop_interval_max) * 1000)

        # Mines intentionally stay disabled; hidden mines made losses feel unfair.

        # Spawn infantry waves from behind each team's spawn (after first shot)
        if runtime_reinf and first_shot_fired and now >= next_infantry_time:
            # Only spawn if the opposing tank is still alive
            if not gr_tank_dead and not bl_tank_dead:
                gr_inf_count = sum(1 for u in infantry if u['team'] == 'green')
                bl_inf_count = sum(1 for u in infantry if u['team'] == 'blue')
                if green_reinf_alive and gr_inf_count < ai_max_inf:
                    pending_infantry.extend(spawn_infantry_wave("green", gr_spawn[0] - 40, gr_spawn[1] + random.randint(-40, 40), now))
                if blue_reinf_alive and bl_inf_count < ai_max_inf:
                    pending_infantry.extend(spawn_infantry_wave("blue", bl_spawn[0] + 40, bl_spawn[1] + random.randint(-40, 40), now))
            next_infantry_time = now + int(random.uniform(infantry_wave_min, infantry_wave_max) * 1000)
        # Comeback director: trailing team receives occasional extra infantry support
        if runtime_reinf and first_shot_fired and now >= next_comeback_time and not gr_tank_dead and not bl_tank_dead:
            if green_reinf_alive and (gr_lives < bl_lives or gr_hp + 35 < bl_hp):
                pending_infantry.extend(spawn_infantry_wave("green", gr_spawn[0] - 30, gr_spawn[1] + random.randint(-30, 30), now))
                push_kill_feed(kill_feed, "GREEN RECEIVES SUPPORT", (120, 255, 160), now)
            elif blue_reinf_alive and (bl_lives < gr_lives or bl_hp + 35 < gr_hp):
                pending_infantry.extend(spawn_infantry_wave("blue", bl_spawn[0] + 30, bl_spawn[1] + random.randint(-30, 30), now))
                push_kill_feed(kill_feed, "BLUE RECEIVES SUPPORT", (150, 200, 255), now)
            next_comeback_time = now + random.randint(16000, 24000)

        gr_rect = get_collision_rect(gr_ch, (grx, gry), gr_chassis_angle, TANK_HITBOX_SCALE)
        bl_rect = get_collision_rect(bl_ch, (blx, bly), bl_chassis_angle, TANK_HITBOX_SCALE)
        gr_turret_rect = get_collision_rect(gr_tr, (grx, gry), gr_turret_angle, TURRET_HITBOX_SCALE)
        bl_turret_rect = get_collision_rect(bl_tr, (blx, bly), bl_turret_angle, TURRET_HITBOX_SCALE)

        # Vehicle collisions + ramming response
        vehicles = apcs + jeeps + humvees
        for apc in vehicles:
            a_rect = apc_rect(apc)
            if a_rect.colliderect(gr_rect) or a_rect.colliderect(gr_turret_rect):
                push_dx = grx - apc['x']
                push_dy = gry - apc['y']
                push_dist = math.hypot(push_dx, push_dy)
                if push_dist > 0:
                    grx += (push_dx / push_dist) * 4
                    gry += (push_dy / push_dist) * 4
                    apc['x'] -= (push_dx / push_dist) * 4
                    apc['y'] -= (push_dy / push_dist) * 4
                gr_vel *= -0.3
            if a_rect.colliderect(bl_rect) or a_rect.colliderect(bl_turret_rect):
                push_dx = blx - apc['x']
                push_dy = bly - apc['y']
                push_dist = math.hypot(push_dx, push_dy)
                if push_dist > 0:
                    blx += (push_dx / push_dist) * 4
                    bly += (push_dy / push_dist) * 4
                    apc['x'] -= (push_dx / push_dist) * 4
                    apc['y'] -= (push_dy / push_dist) * 4
                bl_vel *= -0.3

        # Tank vs tank ramming
        if gr_rect.colliderect(bl_rect) or gr_turret_rect.colliderect(bl_rect) or bl_turret_rect.colliderect(gr_rect) or gr_turret_rect.colliderect(bl_turret_rect):
            push_dx = grx - blx
            push_dy = gry - bly
            push_dist = math.hypot(push_dx, push_dy)
            # Use overlap size to separate harder when only turrets overlap.
            overlap = gr_turret_rect.clip(bl_turret_rect)
            sep = 10
            if overlap.width > 0 and overlap.height > 0:
                sep = max(10, min(26, int((overlap.width + overlap.height) * 0.7)))
            if push_dist <= 0.001:
                push_dx, push_dy = 1.0, 0.0
                push_dist = 1.0
            grx += (push_dx / push_dist) * sep
            gry += (push_dy / push_dist) * sep
            blx -= (push_dx / push_dist) * sep
            bly -= (push_dy / push_dist) * sep
            gr_vel *= -0.3
            bl_vel *= -0.3
            first_shot_fired = True
            # Refresh hitboxes immediately after separation.
            gr_rect = get_collision_rect(gr_ch, (grx, gry), gr_chassis_angle, TANK_HITBOX_SCALE)
            bl_rect = get_collision_rect(bl_ch, (blx, bly), bl_chassis_angle, TANK_HITBOX_SCALE)
            gr_turret_rect = get_collision_rect(gr_tr, (grx, gry), gr_turret_angle, TURRET_HITBOX_SCALE)
            bl_turret_rect = get_collision_rect(bl_tr, (blx, bly), bl_turret_angle, TURRET_HITBOX_SCALE)

        # Run over infantry (teamkilling allowed after spawn protection)
        for unit in infantry:
            if unit.get('protect_until', 0) > now:
                continue
            if math.hypot(unit['x'] - grx, unit['y'] - gry) <= 10:
                unit['hp'] = 0
            if math.hypot(unit['x'] - blx, unit['y'] - bly) <= 10:
                unit['hp'] = 0
        for apc in (apcs + jeeps + humvees):
            for unit in infantry:
                if unit.get('protect_until', 0) > now:
                    continue
                if math.hypot(unit['x'] - apc['x'], unit['y'] - apc['y']) <= 12:
                    unit['hp'] = 0

        grx, gry = clamp_position(grx, gry, gr_rect)
        blx, bly = clamp_position(blx, bly, bl_rect)

        gr_rect = get_collision_rect(gr_ch, (grx, gry), gr_chassis_angle, TANK_HITBOX_SCALE)
        bl_rect = get_collision_rect(bl_ch, (blx, bly), bl_chassis_angle, TANK_HITBOX_SCALE)

        # Airdrop pickups
        remaining_drops = []
        for drop in airdrops:
            if not drop['landed'] and now - drop['spawn'] >= 5000:
                drop['landed'] = True
                drop['land_time'] = now
            if not drop['landed']:
                remaining_drops.append(drop)
                continue
            if drop.get('land_time') is not None and now - drop['land_time'] >= airdrop_despawn_ms:
                continue
            drop_rect = pygame.Rect(drop['x'] - airdrop_size // 2, drop['y'] - airdrop_size // 2, airdrop_size, airdrop_size)
            picked_green = gr_rect.colliderect(drop_rect)
            picked_blue = bl_rect.colliderect(drop_rect)
            if picked_green or picked_blue:
                if picked_green:
                    if drop['type'] == "ammo":
                        gr_ammo_ap = min(cannon_ap_max, gr_ammo_ap + 5)
                        gr_ammo_he = min(cannon_he_max, gr_ammo_he + 3)
                        gr_ammo_atgm = min(cannon_atgm_max, gr_ammo_atgm + 1)
                        gr_mg_ammo = min(mg_ammo_max, gr_mg_ammo + 150)
                    elif drop['type'] == "fuel":
                        gr_fuel = min(fuel_max, gr_fuel + 30)
                    elif drop['type'] == "speed":
                        gr_speed_mult = min(upg_cap, gr_speed_mult + speed_upg_step)
                    elif drop['type'] == "damage":
                        gr_damage_mult = min(upg_cap, gr_damage_mult + damage_upg_step)
                    elif drop['type'] == "spread":
                        gr_spread_mult = max(0.4, gr_spread_mult - spread_upg_step)
                    elif drop['type'] == "airstrike":
                        # Airstrike prioritizes enemy hill control first, then tank area.
                        strike_centers = []
                        if round_mode == "KOTH" and hill_control == "blue":
                            strike_centers.append((hill_x, hill_y, 0.7))
                        strike_centers.append((blx, bly, 0.3))
                        for _ in range(8):
                            cx, cy, w = random.choice(strike_centers)
                            spread = 120 if (round_mode == "KOTH" and hill_control == "blue" and w > 0.5) else 130
                            sx = cx + random.uniform(-spread, spread)
                            sy = cy + random.uniform(-spread, spread)
                            explosions.append({'x': sx, 'y': sy, 'angle': 0, 't': now, 'r': 72})
                            if bl_protect_until <= now and math.hypot(sx - blx, sy - bly) <= 78:
                                bl_hp = max(0, bl_hp - 24)
                            for v in apcs + jeeps + humvees:
                                if v['team'] == 'blue' and math.hypot(sx - v['x'], sy - v['y']) <= 80:
                                    v['hp'] -= 34
                            for u in infantry:
                                if u['team'] == 'blue' and math.hypot(sx - u['x'], sy - u['y']) <= 70:
                                    u['hp'] -= 55
                        shake_timer = max(shake_timer, shake_duration * 1.8)
                        if hit_sound:
                            hit_sound.play()
                if picked_blue:
                    if drop['type'] == "ammo":
                        bl_ammo_ap = min(cannon_ap_max, bl_ammo_ap + 5)
                        bl_ammo_he = min(cannon_he_max, bl_ammo_he + 3)
                        bl_ammo_atgm = min(cannon_atgm_max, bl_ammo_atgm + 1)
                        bl_mg_ammo = min(mg_ammo_max, bl_mg_ammo + 150)
                    elif drop['type'] == "fuel":
                        bl_fuel = min(fuel_max, bl_fuel + 30)
                    elif drop['type'] == "speed":
                        bl_speed_mult = min(upg_cap, bl_speed_mult + speed_upg_step)
                    elif drop['type'] == "damage":
                        bl_damage_mult = min(upg_cap, bl_damage_mult + damage_upg_step)
                    elif drop['type'] == "spread":
                        bl_spread_mult = max(0.4, bl_spread_mult - spread_upg_step)
                    elif drop['type'] == "airstrike":
                        # Airstrike prioritizes enemy hill control first, then tank area.
                        strike_centers = []
                        if round_mode == "KOTH" and hill_control == "green":
                            strike_centers.append((hill_x, hill_y, 0.7))
                        strike_centers.append((grx, gry, 0.3))
                        for _ in range(8):
                            cx, cy, w = random.choice(strike_centers)
                            spread = 120 if (round_mode == "KOTH" and hill_control == "green" and w > 0.5) else 130
                            sx = cx + random.uniform(-spread, spread)
                            sy = cy + random.uniform(-spread, spread)
                            explosions.append({'x': sx, 'y': sy, 'angle': 0, 't': now, 'r': 72})
                            if gr_protect_until <= now and math.hypot(sx - grx, sy - gry) <= 78:
                                gr_hp = max(0, gr_hp - 24)
                            for v in apcs + jeeps + humvees:
                                if v['team'] == 'green' and math.hypot(sx - v['x'], sy - v['y']) <= 80:
                                    v['hp'] -= 34
                            for u in infantry:
                                if u['team'] == 'green' and math.hypot(sx - u['x'], sy - u['y']) <= 70:
                                    u['hp'] -= 55
                        shake_timer = max(shake_timer, shake_duration * 1.8)
                        if hit_sound:
                            hit_sound.play()
                        push_kill_feed(kill_feed, "BLUE CALLS AIRSTRIKE", (130, 180, 255), now)
            else:
                remaining_drops.append(drop)
        airdrops = remaining_drops
        hit_vehicle = False
        for veh in (apcs + jeeps + humvees):
            v_rect = apc_rect(veh)
            if v_rect.colliderect(gr_rect) or v_rect.colliderect(gr_turret_rect):
                grx, gry = prev_grx, prev_gry
                gr_vel *= -0.4
                hit_vehicle = True
            if v_rect.colliderect(bl_rect) or v_rect.colliderect(bl_turret_rect):
                blx, bly = prev_blx, prev_bly
                bl_vel *= -0.4
                hit_vehicle = True

        hit_obstacle = False
        gr_hit_obs = False
        bl_hit_obs = False
        gr_obs_hit = None
        bl_obs_hit = None
        for obs in obstacles:
            # Chassis/body collisions handle vehicle movement.
            if gr_rect.colliderect(obs['rect']):
                hit_obstacle = True
                gr_hit_obs = True
                if gr_obs_hit is None:
                    gr_obs_hit = obs
            if bl_rect.colliderect(obs['rect']):
                hit_obstacle = True
                bl_hit_obs = True
                if bl_obs_hit is None:
                    bl_obs_hit = obs
            if hit_obstacle and gr_hit_obs and bl_hit_obs:
                break

        # Turret-only obstacle collision:
        # rewind turret angle to pre-step so it cannot rotate into obstacles.
        gr_turret_blocked = False
        bl_turret_blocked = False
        for obs in obstacles:
            if gr_turret_rect.colliderect(obs['rect']):
                gr_turret_blocked = True
            if bl_turret_rect.colliderect(obs['rect']):
                bl_turret_blocked = True
            if gr_turret_blocked and bl_turret_blocked:
                break
        if gr_turret_blocked:
            gr_turret_angle = prev_gr_turret_angle
            gr_turret_av = 0.0
        if bl_turret_blocked:
            bl_turret_angle = prev_bl_turret_angle
            bl_turret_av = 0.0
        if gr_turret_blocked or bl_turret_blocked:
            gr_turret_rect = get_collision_rect(gr_tr, (grx, gry), gr_turret_angle, TURRET_HITBOX_SCALE)
            bl_turret_rect = get_collision_rect(bl_tr, (blx, bly), bl_turret_angle, TURRET_HITBOX_SCALE)

        if gr_rect.colliderect(bl_rect) or gr_turret_rect.colliderect(bl_rect) or bl_turret_rect.colliderect(gr_rect) or gr_turret_rect.colliderect(bl_turret_rect):
            # Emergency second-pass separation instead of rewinding both tanks.
            push_dx = grx - blx
            push_dy = gry - bly
            push_dist = math.hypot(push_dx, push_dy)
            if push_dist <= 0.001:
                push_dx, push_dy = 1.0, 0.0
                push_dist = 1.0
            grx += (push_dx / push_dist) * 8
            gry += (push_dy / push_dist) * 8
            blx -= (push_dx / push_dist) * 8
            bly -= (push_dy / push_dist) * 8
            gr_vel *= -0.45
            bl_vel *= -0.45
        if hit_obstacle:
            if gr_hit_obs:
                grx, gry = prev_grx, prev_gry
            if bl_hit_obs:
                blx, bly = prev_blx, prev_bly
            gr_rect = get_collision_rect(gr_ch, (grx, gry), gr_chassis_angle, TANK_HITBOX_SCALE)
            bl_rect = get_collision_rect(bl_ch, (blx, bly), bl_chassis_angle, TANK_HITBOX_SCALE)
            gr_turret_rect = get_collision_rect(gr_tr, (grx, gry), gr_turret_angle, TURRET_HITBOX_SCALE)
            bl_turret_rect = get_collision_rect(bl_tr, (blx, bly), bl_turret_angle, TURRET_HITBOX_SCALE)
            # Repel/turn away on obstacle hit
            if hit_obstacle:
                # Optional ram damage into obstacle if facing it
                if gr_hit_obs and gr_obs_hit is not None:
                    fx, fy = tank_forward(gr_chassis_angle)
                    ox, oy = gr_obs_hit['rect'].centerx - grx, gr_obs_hit['rect'].centery - gry
                    if fx * ox + fy * oy > 0.3:
                        dmg = max(0.0, abs(gr_vel) - ram_speed_thresh) * ram_dmg_scale * obstacle_ram_scale
                        gr_hp = max(gr_hp - dmg, 0)
                    # Move whole tank away from the obstacle center.
                    d = math.hypot(ox, oy)
                    if d > 0:
                        grx -= (ox / d) * 12
                        gry -= (oy / d) * 12
                        away_ang = (math.degrees(math.atan2(-(gry - gr_obs_hit['rect'].centery), grx - gr_obs_hit['rect'].centerx)) + 360) % 360
                        gr_chassis_angle = approach_angle(gr_chassis_angle, away_ang, 140 * dt)
                if bl_hit_obs and bl_obs_hit is not None:
                    fx, fy = tank_forward(bl_chassis_angle)
                    ox, oy = bl_obs_hit['rect'].centerx - blx, bl_obs_hit['rect'].centery - bly
                    if fx * ox + fy * oy > 0.3:
                        dmg = max(0.0, abs(bl_vel) - ram_speed_thresh) * ram_dmg_scale * obstacle_ram_scale
                        bl_hp = max(bl_hp - dmg, 0)
                    # Move whole tank away from the obstacle center.
                    d = math.hypot(ox, oy)
                    if d > 0:
                        blx -= (ox / d) * 12
                        bly -= (oy / d) * 12
                        away_ang = (math.degrees(math.atan2(-(bly - bl_obs_hit['rect'].centery), blx - bl_obs_hit['rect'].centerx)) + 360) % 360
                        bl_chassis_angle = approach_angle(bl_chassis_angle, away_ang, 140 * dt)
                if gr_hit_obs:
                    gr_vel *= -0.5
                if bl_hit_obs:
                    bl_vel *= -0.5
        gr_in_smoke = is_in_smoke(grx, gry, smokes, now)
        bl_in_smoke = is_in_smoke(blx, bly, smokes, now)
        vehicles = apcs + jeeps + humvees
        bullets, green_hits, blue_hits, green_damage, blue_damage, new_explosions, cannon_hit, crit_events = handle_bullets(
            bullets, gr_rect, bl_rect, obstacles, infantry, vehicles, now, dt, gr_in_smoke, bl_in_smoke, gr_protect_until, bl_protect_until, gr_chassis_angle, bl_chassis_angle, wind_vec
        )
        # Cannon rounds detonate on contact with crates/airdrops (ATGM excluded).
        if airdrops and bullets:
            to_remove = set()
            kept_drops = []
            for drop in airdrops:
                if (not drop.get('landed', False)) or (drop.get('land_time') is not None and now - drop['land_time'] >= airdrop_despawn_ms):
                    kept_drops.append(drop)
                    continue
                drect = pygame.Rect(drop['x'] - airdrop_size // 2, drop['y'] - airdrop_size // 2, airdrop_size, airdrop_size)
                hit = False
                for bi, b in enumerate(bullets):
                    if bi in to_remove:
                        continue
                    if b.get('type') == 'cannon' and b.get('ammo_type') != "ATGM":
                        brect = bull.get_rect(center=(b['x'], b['y']))
                        if brect.colliderect(drect):
                            explosions.append({'x': b['x'], 'y': b['y'], 'angle': 0, 't': now, 'r': b.get('blast_r')})
                            cannon_hit = True
                            to_remove.add(bi)
                            hit = True
                            break
                if not hit:
                    kept_drops.append(drop)
            if to_remove:
                bullets = [b for i, b in enumerate(bullets) if i not in to_remove]
            airdrops = kept_drops
        for c in crit_events:
            if c['team'] == 'green':
                if c['system'] == 'engine':
                    gr_engine_dmg = min(1.0, gr_engine_dmg + c['amount'])
                else:
                    gr_turret_dmg = min(1.0, gr_turret_dmg + c['amount'])
            else:
                if c['system'] == 'engine':
                    bl_engine_dmg = min(1.0, bl_engine_dmg + c['amount'])
                else:
                    bl_turret_dmg = min(1.0, bl_turret_dmg + c['amount'])
        crowd_total = len(infantry) + len(apcs) + len(jeeps) + len(humvees)
        crowd_scale = 1.0 + max(0, (crowd_total - ai_crowd_threshold)) / max(ai_crowd_step, 1) * 0.25
        infantry, new_shots, inf_flashes = update_infantry(infantry, grx, gry, blx, bly, obstacles, smokes, now, dt, gr_tank_dead, bl_tank_dead, gr_spawn, bl_spawn, WEATHER_EFFECTS.get(weather_type, WEATHER_EFFECTS["clear"]), think=ai_think, crowd_scale=crowd_scale, commander_teams=commander_teams)
        if runtime_reinf and first_shot_fired and not apcs and not jeeps and not humvees and (not gr_tank_dead and not bl_tank_dead):
            slots = ai_max_veh
            if slots > 0 and green_reinf_alive:
                pending_vehicles.append({'type': 'apc', 'x': gr_spawn[0] + 60, 'y': gr_spawn[1] + 80, 'team': 'green', 'hp': apc_hp, 'hp_max': apc_hp, 'last_shot': 0, 'last_drop': 0, 'last_at': 0, 'at_ammo': apc_at_ammo_max, 'angle': 0, 'turret_angle': 0, 'vx': 0.0, 'vy': 0.0, 'protect_until': now + spawn_protect_ms, 'spawn_t': now, 'last_active': now})
                slots -= 1
            if slots > 0 and blue_reinf_alive:
                pending_vehicles.append({'type': 'apc', 'x': bl_spawn[0] - 60, 'y': bl_spawn[1] + 80, 'team': 'blue', 'hp': apc_hp, 'hp_max': apc_hp, 'last_shot': 0, 'last_drop': 0, 'last_at': 0, 'at_ammo': apc_at_ammo_max, 'angle': 0, 'turret_angle': 0, 'vx': 0.0, 'vy': 0.0, 'protect_until': now + spawn_protect_ms, 'spawn_t': now, 'last_active': now})
                slots -= 1
            if slots > 0 and green_reinf_alive:
                pending_vehicles.append({'type': 'jeep', 'x': gr_spawn[0] + 40, 'y': gr_spawn[1] - 80, 'team': 'green', 'hp': jeep_hp, 'hp_max': jeep_hp, 'last_shot': 0, 'angle': 0, 'turret_angle': 0, 'vx': 0.0, 'vy': 0.0, 'protect_until': now + spawn_protect_ms, 'spawn_t': now, 'last_active': now})
                slots -= 1
            if slots > 0 and blue_reinf_alive:
                pending_vehicles.append({'type': 'jeep', 'x': bl_spawn[0] - 40, 'y': bl_spawn[1] - 80, 'team': 'blue', 'hp': jeep_hp, 'hp_max': jeep_hp, 'last_shot': 0, 'angle': 0, 'turret_angle': 0, 'vx': 0.0, 'vy': 0.0, 'protect_until': now + spawn_protect_ms, 'spawn_t': now, 'last_active': now})
                slots -= 1
            if slots > 0:
                hum_team = random.choice(["green", "blue"])
                if (hum_team == "green" and not green_reinf_alive) or (hum_team == "blue" and not blue_reinf_alive):
                    hum_team = "blue" if hum_team == "green" else "green"
                if (hum_team == "green" and not green_reinf_alive) or (hum_team == "blue" and not blue_reinf_alive):
                    slots = 0
                
                hx = gr_spawn[0] + 80 if hum_team == "green" else bl_spawn[0] - 80
                hy = gr_spawn[1] + 40 if hum_team == "green" else bl_spawn[1] + 40
                if slots > 0:
                    pending_vehicles.append({'type': 'humvee', 'x': hx, 'y': hy, 'team': hum_team, 'hp': humvee_hp, 'hp_max': humvee_hp, 'last_shot': 0, 'angle': 0, 'turret_angle': 0, 'vx': 0.0, 'vy': 0.0, 'protect_until': now + spawn_protect_ms, 'spawn_t': now, 'last_active': now})
        apcs, apc_shots, apc_infantry = update_apcs(apcs, grx, gry, blx, bly, obstacles, smokes, now, dt, gr_tank_dead, bl_tank_dead, infantry, runtime_reinf, apcs + jeeps + humvees, WEATHER_EFFECTS.get(weather_type, WEATHER_EFFECTS["clear"]), think=ai_think, crowd_scale=crowd_scale, reinf_green=green_reinf_alive, reinf_blue=blue_reinf_alive, commander_teams=commander_teams) if apcs else (apcs, [], [])
        jeeps, jeep_shots = update_jeeps(jeeps, grx, gry, blx, bly, obstacles, smokes, now, dt, gr_tank_dead, bl_tank_dead, infantry, WEATHER_EFFECTS.get(weather_type, WEATHER_EFFECTS["clear"]), think=ai_think, crowd_scale=crowd_scale, commander_teams=commander_teams) if jeeps else (jeeps, [])
        humvees, humvee_shots = update_humvees(humvees, grx, gry, blx, bly, obstacles, smokes, now, dt, gr_tank_dead, bl_tank_dead, infantry, WEATHER_EFFECTS.get(weather_type, WEATHER_EFFECTS["clear"]), think=ai_think, crowd_scale=crowd_scale, commander_teams=commander_teams) if humvees else (humvees, [])
        if len(infantry_bullets) < infantry_bullet_limit:
            for shot in new_shots:
                infantry_bullets.append(shot)
            for shot in apc_shots:
                infantry_bullets.append(shot)
            for shot in jeep_shots:
                infantry_bullets.append(shot)
            for shot in humvee_shots:
                infantry_bullets.append(shot)
        if inf_flashes:
            muzzle_flashes.extend(inf_flashes)
        if apc_infantry:
            pending_infantry.extend([u for u in apc_infantry if (u['team'] == 'green' and green_reinf_alive) or (u['team'] == 'blue' and blue_reinf_alive)])
        pending_infantry = [u for u in pending_infantry if (u['team'] == 'green' and green_reinf_alive) or (u['team'] == 'blue' and blue_reinf_alive)]
        pending_vehicles = [v for v in pending_vehicles if (v['team'] == 'green' and green_reinf_alive) or (v['team'] == 'blue' and blue_reinf_alive)]
        infantry_bullets, inf_green_damage, inf_blue_damage, _, _ = handle_infantry_bullets(
            infantry_bullets, infantry, gr_rect, bl_rect, obstacles, vehicles, now, dt, gr_in_smoke, bl_in_smoke, gr_protect_until, bl_protect_until, wind_vec
        )
        if round_mode == "SIEGE":
            next_bullets = []
            for b in bullets:
                brect = bull.get_rect(center=(b['x'], b['y']))
                hit_green_base = b.get('owner') == 'blue' and brect.colliderect(gr_barracks_rect)
                hit_blue_base = b.get('owner') == 'green' and brect.colliderect(bl_barracks_rect)
                if not (hit_green_base or hit_blue_base):
                    next_bullets.append(b)
                    continue
                if b.get('type') == 'mg':
                    base_dmg = b['damage'] * 1.35
                elif b.get('type') == 'cannon':
                    base_dmg = b['damage'] * (1.3 if b.get('ammo_type') == "ATGM" else 1.1)
                else:
                    base_dmg = b['damage'] * 0.9
                if hit_green_base:
                    gr_barracks['hp'] = max(0.0, gr_barracks['hp'] - base_dmg)
                if hit_blue_base:
                    bl_barracks['hp'] = max(0.0, bl_barracks['hp'] - base_dmg)
                explosions.append({'x': b['x'], 'y': b['y'], 'angle': 0, 't': now, 'r': b.get('blast_r', 18)})
                bullets = next_bullets

            next_inf_bullets = []
            for ib in infantry_bullets:
                ib_rect = pygame.Rect(ib['x'] - 3, ib['y'] - 3, 6, 6)
                hit_green_base = ib.get('owner') == 'blue' and ib_rect.colliderect(gr_barracks_rect)
                hit_blue_base = ib.get('owner') == 'green' and ib_rect.colliderect(bl_barracks_rect)
                if not (hit_green_base or hit_blue_base):
                    next_inf_bullets.append(ib)
                    continue
                base_dmg = ib.get('damage', 1.0) * (1.05 if ib.get('type') in ('apc_at', 'at') else 0.75)
                if hit_green_base:
                    gr_barracks['hp'] = max(0.0, gr_barracks['hp'] - base_dmg)
                if hit_blue_base:
                    bl_barracks['hp'] = max(0.0, bl_barracks['hp'] - base_dmg)
                explosions.append({'x': ib['x'], 'y': ib['y'], 'angle': 0, 't': now, 'r': ib.get('blast_r', 14)})
                cannon_hit = True
            infantry_bullets = next_inf_bullets
        # Staggered spawn budget to avoid spike
        inf_budget = max(1, int(quality_spawn_inf * ai_scale))
        while pending_infantry and inf_budget > 0:
            infantry.append(pending_infantry.pop(0))
            inf_budget -= 1
        veh_budget = max(1, int(quality_spawn_veh * ai_scale))
        while pending_vehicles and veh_budget > 0:
            v = pending_vehicles.pop(0)
            if v.get('type') == 'apc':
                apcs.append(v)
            elif v.get('type') == 'jeep':
                jeeps.append(v)
            else:
                humvees.append(v)
            veh_budget -= 1
        # AI despawn (units drift out if inactive and far)
        def ai_far(unit_x, unit_y, team):
            tx, ty = (grx, gry) if team == 'blue' else (blx, bly)
            return math.hypot(unit_x - tx, unit_y - ty) > ai_despawn_dist

        next_infantry = []
        for u in infantry:
            if (now - u.get('spawn_t', now)) > ai_despawn_ms and ai_far(u['x'], u['y'], u['team']) and (now - u.get('last_active', 0)) > 5000:
                continue
            next_infantry.append(u)
        infantry = next_infantry

        def keep_vehicle(v):
            if (now - v.get('spawn_t', now)) > ai_despawn_ms and ai_far(v['x'], v['y'], v['team']) and (now - v.get('last_active', 0)) > 6000:
                return False
            return True
        apcs = [v for v in apcs if keep_vehicle(v)]
        jeeps = [v for v in jeeps if keep_vehicle(v)]
        humvees = [v for v in humvees if keep_vehicle(v)]
        # Drone spawns
        if runtime_reinf and now >= next_supply_drone:
            if green_reinf_alive:
                supply_drones.append({'x': gr_spawn[0], 'y': gr_spawn[1] - 30, 'team': 'green', 'spawn_t': now, 'hover_t': None})
            if blue_reinf_alive:
                supply_drones.append({'x': bl_spawn[0], 'y': bl_spawn[1] - 30, 'team': 'blue', 'spawn_t': now, 'hover_t': None})
            next_supply_drone = now + supply_drone_cd
        if runtime_reinf and now >= next_attack_drone:
            if green_reinf_alive:
                attack_drones.append({'x': gr_spawn[0], 'y': gr_spawn[1] + 30, 'team': 'green', 'spawn_t': now, 'lock_t': None})
            if blue_reinf_alive:
                attack_drones.append({'x': bl_spawn[0], 'y': bl_spawn[1] + 30, 'team': 'blue', 'spawn_t': now, 'lock_t': None})
            next_attack_drone = now + attack_drone_cd

        # Supply drones: seek most impactful landed crate and auto-collect.
        consumed_drop_ids = set()
        next_supply = []
        for d in supply_drones:
            if now - d.get('spawn_t', now) < supply_drone_arm_ms:
                next_supply.append(d)
                continue
            tx, ty = None, None
            best_score = -1e9
            best_drop = None
            for drop in airdrops:
                if id(drop) in consumed_drop_ids:
                    continue
                if (not drop.get('landed')) or (drop.get('land_time') is None):
                    continue
                if now - drop.get('land_time', now) > airdrop_despawn_ms:
                    continue
                dtype = drop.get('type')
                if dtype == "ammo":
                    score = 0.0
                    if d['team'] == 'green':
                        score = (cannon_ap_max - gr_ammo_ap) + (cannon_he_max - gr_ammo_he) + (cannon_atgm_max - gr_ammo_atgm) * 2 + (mg_ammo_max - gr_mg_ammo) * 0.02
                    else:
                        score = (cannon_ap_max - bl_ammo_ap) + (cannon_he_max - bl_ammo_he) + (cannon_atgm_max - bl_ammo_atgm) * 2 + (mg_ammo_max - bl_mg_ammo) * 0.02
                elif dtype == "fuel":
                    score = (fuel_max - (gr_fuel if d['team'] == 'green' else bl_fuel)) * 0.05
                elif dtype == "airstrike":
                    score = 14.0
                else:
                    score = 6.0
                dist = math.hypot(drop['x'] - d['x'], drop['y'] - d['y'])
                score -= dist * 0.01
                if score > best_score:
                    best_score = score
                    best_drop = drop
            if best_drop is not None:
                tx, ty = best_drop['x'], best_drop['y']
            if tx is None:
                tx, ty = (grx, gry) if d['team'] == 'green' else (blx, bly)
            dx = tx - d['x']
            dy = ty - d['y']
            dist = math.hypot(dx, dy)
            mvx = 0.0
            mvy = 0.0
            if dist > 1:
                mvx += (dx / dist) * supply_drone_spd
                mvy += (dy / dist) * supply_drone_spd
            for obs in obstacles:
                if obs.get('otype') != 'building':
                    continue
                cx, cy = closest_point_on_rect(obs['rect'], d['x'], d['y'])
                odx = d['x'] - cx
                ody = d['y'] - cy
                od = math.hypot(odx, ody)
                if 0 < od < drone_avoid_dist:
                    mvx += (odx / od) * supply_drone_spd
                    mvy += (ody / od) * supply_drone_spd
            mag = math.hypot(mvx, mvy)
            if mag > 0:
                d['x'] += (mvx / mag) * supply_drone_spd * dt
                d['y'] += (mvy / mag) * supply_drone_spd * dt
            d['x'] = max(8, min(frame_x - 8, d['x']))
            d['y'] = max(8, min(frame_y - 8, d['y']))
            if best_drop is not None and math.hypot(d['x'] - best_drop['x'], d['y'] - best_drop['y']) <= 16:
                if d.get('hover_t') is None:
                    d['hover_t'] = now
                    next_supply.append(d)
                    continue
                if now - d['hover_t'] < supply_drone_collect_ms:
                    next_supply.append(d)
                    continue
                consumed_drop_ids.add(id(best_drop))
                dtype = best_drop.get('type')
                if d['team'] == 'green':
                    if dtype == "ammo":
                        gr_ammo_ap = min(cannon_ap_max, gr_ammo_ap + 5)
                        gr_ammo_he = min(cannon_he_max, gr_ammo_he + 3)
                        gr_ammo_atgm = min(cannon_atgm_max, gr_ammo_atgm + 1)
                        gr_mg_ammo = min(mg_ammo_max, gr_mg_ammo + 150)
                    elif dtype == "fuel":
                        gr_fuel = min(fuel_max, gr_fuel + 30)
                    elif dtype == "airstrike":
                        strike_centers = []
                        if round_mode == "KOTH" and hill_control == "blue":
                            strike_centers.append((hill_x, hill_y, 0.7))
                        strike_centers.append((blx, bly, 0.3))
                        for _ in range(8):
                            cx0, cy0, w = random.choice(strike_centers)
                            spread = 120 if (round_mode == "KOTH" and hill_control == "blue" and w > 0.5) else 130
                            cx = cx0 + random.uniform(-spread, spread)
                            cy = cy0 + random.uniform(-spread, spread)
                            explosions.append({'x': cx, 'y': cy, 'angle': 0, 't': now, 'r': 72})
                            if bl_protect_until <= now and math.hypot(cx - blx, cy - bly) <= 78:
                                bl_hp = max(0, bl_hp - 24)
                            for v in apcs + jeeps + humvees:
                                if v['team'] == 'blue' and math.hypot(cx - v['x'], cy - v['y']) <= 80:
                                    v['hp'] -= 34
                            for u in infantry:
                                if u['team'] == 'blue' and math.hypot(cx - u['x'], cy - u['y']) <= 70:
                                    u['hp'] -= 55
                        if hit_sound:
                            hit_sound.play()
                else:
                    if dtype == "ammo":
                        bl_ammo_ap = min(cannon_ap_max, bl_ammo_ap + 5)
                        bl_ammo_he = min(cannon_he_max, bl_ammo_he + 3)
                        bl_ammo_atgm = min(cannon_atgm_max, bl_ammo_atgm + 1)
                        bl_mg_ammo = min(mg_ammo_max, bl_mg_ammo + 150)
                    elif dtype == "fuel":
                        bl_fuel = min(fuel_max, bl_fuel + 30)
                    elif dtype == "airstrike":
                        strike_centers = []
                        if round_mode == "KOTH" and hill_control == "green":
                            strike_centers.append((hill_x, hill_y, 0.7))
                        strike_centers.append((grx, gry, 0.3))
                        for _ in range(8):
                            cx0, cy0, w = random.choice(strike_centers)
                            spread = 120 if (round_mode == "KOTH" and hill_control == "green" and w > 0.5) else 130
                            cx = cx0 + random.uniform(-spread, spread)
                            cy = cy0 + random.uniform(-spread, spread)
                            explosions.append({'x': cx, 'y': cy, 'angle': 0, 't': now, 'r': 72})
                            if gr_protect_until <= now and math.hypot(cx - grx, cy - gry) <= 78:
                                gr_hp = max(0, gr_hp - 24)
                            for v in apcs + jeeps + humvees:
                                if v['team'] == 'green' and math.hypot(cx - v['x'], cy - v['y']) <= 80:
                                    v['hp'] -= 34
                            for u in infantry:
                                if u['team'] == 'green' and math.hypot(cx - u['x'], cy - u['y']) <= 70:
                                    u['hp'] -= 55
                        if hit_sound:
                            hit_sound.play()
                continue
            d['hover_t'] = None
            next_supply.append(d)
        supply_drones = next_supply
        if consumed_drop_ids:
            airdrops = [d for d in airdrops if id(d) not in consumed_drop_ids]

        # Attack drones: kamikaze highest-priority targets.
        next_attack = []
        for d in attack_drones:
            if try_intercept_air_target(d, bullets, infantry_bullets, now, explosions):
                if hit_sound:
                    hit_sound.play()
                continue
            if now - d.get('spawn_t', now) < attack_drone_arm_ms:
                next_attack.append(d)
                continue
            if d['team'] == 'green':
                candidates = []
                if not bl_tank_dead:
                    candidates.append((0, blx, bly))
                candidates.extend((1, v['x'], v['y']) for v in apcs + jeeps + humvees if v['team'] == 'blue')
                candidates.extend((2, u['x'], u['y']) for u in infantry if u['team'] == 'blue')
            else:
                candidates = []
                if not gr_tank_dead:
                    candidates.append((0, grx, gry))
                candidates.extend((1, v['x'], v['y']) for v in apcs + jeeps + humvees if v['team'] == 'green')
                candidates.extend((2, u['x'], u['y']) for u in infantry if u['team'] == 'green')
            if not candidates:
                continue
            candidates.sort(key=lambda c: (c[0], math.hypot(c[1] - d['x'], c[2] - d['y'])))
            _, tx, ty = candidates[0]
            dx = tx - d['x']
            dy = ty - d['y']
            dist = math.hypot(dx, dy)
            mvx = 0.0
            mvy = 0.0
            if dist > 0:
                mvx += (dx / dist) * attack_drone_spd
                mvy += (dy / dist) * attack_drone_spd
            for obs in obstacles:
                if obs.get('otype') != 'building':
                    continue
                cx, cy = closest_point_on_rect(obs['rect'], d['x'], d['y'])
                odx = d['x'] - cx
                ody = d['y'] - cy
                od = math.hypot(odx, ody)
                if 0 < od < drone_avoid_dist:
                    mvx += (odx / od) * attack_drone_spd
                    mvy += (ody / od) * attack_drone_spd
            mag = math.hypot(mvx, mvy)
            if mag > 0:
                d['x'] += (mvx / mag) * attack_drone_spd * dt
                d['y'] += (mvy / mag) * attack_drone_spd * dt
            if dist <= 14:
                if d.get('lock_t') is None:
                    d['lock_t'] = now
                    next_attack.append(d)
                    continue
                if now - d['lock_t'] < attack_drone_dive_ms:
                    next_attack.append(d)
                    continue
                explosions.append({'x': d['x'], 'y': d['y'], 'angle': 0, 't': now, 'r': 60})
                if d['team'] == 'green':
                    if bl_protect_until <= now and math.hypot(d['x'] - blx, d['y'] - bly) <= 72:
                        bl_hp = max(0, bl_hp - attack_drone_damage)
                else:
                    if gr_protect_until <= now and math.hypot(d['x'] - grx, d['y'] - gry) <= 72:
                        gr_hp = max(0, gr_hp - attack_drone_damage)
                continue
            d['lock_t'] = None
            next_attack.append(d)
        attack_drones = next_attack
        bullets = [b for b in bullets if not b.get('spent')]
        infantry_bullets = [b for b in infantry_bullets if not b.get('spent')]

        # Hard caps per team (despawn oldest if too many)
        for team in ("green", "blue"):
            team_inf = [u for u in infantry if u['team'] == team]
            if len(team_inf) > ai_max_inf:
                team_inf.sort(key=lambda u: u.get('spawn_t', 0))
                drop = set(id(u) for u in team_inf[:-ai_max_inf])
                infantry = [u for u in infantry if id(u) not in drop]
            team_veh = [v for v in apcs + jeeps + humvees if v['team'] == team]
            if len(team_veh) > ai_max_veh:
                team_veh.sort(key=lambda v: v.get('spawn_t', 0))
                drop = set(id(v) for v in team_veh[:-ai_max_veh])
                apcs = [v for v in apcs if id(v) not in drop]
                jeeps = [v for v in jeeps if id(v) not in drop]
                humvees = [v for v in humvees if id(v) not in drop]
        if cannon_hit:
            hit_pause_until = max(hit_pause_until, now + hit_pause_ms)
            shake_timer = max(shake_timer, shake_duration)
            if hit_sound:
                hit_sound.play()
        if green_hits:
            if bl_protect_until <= now:
                gr_hp = max(gr_hp - green_damage, 0)
            bl_hits += green_hits
            bl_damage_dealt += green_damage
            bl_streak += green_hits
            bl_best_streak = max(bl_best_streak, bl_streak)
        if blue_hits:
            if gr_protect_until <= now:
                bl_hp = max(bl_hp - blue_damage, 0)
            gr_hits += blue_hits
            gr_damage_dealt += blue_damage
            gr_streak += blue_hits
            gr_best_streak = max(gr_best_streak, gr_streak)
        if gr_protect_until > now:
            inf_green_damage = 0.0
        if bl_protect_until > now:
            inf_blue_damage = 0.0
        if inf_green_damage:
            scale = infantry_tank_dmg_scale
            if gr_dead_until == 0 and gr_hp > 0:
                scale *= infantry_manned_scale
            inf_green_damage *= scale
            gr_hp = max(gr_hp - inf_green_damage, 0)
        if inf_blue_damage:
            scale = infantry_tank_dmg_scale
            if bl_dead_until == 0 and bl_hp > 0:
                scale *= infantry_manned_scale
            inf_blue_damage *= scale
            bl_hp = max(bl_hp - inf_blue_damage, 0)

        # Handle lives / respawn
        if gr_hp <= 0 and gr_dead_until == 0:
            gr_lives -= 1
            explosions.append({'x': grx, 'y': gry, 'angle': 0, 't': now})
            explosions.append({'x': grx + 12, 'y': gry - 6, 'angle': 0, 't': now})
            explosions.append({'x': grx - 8, 'y': gry + 10, 'angle': 0, 't': now})
            explosions.append({'x': grx + 20, 'y': gry + 18, 'angle': 0, 't': now})
            if hit_sound:
                hit_sound.play()
            blowouts.append({'x': grx, 'y': gry, 'angle': gr_turret_angle, 't': now, 'team': 'green'})
            push_kill_feed(kill_feed, "GREEN MBT DESTROYED", (255, 120, 120), now)
            gr_dead_until = now + kill_cd_ms
            gr_death_fx_until = now + 450
            shake_timer = max(shake_timer, shake_duration * 5)
            globals()['shake_mag'] = max(shake_mag, 12)
            if gr_lives > 0:
                bullets = []
                infantry_bullets = []
        if bl_hp <= 0 and bl_dead_until == 0:
            bl_lives -= 1
            explosions.append({'x': blx, 'y': bly, 'angle': 0, 't': now})
            explosions.append({'x': blx - 12, 'y': bly + 6, 'angle': 0, 't': now})
            explosions.append({'x': blx + 8, 'y': bly - 10, 'angle': 0, 't': now})
            explosions.append({'x': blx - 20, 'y': bly - 18, 'angle': 0, 't': now})
            if hit_sound:
                hit_sound.play()
            blowouts.append({'x': blx, 'y': bly, 'angle': bl_turret_angle, 't': now, 'team': 'blue'})
            push_kill_feed(kill_feed, "BLUE MBT DESTROYED", (255, 120, 120), now)
            bl_dead_until = now + kill_cd_ms
            bl_death_fx_until = now + 450
            shake_timer = max(shake_timer, shake_duration * 5)
            globals()['shake_mag'] = max(shake_mag, 12)
            if bl_lives > 0:
                bullets = []
                infantry_bullets = []
        if gr_dead_until and now >= gr_dead_until and gr_lives > 0:
            st = respawn_tank(gr_spawn, now)
            gr_hp = st['hp']
            grx, gry = st['x'], st['y']
            gr_vel = st['vel']
            gr_chassis_av = st['chassis_av']
            gr_ammo_ap = st['cannon_ap']
            gr_ammo_he = st['cannon_he']
            gr_ammo_atgm = st['cannon_atgm']
            gr_mg_ammo = st['mg_ammo']
            gr_fuel = st['fuel']
            gr_mg_heat = st['mg_heat']
            gr_overheat = st['overheat']
            gr_smoke_ammo = st['smoke_ammo']
            gr_repair_ammo = st['repair_ammo']
            gr_protect_until = st['protect_until']
            gr_engine_dmg = st.get('engine_dmg', 0.0)
            gr_turret_dmg = st.get('turret_dmg', 0.0)
            gr_dead_until = 0
            push_kill_feed(kill_feed, "GREEN MBT RESPAWNED", (160, 255, 160), now)
        if bl_dead_until and now >= bl_dead_until and bl_lives > 0:
            st = respawn_tank(bl_spawn, now)
            bl_hp = st['hp']
            blx, bly = st['x'], st['y']
            bl_vel = st['vel']
            bl_chassis_av = st['chassis_av']
            bl_ammo_ap = st['cannon_ap']
            bl_ammo_he = st['cannon_he']
            bl_ammo_atgm = st['cannon_atgm']
            bl_mg_ammo = st['mg_ammo']
            bl_fuel = st['fuel']
            bl_mg_heat = st['mg_heat']
            bl_overheat = st['overheat']
            bl_smoke_ammo = st['smoke_ammo']
            bl_repair_ammo = st['repair_ammo']
            bl_protect_until = st['protect_until']
            bl_engine_dmg = st.get('engine_dmg', 0.0)
            bl_turret_dmg = st.get('turret_dmg', 0.0)
            bl_dead_until = 0
            push_kill_feed(kill_feed, "BLUE MBT RESPAWNED", (160, 180, 255), now)

        muzzle_flashes = [f for f in muzzle_flashes if now - f['t'] <= 100]
        explosions = [e for e in explosions if now - e['t'] <= 180] + new_explosions
        # Explosion vs infantry
        vehicles = apcs + jeeps + humvees
        for boom in new_explosions:
            for unit in infantry:
                if unit.get('protect_until', 0) > now:
                    continue
                if math.hypot(unit['x'] - boom['x'], unit['y'] - boom['y']) <= mortar_blast_r * 0.6:
                    unit['hp'] -= 12
            for veh in vehicles:
                if veh.get('protect_until', 0) > now:
                    continue
                if math.hypot(veh['x'] - boom['x'], veh['y'] - boom['y']) <= mortar_blast_r * 0.7:
                    veh['hp'] -= 18
        # Vehicle death explosions
        dead_apcs = []
        for apc in apcs:
            if apc['hp'] <= 0:
                explosions.append({'x': apc['x'], 'y': apc['y'], 'angle': 0, 't': now})
                explosions.append({'x': apc['x'] + 6, 'y': apc['y'] - 4, 'angle': 0, 't': now})
                dead_apcs.append(apc)
        if dead_apcs:
            g_dead = sum(1 for v in dead_apcs if v['team'] == 'green')
            b_dead = sum(1 for v in dead_apcs if v['team'] == 'blue')
            if g_dead:
                push_kill_feed(kill_feed, f"GREEN APC LOST x{g_dead}", (255, 170, 170), now)
            if b_dead:
                push_kill_feed(kill_feed, f"BLUE APC LOST x{b_dead}", (180, 200, 255), now)
            apcs = [a for a in apcs if a['hp'] > 0]
        dead_jeeps = []
        for jeep in jeeps:
            if jeep['hp'] <= 0:
                explosions.append({'x': jeep['x'], 'y': jeep['y'], 'angle': 0, 't': now})
                explosions.append({'x': jeep['x'] + 5, 'y': jeep['y'] - 3, 'angle': 0, 't': now})
                dead_jeeps.append(jeep)
        if dead_jeeps:
            g_dead = sum(1 for v in dead_jeeps if v['team'] == 'green')
            b_dead = sum(1 for v in dead_jeeps if v['team'] == 'blue')
            if g_dead:
                push_kill_feed(kill_feed, f"GREEN JEEP LOST x{g_dead}", (255, 170, 170), now)
            if b_dead:
                push_kill_feed(kill_feed, f"BLUE JEEP LOST x{b_dead}", (180, 200, 255), now)
            jeeps = [j for j in jeeps if j['hp'] > 0]
        dead_humvees = []
        for hv in humvees:
            if hv['hp'] <= 0:
                explosions.append({'x': hv['x'], 'y': hv['y'], 'angle': 0, 't': now})
                explosions.append({'x': hv['x'] + 5, 'y': hv['y'] - 3, 'angle': 0, 't': now})
                dead_humvees.append(hv)
        if dead_humvees:
            g_dead = sum(1 for v in dead_humvees if v['team'] == 'green')
            b_dead = sum(1 for v in dead_humvees if v['team'] == 'blue')
            if g_dead:
                push_kill_feed(kill_feed, f"GREEN HMV LOST x{g_dead}", (255, 170, 170), now)
            if b_dead:
                push_kill_feed(kill_feed, f"BLUE HMV LOST x{b_dead}", (180, 200, 255), now)
            humvees = [h for h in humvees if h['hp'] > 0]
        repair_rings = [r for r in repair_rings if now - r['t'] <= repair_ring_ms]
        blowouts = [b for b in blowouts if now - b['t'] <= 420]
        smokes = [s for s in smokes if now - s['t'] <= smoke_duration_ms]
        kill_feed = [k for k in kill_feed if now - k['t'] <= kill_feed_life_ms]
        if shake_timer > 0:
            shake_timer = max(0.0, shake_timer - raw_dt)
            shake_x = random.uniform(-shake_mag, shake_mag)
            shake_y = random.uniform(-shake_mag, shake_mag)
        else:
            shake_x = 0.0
            shake_y = 0.0
        if mode == "pvc":
            mx, my = pygame.mouse.get_pos()
            dx = mx - grx
            dy = my - gry
            target = math.degrees(math.atan2(-dy, dx)) % 360
            prev_mouse_turret = gr_turret_angle
            gr_turret_angle = approach_angle(gr_turret_angle, target, 200 * raw_dt)
            # Green turret obstacle lock in PvC mouse-aim:
            # if new angle collides, rewind to previous angle.
            test_rect = get_collision_rect(gr_tr, (grx, gry), gr_turret_angle, TURRET_HITBOX_SCALE)
            if any(test_rect.colliderect(obs['rect']) for obs in obstacles):
                gr_turret_angle = prev_mouse_turret
                gr_turret_av = 0.0
        gr_buffs = []
        bl_buffs = []
        if gr_armor_until > now:
            gr_buffs.append("ARMOR")
        if gr_rapid_until > now:
            gr_buffs.append("RAPID")
        if bl_armor_until > now:
            bl_buffs.append("ARMOR")
        if bl_rapid_until > now:
            bl_buffs.append("RAPID")
        if gr_engine_dmg > 0.2:
            gr_buffs.append("ENGINE DMG")
        if gr_turret_dmg > 0.2:
            gr_buffs.append("TURRET DMG")
        if bl_engine_dmg > 0.2:
            bl_buffs.append("ENGINE DMG")
        if bl_turret_dmg > 0.2:
            bl_buffs.append("TURRET DMG")
        if round_mode == "KOTH" and hill_control == "green":
            gr_buffs.append("HILL DMG")
        if round_mode == "KOTH" and hill_control == "blue":
            bl_buffs.append("HILL DMG")
        if not gr_buffs:
            gr_buffs = None
        if not bl_buffs:
            bl_buffs = None
        if active_quality != "PERFORMANCE":
            # Track marks
            if abs(gr_vel) > 20 and not gr_tank_dead and (now - last_green_shot) % 120 < 20:
                fx, fy = tank_forward(gr_chassis_angle)
                px = -fy
                py = fx
                x1 = grx - fx * 14 + px * 10
                y1 = gry + fy * 14 + py * 10
                x2 = grx - fx * 22 + px * 10
                y2 = gry + fy * 22 + py * 10
                track_marks.append({'x1': x1, 'y1': y1, 'x2': x2, 'y2': y2, 't': now})
                x1 = grx - fx * 14 - px * 10
                y1 = gry + fy * 14 - py * 10
                x2 = grx - fx * 22 - px * 10
                y2 = gry + fy * 22 - py * 10
                track_marks.append({'x1': x1, 'y1': y1, 'x2': x2, 'y2': y2, 't': now})
            if abs(bl_vel) > 20 and not bl_tank_dead and (now - last_blue_shot) % 120 < 20:
                fx, fy = tank_forward(bl_chassis_angle)
                px = -fy
                py = fx
                x1 = blx - fx * 14 + px * 10
                y1 = bly + fy * 14 + py * 10
                x2 = blx - fx * 22 + px * 10
                y2 = bly + fy * 22 + py * 10
                track_marks.append({'x1': x1, 'y1': y1, 'x2': x2, 'y2': y2, 't': now})
                x1 = blx - fx * 14 - px * 10
                y1 = bly + fy * 14 - py * 10
                x2 = blx - fx * 22 - px * 10
                y2 = bly + fy * 22 - py * 10
                track_marks.append({'x1': x1, 'y1': y1, 'x2': x2, 'y2': y2, 't': now})

            # Engine smoke spawner (damage-based)
            if gr_hp < max_hp * 0.5 and not gr_tank_dead and random.random() < 0.4:
                fx, fy = tank_forward(gr_chassis_angle)
                engine_smoke.append({'x': grx - fx * 20, 'y': gry + fy * 20, 'vx': random.uniform(-10, 10), 'vy': random.uniform(-20, 5), 't': now, 'life': engine_smoke_life})
            if bl_hp < max_hp * 0.5 and not bl_tank_dead and random.random() < 0.4:
                fx, fy = tank_forward(bl_chassis_angle)
                engine_smoke.append({'x': blx - fx * 20, 'y': bly + fy * 20, 'vx': random.uniform(-10, 10), 'vy': random.uniform(-20, 5), 't': now, 'life': engine_smoke_life})
            for v in apcs + jeeps + humvees:
                if v.get('hp', 0) < v.get('hp_max', 1) * 0.5 and random.random() < 0.3:
                    ang = v.get('angle', 0)
                    fx, fy = tank_forward(ang)
                    engine_smoke.append({'x': v['x'] - fx * 14, 'y': v['y'] + fy * 14, 'vx': random.uniform(-8, 8), 'vy': random.uniform(-18, 4), 't': now, 'life': engine_smoke_life})

            # Update smoke drift
            next_engine_smoke = []
            for p in engine_smoke:
                age = now - p['t']
                if age <= p['life']:
                    p['x'] += p.get('vx', 0) * dt
                    p['y'] += p.get('vy', 0) * dt
                    next_engine_smoke.append(p)
            engine_smoke = next_engine_smoke
        else:
            track_marks = []
            engine_smoke = []

        # Hard FX caps to prevent frame spikes.
        if len(muzzle_flashes) > 140:
            muzzle_flashes = muzzle_flashes[-140:]
        if len(explosions) > 90:
            explosions = explosions[-90:]
        if len(casings) > 220:
            casings = casings[-220:]
        if wind_vec != (0.0, 0.0):
            for sm in smokes:
                sm['x'] += wind_vec[0] * dt * 0.08
                sm['y'] += wind_vec[1] * dt * 0.08
        gr_pool_hp = max(0.0, gr_hp) + max(0, gr_lives - 1) * max_hp
        bl_pool_hp = max(0.0, bl_hp) + max(0, bl_lives - 1) * max_hp

        draw_window(
            grx=grx, gry=gry, blx=blx, bly=bly,
            gr_hp=gr_hp, bl_hp=bl_hp,
            gr_heat=gr_mg_heat, bl_heat=bl_mg_heat, heat_max=biome_heat_max,
            gr_chassis_angle=gr_chassis_angle, gr_turret_angle=gr_turret_angle,
            bl_chassis_angle=bl_chassis_angle, bl_turret_angle=bl_turret_angle,
            bullets=bullets, infantry_bullets=infantry_bullets, infantry=infantry,
            apcs=apcs, jeeps=jeeps, humvees=humvees, supply_drones=supply_drones, attack_drones=attack_drones, repair_rings=repair_rings, blowouts=blowouts,
            muzzle_flashes=muzzle_flashes, explosions=explosions, obstacles=obstacles, airdrops=airdrops,
            smokes=smokes, mines=mines, now_ms=now,
            gr_ammo_ap=gr_ammo_ap, gr_ammo_he=gr_ammo_he, gr_ammo_atgm=gr_ammo_atgm, gr_ammo_mg=gr_mg_ammo,
            bl_ammo_ap=bl_ammo_ap, bl_ammo_he=bl_ammo_he, bl_ammo_atgm=bl_ammo_atgm, bl_ammo_mg=bl_mg_ammo,
            gr_fuel=gr_fuel, bl_fuel=bl_fuel, gr_smoke_ammo=gr_smoke_ammo, bl_smoke_ammo=bl_smoke_ammo,
            gr_repair_ammo=gr_repair_ammo, bl_repair_ammo=bl_repair_ammo, gr_lives=gr_lives, bl_lives=bl_lives,
            gr_ammo_type=gr_ammo_type, bl_ammo_type=bl_ammo_type,
            gr_reload_left=reload_left_ratio(now, last_green_shot, gr_cannon_cd),
            bl_reload_left=reload_left_ratio(now, last_blue_shot, bl_cannon_cd),
            gr_protect_until=gr_protect_until, bl_protect_until=bl_protect_until,
            shake_x=shake_x, shake_y=shake_y, gr_recoil=gr_recoil, bl_recoil=bl_recoil,
            gr_turret_recoil=gr_turret_recoil, bl_turret_recoil=bl_turret_recoil,
            theme=theme, night_alpha=night_alpha, clock_text=clock_text, weather_type=weather_type,
            weather_particles=weather_particles, engine_smoke=engine_smoke, track_marks=track_marks, casings=casings,
            night_vision=night_vision, settings_open=settings_open,
            settings_data={"music": music_vol, "sfx": sfx_vol, "weather": weather_enabled, "day_speed": day_speed_mult, "night_dark": night_dark_setting, "particles": particle_enabled, "quality": quality_mode, "auto_low": auto_low_active},
            gr_buffs=gr_buffs, bl_buffs=bl_buffs,
            hide_gr_tank=(gr_dead_until > now or gr_tank_dead),
            hide_bl_tank=(bl_dead_until > now or bl_tank_dead),
            perf_data=({
                "fps": fps_now,
                "inf": len(infantry),
                "veh": len(apcs) + len(jeeps) + len(humvees),
                "bul": len(bullets),
                "ibul": len(infantry_bullets),
                "weather": len(weather_particles),
                "think_ms": ai_think_interval,
            } if show_perf else None),
            kill_feed=kill_feed,
            quality_mode=("AUTO-LOW" if auto_low_active else active_quality),
            koth_data={"mode": round_mode, "x": hill_x, "y": hill_y, "r": hill_r, "control": hill_control, "capturing": hill_capturing, "score": koth_score, "g_ms": gr_hill_ms, "b_ms": bl_hill_ms, "target_ms": koth_target_ms, "gr_pool": gr_pool_hp, "bl_pool": bl_pool_hp, "gr_base": gr_barracks['hp'], "bl_base": bl_barracks['hp'], "base_max": barracks_hp_max},
            siege_data={"mode": round_mode, "green": gr_barracks, "blue": bl_barracks},
            selected_units=None,
            gr_class=gr_class,
            bl_class=bl_class,
            gr_gun_elev=gr_turret_elev,
            bl_gun_elev=bl_turret_elev
        )
        
        if bl_hp <= 0 and bl_lives == 0 and not bl_tank_dead:
            bl_tank_dead = True
            last_tank_died_time = now
        if gr_hp <= 0 and gr_lives == 0 and not gr_tank_dead:
            gr_tank_dead = True
            last_tank_died_time = now

        gr_infantry_alive = any(u['team'] == 'green' for u in infantry)
        bl_infantry_alive = any(u['team'] == 'blue' for u in infantry)
        gr_vehicles_alive = any(v['team'] == 'green' for v in apcs + jeeps + humvees)
        bl_vehicles_alive = any(v['team'] == 'blue' for v in apcs + jeeps + humvees)

        gr_all_dead = gr_tank_dead and not gr_infantry_alive and not gr_vehicles_alive
        bl_all_dead = bl_tank_dead and not bl_infantry_alive and not bl_vehicles_alive

        if round_mode == "KOTH" and gr_hill_ms >= koth_target_ms:
            winner = "Green Wins!"
            running = False
            game_over_timer = now
        elif round_mode == "KOTH" and bl_hill_ms >= koth_target_ms:
            winner = "Blue Wins!"
            running = False
            game_over_timer = now
        elif round_mode == "SIEGE" and gr_barracks['hp'] <= 0:
            winner = "Blue Wins!"
            running = False
            game_over_timer = now
        elif round_mode == "SIEGE" and bl_barracks['hp'] <= 0:
            winner = "Green Wins!"
            running = False
            game_over_timer = now
        elif gr_all_dead:
            winner = "Blue Wins!"
            running = False
            game_over_timer = now
        elif bl_all_dead:
            winner = "Green Wins!"
            running = False
            game_over_timer = now
        elif gr_tank_dead and bl_tank_dead and gr_lives == 0 and bl_lives == 0:
            elapsed = now - start_time
            if elapsed >= 60000:
                winner = "Stalemate!"
                running = False
                game_over_timer = now

    # Simple, functional game over screen
    if winner is not None:
        fx_end = pygame.time.get_ticks() + 1200
        while pygame.time.get_ticks() < fx_end:
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    pygame.quit()
                    sys.exit()
            now = pygame.time.get_ticks()
            draw_window(
                grx=grx, gry=gry, blx=blx, bly=bly,
                gr_hp=gr_hp, bl_hp=bl_hp,
                gr_heat=gr_mg_heat, bl_heat=bl_mg_heat, heat_max=biome_heat_max,
                gr_chassis_angle=gr_chassis_angle, gr_turret_angle=gr_turret_angle,
                bl_chassis_angle=bl_chassis_angle, bl_turret_angle=bl_turret_angle,
                bullets=bullets, infantry_bullets=infantry_bullets, infantry=infantry,
                apcs=apcs, jeeps=jeeps, humvees=humvees, supply_drones=supply_drones, attack_drones=attack_drones, repair_rings=repair_rings, blowouts=blowouts,
                muzzle_flashes=muzzle_flashes, explosions=explosions, obstacles=obstacles, airdrops=airdrops,
                smokes=smokes, mines=mines, now_ms=now,
                gr_ammo_ap=gr_ammo_ap, gr_ammo_he=gr_ammo_he, gr_ammo_atgm=gr_ammo_atgm, gr_ammo_mg=gr_mg_ammo,
                bl_ammo_ap=bl_ammo_ap, bl_ammo_he=bl_ammo_he, bl_ammo_atgm=bl_ammo_atgm, bl_ammo_mg=bl_mg_ammo,
                gr_fuel=gr_fuel, bl_fuel=bl_fuel, gr_smoke_ammo=gr_smoke_ammo, bl_smoke_ammo=bl_smoke_ammo,
                gr_repair_ammo=gr_repair_ammo, bl_repair_ammo=bl_repair_ammo, gr_lives=gr_lives, bl_lives=bl_lives,
                gr_ammo_type=gr_ammo_type, bl_ammo_type=bl_ammo_type,
                gr_reload_left=reload_left_ratio(now, last_green_shot, bull_rld),
                bl_reload_left=reload_left_ratio(now, last_blue_shot, bull_rld),
                gr_protect_until=gr_protect_until, bl_protect_until=bl_protect_until,
                shake_x=0.0, shake_y=0.0, gr_recoil=gr_recoil, bl_recoil=bl_recoil,
                gr_turret_recoil=gr_turret_recoil, bl_turret_recoil=bl_turret_recoil,
                theme=theme, night_alpha=night_dark_alpha, clock_text="", weather_type="clear",
                weather_particles=[], engine_smoke=[], track_marks=track_marks, casings=casings,
                night_vision=False, settings_open=False, settings_data=None,
                gr_buffs=None, bl_buffs=None,
                hide_gr_tank=(gr_dead_until > now or gr_tank_dead),
                hide_bl_tank=(bl_dead_until > now or bl_tank_dead),
                kill_feed=kill_feed,
                quality_mode=quality_mode,
                koth_data={"mode": round_mode, "x": hill_x, "y": hill_y, "r": hill_r, "control": hill_control, "capturing": hill_capturing, "score": koth_score, "g_ms": gr_hill_ms, "b_ms": bl_hill_ms, "target_ms": koth_target_ms, "gr_pool": gr_pool_hp, "bl_pool": bl_pool_hp, "gr_base": gr_barracks['hp'], "bl_base": bl_barracks['hp'], "base_max": barracks_hp_max},
                siege_data={"mode": round_mode, "green": gr_barracks, "blue": bl_barracks},
                selected_units=None,
                gr_class=gr_class,
                bl_class=bl_class
            )
            overlay = pygame.Surface((frame_x, frame_y), pygame.SRCALPHA)
            overlay.fill((0, 0, 0, 170))
            game_window.blit(overlay, (0, 0))
            win_color = (90, 220, 90) if winner == "Green Wins!" else (90, 140, 240) if winner == "Blue Wins!" else (200, 200, 200)
            draw_text(game_window, ocr_big, "GAME OVER", win_color, (frame_x // 2, frame_y // 2 - 40))
            draw_text(game_window, ocr, winner, white, (frame_x // 2, frame_y // 2 + 20))
            pygame.display.update()
            pygame.time.delay(30)

    duration_ms = pygame.time.get_ticks() - start_time
    duration_s = duration_ms / 1000.0
    gr_acc = (gr_hits / gr_shots * 100.0) if gr_shots > 0 else 0.0
    bl_acc = (bl_hits / bl_shots * 100.0) if bl_shots > 0 else 0.0
    gr_missed = gr_shots - gr_hits
    bl_missed = bl_shots - bl_hits
    stats = [
        ("Shots Fired", f"{gr_shots}", f"{bl_shots}"),
        ("Hits", f"{gr_hits}", f"{bl_hits}"),
        ("Shots Missed", f"{gr_missed}", f"{bl_missed}"),
        ("Accuracy", f"{gr_acc:.0f}%", f"{bl_acc:.0f}%"),
        ("Damage Dealt", f"{gr_damage_dealt:.0f}", f"{bl_damage_dealt:.0f}"),
        ("Best Hit Streak", f"{gr_best_streak}", f"{bl_best_streak}"),
        ("HP Remaining", f"{int(gr_hp)}", f"{int(bl_hp)}"),
        ("Match Time", f"{duration_s:.0f}s", f"{duration_s:.0f}s"),
    ]

    return winner, stats


#------------------------------------------------------------


#Game loop
if __name__ == "__main__":
    mode = mode_screen()
    if mode is None:
        pygame.quit()
        sys.exit()
    ai_level = "normal"
    reinforcements_enabled = True
    if mode == "pvc":
        ai_level = difficulty_screen()
        if ai_level is None:
            pygame.quit()
            sys.exit()
    reinforcements_enabled = reinforcement_screen()
    if reinforcements_enabled is None:
        pygame.quit()
        sys.exit()
    class_pick = team_class_screen(mode)
    if class_pick is None:
        pygame.quit()
        sys.exit()
    gr_class, bl_class = class_pick
    if welcome_screen():
        while True:
            result = run_game(mode, ai_level, reinforcements_enabled, gr_class, bl_class)
            if result is None:
                break
            winner, stats = result
            if winner == "RESTART":
                mode = mode_screen()
                if mode is None:
                    break
                ai_level = "normal"
                reinforcements_enabled = True
                if mode == "pvc":
                    ai_level = difficulty_screen()
                    if ai_level is None:
                        break
                reinforcements_enabled = reinforcement_screen()
                if reinforcements_enabled is None:
                    break
                class_pick = team_class_screen(mode)
                if class_pick is None:
                    break
                gr_class, bl_class = class_pick
                if not welcome_screen():
                    break
                continue
            if winner == "LEAVE":
                mode = mode_screen()
                if mode is None:
                    break
                ai_level = "normal"
                reinforcements_enabled = True
                if mode == "pvc":
                    ai_level = difficulty_screen()
                    if ai_level is None:
                        break
                reinforcements_enabled = reinforcement_screen()
                if reinforcements_enabled is None:
                    break
                class_pick = team_class_screen(mode)
                if class_pick is None:
                    break
                gr_class, bl_class = class_pick
                if not welcome_screen():
                    break
                continue
            if winner is not None:
                if not win_screen(winner, stats):
                    break
                mode = mode_screen()
                if mode is None:
                    break
                ai_level = "normal"
                if mode == "pvc":
                    ai_level = difficulty_screen()
                    if ai_level is None:
                        break
                class_pick = team_class_screen(mode)
                if class_pick is None:
                    break
                gr_class, bl_class = class_pick
                if not welcome_screen():
                    break
                continue
    pygame.quit()
    sys.exit()
