"""
VampireFlywheel V0.4 — Synergy + 多地图 + 武器图鉴 + 真实音效框架
基于 V0.3 增量开发，V0.3 全部功能保留。
"""
import pygame, sys, math, random, json, os, struct
try: import fcntl
except ImportError: fcntl = None

pygame.init()
try:
    pygame.mixer.init(frequency=22050, size=-16, channels=2, buffer=512)
    MIXER_OK = True
except Exception:
    MIXER_OK = False

WIDTH, HEIGHT = 1280, 720
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("VampireFlywheel V0.4 - 四环飞轮")
clock = pygame.time.Clock()

def find_cn():
    for n in ['microsoftyaheiui','microsoftyahei','msyh','simhei','pingfangsc',
             'pingfang','stheitisc','stheiti','hiraginosansgb','wqy-microhei',
             'notosanscjksc','arialunicode']:
        p = pygame.font.match_font(n)
        if p: return p
    return None
CN = find_cn()
def mk(s): return pygame.font.Font(CN, s) if CN else pygame.font.Font(None, s+4)
font_xs, font_s, font_m, font_l, font_xl, font_xxl = mk(14), mk(18), mk(22), mk(30), mk(40), mk(60)

WHITE=(245,245,245); RED=(255,70,70); DARK_RED=(170,30,30); GREEN=(80,220,110)
BLUE=(80,160,255); BLACK=(0,0,0); YELLOW=(255,220,60); GOLD=(255,200,0)
PURPLE=(190,90,220); ORANGE=(255,140,30); CYAN=(90,220,255); GRAY=(130,130,140)
DARK_GRAY=(50,50,60); GRASS=(32,50,30); GRAVESTONE=(60,60,65)
CARD_BG=(40,40,56); CARD_HL=(90,90,130)
EVO_GOLD=(255,220,120); SYN_CYAN=(80,255,220)
FROST_C=(170,220,255); POISON_C=(120,220,80)

MAPS = {
    "cemetery": {"name":"墓园","bg":(18,22,16),"grid":(24,30,22),
                 "decos":{"grass":3,"stone":1,"cross":1},
                 "spawn_mult":1.0,"exp_mult":1.0,"cost":0},
    "desert":   {"name":"荒漠","bg":(46,36,26),"grid":(70,55,38),
                 "decos":{"cactus":3,"skull":2,"bone":2},
                 "spawn_mult":0.9,"exp_mult":1.2,"cost":150},
}

META_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "meta_progress.json")
def load_meta():
    d = {"coins":0,"speed_lv":0,"hp_lv":0,"exp_lv":0,"slot_lv":0,
         "best_wave":0,"best_kills":0,"total_runs":0,
         "current_map":"cemetery","unlocked_maps":["cemetery"],
         "unlocked_weapons":["garlic"],"unlocked_evolutions":[],
         "unlocked_synergies":[],"achievements":[]}
    if os.path.exists(META_FILE):
        try:
            with open(META_FILE,"r") as f:
                if fcntl:
                    try: fcntl.flock(f.fileno(), fcntl.LOCK_SH)
                    except: pass
                data = json.load(f)
            for k,v in d.items():
                if k not in data: data[k] = v
            return data
        except Exception: pass
    return d

def save_meta(m):
    """F5: 原子保存 + 文件锁，多开不互相覆盖"""
    try:
        tmp = META_FILE + ".tmp"
        with open(tmp, "w") as f:
            if fcntl:
                try: fcntl.flock(f.fileno(), fcntl.LOCK_EX)
                except: pass
            json.dump(m, f, indent=2)
            f.flush()
            try: os.fsync(f.fileno())
            except: pass
        os.replace(tmp, META_FILE)
    except Exception: pass

META = load_meta()

META_UPGRADES = {
    "speed":{"name":"起始速度","desc":"+0.4 移动速度",    "max":5, "cost":lambda lv: int(30*(lv+1)**1.4)},
    "hp":   {"name":"起始 HP",  "desc":"+10 最大生命",    "max":10,"cost":lambda lv: int(20*(lv+1)**1.3)},
    "exp":  {"name":"经验加成","desc":"+5% 经验获取",     "max":10,"cost":lambda lv: int(40*(lv+1)**1.4)},
    "slot": {"name":"武器槽位","desc":"+1 槽 / 解锁新武器","max":2,"cost":lambda lv: [200,350][min(lv,1)]},
}
COIN_CAP_PER_RUN = 60
def meta_speed_bonus(): return META["speed_lv"]*0.4
def meta_hp_bonus():    return META["hp_lv"]*10
def meta_exp_mult():    return 1.0 + META["exp_lv"]*0.05
def meta_max_weapons(): return [5,6,7][min(META["slot_lv"], 2)]

SFX_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "sfx")
BGM_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "bgm")

def synth(freq, duration, vol=0.3, wave='sine', sweep=0):
    if not MIXER_OK: return None
    rate=22050; n=int(rate*duration); buf=bytearray()
    for i in range(n):
        t=i/rate; env=max(0.0, 1.0 - (t/duration)**0.6); f=freq+sweep*t
        if wave=='sine':     v=math.sin(2*math.pi*f*t)
        elif wave=='square': v=1 if math.sin(2*math.pi*f*t)>0 else -1
        elif wave=='tri':    v=4*abs((f*t)%1.0 - 0.5) - 1
        elif wave=='noise':  v=random.uniform(-1,1)
        else: v=0
        s=max(-32767, min(32767, int(v*env*vol*32767)))
        buf += struct.pack('<hh', s, s)
    try: return pygame.mixer.Sound(buffer=bytes(buf))
    except Exception: return None

def load_sfx(name, *synth_args):
    """优先加载 sfx/<name>.wav，找不到则用 synth 合成占位。
    8bit 音效命名约定（推荐用 Bfxr/sfxr/ChipTone 导出 22050Hz 16bit .wav）：
      sfx/hit.wav | pickup.wav | levelup.wav | evolve.wav | boss_spawn.wav
      sfx/coin.wav | explode.wav | synergy.wav | achievement.wav
      sfx/freeze.wav | poison.wav"""
    if MIXER_OK:
        path = os.path.join(SFX_DIR, name + ".wav")
        if os.path.exists(path):
            try: return pygame.mixer.Sound(path)
            except Exception: pass
    return synth(*synth_args)

SFX = {}
def init_sfx():
    if not MIXER_OK: return
    SFX["hit"]         = load_sfx("hit",         180, 0.05, 0.15, 'square')
    SFX["pickup"]      = load_sfx("pickup",      900, 0.06, 0.18, 'sine')
    SFX["levelup"]     = load_sfx("levelup",     523, 0.35, 0.28, 'sine', 400)
    SFX["evolve"]      = load_sfx("evolve",      330, 0.70, 0.40, 'tri', 700)
    SFX["boss_spawn"]  = load_sfx("boss_spawn",  110, 0.60, 0.45, 'square', -30)
    SFX["coin"]        = load_sfx("coin",        1320,0.10, 0.22, 'sine')
    SFX["explode"]     = load_sfx("explode",     80,  0.20, 0.35, 'noise')
    SFX["synergy"]     = load_sfx("synergy",     660, 0.40, 0.32, 'tri', 200)
    SFX["achievement"] = load_sfx("achievement", 880, 0.50, 0.30, 'sine', 600)
    SFX["freeze"]      = load_sfx("freeze",      440, 0.25, 0.20, 'sine', -200)
    SFX["poison"]      = load_sfx("poison",      300, 0.30, 0.18, 'tri')
init_sfx()
def play(name):
    s = SFX.get(name)
    if s:
        try: s.play()
        except Exception: pass

def play_bgm(map_id):
    """TODO: 放 bgm/<map_id>.ogg|.mp3|.wav 即自动循环播放。"""
    if not MIXER_OK: return
    for ext in ('.ogg', '.mp3', '.wav'):
        path = os.path.join(BGM_DIR, map_id + ext)
        if os.path.exists(path):
            try:
                pygame.mixer.music.load(path)
                pygame.mixer.music.set_volume(0.25)
                pygame.mixer.music.play(-1)
                return
            except Exception: pass
    try: pygame.mixer.music.stop()
    except Exception: pass

WEAPONS = {
    "garlic":   {"name":"蒜头光环","desc":"对周围敌人持续灼烧","color":(220,220,150),"max_level":5},
    "wand":     {"name":"魔法飞弹","desc":"自动追踪最近的敌人","color":(180,120,255),"max_level":5},
    "whip":     {"name":"皮鞭",     "desc":"水平鞭击身前敌人",  "color":(220,110,110),"max_level":5},
    "halo":     {"name":"火焰旋环","desc":"环绕身边旋转的火球","color":(255,130,40), "max_level":5},
    "knife":    {"name":"飞刀",     "desc":"朝移动方向射出飞刀","color":(200,220,230),"max_level":5},
    "lightning":{"name":"雷电",     "desc":"随机闪电击中敌人",  "color":(200,230,255),"max_level":5},
    "frost":    {"name":"冰霜法阵","desc":"地面冰阵伤害+减速","color":FROST_C,"max_level":5},
    "poison":   {"name":"毒雾云",   "desc":"持久毒云造成 DOT", "color":POISON_C,"max_level":5},
}
PASSIVES = {
    "max_hp":  {"name":"强壮","desc":"+20 最大生命",     "color":(255,110,110),"max_level":5},
    "speed":   {"name":"迅捷","desc":"+10% 移动速度",    "color":(110,255,110),"max_level":5},
    "damage":  {"name":"力量","desc":"+15% 全武器伤害",  "color":(255,180,80), "max_level":5},
    "cooldown":{"name":"急速","desc":"-8% 武器冷却",     "color":(110,220,255),"max_level":5},
    "magnet":  {"name":"磁力","desc":"+30% 拾取范围",    "color":(220,110,255),"max_level":5},
    "regen":   {"name":"再生","desc":"+0.5/s 生命恢复",  "color":(255,90,160), "max_level":5},
    "area":    {"name":"扩张","desc":"+10% 武器范围",    "color":(255,240,150),"max_level":5},
}
EVOLUTIONS = {
    "garlic":{"name":"死神光环","color":(255,100,220),"desc":"巨大范围+吸血+死亡脉冲","prereq":"magnet","prereq_lv":1},
    "knife": {"name":"残影千刃","color":(200,240,255),"desc":"8 方位连发+残影+高穿透","prereq":"speed","prereq_lv":3},
    "halo":  {"name":"炼狱火轮","color":(255,80,0),   "desc":"高速旋转+灼烧 DOT",     "prereq":"area","prereq_lv":3},
    "frost": {"name":"永冻之地","color":(120,200,255),"desc":"巨型冰阵+长冻结",       "prereq":"cooldown","prereq_lv":3},
    "poison":{"name":"瘟疫吐息","color":(60,255,60),  "desc":"高伤毒云+多发",         "prereq":"damage","prereq_lv":3},
}
SYNERGIES = {
    "chain_lightning":{"weapon":"lightning","passive":"speed","passive_lv":3,
                       "name":"连锁风暴","desc":"闪电连跳 2 个相邻敌人"},
    "explosive_wand": {"weapon":"wand","passive":"area","passive_lv":3,
                       "name":"爆炸飞弹","desc":"魔法弹击中后 65 范围 AOE"},
    "giant_whip":     {"weapon":"whip","passive":"max_hp","passive_lv":3,
                       "name":"巨型鞭击","desc":"鞭子宽度 2× 伤害 1.5×"},
    "perpetual_halo": {"weapon":"halo","passive":"cooldown","passive_lv":3,
                       "name":"永动旋环","desc":"伤害判定频率翻倍"},
    "homing_knife":   {"weapon":"knife","passive":"magnet","passive_lv":3,
                       "name":"磁吸飞刀","desc":"飞刀微弱跟踪最近敌人"},
    "vital_garlic":   {"weapon":"garlic","passive":"regen","passive_lv":3,
                       "name":"生命光环","desc":"光环触发时每次回 1 HP"},
}
ACHIEVEMENTS = {
    "first_kill":     {"name":"初次染血","desc":"击杀第一只敌人"},
    "first_levelup":  {"name":"成长开始","desc":"第一次升级"},
    "first_evolution":{"name":"进化大师","desc":"完成一次武器进化"},
    "first_synergy":  {"name":"天命组合","desc":"首次激活 Synergy"},
    "boss_slain":     {"name":"屠龙者", "desc":"击败一个 BOSS"},
    "100_kills":      {"name":"百人斩", "desc":"单局击杀 100 敌人"},
    "wave_10":        {"name":"十波生还","desc":"活到 Wave 10"},
    "all_evolutions": {"name":"进化收藏家","desc":"集齐所有 5 个进化"},
    "unlock_desert":  {"name":"向死而生","desc":"解锁荒漠地图"},
    "first_run":      {"name":"新手玩家","desc":"完成第一次游戏"},
}
MAX_PARTICLES = 400
MAX_AFTERIMAGES = 80
MAX_DAMAGE_NUMBERS = 120
MAX_ENEMIES = 200

def gen_decorations(map_id):
    mapdef = MAPS.get(map_id, MAPS["cemetery"])
    decs = []
    kinds_pool = []
    for k, w in mapdef["decos"].items():
        kinds_pool.extend([k]*w)
    for _ in range(70):
        x = random.randint(20, WIDTH-20); y = random.randint(20, HEIGHT-20)
        decs.append({"pos": pygame.Vector2(x,y), "kind": random.choice(kinds_pool)})
    return decs

class Game:
    def __init__(self): self.reset()
    def reset(self):
        self.current_map = META["current_map"] if META["current_map"] in META["unlocked_maps"] else "cemetery"
        self.player = {
            "pos": pygame.Vector2(WIDTH//2, HEIGHT//2),
            "speed": 4.0 + meta_speed_bonus(),
            "radius": 18,
            "hp": 100 + meta_hp_bonus(),
            "max_hp": 100 + meta_hp_bonus(),
            "hp_regen": 0.0,
            "level": 1, "exp": 0, "exp_to_next": 10,
            "damage_mult": 1.0, "cooldown_mult": 1.0,
            "pickup_range": 75, "projectiles_bonus": 0,
            "area_mult": 1.0, "iframes": 0.0,
            "facing": pygame.Vector2(1,0),
            "weapons": {"garlic": 1},
            "passives": {},
            "weapon_state": {"garlic": {}},
        }
        self.enemies = []; self.projectiles = []; self.enemy_projectiles = []
        self.exp_orbs = []; self.damage_numbers = []; self.particles = []
        self.pulses = []; self.lightning_bolts = []; self.afterimages = []
        self.ground_effects = []; self.delayed_explosions = []; self.toasts = []
        self.decorations = gen_decorations(self.current_map)
        self.wave = 1; self.wave_timer = 0.0; self.wave_duration = 25
        self.enemy_spawn_timer = 0.0
        self.score = 0; self.kills = 0; self.elapsed = 0.0
        self.game_over = False; self.game_over_committed = False
        self.paused = False
        self.pending_levelups = 0
        self.level_up_cards = None; self.selected_card = 0
        self.boss_alive = False; self.next_boss_wave = 3
        self.coins_this_run = 0
        self.weapon_use_time = {"garlic": 0.0}
        self.combo = 0; self.combo_timer = 0.0; self.max_combo = 0
        self.evolutions_count = 0; self.total_damage = 0.0
        self.shop_tab = "upgrades"; self.meta_selection = 0
        self.shown_synergies_run = set()
        play_bgm(self.current_map)
G = Game()

def unlock_achievement(key):
    if key in META["achievements"]: return
    if key not in ACHIEVEMENTS: return
    META["achievements"].append(key)
    save_meta(META)
    a = ACHIEVEMENTS[key]
    G.toasts.append({"name":"成就 ★ " + a["name"], "desc":a["desc"],
                     "life":3.5,"max_life":3.5,"color":GOLD})
    play("achievement")

def active_synergies_set(p):
    out = []
    for sid, s in SYNERGIES.items():
        if s["weapon"] in p["weapons"] and p["passives"].get(s["passive"],0) >= s["passive_lv"]:
            out.append(sid)
    return out

def check_synergy_unlocks(p):
    cur = set(active_synergies_set(p))
    new = cur - G.shown_synergies_run
    for sid in new:
        G.shown_synergies_run.add(sid)
        s = SYNERGIES[sid]
        G.toasts.append({"name":"Synergy ★ " + s["name"], "desc":s["desc"],
                         "life":4.0,"max_life":4.0,"color":SYN_CYAN})
        play("synergy")
        if sid not in META["unlocked_synergies"]:
            META["unlocked_synergies"].append(sid); save_meta(META)
        unlock_achievement("first_synergy")

def can_evolve(p, wid):
    if wid not in EVOLUTIONS: return False
    if p["weapon_state"].get(wid,{}).get("evolved"): return False
    if p["weapons"].get(wid, 0) < 5: return False
    evo = EVOLUTIONS[wid]
    return p["passives"].get(evo["prereq"], 0) >= evo["prereq_lv"]

def weapon_available(wid):
    if wid in ("garlic","wand","whip","halo","knife"): return True
    if wid == "lightning": return META["slot_lv"] >= 1
    if wid in ("frost","poison"): return META["slot_lv"] >= 2
    return False

def queue_explosion(at_pos, radius=75, damage=12, color=(255,120,60), delay=0.30):
    """F3: 延迟爆炸 + 警告环"""
    G.delayed_explosions.append({"pos":at_pos.copy(), "radius":radius,
                                  "damage":damage, "color":color,
                                  "delay":delay, "max_delay":delay})

def can_add_particle():
    """F4: 后期性能 — 敌人 80+ 时粒子上限减半"""
    cap = MAX_PARTICLES if len(G.enemies) < 80 else MAX_PARTICLES // 2
    return len(G.particles) < cap

def can_add_damage_number():
    return len(G.damage_numbers) < MAX_DAMAGE_NUMBERS

def kill_enemy(e):
    if e.get("dead"): return
    e["dead"] = True
    map_exp_mult = MAPS[G.current_map]["exp_mult"]
    G.exp_orbs.append({"pos": e["pos"].copy(),
                       "value": max(1, int(e.get("exp",3) * map_exp_mult))})
    if random.random() < 0.20 and G.coins_this_run < COIN_CAP_PER_RUN:
        G.exp_orbs.append({
            "pos": e["pos"].copy() + pygame.Vector2(random.uniform(-15,15), random.uniform(-15,15)),
            "value": 0, "is_coin": True, "phase": random.random()*6.28})
    n_part = 8 if not e.get("is_boss") else 28
    if can_add_particle():
        for _ in range(n_part):
            ang = random.uniform(0,6.28); spd = random.uniform(1.2,4.5)
            G.particles.append({"type":"blood","pos":e["pos"].copy(),
                "vel": pygame.Vector2(math.cos(ang)*spd, math.sin(ang)*spd),
                "life":0.5,"max_life":0.5,
                "color": e.get("blood_color", DARK_RED),
                "size": random.uniform(2,4)})
    G.score += e.get("score",10); G.kills += 1
    G.combo += 1; G.combo_timer = 0
    if G.combo > G.max_combo: G.max_combo = G.combo
    if G.kills == 1: unlock_achievement("first_kill")
    if G.kills == 100: unlock_achievement("100_kills")
    if e.get("is_boss"):
        unlock_achievement("boss_slain")
        G.boss_alive = False
        for _ in range(8):
            off = pygame.Vector2(random.uniform(-40,40), random.uniform(-40,40))
            G.exp_orbs.append({"pos": e["pos"].copy()+off, "value":6})
        for _ in range(5):
            if G.coins_this_run >= COIN_CAP_PER_RUN: break
            off = pygame.Vector2(random.uniform(-30,30), random.uniform(-30,30))
            G.exp_orbs.append({"pos":e["pos"].copy()+off,"value":0,
                               "is_coin":True,"phase":random.random()*6.28})
    if e.get("type") == "kamikaze" and not e.get("queued_explosion"):
        e["queued_explosion"] = True
        queue_explosion(e["pos"], radius=75, damage=12, color=(255,120,60))

def deal_damage(e, dmg, src_pos):
    if e.get("dead") or e["hp"] <= 0: return False
    e["hp"] -= dmg
    G.total_damage += dmg
    kb = e["pos"] - src_pos
    if kb.length() > 0:
        kb.normalize_ip()
        e["pos"] += kb * (5 if not e.get("is_boss") else 1.5)
    if can_add_damage_number():
        G.damage_numbers.append({
            "pos": pygame.Vector2(e["pos"].x + random.uniform(-8,8), e["pos"].y - e["radius"]),
            "value": int(dmg), "life": 0.7, "max_life": 0.7,
            "color": YELLOW if dmg < 18 else (ORANGE if dmg < 40 else (255,80,60))})
    if e["hp"] <= 0:
        kill_enemy(e)
        return True
    return False

def spawn_enemy(boss=False):
    side = random.choice(["top","bottom","left","right"])
    if side == "top":    pos = pygame.Vector2(random.randint(0,WIDTH), -40)
    elif side == "bottom": pos = pygame.Vector2(random.randint(0,WIDTH), HEIGHT+40)
    elif side == "left": pos = pygame.Vector2(-40, random.randint(0,HEIGHT))
    else:                pos = pygame.Vector2(WIDTH+40, random.randint(0,HEIGHT))
    if boss:
        hp = 180 + G.wave*70
        G.enemies.append({"pos":pos,"speed":1.3,"hp":hp,"max_hp":hp,
            "radius":38,"color":(170,40,200),"damage":1.5,
            "exp":25,"score":250,"is_boss":True,"type":"boss",
            "blood_color":(220,80,220)})
        G.boss_alive = True
        play("boss_spawn")
        return
    r = random.random()
    if G.wave >= 5 and r < 0.10:
        hp = 8 + G.wave*1.5
        G.enemies.append({"pos":pos,"speed":2.4+G.wave*0.07,"hp":hp,"max_hp":hp,
            "radius":16,"color":(255,200,80),"damage":0,
            "exp":7,"score":18,"type":"kamikaze","blood_color":(255,120,60)})
    elif G.wave >= 5 and r < 0.25:
        hp = 14 + G.wave*2.5
        G.enemies.append({"pos":pos,"speed":1.7+G.wave*0.05,"hp":hp,"max_hp":hp,
            "radius":14,"color":(120,80,160),"damage":0.6,
            "exp":6,"score":15,"type":"bat",
            "shoot_range":300,"shoot_cd":1.5,"shoot_timer":random.uniform(0,1.5),
            "preferred_dist":220,"blood_color":(120,80,160)})
    elif G.wave >= 3 and r < 0.40:
        hp = 7 + G.wave*2
        G.enemies.append({"pos":pos,"speed":2.9+G.wave*0.08,"hp":hp,"max_hp":hp,
            "radius":12,"color":(255,130,130),"damage":0.5,
            "exp":3,"score":12,"type":"fast","blood_color":DARK_RED})
    elif G.wave >= 4 and r < 0.55:
        hp = 38 + G.wave*7
        G.enemies.append({"pos":pos,"speed":1.05+G.wave*0.04,"hp":hp,"max_hp":hp,
            "radius":26,"color":(140,55,55),"damage":1.3,
            "exp":9,"score":28,"type":"tank","blood_color":(110,35,35)})
    else:
        hp = 11 + G.wave*3
        G.enemies.append({"pos":pos,"speed":1.5+G.wave*0.10,"hp":hp,"max_hp":hp,
            "radius":17,"color":RED,"damage":0.8,
            "exp":4,"score":10,"type":"normal","blood_color":DARK_RED})

def upd_garlic(p, lv, dt, st):
    evolved = st.get("evolved", False)
    vital = p["passives"].get("regen", 0) >= 3
    st["timer"] = st.get("timer", 0) + dt
    if evolved:
        dmg = (18 + (lv-5)*6) * p["damage_mult"]
        rng = (170 + (lv-5)*25) * p["area_mult"]
        cd  = max(0.10, 0.30 - (lv-5)*0.04) * p["cooldown_mult"]
    else:
        dmg = (5 + lv*3) * p["damage_mult"]
        rng = (88 + lv*18) * p["area_mult"]
        cd  = max(0.18, 0.55 - lv*0.05) * p["cooldown_mult"]
    if st["timer"] >= cd:
        st["timer"] = 0
        hit = False
        for e in G.enemies:
            if e.get("dead"): continue
            dx = e["pos"].x - p["pos"].x; dy = e["pos"].y - p["pos"].y
            R = rng + e["radius"]
            if dx*dx + dy*dy < R*R:
                killed = deal_damage(e, dmg, p["pos"])
                hit = True
                if killed and evolved:
                    if p["hp"] < p["max_hp"]:
                        p["hp"] = min(p["max_hp"], p["hp"] + 2)
                    for e2 in G.enemies:
                        if e2 is e or e2.get("dead"): continue
                        ex = e2["pos"].x - e["pos"].x; ey = e2["pos"].y - e["pos"].y
                        if ex*ex + ey*ey < 90*90:
                            deal_damage(e2, dmg*0.5, e["pos"])
        if hit:
            if vital and p["hp"] < p["max_hp"]:
                p["hp"] = min(p["max_hp"], p["hp"] + 1)
            color = (255,120,220) if evolved else (220,220,150)
            G.pulses.append({"pos":p["pos"].copy(),"max_r":rng,"r":0,
                             "life":0.22,"max_life":0.22,"color":color})

def upd_wand(p, lv, dt, st):
    st["timer"] = st.get("timer", 0) + dt
    cd = max(0.32, 1.0 - lv*0.08) * p["cooldown_mult"]
    explosive = p["passives"].get("area", 0) >= 3
    if st["timer"] >= cd:
        alive = [e for e in G.enemies if not e.get("dead")]
        if not alive: return
        st["timer"] = 0
        n = 1 + (lv-1)//2 + p["projectiles_bonus"]
        targets = sorted(alive, key=lambda e: (e["pos"]-p["pos"]).length_squared())[:n]
        for t in targets:
            d = t["pos"] - p["pos"]
            d = d.normalize() if d.length() > 0 else pygame.Vector2(1,0)
            G.projectiles.append({"pos":p["pos"].copy(),"vel":d*9,
                "damage":(10+lv*4)*p["damage_mult"],"radius":7,
                "color":(185,130,255) if not explosive else (255,150,200),
                "life":2.0,"homing":True,"target":t,
                "pierce":0,"type":"wand","hit_set":set(),
                "explosive": explosive,
                "explode_dmg": (10+lv*4)*p["damage_mult"]*0.5,
                "explode_r": 65 * p["area_mult"]})

def upd_whip(p, lv, dt, st):
    st["timer"] = st.get("timer", 0) + dt
    cd = max(0.55, 1.3 - lv*0.09) * p["cooldown_mult"]
    giant = p["passives"].get("max_hp", 0) >= 3
    if st["timer"] >= cd:
        st["timer"] = 0
        n = 1 + (lv-1)//2
        f = p["facing"] if p["facing"].length() > 0 else pygame.Vector2(1,0)
        sd = pygame.Vector2(1,0) if f.x >= 0 else pygame.Vector2(-1,0)
        length_mult = 1.4 if giant else 1.0
        dmg_mult = 1.5 if giant else 1.0
        width = 40 if giant else 20
        for i in range(n):
            d = sd if i%2 == 0 else -sd
            G.particles.append({"type":"whip","pos":p["pos"].copy(),"dir":d,
                "length":(115+lv*18)*p["area_mult"]*length_mult,
                "damage":(12+lv*5)*p["damage_mult"]*dmg_mult,
                "width": width,
                "life":0.18,"max_life":0.18,
                "color":(255,150,140) if giant else (220,110,110),
                "hit_set":set()})

def upd_halo(p, lv, dt, st):
    evolved = st.get("evolved", False)
    perpetual = p["passives"].get("cooldown", 0) >= 3
    if evolved:
        needed = 6 + (lv-5)*2 + p["projectiles_bonus"]
        radius = (95 + (lv-5)*12) * p["area_mult"]
        rot = 5.5; dmg = (8 + (lv-5)*3) * p["damage_mult"]
        hit_cd = 0.15; burn = 6 * p["damage_mult"]; burn_dur = 2.0
    else:
        needed = 2 + (lv-1)//2 + p["projectiles_bonus"]
        radius = (74 + lv*10) * p["area_mult"]
        rot = 2.6; dmg = (4 + lv*2) * p["damage_mult"]
        hit_cd = 0.22; burn = 0; burn_dur = 0
    if perpetual: hit_cd *= 0.5
    orbs = st.setdefault("orbs", [])
    st["angle"] = st.get("angle",0) + dt*rot
    while len(orbs) < needed: orbs.append({})
    while len(orbs) > needed: orbs.pop()
    st["dmg_timer"] = st.get("dmg_timer",0) + dt
    can = st["dmg_timer"] >= hit_cd
    if can: st["dmg_timer"] = 0
    for i, orb in enumerate(orbs):
        ang = st["angle"] + (6.2832/needed)*i
        orb["pos"] = p["pos"] + pygame.Vector2(math.cos(ang), math.sin(ang)) * radius
        orb["evolved"] = evolved
        if can:
            for e in G.enemies:
                if e.get("dead"): continue
                dx = e["pos"].x - orb["pos"].x; dy = e["pos"].y - orb["pos"].y
                R = e["radius"] + 14
                if dx*dx + dy*dy < R*R:
                    deal_damage(e, dmg, orb["pos"])
                    if evolved and not e.get("dead"):
                        e["burn_dot"] = max(e.get("burn_dot",0), burn)
                        e["burn_dur"] = max(e.get("burn_dur",0), burn_dur)

def upd_knife(p, lv, dt, st):
    evolved = st.get("evolved", False)
    homing_syn = p["passives"].get("magnet", 0) >= 3
    st["timer"] = st.get("timer", 0) + dt
    if evolved:
        cd = max(0.10, 0.30 - (lv-5)*0.03) * p["cooldown_mult"]
        n = 8 + (lv-5)*2 + p["projectiles_bonus"]
        dmg = (10 + (lv-5)*4) * p["damage_mult"]
        pierce = 3 + (lv-5)
    else:
        cd = max(0.18, 0.5 - lv*0.04) * p["cooldown_mult"]
        n = 1 + (lv-1)//2 + p["projectiles_bonus"]
        dmg = (6 + lv*3) * p["damage_mult"]
        pierce = 1 + lv//3
    if st["timer"] >= cd:
        st["timer"] = 0
        if evolved:
            base_ang = st.get("rot_phase", 0)
            for i in range(n):
                ang = base_ang + (6.2832/n)*i
                d = pygame.Vector2(math.cos(ang), math.sin(ang))
                G.projectiles.append({"pos":p["pos"].copy(),"vel":d*14,
                    "damage":dmg,"radius":6,"color":(200,240,255),
                    "life":1.1,"homing":False,"pierce":pierce,
                    "type":"knife_evo","hit_set":set(),"trail":True,
                    "homing_weak": homing_syn})
            st["rot_phase"] = base_ang + 0.4
        else:
            f = p["facing"] if p["facing"].length() > 0 else pygame.Vector2(1,0)
            for i in range(n):
                sp = (i - (n-1)/2) * 0.20
                cs, sn = math.cos(sp), math.sin(sp)
                d = pygame.Vector2(f.x*cs - f.y*sn, f.x*sn + f.y*cs)
                G.projectiles.append({"pos":p["pos"].copy(),"vel":d*13,
                    "damage":dmg,"radius":5,"color":(220,230,240),
                    "life":0.85,"homing":False,"pierce":pierce,
                    "type":"knife","hit_set":set(),
                    "homing_weak": homing_syn})

def gen_lightning_segments(a, b):
    segs = []
    cur = pygame.Vector2(a.x, a.y); end = pygame.Vector2(b.x, b.y)
    diff = end - cur
    if diff.length() == 0: return [(a.x,a.y,b.x,b.y)]
    perp = pygame.Vector2(-diff.y, diff.x).normalize()
    n = 6
    for i in range(1, n):
        t = i/n
        mid = pygame.Vector2(cur.x + diff.x*t, cur.y + diff.y*t) + perp * random.uniform(-12, 12)
        segs.append((cur.x, cur.y, mid.x, mid.y))
        cur = mid
    segs.append((cur.x, cur.y, end.x, end.y))
    return segs

def upd_lightning(p, lv, dt, st):
    chain = p["passives"].get("speed", 0) >= 3
    st["timer"] = st.get("timer", 0) + dt
    cd = max(0.6, 1.6 - lv*0.15) * p["cooldown_mult"]
    if st["timer"] >= cd:
        alive = [e for e in G.enemies if not e.get("dead")]
        if not alive: return
        st["timer"] = 0
        n = 1 + (lv-1)//2 + p["projectiles_bonus"]
        rng_sq = (400*p["area_mult"])**2
        in_range = [e for e in alive if (e["pos"]-p["pos"]).length_squared() < rng_sq] or alive
        for _ in range(n):
            t = random.choice(in_range)
            dmg = (16 + lv*6) * p["damage_mult"]
            deal_damage(t, dmg, p["pos"])
            G.lightning_bolts.append({
                "start": p["pos"].copy(), "end": t["pos"].copy(),
                "life":0.18,"max_life":0.18,
                "segments": gen_lightning_segments(p["pos"], t["pos"])})
            if chain:
                cur = t; used = {id(t)}
                for _step in range(2):
                    cands = [e for e in alive if not e.get("dead") and id(e) not in used]
                    if not cands: break
                    cands.sort(key=lambda e: (e["pos"]-cur["pos"]).length_squared())
                    nxt = cands[0]
                    if (nxt["pos"]-cur["pos"]).length() > 280: break
                    deal_damage(nxt, dmg*0.6, cur["pos"])
                    G.lightning_bolts.append({
                        "start": cur["pos"].copy(), "end": nxt["pos"].copy(),
                        "life":0.14,"max_life":0.14,
                        "segments": gen_lightning_segments(cur["pos"], nxt["pos"])})
                    used.add(id(nxt))
                    cur = nxt

def upd_frost(p, lv, dt, st):
    evolved = st.get("evolved", False)
    st["timer"] = st.get("timer", 0) + dt
    if evolved:
        cd = max(0.5, 1.2 - (lv-5)*0.1) * p["cooldown_mult"]
        n = 3 + (lv-5)*2 + p["projectiles_bonus"]
        r_base = 90 + (lv-5)*15
        dmg = (4 + (lv-5)*2) * p["damage_mult"]
        slow_dur = 1.5; slow_fac = 0.3; life = 3.0
        col = (120,200,255)
    else:
        cd = max(1.0, 2.5 - lv*0.2) * p["cooldown_mult"]
        n = 1 + (lv-1)//2 + p["projectiles_bonus"]
        r_base = 50 + lv*8
        dmg = (2 + lv*1.2) * p["damage_mult"]
        slow_dur = 1.0; slow_fac = 0.5; life = 2.0
        col = FROST_C
    if st["timer"] >= cd:
        st["timer"] = 0
        for _ in range(n):
            ang = random.uniform(0, 6.28); dist = random.uniform(50, 220)
            pos = p["pos"] + pygame.Vector2(math.cos(ang)*dist, math.sin(ang)*dist)
            G.ground_effects.append({
                "type":"frost", "pos":pos,
                "radius": r_base * p["area_mult"],
                "damage": dmg, "tick": 0, "tick_cd": 0.3,
                "life": life, "max_life": life,
                "slow_dur": slow_dur, "slow_fac": slow_fac,
                "color": col})
        play("freeze")

def upd_poison(p, lv, dt, st):
    evolved = st.get("evolved", False)
    st["timer"] = st.get("timer", 0) + dt
    if evolved:
        cd = max(0.8, 2.0 - (lv-5)*0.2) * p["cooldown_mult"]
        n = 3 + (lv-5)*2 + p["projectiles_bonus"]
        r_base = 80 + (lv-5)*12
        dmg = (8 + (lv-5)*4) * p["damage_mult"]
        life = 6.0; col = (60,255,60)
    else:
        cd = max(1.5, 3.5 - lv*0.3) * p["cooldown_mult"]
        n = 1 + (lv-1)//2 + p["projectiles_bonus"]
        r_base = 45 + lv*7
        dmg = (3 + lv*2) * p["damage_mult"]
        life = 4.0; col = POISON_C
    if st["timer"] >= cd:
        st["timer"] = 0
        for _ in range(n):
            ang = random.uniform(0, 6.28); dist = random.uniform(40, 180)
            pos = p["pos"] + pygame.Vector2(math.cos(ang)*dist, math.sin(ang)*dist)
            G.ground_effects.append({
                "type":"poison", "pos":pos,
                "radius": r_base * p["area_mult"],
                "damage": dmg, "tick": 0, "tick_cd": 0.4,
                "life": life, "max_life": life,
                "color": col})
        play("poison")

WEAPON_UPDATES = {
    "garlic": upd_garlic, "wand": upd_wand, "whip": upd_whip,
    "halo": upd_halo, "knife": upd_knife, "lightning": upd_lightning,
    "frost": upd_frost, "poison": upd_poison,
}

def generate_cards(p):
    new_cards = []
    if len(p["weapons"]) < meta_max_weapons():
        for wid, w in WEAPONS.items():
            if wid in p["weapons"]: continue
            if not weapon_available(wid): continue
            new_cards.append(("new_weapon", wid, w["name"], w["desc"], w["color"]))
    evo_cards = []
    for wid in list(p["weapons"].keys()):
        if can_evolve(p, wid):
            evo = EVOLUTIONS[wid]
            evo_cards.append(("evolve", wid, "★ "+evo["name"]+" ★", evo["desc"], evo["color"]))
    upg_cards = []
    for wid, lv in p["weapons"].items():
        evolved = p["weapon_state"].get(wid, {}).get("evolved", False)
        max_lv = 7 if evolved else 5
        if lv >= max_lv: continue
        if not evolved and can_evolve(p, wid): continue
        if evolved:
            name = f"{EVOLUTIONS[wid]['name']} Lv{lv+1}"
            color = EVOLUTIONS[wid]["color"]; desc = "进化武器继续成长"
        else:
            name = f"{WEAPONS[wid]['name']} Lv{lv+1}"
            color = WEAPONS[wid]["color"]; desc = "强化已拥有武器"
        upg_cards.append(("upgrade_weapon", wid, name, desc, color))
    pas_cards = []
    for pid, pdef in PASSIVES.items():
        cur = p["passives"].get(pid, 0)
        if cur < pdef["max_level"]:
            pas_cards.append(("passive", pid, f"{pdef['name']} Lv{cur+1}",
                              pdef["desc"], pdef["color"]))
    others = new_cards + upg_cards + pas_cards
    cards = []
    if evo_cards and random.random() < 0.80:
        cards.append(random.choice(evo_cards))
    take = min(3 - len(cards), len(others))
    if take > 0:
        cards += random.sample(others, take)
    return cards

def apply_card(card):
    kind, key, *_ = card
    p = G.player
    if kind == "new_weapon":
        p["weapons"][key] = 1
        p["weapon_state"][key] = {}
        G.weapon_use_time.setdefault(key, 0.0)
        if key not in META["unlocked_weapons"]:
            META["unlocked_weapons"].append(key); save_meta(META)
        play("levelup")
    elif kind == "upgrade_weapon":
        p["weapons"][key] += 1
        play("levelup")
    elif kind == "evolve":
        p["weapon_state"][key]["evolved"] = True
        p["weapons"][key] += 1
        G.evolutions_count += 1
        if key not in META["unlocked_evolutions"]:
            META["unlocked_evolutions"].append(key); save_meta(META)
        unlock_achievement("first_evolution")
        if len(META["unlocked_evolutions"]) >= len(EVOLUTIONS):
            unlock_achievement("all_evolutions")
        play("evolve")
        if can_add_particle():
            for _ in range(40):
                ang = random.uniform(0, 6.28); spd = random.uniform(2, 9)
                G.particles.append({"type":"blood","pos":p["pos"].copy(),
                    "vel": pygame.Vector2(math.cos(ang)*spd, math.sin(ang)*spd),
                    "life":1.5,"max_life":1.5,
                    "color": EVOLUTIONS[key]["color"], "size":random.uniform(4,7)})
        G.pulses.append({"pos":p["pos"].copy(),"max_r":260,"r":0,
                         "life":0.6,"max_life":0.6,"color":EVO_GOLD})
    elif kind == "passive":
        p["passives"][key] = p["passives"].get(key, 0) + 1
        recompute_passives()
        play("levelup")
    check_synergy_unlocks(p)

def recompute_passives():
    p = G.player
    base_speed = 4.0 + meta_speed_bonus()
    base_max_hp = 100 + meta_hp_bonus()
    p["damage_mult"] = 1.0; p["cooldown_mult"] = 1.0
    p["pickup_range"] = 75; p["projectiles_bonus"] = 0
    p["area_mult"] = 1.0; p["hp_regen"] = 0.0
    bonus_hp = 0
    for pid, lv in p["passives"].items():
        if pid == "max_hp":     bonus_hp += 20*lv
        elif pid == "speed":    base_speed *= (1 + 0.10*lv)
        elif pid == "damage":   p["damage_mult"] *= (1 + 0.15*lv)
        elif pid == "cooldown": p["cooldown_mult"] *= (1 - 0.08*lv)
        elif pid == "magnet":   p["pickup_range"] *= (1 + 0.30*lv)
        elif pid == "regen":    p["hp_regen"] += 0.5*lv
        elif pid == "area":     p["area_mult"] *= (1 + 0.10*lv)
    p["speed"] = base_speed
    new_max = base_max_hp + bonus_hp
    if new_max > p["max_hp"]:
        p["hp"] += (new_max - p["max_hp"])
    p["max_hp"] = new_max

def draw_bg():
    mapdef = MAPS[G.current_map]
    screen.fill(mapdef["bg"])
    grid_col = mapdef["grid"]
    for x in range(0, WIDTH, 60):
        pygame.draw.line(screen, grid_col, (x,0), (x,HEIGHT))
    for y in range(0, HEIGHT, 60):
        pygame.draw.line(screen, grid_col, (0,y), (WIDTH,y))
    for d in G.decorations:
        x, y = int(d["pos"].x), int(d["pos"].y); k = d["kind"]
        if k == "grass":
            for ox in (-3,0,3): pygame.draw.line(screen, GRASS, (x+ox,y+4), (x+ox,y-4), 2)
        elif k == "stone":
            pygame.draw.rect(screen, GRAVESTONE, (x-7,y-12,14,18), border_radius=4)
            pygame.draw.rect(screen, (35,35,40), (x-7,y-12,14,18), 1, border_radius=4)
        elif k == "cross":
            pygame.draw.rect(screen, GRAVESTONE, (x-2,y-12,4,22))
            pygame.draw.rect(screen, GRAVESTONE, (x-9,y-6,18,4))
        elif k == "cactus":
            pygame.draw.rect(screen, (60,95,45), (x-3,y-14,6,18))
            pygame.draw.rect(screen, (60,95,45), (x-8,y-7,5,3))
            pygame.draw.rect(screen, (60,95,45), (x+3,y-10,5,3))
        elif k == "skull":
            pygame.draw.circle(screen, (210,200,170), (x,y), 7)
            pygame.draw.circle(screen, BLACK, (x-2,y-1), 2)
            pygame.draw.circle(screen, BLACK, (x+2,y-1), 2)
            pygame.draw.line(screen, BLACK, (x-2,y+4), (x+2,y+4), 1)
        elif k == "bone":
            pygame.draw.line(screen, (220,210,180), (x-5,y), (x+5,y), 3)
            pygame.draw.circle(screen, (220,210,180), (x-6,y), 3)
            pygame.draw.circle(screen, (220,210,180), (x+6,y), 3)

def draw_player(p):
    if int(p["iframes"]*20) % 2 == 1:
        pygame.draw.circle(screen, (180,200,255), p["pos"], p["radius"])
    else:
        pygame.draw.circle(screen, BLUE, p["pos"], p["radius"])
    pygame.draw.circle(screen, WHITE, p["pos"], p["radius"], 3)
    if p["facing"].length() > 0:
        tip = p["pos"] + p["facing"] * (p["radius"]+6)
        pygame.draw.circle(screen, YELLOW, tip, 4)

def draw_enemies():
    for e in G.enemies:
        if e.get("dead"): continue
        col = e["color"]
        if e.get("slow_dur", 0) > 0:
            col = tuple(min(255, c + 40) for c in col[:3])
        pygame.draw.circle(screen, col, e["pos"], e["radius"])
        if e.get("type") == "bat":
            pygame.draw.polygon(screen, col, [
                (e["pos"].x - e["radius"]*1.5, e["pos"].y),
                (e["pos"].x - e["radius"]*0.5, e["pos"].y - e["radius"]*0.7),
                (e["pos"].x - e["radius"]*0.5, e["pos"].y + e["radius"]*0.4)])
            pygame.draw.polygon(screen, col, [
                (e["pos"].x + e["radius"]*1.5, e["pos"].y),
                (e["pos"].x + e["radius"]*0.5, e["pos"].y - e["radius"]*0.7),
                (e["pos"].x + e["radius"]*0.5, e["pos"].y + e["radius"]*0.4)])
        elif e.get("type") == "kamikaze":
            if (pygame.time.get_ticks() // 100) % 2:
                pygame.draw.circle(screen, (255,80,40), e["pos"], e["radius"]+3, 2)
        pygame.draw.circle(screen, BLACK, e["pos"], e["radius"], 2)
        if e.get("burn_dur", 0) > 0:
            pygame.draw.circle(screen, (255,100,30), e["pos"], e["radius"]+5, 2)
        if e.get("slow_dur", 0) > 0:
            pygame.draw.circle(screen, FROST_C, e["pos"], e["radius"]+3, 1)
        if e["hp"] < e["max_hp"]:
            bw = int(e["radius"]*2); pct = max(0, e["hp"]/e["max_hp"])
            bx = e["pos"].x - bw//2; by = e["pos"].y - e["radius"] - 10
            pygame.draw.rect(screen, (60,60,60), (bx,by,bw,5))
            col2 = GREEN if pct > 0.5 else (ORANGE if pct > 0.25 else RED)
            pygame.draw.rect(screen, col2, (bx,by,int(bw*pct),5))
        if e.get("is_boss"):
            lab = font_s.render("BOSS", True, GOLD)
            screen.blit(lab, (e["pos"].x - lab.get_width()//2, e["pos"].y - e["radius"] - 30))

def draw_ground_effects():
    for z in G.ground_effects:
        ap = z["life"] / z["max_life"]
        r = int(z["radius"])
        if r <= 0: continue
        s = pygame.Surface((r*2+4, r*2+4), pygame.SRCALPHA)
        pygame.draw.circle(s, (*z["color"], int(60*ap)), (r+2, r+2), r)
        pygame.draw.circle(s, (*z["color"], int(180*ap)), (r+2, r+2), r, 3)
        screen.blit(s, (z["pos"].x - r - 2, z["pos"].y - r - 2))

def draw_warnings():
    for ex in G.delayed_explosions:
        prog = 1.0 - (ex["delay"] / ex["max_delay"])
        pulse = 0.5 + 0.5*math.sin(prog * 25)
        r = int(ex["radius"] * (0.3 + 0.7*prog))
        if r <= 0: continue
        col = (255, int(70 + 120*pulse), 0)
        pygame.draw.circle(screen, col, ex["pos"], r, 3)
        pygame.draw.circle(screen, col, ex["pos"], max(1, r-2), 1)

def draw_projectiles():
    for ai in G.afterimages:
        alpha = max(0, int(160 * ai["life"]/ai["max_life"]))
        s = pygame.Surface((ai["radius"]*2+4, ai["radius"]*2+4), pygame.SRCALPHA)
        pygame.draw.circle(s, (*ai["color"], alpha), (ai["radius"]+2, ai["radius"]+2), ai["radius"])
        screen.blit(s, (ai["pos"].x - ai["radius"] - 2, ai["pos"].y - ai["radius"] - 2))
    for proj in G.projectiles:
        pygame.draw.circle(screen, proj["color"], proj["pos"], proj["radius"])
        pygame.draw.circle(screen, WHITE, proj["pos"], proj["radius"], 1)
    for ep in G.enemy_projectiles:
        pygame.draw.circle(screen, ep["color"], ep["pos"], ep["radius"])
        pygame.draw.circle(screen, BLACK, ep["pos"], ep["radius"], 1)

def draw_orbs():
    for orb in G.exp_orbs:
        if orb.get("is_coin"):
            ph = orb.get("phase", 0); flash = abs(math.sin(ph))
            col = (255, int(180 + 60*flash), int(40*flash))
            pygame.draw.circle(screen, col, orb["pos"], 9)
            pygame.draw.circle(screen, (255,240,160), orb["pos"], 5)
            pygame.draw.circle(screen, BLACK, orb["pos"], 9, 1)
        else:
            pygame.draw.circle(screen, YELLOW, orb["pos"], 7)
            pygame.draw.circle(screen, WHITE, orb["pos"], 7, 1)

def draw_damage_numbers():
    for d in G.damage_numbers:
        alpha = max(0, min(255, int(255*(d["life"]/d["max_life"]))))
        txt = font_s.render(str(d["value"]), True, d["color"])
        txt.set_alpha(alpha)
        screen.blit(txt, (d["pos"].x - txt.get_width()//2, d["pos"].y))

def draw_particles():
    for pt in G.particles:
        if pt.get("type") == "whip":
            lp = pt["life"]/pt["max_life"]
            length = pt["length"] * (1 - (1-lp)*0.15)
            start = pt["pos"]; end = start + pt["dir"] * length
            w = max(2, int((pt.get("width", 20)) * lp * 1.1))
            pygame.draw.line(screen, pt["color"], start, end, w)
        else:
            sz = max(1, pt["size"] * (pt["life"]/pt["max_life"]))
            pygame.draw.circle(screen, pt["color"], pt["pos"], sz)

def draw_pulses():
    for ps in G.pulses:
        ap = ps["life"]/ps["max_life"]
        col = ps.get("color", (220,220,150)); mr = int(ps["max_r"])
        if mr <= 0: continue
        s = pygame.Surface((mr*2+4, mr*2+4), pygame.SRCALPHA)
        pygame.draw.circle(s, (*col, int(90*ap)), (mr+2, mr+2), int(ps["r"]), 6)
        screen.blit(s, (ps["pos"].x - mr - 2, ps["pos"].y - mr - 2))

def draw_lightning():
    for lb in G.lightning_bolts:
        lp = lb["life"]/lb["max_life"]
        col = (200, 230, 255) if lp > 0.5 else (140, 170, 220)
        w = max(1, int(4 * lp))
        for (x1,y1,x2,y2) in lb["segments"]:
            pygame.draw.line(screen, col, (x1,y1), (x2,y2), w)

def draw_halo_orbs():
    st = G.player["weapon_state"].get("halo")
    if not st: return
    orbs = st.get("orbs", [])
    evolved = orbs[0].get("evolved", False) if orbs else False
    for orb in orbs:
        if "pos" in orb:
            if evolved:
                pygame.draw.circle(screen, (255,80,0), orb["pos"], 16)
                pygame.draw.circle(screen, (255,160,40), orb["pos"], 11)
                pygame.draw.circle(screen, (255,240,180), orb["pos"], 5)
            else:
                pygame.draw.circle(screen, (255,200,80), orb["pos"], 13)
                pygame.draw.circle(screen, (255,140,50), orb["pos"], 10)
                pygame.draw.circle(screen, (255,240,200), orb["pos"], 4)

def draw_ui():
    p = G.player
    pygame.draw.rect(screen, DARK_GRAY, (20,20,260,22))
    pct = max(0, p["hp"]/p["max_hp"])
    pygame.draw.rect(screen, RED, (20,20,int(260*pct),22))
    pygame.draw.rect(screen, WHITE, (20,20,260,22), 2)
    hp_t = font_m.render(f"{int(p['hp'])}/{int(p['max_hp'])}", True, WHITE)
    screen.blit(hp_t, (150 - hp_t.get_width()//2, 22))
    bar_w = 700; bx = WIDTH//2 - bar_w//2
    pygame.draw.rect(screen, DARK_GRAY, (bx,14,bar_w,14))
    ep = p["exp"]/p["exp_to_next"] if p["exp_to_next"]>0 else 0
    pygame.draw.rect(screen, YELLOW, (bx,14,int(bar_w*ep),14))
    pygame.draw.rect(screen, WHITE, (bx,14,bar_w,14), 1)
    lv = font_l.render(f"LV.{p['level']}", True, YELLOW)
    screen.blit(lv, (WIDTH//2 - lv.get_width()//2, 32))
    mins = int(G.elapsed//60); secs = int(G.elapsed%60)
    info = [
        f"地图 {MAPS[G.current_map]['name']}",
        f"波次 Wave {G.wave}", f"得分 {G.score}", f"击杀 {G.kills}",
        f"连杀 {G.combo}（最高 {G.max_combo}）",
        f"金币 {G.coins_this_run}/{COIN_CAP_PER_RUN}", f"时间 {mins:02d}:{secs:02d}",
    ]
    for i, line in enumerate(info):
        t = font_m.render(line, True, GOLD if i == 5 else WHITE)
        screen.blit(t, (WIDTH - 20 - t.get_width(), 20 + i*24))
    syns_active = active_synergies_set(p)
    syns_by_w = {}
    for sid in syns_active:
        syns_by_w.setdefault(SYNERGIES[sid]["weapon"], []).append(sid)
    x0 = 20; y0 = HEIGHT - 56; i = 0
    for wid, lv in p["weapons"].items():
        evolved = p["weapon_state"].get(wid,{}).get("evolved", False)
        col = EVOLUTIONS[wid]["color"] if evolved else WEAPONS[wid]["color"]
        if evolved:
            pygame.draw.rect(screen, GOLD, (x0+i*46-3, y0-3, 46, 46), border_radius=8)
        pygame.draw.rect(screen, col, (x0+i*46, y0, 40, 40), border_radius=6)
        pygame.draw.rect(screen, WHITE, (x0+i*46, y0, 40, 40), 2, border_radius=6)
        ch = (EVOLUTIONS[wid]["name"] if evolved else WEAPONS[wid]["name"])[:1]
        nt = font_m.render(ch, True, BLACK)
        screen.blit(nt, (x0+i*46+20 - nt.get_width()//2, y0+20 - nt.get_height()//2))
        lvt = font_xs.render(str(lv), True, BLACK)
        screen.blit(lvt, (x0+i*46+30, y0+26))
        if wid in syns_by_w:
            pygame.draw.circle(screen, SYN_CYAN, (x0+i*46+20, y0+44), 4)
        i += 1
    for pid, lv in p["passives"].items():
        col = PASSIVES[pid]["color"]
        pygame.draw.rect(screen, col, (x0+i*46, y0, 40, 40), border_radius=6)
        pygame.draw.rect(screen, WHITE, (x0+i*46, y0, 40, 40), 2, border_radius=6)
        nt = font_m.render(PASSIVES[pid]["name"][:1], True, BLACK)
        screen.blit(nt, (x0+i*46+20 - nt.get_width()//2, y0+20 - nt.get_height()//2))
        lvt = font_xs.render(str(lv), True, BLACK)
        screen.blit(lvt, (x0+i*46+30, y0+26))
        i += 1
    hint = font_xs.render("WASD/方向键 移动   P 暂停   升级时 ←→选卡 Enter 确认", True, GRAY)
    screen.blit(hint, (WIDTH//2 - hint.get_width()//2, HEIGHT - 22))

def wrap_text(text, fnt, color, x, y, maxw):
    line = ""; cy = y
    for ch in text:
        test = line + ch
        if fnt.size(test)[0] > maxw and line:
            screen.blit(fnt.render(line, True, color), (x, cy))
            cy += fnt.get_linesize(); line = ch
        else: line = test
    if line: screen.blit(fnt.render(line, True, color), (x, cy))

def draw_levelup():
    overlay = pygame.Surface((WIDTH, HEIGHT), pygame.SRCALPHA)
    overlay.fill((0,0,0,190)); screen.blit(overlay, (0,0))
    title = font_xxl.render("升级！", True, GOLD)
    screen.blit(title, (WIDTH//2 - title.get_width()//2, 70))
    sub = font_m.render(f"LV.{G.player['level']}    剩余升级 {G.pending_levelups}", True, WHITE)
    screen.blit(sub, (WIDTH//2 - sub.get_width()//2, 145))
    hint = font_m.render("← → 选择    Enter / Space 确认", True, GRAY)
    screen.blit(hint, (WIDTH//2 - hint.get_width()//2, 175))
    cards = G.level_up_cards or []
    cw, ch = 270, 360; sp = 30
    total = len(cards)*cw + max(0,len(cards)-1)*sp
    sx = WIDTH//2 - total//2
    for i, card in enumerate(cards):
        kind, key, name, desc, color = card
        x = sx + i*(cw+sp); y = HEIGHT//2 - ch//2 + 40
        bg = CARD_HL if i == G.selected_card else CARD_BG
        pygame.draw.rect(screen, bg, (x,y,cw,ch), border_radius=14)
        if kind == "evolve":
            tk = pygame.time.get_ticks() / 200
            glow = int(30 + 25*math.sin(tk))
            pygame.draw.rect(screen, (255, 200+min(55,glow), 80),
                             (x-4,y-4,cw+8,ch+8), 4, border_radius=16)
        outline = GOLD if i == G.selected_card else GRAY
        pygame.draw.rect(screen, outline, (x,y,cw,ch),
                         5 if i == G.selected_card else 3, border_radius=14)
        pygame.draw.rect(screen, color, (x+50, y+30, cw-100, cw-100), border_radius=12)
        pygame.draw.rect(screen, WHITE, (x+50, y+30, cw-100, cw-100), 3, border_radius=12)
        if kind == "evolve":          tag, tag_col = "★ 进化 ★", EVO_GOLD
        elif kind == "new_weapon":    tag, tag_col = "新武器", GOLD
        elif kind == "upgrade_weapon":tag, tag_col = "武器强化", CYAN
        else:                          tag, tag_col = "被动", GREEN
        tt = font_m.render(tag, True, tag_col)
        screen.blit(tt, (x+cw//2 - tt.get_width()//2, y+cw-38))
        nt = font_l.render(name, True, WHITE)
        screen.blit(nt, (x+cw//2 - nt.get_width()//2, y+cw-5))
        wrap_text(desc, font_s, (230,230,230), x+20, y+cw+40, cw-40)

def draw_pause():
    overlay = pygame.Surface((WIDTH, HEIGHT), pygame.SRCALPHA)
    overlay.fill((0,0,0,180)); screen.blit(overlay, (0,0))
    title = font_xxl.render("暂停 PAUSED", True, WHITE)
    screen.blit(title, (WIDTH//2 - title.get_width()//2, 40))
    sub = font_m.render("按 P 或 Esc 继续游戏", True, GRAY)
    screen.blit(sub, (WIDTH//2 - sub.get_width()//2, 120))
    mins = int(G.elapsed//60); secs = int(G.elapsed%60)
    stats_y = 170
    stats = [
        f"地图 {MAPS[G.current_map]['name']}    波次 Wave {G.wave}    时间 {mins:02d}:{secs:02d}",
        f"等级 LV.{G.player['level']}    击杀 {G.kills}    得分 {G.score}",
        f"最高连杀 {G.max_combo}    总伤害 {int(G.total_damage)}    本局金币 {G.coins_this_run}",
    ]
    for i, s in enumerate(stats):
        t = font_m.render(s, True, WHITE)
        screen.blit(t, (WIDTH//2 - t.get_width()//2, stats_y + i*28))
    col_y = 290
    pygame.draw.line(screen, GRAY, (200, col_y - 10), (WIDTH-200, col_y - 10), 1)
    wtitle = font_l.render("武器", True, GOLD)
    screen.blit(wtitle, (220, col_y))
    py = col_y + 35
    for wid, lv in G.player["weapons"].items():
        evolved = G.player["weapon_state"].get(wid,{}).get("evolved", False)
        n = EVOLUTIONS.get(wid,{}).get("name") if evolved else WEAPONS.get(wid,{}).get("name", wid)
        marker = "★" if evolved else "·"
        col = EVOLUTIONS[wid]["color"] if evolved else WEAPONS[wid]["color"]
        line = font_m.render(f"{marker} {n}  Lv{lv}", True, col)
        screen.blit(line, (220, py)); py += 28
    ptitle = font_l.render("被动", True, GOLD)
    screen.blit(ptitle, (WIDTH//2 + 60, col_y))
    py = col_y + 35
    for pid, lv in G.player["passives"].items():
        line = font_m.render(f"· {PASSIVES[pid]['name']}  Lv{lv}", True, PASSIVES[pid]["color"])
        screen.blit(line, (WIDTH//2 + 60, py)); py += 28
    syns = active_synergies_set(G.player)
    if syns:
        sy_y = max(col_y + 35 + 28*max(len(G.player['weapons']), len(G.player['passives'])) + 20, 530)
        st = font_l.render("已激活 Synergy", True, SYN_CYAN)
        screen.blit(st, (WIDTH//2 - st.get_width()//2, sy_y))
        for i, sid in enumerate(syns):
            s = SYNERGIES[sid]
            line = font_m.render(f"★ {s['name']}  —  {s['desc']}", True, SYN_CYAN)
            screen.blit(line, (WIDTH//2 - line.get_width()//2, sy_y + 32 + i*26))

def draw_meta_upgrades():
    shop_title = font_l.render(f"元进化商店  |  金币 {META['coins']}", True, GOLD)
    screen.blit(shop_title, (WIDTH//2 - shop_title.get_width()//2, 360))
    ups = list(META_UPGRADES.items())
    box_w, box_h, sp = 230, 140, 18
    total_w = len(ups)*box_w + (len(ups)-1)*sp
    sx = WIDTH//2 - total_w//2
    for i, (key, udef) in enumerate(ups):
        x = sx + i*(box_w+sp); y = 410
        cur_lv = META[f"{key}_lv"]
        maxed = cur_lv >= udef["max"]
        cost = udef["cost"](cur_lv) if not maxed else 0
        bg = CARD_HL if i == G.meta_selection else CARD_BG
        if maxed: bg = (45, 70, 50)
        pygame.draw.rect(screen, bg, (x,y,box_w,box_h), border_radius=10)
        outline = GOLD if i == G.meta_selection else GRAY
        pygame.draw.rect(screen, outline, (x,y,box_w,box_h),
                         4 if i == G.meta_selection else 2, border_radius=10)
        n = font_m.render(udef["name"], True, WHITE)
        screen.blit(n, (x+12, y+8))
        wrap_text(udef["desc"], font_s, (220,220,220), x+12, y+38, box_w-24)
        ll = font_s.render(f"Lv {cur_lv}/{udef['max']}", True, CYAN)
        screen.blit(ll, (x+12, y+88))
        if maxed:
            c = font_s.render("已满级", True, GREEN)
        else:
            can = META["coins"] >= cost
            c = font_s.render(f"{cost} 金币", True, GOLD if can else GRAY)
        screen.blit(c, (x+12, y+112))

def draw_maps_page():
    title = font_l.render(f"地图选择  |  金币 {META['coins']}", True, GOLD)
    screen.blit(title, (WIDTH//2 - title.get_width()//2, 360))
    maps_l = list(MAPS.items())
    box_w, box_h, sp = 300, 140, 30
    total_w = len(maps_l) * box_w + (len(maps_l)-1) * sp
    sx = WIDTH//2 - total_w//2
    for i, (mid, mdef) in enumerate(maps_l):
        x = sx + i*(box_w+sp); y = 410
        unlocked = mid in META["unlocked_maps"]
        selected = mid == META["current_map"]
        bg = CARD_HL if i == G.meta_selection else CARD_BG
        if not unlocked: bg = (35,35,45)
        pygame.draw.rect(screen, bg, (x,y,box_w,box_h), border_radius=10)
        outline = GOLD if i == G.meta_selection else (GREEN if selected else GRAY)
        pygame.draw.rect(screen, outline, (x,y,box_w,box_h),
                         4 if i == G.meta_selection else 2, border_radius=10)
        pygame.draw.rect(screen, mdef["bg"], (x+12, y+12, 50, 50), border_radius=4)
        pygame.draw.rect(screen, WHITE, (x+12, y+12, 50, 50), 1, border_radius=4)
        nt = font_l.render(mdef["name"], True, WHITE)
        screen.blit(nt, (x+72, y+18))
        st1 = font_s.render(f"出怪 ×{mdef['spawn_mult']}   经验 ×{mdef['exp_mult']}", True, (220,220,220))
        screen.blit(st1, (x+72, y+50))
        if selected:
            s = font_s.render("✓ 已选择中", True, GREEN)
        elif unlocked:
            s = font_s.render("已解锁 — Enter 切换", True, CYAN)
        else:
            can = META["coins"] >= mdef["cost"]
            s = font_s.render(f"价格 {mdef['cost']} 金币 — Enter 购买", True, GOLD if can else GRAY)
        screen.blit(s, (x+12, y+box_h - 28))

def draw_collection():
    title = font_l.render("武器图鉴", True, GOLD)
    screen.blit(title, (WIDTH//2 - title.get_width()//2, 360))
    grid_w = 4; box_w, box_h, sp = 140, 95, 14
    total_w = grid_w * box_w + (grid_w-1) * sp
    sx = WIDTH//2 - total_w//2; sy = 400
    wids = list(WEAPONS.keys())
    for i, wid in enumerate(wids):
        col_i = i % grid_w; row_i = i // grid_w
        x = sx + col_i * (box_w + sp); y = sy + row_i * (box_h + sp)
        unlocked = wid in META["unlocked_weapons"]
        evolved = wid in META["unlocked_evolutions"]
        bg = (90,70,40) if evolved else ((60,60,80) if unlocked else (30,30,38))
        pygame.draw.rect(screen, bg, (x,y,box_w,box_h), border_radius=8)
        outline = GOLD if evolved else (WHITE if unlocked else GRAY)
        pygame.draw.rect(screen, outline, (x,y,box_w,box_h), 2, border_radius=8)
        if unlocked:
            col = EVOLUTIONS[wid]["color"] if evolved else WEAPONS[wid]["color"]
            pygame.draw.rect(screen, col, (x+10, y+8, 30, 30), border_radius=4)
            n = EVOLUTIONS[wid]["name"] if evolved else WEAPONS[wid]["name"]
            nt = font_s.render(n, True, WHITE)
            screen.blit(nt, (x+45, y+15))
            if evolved:
                e_marker = font_xs.render("★ 已进化", True, EVO_GOLD)
                screen.blit(e_marker, (x+10, y+44))
            elif wid in EVOLUTIONS:
                evo = EVOLUTIONS[wid]
                req = font_xs.render(f"进化: Lv5 + {PASSIVES[evo['prereq']]['name']} Lv{evo['prereq_lv']}",
                                     True, CYAN)
                screen.blit(req, (x+10, y+44))
            else:
                d = font_xs.render(WEAPONS[wid]["desc"][:14], True, (200,200,200))
                screen.blit(d, (x+10, y+44))
            syns_for = [s for sid, s in SYNERGIES.items() if s["weapon"] == wid]
            if syns_for:
                sn = syns_for[0]
                sn_t = font_xs.render(f"Synergy: {sn['name']}", True, SYN_CYAN)
                screen.blit(sn_t, (x+10, y+64))
        else:
            qt = font_l.render("?", True, GRAY)
            screen.blit(qt, (x+box_w//2 - qt.get_width()//2, y+box_h//2 - 18))
            lock = font_xs.render("未解锁", True, GRAY)
            screen.blit(lock, (x+box_w//2 - lock.get_width()//2, y+box_h - 22))
    sy2 = sy + 2*(box_h+sp) + 8
    st = font_m.render(f"已解锁 Synergy: {len(META['unlocked_synergies'])} / {len(SYNERGIES)}", True, SYN_CYAN)
    screen.blit(st, (WIDTH//2 - st.get_width()//2, sy2))
    at = font_m.render(f"已解锁成就: {len(META['achievements'])} / {len(ACHIEVEMENTS)}", True, GOLD)
    screen.blit(at, (WIDTH//2 - at.get_width()//2, sy2 + 24))

def draw_meta_shop():
    overlay = pygame.Surface((WIDTH, HEIGHT))
    overlay.set_alpha(225); overlay.fill(BLACK)
    screen.blit(overlay, (0,0))
    t1 = font_xxl.render("GAME OVER", True, RED)
    screen.blit(t1, (WIDTH//2 - t1.get_width()//2, 20))
    stats_y = 100
    stats = [
        f"波次 {G.wave}   击杀 {G.kills}   得分 {G.score}",
        f"时间 {int(G.elapsed)}s   最高连杀 {G.max_combo}   进化次数 {G.evolutions_count}",
        f"总伤害 {int(G.total_damage)}   本局金币 +{G.coins_this_run}   总金币 {META['coins']}",
        f"最佳波次 {META['best_wave']}   最多击杀 {META['best_kills']}   总局数 {META['total_runs']}",
    ]
    for i, s in enumerate(stats):
        t = font_s.render(s, True, WHITE)
        screen.blit(t, (WIDTH//2 - t.get_width()//2, stats_y + i*22))
    tab_y = 200
    tabs = [("upgrades","元进化"), ("maps","地图"), ("collection","图鉴")]
    tab_w = 180; tab_sp = 12
    total_tab = len(tabs)*tab_w + (len(tabs)-1)*tab_sp
    tx0 = WIDTH//2 - total_tab//2
    for i, (tid, tname) in enumerate(tabs):
        x = tx0 + i*(tab_w+tab_sp)
        sel = G.shop_tab == tid
        bg = CARD_HL if sel else CARD_BG
        pygame.draw.rect(screen, bg, (x,tab_y,tab_w,40), border_radius=8)
        pygame.draw.rect(screen, GOLD if sel else GRAY, (x,tab_y,tab_w,40),
                         3 if sel else 1, border_radius=8)
        tt = font_m.render(tname, True, GOLD if sel else WHITE)
        screen.blit(tt, (x + tab_w//2 - tt.get_width()//2, tab_y + 10))
    if G.shop_tab == "upgrades":      draw_meta_upgrades()
    elif G.shop_tab == "maps":         draw_maps_page()
    else:                               draw_collection()
    hint = font_s.render("Tab 切换面板   ← → 选择   Enter 操作   R 重新开始   Esc 退出", True, GRAY)
    screen.blit(hint, (WIDTH//2 - hint.get_width()//2, HEIGHT - 30))

def draw_toasts():
    y = 200
    for t in G.toasts[:5]:
        ap = 1.0 if t["life"] > 0.5 else max(0.0, t["life"] / 0.5)
        alpha = int(220 * ap)
        bg = pygame.Surface((360, 60), pygame.SRCALPHA)
        bg.fill((20, 20, 30, alpha))
        screen.blit(bg, (WIDTH - 380, y))
        pygame.draw.rect(screen, t.get("color", GOLD), (WIDTH-380, y, 360, 60), 2)
        nt = font_m.render(t["name"], True, t.get("color", GOLD))
        nt.set_alpha(alpha)
        screen.blit(nt, (WIDTH - 370, y + 6))
        dt_surf = font_s.render(t["desc"], True, WHITE)
        dt_surf.set_alpha(alpha)
        screen.blit(dt_surf, (WIDTH - 370, y + 34))
        y += 70

running = True
while running:
    dt = clock.tick(60) / 1000.0
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False
        elif event.type == pygame.KEYDOWN:
            if event.key == pygame.K_ESCAPE:
                if G.paused: G.paused = False
                elif G.game_over: running = False
            elif event.key == pygame.K_p:
                if not G.game_over and G.level_up_cards is None:
                    G.paused = not G.paused
            elif G.game_over:
                if event.key == pygame.K_r:
                    G.reset()
                elif event.key == pygame.K_TAB:
                    tabs_l = ["upgrades","maps","collection"]
                    idx = tabs_l.index(G.shop_tab)
                    G.shop_tab = tabs_l[(idx+1) % len(tabs_l)]
                    G.meta_selection = 0
                elif event.key in (pygame.K_LEFT, pygame.K_a):
                    if G.shop_tab == "upgrades":
                        G.meta_selection = (G.meta_selection - 1) % len(META_UPGRADES)
                    elif G.shop_tab == "maps":
                        G.meta_selection = (G.meta_selection - 1) % len(MAPS)
                elif event.key in (pygame.K_RIGHT, pygame.K_d):
                    if G.shop_tab == "upgrades":
                        G.meta_selection = (G.meta_selection + 1) % len(META_UPGRADES)
                    elif G.shop_tab == "maps":
                        G.meta_selection = (G.meta_selection + 1) % len(MAPS)
                elif event.key in (pygame.K_RETURN, pygame.K_SPACE, pygame.K_KP_ENTER):
                    if G.shop_tab == "upgrades":
                        keys_l = list(META_UPGRADES.keys())
                        k = keys_l[G.meta_selection]; udef = META_UPGRADES[k]
                        cur = META[f"{k}_lv"]
                        if cur < udef["max"]:
                            cost = udef["cost"](cur)
                            if META["coins"] >= cost:
                                META["coins"] -= cost
                                META[f"{k}_lv"] += 1
                                save_meta(META)
                                play("levelup")
                    elif G.shop_tab == "maps":
                        maps_l = list(MAPS.keys())
                        mid = maps_l[G.meta_selection]
                        mdef = MAPS[mid]
                        if mid in META["unlocked_maps"]:
                            META["current_map"] = mid
                            save_meta(META)
                            play("levelup")
                        else:
                            if META["coins"] >= mdef["cost"]:
                                META["coins"] -= mdef["cost"]
                                META["unlocked_maps"].append(mid)
                                save_meta(META)
                                if mid == "desert":
                                    unlock_achievement("unlock_desert")
                                play("evolve")
            elif G.level_up_cards is not None:
                if event.key in (pygame.K_LEFT, pygame.K_a):
                    G.selected_card = (G.selected_card - 1) % len(G.level_up_cards)
                elif event.key in (pygame.K_RIGHT, pygame.K_d):
                    G.selected_card = (G.selected_card + 1) % len(G.level_up_cards)
                elif event.key in (pygame.K_RETURN, pygame.K_SPACE, pygame.K_KP_ENTER):
                    apply_card(G.level_up_cards[G.selected_card])
                    G.pending_levelups -= 1
                    if G.pending_levelups > 0:
                        cards2 = generate_cards(G.player)
                        if cards2:
                            G.level_up_cards = cards2; G.selected_card = 0
                        else:
                            G.pending_levelups = 0
                            G.level_up_cards = None
                            if G.coins_this_run < COIN_CAP_PER_RUN:
                                G.coins_this_run += 5; play("coin")
                    else:
                        G.level_up_cards = None

    if G.game_over and not G.game_over_committed:
        G.game_over_committed = True
        META["coins"] += G.coins_this_run
        if G.wave > META["best_wave"]: META["best_wave"] = G.wave
        if G.kills > META["best_kills"]: META["best_kills"] = G.kills
        META["total_runs"] += 1
        save_meta(META)
        unlock_achievement("first_run")
        try: pygame.mixer.music.stop()
        except Exception: pass

    if not G.game_over and G.level_up_cards is None and not G.paused:
        keys = pygame.key.get_pressed()
        mv = pygame.Vector2(0,0)
        if keys[pygame.K_w] or keys[pygame.K_UP]:    mv.y -= 1
        if keys[pygame.K_s] or keys[pygame.K_DOWN]:  mv.y += 1
        if keys[pygame.K_a] or keys[pygame.K_LEFT]:  mv.x -= 1
        if keys[pygame.K_d] or keys[pygame.K_RIGHT]: mv.x += 1
        if mv.length() > 0:
            mv.normalize_ip()
            G.player["facing"] = mv.copy()
            G.player["pos"] += mv * G.player["speed"]
        G.player["pos"].x = max(G.player["radius"], min(WIDTH-G.player["radius"], G.player["pos"].x))
        G.player["pos"].y = max(G.player["radius"], min(HEIGHT-G.player["radius"], G.player["pos"].y))

        G.elapsed += dt
        for wid in G.player["weapons"]:
            G.weapon_use_time[wid] = G.weapon_use_time.get(wid, 0) + dt
        G.combo_timer += dt
        if G.combo_timer > 1.5 and G.combo > 0: G.combo = 0
        if G.player["hp_regen"] > 0:
            G.player["hp"] = min(G.player["max_hp"], G.player["hp"] + G.player["hp_regen"]*dt)
        if G.player["iframes"] > 0:
            G.player["iframes"] -= dt

        G.wave_timer += dt
        if G.wave_timer >= G.wave_duration:
            G.wave += 1; G.wave_timer = 0
            if G.wave >= 10: unlock_achievement("wave_10")
            if G.wave >= G.next_boss_wave and not G.boss_alive:
                spawn_enemy(boss=True); G.next_boss_wave += 3
        spawn_mult = MAPS[G.current_map]["spawn_mult"]
        G.enemy_spawn_timer += dt
        if G.wave <= 15:
            spawn_rate = max(0.18, 0.7 - G.wave*0.04)
            burst = 1 + G.wave // 4
        else:
            spawn_rate = max(0.16, 0.18 - (G.wave - 15) * 0.005)
            burst = 4 + (G.wave - 15) // 8
        spawn_rate /= spawn_mult
        if G.enemy_spawn_timer >= spawn_rate and len(G.enemies) < MAX_ENEMIES:
            G.enemy_spawn_timer = 0
            for _ in range(burst):
                if len(G.enemies) >= MAX_ENEMIES: break
                spawn_enemy()

        for e in G.enemies:
            if e.get("dead"): continue
            if e.get("slow_dur", 0) > 0:
                e["slow_dur"] -= dt
                if e["slow_dur"] <= 0:
                    e["slow_fac"] = 1.0
            speed_mult = e.get("slow_fac", 1.0)
            etype = e.get("type")
            if etype == "bat":
                d_vec = G.player["pos"] - e["pos"]
                dist = d_vec.length()
                pref = e.get("preferred_dist", 200)
                if dist > pref + 20 and dist > 0:
                    e["pos"] += (d_vec/dist) * e["speed"] * speed_mult
                elif dist < pref - 30 and dist > 0:
                    e["pos"] -= (d_vec/dist) * e["speed"] * speed_mult
                e["shoot_timer"] = e.get("shoot_timer", 0) - dt
                if e["shoot_timer"] <= 0 and dist < e.get("shoot_range", 300):
                    e["shoot_timer"] = e.get("shoot_cd", 1.5)
                    if dist > 0:
                        dn = d_vec / dist
                        G.enemy_projectiles.append({"pos": e["pos"].copy(), "vel": dn*5,
                            "damage": 6, "radius": 6, "color": (180,80,200), "life": 3.0})
            else:
                d = G.player["pos"] - e["pos"]
                if d.length() > 0:
                    d.normalize_ip()
                    e["pos"] += d * e["speed"] * speed_mult
            if e.get("burn_dur", 0) > 0:
                e["burn_dur"] -= dt
                e["hp"] -= e.get("burn_dot", 0) * dt
                if e["hp"] <= 0:
                    kill_enemy(e); continue
            if not e.get("dead") and (e["pos"] - G.player["pos"]).length() < G.player["radius"] + e["radius"]:
                if etype == "kamikaze":
                    if not e.get("queued_explosion"):
                        e["queued_explosion"] = True
                        queue_explosion(e["pos"], radius=75, damage=12, color=(255,120,60))
                    kill_enemy(e)
                elif G.player["iframes"] <= 0:
                    G.player["hp"] -= e["damage"]
                    G.player["iframes"] = 0.4
                    play("hit")
                    if G.player["hp"] <= 0:
                        G.player["hp"] = 0; G.game_over = True

        for wid, lv in list(G.player["weapons"].items()):
            st = G.player["weapon_state"].setdefault(wid, {})
            WEAPON_UPDATES[wid](G.player, lv, dt, st)

        for z in G.ground_effects[:]:
            z["life"] -= dt
            z["tick"] += dt
            if z["tick"] >= z["tick_cd"]:
                z["tick"] = 0
                r_sq = z["radius"] ** 2
                for e in G.enemies:
                    if e.get("dead"): continue
                    dx = e["pos"].x - z["pos"].x; dy = e["pos"].y - z["pos"].y
                    if dx*dx + dy*dy < r_sq:
                        deal_damage(e, z["damage"], z["pos"])
                        if z["type"] == "frost" and not e.get("dead"):
                            e["slow_dur"] = max(e.get("slow_dur", 0), z["slow_dur"])
                            e["slow_fac"] = min(e.get("slow_fac", 1.0), z["slow_fac"])
            if z["life"] <= 0:
                G.ground_effects.remove(z)

        for ex in G.delayed_explosions[:]:
            ex["delay"] -= dt
            if ex["delay"] <= 0:
                play("explode")
                if (G.player["pos"] - ex["pos"]).length() < ex["radius"] + G.player["radius"]:
                    if G.player["iframes"] <= 0:
                        G.player["hp"] -= ex["damage"]
                        G.player["iframes"] = 0.4
                        if G.player["hp"] <= 0:
                            G.player["hp"] = 0; G.game_over = True
                G.pulses.append({"pos":ex["pos"].copy(), "max_r":ex["radius"], "r":0,
                                 "life":0.4, "max_life":0.4, "color":ex["color"]})
                if can_add_particle():
                    for _ in range(14):
                        ang = random.uniform(0,6.28); spd = random.uniform(2,7)
                        G.particles.append({"type":"blood","pos":ex["pos"].copy(),
                            "vel":pygame.Vector2(math.cos(ang)*spd, math.sin(ang)*spd),
                            "life":0.6,"max_life":0.6,
                            "color":ex["color"],"size":random.uniform(3,5)})
                G.delayed_explosions.remove(ex)

        for proj in G.projectiles[:]:
            proj["life"] -= dt
            target = proj.get("target")
            if proj.get("homing") and target and not target.get("dead"):
                tt = target["pos"] - proj["pos"]
                if tt.length() > 0:
                    tt.normalize_ip()
                    proj["vel"] += tt * 0.6
                    if proj["vel"].length() > 12: proj["vel"].scale_to_length(12)
            if proj.get("homing_weak") and not proj.get("homing"):
                alive2 = [e for e in G.enemies if not e.get("dead")]
                if alive2:
                    nearest = min(alive2, key=lambda e: (e["pos"]-proj["pos"]).length_squared())
                    d = (nearest["pos"] - proj["pos"])
                    dlen = d.length()
                    if 0 < dlen < 280:
                        d /= dlen
                        proj["vel"] = proj["vel"] * 0.94 + d * 0.6
                        sp_ = proj["vel"].length()
                        if sp_ > 14: proj["vel"].scale_to_length(14)
                        elif sp_ < 8: proj["vel"].scale_to_length(8)
            if proj.get("trail") and random.random() < 0.5 and len(G.afterimages) < MAX_AFTERIMAGES:
                G.afterimages.append({"pos": proj["pos"].copy(),
                    "radius": proj["radius"], "color": proj["color"][:3],
                    "life": 0.25, "max_life": 0.25})
            proj["pos"] += proj["vel"]
            if not (-50 < proj["pos"].x < WIDTH+50 and -50 < proj["pos"].y < HEIGHT+50):
                proj["life"] = 0
            for e in G.enemies:
                if e.get("dead"): continue
                eid = id(e)
                if eid in proj["hit_set"]: continue
                dx = e["pos"].x - proj["pos"].x; dy = e["pos"].y - proj["pos"].y
                R = proj["radius"] + e["radius"]
                if dx*dx + dy*dy < R*R:
                    deal_damage(e, proj["damage"], proj["pos"])
                    proj["hit_set"].add(eid)
                    if proj.get("explosive"):
                        r_sq = proj["explode_r"] ** 2
                        for e2 in G.enemies:
                            if e2 is e or e2.get("dead"): continue
                            ddx = e2["pos"].x - proj["pos"].x; ddy = e2["pos"].y - proj["pos"].y
                            if ddx*ddx + ddy*ddy < r_sq:
                                deal_damage(e2, proj["explode_dmg"], proj["pos"])
                        G.pulses.append({"pos":proj["pos"].copy(),"max_r":proj["explode_r"],"r":0,
                                         "life":0.25,"max_life":0.25,"color":(255,180,100)})
                    if proj.get("pierce", 0) > 0:
                        proj["pierce"] -= 1
                    else:
                        proj["life"] = 0
                        break
            if proj["life"] <= 0:
                G.projectiles.remove(proj)

        for ep in G.enemy_projectiles[:]:
            ep["life"] -= dt
            ep["pos"] += ep["vel"]
            if (ep["pos"] - G.player["pos"]).length() < G.player["radius"] + ep["radius"]:
                if G.player["iframes"] <= 0:
                    G.player["hp"] -= ep["damage"]
                    G.player["iframes"] = 0.4
                    play("hit")
                    if G.player["hp"] <= 0:
                        G.player["hp"] = 0; G.game_over = True
                G.enemy_projectiles.remove(ep)
            elif ep["life"] <= 0 or not (-50 < ep["pos"].x < WIDTH+50 and -50 < ep["pos"].y < HEIGHT+50):
                G.enemy_projectiles.remove(ep)

        for pt in G.particles:
            if pt.get("type") == "whip":
                w = pt.get("width", 20)
                for e in G.enemies:
                    if e.get("dead"): continue
                    eid = id(e)
                    if eid in pt["hit_set"]: continue
                    rel = e["pos"] - pt["pos"]
                    along = rel.dot(pt["dir"])
                    if 0 <= along <= pt["length"]:
                        perp = (rel - pt["dir"]*along).length()
                        if perp < e["radius"] + w:
                            deal_damage(e, pt["damage"], pt["pos"])
                            pt["hit_set"].add(eid)

        for pt in G.particles[:]:
            pt["life"] -= dt
            if pt.get("type") == "blood" and "vel" in pt:
                pt["pos"] += pt["vel"]; pt["vel"] *= 0.90
            if pt["life"] <= 0: G.particles.remove(pt)
        for ps in G.pulses[:]:
            ps["life"] -= dt
            ps["r"] = ps["max_r"] * (1 - ps["life"]/ps["max_life"])
            if ps["life"] <= 0: G.pulses.remove(ps)
        for dn in G.damage_numbers[:]:
            dn["life"] -= dt; dn["pos"].y -= 30*dt
            if dn["life"] <= 0: G.damage_numbers.remove(dn)
        for lb in G.lightning_bolts[:]:
            lb["life"] -= dt
            if lb["life"] <= 0: G.lightning_bolts.remove(lb)
        for ai in G.afterimages[:]:
            ai["life"] -= dt
            if ai["life"] <= 0: G.afterimages.remove(ai)
        for t in G.toasts[:]:
            t["life"] -= dt
            if t["life"] <= 0: G.toasts.remove(t)
        for orb in G.exp_orbs:
            if orb.get("is_coin"):
                orb["phase"] = orb.get("phase", 0) + dt*6

        for orb in G.exp_orbs[:]:
            d = G.player["pos"] - orb["pos"]
            dist = d.length()
            is_coin = orb.get("is_coin", False)
            pickup_r = G.player["pickup_range"] * (2.5 if is_coin else 1.0)
            if dist < pickup_r and dist > 0:
                orb["pos"] += d.normalize() * min(14, dist)
            if dist < G.player["radius"] + 12:
                if is_coin:
                    if G.coins_this_run < COIN_CAP_PER_RUN:
                        G.coins_this_run += 1
                    play("coin")
                else:
                    gain = max(1, int(orb["value"] * meta_exp_mult()))
                    G.player["exp"] += gain
                    play("pickup")
                    while G.player["exp"] >= G.player["exp_to_next"]:
                        G.player["exp"] -= G.player["exp_to_next"]
                        G.player["level"] += 1
                        G.player["exp_to_next"] = int(G.player["exp_to_next"]*1.28 + 4)
                        G.pending_levelups += 1
                        if G.player["level"] == 2:
                            unlock_achievement("first_levelup")
                G.exp_orbs.remove(orb)
        if G.pending_levelups > 0 and G.level_up_cards is None and not G.game_over:
            cards = generate_cards(G.player)
            if not cards:
                G.pending_levelups -= 1
                if G.coins_this_run < COIN_CAP_PER_RUN:
                    G.coins_this_run += 5
                play("coin")
            else:
                G.level_up_cards = cards; G.selected_card = 0

        if any(e.get("dead") for e in G.enemies):
            G.enemies = [e for e in G.enemies if not e.get("dead")]

    draw_bg()
    draw_ground_effects()
    draw_pulses()
    draw_orbs()
    draw_particles()
    draw_enemies()
    draw_warnings()
    draw_halo_orbs()
    draw_lightning()
    draw_projectiles()
    draw_player(G.player)
    draw_damage_numbers()
    draw_ui()
    draw_toasts()
    if G.paused and not G.game_over: draw_pause()
    if G.level_up_cards is not None:  draw_levelup()
    if G.game_over:                    draw_meta_shop()
    pygame.display.flip()

pygame.quit()
sys.exit()
