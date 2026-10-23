"""Desktop/device shell shared by the two independently runnable games."""
import argparse
import json
import os
from pathlib import Path
import sys
import tempfile

import pygame
from pygame._sdl2 import controller

WIDTH, HEIGHT = 640, 480
BG, PANEL, TEXT, MUTED = (12, 18, 32), (25, 36, 55), (237, 244, 248), (151, 172, 190)


class Scores:
    def __init__(self, game_id, directory=None):
        base = directory or os.environ.get("PY2PORTS_DATA_DIR")
        if not base:
            base = Path(os.environ.get("XDG_DATA_HOME", str(Path.home() / ".local/share"))) / game_id
        self.path = Path(base) / "scores.json"
        self.best = 0
        try:
            value = json.loads(self.path.read_text())["high_score"]
            if type(value) is not int or value < 0:
                raise ValueError("invalid score")
            self.best = value
        except FileNotFoundError:
            pass
        except (OSError, ValueError, KeyError, TypeError):
            print("High score could not be read; starting at zero.", file=sys.stderr)

    def record(self, score):
        if score <= self.best:
            return
        self.best = score
        temporary = None
        try:
            self.path.parent.mkdir(parents=True, exist_ok=True)
            with tempfile.NamedTemporaryFile(mode="w", dir=self.path.parent, delete=False) as stream:
                temporary = Path(stream.name)
                json.dump({"high_score": score}, stream)
                stream.write("\n")
            os.replace(temporary, self.path)
        except OSError:
            print("High score could not be saved; continuing in memory.", file=sys.stderr)
        finally:
            if temporary is not None:
                try:
                    temporary.unlink(missing_ok=True)
                except OSError:
                    pass


class Inputs:
    """SDL GameController mappings, with raw joystick and keyboard fallbacks."""
    keys = {pygame.K_LEFT: "left", pygame.K_a: "left", pygame.K_RIGHT: "right", pygame.K_d: "right",
            pygame.K_UP: "up", pygame.K_w: "up", pygame.K_DOWN: "down", pygame.K_s: "down"}
    buttons = {pygame.CONTROLLER_BUTTON_DPAD_LEFT: "left", pygame.CONTROLLER_BUTTON_DPAD_RIGHT: "right",
               pygame.CONTROLLER_BUTTON_DPAD_UP: "up", pygame.CONTROLLER_BUTTON_DPAD_DOWN: "down",
               pygame.CONTROLLER_BUTTON_A: "confirm", pygame.CONTROLLER_BUTTON_B: "back",
               pygame.CONTROLLER_BUTTON_START: "pause", pygame.CONTROLLER_BUTTON_BACK: "back"}

    def __init__(self):
        self.held = {}
        self.devices = {}
        self.mapped = set()

    @property
    def horizontal(self):
        return max(-1, min(1, sum(-1 if value == "left" else 1 if value == "right" else 0
                                  for value in self.held.values())))

    def open_device(self, index):
        try:
            stick = pygame.joystick.Joystick(index)
            identity = stick.get_instance_id()
            if identity in self.devices:
                return
            if controller.is_controller(index):
                device = controller.Controller(index)
                self.mapped.add(identity)
            else:
                stick.init()
                device = stick
            self.devices[identity] = device
        except pygame.error:
            print("Controller unavailable; keyboard remains usable.", file=sys.stderr)

    def remove_device(self, identity):
        self.devices.pop(identity, None)
        self.mapped.discard(identity)
        for key in list(self.held):
            if isinstance(key, tuple) and key[0] == identity:
                del self.held[key]

    def set_direction(self, key, direction):
        old = self.held.pop(key, None)
        if direction:
            self.held[key] = direction
        return [direction] if direction and direction != old else []

    def event(self, event):
        if event.type == pygame.QUIT:
            return ["quit"]
        if event.type in (pygame.JOYDEVICEADDED, pygame.CONTROLLERDEVICEADDED):
            self.open_device(event.device_index)
        elif event.type in (pygame.JOYDEVICEREMOVED, pygame.CONTROLLERDEVICEREMOVED):
            self.remove_device(event.instance_id)
        elif event.type == pygame.WINDOWFOCUSLOST:
            self.held.clear()
            return ["focus_lost"]
        elif event.type in (pygame.KEYDOWN, pygame.KEYUP):
            down = event.type == pygame.KEYDOWN
            if event.key in self.keys:
                return self.set_direction(("key", event.key), self.keys[event.key] if down else None)
            if down:
                return [{pygame.K_RETURN: "confirm", pygame.K_SPACE: "confirm", pygame.K_p: "pause",
                         pygame.K_ESCAPE: "back", pygame.K_q: "quit"}.get(event.key)] if event.key in (
                             pygame.K_RETURN, pygame.K_SPACE, pygame.K_p, pygame.K_ESCAPE, pygame.K_q) else []
        elif event.type in (pygame.CONTROLLERBUTTONDOWN, pygame.CONTROLLERBUTTONUP):
            action = self.buttons.get(event.button)
            down = event.type == pygame.CONTROLLERBUTTONDOWN
            if action in ("left", "right", "up", "down"):
                return self.set_direction((event.instance_id, "button", event.button), action if down else None)
            return [action] if down and action else []
        elif event.type in (pygame.CONTROLLERAXISMOTION, pygame.JOYAXISMOTION):
            if event.type == pygame.JOYAXISMOTION and event.instance_id in self.mapped:
                return []
            if event.axis not in (0, 1):
                return []
            value = event.value / 32767 if event.type == pygame.CONTROLLERAXISMOTION else event.value
            negative, positive = ("left", "right") if event.axis == 0 else ("up", "down")
            direction = negative if value < -0.35 else positive if value > 0.35 else None
            return self.set_direction((event.instance_id, "axis", event.axis), direction)
        elif event.type == pygame.JOYHATMOTION and event.instance_id not in self.mapped:
            x, y = event.value
            actions = self.set_direction((event.instance_id, "hat_x"), "left" if x < 0 else "right" if x > 0 else None)
            return actions + self.set_direction((event.instance_id, "hat_y"), "up" if y > 0 else "down" if y < 0 else None)
        elif event.type == pygame.JOYBUTTONDOWN and event.instance_id not in self.mapped:
            action = {0: "confirm", 1: "back", 7: "pause", 6: "back"}.get(event.button)
            return [action] if action else []
        return []


class View:
    def __init__(self, surface):
        self.surface = surface
        self.fonts = {}

    def text(self, message, x, y, size=24, color=TEXT, center=False):
        if size not in self.fonts:
            self.fonts[size] = pygame.font.Font(None, size)
        font = self.fonts[size]
        image = font.render(str(message), True, color)
        rect = image.get_rect(midtop=(x, y)) if center else image.get_rect(topleft=(x, y))
        self.surface.blit(image, rect)


def render(view, game, best):
    view.surface.fill(BG)
    game.draw(view)
    view.text(game.title, 24, 14, 32, game.accent)
    view.text(f"SCORE {game.score:04d}    BEST {best:04d}", 24, 51, 23)
    view.text(game.hint, 320, 461, 17, MUTED, True)
    if game.state != "playing":
        shade = pygame.Surface((WIDTH, HEIGHT), pygame.SRCALPHA)
        shade.fill((6, 10, 18, 205))
        view.surface.blit(shade, (0, 0))
        pygame.draw.rect(view.surface, PANEL, (72, 135, 496, 225), border_radius=18)
        pygame.draw.rect(view.surface, game.accent, (72, 135, 496, 225), 2, border_radius=18)
        title = {"menu": game.title, "paused": "PAUSED", "over": "GAME OVER", "won": "YOU WIN!"}[game.state]
        view.text(title, 320, 161, 48, game.accent, True)
        line = game.subtitle if game.state == "menu" else f"SCORE {game.score}   /   BEST {best}"
        view.text(line, 320, 218, 24, TEXT, True)
        prompt = "A / Enter: resume" if game.state == "paused" else "A / Enter: play"
        view.text(prompt, 320, 264, 26, TEXT, True)
        view.text("D-pad / stick / arrows: move", 320, 302, 21, MUTED, True)
        view.text("B / Esc: back    Q: quit    Start / P: pause", 320, 384, 21, MUTED, True)


def run(game_type, game_id, fullscreen_variable):
    parser = argparse.ArgumentParser(description=game_type.title)
    parser.add_argument("--smoke-test", action="store_true", help="Run bounded headless gameplay/rendering verification")
    args = parser.parse_args()
    if args.smoke_test:
        os.environ.update(SDL_VIDEODRIVER="dummy", SDL_AUDIODRIVER="dummy")
    pygame.display.init()
    pygame.font.init()
    pygame.joystick.init()
    controller.init()
    fullscreen = os.environ.get(fullscreen_variable) == "1" and not args.smoke_test
    window = pygame.display.set_mode((0, 0) if fullscreen else (WIDTH, HEIGHT), pygame.FULLSCREEN if fullscreen else pygame.RESIZABLE)
    pygame.display.set_caption(game_type.title)
    pygame.mouse.set_visible(not fullscreen)
    logical = pygame.Surface((WIDTH, HEIGHT))
    view, inputs, game = View(logical), Inputs(), game_type()
    for index in range(pygame.joystick.get_count()):
        inputs.open_device(index)
    temporary = tempfile.TemporaryDirectory() if args.smoke_test else None
    scores = Scores(game_id, temporary.name if temporary else None)
    clock = pygame.time.Clock()
    running, frames = True, 0
    try:
        while running:
            dt = 1 / 60 if args.smoke_test else min(clock.tick(60) / 1000, 0.1)
            for event in pygame.event.get():
                for action in inputs.event(event):
                    if action == "quit" or (action == "back" and game.state == "menu"):
                        running = False
                    elif action == "focus_lost":
                        if game.state == "playing":
                            game.handle("pause")
                    else:
                        game.handle(action)
            if args.smoke_test:
                if frames in (1, 2):
                    game.handle("confirm")
                if frames in (20, 22):
                    game.handle("pause")
            game.update(dt, inputs.horizontal)
            scores.record(game.score)
            render(view, game, scores.best)
            w, h = window.get_size()
            scale = min(w / WIDTH, h / HEIGHT)
            size = (max(1, int(WIDTH * scale)), max(1, int(HEIGHT * scale)))
            window.fill((0, 0, 0))
            window.blit(pygame.transform.scale(logical, size), ((w - size[0]) // 2, (h - size[1]) // 2))
            pygame.display.flip()
            frames += 1
            if args.smoke_test and frames >= 120:
                running = False
        if args.smoke_test:
            assert frames == 120
            print(f"PASS {game_id}: 120 headless frames, menu, gameplay, pause/resume, rendering")
    finally:
        controller.quit()
        pygame.quit()
        if temporary:
            temporary.cleanup()
