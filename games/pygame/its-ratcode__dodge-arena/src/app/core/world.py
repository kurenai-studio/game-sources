"""The World: everything that belongs to one run."""

import random
from dataclasses import dataclass

import pygame
from pygame.math import Vector2

from app import config
from app.core.difficulty import danger_level, ramp
from app.entities.bolt import Bolt
from app.entities.coin import Coin
from app.entities.laser import Laser
from app.entities.pickup import PowerUpPickup
from app.entities.player import Player
from app.entities.wall import Wall
from app.progression.upgrades import RunStats
from app.render.effects import BlinkTrail, Burst, ClickMarker, Effect, FloatingText, NovaWave, Toast
from app.skills.loadout import SkillSlot, build_loadout
from app.skills.passive import SecondWind
from app.skills.powerups import POWERUP_POOL, PowerUp
from app.theme.palette import PALETTE
from app.util.timefmt import fmt_time

Threat = Bolt | Laser


@dataclass(frozen=True)
class RunRules:
    """Optional changes to how a run plays (from the Gameplay settings)."""

    start_danger: float = 0.0           # 0..1: danger the run starts at
    game_speed: float = 1.0             # 0.5..1: the whole run runs this much slower (applied by the play scene)
    laser_warning: float = 1.0          # 1..2: lasers warn this many times longer
    lasers: bool = True                 # False: bolts only (practice)

    @property
    def counts_for_best(self) -> bool:
        """Slower runs, longer warnings and runs without lasers are easier, so they never set a best time."""
        return self.game_speed == 1.0 and self.laser_warning == 1.0 and self.lasers


class World:
    """One run: the player, the threats, the pickups, the survival clock and the spawn timers.

    A new run is simply a new World. ``stats`` holds the upgrade-dependent
    numbers for the run and ``rules`` the player's gameplay settings. ``killer``
    is set to whatever hit the player, which ends the run.

    ``events`` collects the names of sounds that happened ("shield", "block",
    "coin2" ...). The World never plays audio itself; the play scene drains the
    list every frame, so the simulation stays testable without a sound card.
    """

    def __init__(self, stats: RunStats | None = None, keybinds: dict[str, str] | None = None,
                 rules: RunRules | None = None) -> None:
        self.stats = stats or RunStats()
        self.rules = rules or RunRules()
        keybinds = keybinds if keybinds is not None else dict(config.DEFAULT_KEYBINDS)
        self.player = Player((config.SCREEN_WIDTH / 2, config.SCREEN_HEIGHT / 2), self.stats.player_speed)
        self.loadout = build_loadout(keybinds, self.stats.cooldown_mult)
        self.second_wind = (SecondWind(self.stats.second_wind_cooldown)
                            if self.stats.second_wind_cooldown is not None else None)
        # Power-ups: at most one on the map and one held.
        self.pickup: PowerUpPickup | None = None
        self.pickup_timer = config.POWERUP_FIRST_DELAY
        self.last_pickup_kind: type[PowerUp] | None = None
        self.powerup_slot = SkillSlot("powerup", None, keybinds)
        self.powerup_hold = 0.0                # s before the held power-up expires
        self.time_warp_remaining = 0.0
        self.coin_rush_remaining = 0.0
        self.coins: list[Coin] = []
        self.coins_picked = 0                  # value collected this run (banked at game over)
        self.coin_timer = config.COIN_FIRST_DELAY
        self.coin_combo = 0                    # quick pickups in a row (raises the coin sound's pitch)
        self.last_coin_time = -10.0
        self.events: list[str] = []
        self.toasts: list[Toast] = []          # pop-up messages, drawn by the HUD
        self.close_calls = 0
        self.bolts: list[Bolt] = []
        self.lasers: list[Laser] = []
        self.walls: list[Wall] = []
        self.effects: list[Effect] = []
        self.marker: ClickMarker | None = None
        self.survival_time = 0.0
        self.spawn_timer = config.FIRST_SPAWN_DELAY
        self.laser_timer = config.LASER_FIRST_DELAY
        self.killer: Threat | None = None
        # Milestones already passed: a run that starts at a higher danger doesn't announce the ones below it.
        self.danger_milestone = sum(1 for m in config.DANGER_MILESTONES if self.danger >= m)
        self.next_survival_milestone = config.SURVIVAL_MILESTONE_INTERVAL
        # Transparent layer for lasers (they need alpha); cleared and reused every frame.
        self.fx_layer = pygame.Surface((config.SCREEN_WIDTH, config.SCREEN_HEIGHT), pygame.SRCALPHA)
        self.tint = pygame.Surface((config.SCREEN_WIDTH, config.SCREEN_HEIGHT))     # Time Warp screen tint

    @property
    def over(self) -> bool:
        return self.killer is not None

    @property
    def danger(self) -> float:
        """0..1. A higher starting danger shifts the whole ramp forward."""
        return danger_level(self.survival_time + self.rules.start_danger * config.DANGER_RAMP_TIME)

    @property
    def time_warped(self) -> bool:
        return self.time_warp_remaining > 0

    @property
    def coin_rush(self) -> bool:
        return self.coin_rush_remaining > 0

    # --- Input ---------------------------------------------------------------------------
    def command_move(self, pos, new_click: bool) -> None:
        """Send the player to ``pos``. A fresh click restarts the marker animation;
        while the button is held, the marker follows the cursor and re-pulses."""
        self.player.move_to(pos)
        if new_click or self.marker is None or not self.marker.alive:
            self.marker = ClickMarker(self.player.destination)
        else:
            self.marker.pos.update(self.player.destination)

    def can_cast(self) -> bool:
        return not self.over and not self.player.in_stasis

    def cast(self, slot_index: int, target) -> bool:
        """Cast the skill in a loadout slot, aimed at ``target`` (the cursor)."""
        if not self.can_cast():
            return False
        skill = self.loadout[slot_index].skill
        cast = skill.try_cast(self, Vector2(target))
        self.events.append(skill.icon if cast else "denied")      # a skill's sound is named like its icon
        return cast

    def use_powerup(self, target) -> bool:
        """Use the held power-up, aimed at ``target``. The slot empties after one use."""
        powerup = self.powerup_slot.skill
        if powerup is None or not self.can_cast() or not powerup.try_cast(self, Vector2(target)):
            return False
        self.powerup_slot.skill = None
        self.effects.append(Burst(self.player.pos, powerup.color, scale=1.2))
        self.events.append(powerup.icon)
        return True

    def aim_direction(self, target) -> Vector2:
        """Unit vector from the player toward ``target``; the facing direction if they overlap."""
        aim = Vector2(target) - self.player.pos
        return aim.normalize() if aim.length_squared() >= 1 else Vector2(self.player.facing)

    def blink_toward(self, target, max_range: float) -> None:
        """Teleport toward ``target``: as far as the cursor, at most ``max_range``
        (the full range if the cursor is on the player). Used by Blink and Warp."""
        distance = min(Vector2(target).distance_to(self.player.pos), max_range)
        if distance < 1:
            distance = max_range
        start = Vector2(self.player.pos)
        self.player.teleport(start + self.aim_direction(target) * distance)
        self.effects.append(BlinkTrail(start, self.player.pos))

    def nova(self) -> None:
        """Destroy every bolt and laser on screen, including lasers still warning."""
        for bolt in self.bolts:
            self.effects.append(Burst(bolt.shape.center, PALETTE.nova))
        self.bolts.clear()
        self.lasers.clear()
        self.effects.append(NovaWave(self.player.pos))

    # --- Simulation ------------------------------------------------------------------------
    def update(self, dt: float) -> None:
        if self.over:
            return
        # Time Warp slows the threats (and their spawn timers), never the player.
        threat_dt = dt * config.TIME_WARP_FACTOR if self.time_warped else dt
        self.time_warp_remaining = max(0.0, self.time_warp_remaining - dt)
        self.coin_rush_remaining = max(0.0, self.coin_rush_remaining - dt)
        before = self.survival_time
        self.survival_time += dt
        if before < config.INTRO_READY_TIME <= self.survival_time:
            self.events.append("go")                       # "GET READY" turns into "GO!"
        self.check_milestones()
        for slot in self.loadout:
            slot.skill.update(dt)
        if self.second_wind:
            self.second_wind.update(dt)
            if self.second_wind.ready_flash == 1.0:          # recharged this very frame
                self.events.append("second_wind_ready")
                self.toast("Second Wind is ready", "second_wind", "second_wind")
        for toast in self.toasts:
            toast.update(dt)
        self.toasts = [t for t in self.toasts if t.alive]
        self.player.update(dt)
        if self.marker:
            self.marker.update(dt)

        self.update_spawning(threat_dt)
        self.update_coins(dt)
        self.update_powerups(dt)
        for bolt in self.bolts:
            bolt.update(threat_dt)
        for laser in self.lasers:
            self.update_laser(laser, threat_dt)
        for thing in (*self.walls, *self.effects):
            thing.update(dt)
        self.bolts = [b for b in self.bolts if not b.is_off_screen()]
        self.lasers = [laser for laser in self.lasers if laser.alive]
        self.walls = [w for w in self.walls if w.alive]
        self.effects = [e for e in self.effects if e.alive]
        self.block_with_walls()
        self.check_hits()
        if not self.over:
            self.detect_close_calls()

    def update_aftermath(self, dt: float) -> None:
        """After the fatal hit: only threats, effects and messages keep moving (the slow-motion beat)."""
        for thing in (*self.bolts, *self.lasers, *self.effects, *self.toasts):
            thing.update(dt)
        self.effects = [e for e in self.effects if e.alive]
        self.toasts = [t for t in self.toasts if t.alive]

    # --- Feedback ------------------------------------------------------------------------------
    def toast(self, text: str, color_name: str, icon: str | None = None) -> None:
        self.toasts.append(Toast(text, color_name, icon))

    def float_text(self, pos, text: str, color_name: str) -> None:
        self.effects.append(FloatingText(pos, text, color_name))

    def check_milestones(self) -> None:
        """Announce each danger step once, and every SURVIVAL_MILESTONE_INTERVAL seconds survived."""
        milestones = config.DANGER_MILESTONES
        while self.danger_milestone < len(milestones) and self.danger >= milestones[self.danger_milestone]:
            m = milestones[self.danger_milestone]
            self.danger_milestone += 1
            self.toast("MAX DANGER" if m >= 1 else f"Danger {int(m * 100)}%", "danger", "bolt")
            self.events.append("danger")
        if self.survival_time >= self.next_survival_milestone:
            survived = fmt_time(self.next_survival_milestone)[:-2].removeprefix("0")     # "0:30", "1:00"
            self.toast(f"{survived} survived!", "warning", "time_warp")
            self.events.append("milestone")
            self.next_survival_milestone += config.SURVIVAL_MILESTONE_INTERVAL

    def detect_close_calls(self) -> None:
        """A bolt that comes within NEAR_MISS_DISTANCE and then passes without hitting, or a
        firing laser that just misses, is a close call: risk pays a coin. Nothing counts while
        the player is untouchable."""
        p = self.player
        if p.invulnerable:
            return
        zone = p.hit_radius + config.NEAR_MISS_DISTANCE
        for bolt in self.bolts:
            if bolt.near_miss_counted:
                continue
            if bolt.shape.collides_circle(p.pos, zone):
                bolt.grazing = True
            elif bolt.grazing:                             # it was close and has now gone past
                bolt.near_miss_counted = True
                self.close_call(bolt.shape.center)
        for laser in self.lasers:
            if laser.near_miss_counted or laser.disarmed:
                continue
            if laser.firing and laser.shape.collides_circle(p.pos, zone + 10):
                laser.grazed = True
            elif laser.grazed and not laser.firing:
                laser.near_miss_counted = True
                self.close_call(p.pos)

    def close_call(self, pos) -> None:
        self.close_calls += 1
        self.coins_picked += config.CLOSE_CALL_COINS
        self.float_text(self.player.pos + Vector2(0, -26), "CLOSE!", "accent")
        self.effects.append(Burst(pos, PALETTE.accent, scale=0.5))
        self.events.append("near_miss")

    def update_laser(self, laser: Laser, dt: float) -> None:
        """Age a laser, noting the moments its charge-up starts and its beam fires."""
        charge_at = laser.warning_time - config.LASER_CHARGE_SOUND_TIME
        was_age, was_firing = laser.age, laser.firing
        laser.update(dt)
        if was_age < charge_at <= laser.age:
            self.events.append("laser_charge")
        if laser.firing and not was_firing:
            self.events.append("laser_fire")

    def update_spawning(self, dt: float) -> None:
        danger = self.danger
        # Bolts: a while-loop keeps the rate exact even on long frames.
        self.spawn_timer -= dt
        while self.spawn_timer <= 0:
            self.spawn_bolt()
            if random.random() < ramp(config.DOUBLE_SHOT_CHANCE_START, config.DOUBLE_SHOT_CHANCE_END, danger):
                self.spawn_bolt()                                   # second bolt from another edge
            self.spawn_timer += ramp(config.BOLT_SPAWN_INTERVAL_START, config.BOLT_SPAWN_INTERVAL_END, danger)
        # Lasers: random gaps that shrink as danger rises.
        self.laser_timer -= dt
        if self.laser_timer <= 0 and self.rules.lasers:
            self.spawn_laser()
            self.laser_timer = random.uniform(
                ramp(config.LASER_INTERVAL_MIN_START, config.LASER_INTERVAL_MIN_END, danger),
                ramp(config.LASER_INTERVAL_MAX_START, config.LASER_INTERVAL_MAX_END, danger))

    def update_coins(self, dt: float) -> None:
        """Spawn coins on a timer (up to a cap), pull them with the magnet, collect on touch.
        During a Coin Rush they spawn faster, more fit on the field and each is worth more."""
        self.coin_timer -= dt
        if self.coin_timer <= 0:
            self.coin_timer += config.COIN_SPAWN_INTERVAL * (config.COIN_RUSH_INTERVAL_FACTOR if self.coin_rush else 1)
            cap = config.COIN_MAX_ON_FIELD + (config.COIN_RUSH_EXTRA_COINS if self.coin_rush else 0)
            if len(self.coins) < cap:
                self.spawn_coin()
        p = self.player
        multiplier = config.COIN_RUSH_MULT if self.coin_rush else 1
        for coin in self.coins:
            coin.update(dt, p.pos, self.stats.magnet_radius)
            if coin.touches(p.pos, p.radius):
                coin.remaining = 0
                self.coins_picked += coin.value * multiplier
                self.effects.append(Burst(coin.pos, PALETTE.coin, scale=1.3 if coin.big else 0.8))
                self.float_text(coin.pos, f"+{coin.value * multiplier}", "coin")
                self.coin_sound(coin)
        self.coins = [c for c in self.coins if c.alive]

    def coin_sound(self, coin: Coin) -> None:
        """Coins grabbed in quick succession play a little higher each time."""
        quick = self.survival_time - self.last_coin_time <= config.COIN_COMBO_WINDOW
        self.coin_combo = min(self.coin_combo + 1, config.COIN_COMBO_STEPS - 1) if quick else 0
        self.last_coin_time = self.survival_time
        self.events.append("coin_big" if coin.big else f"coin{self.coin_combo}")

    def update_powerups(self, dt: float) -> None:
        """One pickup on the map at a time; walking over it fills (or replaces) the held slot."""
        if self.powerup_slot.skill:
            self.powerup_hold -= dt
            if self.powerup_hold <= 0:
                self.toast(f"{self.powerup_slot.skill.name} expired", "text_faint", self.powerup_slot.skill.icon)
                self.powerup_slot.skill = None                      # held too long: it expires
                self.events.append("powerup_lost")
        if self.pickup is None:
            self.pickup_timer -= dt
            if self.pickup_timer <= 0:
                self.spawn_pickup()
            return
        self.pickup.update(dt)
        p = self.player
        if self.pickup.alive and self.pickup.touches(p.pos, p.radius):
            self.powerup_slot.skill = self.pickup.kind()
            self.powerup_hold = config.POWERUP_HOLD_TIME
            kind = self.pickup.kind
            self.effects.append(Burst(self.pickup.pos, kind.color_of(), scale=1.3))
            self.toast(f"{kind.name}: press {self.powerup_slot.key_label}", kind.color_name, kind.icon)
            self.events.append("powerup_get")
        elif self.pickup.alive:
            return
        self.pickup = None                                          # taken or expired
        self.pickup_timer = random.uniform(config.POWERUP_RESPAWN_MIN, config.POWERUP_RESPAWN_MAX)

    def spawn_coin(self) -> None:
        value = config.BIG_COIN_VALUE if random.random() < config.BIG_COIN_CHANCE else config.COIN_VALUE
        self.coins.append(Coin(self.open_position(), value))

    def spawn_pickup(self) -> None:
        """A random power-up, never the same kind twice in a row."""
        kind = random.choice([k for k in POWERUP_POOL if k is not self.last_pickup_kind])
        self.last_pickup_kind = kind
        self.pickup = PowerUpPickup(self.open_position(), kind)

    def open_position(self) -> Vector2:
        """A random spot clear of the HUD and not right next to the player."""
        m = config.COIN_EDGE_MARGIN
        for _ in range(20):
            pos = Vector2(random.uniform(m, config.SCREEN_WIDTH - m),
                          random.uniform(config.COIN_TOP_MARGIN, config.SCREEN_HEIGHT - config.COIN_BOTTOM_MARGIN))
            if pos.distance_to(self.player.pos) >= config.COIN_MIN_PLAYER_DISTANCE:
                return pos
        return pos                             # rare: everywhere tried was close; accept the last spot

    def block_with_walls(self) -> None:
        """Bolts that touch a wall are destroyed. Lasers pass through walls."""
        survivors = []
        for bolt in self.bolts:
            if any(bolt.shape.collides_rect(wall.shape) for wall in self.walls):
                self.effects.append(Burst(bolt.shape.center, PALETTE.wall))
                self.events.append("wall_hit")
            else:
                survivors.append(bolt)
        self.bolts = survivors

    def check_hits(self) -> None:
        p = self.player
        if p.invulnerable:
            return                                           # threats pass straight through
        for bolt in list(self.bolts):
            if bolt.shape.collides_circle(p.pos, p.hit_radius):
                if self.player_hit(bolt):
                    return
                self.bolts.remove(bolt)                      # blocked: the bolt is destroyed
                if p.invulnerable:
                    return                                   # Second Wind: untouchable at once, even this frame
        for laser in self.lasers:
            if laser.deadly and laser.shape.collides_circle(p.pos, p.hit_radius):
                if self.player_hit(laser):
                    return
                laser.disarmed = True                        # blocked: it can't hit again
                if p.invulnerable:
                    return

    def player_hit(self, source: Threat) -> bool:
        """Resolve a hit. Returns True if it ended the run, False if something saved the player.

        The shield is used first. Without one, a ready Second Wind saves the
        player and makes them untouchable for a moment.
        """
        p = self.player
        if p.consume_shield():
            self.effects.append(Burst(p.pos, PALETTE.shield, scale=1.4))
            self.float_text(p.pos + Vector2(0, -26), "BLOCKED", "shield")
            self.events.append("block")
            return False
        if self.second_wind and self.second_wind.ready:
            self.second_wind.trigger()
            p.invulnerable_remaining = config.SECOND_WIND_INVULN_TIME
            self.effects.append(Burst(p.pos, PALETTE.second_wind, scale=1.8))
            self.float_text(p.pos + Vector2(0, -26), "SAVED!", "second_wind")
            self.toast("Second Wind saved you!", "second_wind", "second_wind")
            self.events.append("second_wind")
            return False
        self.killer = source
        self.events.append("death")
        return True

    def spawn_bolt(self) -> None:
        """Spawn just outside a random edge, aimed at the player's current position."""
        offset = config.BOLT_LENGTH / 2 + config.BOLT_SPAWN_MARGIN
        w, h = config.SCREEN_WIDTH, config.SCREEN_HEIGHT
        edge = random.choice(("top", "bottom", "left", "right"))
        if edge == "top":
            spawn = Vector2(random.uniform(0, w), -offset)
        elif edge == "bottom":
            spawn = Vector2(random.uniform(0, w), h + offset)
        elif edge == "left":
            spawn = Vector2(-offset, random.uniform(0, h))
        else:
            spawn = Vector2(w + offset, random.uniform(0, h))
        speed = ramp(config.BOLT_SPEED_START, config.BOLT_SPEED_END, self.danger)
        speed *= random.uniform(1 - config.BOLT_SPEED_VARIANCE, 1 + config.BOLT_SPEED_VARIANCE)
        self.bolts.append(Bolt(spawn, self.player.pos, speed))

    def spawn_laser(self) -> None:
        """Aim a beam through the player's current position from a random angle."""
        origin = self.player.pos + Vector2(1, 0).rotate(random.uniform(0, 360)) * 100
        warning = ramp(config.LASER_WARNING_START, config.LASER_WARNING_END, self.danger) * self.rules.laser_warning
        self.lasers.append(Laser(origin, self.player.pos, warning))
        self.events.append(f"laser_warn{min(2, int(self.danger * 3))}")     # 3 tiers: higher and faster beeps

    # --- Drawing -------------------------------------------------------------------------------
    def draw(self, surface: pygame.Surface, show_path: bool = False) -> None:
        if self.marker and self.marker.alive and not self.over:
            self.marker.draw(surface)
        for coin in self.coins:
            coin.draw(surface)
        if self.pickup:
            self.pickup.draw(surface)
        for bolt in self.bolts:
            bolt.draw_trail(surface)                       # motion streaks first, under everything else
        for wall in self.walls:
            wall.draw(surface)
        for bolt in self.bolts:
            bolt.draw(surface, highlight=bolt is self.killer)
        if self.lasers:
            self.fx_layer.fill((0, 0, 0, 0))
            for laser in self.lasers:
                laser.draw(self.fx_layer)
            surface.blit(self.fx_layer, (0, 0))
        self.player.draw(surface, show_path=show_path and not self.over)
        for effect in self.effects:
            effect.draw(surface)
        if self.time_warped:
            # A blue tint that fades out over the last half second.
            self.tint.fill(PALETTE.time_warp)
            self.tint.set_alpha(int(36 * min(1.0, self.time_warp_remaining / 0.5)))
            surface.blit(self.tint, (0, 0))
        if self.over:
            pygame.draw.circle(surface, PALETTE.danger, self.player.pos, self.player.radius + 6, 3)
