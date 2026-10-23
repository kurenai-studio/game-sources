import array
import json
import math
import random
from pathlib import Path

import pygame

WIDTH, HEIGHT = 1100, 750
FPS = 60
MAX_PARTICLES = 300
MAX_FLOATING_TEXTS = 40
VERSION = "1.0.0-rc1"
SAVE_VERSION = 1
SAVE_FILE = Path.home() / ".alloy_forge_save.json"

BACKGROUND = (22, 22, 26)
PANEL = (35, 35, 42)
TEXT = (220, 220, 220)
MUTED = (150, 150, 160)
GOLD = (255, 215, 0)
GREEN = (80, 220, 100)
RED = (230, 70, 70)
BLUE = (150, 200, 255)
CYAN = (100, 230, 240)

ELEMENTS = {
    "Iron (Fe)": {
        "density": 7.87, "strength": 200, "cost": 0.5,
        "color": (160, 160, 165), "unlocked": True,
    },
    "Carbon (C)": {
        "density": 2.26, "strength": 50, "cost": 0.2,
        "color": (40, 40, 40), "unlocked": True,
    },
    "Copper (Cu)": {
        "density": 8.96, "strength": 220, "cost": 8.0,
        "color": (184, 115, 51), "unlocked": True,
    },
    "Zinc (Zn)": {
        "density": 7.14, "strength": 110, "cost": 3.0,
        "color": (190, 200, 210), "unlocked": True,
    },
    "Chromium (Cr)": {
        "density": 7.19, "strength": 300, "cost": 12.0,
        "color": (210, 220, 230), "unlocked": True,
    },
    "Titanium (Ti)": {
        "density": 4.50, "strength": 430, "cost": 35.0,
        "color": (140, 150, 170), "unlocked": False,
    },
    "Gold (Au)": {
        "density": 19.30, "strength": 100, "cost": 60.0,
        "color": (240, 200, 40), "unlocked": False,
    },
    "Silver (Ag)": {
        "density": 10.49, "strength": 140, "cost": 22.0,
        "color": (220, 225, 230), "unlocked": False,
    },
    "Aluminum (Al)": {
        "density": 2.70, "strength": 90, "cost": 2.5,
        "color": (200, 210, 215), "unlocked": False,
    },
    "Nickel (Ni)": {
        "density": 8.90, "strength": 310, "cost": 18.0,
        "color": (170, 180, 175), "unlocked": False,
    },
    "Tungsten (W)": {
        "density": 19.25, "strength": 550, "cost": 45.0,
        "color": (100, 110, 125), "unlocked": False,
    },
}

RECIPES = {
    frozenset(("Iron (Fe)", "Carbon (C)")): "Carbon Steel",
    frozenset(("Iron (Fe)", "Chromium (Cr)")): "Stainless Steel",
    frozenset(("Copper (Cu)", "Zinc (Zn)")): "Brass",
    frozenset(("Titanium (Ti)", "Iron (Fe)")): "Titanium Steel",
    frozenset(("Gold (Au)", "Copper (Cu)")): "Rose Gold",
    frozenset(("Gold (Au)", "Silver (Ag)")): "Electrum Alloy",
    frozenset(("Aluminum (Al)", "Copper (Cu)")): "Duralumin",
    frozenset(("Nickel (Ni)", "Chromium (Cr)")): "Nichrome Wire",
    frozenset(("Titanium (Ti)", "Aluminum (Al)")): "Aero Titanium-Aluminide",
    frozenset(("Tungsten (W)", "Carbon (C)")): "Tungsten Carbide",
}

CONTRACTS = [
    {"client": "Guild Forgery", "desc": "Light Sword Blade",
     "max_den": 8.0, "min_str": 260, "max_cost": 10.0, "reward": 300},
    {"client": "Brass Quintet", "desc": "Trumpet Bell",
     "max_den": 8.5, "min_str": 185, "max_cost": 7.0, "reward": 350,
     "require": ("Zinc (Zn)", 0.30)},
    {"client": "Chem Plant", "desc": "Corrosion-Proof Pipe",
     "max_den": 8.0, "min_str": 290, "max_cost": 6.0, "reward": 500,
     "require": ("Chromium (Cr)", 0.12)},
    {"client": "AeroSpace Lab", "desc": "Lightweight Jet Strut",
     "max_den": 5.5, "min_str": 350, "max_cost": 40.0, "reward": 600},
    {"client": "Royal Mint", "desc": "Lustrous Golden Coin",
     "max_den": 20.0, "min_str": 80, "max_cost": 70.0, "reward": 800,
     "require": ("Gold (Au)", 0.30)},
    {"client": "Jewelry House", "desc": "Ancient Electrum Crown",
     "max_den": 16.0, "min_str": 120, "max_cost": 50.0, "reward": 950,
     "require": ("Silver (Ag)", 0.25)},
    {"client": "Grid Power Corp", "desc": "High-Temp Heating Element",
     "max_den": 8.8, "min_str": 320, "max_cost": 25.0, "reward": 1100,
     "require": ("Nickel (Ni)", 0.30)},
    {"client": "Defense Tech", "desc": "Armor-Piercing Core",
     "max_den": 18.0, "min_str": 450, "max_cost": 35.0, "reward": 1500,
     "require": ("Tungsten (W)", 0.35)},
]

# Per-level values, indexed by the level of the matching upgrade.
BELLOWS_HEAT_DURATION = (5.0, 6.0, 7.0, 8.0)  # seconds the furnace stays hot
BELLOWS_SPEED = (1.0, 1.8, 2.5, 3.5)
ANVIL_HALF_WIDTH = (0.07, 0.09, 0.11, 0.13)
BAR_SPEED = (2.2, 1.8, 1.5, 1.2)
MASTERY_BONUS = (0.15, 0.20, 0.25)
MASTERY_CAP = (1.6, 1.8, 2.0)
QUENCH_MULT = (1.45, 1.60)
SUPPLIER_COST = (1.0, 0.9, 0.8, 0.7)
REPUTATION = (1.0, 1.2, 1.4, 1.6)

UPGRADES = [
    {"id": "bellows", "name": "Bellows", "costs": (150, 300, 600),
     "desc": "Furnace heats faster and stays hot longer."},
    {"id": "anvil", "name": "Heavy Anvil", "costs": (120, 250, 500),
     "desc": "Widens the perfect-strike zone on the hammer bar."},
    {"id": "hands", "name": "Steady Hands", "costs": (100, 220, 450),
     "desc": "Slows the timing bar so strikes are easier to hit."},
    {"id": "mastery", "name": "Forge Mastery", "costs": (300, 700),
     "desc": "Perfect strikes yield higher strength bonuses and quality cap."},
    {"id": "brine", "name": "Brine Quench", "costs": (250,),
     "desc": "Boosts strength gain when quenching hot metal."},
    {"id": "supplier", "name": "Bulk Supplier", "costs": (200, 400, 800),
     "desc": "Reduces raw-material production costs."},
    {"id": "reputation", "name": "Reputation", "costs": (250, 500, 1000),
     "desc": "Increases contract payout rewards."},
    {"id": "analyzer", "name": "Spec Analyzer", "costs": (180,),
     "desc": "Shows real-time pass/fail status for contract specs."},
    {"id": "unlock_ti", "name": "Titanium", "costs": (300,), "unlock": "Titanium (Ti)",
     "desc": "Unlocks lightweight, high-strength Titanium."},
    {"id": "unlock_au", "name": "Gold Supply", "costs": (400,), "unlock": "Gold (Au)",
     "desc": "Unlocks Gold, needed for Royal Mint contracts."},
    {"id": "unlock_ag", "name": "Silver Supply", "costs": (350,), "unlock": "Silver (Ag)",
     "desc": "Unlocks Silver for jewelry and high-conductivity alloys."},
    {"id": "unlock_al", "name": "Aluminum", "costs": (200,), "unlock": "Aluminum (Al)",
     "desc": "Unlocks low-density Aluminum."},
    {"id": "unlock_ni", "name": "Nickel Supply", "costs": (450,), "unlock": "Nickel (Ni)",
     "desc": "Unlocks high-temperature Nickel."},
    {"id": "unlock_w", "name": "Tungsten", "costs": (600,), "unlock": "Tungsten (W)",
     "desc": "Unlocks ultra-dense, ultra-strong Tungsten."},
]

UPGRADES_BY_ID = {u["id"]: u for u in UPGRADES}


def clamp(value, low, high):
    return max(low, min(value, high))


def short(name):
    return name.split(" (", 1)[0]


_text_cache = {}


def render_text(font, text, color):
    key = (id(font), text, color)
    if key not in _text_cache:
        if len(_text_cache) >= 512:
            _text_cache.clear()
        _text_cache[key] = font.render(text, True, color)
    return _text_cache[key]


def draw_text(surface, text, font, color, pos):
    surface.blit(render_text(font, text, color), pos)


def make_sounds():
    mixer = pygame.mixer.get_init()
    if not mixer:
        return {}
    rate, _, channels = mixer

    def sound(duration, wave, volume=0.25):
        samples = array.array("h")
        for i in range(int(rate * duration)):
            t = i / rate
            value, envelope = wave(t, duration)
            level = clamp(int(32767 * volume * envelope * value), -32768, 32767)
            samples.extend([level] * channels)
        return pygame.mixer.Sound(buffer=samples.tobytes())

    sin, tau, exp = math.sin, math.tau, math.exp
    try:
        return {
            "hammer": sound(
                0.15,
                lambda t, d: (sin(tau * 880 * t) + 0.5 * sin(tau * 1760 * t), exp(-25 * t)),
                0.35),
            "heat": sound(
                0.3,
                lambda t, d: (random.uniform(-1, 1) * 0.5 + sin(tau * 110 * t),
                              sin(math.pi * t / d)),
                0.25),
            "quench": sound(0.45, lambda t, d: (random.uniform(-1, 1), exp(-6 * t)), 0.35),
            "success": sound(
                0.35,
                lambda t, d: (sin(tau * (523.25 if t < 0.18 else 659.25) * t), 1 - t / d),
                0.3),
            "fail": sound(
                0.3,
                lambda t, d: (1.0 if sin(tau * 120 * t) > 0 else -1.0, exp(-7 * t)),
                0.25),
            "click": sound(0.04, lambda t, d: (sin(tau * 1200 * t), 1 - t / d), 0.15),
        }
    except (pygame.error, ValueError):
        return {}


class FloatingText:
    LIFETIME = 1.2

    def __init__(self, x, y, text, color, font):
        self.x = x
        self.y = y
        self.surface = font.render(text, True, color)
        self.life = self.LIFETIME

    def update(self, dt):
        self.y -= 35 * dt
        self.life -= dt

    def draw(self, surface):
        self.surface.set_alpha(int(255 * self.life / self.LIFETIME))
        surface.blit(self.surface, self.surface.get_rect(center=(int(self.x), int(self.y))))


class Particle:
    def __init__(self, x, y, kind):
        self.x = x
        self.y = y
        self.kind = kind
        self.life = 1.0
        self.size = random.randint(2, 5)

        if kind == "spark":
            angle = random.uniform(0, math.tau)
            speed = random.uniform(140, 450)
            self.vx = math.cos(angle) * speed
            self.vy = math.sin(angle) * speed
            self.color = (255, random.randint(180, 255), 60)
        elif kind == "steam":
            self.vx = random.uniform(-60, 60)
            self.vy = random.uniform(-250, -130)
            self.color = (210, 230, 255)
        else:
            self.vx = random.uniform(-30, 30)
            self.vy = random.uniform(-120, -50)
            self.color = (255, random.randint(60, 160), 20)

    def update(self, dt):
        self.x += self.vx * dt
        self.y += self.vy * dt
        if self.kind == "spark":
            self.vy += 900 * dt
            self.life -= 2.4 * dt
        else:
            self.life -= 1.2 * dt

    def draw(self, surface):
        radius = max(1, int(self.size * self.life))
        color = tuple(int(c * self.life) for c in self.color)
        pygame.draw.circle(surface, color, (int(self.x), int(self.y)), radius)


class Slider:
    def __init__(self, x, y, width, label, font):
        self.rect = pygame.Rect(x, y, width, 14)
        self.value = 50.0
        self.label = label
        self.font = font
        self.dragging = False

    def set_value(self, value):
        self.value = clamp(float(value), 0.0, 100.0)

    def update_value(self, mouse_x):
        x = clamp(mouse_x, self.rect.left, self.rect.right - 1)
        self.set_value((x - self.rect.left) / (self.rect.width - 1) * 100.0)

    def draw(self, surface):
        pygame.draw.rect(surface, (70, 70, 80), self.rect, border_radius=4)
        handle_x = self.rect.left + round(self.value / 100.0 * (self.rect.width - 1))
        color = (255, 255, 255) if self.dragging else (190, 190, 200)
        pygame.draw.circle(surface, color, (handle_x, self.rect.centery), 9)
        draw_text(surface, f"{self.label}: {round(self.value)}%", self.font, TEXT,
                  (self.rect.x, self.rect.y - 22))

    def handle_event(self, event):
        if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            if self.rect.inflate(10, 20).collidepoint(event.pos):
                self.dragging = True
                self.update_value(event.pos[0])
        elif event.type == pygame.MOUSEBUTTONUP and event.button == 1:
            self.dragging = False
        elif event.type == pygame.MOUSEMOTION and self.dragging:
            self.update_value(event.pos[0])


class Button:
    def __init__(self, x, y, width, height, text, color, hover_color, font, hotkey=None):
        self.rect = pygame.Rect(x, y, width, height)
        self.color = color
        self.hover_color = hover_color
        self.font = font
        self.hotkey = hotkey
        self.hovered = False
        self.enabled = True
        self.set_text(text)

    def set_text(self, text, color=(255, 255, 255)):
        if self.hotkey:
            text = f"{text} [{self.hotkey}]"
        label = self.font.render(text, True, color)

        max_width = self.rect.width - 12
        if label.get_width() > max_width:
            height = max(1, round(label.get_height() * max_width / label.get_width()))
            label = pygame.transform.smoothscale(label, (max_width, height))

        self.label = label
        self.label_rect = label.get_rect(center=self.rect.center)

    def draw(self, surface):
        if self.enabled:
            fill = self.hover_color if self.hovered else self.color
            border = (180, 180, 190)
        else:
            fill, border = (45, 45, 52), (80, 80, 90)
        pygame.draw.rect(surface, fill, self.rect, border_radius=6)
        pygame.draw.rect(surface, border, self.rect, width=2, border_radius=6)
        surface.blit(self.label, self.label_rect)

    def is_clicked(self, event):
        return (self.enabled and event.type == pygame.MOUSEBUTTONDOWN
                and event.button == 1 and self.rect.collidepoint(event.pos))


class AlloyForgeGame:
    def __init__(self):
        pygame.init()
        self.screen = pygame.display.set_mode((WIDTH, HEIGHT))
        self.canvas = pygame.Surface((WIDTH, HEIGHT))
        self.clock = pygame.time.Clock()
        pygame.display.set_caption(f"Alloy Forge: Master Smith {VERSION}")

        self.glow = pygame.Surface((240, 240), pygame.SRCALPHA)
        pygame.draw.rect(self.glow, (255, 100, 20, 255), (0, 0, 240, 240), border_radius=16)

        self.font_large = pygame.font.SysFont(None, 42)
        self.font_medium = pygame.font.SysFont(None, 26)
        self.font_small = pygame.font.SysFont(None, 20)
        self.sounds = make_sounds()

        self.elements = tuple(ELEMENTS)
        self.unlocked = {name: data["unlocked"] for name, data in ELEMENTS.items()}
        self.active = [self.elements[0], self.elements[1]]

        self.temperature = 25.0
        self.heat_timer = 0.0
        self.is_quenched = False
        self.money = 150
        self.contract_idx = 0
        self.completed = 0
        self.quality_bonus = 1.0
        self.unlocked_recipes = set()
        self.show_codex = False
        self.status_msg = "Mix metals, heat furnace, hammer, quench, then submit!"

        self.levels = {u["id"]: 0 for u in UPGRADES}
        self.particles = []
        self.floating_texts = []
        self.shake = 0.0
        self.hammer_pos = 0.0
        self.hammer_dir = 1
        self.hammer_active = False
        self.hammer_swing = 0.0

        self.setup_ui()
        self.load_game()
        self.refresh_shop()

    def play_sfx(self, name):
        if name in self.sounds:
            self.sounds[name].play()

    def add_floating_text(self, x, y, text, color):
        if len(self.floating_texts) >= MAX_FLOATING_TEXTS:
            self.floating_texts.pop(0)
        self.floating_texts.append(FloatingText(x, y, text, color, self.font_medium))

    def setup_ui(self):
        self.s1 = Slider(40, 130, 220, self.active[0], self.font_small)
        self.s2 = Slider(40, 210, 220, self.active[1], self.font_small)

        self.btn_heat = Button(360, 520, 120, 40, "HEAT", (180, 50, 50), (220, 70, 70),
                               self.font_medium, "H")
        self.btn_hammer = Button(490, 520, 140, 40, "HAMMER!", (200, 140, 30), (230, 170, 40),
                                 self.font_medium, "SPACE")
        self.btn_quench = Button(640, 520, 120, 40, "QUENCH", (50, 100, 180), (70, 130, 220),
                                 self.font_medium, "Q")
        self.btn_submit = Button(770, 520, 150, 40, "SUBMIT", (40, 150, 60), (60, 190, 80),
                                 self.font_medium, "S")
        self.btn_c1 = Button(270, 120, 30, 22, ">", (70, 70, 80), (100, 100, 110),
                             self.font_small, "1")
        self.btn_c2 = Button(270, 200, 30, 22, ">", (70, 70, 80), (100, 100, 110),
                             self.font_small, "2")
        self.btn_codex = Button(930, 462, 110, 28, "CODEX", (80, 70, 30), (120, 100, 40),
                                self.font_small, "C")

        self.shop_buttons = {}
        for i, upgrade in enumerate(UPGRADES):
            x, y = 40 + i % 5 * 206, 608 + i // 5 * 32
            self.shop_buttons[upgrade["id"]] = Button(
                x, y, 196, 28, upgrade["name"], (80, 60, 100), (110, 80, 140), self.font_small)

        self.buttons = [self.btn_heat, self.btn_hammer, self.btn_quench, self.btn_submit,
                        self.btn_c1, self.btn_c2, self.btn_codex, *self.shop_buttons.values()]

        self.hotkeys = {
            pygame.K_h: self.start_heating,
            pygame.K_SPACE: self.hammer_strike,
            pygame.K_RETURN: self.hammer_strike,
            pygame.K_q: self.quench,
            pygame.K_s: self.submit_order,
            pygame.K_1: lambda: self.cycle_element(0),
            pygame.K_2: lambda: self.cycle_element(1),
            pygame.K_c: self.toggle_codex,
        }
        self.click_actions = [
            (self.btn_heat, self.start_heating),
            (self.btn_hammer, self.hammer_strike),
            (self.btn_quench, self.quench),
            (self.btn_submit, self.submit_order),
            (self.btn_c1, lambda: self.cycle_element(0)),
            (self.btn_c2, lambda: self.cycle_element(1)),
            (self.btn_codex, self.toggle_codex),
        ]

    def save_game(self):
        data = {
            "version": SAVE_VERSION,
            "money": self.money,
            "contract_idx": self.contract_idx,
            "completed": self.completed,
            "quality_bonus": self.quality_bonus,
            "is_quenched": self.is_quenched,
            "levels": self.levels,
            "unlocked_recipes": sorted(self.unlocked_recipes),
            "active_elements": self.active,
            "mix": [self.s1.value, self.s2.value],
        }
        tmp = SAVE_FILE.with_name(SAVE_FILE.name + ".tmp")
        try:
            tmp.write_text(json.dumps(data, indent=2), encoding="utf-8")
            tmp.replace(SAVE_FILE)
        except OSError:
            self.status_msg = "Progress could not be saved."

    def load_game(self):
        try:
            data = json.loads(SAVE_FILE.read_text(encoding="utf-8"))
        except FileNotFoundError:
            return
        except (OSError, ValueError):
            self.status_msg = "Save file could not be read; starting fresh."
            return
        if not isinstance(data, dict) or data.get("version") != SAVE_VERSION:
            self.status_msg = "Save version is incompatible; starting fresh."
            return

        money = data.get("money")
        if isinstance(money, int):
            self.money = max(0, money)
        index = data.get("contract_idx")
        if isinstance(index, int):
            self.contract_idx = clamp(index, 0, len(CONTRACTS) - 1)
        completed = data.get("completed")
        if isinstance(completed, int):
            self.completed = max(0, completed)

        saved_levels = data.get("levels")
        for upgrade in UPGRADES:
            level = saved_levels.get(upgrade["id"]) if isinstance(saved_levels, dict) else None
            if isinstance(level, int):
                self.levels[upgrade["id"]] = clamp(level, 0, len(upgrade["costs"]))
            if "unlock" in upgrade and self.levels[upgrade["id"]] > 0:
                self.unlocked[upgrade["unlock"]] = True

        recipes = data.get("unlocked_recipes")
        if isinstance(recipes, list):
            self.unlocked_recipes = {r for r in recipes if r in RECIPES.values()}

        active = data.get("active_elements")
        if (isinstance(active, list) and len(active) == 2 and active[0] != active[1]
                and all(isinstance(n, str) and self.unlocked.get(n) for n in active)):
            self.active = active
            self.s1.label, self.s2.label = active

        mix = data.get("mix")
        if (isinstance(mix, list) and len(mix) == 2
                and all(isinstance(v, (int, float)) for v in mix)):
            first, second = (clamp(float(v), 0.0, 100.0) for v in mix)
            if first + second > 0:
                self.s1.set_value(first * 100.0 / (first + second))
                self.s2.set_value(100.0 - self.s1.value)

        quality = data.get("quality_bonus")
        if isinstance(quality, (int, float)):
            self.quality_bonus = clamp(float(quality), 0.8, MASTERY_CAP[self.levels["mastery"]])

        self.is_quenched = data.get("is_quenched") is True
        self.status_msg = "Saved progress loaded."

    def reward_for(self, contract):
        return int(contract["reward"] * REPUTATION[self.levels["reputation"]])

    def get_fraction(self, element):
        total = 0.0
        if self.active[0] == element:
            total += self.s1.value / 100.0
        if self.active[1] == element:
            total += self.s2.value / 100.0
        return total

    def cycle_element(self, index):
        self.play_sfx("click")
        current = self.elements.index(self.active[index])
        for step in range(1, len(self.elements)):
            candidate = self.elements[(current + step) % len(self.elements)]
            if candidate not in self.active and self.unlocked[candidate]:
                self.active[index] = candidate
                (self.s1, self.s2)[index].label = candidate
                self.save_game()
                return

    def get_stats(self):
        first, second = (ELEMENTS[name] for name in self.active)
        p1, p2 = self.s1.value / 100.0, self.s2.value / 100.0

        density = p1 * first["density"] + p2 * second["density"]
        strength = (p1 * first["strength"] + p2 * second["strength"]) * self.quality_bonus
        cost = (p1 * first["cost"] + p2 * second["cost"]) * SUPPLIER_COST[self.levels["supplier"]]
        if self.is_quenched:
            strength *= QUENCH_MULT[self.levels["brine"]]
        return density, strength, cost

    def get_alloy_name(self):
        present = set()
        if self.s1.value > 2.0:
            present.add(self.active[0])
        if self.s2.value > 2.0:
            present.add(self.active[1])

        recipe = RECIPES.get(frozenset(present))
        if recipe:
            return recipe
        if len(present) == 1:
            return next(iter(present))
        return "Custom Experimental Alloy"

    def update_recipe_unlocks(self):
        name = self.get_alloy_name()
        if name in RECIPES.values() and name not in self.unlocked_recipes:
            self.unlocked_recipes.add(name)
            self.save_game()

    def toggle_codex(self):
        self.show_codex = not self.show_codex
        self.btn_codex.set_text("CLOSE" if self.show_codex else "CODEX")

    def contract_checks(self):
        contract = CONTRACTS[self.contract_idx]
        density, strength, cost = self.get_stats()
        checks = {
            "den": density <= contract["max_den"],
            "str": strength >= contract["min_str"],
            "cost": cost <= contract["max_cost"],
        }
        if "require" in contract:
            name, minimum = contract["require"]
            # epsilon so a 30% slider isn't rejected for float error
            checks["req"] = self.get_fraction(name) >= minimum - 1e-9
        return checks

    def buy(self, upgrade_id):
        upgrade = UPGRADES_BY_ID[upgrade_id]
        cost = upgrade["costs"][self.levels[upgrade_id]]
        if self.money < cost:
            self.play_sfx("fail")
            self.status_msg = f"Not enough gold for {upgrade['name']} (${cost} required)."
            return

        self.play_sfx("click")
        self.money -= cost
        self.levels[upgrade_id] += 1

        if "unlock" in upgrade:
            element = upgrade["unlock"]
            self.unlocked[element] = True
            self.status_msg = f"Unlocked {short(element)}! Cycle to it using buttons or keys [1/2]."
            self.add_floating_text(515, 300, f"UNLOCKED {short(element).upper()}!", GOLD)
        else:
            self.status_msg = f"{upgrade['name']} upgraded to Level {self.levels[upgrade_id]}!"
            self.add_floating_text(515, 300, f"+{upgrade['name'].upper()} LEVEL", CYAN)

        self.refresh_shop()
        self.save_game()

    def refresh_shop(self):
        for upgrade in UPGRADES:
            button = self.shop_buttons[upgrade["id"]]
            level = self.levels[upgrade["id"]]
            costs = upgrade["costs"]
            name = upgrade["name"]

            if level >= len(costs):
                button.enabled = False
                button.set_text(f"{name}: OWNED" if len(costs) == 1 else f"{name} MAX", MUTED)
                continue

            button.enabled = True
            cost = costs[level]
            label = f"{name} ${cost}" if len(costs) == 1 else f"{name} {level}/{len(costs)} ${cost}"
            button.set_text(label, (255, 255, 255) if self.money >= cost else (255, 140, 140))

    def start_heating(self):
        self.play_sfx("heat")
        self.heat_timer = BELLOWS_HEAT_DURATION[self.levels["bellows"]]
        self.is_quenched = False
        self.hammer_active = True
        self.status_msg = "Furnace roaring hot! Time your hammer strikes."
        self.add_floating_text(515, 280, "FURNACE STOKED!", RED)

    def spawn_particles(self, x, y, kind, count):
        for _ in range(min(count, MAX_PARTICLES - len(self.particles))):
            self.particles.append(Particle(x, y, kind))

    def hammer_strike(self):
        if self.temperature <= 450:
            self.play_sfx("fail")
            self.status_msg = "Metal is too cold! Heat furnace above 450°C to shape."
            return

        self.play_sfx("hammer")
        self.shake = 6.0
        self.hammer_swing = 1.0
        self.spawn_particles(515, 220, "spark", 14)

        if abs(self.hammer_pos - 0.5) <= ANVIL_HALF_WIDTH[self.levels["anvil"]]:
            gain = MASTERY_BONUS[self.levels["mastery"]]
            cap = MASTERY_CAP[self.levels["mastery"]]
            self.quality_bonus = min(cap, self.quality_bonus + gain)
            self.status_msg = f"PERFECT STRIKE! Grain refined (+{gain * 100:.0f}% strength)."
            self.add_floating_text(515, 200, f"PERFECT! +{gain * 100:.0f}%", GOLD)
        else:
            self.quality_bonus = max(0.8, self.quality_bonus - 0.05)
            self.status_msg = "Off-center strike. Metal grain misaligned."
            self.add_floating_text(515, 200, "MISALIGNED", RED)

        self.save_game()

    def quench(self):
        if self.temperature > 650:
            self.play_sfx("quench")
            self.is_quenched = True
            self.shake = 10.0
            self.spawn_particles(515, 220, "steam", 28)
            bonus = (QUENCH_MULT[self.levels["brine"]] - 1) * 100
            medium = "BRINE" if self.levels["brine"] else "STEAM"
            self.status_msg = (f"{medium} QUENCH! Locked in hard martensitic phase "
                               f"(+{bonus:.0f}% strength).")
            self.add_floating_text(515, 200, f"{medium} QUENCHED (+{bonus:.0f}%)", CYAN)
        else:
            self.play_sfx("fail")
            self.status_msg = "Metal must be glowing red (>650°C) to quench!"

        self.heat_timer = 0.0
        self.hammer_active = False
        self.save_game()

    def submit_order(self):
        contract = CONTRACTS[self.contract_idx]
        if all(self.contract_checks().values()):
            self.play_sfx("success")
            reward = self.reward_for(contract)
            self.money += reward
            self.completed += 1
            self.status_msg = f"CONTRACT APPROVED! Earned ${reward} from {contract['client']}!"
            self.add_floating_text(880, 200, f"+${reward}", GREEN)
            self.contract_idx = (self.contract_idx + 1) % len(CONTRACTS)
            self.quality_bonus = 1.0
            self.is_quenched = False
            self.refresh_shop()
            self.save_game()
        else:
            self.play_sfx("fail")
            self.status_msg = "REJECTED! Material specs do not meet client requirements."
            self.add_floating_text(880, 200, "REJECTED!", RED)

    def update(self, dt):
        if self.heat_timer > 0:
            self.heat_timer -= dt
            target = 1400.0
        else:
            target = 25.0
        rate = 0.7 * BELLOWS_SPEED[self.levels["bellows"]] if target > 500 else 0.35
        self.temperature += (target - self.temperature) * (1.0 - math.exp(-rate * dt))
        self.update_recipe_unlocks()

        if self.hammer_active and self.heat_timer <= 0 and self.temperature <= 450:
            self.hammer_active = False
        if self.hammer_active:
            self.hammer_pos += self.hammer_dir * dt * BAR_SPEED[self.levels["hands"]]
            if self.hammer_pos >= 1.0:
                self.hammer_pos, self.hammer_dir = 1.0, -1
            elif self.hammer_pos <= 0.0:
                self.hammer_pos, self.hammer_dir = 0.0, 1

        self.hammer_swing = max(0.0, self.hammer_swing - dt * 4.5)
        self.shake = max(0.0, self.shake - dt * 30.0)

        if self.temperature > 400 and random.random() < 30 * dt:
            self.spawn_particles(510 + random.randint(-40, 40), 300, "ember", 1)

        for item in self.particles + self.floating_texts:
            item.update(dt)
        self.particles = [p for p in self.particles if p.life > 0]
        self.floating_texts = [t for t in self.floating_texts if t.life > 0]

    def draw_left(self, surface):
        self.s1.draw(surface)
        self.s2.draw(surface)
        draw_text(surface, "Selected Elements", self.font_medium, BLUE, (40, 295))

        for i, name in enumerate(self.active):
            element = ELEMENTS[name]
            y = 325 + i * 48
            swatch = pygame.Rect(40, y + 2, 14, 14)
            pygame.draw.rect(surface, element["color"], swatch)
            pygame.draw.rect(surface, (150, 150, 160), swatch, width=1)
            draw_text(surface, name, self.font_small, TEXT, (62, y))
            info = (f"{element['density']} g/cm³  {element['strength']} MPa  "
                    f"${element['cost']}/kg")
            draw_text(surface, info, self.font_small, MUTED, (40, y + 18))

        locked = [short(name) for name in self.elements if not self.unlocked[name]]
        for i in range(0, len(locked), 3):
            prefix = "Locked: " if i == 0 else "         "
            draw_text(surface, prefix + ", ".join(locked[i:i + 3]), self.font_small, MUTED,
                      (40, 440 + i // 3 * 18))

    def get_metal_color(self):
        p1, p2 = self.s1.value / 100.0, self.s2.value / 100.0
        first = ELEMENTS[self.active[0]]["color"]
        second = ELEMENTS[self.active[1]]["color"]
        base = [p1 * first[i] + p2 * second[i] for i in range(3)]
        glow = clamp((self.temperature - 200) / 1200, 0.0, 1.0)
        r = base[0] + (255 - base[0]) * glow
        g = base[1] + (140 - base[1]) * glow
        b = base[2] * (1.0 - glow)
        return tuple(int(clamp(c, 0, 255)) for c in (r, g, b))

    def draw_center(self, surface):
        crucible = pygame.Rect(415, 120, 200, 200)

        glow_alpha = int(clamp((self.temperature - 300) / 1100, 0, 1) * 60)
        if glow_alpha > 0:
            self.glow.set_alpha(glow_alpha)
            surface.blit(self.glow, (395, 100))

        pygame.draw.rect(surface, (15, 15, 18), crucible.inflate(16, 16), border_radius=12)
        pygame.draw.rect(surface, self.get_metal_color(), crucible, border_radius=8)

        temp_color = RED if self.temperature > 600 else TEXT
        temp_text = render_text(self.font_medium, f"Temp: {int(self.temperature)}°C", temp_color)
        surface.blit(temp_text, temp_text.get_rect(center=(515, 340)))

        bar_x, bar_w = 360, 310
        pygame.draw.rect(surface, (20, 20, 25), (bar_x, 380, bar_w, 20), border_radius=5)
        half = ANVIL_HALF_WIDTH[self.levels["anvil"]]
        sweet_spot = pygame.Rect(int(bar_x + (0.5 - half) * bar_w), 380, int(2 * half * bar_w), 20)
        pygame.draw.rect(surface, GREEN, sweet_spot)
        marker_x = int(bar_x + self.hammer_pos * bar_w)
        pygame.draw.line(surface, GOLD, (marker_x, 375), (marker_x, 405), 4)

        if self.hammer_swing > 0.0:
            angle = self.hammer_swing * 0.7
            hx = marker_x + math.sin(angle) * 35
            hy = 370 - math.cos(angle) * 35
            pygame.draw.line(surface, (150, 100, 50), (marker_x, 370), (hx, hy), 6)
            pygame.draw.rect(surface, (200, 200, 210), (hx - 8, hy - 6, 16, 12), border_radius=2)

        cap = MASTERY_CAP[self.levels["mastery"]]
        quality = f"Quality Bonus: {self.quality_bonus:.2f}x (Max {cap:.1f}x)"
        draw_text(surface, quality, self.font_small, GOLD, (bar_x, 410))

    def draw_right(self, surface):
        contract = CONTRACTS[self.contract_idx]
        draw_text(surface, "Client Order", self.font_medium, GOLD, (740, 85))

        lines = [
            f"Client: {contract['client']}",
            f"Item: {contract['desc']}",
            f"Max Density: {contract['max_den']} g/cm³",
            f"Min Strength: {contract['min_str']} MPa",
            f"Max Cost: ${contract['max_cost']} / kg",
        ]
        if "require" in contract:
            name, fraction = contract["require"]
            lines.append(f"Needs: {short(name)} >= {fraction * 100:.0f}%")
        lines.append(f"Reward: ${self.reward_for(contract)}")
        for i, line in enumerate(lines):
            draw_text(surface, line, self.font_small, TEXT, (740, 115 + i * 19))

        pygame.draw.line(surface, (60, 60, 70), (730, 255), (1050, 255), 2)
        draw_text(surface, "Material Specs", self.font_medium, BLUE, (740, 262))

        density, strength, cost = self.get_stats()
        checks = self.contract_checks()
        rows = [
            (f"Alloy: {self.get_alloy_name()}", None),
            (f"Density: {density:.2f} g/cm³", checks["den"]),
            (f"Yield Strength: {strength:.0f} MPa", checks["str"]),
            (f"Cost: ${cost:.2f} / kg", checks["cost"]),
            (f"State: {'Quenched' if self.is_quenched else 'Normal'}", None),
        ]
        if "req" in checks:
            name, fraction = contract["require"]
            have = self.get_fraction(name) * 100
            rows.append((f"{short(name)}: {have:.0f}% (need {fraction * 100:.0f}%)", checks["req"]))

        analyzer = self.levels["analyzer"] > 0
        for i, (line, passed) in enumerate(rows):
            color = TEXT
            if analyzer and passed is not None:
                color = GREEN if passed else RED
            draw_text(surface, line, self.font_small, color, (740, 290 + i * 20))

        y = 290 + len(rows) * 20 + 8
        if analyzer:
            ready = all(checks.values())
            draw_text(surface, "READY TO SUBMIT" if ready else "Specs not met yet",
                      self.font_medium, GREEN if ready else RED, (740, y))
        else:
            draw_text(surface, "Tip: Spec Analyzer shows pass/fail.", self.font_small, MUTED,
                      (740, y))

    def draw_shop(self, surface):
        draw_text(surface, "Workshop Upgrades", self.font_medium, GOLD, (40, 582))
        tip = next((u["desc"] for u in UPGRADES if self.shop_buttons[u["id"]].hovered),
                   "Hover an upgrade to view details.")
        draw_text(surface, tip, self.font_small, (170, 170, 180), (280, 585))

    def draw_codex(self, surface):
        panel = pygame.Rect(300, 130, 500, 480)
        pygame.draw.rect(surface, (18, 18, 22), panel, border_radius=12)
        pygame.draw.rect(surface, GOLD, panel, width=2, border_radius=12)
        draw_text(surface, "Recipe Codex", self.font_large, GOLD, (335, 160))

        if self.unlocked_recipes:
            for i, recipe in enumerate(sorted(self.unlocked_recipes)):
                draw_text(surface, f"★ {recipe}", self.font_medium, GOLD, (340, 220 + i * 28))
        else:
            draw_text(surface, "Mix metals to discover alloy recipes.", self.font_medium, MUTED,
                      (340, 220))
        draw_text(surface, "Press C or click CLOSE to return.", self.font_small, MUTED, (340, 570))

    def draw(self):
        surface = self.canvas
        surface.fill(BACKGROUND)

        title = render_text(self.font_large, "ALLOY FORGE: MASTER SMITH", GOLD)
        surface.blit(title, title.get_rect(midtop=(WIDTH // 2, 15)))
        draw_text(surface, f"Gold: ${self.money}", self.font_medium, GREEN, (940, 20))
        draw_text(surface, f"Orders filled: {self.completed}", self.font_medium, TEXT, (40, 22))

        for rect in ((25, 70, 290, 430), (330, 70, 370, 430), (720, 70, 350, 430),
                     (25, 575, 1050, 125), (25, 708, 1050, 34)):
            pygame.draw.rect(surface, PANEL, rect, border_radius=10)

        self.draw_left(surface)
        self.draw_center(surface)
        self.draw_right(surface)
        self.draw_shop(surface)

        for button in self.buttons:
            button.draw(surface)
        for item in self.particles + self.floating_texts:
            item.draw(surface)

        draw_text(surface, f"> {self.status_msg}", self.font_medium, TEXT, (40, 716))
        if self.show_codex:
            self.draw_codex(surface)

        offset = (0, 0)
        if self.shake > 0:
            offset = (int(random.uniform(-self.shake, self.shake)),
                      int(random.uniform(-self.shake, self.shake)))
        self.screen.fill(BACKGROUND)
        self.screen.blit(surface, offset)
        pygame.display.flip()

    def handle_events(self):
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                return False
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
                    return False
                action = self.hotkeys.get(event.key)
                if action:
                    action()

            self.s1.handle_event(event)
            self.s2.handle_event(event)
            if self.s1.dragging:
                self.s2.set_value(100.0 - self.s1.value)
            elif self.s2.dragging:
                self.s1.set_value(100.0 - self.s2.value)

            for button, action in self.click_actions:
                if button.is_clicked(event):
                    action()
            for upgrade_id, button in self.shop_buttons.items():
                if button.is_clicked(event):
                    self.buy(upgrade_id)

            if event.type == pygame.MOUSEBUTTONUP and event.button == 1:
                self.save_game()
        return True

    def run(self):
        running = True
        while running:
            dt = min(self.clock.tick(FPS) / 1000.0, 0.1)
            mouse = pygame.mouse.get_pos()
            for button in self.buttons:
                button.hovered = button.rect.collidepoint(mouse)

            running = self.handle_events()
            if running:
                self.update(dt)
                self.draw()

        self.save_game()
        pygame.quit()


if __name__ == "__main__":
    AlloyForgeGame().run()
    
