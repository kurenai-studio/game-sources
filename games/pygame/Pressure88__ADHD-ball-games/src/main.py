#!/usr/bin/env python3
"""Realtime modular ball-and-planks game."""

from __future__ import annotations

import argparse
import importlib.util
import math
import sys
from dataclasses import dataclass
from pathlib import Path

import pygame
from ring_mode import RingBehavior, RingGame, draw_ring_game, make_ring_game, update_ring_game
from arena_mode import (ArenaGame, available_behaviors as available_arena_behaviors,
                        draw_game as draw_arena_game, load_behavior as load_arena_behavior,
                        new_game as new_arena_game, update_game as update_arena_game)


ROOT = Path(__file__).resolve().parent
WIDTH, HEIGHT = 600, 960
FPS = 60
BG = (12, 15, 29)
FIELD = pygame.Rect(64, 104, 472, 790)
BALL_RADIUS = 15
GRAVITY = 900.0
PLANK_COUNT = 12
PLANK_HEALTH = (1, 5, 10, 50, 100, 500, 1_000, 5_000, 10_000, 50_000, 100_000, 500_000)
MAX_EVENTS_PER_FRAME = 1_000
BALL_CARD_HEIGHT = 126
BALL_CARD_GAP = 14
BALL_CARD_STRIDE = BALL_CARD_HEIGHT + BALL_CARD_GAP


@dataclass
class Plank:
    number: int
    rect: pygame.Rect
    health: int
    max_health: int
    color: tuple[int, int, int]
    alive: bool = True


@dataclass
class Ball:
    x: float
    y: float
    vx: float
    vy: float
    speed: float
    arena: pygame.Rect
    hits: int = 0
    trail: list[tuple[float, float]] | None = None
    pending_time: float = 0.0


@dataclass
class Competitor:
    label: str
    behavior: object
    planks: list[Plank]
    ball: Ball
    finished_at: float | None = None
    success: bool | None = None


def load_behavior(name: str):
    path = ROOT / "balls" / f"{name}.py"
    if not path.is_file():
        choices = ", ".join(available_behaviors())
        raise ValueError(f"Не найден мод {name!r}. Доступны: {choices}")
    spec = importlib.util.spec_from_file_location(f"ball_mod_{name}", path)
    if spec is None or spec.loader is None:
        raise ValueError(f"Не удалось загрузить {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    if not hasattr(module, "Behavior"):
        raise ValueError(f"В файле {path.name} должен быть класс Behavior")
    return module.Behavior()


def available_behaviors() -> list[str]:
    return sorted(path.stem for path in (ROOT / "balls").glob("*.py") if not path.name.startswith("_"))


def make_planks(arena: pygame.Rect = FIELD) -> list[Plank]:
    planks = []
    palette = [(75, 130, 220), (91, 119, 225), (112, 109, 219), (139, 97, 207)]
    height = 40
    usable = arena.height - 48
    spacing = usable / PLANK_COUNT
    for i in range(PLANK_COUNT):
        y = arena.top + 36 + int(i * spacing)
        rect = pygame.Rect(arena.left + 2, y, arena.width - 4, height)
        color = palette[i % len(palette)]
        health = PLANK_HEALTH[i]
        planks.append(Plank(health, rect, health, health, color))
    return planks


def reset_game(behavior, arena: pygame.Rect = FIELD) -> tuple[list[Plank], Ball, bool]:
    speed = float(behavior.initial_speed())
    if not math.isfinite(speed):
        speed = sys.float_info.max if speed > 0 else 0.0
    speed = max(0.0, speed)
    # Starts with a small sideways component so it can meet offset platforms.
    ball = Ball(arena.centerx, arena.top + 20, speed * 0.28, 0.0,
                speed, arena, trail=[])
    return make_planks(arena), ball, False


def draw_text(surface, text, font, color, pos, center=True):
    image = font.render(str(text), True, color)
    rect = image.get_rect(center=pos) if center else image.get_rect(topleft=pos)
    surface.blit(image, rect)


def compact_number(value: float) -> str:
    """Format large stats with Russian short units: тыс., млн., млрд."""
    units = ("", "тыс.", "млн.", "млрд.", "трлн.", "квдрлн.")
    original = float(value)
    number = original
    unit_index = 0
    while abs(number) >= 1000 and unit_index < len(units) - 1:
        number /= 1000
        unit_index += 1
    if unit_index and round(abs(number), 1) >= 1000 and unit_index < len(units) - 1:
        number /= 1000
        unit_index += 1
    if unit_index == 0:
        return str(int(number))
    if abs(number) >= 1000:
        return f"{original:.2e}".replace(".", ",")
    short_value = f"{number:.1f}".rstrip("0").rstrip(".").replace(".", ",")
    return f"{short_value} {units[unit_index]}"


def restart_button_rect() -> pygame.Rect:
    return pygame.Rect(WIDTH // 2 - 125, HEIGHT // 2 + 74, 250, 48)


def exit_button_rect() -> pygame.Rect:
    return pygame.Rect(WIDTH // 2 - 90, HEIGHT - 56, 180, 38)


def mode_card_rects() -> list[pygame.Rect]:
    return [pygame.Rect(62, 340, WIDTH - 124, 150),
            pygame.Rect(62, 515, WIDTH - 124, 150)]


def main_menu_card_rects() -> list[pygame.Rect]:
    return [pygame.Rect(62, 265 + index * 150, WIDTH - 124, 130) for index in range(3)]


def main_menu_back_rect() -> pygame.Rect:
    return pygame.Rect(20, 20, 100, 36)


def race_arenas() -> list[pygame.Rect]:
    lane_width = (FIELD.width - 14) // 2
    return [pygame.Rect(FIELD.left, FIELD.top, lane_width, FIELD.height),
            pygame.Rect(FIELD.left + lane_width + 14, FIELD.top, lane_width, FIELD.height)]


def ball_list_rect() -> pygame.Rect:
    return pygame.Rect(44, 164, WIDTH - 88, 668)


def max_ball_scroll(choice_count: int) -> int:
    content_height = max(0, choice_count * BALL_CARD_STRIDE - BALL_CARD_GAP)
    return max(0, content_height - ball_list_rect().height)


def clamp_ball_scroll(scroll: int, choice_count: int) -> int:
    return max(0, min(scroll, max_ball_scroll(choice_count)))


def keep_ball_visible(index: int, scroll: int, choice_count: int) -> int:
    viewport = ball_list_rect()
    card_top = viewport.top + index * BALL_CARD_STRIDE - scroll
    if card_top < viewport.top:
        scroll = index * BALL_CARD_STRIDE
    elif card_top + BALL_CARD_HEIGHT > viewport.bottom:
        scroll = index * BALL_CARD_STRIDE + BALL_CARD_HEIGHT - viewport.height
    return clamp_ball_scroll(scroll, choice_count)


def ball_card_rects(choice_count: int, scroll: int = 0) -> list[pygame.Rect]:
    viewport = ball_list_rect()
    return [pygame.Rect(58, viewport.top + index * BALL_CARD_STRIDE - scroll,
                        WIDTH - 116, BALL_CARD_HEIGHT)
            for index in range(choice_count)]


def assign_button_rect(card: pygame.Rect, slot: int) -> pygame.Rect:
    return pygame.Rect(card.right - 98 + slot * 46, card.centery - 18, 40, 36)


def race_start_rect() -> pygame.Rect:
    return pygame.Rect(WIDTH // 2 - 132, HEIGHT - 100, 264, 48)


def menu_button_rect() -> pygame.Rect:
    return pygame.Rect(WIDTH - 100, 20, 82, 32)


def draw_mode_menu(surface, fonts, selected):
    title_font, medium_font, small_font = fonts
    surface.fill(BG)
    back = main_menu_back_rect()
    pygame.draw.rect(surface, (29, 36, 58), back, border_radius=9)
    draw_text(surface, "НАЗАД", small_font, (201, 211, 234), back.center)
    draw_text(surface, "PLANK BREAKER", title_font, (239, 242, 255), (WIDTH // 2, 105))
    draw_text(surface, "РЕЖИМ ПЛАНОК", medium_font, (161, 179, 215), (WIDTH // 2, 174))
    cards = mode_card_rects()
    labels = [("ОДИН МЯЧ", "Обычный режим: выбери один мод и пробей планки."),
              ("ГОНКА ДВУХ МЯЧЕЙ", "Две независимые дорожки. Кто быстрее пробьёт свою?")]
    for index, (name, description) in enumerate(labels):
        rect = cards[index]
        is_selected = index == selected
        background = (38, 48, 75) if is_selected else (24, 30, 50)
        border = (110, 163, 255) if is_selected else (48, 59, 88)
        pygame.draw.rect(surface, background, rect, border_radius=16)
        pygame.draw.rect(surface, border, rect, width=2 if is_selected else 1, border_radius=16)
        draw_text(surface, name, medium_font, (245, 247, 255),
                  (rect.centerx, rect.top + 51))
        draw_text(surface, description, small_font, (177, 190, 219),
                  (rect.centerx, rect.top + 96))
    draw_text(surface, "↑ ↓ — выбор     Enter — продолжить     Esc — назад", small_font,
              (198, 208, 231), (WIDTH // 2, HEIGHT - 106))
    draw_text(surface, "Или нажми на карточку мышью", small_font,
              (115, 132, 166), (WIDTH // 2, HEIGHT - 77))
    return cards


def draw_main_menu(surface, fonts, selected):
    title_font, medium_font, small_font = fonts
    surface.fill(BG)
    draw_text(surface, "PLANK BREAKER", title_font, (239, 242, 255), (WIDTH // 2, 105))
    draw_text(surface, "ВЫБЕРИ РЕЖИМ ИГРЫ", medium_font, (161, 179, 215), (WIDTH // 2, 174))
    cards = main_menu_card_rects()
    labels = [("ПЛАНКИ", "Одиночный режим или гонка двух мячей"),
              ("КОЛЬЦА", "Пройди через отверстия во вращающихся кольцах"),
              ("АРЕНА", "Дуэль двух мячей или бой с боссом за 60 секунд")]
    for index, (label, description) in enumerate(labels):
        rect = cards[index]
        chosen = index == selected
        bg = (38, 48, 75) if chosen else (24, 30, 50)
        border = (110, 163, 255) if chosen else (48, 59, 88)
        pygame.draw.rect(surface, bg, rect, border_radius=16)
        pygame.draw.rect(surface, border, rect, width=2 if chosen else 1, border_radius=16)
        draw_text(surface, label, medium_font, (245, 247, 255), (rect.centerx, rect.top + 43))
        draw_text(surface, description, small_font, (177, 190, 219), (rect.centerx, rect.top + 87))
    draw_text(surface, "↑ ↓ — выбор     Enter — продолжить", small_font,
              (198, 208, 231), (WIDTH // 2, HEIGHT - 113))
    exit_button = exit_button_rect()
    pygame.draw.rect(surface, (39, 34, 51), exit_button, border_radius=10)
    pygame.draw.rect(surface, (100, 78, 102), exit_button, width=1, border_radius=10)
    draw_text(surface, "ВЫХОД", small_font, (212, 194, 211), exit_button.center)
    return cards


def draw_arena_mode_menu(surface, fonts, selected):
    title_font, medium_font, small_font = fonts
    surface.fill(BG)
    back = main_menu_back_rect()
    pygame.draw.rect(surface, (29, 36, 58), back, border_radius=9)
    draw_text(surface, "НАЗАД", small_font, (201, 211, 234), back.center)
    draw_text(surface, "АРЕНА", title_font, (239, 242, 255), (WIDTH // 2, 105))
    draw_text(surface, "ВЫБЕРИ РЕЖИМ БОЯ", medium_font, (161, 179, 215), (WIDTH // 2, 174))
    cards = mode_card_rects()
    labels = [("ДУЭЛЬ ДВУХ МЯЧЕЙ", "Два разных мода сражаются в квадратной арене"),
              ("БОЙ С БОССОМ", "Победи центральный шар за 60 секунд")]
    for index, (name, description) in enumerate(labels):
        rect = cards[index]
        chosen = index == selected
        pygame.draw.rect(surface, (38, 48, 75) if chosen else (24, 30, 50), rect, border_radius=16)
        pygame.draw.rect(surface, (110, 163, 255) if chosen else (48, 59, 88),
                         rect, width=2 if chosen else 1, border_radius=16)
        draw_text(surface, name, medium_font, (245, 247, 255), (rect.centerx, rect.top + 51))
        draw_text(surface, description, small_font, (177, 190, 219), (rect.centerx, rect.top + 96))
    draw_text(surface, "↑ ↓ — выбор     Enter — продолжить     Esc — назад", small_font,
              (198, 208, 231), (WIDTH // 2, HEIGHT - 106))
    return cards


def draw_ball_menu(surface, fonts, choices, selected, mode, assignments, scroll):
    title_font, medium_font, small_font = fonts
    surface.fill(BG)
    draw_text(surface, "ВЫБЕРИ МЯЧИ", title_font, (239, 242, 255), (WIDTH // 2, 82))
    prompt = ("Выбери мод мяча" if mode in ("single", "rings")
              else "Назначь разные моды игрокам A и B")
    draw_text(surface, prompt, small_font, (161, 179, 215), (WIDTH // 2, 126))
    if mode == "race":
        assigned_names = [choices[index][1].name if index is not None else "—" for index in assignments]
        draw_text(surface, f"A: {assigned_names[0]}    B: {assigned_names[1]}", small_font,
                  (190, 204, 232), (WIDTH // 2, 147))
    cards = ball_card_rects(len(choices), scroll)
    viewport = ball_list_rect()
    old_clip = surface.get_clip()
    surface.set_clip(viewport)
    for index, (name, behavior) in enumerate(choices):
        rect = cards[index]
        cursor_selected = mode == "race" and index == selected
        selected_single = mode in ("single", "rings") and index == selected
        assigned_a = mode == "race" and assignments[0] == index
        assigned_b = mode == "race" and assignments[1] == index
        assigned_color = (83, 190, 255) if assigned_a else (255, 157, 105)
        border = ((242, 246, 255) if cursor_selected else behavior.color
                  if selected_single else assigned_color if assigned_a or assigned_b else (48, 59, 88))
        background = (38, 48, 75) if cursor_selected or assigned_a or assigned_b else (24, 30, 50)
        pygame.draw.rect(surface, background, rect, border_radius=16)
        pygame.draw.rect(surface, border,
                         rect, width=3 if cursor_selected else 2 if selected_single or assigned_a or assigned_b else 1,
                         border_radius=16)
        pygame.draw.circle(surface, behavior.color, (rect.left + 34, rect.centery), 11)
        draw_text(surface, behavior.name, medium_font, (245, 247, 255),
                  (rect.left + 58, rect.top + 33), center=False)
        draw_text(surface, behavior.description or name, small_font, (177, 190, 219),
                  (rect.left + 58, rect.top + 72), center=False)
        if mode == "race":
            for slot, label in enumerate(("A", "B")):
                button = assign_button_rect(rect, slot)
                assigned = assignments[slot] == index
                slot_color = (83, 190, 255) if slot == 0 else (255, 157, 105)
                pygame.draw.rect(surface, slot_color if assigned else (43, 51, 75),
                                 button, border_radius=8)
                draw_text(surface, label, small_font,
                          (12, 15, 29) if assigned else (213, 222, 242), button.center)
        else:
            draw_text(surface, f"{index + 1}", small_font, (127, 146, 184),
                      (rect.right - 22, rect.centery))
    surface.set_clip(old_clip)
    pygame.draw.rect(surface, (48, 59, 88), viewport, width=1, border_radius=12)
    if max_ball_scroll(len(choices)):
        track = pygame.Rect(viewport.right - 7, viewport.top + 8, 3, viewport.height - 16)
        pygame.draw.rect(surface, (35, 42, 62), track, border_radius=2)
        content_height = len(choices) * BALL_CARD_STRIDE - BALL_CARD_GAP
        thumb_height = max(34, int(track.height * viewport.height / content_height))
        thumb_travel = track.height - thumb_height
        thumb_y = track.top + int(thumb_travel * scroll / max_ball_scroll(len(choices)))
        pygame.draw.rect(surface, (132, 153, 194),
                         pygame.Rect(track.x - 1, thumb_y, track.width + 2, thumb_height), border_radius=3)
    if mode == "race":
        ready = assignments[0] is not None and assignments[1] is not None and assignments[0] != assignments[1]
        button = race_start_rect()
        pygame.draw.rect(surface, (52, 71, 112) if ready else (35, 39, 54), button, border_radius=12)
        pygame.draw.rect(surface, (117, 151, 220) if ready else (64, 69, 84),
                         button, width=2, border_radius=12)
        draw_text(surface, "СТАРТ ГОНКИ" if ready else "ВЫБЕРИ ДВА РАЗНЫХ МЯЧА",
                  small_font, (255, 255, 255) if ready else (155, 161, 178), button.center)
        instruction = "Колесо/↑↓ — прокрутка   A/B — назначить   Enter — старт"
        draw_text(surface, instruction, small_font, (170, 183, 211), (WIDTH // 2, HEIGHT - 34))
    else:
        draw_text(surface, "Колесо/↑↓ — прокрутка   Enter — начать   Esc — назад", small_font,
                  (170, 183, 211), (WIDTH // 2, HEIGHT - 54))
    back = pygame.Rect(20, 20, 100, 36)
    pygame.draw.rect(surface, (29, 36, 58), back, border_radius=9)
    draw_text(surface, "НАЗАД", small_font, (201, 211, 234), back.center)
    return cards


def draw(surface, fonts, planks, ball, behavior, ended, won, elapsed):
    title_font, medium_font, small_font = fonts
    surface.fill(BG)
    draw_text(surface, "PLANK BREAKER", title_font, (239, 242, 255), (WIDTH // 2, 38))
    draw_text(surface, f"МОД: {behavior.name}", small_font, (157, 175, 210), (WIDTH // 2, 75))
    menu_button = menu_button_rect()
    pygame.draw.rect(surface, (29, 36, 58), menu_button, border_radius=9)
    pygame.draw.rect(surface, (67, 81, 116), menu_button, width=1, border_radius=9)
    draw_text(surface, "МЕНЮ", small_font, (201, 211, 234), menu_button.center)
    pygame.draw.rect(surface, (21, 26, 46), FIELD, border_radius=18)
    pygame.draw.rect(surface, (48, 59, 88), FIELD, width=2, border_radius=18)
    pygame.draw.line(surface, (255, 255, 255, 12), (FIELD.left + 1, FIELD.top),
                     (FIELD.right - 1, FIELD.top), 1)

    for plank in planks:
        if not plank.alive:
            continue
        pygame.draw.rect(surface, (5, 7, 16), plank.rect.move(0, 5), border_radius=10)
        pygame.draw.rect(surface, plank.color, plank.rect, border_radius=10)
        # Health indicator appears as a brighter inset strip.
        ratio = max(0, plank.health / plank.max_health)
        fill = pygame.Rect(plank.rect.x + 4, plank.rect.y + 4,
                           max(0, int((plank.rect.width - 8) * ratio)), plank.rect.height - 8)
        if fill.width:
            pygame.draw.rect(surface, tuple(min(255, c + 24) for c in plank.color), fill, border_radius=7)
        draw_text(surface, f"{plank.number}   ·   {max(0, plank.health)}", medium_font,
                  (255, 255, 255), plank.rect.center)

    if ball.trail:
        for index, (tx, ty) in enumerate(ball.trail):
            alpha = 25 + int(100 * (index + 1) / len(ball.trail))
            radius = 3 + int(7 * (index + 1) / len(ball.trail))
            pygame.draw.circle(surface, (*behavior.color, alpha), (int(tx), int(ty)), radius)
    pygame.draw.circle(surface, (255, 255, 255), (round(ball.x), round(ball.y)), BALL_RADIUS + 3)
    pygame.draw.circle(surface, behavior.color, (round(ball.x), round(ball.y)), BALL_RADIUS)
    pygame.draw.circle(surface, (255, 255, 255), (round(ball.x - 5), round(ball.y - 5)), 4)

    next_plank = next((plank for plank in planks if plank.alive), None)
    if next_plank is None:
        damage = 0
    else:
        damage = max(0, int(behavior.damage(ball.hits + 1, ball, next_plank.number)))
    stats = f"СКОРОСТЬ  {compact_number(ball.speed)} px/s    ·    УРОН  {compact_number(damage)}"
    draw_text(surface, stats, small_font, (208, 216, 237), (WIDTH // 2, 914))
    draw_text(surface, f"ОТСКОКИ  {compact_number(ball.hits)}", small_font,
              (145, 160, 192), (WIDTH // 2, 941))
    if ended:
        veil = pygame.Surface((WIDTH, HEIGHT), pygame.SRCALPHA)
        veil.fill((4, 6, 15, 190))
        surface.blit(veil, (0, 0))
        heading = "ВСЁ ПРОБИТО!" if won else "ШАР ВЫПАЛ!"
        draw_text(surface, heading, title_font, (255, 255, 255), (WIDTH // 2, HEIGHT // 2 - 28))
        draw_text(surface, f"Время: {elapsed:.1f} сек.", small_font,
                  (199, 211, 235), (WIDTH // 2, HEIGHT // 2 + 24))
        button = restart_button_rect()
        pygame.draw.rect(surface, (52, 71, 112), button, border_radius=12)
        pygame.draw.rect(surface, (117, 151, 220), button, width=2, border_radius=12)
        draw_text(surface, "ЗАНОВО  ·  R", small_font, (255, 255, 255), button.center)


def draw_race(surface, fonts, competitors, winner, elapsed, ended):
    title_font, medium_font, small_font = fonts
    surface.fill(BG)
    draw_text(surface, "ГОНКА МЯЧЕЙ", title_font, (239, 242, 255), (WIDTH // 2, 38))
    menu_button = menu_button_rect()
    pygame.draw.rect(surface, (29, 36, 58), menu_button, border_radius=9)
    pygame.draw.rect(surface, (67, 81, 116), menu_button, width=1, border_radius=9)
    draw_text(surface, "МЕНЮ", small_font, (201, 211, 234), menu_button.center)

    for competitor in competitors:
        arena, ball = competitor.ball.arena, competitor.ball
        draw_text(surface, f"{competitor.label}: {competitor.behavior.name}", small_font,
                  competitor.behavior.color, (arena.centerx, 77))
        pygame.draw.rect(surface, (21, 26, 46), arena, border_radius=14)
        pygame.draw.rect(surface, (48, 59, 88), arena, width=2, border_radius=14)
        for plank in competitor.planks:
            if not plank.alive:
                continue
            pygame.draw.rect(surface, (5, 7, 16), plank.rect.move(0, 4), border_radius=8)
            pygame.draw.rect(surface, plank.color, plank.rect, border_radius=8)
            ratio = max(0, plank.health / plank.max_health)
            fill = pygame.Rect(plank.rect.x + 3, plank.rect.y + 4,
                               max(0, int((plank.rect.width - 6) * ratio)), plank.rect.height - 8)
            if fill.width:
                pygame.draw.rect(surface, tuple(min(255, c + 24) for c in plank.color),
                                 fill, border_radius=6)
            draw_text(surface, f"{plank.number} · {max(0, plank.health)}", small_font,
                      (255, 255, 255), plank.rect.center)
        if ball.trail:
            for index, (tx, ty) in enumerate(ball.trail):
                radius = 2 + int(5 * (index + 1) / len(ball.trail))
                pygame.draw.circle(surface, competitor.behavior.color, (int(tx), int(ty)), radius)
        pygame.draw.circle(surface, (255, 255, 255), (round(ball.x), round(ball.y)), BALL_RADIUS + 2)
        pygame.draw.circle(surface, competitor.behavior.color, (round(ball.x), round(ball.y)), BALL_RADIUS)
        next_plank = next((plank for plank in competitor.planks if plank.alive), None)
        damage = (max(0, int(competitor.behavior.damage(ball.hits + 1, ball, next_plank.number)))
                  if next_plank else 0)
        draw_text(surface, f"СКОР. {compact_number(ball.speed)} px/s", small_font,
                  (208, 216, 237), (arena.centerx, 914))
        draw_text(surface, f"УРОН {compact_number(damage)}  ·  ОТСКОКИ {compact_number(ball.hits)}",
                  small_font, (145, 160, 192), (arena.centerx, 941))

    if ended:
        veil = pygame.Surface((WIDTH, HEIGHT), pygame.SRCALPHA)
        veil.fill((4, 6, 15, 205))
        surface.blit(veil, (0, 0))
        if winner is None:
            heading = "ГОНКА ЗАВЕРШЕНА"
            detail = "Оба мяча выбыли"
        else:
            heading = f"ПОБЕДИЛ МЯЧ {winner.label}!"
            detail = f"{winner.behavior.name} · {elapsed:.1f} сек."
        draw_text(surface, heading, title_font, (255, 255, 255), (WIDTH // 2, HEIGHT // 2 - 46))
        draw_text(surface, detail, small_font, (199, 211, 235), (WIDTH // 2, HEIGHT // 2 + 4))
        button = restart_button_rect()
        pygame.draw.rect(surface, (52, 71, 112), button, border_radius=12)
        pygame.draw.rect(surface, (117, 151, 220), button, width=2, border_radius=12)
        draw_text(surface, "ЗАНОВО  ·  R", small_font, (255, 255, 255), button.center)


def _time_to_y(ball: Ball, target_y: float, direction: int) -> float | None:
    """Return the first positive flight time to a horizontal line."""
    delta = target_y - ball.y
    vy = ball.vy
    if direction < 0 and vy >= 0 or direction > 0 and vy < 0:
        return None
    if abs(vy) > 1e150:
        time = delta / vy
        return time if time > 0 and math.isfinite(time) else None

    if direction > 0:
        # Stable positive root of 0.5*g*t² + vy*t - delta = 0.
        if delta < 0:
            return None
        root = math.hypot(vy, math.sqrt(2 * GRAVITY * delta))
        denominator = vy + root
        if denominator <= 0:
            return None
        time = (2 * delta) / denominator if delta else 0.0
    else:
        # The ascending root; if the ceiling is above the apex, it is unreachable.
        distance = -delta
        upward_speed = -vy
        discriminant = upward_speed * upward_speed - 2 * GRAVITY * distance
        if discriminant < 0:
            return None
        root = math.sqrt(discriminant)
        denominator = upward_speed + root
        time = (2 * distance) / denominator if denominator else 0.0
    return time if time > 0 and math.isfinite(time) else None


def _advance_ball(ball: Ball, time: float) -> None:
    """Advance freely for a short event interval, reflecting from side walls."""
    arena = ball.arena
    left = arena.left + BALL_RADIUS
    right = arena.right - BALL_RADIUS
    width = right - left
    if width > 0 and ball.vx:
        period = 2 * width
        offset = ball.x - left
        phase = offset if ball.vx >= 0 else period - offset
        phase = (phase + abs(ball.vx) * time) % period
        if phase < width:
            ball.x = left + phase
            ball.vx = abs(ball.vx)
        else:
            ball.x = right - (phase - width)
            ball.vx = -abs(ball.vx)
    ball.y += ball.vy * time + 0.5 * GRAVITY * time * time
    ball.vy += GRAVITY * time


def _normalize_after_bounce(ball: Ball, vertical_direction: int) -> None:
    # Python floats have a finite representable range. This is not a gameplay cap.
    if not math.isfinite(ball.speed):
        ball.speed = sys.float_info.max if ball.speed > 0 else 0.0
    ball.speed = max(0.0, ball.speed)
    magnitude = math.hypot(ball.vx, ball.vy)
    if magnitude <= 1e-300:
        ball.vx = 0.0
        ball.vy = vertical_direction * ball.speed
        return
    scale = ball.speed / magnitude
    ball.vx *= scale
    ball.vy = vertical_direction * abs(ball.vy * scale)


def collide_and_update(ball: Ball, planks: list[Plank], behavior, dt: float) -> bool:
    """Advance by exact time-of-impact events; no speed-based substep cap."""
    remaining = dt + ball.pending_time
    ball.pending_time = 0.0
    event_count = 0
    arena = ball.arena
    ceiling_y = arena.top + BALL_RADIUS
    exit_y = arena.bottom + BALL_RADIUS

    while remaining > 0:
        if ball.vy < 0:
            top_time = _time_to_y(ball, ceiling_y, -1)
            apex_time = -ball.vy / GRAVITY
            if top_time is not None and top_time <= apex_time:
                event_time, event = top_time, "ceiling"
            else:
                event_time, event = apex_time, "apex"
        else:
            next_plank = next((plank for plank in planks if plank.alive), None)
            if next_plank is None:
                target_y, event = exit_y, "exit"
            else:
                target_y, event = next_plank.rect.top - BALL_RADIUS, "plank"
            event_time = _time_to_y(ball, target_y, 1)
            if event_time is None:
                # Recover from a tiny accumulated rounding error at a contact line.
                ball.y = target_y
                event_time, event = 0.0, event

        if event_time > remaining:
            _advance_ball(ball, remaining)
            remaining = 0.0
            break

        # Advancing by zero is only valid at a boundary; after resolving it the
        # vertical direction changes, so the next event is strictly later.
        _advance_ball(ball, event_time)
        remaining = max(0.0, remaining - event_time)
        event_count += 1

        if event == "apex":
            ball.vy = 0.0
            if event_count >= MAX_EVENTS_PER_FRAME:
                ball.pending_time = remaining
                break
            continue
        if event == "exit":
            ball.y = exit_y
            return True
        if event == "ceiling":
            ball.y = ceiling_y
            ball.vy = abs(ball.vy)
            ball.hits += 1
            behavior.on_bounce(ball, ball.hits, 0)
            _normalize_after_bounce(ball, 1)
            if event_count >= MAX_EVENTS_PER_FRAME:
                ball.pending_time = remaining
                break
            continue

        plank = next((item for item in planks if item.alive), None)
        if plank is None:
            continue
        ball.y = plank.rect.top - BALL_RADIUS
        ball.vy = -max(abs(ball.vy), ball.speed * 0.72)
        ball.hits += 1
        damage = max(1, int(behavior.damage(ball.hits, ball, plank.number)))
        plank.health -= damage
        if plank.health <= 0:
            plank.alive = False
        behavior.on_bounce(ball, ball.hits, plank.number)
        _normalize_after_bounce(ball, -1)

        if event_count >= MAX_EVENTS_PER_FRAME:
            ball.pending_time = remaining
            break

    if ball.trail is not None:
        ball.trail.append((ball.x, ball.y))
        if len(ball.trail) > 12:
            ball.trail.pop(0)
    return False


def main() -> None:
    parser = argparse.ArgumentParser(description="Модульная игра с шаром и планками")
    parser.add_argument("--ball", default="basic", help="начальный выбор в меню (например speed_up)")
    parser.add_argument("--list-balls", action="store_true", help="показать доступные моды")
    args = parser.parse_args()
    if args.list_balls:
        for name in available_behaviors():
            behavior = load_behavior(name)
            print(f"{name:18} {behavior.name}: {behavior.description}")
        return
    try:
        choices = [(name, load_behavior(name)) for name in available_behaviors()]
        arena_choices = [(name, load_arena_behavior(name)) for name in available_arena_behaviors()]
    except Exception as exc:
        parser.error(str(exc))
    choice_names = [name for name, _ in choices]
    if args.ball not in choice_names:
        parser.error(f"Мод {args.ball!r} не найден. Доступны: {', '.join(choice_names)}")

    pygame.init()
    screen = pygame.display.set_mode((WIDTH, HEIGHT))
    pygame.display.set_caption("Plank Breaker")
    clock = pygame.time.Clock()
    fonts = (pygame.font.SysFont("dejavusans", 30, bold=True),
             pygame.font.SysFont("dejavusans", 20, bold=True),
             pygame.font.SysFont("dejavusans", 15))
    selected = choice_names.index(args.ball)
    main_choice = 0
    selected_mode = 0
    selected_arena_mode = 0
    screen_state = "main"
    mode = "single"
    assignments: list[int | None] = [None, None]
    cursor = selected
    ball_scroll = keep_ball_visible(cursor, 0, len(choices))
    competitors: list[Competitor] = []
    winner: Competitor | None = None
    ring_game: RingGame | None = None
    ring_behavior = None
    arena_game: ArenaGame | None = None
    ended = False
    started_at = 0
    finished_time: float | None = None

    def start_round() -> None:
        nonlocal competitors, winner, ring_game, ring_behavior, arena_game, selected
        nonlocal ended, started_at, finished_time, screen_state
        if mode == "rings":
            ring_behavior = RingBehavior()
            ring_game = make_ring_game(FIELD, ring_behavior.start_speed)
            competitors = []
            winner = None
            ended = False
            finished_time = None
            started_at = pygame.time.get_ticks()
            screen_state = "playing"
            return
        if mode in ("arena_duel", "arena_boss"):
            if mode == "arena_duel":
                if assignments[0] is None or assignments[1] is None or assignments[0] == assignments[1]:
                    return
                behaviors = [arena_choices[assignments[0]][1], arena_choices[assignments[1]][1]]
                arena_game = new_arena_game("duel", behaviors)
            else:
                selected = cursor
                arena_game = new_arena_game("boss", [arena_choices[selected][1]])
            competitors = []
            winner = None
            ended = False
            finished_time = None
            started_at = pygame.time.get_ticks()
            screen_state = "playing"
            return
        if mode == "single":
            indices = [selected]
            arenas = [FIELD.copy()]
        else:
            if assignments[0] is None or assignments[1] is None or assignments[0] == assignments[1]:
                return
            indices = [assignments[0], assignments[1]]
            arenas = race_arenas()
        competitors = []
        for label, index, arena in zip(("A", "B"), indices, arenas):
            behavior = load_behavior(choice_names[index])
            planks, ball, _ = reset_game(behavior, arena)
            competitors.append(Competitor(label, behavior, planks, ball))
        winner = None
        ended = False
        finished_time = None
        started_at = pygame.time.get_ticks()
        screen_state = "playing"

    running = True
    while running:
        dt = min(clock.tick(FPS) / 1000, 1 / 30)
        mode_cards = mode_card_rects()
        main_cards = main_menu_card_rects()
        current_choices = arena_choices if mode.startswith("arena_") else choices
        ball_cards = ball_card_rects(len(current_choices), ball_scroll)
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
                continue

            if screen_state == "main":
                if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
                    if exit_button_rect().collidepoint(event.pos):
                        running = False
                    else:
                        for index, rect in enumerate(main_cards):
                            if rect.collidepoint(event.pos):
                                main_choice = index
                                if index == 0:
                                    screen_state = "mode"
                                    selected_mode = 0
                                elif index == 1:
                                    mode = "rings"
                                    start_round()
                                else:
                                    screen_state = "arena_mode"
                                    selected_arena_mode = 0
                                break
                elif event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_ESCAPE:
                        running = False
                    elif event.key in (pygame.K_UP, pygame.K_DOWN, pygame.K_LEFT, pygame.K_RIGHT):
                        main_choice = (main_choice + (1 if event.key in (pygame.K_DOWN, pygame.K_RIGHT) else -1)) % 3
                    elif event.key in (pygame.K_RETURN, pygame.K_SPACE):
                        if main_choice == 0:
                            screen_state = "mode"
                            selected_mode = 0
                        elif main_choice == 1:
                            mode = "rings"
                            start_round()
                        else:
                            screen_state = "arena_mode"
                            selected_arena_mode = 0
                continue

            if screen_state == "arena_mode":
                if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
                    if main_menu_back_rect().collidepoint(event.pos):
                        screen_state = "main"
                    else:
                        for index, rect in enumerate(mode_cards):
                            if rect.collidepoint(event.pos):
                                selected_arena_mode = index
                                mode = "arena_duel" if index == 0 else "arena_boss"
                                assignments = [None, None]
                                cursor = 0
                                ball_scroll = 0
                                screen_state = "balls"
                                break
                elif event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_ESCAPE:
                        screen_state = "main"
                    elif event.key in (pygame.K_UP, pygame.K_DOWN, pygame.K_LEFT, pygame.K_RIGHT):
                        selected_arena_mode = 1 - selected_arena_mode
                    elif event.key in (pygame.K_RETURN, pygame.K_SPACE):
                        mode = "arena_duel" if selected_arena_mode == 0 else "arena_boss"
                        assignments = [None, None]
                        cursor = 0
                        ball_scroll = 0
                        screen_state = "balls"
                continue

            if screen_state == "mode":
                if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
                    if main_menu_back_rect().collidepoint(event.pos):
                        main_choice = 0
                        screen_state = "main"
                    else:
                        for index, rect in enumerate(mode_cards):
                            if rect.collidepoint(event.pos):
                                selected_mode = index
                                mode = "single" if index == 0 else "race"
                                assignments = [None, None]
                                cursor = selected
                                ball_scroll = keep_ball_visible(cursor, 0, len(choices))
                                screen_state = "balls"
                                break
                elif event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_ESCAPE:
                        main_choice = 0
                        screen_state = "main"
                    elif event.key in (pygame.K_UP, pygame.K_DOWN, pygame.K_LEFT, pygame.K_RIGHT):
                        selected_mode = 1 - selected_mode
                    elif event.key in (pygame.K_RETURN, pygame.K_SPACE):
                        mode = "single" if selected_mode == 0 else "race"
                        assignments = [None, None]
                        cursor = selected
                        ball_scroll = keep_ball_visible(cursor, 0, len(choices))
                        screen_state = "balls"
                continue

            if screen_state == "balls":
                current_choices = arena_choices if mode.startswith("arena_") else choices
                back_rect = pygame.Rect(20, 20, 100, 36)
                ball_cards = ball_card_rects(len(current_choices), ball_scroll)
                duel_selection = mode in ("race", "arena_duel")
                single_selection = mode in ("single", "rings", "arena_boss")
                if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
                    if back_rect.collidepoint(event.pos):
                        screen_state = "arena_mode" if mode.startswith("arena_") else "main" if mode == "rings" else "mode"
                    elif ball_list_rect().collidepoint(event.pos) and single_selection:
                        for index, rect in enumerate(ball_cards):
                            if rect.collidepoint(event.pos):
                                selected = index
                                cursor = index
                                start_round()
                                break
                    elif duel_selection and race_start_rect().collidepoint(event.pos):
                        start_round()
                    elif ball_list_rect().collidepoint(event.pos) and duel_selection:
                        for index, rect in enumerate(ball_cards):
                            if assign_button_rect(rect, 0).collidepoint(event.pos):
                                other = 1
                                previous = assignments[0]
                                assignments[0] = index
                                if assignments[other] == index:
                                    assignments[other] = previous
                                cursor = index
                                break
                            if assign_button_rect(rect, 1).collidepoint(event.pos):
                                other = 0
                                previous = assignments[1]
                                assignments[1] = index
                                if assignments[other] == index:
                                    assignments[other] = previous
                                cursor = index
                                break
                            if rect.collidepoint(event.pos):
                                cursor = index
                                if assignments[0] is None:
                                    assignments[0] = index
                                elif assignments[1] is None and assignments[0] != index:
                                    assignments[1] = index
                                elif assignments[0] != index and assignments[1] != index:
                                    assignments[1] = index
                                break
                elif event.type == pygame.MOUSEWHEEL:
                    if ball_list_rect().collidepoint(pygame.mouse.get_pos()):
                        ball_scroll = clamp_ball_scroll(
                            ball_scroll - event.y * BALL_CARD_STRIDE, len(current_choices))
                elif event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_ESCAPE:
                        screen_state = "arena_mode" if mode.startswith("arena_") else "main" if mode == "rings" else "mode"
                    elif event.key in (pygame.K_UP, pygame.K_LEFT):
                        cursor = (cursor - 1) % len(current_choices)
                        ball_scroll = keep_ball_visible(cursor, ball_scroll, len(current_choices))
                    elif event.key in (pygame.K_DOWN, pygame.K_RIGHT):
                        cursor = (cursor + 1) % len(current_choices)
                        ball_scroll = keep_ball_visible(cursor, ball_scroll, len(current_choices))
                    elif event.key == pygame.K_PAGEUP:
                        ball_scroll = clamp_ball_scroll(
                            ball_scroll - ball_list_rect().height, len(current_choices))
                    elif event.key == pygame.K_PAGEDOWN:
                        ball_scroll = clamp_ball_scroll(
                            ball_scroll + ball_list_rect().height, len(current_choices))
                    elif single_selection and event.key in (pygame.K_RETURN, pygame.K_SPACE):
                        selected = cursor
                        start_round()
                    elif duel_selection and (
                            event.key in (pygame.K_a, pygame.K_b)
                            or event.unicode.lower() in ("a", "b", "ф", "и")):
                        slot = 0 if event.key == pygame.K_a or event.unicode.lower() in ("a", "ф") else 1
                        other = 1 - slot
                        previous = assignments[slot]
                        assignments[slot] = cursor
                        if assignments[other] == cursor:
                            assignments[other] = previous
                    elif duel_selection and event.key in (pygame.K_RETURN, pygame.K_SPACE):
                        start_round()
                continue

            if screen_state == "playing":
                if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
                    if menu_button_rect().collidepoint(event.pos):
                        screen_state = "main" if mode == "rings" or mode.startswith("arena_") else "mode"
                        ended = False
                    elif ((ended or (arena_game is not None and arena_game.ended))
                          and restart_button_rect().collidepoint(event.pos)):
                        start_round()
                elif event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_ESCAPE:
                        screen_state = "main" if mode == "rings" or mode.startswith("arena_") else "mode"
                        ended = False
                    elif event.key == pygame.K_r or event.unicode.lower() in ("r", "к"):
                        start_round()

        if screen_state == "main":
            draw_main_menu(screen, fonts, main_choice)
        elif screen_state == "mode":
            draw_mode_menu(screen, fonts, selected_mode)
        elif screen_state == "arena_mode":
            draw_arena_mode_menu(screen, fonts, selected_arena_mode)
        elif screen_state == "balls":
            current_choices = arena_choices if mode.startswith("arena_") else choices
            ui_mode = "race" if mode == "arena_duel" else "single" if mode == "arena_boss" else mode
            draw_ball_menu(screen, fonts, current_choices, cursor, ui_mode, assignments, ball_scroll)
        else:
            now_elapsed = (pygame.time.get_ticks() - started_at) / 1000
            if mode.startswith("arena_"):
                if arena_game is not None:
                    update_arena_game(arena_game, dt)
                    draw_arena_game(screen, fonts, arena_game, menu_button_rect())
            elif mode == "rings":
                if not ended and ring_game is not None and update_ring_game(ring_game, ring_behavior, dt):
                    ended = True
                    finished_time = now_elapsed
                elapsed = finished_time if finished_time is not None else now_elapsed
                if ring_game is not None:
                    draw_ring_game(screen, fonts, ring_game, ring_behavior, elapsed,
                                   ended, menu_button_rect(), restart_button_rect())
            else:
                if not ended:
                    for competitor in competitors:
                        if competitor.finished_at is not None:
                            continue
                        if collide_and_update(competitor.ball, competitor.planks,
                                              competitor.behavior, dt):
                            competitor.success = not any(plank.alive for plank in competitor.planks)
                            competitor.finished_at = now_elapsed
                            if competitor.success:
                                winner = competitor
                                ended = True
                                finished_time = now_elapsed
                                break
                    if not ended and all(item.finished_at is not None for item in competitors):
                        ended = True
                        finished_time = now_elapsed
                elapsed = finished_time if finished_time is not None else now_elapsed
                if mode == "single":
                    item = competitors[0]
                    draw(screen, fonts, item.planks, item.ball, item.behavior,
                         ended, item.success is True, elapsed)
                else:
                    draw_race(screen, fonts, competitors, winner, elapsed, ended)
        pygame.display.flip()
    pygame.quit()


if __name__ == "__main__":
    main()
