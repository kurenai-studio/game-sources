"""Moteur de simulation : monde, civilisations, IA individuelle, météo, catastrophes, armées."""
import math
import random

W, H = 240, 150
N = W * H
DAY, YEAR = 200, 800                 # ticks par jour / par cycle saisonnier
START_YEAR, CYCLE_YEARS = 1000, 12   # 1 cycle de saisons = 12 ans d'histoire
END_YEAR = 2026
SEASONS = ['Printemps', 'Été', 'Automne', 'Hiver']
ERAS = ['Moyen-Âge', 'Renaissance', 'Ère industrielle', 'Époque moderne']
ERA_START = [1000, 1450, 1750, 1900]
RES = ['food', 'water', 'wood', 'stone', 'metal']
RNAME = {'food': 'Nourriture', 'water': 'Eau', 'wood': 'Bois', 'stone': 'Pierre', 'metal': 'Métal'}
PER = {'food': 14, 'water': 12, 'wood': 7, 'stone': 6, 'metal': 3}
DEEP, WATER, SAND, GRASS, FOREST, ROCK, SNOW, LAVA = range(8)
TNAME = ['Eau profonde', 'Eau', 'Sable', 'Herbe', 'Forêt', 'Roche', 'Neige', 'Lave']
PASS = [False, True, True, True, True, True, True, False]
BIOMES = ['Désert', 'Forêt', 'Montagne']
CHILD = 500

# nom, coût, prérequis, court, ère
TECH = {
    'tools': ('Outils', 40, [], 'Outils', 0), 'agri': ('Agriculture', 70, ['tools'], 'Agri.', 0),
    'mason': ('Maçonnerie', 90, ['tools'], 'Maçon.', 0), 'irrig': ('Irrigation', 120, ['agri'], 'Irrig.', 0),
    'trade': ('Commerce', 100, [], 'Comm.', 0), 'metal': ('Métallurgie', 150, ['tools'], 'Métal.', 0),
    'chiv': ('Chevalerie', 200, ['metal'], 'Chev.', 0),
    'print': ('Imprimerie', 260, ['mason', 'trade'], 'Impr.', 1), 'gunp': ('Poudre à canon', 300, ['metal'], 'Poudre', 1),
    'bank': ('Banque', 280, ['trade'], 'Banque', 1), 'med': ('Médecine', 240, ['tools'], 'Méd.', 1),
    'steam': ('Machine à vapeur', 420, ['print'], 'Vapeur', 2), 'rifle': ('Fusils', 450, ['gunp'], 'Fusils', 2),
    'rail': ('Chemin de fer', 500, ['steam'], 'Rail', 2), 'hyg': ('Hygiène', 420, ['med'], 'Hyg.', 2),
    'elec': ('Électricité', 650, ['steam'], 'Élec.', 3), 'auto': ('Automobile', 700, ['rail'], 'Auto', 3),
    'tank': ('Blindés', 800, ['rifle', 'auto'], 'Blindés', 3), 'comp': ('Informatique', 900, ['elec'], 'Info.', 3),
    'vacc': ('Vaccins', 700, ['hyg'], 'Vaccins', 3),
}
GOV = {
    'monarchie': dict(name='Monarchie', title='Souverain', res=.85, prod=1.0, army=.25, mood=4, aggr=.5),
    'republique': dict(name='République', title='Consul', res=1.15, prod=1.05, army=.15, mood=10, aggr=.2),
    'dictature': dict(name='Dictature', title='Dictateur', res=.8, prod=1.2, army=.4, mood=-12, aggr=.85),
}
# nom, couleur, options de coût, durée, tech requise
BDEF = {
    'house': ('Maison', [{'wood': 10, 'stone': 2}, {'stone': 14}], 30, None),
    'farm': ('Ferme', [{'wood': 6}, {'stone': 6}], 30, 'agri'),
    'well': ('Puits', [{'stone': 8, 'wood': 2}, {'stone': 10}, {'wood': 10}], 25, None),
    'sawmill': ('Scierie', [{'wood': 8}, {'stone': 8}], 25, None),
    'mine': ('Mine', [{'wood': 8, 'stone': 6}, {'stone': 12}], 40, 'tools'),
    'warehouse': ('Entrepôt', [{'wood': 8, 'stone': 4}, {'stone': 12}], 30, None),
    'barracks': ('Caserne', [{'wood': 10, 'stone': 10, 'metal': 5}, {'stone': 14, 'metal': 5}], 50, 'metal'),
    'govt': ('Palais', [{'stone': 30, 'wood': 10}, {'stone': 40}], 80, 'mason'),
    'academy': ('Académie', [{'stone': 25, 'wood': 10}, {'stone': 35}], 70, 'print'),
    'factory': ('Usine', [{'stone': 20, 'metal': 10}, {'stone': 24, 'wood': 10, 'metal': 6}], 70, 'steam'),
}
NAMES = [
    'Amir Zahra Karim Leila Rashid Samira Tarek Yasmin Idris Nadia Omar Soraya Jamil Farah Malik Dalia Hakim Amina Tahar Salma Nour Walid Layla Anwar'.split(),
    'Elowen Thalion Sylva Aldric Fenna Orin Maelis Bran Liora Edric Tilda Rowan Isold Garrick Wren Cedric Hazel Lorin Maeve Torin Elara Perrin Faye Joren'.split(),
    'Brokk Thora Gunnar Helga Dorn Ragna Ulric Sigrid Bjorn Astrid Torv Ingrid Kjell Freya Harald Revna Orm Gerda Rurik Vigdis Skarn Hild Magnar Yrsa'.split(),
]
CIV_DEF = [
    dict(name='Sahari', biome=0, color=(255, 122, 26), cx=40, cy=75, gov='monarchie',
         order=['tools', 'agri', 'irrig', 'trade', 'mason', 'metal', 'chiv', 'bank', 'print', 'med', 'gunp', 'steam', 'hyg',
                'rifle', 'rail', 'elec', 'auto', 'vacc', 'comp', 'tank'],
         start=dict(food=50, water=60, wood=10, stone=25, metal=0), bonus=dict(curio=.15)),
    dict(name='Sylvani', biome=1, color=(46, 230, 192), cx=120, cy=75, gov='republique',
         order=['tools', 'agri', 'mason', 'trade', 'metal', 'irrig', 'chiv', 'print', 'bank', 'med', 'gunp', 'steam', 'hyg',
                'rail', 'rifle', 'elec', 'vacc', 'comp', 'auto', 'tank'],
         start=dict(food=50, water=40, wood=35, stone=5, metal=0), bonus=dict(social=.15)),
    dict(name='Karak', biome=2, color=(190, 120, 255), cx=200, cy=75, gov='dictature',
         order=['tools', 'mason', 'metal', 'agri', 'chiv', 'trade', 'gunp', 'print', 'bank', 'med', 'steam', 'rifle', 'rail',
                'hyg', 'elec', 'auto', 'tank', 'vacc', 'comp', 'irrig'],
         start=dict(food=35, water=40, wood=12, stone=30, metal=3), bonus=dict(courage=.15, travail=.1)),
]


def clamp(v, a, b):
    return a if v < a else b if v > b else v


class Noise:
    def __init__(self, seed):
        r = random.Random(seed)
        self.g = [r.random() for _ in range(4096)]

    def __call__(self, x, y):
        xi, yi = math.floor(x), math.floor(y)
        xf, yf = x - xi, y - yi
        u, w = xf * xf * (3 - 2 * xf), yf * yf * (3 - 2 * yf)
        g = self.g
        a = g[((yi & 63) << 6) | (xi & 63)] * (1 - u) + g[((yi & 63) << 6) | ((xi + 1) & 63)] * u
        b = g[(((yi + 1) & 63) << 6) | (xi & 63)] * (1 - u) + g[(((yi + 1) & 63) << 6) | ((xi + 1) & 63)] * u
        return a * (1 - w) + b * w

    def fbm(self, x, y):
        return self(x, y) * .6 + self(x * 2.1, y * 2.1) * .3 + self(x * 4.3, y * 4.3) * .1


class Building:
    def __init__(self, typ, x, y, civ, done=False):
        self.type, self.x, self.y, self.civ = typ, x, y, civ
        self.prog, self.done = 0, done
        self.res = set()


class Agent:
    __slots__ = ('id', 'civ', 'name', 'x', 'y', 'ox', 'oy', 'hp', 'age', 'role', 'state', 'task', 'tx', 'ty', 'reach',
                 'job', 'cd', 'carry', 'dead', 'why', 'hunger', 'thirst', 'energy', 'mood', 'tr', 'thought', 'thoughts',
                 'mem', 'friends', 'home', 'stuck', 'act', 'kills', 'target', 'parents', 'title', 'rank', 'born', 'sheltered')

    def __init__(self, i, civ, x, y, name, tr, age):
        self.id, self.civ, self.name, self.tr, self.age = i, civ, name, tr, age
        self.x = self.ox = x
        self.y = self.oy = y
        self.hp, self.role, self.state, self.task = 100.0, 'worker', 'idle', ''
        self.tx = self.ty = 0
        self.reach = 0
        self.job = None
        self.cd = 0
        self.carry = None
        self.dead = False
        self.why = 'maladie'
        self.hunger = random.uniform(60, 100)
        self.thirst = random.uniform(60, 100)
        self.energy = random.uniform(60, 100)
        self.mood = 60.0
        self.thought = ''
        self.thoughts = []
        self.mem = {}
        self.friends = {}
        self.home = None
        self.stuck = 0
        self.act = 'autre'
        self.kills = 0
        self.target = None
        self.parents = ()
        self.title = ''
        self.rank = 0
        self.born = 0
        self.sheltered = False


class Animal:
    __slots__ = ('kind', 'x', 'y', 'ox', 'oy', 'hp', 'cd', 'life', 'dead')

    def __init__(self, kind, x, y, life=0):
        self.kind, self.x, self.y, self.ox, self.oy = kind, x, y, x, y
        self.hp = 40 if kind == 'deer' else 70
        self.cd = 0
        self.life = life
        self.dead = False


class Wx:
    __slots__ = ('kind', 'x', 'y', 'r', 'life', 'max', 'vx', 'vy')

    def __init__(self, kind, x, y, r, life):
        self.kind, self.x, self.y, self.r, self.life, self.max = kind, x, y, r, life, life
        self.vx = self.vy = 0.0


class Civ:
    def __init__(self, i, d):
        self.id, self.name, self.color, self.biome = i, d['name'], d['color'], d['biome']
        self.cx, self.cy, self.order = d['cx'], d['cy'], d['order']
        self.stock = {r: float(d['start'].get(r, 0)) for r in RES}
        self.agents, self.buildings = [], []
        self.tech, self.rp, self.research = set(), 0.0, None
        self.prio = dict(food=1.0, water=1.0, wood=1.0, stone=1.0, metal=.5, military=0.0)
        self.auto = dict(food=1.0, water=1.0, wood=1.0, stone=1.0, metal=1.0, military=0.0)
        self.alive = True
        self.flags = set()
        self.dc = {}
        self.atk = 1.0
        self.gov = d['gov']
        self.leader = None
        self.unrest = 0
        self.mood = 60.0
        self.next_elect = 1600
        self.era = 0
        self.nores = {}
        self.wx = set()
        self.pm = 1.0
        self.bonus = d['bonus']
        self.decree = ''
        self.army = dict(state='garrison', enemy=None, t0=0, n0=0, cool=0, rally=(d['cx'], d['cy']))
        self.biome_name = BIOMES[d['biome']]

    @property
    def pop(self):
        return len(self.agents)

    @property
    def soldiers(self):
        return sum(1 for a in self.agents if a.role == 'soldier')


class Sim:
    def __init__(self, seed=None):
        self.seed = seed or random.randrange(1 << 30)
        self.t = 0
        self.log, self.fx = [], []
        self.dirty = set()
        self.carav = []
        self.hist = [[], [], []]
        self.drought = [0, 0, 0]
        self.rel = [[0.0] * 3 for _ in range(3)]
        self.war = [[None] * 3 for _ in range(3)]
        self.p = dict(fert=1.0, birth=1.0, cons=1.0, research=1.0, wfreq=1.0, temp=0.0, aggr=1.0)
        self.animals, self.wx, self.fire, self.lava, self.floods, self.pending = [], [], {}, {}, [], []
        self.hazards = []
        self.wind = [.03, .01]
        self.next_id = 1
        self.byid = {}
        self.cells = [{}, {}, {}]
        self.shake = 0
        self.reached = False
        self.gen()
        self.civs = [Civ(i, d) for i, d in enumerate(CIV_DEF)]
        for c in self.civs:
            self.add_building(c, 'town', c.cx, c.cy, done=True)
            for _ in range(12):
                self.add_agent(c, c.cx + random.randint(-3, 3), c.cy + random.randint(-3, 3), age=random.randint(600, 1800))
            self.elect(c, silent=True)
        self.territory()
        self.say("An 1000 : trois peuples s'installent — Sahari (désert), Sylvani (forêt), Karak (montagne).", (240, 220, 160))

    # ───────── temps ─────────
    def year(self):
        return START_YEAR + int(self.t * CYCLE_YEARS / YEAR)

    def world_era(self):
        y = self.year()
        return max(i for i in range(4) if y >= ERA_START[i])

    def season(self):
        return (self.t % YEAR) // (YEAR // 4)

    def hour(self):
        return (self.t % DAY) / DAY

    def dark(self):
        h = self.hour()
        if h < .55:
            return 0.0
        if h < .7:
            return (h - .55) / .15
        if h < .93:
            return 1.0
        return (1 - h) / .07

    def night(self):
        return self.dark() > .6

    def when(self):
        return '%d · %s' % (self.year(), SEASONS[self.season()])

    def say(self, msg, col=(230, 232, 236)):
        self.log.insert(0, (self.year(), msg, col))
        del self.log[120:]

    # ───────── carte ─────────
    def gen(self):
        s = self.seed
        n1, n2, n3 = Noise(s), Noise(s + 7), Noise(s + 13)
        r = random.Random(s + 99)
        self.terr = [SAND] * N
        self.biome = [0] * N
        self.food, self.wood, self.stone, self.metal = ([0.0] * N for _ in range(4))
        self.mf, self.mw = [0.0] * N, [0.0] * N
        self.water = [0] * N
        self.burnt = [0] * N
        self.owner = [-1] * N
        self.bld = [None] * N
        self.arr = {'food': self.food, 'wood': self.wood, 'stone': self.stone, 'metal': self.metal}
        for y in range(H):
            b1 = 80 + (n3(3.3, y * .05) - .5) * 16
            b2 = 160 + (n3(7.7, y * .05) - .5) * 16
            for x in range(W):
                i = y * W + x
                b = 0 if x < b1 else 1 if x < b2 else 2
                self.biome[i] = b
                a = n1.fbm(x * .09, y * .09)
                c = n2.fbm(x * .2 + 50, y * .2)
                d = r.random()
                lake = n3.fbm(x * .13 + 9, y * .13)
                ed = min(x, W - 1 - x, y, H - 1 - y) + (n3.fbm(x * .06 + 3, y * .06 + 3) - .5) * 14
                if ed < 3:
                    self.terr[i] = DEEP
                    continue
                if ed < 5:
                    self.set_water(i)
                    continue
                if b == 0:
                    if a > .62:
                        self.terr[i], self.stone[i] = ROCK, 20 + a * 30
                        if a > .66 and d < .18:
                            self.metal[i] = 15
                    elif c > .72 and d < .5:
                        self.food[i] = self.mf[i] = 4
                    if d < .004:
                        self.wood[i] = self.mw[i] = 8
                elif b == 1:
                    self.terr[i] = GRASS
                    if a > .45:
                        self.terr[i] = FOREST
                        self.wood[i] = self.mw[i] = 14 + a * 14
                    if c > .55 and d < .35:
                        self.food[i] = self.mf[i] = 7
                    if d < .015:
                        self.stone[i] = 12
                    if d > .997:
                        self.metal[i] = 8
                    if lake > .68:
                        self.set_water(i, lake > .76)
                else:
                    self.terr[i] = GRASS
                    if a > .42:
                        self.terr[i], self.stone[i] = ROCK, 25 + a * 35
                        if a > .7:
                            self.terr[i] = SNOW
                        if c > .55 and d < .3:
                            self.metal[i] = 18
                    else:
                        if c > .5 and d < .25:
                            self.food[i] = self.mf[i] = 5
                        if d < .12:
                            self.wood[i] = self.mw[i] = 10
                    if lake > .74:
                        self.set_water(i, lake > .8)
        for ox, oy in ((50, 72), (12 + r.randint(0, 6), 46), (15, 112), (62, 118), (30, 22), (66, 30), (55, 140)):
            for dy in range(-4, 5):
                for dx in range(-4, 5):
                    x, y = ox + dx, oy + dy
                    if not (6 <= x < W - 6 and 6 <= y < H - 6):
                        continue
                    i, dd = y * W + x, math.hypot(dx, dy)
                    if dd <= 1.6:
                        self.set_water(i)
                    elif dd <= 3.4 and self.terr[i] not in (WATER, DEEP):
                        self.terr[i], self.stone[i], self.metal[i] = GRASS, 0, 0
                        if r.random() < .6:
                            self.food[i] = self.mf[i] = 8
                        elif r.random() < .5:
                            self.wood[i] = self.mw[i] = 10
        for d in CIV_DEF:
            self.clear(d['cx'], d['cy'], 5, d['biome'], r)
        self.grow = [i for i in range(N) if self.mf[i] or self.mw[i]]
        self.grow_set = set(self.grow)
        for _ in range(70):
            x, y = r.randint(6, W - 7), r.randint(6, H - 7)
            if self.terr[y * W + x] in (GRASS, FOREST):
                self.animals.append(Animal('deer', x, y))

    def set_water(self, i, deep=False):
        self.terr[i] = DEEP if deep else WATER
        self.water[i] = 0 if deep else 1
        self.food[i] = self.wood[i] = self.stone[i] = self.metal[i] = 0
        self.mf[i] = self.mw[i] = 0
        self.touch(i)

    def clear(self, cx, cy, rad, b, r):
        for y in range(cy - 8, cy + 9):
            for x in range(cx - 8, cx + 9):
                i, d = y * W + x, math.hypot(x - cx, y - cy)
                if d <= rad:
                    self.terr[i] = SAND if b == 0 else GRASS
                    self.water[i] = 0
                    self.food[i] = self.wood[i] = self.stone[i] = self.metal[i] = 0
                    self.mf[i] = self.mw[i] = 0
                elif 6 <= d <= 9 and r.random() < .25 and self.terr[i] not in (WATER, DEEP):
                    self.food[i] = self.mf[i] = 6 if b else 4

    def touch(self, i):
        self.dirty.add(i)

    def add_grow(self, i):
        if i not in self.grow_set:
            self.grow_set.add(i)
            self.grow.append(i)

    def ok(self, x, y):
        return 0 <= x < W and 0 <= y < H and PASS[self.terr[y * W + x]]

    def findres(self, x, y, res, R):
        water = res == 'water'
        arr = None if water else self.arr[res]
        for d in range(R + 1):
            hits = []
            for dy in range(-d, d + 1):
                yy = y + dy
                if yy < 0 or yy >= H:
                    continue
                step = 1 if (dy == -d or dy == d) else (2 * d or 1)
                for dx in range(-d, d + 1, step):
                    xx = x + dx
                    if 0 <= xx < W:
                        i = yy * W + xx
                        if (self.water[i] if water else arr[i] >= 1):
                            hits.append(i)
            if hits:
                return random.choice(hits)
        return None

    # ───────── entités ─────────
    def new_traits(self, c, p1=None, p2=None):
        tr = {}
        for k in ('travail', 'courage', 'social', 'curio'):
            if p1 and p2:
                v = (p1.tr[k] + p2.tr[k]) / 2 + random.uniform(-.15, .15)
            else:
                v = random.uniform(.15, .85) + c.bonus.get(k, 0)
            tr[k] = clamp(v, .05, .98)
        return tr

    def add_agent(self, c, x, y, age=0, p1=None, p2=None):
        x, y = clamp(x, 1, W - 2), clamp(y, 1, H - 2)
        a = Agent(self.next_id, c.id, x, y, random.choice(NAMES[c.id]), self.new_traits(c, p1, p2), age)
        self.next_id += 1
        a.born = self.t
        if p1:
            a.parents = (p1.id, p2.id)
            a.hunger = a.thirst = a.energy = 100
        c.agents.append(a)
        self.byid[a.id] = a
        return a

    def add_building(self, c, typ, x, y, done=False):
        b = Building(typ, x, y, c.id, done)
        c.buildings.append(b)
        if typ == 'town':
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    self.bld[(y + dy) * W + x + dx] = b
                    self.touch((y + dy) * W + x + dx)
        else:
            self.bld[y * W + x] = b
            self.touch(y * W + x)
        return b

    def remove_building(self, b, silent=False):
        c = self.civs[b.civ]
        if b.type == 'town':
            return
        if b in c.buildings:
            c.buildings.remove(b)
        i = b.y * W + b.x
        if self.bld[i] is b:
            self.bld[i] = None
        for aid in list(b.res):
            ag = self.byid.get(aid)
            if ag:
                ag.home = None
        self.touch(i)
        if not silent:
            self.fx.append(['dust', b.x, b.y, 25])

    def count(self, c, typ, done=False):
        return sum(1 for b in c.buildings if b.type == typ and (b.done or not done))

    def cap(self, c):
        per = 4 + (2 if 'mason' in c.tech else 0) + (4 if 'steam' in c.tech else 0) + (6 if 'elec' in c.tech else 0)
        return 8 + self.count(c, 'house', True) * per

    def stock_cap(self, c):
        return 120 + 80 * self.count(c, 'warehouse', True) + (100 if 'bank' in c.tech else 0)

    def pay_option(self, c, typ):
        for opt in BDEF[typ][1]:
            if all(c.stock[r] >= v for r, v in opt.items()):
                return opt
        return None

    def try_build(self, c, typ, x=None, y=None, quiet=False):
        d = BDEF[typ]
        if d[3] and d[3] not in c.tech:
            return False
        opt = self.pay_option(c, typ)
        if not opt:
            return False
        if x is None:
            pos = self.site(c, typ)
            if not pos:
                return False
            x, y = pos
        elif self.bld[y * W + x] is not None or self.terr[y * W + x] in (WATER, DEEP, LAVA):
            return False
        for r, v in opt.items():
            c.stock[r] -= v
        self.add_building(c, typ, x, y)
        if not quiet and typ not in ('house', 'farm'):
            self.say('%s : construction — %s' % (c.name, d[0].lower()), c.color)
        return True

    def site(self, c, typ):
        if typ in ('sawmill', 'mine'):
            res = 'wood' if typ == 'sawmill' else 'stone'
            i = self.findres(c.cx, c.cy, res, 24)
            if i is not None and self.bld[i] is None:
                return i % W, i // W
            if typ == 'sawmill':
                return None
        nb = len(c.buildings)
        for k in range(60):
            ang = random.random() * 6.283
            dist = 3 + random.random() * min(16, 4 + nb * .25)
            x, y = int(c.cx + math.cos(ang) * dist), int(c.cy + math.sin(ang) * dist)
            if not (3 <= x < W - 3 and 3 <= y < H - 3):
                continue
            i = y * W + x
            if self.bld[i] is not None or self.terr[i] in (WATER, DEEP, SNOW, LAVA) or i in self.fire:
                continue
            if k < 35 and (self.food[i] >= 1 or self.wood[i] >= 1 or self.metal[i] >= 1):
                continue
            return x, y
        return None

    # ───────── diplomatie ─────────
    def at_war(self, a, b):
        return self.war[a][b] is not None

    def war_any(self, c):
        return any(self.war[c.id][o] is not None for o in range(3) if o != c.id)

    def war_target(self, c):
        for o in self.civs:
            if o is not c and o.alive and self.war[c.id][o.id] is not None:
                return o
        return None

    def set_rel(self, a, b, v):
        self.rel[a][b] = self.rel[b][a] = clamp(v, -100, 100)

    def add_rel(self, a, b, dv):
        self.set_rel(a, b, self.rel[a][b] + dv)

    def declare_war(self, a, b):
        if self.war[a][b] is None and self.civs[a].alive and self.civs[b].alive:
            self.war[a][b] = self.war[b][a] = self.t
            self.set_rel(a, b, min(self.rel[a][b], -60))
            self.war_pop = getattr(self, 'war_pop', {})
            self.war_pop[a], self.war_pop[b] = self.civs[a].pop, self.civs[b].pop
            self.say('GUERRE entre %s et %s !' % (self.civs[a].name, self.civs[b].name), (255, 90, 90))

    def make_peace(self, a, b, quiet=False):
        if self.war[a][b] is not None:
            self.war[a][b] = self.war[b][a] = None
            self.set_rel(a, b, max(self.rel[a][b], -10))
            for c in (self.civs[a], self.civs[b]):
                c.army.update(state='garrison', enemy=None, cool=self.t + 200)
            if not quiet:
                self.say('Paix entre %s et %s.' % (self.civs[a].name, self.civs[b].name), (130, 230, 130))

    # ───────── boucle ─────────
    def tick(self):
        t = self.t
        if t % 3 == 0:
            self.rebuild_cells()
        if t % 2 == 0:
            self.compute_hazards()
        for c in self.civs:
            if not c.alive:
                continue
            for a in c.agents:
                if not a.dead:
                    self.step_agent(a, c)
            self.civ_tick(c)
        self.animals_tick()
        self.weather_tick()
        if self.fire and t % 4 == 0:
            self.fire_tick()
        if self.lava and t % 3 == 0:
            self.lava_tick()
        if self.pending:
            self.pending_tick()
        if t % 10 == 0:
            self.regrow()
        if t % 20 == 0:
            self.temp_tick()
            for i, c in enumerate(self.civs):
                self.hist[i].append(c.pop)
                del self.hist[i][:-400]
        if t % 50 == 0:
            self.diplomacy()
        if t % 120 == 60:
            self.trade()
        if t % 100 == 40:
            self.territory()
        if random.random() < self.p['wfreq'] / 160:
            self.natural_weather()
        if random.random() < 1 / 4000:
            self.natural_disaster()
        if not self.reached and self.year() >= END_YEAR:
            self.reached = True
            self.say("L'ÉPOQUE ACTUELLE est atteinte (%d). Les civilisations ont traversé les siècles." % END_YEAR, (255, 230, 120))
        self.t += 1

    def rebuild_cells(self):
        for i, c in enumerate(self.civs):
            cells = {}
            for a in c.agents:
                if not a.dead:
                    cells.setdefault((a.x >> 3, a.y >> 3), []).append(a)
            self.cells[i] = cells

    def near_agents(self, civ, x, y, r):
        out = []
        cells = self.cells[civ]
        cx0, cx1, cy0, cy1 = (x - r) >> 3, (x + r) >> 3, (y - r) >> 3, (y + r) >> 3
        for cx in range(cx0, cx1 + 1):
            for cy in range(cy0, cy1 + 1):
                for a in cells.get((cx, cy), ()):
                    if not a.dead:
                        out.append(a)
        return out

    def compute_hazards(self):
        hz = []
        for i in list(self.fire)[:60]:
            hz.append((i % W, i // W, 3, 'le feu', 'fire'))
        for i in list(self.lava)[:40]:
            hz.append((i % W, i // W, 3, 'la lave', 'lava'))
        for w in self.wx:
            if w.kind == 'tornado':
                hz.append((w.x, w.y, 9, 'la tornade', 'tornado'))
        for a in self.animals:
            if a.kind == 'wolf' and not a.dead:
                hz.append((a.x, a.y, 7, 'un loup', 'wolf'))
        for p in self.pending:
            if p[1] == 'meteor':
                hz.append((p[2], p[3], 9, 'la météorite', 'meteor'))
        self.hazards = hz

    # ───────── pensées ─────────
    def think(self, a, txt):
        if txt != a.thought:
            a.thought = txt
            a.thoughts.insert(0, (self.year(), txt))
            del a.thoughts[7:]

    # ───────── agents ─────────
    def kill(self, a, why=None):
        if a.dead:
            return
        a.dead = True
        if why:
            a.why = why
        c = self.civs[a.civ]
        c.dc[a.why] = c.dc.get(a.why, 0) + 1
        if a.home:
            a.home.res.discard(a.id)
        self.byid.pop(a.id, None)
        for fid, aff in a.friends.items():
            f = self.byid.get(fid)
            if f and aff > .5 and not f.dead:
                f.mood -= 15
                self.think(f, "J'ai perdu %s… ma peine est immense." % a.name)
        if a is c.leader:
            c.leader = None

    def step_agent(self, a, c):
        a.ox, a.oy = a.x, a.y
        a.age += 1
        t = self.t
        sl = a.state == 'sleep'
        away = a.role == 'soldier' and c.army['state'] in ('march', 'siege')
        if away:
            c.stock['food'] = max(0, c.stock['food'] - .03)
            c.stock['water'] = max(0, c.stock['water'] - .02)
        else:
            a.hunger -= (.5 if sl else 1.1) * self.p['cons']
            heat = 'heat' in c.wx
            a.thirst -= (.5 if sl else 1.05) * self.p['cons'] * (1.6 if heat else 1)
        a.energy = min(100, a.energy + 1.5) if sl else a.energy - .14
        if a.hunger <= 0:
            a.hp -= .5
            a.why = 'faim'
            a.hunger = 0
        if a.thirst <= 0:
            a.hp -= 1.0
            a.why = 'soif'
            a.thirst = 0
        if 'FROID' in c.flags and not sl:
            a.hp -= .25
            a.why = 'froid'
        if a.hp < 100 and a.hunger > 30 and a.thirst > 30:
            a.hp = min(100, a.hp + .3 + (.3 if 'med' in c.tech else 0) + (.3 if 'vacc' in c.tech else 0))
        g = GOV[c.gov]
        target = 55 + g['mood'] + (8 if a.hunger > 40 else -25 if a.hunger < 20 else 0) + (8 if a.thirst > 40 else -25 if a.thirst < 20 else 0)
        target += -15 if 'FROID' in c.flags else 0
        target += -8 if self.war_any(c) else 0
        a.mood += (target - a.mood) * .02
        if a.age > 3500 and random.random() < (.002 if a.age < 5500 else .01):
            self.kill(a, 'vieillesse')
            return
        if a.hp <= 0:
            self.kill(a)
            return
        # dangers (perception)
        if self.hazards and (a.id + t) % 4 == 0 and a.state != 'sleep':
            if self.perceive(a, c):
                return
        # combat
        if (a.role == 'soldier' and (a.id + t) % 2 == 0) or (self.animals and a.tr['courage'] > .7 and (a.id + t) % 5 == 0):
            if self.engage(a, c):
                return
        st = a.state
        if st == 'idle':
            self.decide(a, c)
        elif st == 'move':
            spd = 3 if 'auto' in c.tech else 2 if 'rail' in c.tech else 1
            if a.role == 'soldier' and c.army['state'] in ('march', 'muster'):
                spd = 2 if 'rail' in c.tech else 1
            for _ in range(spd):
                if self.arrived(a):
                    self.arrive(a, c)
                    break
                self.stepto(a, a.tx, a.ty)
                if a.stuck > 6:
                    a.state = 'idle'
                    a.stuck = 0
                    break
            else:
                if self.arrived(a):
                    self.arrive(a, c)
        elif st == 'work':
            a.cd -= 1
            if a.cd <= 0:
                self.finish(a, c)
        elif st == 'sleep':
            if a.sheltered:
                if not self.bad_weather(a) and (a.id + t) % 10 == 0:
                    a.sheltered = False
                    a.state = 'idle'
            elif a.energy >= 100 or (a.energy > 85 and not self.night()):
                a.state = 'idle'
                self.think(a, 'Une bonne nuit de sommeil ! Je me sens en forme.')

    def arrived(self, a):
        if a.reach:
            return abs(a.x - a.tx) <= 1 and abs(a.y - a.ty) <= 1
        return a.x == a.tx and a.y == a.ty

    def stepto(self, a, tx, ty):
        dx, dy = (tx > a.x) - (tx < a.x), (ty > a.y) - (ty < a.y)
        for ddx, ddy in ((dx, dy), (dx, 0), (0, dy)):
            if (ddx or ddy) and self.ok(a.x + ddx, a.y + ddy):
                a.x += ddx
                a.y += ddy
                a.stuck = max(0, a.stuck - 1)
                return
        a.stuck += 1
        for _ in range(4):
            ddx, ddy = random.randint(-1, 1), random.randint(-1, 1)
            if (ddx or ddy) and self.ok(a.x + ddx, a.y + ddy):
                a.x += ddx
                a.y += ddy
                return

    def go(self, a, x, y, task, thought=None, reach=0, act='autre'):
        a.tx, a.ty = clamp(int(x), 1, W - 2), clamp(int(y), 1, H - 2)
        a.state, a.task, a.reach, a.act, a.stuck = 'move', task, reach, act, 0
        if thought:
            self.think(a, thought)

    def home_pos(self, a, c):
        h = a.home
        if h is None or h not in c.buildings:
            a.home = None
            for b in c.buildings:
                if b.type == 'house' and b.done and len(b.res) < 4:
                    b.res.add(a.id)
                    a.home = b
                    break
            h = a.home
        return (h.x, h.y) if h else (c.cx, c.cy)

    def perceive(self, a, c):
        brave = a.tr['courage']
        for x, y, r, label, kind in self.hazards:
            d = math.hypot(x - a.x, y - a.y)
            if d > r * (1.25 - brave * .5):
                continue
            if kind == 'wolf' and (a.role == 'soldier' or (brave > .7 and a.hp > 50)):
                return False
            if kind == 'meteor' and d > 9:
                continue
            ang = math.atan2(a.y - y, a.x - x)
            self.go(a, a.x + math.cos(ang) * 12, a.y + math.sin(ang) * 12, 'flee',
                    'Au secours ! Fuyez, %s !' % label if brave < .5 else 'Je recule devant %s.' % label, act='fuite')
            return True
        return False

    def bad_weather(self, a):
        for w in self.wx:
            if w.kind in ('storm', 'blizzard') and (w.x - a.x) ** 2 + (w.y - a.y) ** 2 < w.r * w.r:
                return 'orage' if w.kind == 'storm' else 'blizzard'
        return None

    def engage(self, a, c):
        foe, fd, kind = None, 99, None
        det = 16 if math.hypot(a.x - c.cx, a.y - c.cy) < 18 else 5
        if a.role != 'soldier':
            det = 6
        rng = 1.5 + (2.5 if 'gunp' in c.tech else 0) + (2 if 'rifle' in c.tech else 0) + (2 if 'tank' in c.tech else 0)
        if a.role != 'soldier':
            rng = 1.5
            enemies = []
        else:
            enemies = [o for o in self.civs if o is not c and o.alive and self.at_war(c.id, o.id)]
        for o in enemies:
            for e in self.near_agents(o.id, a.x, a.y, int(det)):
                d = math.hypot(e.x - a.x, e.y - a.y)
                if d < fd and d <= det and not (e.state == 'sleep' and e.home):
                    fd, foe, kind = d, e, 'agent'
        for an in self.animals:
            if an.kind == 'wolf' and not an.dead:
                d = math.hypot(an.x - a.x, an.y - a.y)
                if d < fd and d <= det:
                    fd, foe, kind = d, an, 'wolf'
        if not foe:
            return False
        if fd <= rng:
            armor = 1 - .08 * self.civs[foe.civ].era if kind == 'agent' else 1
            base = 2.2 if a.role == 'soldier' else .8
            if kind == 'agent':
                foe.hp -= base * c.atk * armor * (1 if foe.role == 'soldier' else .6)
                foe.why = 'guerre'
                if foe.role == 'soldier' and fd <= 1.8:
                    a.hp -= 1.4 * self.civs[foe.civ].atk * (1 - .08 * c.era)
                    a.why = 'guerre'
                if foe.hp <= 0 and not foe.dead:
                    self.kill(foe, 'guerre')
                    a.kills += 1
                    self.add_rel(c.id, foe.civ, -2.5)
                    self.think(a, 'Un ennemi de moins… pour %s !' % c.name)
                if a.hp <= 0:
                    self.kill(a, 'guerre')
            else:
                foe.hp -= base * c.atk
                a.hp -= 1.2
                a.why = 'loup'
                if foe.hp <= 0:
                    foe.dead = True
                    a.kills += 1
                    self.say('%s abat un loup !' % a.name, c.color)
                if a.hp <= 0:
                    self.kill(a, 'loup')
            if rng > 2 and random.random() < .5:
                self.fx.append(['shot', a.x, a.y, 6, foe.x, foe.y])
            elif random.random() < .2:
                self.fx.append(['hit', foe.x, foe.y, 8])
            self.think(a, "À l'attaque !" if a.role == 'soldier' else 'Je défends les miens contre le loup !')
            a.act = 'combat'
        else:
            self.stepto(a, foe.x, foe.y)
            a.act = 'combat'
        return True

    # ───────── décision (IA utilitaire) ─────────
    def need(self, c, r):
        if r == 'metal' and 'tools' not in c.tech:
            return 0
        target = max(1, c.pop) * PER[r]
        v = clamp(1.6 - c.stock[r] / target, .05, 2.2)
        if c.stock[r] >= self.stock_cap(c) * .95:
            return 0
        return v * c.auto[r]

    def decide(self, a, c):
        night = self.night()
        tr = a.tr
        opts = []
        if a.hunger < 50:
            opts.append((160 - a.hunger * 1.6, 'eat', None))
        if a.thirst < 50:
            opts.append((160 - a.thirst * 1.6, 'drink', None))
        if a.energy < 25 or (night and a.energy < 90):
            opts.append(((75 + (100 - a.energy) * .6) if night else 130 - a.energy * 2, 'sleep', None))
        bw = self.bad_weather(a)
        if bw and not (a.role == 'soldier' and tr['courage'] > .7):
            opts.append((55 + (1 - tr['courage']) * 45, 'shelter', bw))
        if a.age < CHILD:
            opts.append((20, 'play', None))
        elif a is c.leader:
            opts.append((30, 'govern', None))
            opts.append((10 + tr['curio'] * 20, 'inspect', None))
        elif a.role == 'soldier':
            ar = c.army
            if ar['state'] in ('muster', 'march', 'siege'):
                opts.append((90, ar['state'], None))
            else:
                opts.append((30 + tr['courage'] * 15, 'patrol', None))
        else:
            dil = (.5 + tr['travail']) * (.7 + a.mood / 200)
            for r in RES:
                w = c.prio[r] * self.need(c, r)
                if w > 0:
                    opts.append((38 * dil * w, 'work', r))
        if tr['social'] > .15 and a.age >= CHILD:
            opts.append((tr['social'] * 26 + (22 if a.mood < 45 else 0), 'chat', None))
        opts.append((tr['curio'] * 16, 'explore', None))
        opts.append((8, 'wander', None))
        sc, kind, arg = max(opts, key=lambda o: o[0] + random.random() * 10)
        hx, hy = self.home_pos(a, c)
        if kind == 'eat' and c.stock['food'] < 3:
            self.think(a, "Les réserves sont vides : je cherche de quoi manger dehors.")
            self.start_work(a, c, 'food')
        elif kind == 'drink' and c.stock['water'] < 3:
            i = a.mem.get('water')
            if i is None or not self.water[i]:
                i = self.findres(a.x, a.y, 'water', 40)
            if i is None:
                self.go(a, a.x + random.randint(-6, 6), a.y + random.randint(-6, 6), 'wander', "Pas une goutte d'eau en vue…", act='autre')
            else:
                a.mem['water'] = i
                self.go(a, i % W, i // W, 'drinkat', 'Plus d\'eau au village : je vais boire à la source.', act='repas')
        elif kind == 'eat':
            self.go(a, c.cx, c.cy, 'eat', "J'ai faim, je rentre manger." if a.hunger > 20 else 'Je meurs de faim !', act='repas')
        elif kind == 'drink':
            self.go(a, c.cx, c.cy, 'drink', "J'ai soif, je vais boire." if a.thirst > 20 else 'Je dois boire, vite !', act='repas')
        elif kind == 'sleep':
            self.go(a, hx, hy, 'sleep', 'La nuit tombe, je rentre dormir.' if night else 'Je tombe de fatigue…', act='repos')
        elif kind == 'shelter':
            self.go(a, hx, hy, 'shelter', "Ce %s est trop violent, je m'abrite !" % arg, act='abri')
        elif kind == 'play':
            self.go(a, c.cx + random.randint(-6, 6), c.cy + random.randint(-6, 6), 'wander', 'Jouons près du village !', act='jeu')
        elif kind == 'govern':
            self.go(a, c.cx + random.randint(-2, 2), c.cy + random.randint(-2, 2), 'wander',
                    c.decree or ('Je dirige %s depuis le %s.' % (c.name, 'palais' if c.era else 'château')), act='gouverne')
        elif kind == 'inspect':
            self.go(a, c.cx + random.randint(-14, 14), c.cy + random.randint(-12, 12), 'wander',
                    "J'inspecte mon peuple et mes terres.", act='gouverne')
        elif kind in ('muster', 'march', 'siege'):
            self.army_order(a, c, kind)
        elif kind == 'patrol':
            self.go(a, c.cx + random.randint(-7, 7), c.cy + random.randint(-7, 7), 'wander', 'Je monte la garde.', act='garde')
        elif kind == 'chat':
            self.start_chat(a, c)
        elif kind == 'explore':
            ang = random.random() * 6.283
            d = random.randint(8, 22)
            tx, ty = a.x + math.cos(ang) * d, a.y + math.sin(ang) * d
            self.go(a, tx, ty, 'explore', random.choice(["Je me demande ce qu'il y a au-delà de l'horizon…",
                                                         'Je pars explorer de nouvelles terres.',
                                                         "Qui sait quelles richesses se cachent par là ?"]), act='explore')
        elif kind == 'work':
            self.start_work(a, c, arg)
        else:
            self.go(a, a.x + random.randint(-4, 4), a.y + random.randint(-4, 4), 'wander', random.choice(self.musings(a, c)), act='autre')

    def musings(self, a, c):
        out = ['Le temps passe vite en %d…' % self.year(), '%s, mon peuple, ma maison.' % c.name]
        if a.tr['courage'] > .65:
            out.append("Je rêve de gloire et de batailles.")
        if a.tr['social'] > .65:
            out.append("Quelle belle journée pour croiser des amis !")
        if a.tr['travail'] > .65:
            out.append("Il y a tant à faire, pas de temps à perdre.")
        if a.mood < 40:
            out.append("Rien ne va comme je voudrais…")
        if c.gov == 'dictature':
            out.append("Il vaut mieux se taire ces temps-ci.")
        elif c.gov == 'republique':
            out.append("Je voterai bientôt pour le prochain Consul.")
        else:
            out.append("Longue vie au Souverain !")
        return out

    def start_chat(self, a, c):
        best, bs = None, 0
        for o in self.near_agents(c.id, a.x, a.y, 12):
            if o is a or o.age < CHILD:
                continue
            s = a.friends.get(o.id, 0) + random.random() * .6
            if s > bs:
                best, bs = o, s
        if best:
            self.go(a, best.x, best.y, 'chat', 'Je vais voir %s pour discuter.' % best.name, reach=1, act='social')
            a.target = best.id
        else:
            self.go(a, a.x + random.randint(-4, 4), a.y + random.randint(-4, 4), 'wander', 'Personne à qui parler…', act='autre')

    def start_work(self, a, c, r):
        phr = {'food': ['Il faut nourrir le village.', 'Je cherche de quoi manger pour tous.'],
               'water': ["L'eau, c'est la vie. J'en rapporte."], 'wood': ['Le village a besoin de bois.'],
               'stone': ['Je vais chercher de la pierre pour bâtir.'], 'metal': ['Du métal pour nos outils et nos armes !']}
        if r == 'food' and 'agri' not in c.tech or (r == 'food' and random.random() < .3):
            deer = [an for an in self.animals if an.kind == 'deer' and not an.dead and abs(an.x - a.x) < 25 and abs(an.y - a.y) < 25]
            if deer and (a.tr['courage'] > .3 or random.random() < .3):
                an = random.choice(deer)
                a.target = an
                self.go(a, an.x, an.y, 'hunt', 'Un cerf ! Je tente ma chance à la chasse.', reach=1, act='food')
                return
        i = a.mem.get(r)
        ok = i is not None and (self.water[i] if r == 'water' else self.arr[r][i] >= 1) and abs(i % W - a.x) < 40 and abs(i // W - a.y) < 40
        if not ok:
            if self.nores_active(c, r):
                i = None
            else:
                i = self.findres(a.x, a.y, r, 32)
                if i is None:
                    c.nores[r] = self.t + 40
        if i is None:
            self.go(a, a.x + random.randint(-6, 6), a.y + random.randint(-6, 6), 'wander', 'Je ne trouve plus de %s par ici…' % RNAME[r].lower(), act='autre')
            return
        a.job = r
        a.mem[r] = i
        txt = random.choice(phr[r])
        if a.tr['courage'] > .6 and self.owner[i] not in (-1, c.id):
            txt = "Cette ressource est chez %s, mais j'oserai y aller." % self.civs[self.owner[i]].name
        self.go(a, i % W, i // W, 'gather', txt, act=r)

    def nores_active(self, c, r):
        return c.nores.get(r, 0) > self.t

    def army_order(self, a, c, st):
        ar = c.army
        e = self.civs[ar['enemy']] if ar['enemy'] is not None else None
        if st == 'muster' or e is None:
            rx, ry = ar['rally']
            self.go(a, rx + (a.id % 5) - 2, ry + (a.id // 5 % 5) - 2, 'rally', "Je rejoins l'armée au point de ralliement.", act='armée')
        else:
            off = ((a.id * 7) % 11 - 5, (a.id * 3) % 9 - 4)
            self.go(a, e.cx + off[0], e.cy + off[1], 'march', 'En avant, vers %s !' % e.name, act='armée')

    # ───────── actions ─────────
    def arrive(self, a, c):
        k = a.task
        if k == 'gather':
            a.state, a.cd = 'work', 3
        elif k == 'hunt':
            an = a.target
            if an is None or an.dead:
                a.state = 'idle'
            else:
                a.state, a.cd = 'work', 2
        elif k == 'deposit':
            if a.carry:
                r, n = a.carry
                c.stock[r] = min(self.stock_cap(c), c.stock[r] + n)
                a.carry = None
            a.state = 'idle'
        elif k == 'eat':
            need = (100 - a.hunger) / 100 * 6
            got = min(need, c.stock['food'])
            c.stock['food'] -= got
            a.hunger = min(100, a.hunger + got / 6 * 100)
            if got < need * .5:
                self.think(a, "Il n'y a presque plus de vivres !")
                a.mood -= 5
            else:
                self.think(a, 'Un bon repas, ça fait du bien.')
            a.state = 'idle'
        elif k == 'drink':
            need = (100 - a.thirst) / 100 * 5
            got = min(need, c.stock['water'])
            c.stock['water'] -= got
            a.thirst = min(100, a.thirst + got / 5 * 100)
            if got < need * .5:
                self.think(a, "L'eau manque cruellement…")
                a.mood -= 5
            a.state = 'idle'
        elif k == 'drinkat':
            a.thirst = 100
            a.state = 'idle'
        elif k == 'sleep':
            a.state = 'sleep'
            a.sheltered = False
        elif k == 'shelter':
            a.state, a.sheltered = 'sleep', True
        elif k == 'chat':
            o = self.byid.get(a.target)
            if o and not o.dead and abs(o.x - a.x) <= 2 and abs(o.y - a.y) <= 2:
                a.state, a.cd = 'work', 6
            else:
                a.state = 'idle'
        elif k == 'explore':
            self.scout(a, c)
            a.state = 'idle'
        elif k in ('rally', 'march'):
            a.state = 'idle'
        else:
            a.state = 'idle'

    def scout(self, a, c):
        found = []
        for r in ('food', 'wood', 'stone', 'metal'):
            i = self.findres(a.x, a.y, r, 7)
            if i is not None:
                a.mem[r] = i
                found.append(RNAME[r].lower())
        if 'water' in c.tech or True:
            i = self.findres(a.x, a.y, 'water', 7)
            if i is not None:
                a.mem['water'] = i
        self.think(a, ('Découverte : %s !' % ', '.join(found)) if found else 'Rien de notable par ici.')

    def finish(self, a, c):
        k = a.task
        if k == 'gather':
            i = a.ty * W + a.tx
            r = a.job
            cap = (5 + (3 if 'tools' in c.tech else 0) + (2 if 'metal' in c.tech else 0) + (4 if 'rail' in c.tech else 0)) * c.pm
            n = cap * 1.2 if (r == 'water' and self.water[i]) else (0 if r == 'water' else self.cut(i, r, cap))
            if n < 1:
                a.state = 'idle'
                a.mem.pop(r, None)
                return
            own = self.owner[i]
            if own not in (-1, c.id) and self.civs[own].alive:
                self.add_rel(c.id, own, -.15)
            if r == 'food' and a.hunger < 45:
                a.hunger = min(100, a.hunger + 35)
                n = max(0, n - 2)
                self.think(a, 'Je mange quelques baies sur place.')
            elif r == 'water' and a.thirst < 45:
                a.thirst = 100
            a.carry = (r, n)
            self.go(a, c.cx, c.cy, 'deposit', None, act=r)
        elif k == 'hunt':
            an = a.target
            if an is not None and not an.dead and abs(an.x - a.x) <= 2 and abs(an.y - a.y) <= 2:
                an.dead = True
                a.carry = ('food', 8 * c.pm)
                self.think(a, 'Chasse réussie ! Du gibier pour le village.')
                self.go(a, c.cx, c.cy, 'deposit', None, act='food')
            else:
                a.state = 'idle'
        elif k == 'chat':
            o = self.byid.get(a.target)
            if o and not o.dead:
                aff = a.friends.get(o.id, 0) + .12 + .1 * a.tr['social']
                a.friends[o.id] = min(1.0, aff)
                o.friends[a.id] = min(1.0, o.friends.get(a.id, 0) + .1)
                a.mood = min(100, a.mood + 6)
                o.mood = min(100, o.mood + 4)
                self.think(a, 'Bavarder avec %s me remonte le moral.' % o.name)
                if aff > .8 and o.state == 'idle':
                    self.think(o, '%s est un vrai ami.' % a.name)
            a.state = 'idle'
        else:
            a.state = 'idle'

    def cut(self, i, res, n):
        arr = self.arr[res]
        taken = min(arr[i], n)
        arr[i] -= taken
        if res == 'stone' and arr[i] < 1 and self.terr[i] == ROCK:
            self.terr[i] = SAND if self.biome[i] == 0 else GRASS
        if res == 'wood' and arr[i] < 1 and self.terr[i] == FOREST:
            self.terr[i] = GRASS
        self.touch(i)
        return taken

    # ───────── animaux ─────────
    def animals_tick(self):
        t = self.t
        for an in self.animals:
            an.ox, an.oy = an.x, an.y
            if an.dead:
                continue
            if an.life and t > an.life:
                an.dead = True
                continue
            if an.kind == 'deer':
                if t % 2 == 0:
                    fl = None
                    for c in self.civs:
                        for a in self.near_agents(c.id, an.x, an.y, 4):
                            fl = a
                            break
                        if fl:
                            break
                    if fl:
                        dx, dy = an.x - fl.x, an.y - fl.y
                        nx, ny = an.x + (dx > 0) - (dx < 0), an.y + (dy > 0) - (dy < 0)
                    elif random.random() < .25:
                        nx, ny = an.x + random.randint(-1, 1), an.y + random.randint(-1, 1)
                    else:
                        continue
                    if self.ok(nx, ny) and self.terr[ny * W + nx] != SAND:
                        an.x, an.y = nx, ny
            else:  # loup
                tgt, bd = None, 15
                for c in self.civs:
                    for a in self.near_agents(c.id, an.x, an.y, 15):
                        d = math.hypot(a.x - an.x, a.y - an.y)
                        if d < bd and not (a.state == 'sleep' and a.home):
                            tgt, bd = a, d
                if tgt:
                    if bd <= 1.5:
                        tgt.hp -= 2.5
                        tgt.why = 'loup'
                        if tgt.hp <= 0:
                            self.kill(tgt, 'loup')
                    else:
                        nx, ny = an.x + (tgt.x > an.x) - (tgt.x < an.x), an.y + (tgt.y > an.y) - (tgt.y < an.y)
                        if self.ok(nx, ny):
                            an.x, an.y = nx, ny
                elif random.random() < .3:
                    nx, ny = an.x + random.randint(-1, 1), an.y + random.randint(-1, 1)
                    if self.ok(nx, ny):
                        an.x, an.y = nx, ny
        if t % 40 == 0:
            self.animals = [a for a in self.animals if not a.dead]
            deer = [a for a in self.animals if a.kind == 'deer']
            if 0 < len(deer) < 90 and random.random() < .4 and not self.night():
                p = random.choice(deer)
                self.animals.append(Animal('deer', p.x, p.y))

    # ───────── météo ─────────
    def add_weather(self, kind, x, y, r=None, life=None):
        r = r or {'rain': 14, 'storm': 13, 'snow': 15, 'blizzard': 13, 'heat': 18, 'fog': 16, 'locust': 7, 'tornado': 3.2}[kind]
        life = life or {'rain': 600, 'storm': 450, 'snow': 700, 'blizzard': 450, 'heat': 700, 'fog': 600, 'locust': 500, 'tornado': 420}[kind]
        w = Wx(kind, x, y, r, life)
        if kind == 'tornado':
            ang = random.random() * 6.283
            w.vx, w.vy = math.cos(ang) * .25, math.sin(ang) * .25
        self.wx.append(w)
        return w

    def natural_weather(self):
        s = self.season()
        x, y = random.uniform(10, W - 10), random.uniform(10, H - 10)
        b = self.biome[int(y) * W + int(x)]
        tab = {
            0: {0: [('rain', .1), ('heat', .2), ('fog', .1)], 1: [('heat', .6), ('storm', .1)], 2: [('rain', .1), ('fog', .2)], 3: [('fog', .2)]},
            1: {0: [('rain', .5), ('fog', .3), ('storm', .15)], 1: [('storm', .3), ('rain', .25), ('heat', .15)],
                2: [('rain', .4), ('fog', .35), ('storm', .2)], 3: [('snow', .5), ('blizzard', .15), ('fog', .2)]},
            2: {0: [('rain', .3), ('fog', .3), ('snow', .2)], 1: [('storm', .3), ('rain', .25), ('fog', .2)],
                2: [('snow', .4), ('fog', .3), ('rain', .2)], 3: [('snow', .6), ('blizzard', .35)]},
        }[b][s]
        k = random.random()
        for kind, p in tab:
            k -= p * .6
            if k <= 0:
                self.add_weather(kind, x, y)
                return

    def weather_tick(self):
        if self.t % 40 == 0:
            a = math.atan2(self.wind[1], self.wind[0]) + random.uniform(-.4, .4)
            sp = clamp(math.hypot(*self.wind) + random.uniform(-.005, .005), .015, .06)
            self.wind = [math.cos(a) * sp, math.sin(a) * sp]
        for c in self.civs:
            if self.t % 10 == c.id:
                c.wx = {w.kind for w in self.wx if (w.x - c.cx) ** 2 + (w.y - c.cy) ** 2 < w.r * w.r}
        for w in self.wx[:]:
            w.life -= 1
            if w.kind == 'tornado':
                w.vx = clamp(w.vx + random.uniform(-.04, .04), -.4, .4)
                w.vy = clamp(w.vy + random.uniform(-.04, .04), -.4, .4)
                w.x += w.vx
                w.y += w.vy
            else:
                w.x += self.wind[0]
                w.y += self.wind[1]
            if w.life <= 0 or not (-20 < w.x < W + 20 and -20 < w.y < H + 20):
                self.wx.remove(w)
                continue
            k = w.kind
            for _ in range(5):
                ang, rr = random.random() * 6.283, math.sqrt(random.random()) * w.r
                x, y = int(w.x + math.cos(ang) * rr), int(w.y + math.sin(ang) * rr)
                if not (1 <= x < W - 1 and 1 <= y < H - 1):
                    continue
                i = y * W + x
                if k in ('rain', 'storm'):
                    if i in self.fire:
                        del self.fire[i]
                    if self.food[i] < self.mf[i]:
                        self.food[i] = min(self.mf[i], self.food[i] + self.mf[i] * .06)
                        self.touch(i) if int(self.food[i]) != int(self.food[i] - .5) else None
                    if self.wood[i] < self.mw[i]:
                        self.wood[i] = min(self.mw[i], self.wood[i] + self.mw[i] * .03)
                elif k == 'heat' and self.wood[i] >= 3 and random.random() < .0025 and i not in self.fire:
                    self.ignite(i)
                elif k == 'locust':
                    if self.food[i] > 0 or self.wood[i] > 0:
                        self.food[i] = 0
                        self.wood[i] *= .8
                        self.touch(i)
                elif k == 'tornado':
                    b = self.bld[i]
                    if b and b.type != 'town' and random.random() < .5:
                        self.remove_building(b)
                    if self.wood[i] > 0:
                        self.wood[i] = 0
                        if self.terr[i] == FOREST:
                            self.terr[i] = GRASS
                        self.touch(i)
            if k == 'storm' and random.random() < .04:
                ang, rr = random.random() * 6.283, math.sqrt(random.random()) * w.r
                self.strike(int(w.x + math.cos(ang) * rr), int(w.y + math.sin(ang) * rr), True)
            if k == 'locust':
                for c in self.civs:
                    if (w.x - c.cx) ** 2 + (w.y - c.cy) ** 2 < w.r * w.r:
                        c.stock['food'] = max(0, c.stock['food'] - .3)
            if k in ('blizzard', 'tornado') and self.t % 4 == 0:
                for c in self.civs:
                    if abs(w.x - c.cx) < w.r + 40:
                        for a in c.agents:
                            d2 = (a.x - w.x) ** 2 + (a.y - w.y) ** 2
                            if d2 < w.r * w.r and not (a.state == 'sleep' and a.home):
                                if k == 'blizzard':
                                    a.hp -= .5
                                    a.why = 'blizzard'
                                elif d2 < 12:
                                    a.hp -= 30
                                    a.why = 'tornade'
                                    a.x = clamp(a.x + random.randint(-5, 5), 1, W - 2)
                                    a.y = clamp(a.y + random.randint(-5, 5), 1, H - 2)
                                    a.state = 'idle'
                                if a.hp <= 0:
                                    self.kill(a)

    def temp_tick(self):
        tp = self.p['temp']
        if abs(tp) < .25:
            return
        for _ in range(300):
            i = random.randrange(N)
            if tp > 0 and self.terr[i] == SNOW and random.random() < tp * .3:
                self.terr[i] = ROCK
                self.touch(i)
            elif tp < 0 and self.terr[i] == ROCK and random.random() < -tp * .08:
                x, y = i % W, i // W
                if any(self.terr[(y + dy) * W + x + dx] == SNOW for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)) if 0 < x < W - 1 and 0 < y < H - 1):
                    self.terr[i] = SNOW
                    self.touch(i)

    # ───────── feu / lave / catastrophes ─────────
    def ignite(self, i):
        if i in self.fire or self.terr[i] in (WATER, DEEP, SAND, LAVA, SNOW) and not self.bld[i]:
            return
        self.fire[i] = random.randint(30, 70)

    def fire_tick(self):
        raining = {int(w.y) * W + int(w.x) for w in self.wx if w.kind in ('rain', 'storm')}
        for i in list(self.fire):
            life = self.fire[i] - 4
            x, y = i % W, i // W
            for c in self.civs:
                for a in self.near_agents(c.id, x, y, 1):
                    if a.x == x and a.y == y:
                        a.hp -= 18
                        a.why = 'incendie'
            b = self.bld[i]
            if b and b.type != 'town' and random.random() < .4:
                self.remove_building(b)
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                j = (y + dy) * W + x + dx
                if 0 < x + dx < W - 1 and 0 < y + dy < H - 1 and j not in self.fire and not self.burnt[j]:
                    flam = self.wood[j] >= 1 or self.bld[j] or (self.terr[j] == GRASS and random.random() < .1)
                    if flam and random.random() < .22:
                        self.fire[j] = random.randint(30, 70)
            if life <= 0 or self.rain_over(x, y):
                del self.fire[i]
                self.wood[i] = self.food[i] = 0
                self.mw[i] *= .4
                self.mf[i] *= .5
                if self.terr[i] == FOREST:
                    self.terr[i] = GRASS
                self.burnt[i] = 1
                self.touch(i)
            else:
                self.fire[i] = life

    def rain_over(self, x, y):
        for w in self.wx:
            if w.kind in ('rain', 'storm') and (w.x - x) ** 2 + (w.y - y) ** 2 < w.r * w.r and random.random() < .15:
                return True
        return False

    def lava_tick(self):
        for i in list(self.lava):
            self.lava[i] -= 3
            x, y = i % W, i // W
            for c in self.civs:
                for a in self.near_agents(c.id, x, y, 1):
                    if a.x == x and a.y == y:
                        a.hp = 0
                        a.why = 'lave'
                        self.kill(a)
            if self.lava[i] <= 0:
                del self.lava[i]
                self.terr[i] = ROCK
                self.stone[i] = 20
                if random.random() < .15:
                    self.metal[i] = 12
                self.touch(i)

    def pending_tick(self):
        for p in self.pending[:]:
            if self.t >= p[0]:
                self.pending.remove(p)
                if p[1] == 'meteor':
                    self.impact(p[2], p[3])
                elif p[1] == 'flood_end':
                    self.flood_end(p[2])
                elif p[1] == 'erupt':
                    self.erupt(p[2], p[3], p[4])

    def strike(self, x, y, natural=False):
        if not (0 < x < W - 1 and 0 < y < H - 1):
            return
        self.fx.append(['bolt', x, y, 10])
        i = y * W + x
        for c in self.civs:
            for a in self.near_agents(c.id, x, y, 2):
                if abs(a.x - x) <= 1 and abs(a.y - y) <= 1:
                    a.hp = 0
                    self.kill(a, 'foudre')
        b = self.bld[i]
        if b and b.type != 'town' and random.random() < .4:
            self.remove_building(b)
        if self.wood[i] >= 1 and random.random() < (.5 if not natural else .3):
            self.ignite(i)

    def impact(self, x, y):
        self.fx.append(['boom', x, y, 40])
        self.shake = 25
        for dy in range(-5, 6):
            for dx in range(-5, 6):
                xx, yy = x + dx, y + dy
                if not (1 <= xx < W - 1 and 1 <= yy < H - 1):
                    continue
                i, d = yy * W + xx, math.hypot(dx, dy)
                if d > 5:
                    continue
                b = self.bld[i]
                if b and b.type != 'town':
                    self.remove_building(b)
                if self.terr[i] in (WATER, DEEP):
                    continue
                if d <= 2.5:
                    self.terr[i] = LAVA
                    self.lava[i] = random.randint(150, 400)
                    self.wood[i] = self.food[i] = 0
                elif d <= 3.6:
                    self.terr[i] = ROCK
                    self.stone[i] = 25
                    self.metal[i] = 20 if random.random() < .5 else 0
                    self.wood[i] = self.food[i] = 0
                elif self.wood[i] >= 1:
                    self.ignite(i)
                self.touch(i)
        for c in self.civs:
            for a in self.near_agents(c.id, x, y, 7):
                if math.hypot(a.x - x, a.y - y) <= 6:
                    a.hp = 0
                    self.kill(a, 'météorite')
        self.say("Une météorite s'écrase en (%d,%d) !" % (x, y), (255, 160, 80))

    def erupt(self, x, y, left):
        if left <= 0:
            return
        for _ in range(6):
            ang, rr = random.random() * 6.283, random.random() * (2 + (30 - left) * .12)
            xx, yy = int(x + math.cos(ang) * rr), int(y + math.sin(ang) * rr)
            if 1 <= xx < W - 1 and 1 <= yy < H - 1:
                i = yy * W + xx
                if self.terr[i] not in (WATER, DEEP):
                    self.terr[i] = LAVA
                    self.lava[i] = random.randint(120, 320)
                    self.wood[i] = self.food[i] = 0
                    b = self.bld[i]
                    if b and b.type != 'town':
                        self.remove_building(b)
                    self.touch(i)
        self.fx.append(['smoke', x, y, 30])
        self.pending.append((self.t + 5, 'erupt', x, y, left - 1))

    def flood(self, x, y, r=8):
        saved = {}
        for dy in range(-r, r + 1):
            for dx in range(-r, r + 1):
                xx, yy = x + dx, y + dy
                if 1 <= xx < W - 1 and 1 <= yy < H - 1 and math.hypot(dx, dy) <= r + random.random() * 2 - 1:
                    i = yy * W + xx
                    if self.terr[i] in (WATER, DEEP, LAVA):
                        continue
                    b = self.bld[i]
                    if b and b.type == 'town':
                        continue
                    if b:
                        self.remove_building(b)
                    saved[i] = (self.terr[i], self.food[i], self.wood[i], self.mf[i], self.mw[i])
                    self.terr[i], self.water[i] = WATER, 1
                    self.food[i] = self.wood[i] = 0
                    self.fire.pop(i, None)
                    self.touch(i)
        for c in self.civs:
            for a in c.agents:
                if math.hypot(a.x - x, a.y - y) <= r:
                    a.hp -= 40
                    a.why = 'inondation'
                    if a.hp <= 0:
                        self.kill(a)
        self.floods.append(saved)
        self.pending.append((self.t + 400, 'flood_end', len(self.floods) - 1))
        self.say('INONDATION à (%d,%d)' % (x, y), (120, 190, 255))

    def flood_end(self, k):
        for i, (tt, f, w, mf, mw) in self.floods[k].items():
            if self.terr[i] == WATER:
                self.terr[i], self.water[i] = tt, 0
                self.food[i], self.wood[i], self.mf[i], self.mw[i] = f, w, mf, mw
                self.touch(i)
        self.floods[k] = {}

    def quake(self, x, y, r=14):
        self.shake = 30
        for c in self.civs:
            for b in list(c.buildings):
                if b.type != 'town' and math.hypot(b.x - x, b.y - y) <= r and random.random() < .45:
                    self.remove_building(b)
            for a in c.agents:
                if math.hypot(a.x - x, a.y - y) <= r and random.random() < .3:
                    a.hp -= 30
                    a.why = 'séisme'
                    if a.hp <= 0:
                        self.kill(a)
        for _ in range(40):
            xx, yy = x + random.randint(-r, r), y + random.randint(-r, r)
            if 1 <= xx < W - 1 and 1 <= yy < H - 1:
                self.fx.append(['crack', xx, yy, 60])
        self.say('SÉISME en (%d,%d) !' % (x, y), (255, 160, 100))

    def natural_disaster(self):
        x, y = random.randint(15, W - 15), random.randint(15, H - 15)
        k = random.choice(['quake', 'meteor', 'locust', 'wolves', 'drought'])
        self.power(k, x, y, random.choice(self.civs), 1)

    # ───────── pousse / ressources ─────────
    def regrow(self):
        s = self.season()
        sf = (1.3, 1.0, .7, 0.0)[s] * self.p['fert']
        tp = self.p['temp']
        for i in self.grow:
            b = self.biome[i]
            f = sf
            if s == 3 and b == 1:
                f = .2 * self.p['fert']
            if b == 0:
                f *= .5
            if tp < -.3:
                f *= max(0, 1 + tp)
            if self.drought[b] > self.t:
                f = 0
            if self.burnt[i]:
                if random.random() < .04:
                    self.burnt[i] = 0
                    self.touch(i)
                else:
                    continue
            if f <= 0:
                continue
            if self.food[i] < self.mf[i]:
                old = int(self.food[i])
                self.food[i] = min(self.mf[i], self.food[i] + self.mf[i] * .03 * f)
                if int(self.food[i]) != old:
                    self.touch(i)
            if self.wood[i] < self.mw[i]:
                old = int(self.wood[i])
                self.wood[i] = min(self.mw[i], self.wood[i] + self.mw[i] * .012 * f)
                if int(self.wood[i]) != old:
                    self.touch(i)
                if self.mw[i] >= 8 and b != 0 and self.terr[i] in (GRASS, FOREST):
                    nt = FOREST if self.wood[i] >= self.mw[i] * .5 else GRASS
                    if nt != self.terr[i]:
                        self.terr[i] = nt
                        self.touch(i)

    def territory(self):
        new = [-1] * N
        best = [1e9] * N
        for c in self.civs:
            if not c.alive:
                continue
            src = [(c.cx, c.cy, 16 + min(12, c.pop // 8))] + [(b.x, b.y, 5) for b in c.buildings if b.type != 'town']
            for sx, sy, r in src:
                r2 = r * r
                for y in range(max(1, sy - r), min(H - 1, sy + r + 1)):
                    for x in range(max(1, sx - r), min(W - 1, sx + r + 1)):
                        d = (x - sx) ** 2 + (y - sy) ** 2
                        if d <= r2:
                            i = y * W + x
                            if d < best[i] and self.terr[i] not in (DEEP, WATER):
                                best[i], new[i] = d, c.id
        old = self.owner
        for i in range(N):
            if old[i] != new[i]:
                self.dirty.add(i)
                for j in (i - 1, i + 1, i - W, i + W):
                    if 0 <= j < N:
                        self.dirty.add(j)
        self.owner = new

    # ───────── civilisation ─────────
    def civ_tick(self, c):
        c.agents = [a for a in c.agents if not a.dead]
        pop = c.pop
        if pop == 0:
            c.alive = False
            self.say("La civilisation %s s'éteint…" % c.name, (255, 90, 90))
            return
        st, b, t = c.stock, c.biome, self.t
        s = self.season()
        if t % 10 == c.id:
            need_h = 0.0
            tp = self.p['temp']
            if s == 3:
                need_h = pop * .012 * (2 if b == 2 else .4 if b == 0 else 1) * clamp(1 - .6 * tp, .3, 1.8) * 10
            elif s == 2 and b == 2:
                need_h = pop * .005 * 10
            if 'blizzard' in c.wx or 'snow' in c.wx:
                need_h *= 1.5
            if 'elec' in c.tech:
                need_h *= .4
            cold = st['wood'] < need_h
            st['wood'] = max(0, st['wood'] - need_h)
            c.flags = set()
            if st['food'] < 1:
                c.flags.add('FAIM')
            if st['water'] < 1:
                c.flags.add('SOIF')
            if cold and need_h > 0:
                c.flags.add('FROID')
            if self.war_any(c):
                c.flags.add('GUERRE')
        self.produce(c, s)
        cap = self.stock_cap(c)
        for r in RES:
            st[r] = min(cap, st[r])
        # technologies / ères
        g = GOV[c.gov]
        if t % 20 == c.id:
            c.pm = g['prod'] * (1.3 if 'steam' in c.tech else 1) * (1.2 if 'elec' in c.tech else 1) * (1.15 if 'comp' in c.tech else 1)
            c.atk = (1 + (.7 if 'metal' in c.tech else 0) + (.3 if 'chiv' in c.tech else 0) + (.8 if 'gunp' in c.tech else 0)
                     + (1.0 if 'rifle' in c.tech else 0) + (1.5 if 'tank' in c.tech else 0))
            ne = c.era
            e0 = sum(1 for k, v in TECH.items() if v[4] == 0 and k in c.tech)
            e1 = sum(1 for k, v in TECH.items() if v[4] == 1 and k in c.tech)
            e2 = sum(1 for k, v in TECH.items() if v[4] == 2 and k in c.tech)
            ne = 3 if e2 >= 3 else 2 if e1 >= 3 else 1 if e0 >= 5 else 0
            while ne > 0 and self.year() < ERA_START[ne] - 50:
                ne -= 1
            ne = max(ne, c.era)
            if ne > c.era:
                c.era = ne
                self.say('%s entre dans l\'ère : %s (%d)' % (c.name, ERAS[ne], self.year()), c.color)
        if c.research is None or c.research in c.tech:
            c.research = None
            y = self.year()
            for k in c.order:
                tk = TECH[k]
                if k not in c.tech and all(q in c.tech for q in tk[2]) and y >= ERA_START[tk[4]] - 120:
                    c.research = k
                    break
        if c.research:
            rate = pop * .012 * self.p['research'] * g['res'] * (1.25 if 'print' in c.tech else 1) * (1.5 if 'comp' in c.tech else 1)
            rate *= 1 + .5 * self.count(c, 'academy', True)
            if c.leader:
                rate *= .9 + .2 * c.leader.tr['curio']
            c.rp += rate
            if c.rp >= TECH[c.research][1]:
                c.rp = 0
                c.tech.add(c.research)
                self.say('%s découvre : %s' % (c.name, TECH[c.research][0]), c.color)
                c.research = None
        # naissances
        if pop < self.cap(c) and st['food'] > pop * 4 and st['water'] > pop * 3 and random.random() < .001 * pop * self.p['birth']:
            ads = [a for a in c.agents if a.age >= CHILD * 1.5]
            if len(ads) >= 2:
                p1, p2 = random.sample(ads, 2)
                self.add_agent(c, c.cx + random.randint(-1, 1), c.cy + random.randint(-1, 1), 0, p1, p2)
        for bd in c.buildings:
            if not bd.done:
                bd.prog += 1 + pop / 10
                if bd.prog >= BDEF[bd.type][2]:
                    bd.done = True
                    self.touch(bd.y * W + bd.x)
        if t % 15 == c.id:
            self.think_build(c)
        if t % 30 == c.id:
            self.assign_soldiers(c)
        if t % 60 == c.id:
            self.leader_think(c)
        if t % 20 == c.id:
            self.gov_tick(c)
        if t % 10 == c.id:
            self.army_tick(c)
        if t % 100 == c.id * 7 and c.dc:
            self.say('%s : %s' % (c.name, ', '.join('%d mort(s) de %s' % (n, w) for w, n in c.dc.items())), (200, 150, 150))
            c.dc = {}

    def produce(self, c, s):
        st, b = c.stock, c.biome
        dr = self.drought[b] > self.t
        pm = c.pm
        for bd in c.buildings:
            if not bd.done:
                continue
            ty = bd.type
            if ty == 'farm':
                m = (.9, 1.1, 1.4, .1)[s] * (.55, 1.2, .6)[b] * (1.5 if 'irrig' in c.tech else 1) * (.4 if dr else 1) * (1.2 if 'elec' in c.tech else 1)
                if b == 0 and 'irrig' not in c.tech:
                    if st['water'] >= .05:
                        st['water'] -= .05
                    else:
                        m *= .3
                st['food'] += .22 * m * pm
            elif ty == 'well':
                st['water'] += .35 * (.6 if dr else 1) * pm
            elif ty == 'sawmill' and self.t % 10 == bd.x % 10:
                i = self.findres(bd.x, bd.y, 'wood', 9)
                if i is not None:
                    st['wood'] += self.cut(i, 'wood', 2 * pm)
            elif ty == 'mine' and self.t % 10 == bd.y % 10:
                i = self.findres(bd.x, bd.y, 'stone', 10)
                if i is not None:
                    st['stone'] += self.cut(i, 'stone', 2 * pm)
                if 'metal' in c.tech:
                    j = self.findres(bd.x, bd.y, 'metal', 12)
                    if j is not None:
                        st['metal'] += self.cut(j, 'metal', 1 * pm)
            elif ty == 'factory' and self.t % 10 == bd.x % 10:
                st['metal'] += .8 * pm
                st['stone'] += .8 * pm
                st['wood'] += .5 * pm

    def think_build(self, c):
        st, pop, cap = c.stock, c.pop, self.cap(c)
        if sum(1 for b in c.buildings if not b.done) >= 2:
            return
        n = lambda t: self.count(c, t)
        want = []
        if pop >= cap - 1:
            want.append('house')
        if (c.biome == 0 and n('well') < 1) or (st['water'] < pop * 6 and n('well') < min(8, 1 + pop // 8)):
            want.append('well')
        if 'mason' in c.tech and n('govt') < 1:
            want.append('govt')
        if 'agri' in c.tech and n('farm') < min(20, math.ceil(pop / 4)) and st['food'] < pop * 12:
            want.append('farm')
        if st['wood'] < pop * 4 and n('sawmill') < 3 and c.biome != 0:
            want.append('sawmill')
        if 'tools' in c.tech and n('mine') < (4 if c.biome == 2 else 2) and (st['stone'] < pop * 4 or st['metal'] < 5):
            want.append('mine')
        if max(st.values()) > self.stock_cap(c) * .85 and n('warehouse') < 4:
            want.append('warehouse')
        if 'print' in c.tech and n('academy') < 2 and pop > 30:
            want.append('academy')
        if 'steam' in c.tech and n('factory') < 3 and pop > 40:
            want.append('factory')
        if 'metal' in c.tech and n('barracks') < 1 + pop // 60 and (c.prio['military'] > .15 or self.war_any(c) or GOV[c.gov]['army'] > .2):
            want.append('barracks')
        for t in want:
            if self.try_build(c, t):
                break

    def assign_soldiers(self, c):
        g = GOV[c.gov]
        has = any(b.type == 'barracks' and b.done for b in c.buildings)
        frac = 0.0
        if has:
            frac = min(g['army'] * (1.3 if self.war_any(c) else 1), max(c.prio['military'] * .4, c.auto['military'] * g['army'] * .8))
        want = int(c.pop * frac)
        sol = [a for a in c.agents if a.role == 'soldier']
        if len(sol) < want:
            cands = [a for a in c.agents if a.role == 'worker' and a.age >= CHILD and a is not c.leader and a.carry is None]
            cands.sort(key=lambda a: -a.tr['courage'])
            for a in cands[:want - len(sol)]:
                a.role, a.state = 'soldier', 'idle'
                self.think(a, "Je m'enrôle dans l'armée de %s." % c.name)
        elif len(sol) > want:
            for a in sol[want:]:
                a.role, a.state = 'worker', 'idle'
                self.think(a, 'Je rends les armes et reprends le travail.')
        sol = [a for a in c.agents if a.role == 'soldier']
        for k, a in enumerate(sorted(sol, key=lambda a: (-a.kills, -a.tr['courage']))):
            a.rank = 2 if k == 0 else 1 if k % 8 == 0 else 0

    # ───────── gouvernement ─────────
    def title(self, c):
        if c.gov == 'republique':
            return 'Président' if c.era >= 2 else 'Consul'
        return GOV[c.gov]['title']

    def elect(self, c, silent=False):
        ads = [a for a in c.agents if a.age >= CHILD * 1.5 and not a.dead]
        if not ads:
            return
        old = c.leader
        if old:
            old.title = ''
        if c.gov == 'republique':
            new = max(ads, key=lambda a: a.tr['social'] * .4 + a.tr['travail'] * .3 + a.tr['courage'] * .1 + a.mood / 300 + random.random() * .25)
        elif c.gov == 'monarchie':
            heirs = [a for a in ads if old and old.id in a.parents]
            new = max(heirs or ads, key=lambda a: a.age + random.random() * 200)
        else:
            sol = [a for a in ads if a.role == 'soldier'] or ads
            new = max(sol, key=lambda a: a.tr['courage'] * .6 + a.kills * .05 + a.tr['travail'] * .1 + random.random() * .2)
        if new.role == 'soldier':
            new.role = 'worker'
        c.leader = new
        new.title = self.title(c)
        c.next_elect = self.t + 1600
        self.think(new, ('Le peuple m\'a choisi pour le guider.' if c.gov == 'republique' else
                         'Le trône me revient désormais.' if c.gov == 'monarchie' else 'Le pouvoir est à moi. Que nul ne s\'y oppose.'))
        if not silent:
            verb = {'republique': 'élit', 'monarchie': 'couronne', 'dictature': 'subit le coup de force de'}[c.gov]
            self.say('%s %s %s (%s)' % (c.name, verb, new.name, new.title), c.color)

    def gov_tick(self, c):
        ags = c.agents
        if not ags:
            return
        c.mood = sum(a.mood for a in ags) / len(ags)
        c.unrest = c.unrest + 18 if c.mood < 34 else max(0, c.unrest - 12)
        if c.leader is None or c.leader.dead:
            self.elect(c)
        elif c.gov == 'republique' and self.t >= c.next_elect:
            self.elect(c)
        if c.unrest >= 300:
            self.revolution(c)

    def revolution(self, c, new=None, forced=False):
        old = c.gov
        new = new or random.choice([g for g in GOV if g != old])
        c.gov, c.unrest, c.mood = new, 0, 55
        for a in c.agents:
            a.mood = max(a.mood, 50)
        sol = [a for a in c.agents if a.role == 'soldier']
        for a in sol[:len(sol) // 5]:
            a.hp -= 100
            a.why = 'guerre civile'
            self.kill(a)
        why = 'Réforme' if forced else 'RÉVOLUTION'
        self.say('%s à %s : %s → %s' % (why, c.name, GOV[old]['name'], GOV[new]['name']), (255, 210, 90))
        self.elect(c)
        for b in c.buildings:
            if b.type == 'govt':
                self.touch(b.y * W + b.x)

    def leader_think(self, c):
        pop = max(1, c.pop)
        notes = []
        for r in RES:
            ratio = c.stock[r] / (pop * PER[r])
            c.auto[r] = clamp(1.8 - ratio, .6, 1.6)
            if ratio < .5 and r != 'metal':
                notes.append(RNAME[r].lower())
        at_war = self.war_any(c)
        bad = [o for o in self.civs if o is not c and o.alive and self.rel[c.id][o.id] < -40]
        c.auto['military'] = 1.0 if (at_war or bad) else (.7 if c.gov == 'dictature' else .4 if c.gov == 'monarchie' else .35)
        if at_war:
            c.decree = 'Décret : tout pour la guerre !'
        elif notes:
            c.decree = 'Décret : priorité à %s.' % notes[0]
        elif bad:
            c.decree = 'Décret : renforcer nos défenses.'
        else:
            c.decree = ''
        if c.leader:
            self.think(c.leader, c.decree or 'Le royaume est en paix et prospère.' if c.gov == 'monarchie' else (c.decree or 'Le peuple est prospère.'))

    # ───────── armée ─────────
    def army_tick(self, c):
        ar = c.army
        sol = [a for a in c.agents if a.role == 'soldier']
        enemy = self.war_target(c)
        stt = ar['state']
        if stt == 'garrison':
            if enemy and len(sol) >= 5 and self.t >= ar['cool']:
                dx, dy = enemy.cx - c.cx, enemy.cy - c.cy
                d = math.hypot(dx, dy) or 1
                ar.update(state='muster', enemy=enemy.id, t0=self.t, rally=(int(c.cx + dx / d * 12), int(c.cy + dy / d * 12)))
                self.say("%s mobilise son armée (%d soldats) contre %s" % (c.name, len(sol), enemy.name), c.color)
                for a in sol:
                    if a.state != 'sleep':
                        a.state = 'idle'
        elif stt == 'muster':
            if not enemy or enemy.id != ar['enemy']:
                ar['state'] = 'garrison'
                return
            rx, ry = ar['rally']
            near = sum(1 for a in sol if abs(a.x - rx) < 8 and abs(a.y - ry) < 8)
            if near >= .7 * len(sol) or self.t - ar['t0'] > 250:
                ar.update(state='march', n0=len(sol))
                self.say("L'armée de %s marche sur %s !" % (c.name, enemy.name), c.color)
                for a in sol:
                    a.state = 'idle'
        elif stt in ('march', 'siege'):
            if not enemy or enemy.id != ar['enemy']:
                ar['state'] = 'garrison'
                return
            if len(sol) < .3 * ar['n0']:
                ar.update(state='garrison', cool=self.t + 400)
                self.say("L'armée de %s bat en retraite." % c.name, (255, 150, 120))
                return
            present = [a for a in sol if abs(a.x - enemy.cx) < 10 and abs(a.y - enemy.cy) < 10]
            if stt == 'march' and len(present) >= max(3, .4 * len(sol)):
                ar.update(state='siege', t1=self.t)
                self.say('%s assiège la capitale de %s !' % (c.name, enemy.name), (255, 120, 90))
            elif stt == 'siege':
                defenders = [x for x in enemy.agents if x.role == 'soldier' and abs(x.x - enemy.cx) < 14 and abs(x.y - enemy.cy) < 14]
                bs = [b for b in enemy.buildings if b.type != 'town']
                if bs and random.random() < .35:
                    self.remove_building(random.choice(bs))
                r = max(RES, key=lambda k: enemy.stock[k])
                n = min(10, enemy.stock[r])
                enemy.stock[r] -= n
                c.stock[r] += n
                if len(defenders) <= .2 * len(present) and self.t - ar['t1'] > 60:
                    self.capitulate(c, enemy)

    def capitulate(self, c, e):
        for r in RES:
            n = e.stock[r] * .4
            e.stock[r] -= n
            c.stock[r] = min(self.stock_cap(c), c.stock[r] + n)
        e.mood -= 25
        for a in e.agents:
            a.mood -= 20
        e.unrest += 150
        self.say('%s PREND la capitale de %s ! %s capitule et paie un tribut.' % (c.name, e.name, e.name), (255, 90, 90))
        self.make_peace(c.id, e.id, True)
        self.set_rel(c.id, e.id, -35)
        c.army['cool'] = self.t + 600

    def diplomacy(self):
        for a in range(3):
            for b in range(a + 1, 3):
                ca, cb = self.civs[a], self.civs[b]
                if not (ca.alive and cb.alive):
                    continue
                r = self.rel[a][b]
                if self.war[a][b] is None:
                    if ca.flags & {'FAIM', 'SOIF'} or cb.flags & {'FAIM', 'SOIF'}:
                        self.add_rel(a, b, -1)
                    self.set_rel(a, b, self.rel[a][b] * .99)
                    aggr = (GOV[ca.gov]['aggr'] + GOV[cb.gov]['aggr']) * self.p['aggr']
                    if ca.leader and cb.leader:
                        aggr += (ca.leader.tr['courage'] + cb.leader.tr['courage'] - 1) * .3
                    if r < -55 and random.random() < max(0, aggr) * .2:
                        self.declare_war(a, b)
                else:
                    self.add_rel(a, b, .5)
                    dur = self.t - self.war[a][b]
                    wp = getattr(self, 'war_pop', {})
                    if (ca.pop < .5 * wp.get(a, 0) or cb.pop < .5 * wp.get(b, 0) or min(ca.pop, cb.pop) < 4
                            or (dur > 1800 and random.random() < .06) or self.rel[a][b] > -20):
                        self.make_peace(a, b)

    def trade(self):
        for a in range(3):
            for b in range(a + 1, 3):
                ca, cb = self.civs[a], self.civs[b]
                if not (ca.alive and cb.alive) or self.at_war(a, b) or self.rel[a][b] < -20:
                    continue
                if 'trade' not in ca.tech or 'trade' not in cb.tech:
                    continue
                surplus = lambda c, r: c.stock[r] - c.pop * PER[r] * 1.3
                lack = lambda c, r: c.pop * PER[r] * .8 - c.stock[r]
                give_a = max((min(surplus(ca, r), lack(cb, r)), r) for r in RES)
                give_b = max((min(surplus(cb, r), lack(ca, r)), r) for r in RES)
                if give_a[0] < 3 or give_b[0] < 3:
                    continue
                n = min(20, give_a[0], give_b[0])
                ra, rb = give_a[1], give_b[1]
                ca.stock[ra] -= n
                cb.stock[ra] += n
                cb.stock[rb] -= n
                ca.stock[rb] += n
                self.add_rel(a, b, 4)
                self.carav.append([ca, cb, 0.0])
                self.carav.append([cb, ca, 0.0])
                self.say('Commerce %s ↔ %s : %d %s contre %d %s' % (ca.name, cb.name, n, RNAME[ra].lower(), n, RNAME[rb].lower()), (240, 210, 120))

    # ───────── pouvoirs du joueur ─────────
    def brush(self, kind, x, y, size, c):
        for dy in range(-size + 1, size):
            for dx in range(-size + 1, size):
                xx, yy = x + dx, y + dy
                if not (1 <= xx < W - 1 and 1 <= yy < H - 1) or dx * dx + dy * dy > (size - .5) ** 2:
                    continue
                self.paint(kind, xx, yy)

    def paint(self, kind, x, y):
        i = y * W + x
        b = self.bld[i]
        if kind in ('deep', 'water') and b and b.type == 'town':
            return
        if kind in ('deep', 'water', 'sand', 'grass', 'mountain', 'ice', 'forest', 'lava'):
            if b and b.type == 'town':
                return
            if b:
                self.remove_building(b)
            self.fire.pop(i, None)
            self.lava.pop(i, None)
            self.burnt[i] = 0
            self.food[i] = self.wood[i] = self.stone[i] = self.metal[i] = 0
            self.mf[i] = self.mw[i] = 0
            self.water[i] = 0
            if kind == 'deep':
                self.terr[i] = DEEP
            elif kind == 'water':
                self.terr[i], self.water[i] = WATER, 1
            elif kind == 'sand':
                self.terr[i] = SAND
            elif kind == 'grass':
                self.terr[i] = GRASS
                if random.random() < .06:
                    self.food[i] = self.mf[i] = 6
                    self.add_grow(i)
            elif kind == 'forest':
                self.terr[i] = FOREST
                self.wood[i] = self.mw[i] = 16 + random.random() * 6
                self.add_grow(i)
            elif kind == 'mountain':
                self.terr[i], self.stone[i] = ROCK, 30
                if random.random() < .08:
                    self.metal[i] = 15
            elif kind == 'ice':
                self.terr[i], self.stone[i] = SNOW, 30
            elif kind == 'lava':
                self.terr[i] = LAVA
                self.lava[i] = random.randint(200, 500)
            self.touch(i)
            for j in (i - 1, i + 1, i - W, i + W):
                self.touch(j)
        elif kind == 'berries' and PASS[self.terr[i]] and not self.water[i] and self.terr[i] != LAVA:
            self.mf[i] = max(self.mf[i], 8)
            self.food[i] = self.mf[i]
            self.add_grow(i)
            self.touch(i)
        elif kind == 'ore' and PASS[self.terr[i]] and not self.water[i]:
            self.metal[i] = 18
            self.touch(i)
        elif kind == 'rock' and PASS[self.terr[i]] and not self.water[i]:
            self.stone[i] = 25
            self.touch(i)
        elif kind == 'erase':
            if b and b.type != 'town':
                self.remove_building(b)
            self.fire.pop(i, None)
            for cv in self.civs:
                for a in self.near_agents(cv.id, x, y, 1):
                    if a.x == x and a.y == y:
                        self.kill(a, 'divin')
            for an in self.animals:
                if an.x == x and an.y == y:
                    an.dead = True

    def power(self, kind, x, y, c, size=1, btype='house'):
        i = y * W + x
        if kind in ('rain', 'storm', 'snow', 'blizzard', 'heat', 'fog', 'locust', 'tornado'):
            self.add_weather(kind, x, y)
            nm = {'rain': 'Pluie', 'storm': 'Orage', 'snow': 'Neige', 'blizzard': 'Blizzard', 'heat': 'Canicule', 'fog': 'Brouillard',
                  'locust': 'Nuée de criquets', 'tornado': 'Tornade'}[kind]
            self.say('%s invoqué(e) en (%d,%d)' % (nm, x, y), (170, 200, 255))
        elif kind == 'clear':
            self.wx = [w for w in self.wx if math.hypot(w.x - x, w.y - y) > w.r + 8]
            self.drought = [0, 0, 0]
        elif kind == 'bolt':
            self.strike(x, y)
        elif kind == 'meteor':
            self.pending.append((self.t + 14, 'meteor', x, y))
            self.fx.append(['meteor', x, y, 14])
        elif kind == 'quake':
            self.quake(x, y)
        elif kind == 'volcano':
            for dy in range(-4, 5):
                for dx in range(-4, 5):
                    xx, yy = x + dx, y + dy
                    d = math.hypot(dx, dy)
                    if 1 <= xx < W - 1 and 1 <= yy < H - 1 and d <= 4 and self.terr[yy * W + xx] not in (WATER, DEEP):
                        j = yy * W + xx
                        bb = self.bld[j]
                        if bb and bb.type != 'town':
                            self.remove_building(bb)
                        self.terr[j] = ROCK if d > 1.5 else SNOW if False else ROCK
                        self.stone[j] = 40
                        self.wood[j] = self.food[j] = 0
                        self.touch(j)
            self.pending.append((self.t + 1, 'erupt', x, y, 30))
            self.shake = 20
            self.say('UN VOLCAN entre en éruption en (%d,%d) !' % (x, y), (255, 110, 50))
        elif kind == 'flood':
            self.flood(x, y)
        elif kind == 'fire':
            for dy in range(-2, 3):
                for dx in range(-2, 3):
                    j = (y + dy) * W + x + dx
                    if 0 < x + dx < W - 1 and 0 < y + dy < H - 1 and self.terr[j] not in (WATER, DEEP, LAVA):
                        self.fire[j] = random.randint(40, 80)
            self.say('Un incendie se déclare en (%d,%d)' % (x, y), (255, 120, 60))
        elif kind == 'plague':
            for cv in self.civs:
                for a in cv.agents:
                    if math.hypot(a.x - x, a.y - y) <= 10 and random.random() < .6:
                        a.hp -= 80 * (.2 if 'vacc' in cv.tech else .5 if 'med' in cv.tech else 1)
                        a.why = 'épidémie'
                        if a.hp <= 0:
                            self.kill(a)
            self.say('ÉPIDÉMIE près de (%d,%d)' % (x, y), (180, 255, 120))
        elif kind == 'drought':
            b = self.biome[i]
            self.drought[b] = self.t + 500
            self.say('SÉCHERESSE sur la région « %s »' % BIOMES[b].lower(), (255, 190, 80))
        elif kind == 'wolves':
            for _ in range(4):
                self.animals.append(Animal('wolf', x + random.randint(-2, 2), y + random.randint(-2, 2), life=self.t + 1500))
            self.say('Une meute de loups rôde en (%d,%d)' % (x, y), (200, 200, 220))
        elif kind == 'deer':
            for _ in range(5):
                self.animals.append(Animal('deer', x + random.randint(-2, 2), y + random.randint(-2, 2)))
        elif kind == 'villager':
            if c.alive and self.ok(x, y):
                self.add_agent(c, x, y, age=random.randint(700, 1500))
        elif kind == 'group':
            for _ in range(6):
                if c.alive:
                    self.add_agent(c, x + random.randint(-2, 2), y + random.randint(-2, 2), age=random.randint(700, 1500))
        elif kind in ('bless', 'heal'):
            for cv in self.civs:
                for a in cv.agents:
                    if math.hypot(a.x - x, a.y - y) <= 7:
                        a.hp = 100
                        if kind == 'bless':
                            a.hunger = a.thirst = a.energy = 100
                            a.mood = 100
                            self.think(a, 'Je sens une présence bienveillante veiller sur nous…')
            self.fx.append(['bless', x, y, 40])
        elif kind == 'manna':
            for dy in range(-5, 6):
                for dx in range(-5, 6):
                    xx, yy = x + dx, y + dy
                    if 1 <= xx < W - 1 and 1 <= yy < H - 1 and math.hypot(dx, dy) <= 5 and random.random() < .5:
                        self.paint('berries', xx, yy)
            self.fx.append(['bless', x, y, 40])
        elif kind == 'build':
            if not self.try_build(c, btype, x, y):
                return 'Impossible : ressources, technologie ou emplacement'
        elif kind == 'demolish':
            b = self.bld[i]
            if b and b.type != 'town':
                self.remove_building(b)
        elif kind in ('deep', 'water', 'sand', 'grass', 'forest', 'mountain', 'ice', 'lava', 'berries', 'ore', 'rock', 'erase'):
            self.brush(kind, x, y, size, c)
        return None

    def gift(self, c):
        for r in RES:
            c.stock[r] = min(self.stock_cap(c), c.stock[r] + 30)
        self.say('Offrande divine pour %s (+30 de chaque)' % c.name, c.color)

    def ev_ore(self, c):
        k = 0
        for _ in range(80):
            x, y = c.cx + random.randint(-18, 18), c.cy + random.randint(-14, 14)
            if 2 <= x < W - 2 and 2 <= y < H - 2:
                i = y * W + x
                if PASS[self.terr[i]] and not self.water[i] and self.bld[i] is None and math.hypot(x - c.cx, y - c.cy) > 6:
                    if self.terr[i] != SNOW:
                        self.terr[i] = ROCK
                    self.stone[i], self.metal[i] = 30, 20
                    self.touch(i)
                    k += 1
                    if k >= 6:
                        break
        self.say('Un filon est découvert près de %s' % c.name, (245, 175, 60))

    def refound(self, c):
        if c.alive:
            return
        c.alive = True
        c.agents = []
        for r in RES:
            c.stock[r] = max(c.stock[r], 30)
        for _ in range(8):
            self.add_agent(c, c.cx + random.randint(-3, 3), c.cy + random.randint(-3, 3), age=random.randint(600, 1500))
        self.elect(c, silent=True)
        self.say('%s est refondée' % c.name, c.color)
