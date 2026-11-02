"""Main game loop."""

from datetime import datetime
from enum import Enum, auto

import pygame

from duck_attack import settings
from duck_attack.crosshair import make_crosshair_cursor
from duck_attack.duck import Duck, load_duck_image
from duck_attack.highscores import HighScore, HighScoreList
from duck_attack.hud import Hud
from duck_attack.player import load_player_name, save_player_name
from duck_attack.screens import HighScoreScreen, NameEntryScreen, RoundOverScreen
from duck_attack.sounds import AmbientSounds, RandomSound


class State(Enum):
    NAME_ENTRY = auto()  # asking for the player name; Enter or a click starts the round
    PLAYING = auto()
    ROUND_OVER = auto()  # showing the final score
    HIGHSCORES = auto()  # showing the high-score list; a click goes to the name entry


class Game:
    def __init__(self) -> None:
        pygame.init()
        pygame.display.set_caption(settings.TITLE)
        self.screen = pygame.display.set_mode((settings.SCREEN_WIDTH, settings.SCREEN_HEIGHT))
        self.clock = pygame.time.Clock()
        self.running = True
        self.background = self._load_background()
        self.duck_image = load_duck_image()
        self.ducks: pygame.sprite.Group = pygame.sprite.Group()
        pygame.mouse.set_cursor(make_crosshair_cursor())
        self.hud = Hud()
        self.name_entry_screen = NameEntryScreen()
        self.round_over_screen = RoundOverScreen()
        self.highscore_screen = HighScoreScreen()
        self.highscores = HighScoreList(settings.HIGHSCORES_FILE)
        self.ambience = AmbientSounds()
        self.shot_sound = RandomSound([settings.SHOT_SOUND], settings.SHOT_VOLUME)
        self.player_name = load_player_name(settings.PLAYER_NAME_FILE)
        self.score = 0
        self.highscore_rank: int | None = None
        self.enter_name()

    def _load_background(self) -> pygame.Surface:
        image = pygame.image.load(settings.BACKGROUND_IMAGE).convert()
        if image.get_size() != self.screen.get_size():
            image = pygame.transform.smoothscale(image, self.screen.get_size())
        return image

    def enter_name(self) -> None:
        """Show the name entry, prefilled with the last player name."""
        self.state = State.NAME_ENTRY
        self.state_time = 0.0
        self.ducks.empty()
        pygame.key.start_text_input()

    def type_name(self, text: str) -> None:
        name = (self.player_name + text).lstrip()
        self.player_name = name[: settings.PLAYER_NAME_MAX_LENGTH]

    def start_round(self) -> None:
        """Start a round with the entered name; does nothing while the name is empty."""
        self.player_name = self.player_name.strip()
        if not self.player_name:
            return
        save_player_name(settings.PLAYER_NAME_FILE, self.player_name)
        pygame.key.stop_text_input()
        self.state = State.PLAYING
        self.state_time = 0.0  # seconds spent in the current state
        self.score = 0
        self.ducks.empty()
        self.round_started = datetime.now()
        self.highscore_rank = None

    def end_round(self) -> None:
        self.state = State.ROUND_OVER
        self.state_time = 0.0
        self.ducks.empty()
        self.highscore_rank = self.highscores.add(
            HighScore(self.score, self.round_started, self.player_name)
        )

    @property
    def time_left(self) -> float:
        return max(0.0, settings.ROUND_DURATION - self.state_time)

    def handle_events(self) -> None:
        for event in pygame.event.get():
            if event.type == pygame.QUIT or (
                event.type == pygame.KEYDOWN and event.key == pygame.K_ESCAPE
            ):
                self.running = False
            elif event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
                if self.state is State.PLAYING:
                    self.shoot(event.pos)
                elif self.state is State.NAME_ENTRY:
                    self.start_round()
                elif self.state is State.HIGHSCORES:
                    self.enter_name()
            elif self.state is State.NAME_ENTRY:
                if event.type == pygame.TEXTINPUT:
                    self.type_name(event.text)
                elif event.type == pygame.KEYDOWN and event.key == pygame.K_BACKSPACE:
                    self.player_name = self.player_name[:-1]
                elif event.type == pygame.KEYDOWN and event.key in (
                    pygame.K_RETURN,
                    pygame.K_KP_ENTER,
                ):
                    self.start_round()

    def shoot(self, pos: tuple[int, int]) -> bool:
        """Fire at screen position ``pos``. Hits at most one duck; returns whether one was hit.

        A miss costs ``settings.MISS_PENALTY`` points.
        """
        self.shot_sound.play()
        # Check the closest (drawn on top) duck first.
        for duck in reversed(self._ducks_far_to_near()):
            if duck.is_hit_by(pos):
                duck.shoot()
                self.score += duck.points
                return True
        self.score -= settings.MISS_PENALTY
        return False

    def _ducks_far_to_near(self) -> list[Duck]:
        return sorted(self.ducks, key=lambda duck: duck.scale)

    def update(self, dt: float) -> None:
        """Advance the game state by ``dt`` seconds."""
        self.ambience.update(dt)
        self.state_time += dt
        if self.state is State.PLAYING:
            if self.time_left <= 0:
                self.end_round()
                return
            # Send in a new duck once no duck is flying anymore (left the screen or shot).
            if all(duck.shot for duck in self.ducks):
                self.ducks.add(Duck(self.duck_image))
            self.ducks.update(dt)
        elif self.state is State.ROUND_OVER and self.state_time >= settings.SCORE_SCREEN_DURATION:
            self.state = State.HIGHSCORES
            self.state_time = 0.0

    def draw(self) -> None:
        self.screen.blit(self.background, (0, 0))
        if self.state is State.NAME_ENTRY:
            show_cursor = int(self.state_time * 2) % 2 == 0  # blinks twice per second
            self.name_entry_screen.draw(self.screen, self.player_name, show_cursor)
        elif self.state is State.PLAYING:
            # Far ducks first so closer ones are drawn in front of them.
            for duck in self._ducks_far_to_near():
                self.screen.blit(duck.image, duck.rect)
            self.hud.draw(self.screen, self.score, self.time_left)
        elif self.state is State.ROUND_OVER:
            seconds_left = settings.SCORE_SCREEN_DURATION - self.state_time
            self.round_over_screen.draw(self.screen, self.score, seconds_left)
        else:
            self.highscore_screen.draw(
                self.screen, self.highscores.entries, self.highscore_rank, self.score
            )
        pygame.display.flip()

    def run(self, max_frames: int | None = None) -> None:
        """Run the game loop until the window is closed (or ``max_frames`` have passed)."""
        frames = 0
        try:
            while self.running:
                dt = self.clock.tick(settings.FPS) / 1000
                self.handle_events()
                self.update(dt)
                self.draw()
                frames += 1
                if max_frames is not None and frames >= max_frames:
                    break
        finally:
            pygame.quit()
