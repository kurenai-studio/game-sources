"""Combat arena modes and their independent ball-mod interface."""

from __future__ import annotations

import importlib.util
import math
from dataclasses import dataclass, field
from pathlib import Path

import pygame


ROOT = Path(__file__).resolve().parent
ARENA_RECT = pygame.Rect(48, 120, 504, 504)
BOSS_RADIUS = 82
BOSS_HEALTH = 1_000
BOSS_CONTACT_DAMAGE = 12
BOSS_MELEE_ARMOR = 0.25
BOSS_RANGED_ARMOR = 0.25
BOSS_DURATION = 60.0
BACKGROUND = (12, 15, 29)


@dataclass
class ArenaBall:
    behavior: object
    x: float
    y: float
    vx: float
    vy: float
    health: float
    max_health: float
    radius: int
    shot_timer: float = 0.0
    burst_timer: float = 0.0
    burst_remaining: int = 0
    spiral_angle: float = 0.0
    contact_timer: float = 0.0
    trail: list[tuple[float, float]] = field(default_factory=list)


@dataclass
class Projectile:
    x: float
    y: float
    vx: float
    vy: float
    owner: int
    damage: float
    lifetime: float = 2.2
    bounces_remaining: int = 0


@dataclass
class ArenaGame:
    mode: str
    balls: list[ArenaBall]
    projectiles: list[Projectile]
    elapsed: float = 0.0
    boss_health: float = BOSS_HEALTH
    boss_max_health: float = BOSS_HEALTH
    ended: bool = False
    winner: int | None = None


def available_behaviors() -> list[str]:
    return sorted(p.stem for p in (ROOT / "arena_balls").glob("*.py")
                  if p.is_file() and not p.name.startswith("_"))


def load_behavior(name: str):
    path = ROOT / "arena_balls" / f"{name}.py"
    if not path.is_file():
        raise ValueError(f"Не найден аренный мод мяча: {name}")
    spec = importlib.util.spec_from_file_location(f"arena_ball_mod_{name}", path)
    if spec is None or spec.loader is None:
        raise ValueError(f"Не удалось загрузить {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    behavior = module.Behavior()
    required = ("name", "description", "color", "health", "radius",
                "contact_damage", "shot_damage", "shot_interval", "shot_speed")
    missing = [attr for attr in required if not hasattr(behavior, attr)]
    if missing:
        raise ValueError(f"В {path.name} отсутствуют параметры: {', '.join(missing)}")
    legacy_speed = float(getattr(behavior, "speed", 300.0))
    if not hasattr(behavior, "min_speed"):
        behavior.min_speed = legacy_speed * 0.7
    if not hasattr(behavior, "max_speed"):
        behavior.max_speed = legacy_speed * 1.2
    behavior.min_speed = max(0.0, float(behavior.min_speed))
    behavior.max_speed = max(behavior.min_speed, float(behavior.max_speed))
    if not hasattr(behavior, "start_speed"):
        behavior.start_speed = legacy_speed if hasattr(behavior, "speed") else behavior.min_speed
    for attr in ("melee_armor", "ranged_armor", "melee_penetration", "ranged_penetration"):
        setattr(behavior, attr, min(1.0, max(0.0, float(getattr(behavior, attr, 0.0)))))
    return behavior


def _make_ball(behavior, x: float, y: float, angle: float, health_scale: float = 1.0):
    speed = min(float(behavior.max_speed), max(float(behavior.min_speed),
                                               float(behavior.start_speed)))
    return ArenaBall(
        behavior, x, y, speed * math.cos(angle), speed * math.sin(angle),
        float(behavior.health) * health_scale, float(behavior.health) * health_scale,
        int(behavior.radius), shot_timer=0.55,
    )


def new_game(mode: str, behaviors: list[object]) -> ArenaGame:
    if mode == "duel":
        if len(behaviors) != 2:
            raise ValueError("Для дуэли нужны два мяча")
        balls = [
            _make_ball(behaviors[0], ARENA_RECT.left + 92, ARENA_RECT.top + 108, 0.84),
            _make_ball(behaviors[1], ARENA_RECT.right - 92, ARENA_RECT.bottom - 108, math.pi + 0.84),
        ]
        return ArenaGame(mode, balls, [])
    if mode == "boss" and len(behaviors) == 1:
        behavior = behaviors[0]
        ball = _make_ball(behavior, ARENA_RECT.centerx, ARENA_RECT.top + 102, 0.72)
        ball.health = ball.max_health = 120.0
        return ArenaGame(mode, [ball], [])
    raise ValueError(f"Неизвестный режим арены: {mode}")


def _target_direction(game: ArenaGame, owner: int) -> tuple[float, float]:
    ball = game.balls[owner]
    if game.mode == "boss":
        target_x, target_y = ARENA_RECT.center
    else:
        target = game.balls[1 - owner]
        target_x, target_y = target.x, target.y
    dx, dy = target_x - ball.x, target_y - ball.y
    distance = math.hypot(dx, dy) or 1.0
    return dx / distance, dy / distance


def _spawn_shot(game: ArenaGame, ball: ArenaBall, owner: int,
                direction: tuple[float, float]):
    behavior = ball.behavior
    vx, vy = direction
    bouncing = getattr(behavior, "bouncing", 0) == 1
    bounce_count = max(0, int(getattr(behavior, "bouncing_count", 0))) if bouncing else 0
    # The lifetime countdown starts after this individual projectile spends
    # its own ricochet budget; it cannot expire in sync with its volley mates.
    game.projectiles.append(Projectile(
        ball.x + vx * (ball.radius + 5), ball.y + vy * (ball.radius + 5),
        vx * behavior.shot_speed, vy * behavior.shot_speed, owner,
        float(behavior.shot_damage),
        bounces_remaining=bounce_count,
    ))


def _fire(game: ArenaGame, owner: int):
    ball = game.balls[owner]
    behavior = ball.behavior
    if behavior.shot_damage <= 0:
        return
    pattern = getattr(behavior, "shot_pattern", "cross")

    if pattern == "shotgun":
        if ball.burst_remaining == 0:
            if ball.shot_timer > 0:
                return
            ball.burst_remaining = 3
        if ball.burst_timer > 0:
            return
        _spawn_shot(game, ball, owner, _target_direction(game, owner))
        ball.burst_remaining -= 1
        if ball.burst_remaining:
            ball.burst_timer = 0.11
        else:
            ball.shot_timer = float(behavior.shot_interval)
        return

    if ball.shot_timer > 0:
        return
    if pattern == "aimed":
        directions = [_target_direction(game, owner)]
    elif pattern == "spiral":
        directions = [(math.cos(ball.spiral_angle), math.sin(ball.spiral_angle))]
        ball.spiral_angle = (ball.spiral_angle + 0.48) % math.tau
    else:
        directions = ((1, 0), (-1, 0), (0, 1), (0, -1))
    for direction in directions:
        _spawn_shot(game, ball, owner, direction)
    ball.shot_timer = float(behavior.shot_interval)


def _move_ball(ball: ArenaBall, dt: float):
    ball.x += ball.vx * dt
    ball.y += ball.vy * dt
    left, right = ARENA_RECT.left + ball.radius, ARENA_RECT.right - ball.radius
    top, bottom = ARENA_RECT.top + ball.radius, ARENA_RECT.bottom - ball.radius
    if ball.x < left:
        ball.x, ball.vx = left, abs(ball.vx)
    elif ball.x > right:
        ball.x, ball.vx = right, -abs(ball.vx)
    if ball.y < top:
        ball.y, ball.vy = top, abs(ball.vy)
    elif ball.y > bottom:
        ball.y, ball.vy = bottom, -abs(ball.vy)
    ball.trail.append((ball.x, ball.y))
    if len(ball.trail) > 10:
        ball.trail.pop(0)


def _armor(target: ArenaBall | None, attack_type: str) -> float:
    if target is None:
        return BOSS_MELEE_ARMOR if attack_type == "melee" else BOSS_RANGED_ARMOR
    return float(getattr(target.behavior, f"{attack_type}_armor", 0.0))


def _apply_damage(target: ArenaBall | None, health: float, amount: float,
                  attack_type: str, penetration: float = 0.0) -> tuple[float, float]:
    armor = _armor(target, attack_type)
    penetration = min(1.0, max(0.0, penetration))
    effective = max(0.0, amount) * (1.0 - armor * (1.0 - penetration))
    actual = min(max(0.0, health), effective)
    return max(0.0, health - actual), actual


def _heal(ball: ArenaBall, amount: float):
    ball.health = min(ball.max_health, ball.health + max(0.0, amount))


def _damage_ball(attacker: ArenaBall, target: ArenaBall, amount: float, attack_type: str):
    penetration = float(getattr(attacker.behavior, f"{attack_type}_penetration", 0.0))
    target.health, actual_damage = _apply_damage(
        target, target.health, amount, attack_type, penetration)
    vampirism = max(0.0, float(getattr(attacker.behavior, "vampirism", 0.0)))
    _heal(attacker, actual_damage * vampirism)


def _damage_boss(game: ArenaGame, attacker: ArenaBall, amount: float, attack_type: str):
    penetration = float(getattr(attacker.behavior, f"{attack_type}_penetration", 0.0))
    armor = BOSS_MELEE_ARMOR if attack_type == "melee" else BOSS_RANGED_ARMOR
    effective = max(0.0, amount) * (1.0 - armor * (1.0 - min(1.0, max(0.0, penetration))))
    actual_damage = min(game.boss_health, effective)
    game.boss_health = max(0.0, game.boss_health - actual_damage)
    vampirism = max(0.0, float(getattr(attacker.behavior, "vampirism", 0.0)))
    _heal(attacker, actual_damage * vampirism)


def _set_ball_speed(ball: ArenaBall, desired_speed: float):
    minimum = max(0.0, float(ball.behavior.min_speed))
    maximum = max(minimum, float(ball.behavior.max_speed))
    speed = min(maximum, max(minimum, desired_speed))
    current = math.hypot(ball.vx, ball.vy)
    if current <= 1e-9:
        ball.vx, ball.vy = speed, 0.0
    else:
        scale = speed / current
        ball.vx *= scale
        ball.vy *= scale


def _transfer_speed(a: ArenaBall, b: ArenaBall,
                    speed_a_before: float, speed_b_before: float):
    # Move part of the pre-impact speed gap, respecting each ball's speed range.
    for donor, receiver, donor_before, receiver_before in (
            (a, b, speed_a_before, speed_b_before),
            (b, a, speed_b_before, speed_a_before)):
        fraction = min(1.0, max(0.0, float(getattr(donor.behavior, "speed_transfer", 0.0))))
        receiver_max = float(receiver.behavior.max_speed)
        donor_min = float(donor.behavior.min_speed)
        speed_gap = max(0.0, donor_before - receiver_before)
        amount = min(speed_gap * fraction,
                     max(0.0, donor_before - donor_min),
                     max(0.0, receiver_max - receiver_before))
        if amount > 0:
            _set_ball_speed(donor, donor_before - amount)
            _set_ball_speed(receiver, receiver_before + amount)


def _collide_duel(game: ArenaGame):
    a, b = game.balls
    dx, dy = b.x - a.x, b.y - a.y
    distance = math.hypot(dx, dy)
    min_distance = a.radius + b.radius
    if distance >= min_distance:
        return
    if distance < 1e-8:
        nx, ny, distance = 1.0, 0.0, 1.0
    else:
        nx, ny = dx / distance, dy / distance
    overlap = min_distance - distance
    a.x -= nx * overlap * 0.5
    a.y -= ny * overlap * 0.5
    b.x += nx * overlap * 0.5
    b.y += ny * overlap * 0.5
    speed_a_before = math.hypot(a.vx, a.vy)
    speed_b_before = math.hypot(b.vx, b.vy)
    rel = (b.vx - a.vx) * nx + (b.vy - a.vy) * ny
    if rel < 0:
        a.vx += rel * nx
        a.vy += rel * ny
        b.vx -= rel * nx
        b.vy -= rel * ny
        _transfer_speed(a, b, speed_a_before, speed_b_before)
    _set_ball_speed(a, math.hypot(a.vx, a.vy))
    _set_ball_speed(b, math.hypot(b.vx, b.vy))
    if a.contact_timer <= 0:
        _damage_ball(a, b, float(a.behavior.contact_damage), "melee")
        a.contact_timer = 0.42
    if b.contact_timer <= 0:
        _damage_ball(b, a, float(b.behavior.contact_damage), "melee")
        b.contact_timer = 0.42


def _collide_boss(game: ArenaGame):
    ball = game.balls[0]
    dx, dy = ball.x - ARENA_RECT.centerx, ball.y - ARENA_RECT.centery
    distance = math.hypot(dx, dy)
    minimum = BOSS_RADIUS + ball.radius
    if distance >= minimum:
        return
    nx, ny = (dx / distance, dy / distance) if distance > 1e-8 else (0.0, -1.0)
    ball.x, ball.y = ARENA_RECT.centerx + nx * minimum, ARENA_RECT.centery + ny * minimum
    dot = ball.vx * nx + ball.vy * ny
    if dot < 0:
        ball.vx -= 2 * dot * nx
        ball.vy -= 2 * dot * ny
    if ball.contact_timer <= 0:
        _damage_boss(game, ball, float(ball.behavior.contact_damage), "melee")
        ball.health, _ = _apply_damage(ball, ball.health, BOSS_CONTACT_DAMAGE, "melee")
        ball.contact_timer = 0.48


def update_game(game: ArenaGame, dt: float) -> bool:
    if game.ended:
        return True
    dt = min(max(0.0, dt), 1 / 30)
    game.elapsed += dt
    for index, ball in enumerate(game.balls):
        ball.shot_timer -= dt
        ball.burst_timer -= dt
        ball.contact_timer -= dt
        _fire(game, index)
        _move_ball(ball, dt)

    if game.mode == "duel":
        _collide_duel(game)
    else:
        _collide_boss(game)

    for shot in game.projectiles:
        shot.x += shot.vx * dt
        shot.y += shot.vy * dt
        if shot.bounces_remaining == 0:
            shot.lifetime -= dt
        wall_hit = False
        if shot.x < ARENA_RECT.left or shot.x > ARENA_RECT.right:
            if shot.bounces_remaining:
                shot.x = min(ARENA_RECT.right, max(ARENA_RECT.left, shot.x))
                shot.vx *= -1
                wall_hit = True
            else:
                shot.lifetime = 0
        if shot.y < ARENA_RECT.top or shot.y > ARENA_RECT.bottom:
            if shot.bounces_remaining:
                shot.y = min(ARENA_RECT.bottom, max(ARENA_RECT.top, shot.y))
                shot.vy *= -1
                wall_hit = True
            else:
                shot.lifetime = 0
        if wall_hit:
            shot.bounces_remaining -= 1
            if shot.bounces_remaining == 0:
                shot.lifetime = 2.2
        if game.mode == "duel":
            target_index = 1 - shot.owner
            target = game.balls[target_index]
            if shot.lifetime > 0 and math.hypot(shot.x - target.x, shot.y - target.y) <= target.radius + 5:
                _damage_ball(game.balls[shot.owner], target, shot.damage, "ranged")
                shot.lifetime = 0
        else:
            if shot.lifetime > 0 and math.hypot(shot.x - ARENA_RECT.centerx,
                          shot.y - ARENA_RECT.centery) <= BOSS_RADIUS + 5:
                _damage_boss(game, game.balls[shot.owner], shot.damage, "ranged")
                shot.lifetime = 0
    game.projectiles[:] = [s for s in game.projectiles
                           if s.lifetime > 0 and ARENA_RECT.inflate(80, 80).collidepoint(s.x, s.y)]

    if game.mode == "duel":
        if game.balls[0].health <= 0 or game.balls[1].health <= 0:
            game.ended = True
            if game.balls[0].health <= 0 and game.balls[1].health <= 0:
                game.winner = None
            else:
                game.winner = 0 if game.balls[1].health <= 0 else 1
    else:
        if game.boss_health <= 0:
            game.ended, game.winner = True, 0
        elif game.balls[0].health <= 0 or game.elapsed >= BOSS_DURATION:
            game.ended, game.winner = True, None
    return game.ended


def _draw_text(surface, text, font, color, pos):
    image = font.render(str(text), True, color)
    surface.blit(image, image.get_rect(center=pos))


def _draw_bar(surface, x: int, y: int, width: int, height: int,
              value: float, maximum: float, color):
    pygame.draw.rect(surface, (34, 40, 59), (x, y, width, height), border_radius=5)
    ratio = 0 if maximum <= 0 else min(1.0, max(0.0, value / maximum))
    if ratio:
        pygame.draw.rect(surface, color, (x, y, round(width * ratio), height), border_radius=5)


def _pattern_label(behavior) -> str:
    return {
        "cross": "ЗАЛП В 4 СТОРОНЫ",
        "aimed": "ПРИЦЕЛЬНЫЙ ВЫСТРЕЛ",
        "spiral": "СПИРАЛЬНЫЙ ЗАЛП",
        "shotgun": "ДРОБОВИК · 3 ВЫСТРЕЛА",
    }.get(getattr(behavior, "shot_pattern", "cross"), "ЗАЛП В 4 СТОРОНЫ")


def _draw_ball_stats(surface, fonts, ball: ArenaBall, rect: pygame.Rect, label: str):
    _, _, small_font = fonts
    stat_font = pygame.font.SysFont("dejavusans", 12)
    pygame.draw.rect(surface, (20, 26, 44), rect, border_radius=14)
    pygame.draw.rect(surface, (57, 70, 100), rect, width=1, border_radius=14)
    color = ball.behavior.color
    cx = rect.centerx
    _draw_text(surface, f"{label} · {ball.behavior.name}", small_font, color, (cx, rect.top + 17))
    _draw_bar(surface, rect.left + 12, rect.top + 30, rect.width - 24, 10,
              ball.health, ball.max_health, color)
    rows = [
        f"HP {ball.health:.0f} / {ball.max_health:.0f}",
        f"СКОРОСТЬ {math.hypot(ball.vx, ball.vy):.0f}  [{ball.behavior.min_speed:.0f}–{ball.behavior.max_speed:.0f}]",
        f"КОНТАКТ {ball.behavior.contact_damage:g} · ВЫСТРЕЛ {ball.behavior.shot_damage:g}",
        f"БРОНЯ · БЛИЖ {ball.behavior.melee_armor:.0%} · ДАЛЬ {ball.behavior.ranged_armor:.0%}",
        f"ПРОБИТИЕ · БЛИЖ {ball.behavior.melee_penetration:.0%} · ДАЛЬ {ball.behavior.ranged_penetration:.0%}",
        f"АТАКА · {_pattern_label(ball.behavior) if ball.behavior.shot_damage else 'ТОЛЬКО КОНТАКТ'}",
        f"ИНТЕРВАЛ {ball.behavior.shot_interval:g}с · СНАРЯД {ball.behavior.shot_speed:g}",
        f"ВАМПИРИЗМ {getattr(ball.behavior, 'vampirism', 0):g} · ПЕРЕДАЧА {getattr(ball.behavior, 'speed_transfer', 0):.0%}",
        f"РИКОШЕТЫ {getattr(ball.behavior, 'bouncing_count', 0) if getattr(ball.behavior, 'bouncing', 0) == 1 else 0}",
    ]
    for index, row in enumerate(rows):
        _draw_text(surface, row, stat_font, (186, 198, 220), (cx, rect.top + 53 + index * 23))


def _draw_boss_stats(surface, fonts, rect: pygame.Rect, health: float, max_health: float):
    _, _, small_font = fonts
    stat_font = pygame.font.SysFont("dejavusans", 12)
    pygame.draw.rect(surface, (35, 24, 43), rect, border_radius=14)
    pygame.draw.rect(surface, (112, 54, 78), rect, width=1, border_radius=14)
    cx = rect.centerx
    _draw_text(surface, "ЦЕНТРАЛЬНЫЙ БОСС", small_font, (255, 157, 166), (cx, rect.top + 17))
    _draw_bar(surface, rect.left + 12, rect.top + 30, rect.width - 24, 10,
              health, max_health, (220, 76, 102))
    rows = [
        f"HP {health:.0f} / {max_health:.0f}",
        "СКОРОСТЬ 0 · НЕ ДВИГАЕТСЯ",
        f"КОНТАКТНЫЙ УРОН {BOSS_CONTACT_DAMAGE}",
        f"БРОНЯ · БЛИЖ {BOSS_MELEE_ARMOR:.0%} · ДАЛЬ {BOSS_RANGED_ARMOR:.0%}",
        "ПРОБИТИЕ · БЛИЖ 0% · ДАЛЬ 0%",
        "АТАКА · КОНТАКТ",
        "СНАРЯДЫ · НЕТ",
        "СПЕЦИАЛЬНЫЕ ЭФФЕКТЫ · НЕТ",
    ]
    for index, row in enumerate(rows):
        _draw_text(surface, row, stat_font, (219, 180, 193), (cx, rect.top + 53 + index * 23))


def draw_game(surface, fonts, game: ArenaGame, menu_rect: pygame.Rect):
    title_font, medium_font, small_font = fonts
    surface.fill(BACKGROUND)
    title = "ДУЭЛЬ МЯЧЕЙ" if game.mode == "duel" else "БОЙ С БОССОМ"
    _draw_text(surface, title, title_font, (239, 242, 255), (surface.get_width() // 2, 38))
    pygame.draw.rect(surface, (29, 36, 58), menu_rect, border_radius=9)
    _draw_text(surface, "МЕНЮ", small_font, (201, 211, 234), menu_rect.center)
    pygame.draw.rect(surface, (19, 24, 42), ARENA_RECT, border_radius=20)
    pygame.draw.rect(surface, (73, 88, 123), ARENA_RECT, width=3, border_radius=20)

    if game.mode == "boss":
        cx, cy = ARENA_RECT.center
        pulse = 5 * math.sin(game.elapsed * 3)
        pygame.draw.circle(surface, (105, 33, 61), (cx, cy), round(BOSS_RADIUS + pulse + 7))
        pygame.draw.circle(surface, (205, 65, 92), (cx, cy), BOSS_RADIUS)
        pygame.draw.circle(surface, (255, 157, 166), (cx - 25, cy - 27), 14)
        pygame.draw.circle(surface, (255, 220, 222), (cx - 29, cy - 32), 5)

    for shot in game.projectiles:
        color = game.balls[shot.owner].behavior.color
        pygame.draw.circle(surface, color, (round(shot.x), round(shot.y)), 5)
        pygame.draw.circle(surface, (255, 255, 255), (round(shot.x), round(shot.y)), 2)

    for ball in game.balls:
        for i, (x, y) in enumerate(ball.trail):
            pygame.draw.circle(surface, ball.behavior.color, (round(x), round(y)), 3 + i // 4)
        pygame.draw.circle(surface, (245, 248, 255), (round(ball.x), round(ball.y)), ball.radius + 3)
        pygame.draw.circle(surface, ball.behavior.color, (round(ball.x), round(ball.y)), ball.radius)
        pygame.draw.circle(surface, (255, 255, 255), (round(ball.x - 4), round(ball.y - 5)), 4)

    left, right = 48, 308
    card_size = (244, 284)
    if game.mode == "duel":
        _draw_ball_stats(surface, fonts, game.balls[0],
                         pygame.Rect(left, 644, *card_size), "A")
        _draw_ball_stats(surface, fonts, game.balls[1],
                         pygame.Rect(right, 644, *card_size), "B")
    else:
        remaining = max(0.0, BOSS_DURATION - game.elapsed)
        _draw_text(surface, f"ОСТАЛОСЬ {remaining:04.1f} СЕК.", medium_font,
                   (245, 219, 145), (surface.get_width() // 2, 640))
        _draw_ball_stats(surface, fonts, game.balls[0],
                         pygame.Rect(left, 656, *card_size), "ИГРОК")
        _draw_boss_stats(surface, fonts,
                         pygame.Rect(right, 656, *card_size),
                         game.boss_health, game.boss_max_health)

    if game.ended:
        veil = pygame.Surface(surface.get_size(), pygame.SRCALPHA)
        veil.fill((4, 6, 15, 205))
        surface.blit(veil, (0, 0))
        if game.mode == "boss":
            heading = "БОСС ПОБЕЖДЁН!" if game.winner == 0 else "ВРЕМЯ ВЫШЛО" if game.elapsed >= BOSS_DURATION else "МЯЧ ВЫБЫЛ"
            detail = f"Здоровье босса: {int(game.boss_health)} / {int(game.boss_max_health)}"
        elif game.winner is None:
            heading, detail = "НИЧЬЯ!", "Оба мяча выбыли"
        else:
            heading = f"ПОБЕДИЛ МЯЧ {'A' if game.winner == 0 else 'B'}!"
            detail = game.balls[game.winner].behavior.name
        _draw_text(surface, heading, title_font, (255, 255, 255),
                   (surface.get_width() // 2, surface.get_height() // 2 - 28))
        _draw_text(surface, detail, small_font, (199, 211, 235),
                   (surface.get_width() // 2, surface.get_height() // 2 + 18))
        restart = pygame.Rect(surface.get_width() // 2 - 125,
                              surface.get_height() // 2 + 74, 250, 48)
        pygame.draw.rect(surface, (52, 71, 112), restart, border_radius=12)
        pygame.draw.rect(surface, (117, 151, 220), restart, width=2, border_radius=12)
        _draw_text(surface, "ЗАНОВО · R", small_font, (255, 255, 255), restart.center)
