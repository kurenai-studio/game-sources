"""Real SDL-dummy integration tests, with no display or audio device needed."""

import os
import subprocess
import sys
from pathlib import Path

os.environ["SDL_VIDEODRIVER"] = "dummy"
os.environ["SDL_AUDIODRIVER"] = "dummy"
os.environ["PYGAME_HIDE_SUPPORT_PROMPT"] = "1"

import pygame
import pytest

from gridquest.app import App
from gridquest.core import shortest_path


@pytest.fixture
def app():
    instance = App(42)
    yield instance
    pygame.quit()


def press(app, key):
    app.handle_event(pygame.event.Event(pygame.KEYDOWN, key=key))


def test_arrow_keys_move_and_h_toggles_hint(app):
    route = shortest_path(app.game.maze, app.game.player, app.game.maze.exit)
    dx = route[1][0] - route[0][0]
    dy = route[1][1] - route[0][1]
    key = {
        (1, 0): pygame.K_RIGHT,
        (-1, 0): pygame.K_LEFT,
        (0, 1): pygame.K_DOWN,
        (0, -1): pygame.K_UP,
    }[dx, dy]
    press(app, key)
    assert app.game.player == route[1]
    press(app, pygame.K_h)
    assert app.hints
    press(app, pygame.K_h)
    assert not app.hints


def test_pause_freezes_timer_and_blocks_moves(app):
    press(app, pygame.K_p)
    app.update(10)
    press(app, pygame.K_RIGHT)
    press(app, pygame.K_DOWN)
    assert app.elapsed == 0
    assert app.game.moves == 0
    press(app, pygame.K_p)
    app.update(1)
    assert app.elapsed == 1


def test_grace_period_then_enemy_catches_idle_player(app):
    app.update(4.9)
    assert app.game.status == "playing"
    app.update(0.7)
    assert app.game.status == "lost"


def test_restart_reproduces_map_and_resets_state(app):
    old_maze = app.game.maze
    app.update(10)
    press(app, pygame.K_r)
    assert app.game.maze == old_maze
    assert app.elapsed == 0
    assert app.game.status == "playing"
    press(app, pygame.K_n)
    assert app.seed == 43
    assert app.game.maze != old_maze


def test_escape_and_close_event_exit_cleanly(app):
    press(app, pygame.K_ESCAPE)
    assert not app.running


def test_headless_screenshot_cli_creates_valid_image(tmp_path):
    destination = tmp_path / "screen.png"
    result = subprocess.run(
        [sys.executable, "-m", "gridquest", "--seed", "42", "--screenshot", str(destination)],
        capture_output=True,
        text=True,
        timeout=15,
    )
    assert result.returncode == 0, result.stderr
    assert destination.read_bytes().startswith(b"\x89PNG\r\n\x1a\n")
    assert destination.stat().st_size > 10000
    pygame.init()
    assert pygame.image.load(str(destination)).get_size() == (1100, 820)
    pygame.quit()


def test_negative_seed_cli_is_supported(tmp_path):
    result = subprocess.run(
        [
            sys.executable,
            "-m",
            "gridquest",
            "--seed",
            "-1",
            "--screenshot",
            str(Path(tmp_path) / "negative.png"),
        ],
        capture_output=True,
        text=True,
        timeout=15,
    )
    assert result.returncode == 0, result.stderr


@pytest.mark.parametrize("seed", range(10))
def test_following_escape_route_at_repeat_speed_wins_despite_chase(seed):
    instance = App(seed)
    route = shortest_path(instance.game.maze, instance.game.player, instance.game.maze.exit)
    for current, target in zip(route, route[1:], strict=False):
        instance.game.move(target[0] - current[0], target[1] - current[1])
        instance.update(0.11)
    assert instance.game.status == "won"
    instance.draw()
    pygame.quit()


def test_hunter_moves_after_grace_and_remains_separate_from_player(app):
    route = shortest_path(app.game.maze, app.game.player, app.game.maze.exit)
    for current, target in zip(route[:10], route[1:11], strict=True):
        app.game.move(target[0] - current[0], target[1] - current[1])
    app.update(5.43)
    assert app.game.enemy == route[1]
    assert app.game.player == route[10]
    app.draw()


def test_pause_loss_and_quit_render_without_crashing(app):
    press(app, pygame.K_p)
    app.draw()
    press(app, pygame.K_p)
    app.update(6)
    assert app.game.status == "lost"
    app.draw()
    app.handle_event(pygame.event.Event(pygame.QUIT))
    assert not app.running
