"""Pygame presentation and real-time input; rules live in :mod:`core`."""

import argparse
import math
import os
import random
from pathlib import Path

os.environ.setdefault("PYGAME_HIDE_SUPPORT_PROMPT", "1")
import pygame

from gridquest.core import Game, shortest_path

SIZE = (1100, 820)
TILE = 30
ORIGIN = (34, 151)
GRACE_SECONDS = 5.0
ENEMY_INTERVAL = 0.42
BG = "#0b101b"
PANEL = "#111a2a"
LINE = "#26354d"
WHITE = "#edf5ff"
MUTED = "#8b9db8"
CYAN = "#67e8f9"
MINT = "#8cf0ba"
ORANGE = "#ff846b"


class App:
    def __init__(self, seed: int):
        pygame.display.init()
        pygame.font.init()
        self.screen = pygame.display.set_mode(SIZE)
        pygame.display.set_caption("GridQuest | Escape the maze")
        pygame.key.set_repeat(180, 110)
        self.fonts = {
            "small": pygame.font.Font(None, 21),
            "body": pygame.font.Font(None, 25),
            "heading": pygame.font.Font(None, 30),
            "title": pygame.font.Font(None, 54),
            "number": pygame.font.Font(None, 44),
        }
        self.running = True
        self.hints = False
        self.seed = seed
        self.reset()

    def reset(self) -> None:
        self.game = Game.new(self.seed)
        self.elapsed = 0.0
        self.enemy_accumulator = 0.0
        self.paused = False

    def handle_event(self, event: pygame.event.Event) -> None:
        if event.type == pygame.QUIT:
            self.running = False
        if event.type != pygame.KEYDOWN:
            return
        if event.key == pygame.K_ESCAPE:
            self.running = False
        elif event.key == pygame.K_r:
            self.reset()
        elif event.key == pygame.K_n:
            self.seed += 1
            self.reset()
        elif event.key == pygame.K_h:
            self.hints = not self.hints
        elif event.key == pygame.K_p and self.game.status == "playing":
            self.paused = not self.paused
        elif not self.paused:
            direction = {
                pygame.K_RIGHT: (1, 0),
                pygame.K_d: (1, 0),
                pygame.K_LEFT: (-1, 0),
                pygame.K_a: (-1, 0),
                pygame.K_DOWN: (0, 1),
                pygame.K_s: (0, 1),
                pygame.K_UP: (0, -1),
                pygame.K_w: (0, -1),
            }.get(event.key)
            if direction:
                self.game.move(*direction)

    def update(self, dt: float) -> None:
        if self.paused or self.game.status != "playing":
            return
        previous = self.elapsed
        self.elapsed += dt
        active_dt = max(0.0, self.elapsed - GRACE_SECONDS) - max(0.0, previous - GRACE_SECONDS)
        self.enemy_accumulator += active_dt
        while self.enemy_accumulator >= ENEMY_INTERVAL and self.game.status == "playing":
            self.enemy_accumulator -= ENEMY_INTERVAL
            self.game.advance_enemy()

    def text(self, value: str, pos: tuple[int, int], color=WHITE, font="body") -> None:
        self.screen.blit(self.fonts[font].render(value, True, color), pos)

    def center(self, cell: tuple[int, int]) -> tuple[int, int]:
        return (ORIGIN[0] + cell[0] * TILE + TILE // 2, ORIGIN[1] + cell[1] * TILE + TILE // 2)

    def draw(self) -> None:
        screen = self.screen
        screen.fill(BG)
        pygame.draw.rect(screen, CYAN, (34, 34, 8, 39), border_radius=4)
        self.text("GRIDQUEST", (54, 27), font="title")
        self.text("A PROCEDURAL MAZE ESCAPE", (56, 80), MUTED, "small")
        pygame.draw.rect(screen, PANEL, (825, 35, 240, 61), border_radius=12)
        self.text("RUN SEED", (842, 46), MUTED, "small")
        # Keep arbitrary integer seeds inside the panel.
        seed_label = str(self.seed)
        if len(seed_label) > 19:
            seed_label = seed_label[:16] + "..."
        self.text(seed_label, (842, 69), CYAN, "small")
        pygame.draw.line(screen, LINE, (34, 116), (1066, 116))
        self.text("01  /  THE LABYRINTH", (34, 129), MUTED, "small")
        self.text("FIND THE SIGNAL. STAY AHEAD.", (825, 129), MUTED, "small")

        maze = self.game.maze
        pygame.draw.rect(screen, LINE, (30, 147, 758, 578), border_radius=9)
        for y in range(maze.height):
            for x in range(maze.width):
                rect = pygame.Rect(ORIGIN[0] + x * TILE, ORIGIN[1] + y * TILE, TILE, TILE)
                if (x, y) in maze.floor:
                    pygame.draw.rect(screen, "#0e1926", rect)
                    pygame.draw.rect(screen, "#122130", rect, width=1)
                else:
                    pygame.draw.rect(screen, "#233148", rect)
                    pygame.draw.rect(screen, "#2b3c55", rect.inflate(-2, -2), width=1)
        if self.hints:
            for cell in shortest_path(maze, self.game.player, maze.exit)[1:-1]:
                pygame.draw.circle(screen, "#387986", self.center(cell), 3)
        exit_center = self.center(maze.exit)
        portal = pygame.Rect(0, 0, 22, 22)
        portal.center = exit_center
        pygame.draw.rect(screen, MINT, portal, width=2, border_radius=5)
        pygame.draw.circle(screen, MINT, exit_center, 4)
        hunter_center = self.center(self.game.enemy)
        hx, hy = hunter_center
        hunter_active = self.elapsed >= GRACE_SECONDS
        hunter_color = ORANGE if hunter_active else "#9d685d"
        pygame.draw.polygon(
            screen, hunter_color, [(hx, hy - 11), (hx + 11, hy + 9), (hx - 11, hy + 9)]
        )
        pygame.draw.circle(screen, BG, (hx - 3, hy + 3), 2)
        pygame.draw.circle(screen, BG, (hx + 3, hy + 3), 2)
        px, py = self.center(self.game.player)
        pygame.draw.circle(screen, "#164453", (px, py), 13)
        pygame.draw.circle(screen, CYAN, (px, py), 9)
        pygame.draw.circle(screen, WHITE, (px - 2, py - 3), 3)

        pygame.draw.rect(screen, PANEL, (812, 151, 254, 570), border_radius=12)
        self.text("MISSION", (833, 173), MUTED, "small")
        self.text("Reach the exit", (833, 203), font="heading")
        self.text("Follow the green signal.", (833, 238), MUTED, "small")
        self.text("The hunter follows you.", (833, 262), MUTED, "small")
        pygame.draw.line(screen, LINE, (833, 297), (1045, 297))
        self.text("MOVES", (833, 317), MUTED, "small")
        self.text(str(self.game.moves), (833, 344), font="number")
        self.text("TIME", (956, 317), MUTED, "small")
        self.text(f"{int(self.elapsed):02d}s", (956, 344), font="number")
        remaining = len(shortest_path(maze, self.game.player, maze.exit)) - 1
        self.text(f"{remaining} steps to the signal", (833, 395), MUTED, "small")
        pygame.draw.line(screen, LINE, (833, 432), (1045, 432))
        if self.game.status == "won":
            status, detail, color = "ESCAPED", "Signal reached. Well played.", MINT
        elif self.game.status == "lost":
            status, detail, color = "CAUGHT", "The hunter found your trail.", ORANGE
        elif self.paused:
            status, detail, color = "PAUSED", "Press P to resume.", CYAN
        elif not hunter_active:
            countdown = math.ceil(GRACE_SECONDS - self.elapsed)
            status, detail, color = (
                f"HEAD START  {countdown}s",
                "Move now. The hunt is coming.",
                MINT,
            )
        else:
            status, detail, color = "HUNTER ACTIVE", "Keep moving. Watch your route.", ORANGE
        self.text(status, (833, 456), color, "body")
        self.text(detail, (833, 489), MUTED, "small")
        self.text("LEGEND", (833, 543), MUTED, "small")
        for i, (label, color) in enumerate([("YOU", CYAN), ("EXIT", MINT), ("HUNTER", ORANGE)]):
            pygame.draw.circle(screen, color, (841, 579 + 29 * i), 5)
            self.text(label, (859, 572 + 29 * i), MUTED, "small")
        self.text(f"HINT ROUTE  {'ON' if self.hints else 'OFF'}", (833, 682), CYAN, "small")

        self.text("WASD / ARROWS  Move", (34, 752), WHITE, "small")
        self.text("H  Hint   /   P  Pause", (310, 752), MUTED, "small")
        self.text("R  Restart   /   N  New maze", (557, 752), MUTED, "small")
        self.text("ESC  Quit", (964, 752), MUTED, "small")
        self.text("SEE THE ROUTE. MAKE YOUR MOVE.", (34, 788), "#52657e", "small")
        if self.paused or self.game.status != "playing":
            veil = pygame.Surface((750, 570), pygame.SRCALPHA)
            veil.fill((7, 13, 23, 190))
            screen.blit(veil, ORIGIN)
            box = pygame.Rect(159, 346, 500, 159)
            pygame.draw.rect(screen, PANEL, box, border_radius=15)
            pygame.draw.rect(screen, color, box, width=1, border_radius=15)
            self.text(status, (188, 370), color, "title")
            self.text(detail, (189, 425), MUTED)
            if self.game.status != "playing":
                self.text("R  Try this seed again     N  Next maze", (189, 467), CYAN, "small")
        pygame.display.flip()

    def run(self) -> None:
        clock = pygame.time.Clock()
        while self.running:
            dt = min(clock.tick(60) / 1000.0, 0.1)
            for event in pygame.event.get():
                self.handle_event(event)
            self.update(dt)
            self.draw()


def main() -> None:
    parser = argparse.ArgumentParser(description="GridQuest: a procedural maze chase game.")
    parser.add_argument("--seed", type=int, default=None, help="Reproduce a maze by integer seed.")
    parser.add_argument(
        "--screenshot", type=Path, help="Render one frame to PNG, then exit (headless)."
    )
    args = parser.parse_args()
    if args.screenshot:
        os.environ.setdefault("SDL_VIDEODRIVER", "dummy")
    app = App(args.seed if args.seed is not None else random.SystemRandom().randrange(1_000_000))
    try:
        if args.screenshot:
            app.hints = True
            app.draw()
            args.screenshot.parent.mkdir(parents=True, exist_ok=True)
            pygame.image.save(app.screen, str(args.screenshot))
        else:
            app.run()
    finally:
        pygame.quit()
