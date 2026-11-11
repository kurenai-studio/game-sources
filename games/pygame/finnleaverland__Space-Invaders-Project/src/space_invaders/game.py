"""The Space Invaders game itself, written with pygame.

Call main() to play one game in its own window. It returns the final score.

A game moves through four states: the start screen, playing, paused and game over.
Game time only moves forward while playing, so pausing really does freeze everything.
"""
import os
import random

import pygame
from pygame.locals import K_ESCAPE, K_LEFT, K_RIGHT, K_SPACE, KEYDOWN, QUIT, K_m, K_p

# Asset folders, so the images and sounds load whatever folder you run from
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IMAGE_DIR = os.path.join(PROJECT_ROOT, "assets", "images")
SOUND_DIR = os.path.join(PROJECT_ROOT, "assets", "sounds")

# Window
SCREEN_WIDTH = 600
SCREEN_HEIGHT = 800
FPS = 60
WINDOW_TITLE = "Space Invaders"

FRAME_MS = 1000 / FPS  # game time that passes each frame

# Game states
READY = "ready"  # the start screen
PLAYING = "playing"
PAUSED = "paused"
GAME_OVER = "game over"
GAME_OVER_DELAY = 1200  # ms after dying before SPACE returns to the menu (so it isn't skipped by accident)

# Colours (the same palette as the menus in theme.py)
TEXT = (232, 236, 248)
MUTED = (141, 148, 179)
ACCENT = (79, 195, 247)
WARNING = (255, 107, 107)
GOLD = (255, 209, 102)
BAR_COLOUR = (11, 14, 31, 200)  # the top bar: dark and slightly see-through
OVERLAY_COLOUR = (11, 14, 31, 170)  # dims the game behind pause and game over text
PANEL_COLOUR = (22, 27, 54, 240)  # the box that pause and game over text sits on
PANEL_BORDER = (44, 53, 96)
PANEL_RADIUS = 16

# Fonts (the first one installed is used)
FONT_NAMES = "segoeui,helveticaneue,helvetica,dejavusans,arial"
SMALL_FONT_SIZE = 18
FONT_SIZE = 26
BIG_FONT_SIZE = 64

# Sound: how loud each effect is at full volume. The laser plays all the time, so it's
# the quietest; the player's ship exploding is the loudest. The menu's volume slider
# scales all of them.
SOUND_LEVELS = {
    "laser": 0.25,
    "explosion": 0.5,
    "player_explosion": 0.7,
}

# Top bar
BAR_HEIGHT = 44
BAR_MARGIN = 14
LIFE_ICON_SIZE = (26, 20)
MAX_LIFE_ICONS = 5  # with more lives than this, a number is shown instead

# Player
PLAYER_START_POS = (SCREEN_WIDTH // 2, SCREEN_HEIGHT - 70)
PLAYER_SPEED = 4  # pixels per frame
PLAYER_LIVES = 5
PLAYER_SHOT_COOLDOWN = 30  # frames between shots
FRAME_COUNTER_LIMIT = 1_000_000  # the shot counter wraps back to 0 after this
BULLET_SPEED = 4  # pixels per frame, upwards

# Aliens
ALIEN_IMAGES = ("alien1.png", "alien2.png", "alien3.png", "alien4.png")
ALIEN_ROWS = 5
ALIEN_COLUMNS = 5
ALIEN_GRID_LEFT = 100
ALIEN_GRID_TOP = 150
ALIEN_SPACING_X = 100
ALIEN_SPACING_Y = 70
ALIEN_START_SPEED = 1.0  # pixels per frame the formation moves sideways in wave 1
ALIEN_MAX_SPEED = 3.0
ALIEN_STEP_DOWN = 12  # pixels the formation drops each time it reaches the edge
FORMATION_EDGE = 10  # how close to the side of the screen the formation gets
ALIEN_SHOT_COOLDOWN = 1000  # milliseconds between alien shots in wave 1
ALIEN_MIN_SHOT_COOLDOWN = 350
WAVE_SPEED_UP = 0.15  # each wave the aliens move 15% faster...
WAVE_SHOT_SPEED_UP = 0.10  # ...and fire 10% more often
ALIEN_BULLET_SPEED = 3  # pixels per frame, downwards
ALIEN_POINTS = 10
WAVE_BONUS = 100  # points for clearing a wave (not given for the first wave)

# Mystery alien
MYSTERY_START_POS = (100, 80)
MYSTERY_MOVE_RANGE = 400  # pixels it travels before turning round
MYSTERY_SPAWN_DELAY = 1050  # milliseconds after the last one before a new one appears
EXTRA_LIFE = "extra life"
MYSTERY_REWARDS = (EXTRA_LIFE, 100, 150, 200)  # one is picked at random

# Explosions: which image to show and for how many frames
# Explosions are strips of square frames drawn by tools/make_explosions.py:
# (image, frame size in pixels, game frames each picture is shown for)
ALIEN_EXPLOSION = ("explosion1.png", 40, 3)  # 8 pictures x 3 = 0.4 seconds
PLAYER_EXPLOSION = ("explosion2.png", 80, 5)  # 10 pictures x 5 = about 0.8 seconds

# After losing a life the ship blinks and can't be hit for a moment
INVINCIBLE_TIME = 1500  # ms
BLINK_INTERVAL = 100  # ms the ship spends visible, then hidden, while blinking

SPRITE_IMAGES = ALIEN_IMAGES + (
    "spaceship.png", "bullet.png", "alien_bullet.png", "mysteryalien.png",
    ALIEN_EXPLOSION[0], PLAYER_EXPLOSION[0],
)


def image_path(filename):
    """Return the full path to an image in assets/images."""
    return os.path.join(IMAGE_DIR, filename)


def sound_path(filename):
    """Return the full path to a sound in assets/sounds."""
    return os.path.join(SOUND_DIR, filename)


class Player(pygame.sprite.Sprite):
    """The player's ship. It moves left and right, shoots, and keeps the score and lives."""

    def __init__(self, game, x, y):
        super().__init__()
        self.game = game
        self.image = game.images["spaceship.png"]
        self.rect = self.image.get_rect(center=(x, y))
        self.frame_count = 0
        self.score = 0
        self.lives = PLAYER_LIVES
        self.invincible_until = 0.0  # game time when the invincibility after a hit runs out

    @property
    def invincible(self):
        return self.game.time < self.invincible_until

    def update(self, pressed_keys):
        """Move and shoot based on the keys being held down."""
        if self.lives <= 0:
            return  # a dead player can't move or shoot

        self.frame_count += 1
        if self.frame_count > FRAME_COUNTER_LIMIT:
            self.frame_count = 0
        if pressed_keys[K_LEFT]:
            self.rect.move_ip(-PLAYER_SPEED, 0)
        if pressed_keys[K_RIGHT]:
            self.rect.move_ip(PLAYER_SPEED, 0)

        if pressed_keys[K_SPACE] and self.frame_count % PLAYER_SHOT_COOLDOWN == 0:
            self.game.laser_sound.play()
            bullet = Bullet(self.game, self.rect.centerx, self.rect.top)
            self.game.bullet_group.add(bullet)

        # Keep the player on the screen
        if self.rect.left < 0:
            self.rect.left = 0
        if self.rect.right > SCREEN_WIDTH:
            self.rect.right = SCREEN_WIDTH

    def hit(self):
        """Lose a life after being hit by an alien bullet, and explode on the last one.

        Losing a life makes the ship invincible for a moment, so one burst of bullets
        can't take several lives at once.
        """
        if self.lives <= 0 or self.invincible:
            return
        self.lives -= 1
        if self.lives <= 0:
            self.destroy()
        else:
            self.invincible_until = self.game.time + INVINCIBLE_TIME

    def destroy(self):
        """Blow up the ship and end the game (out of lives, or the aliens have landed)."""
        self.lives = 0
        self.game.player_death_sound.play()
        explosion = Explosion(self.game, self.rect.center, *PLAYER_EXPLOSION)
        self.game.player_explosion_group.add(explosion)
        self.kill()


class Bullet(pygame.sprite.Sprite):
    """A bullet fired upwards by the player."""

    def __init__(self, game, x, y):
        super().__init__()
        self.game = game
        self.image = game.images["bullet.png"]
        self.rect = self.image.get_rect(center=(x, y))

    def update(self):
        """Move up, disappear off the top of the screen, and destroy any alien it hits."""
        self.rect.y -= BULLET_SPEED
        if self.rect.bottom < 0:
            self.kill()
        hit_aliens = pygame.sprite.spritecollide(self, self.game.alien_group, True)
        if hit_aliens:
            self.game.player.score += ALIEN_POINTS
            self.kill()
            self.game.explosion_sound.play()
            explosion = Explosion(self.game, hit_aliens[0].rect.center, *ALIEN_EXPLOSION)
            self.game.alien_explosion_group.add(explosion)


class Alien(pygame.sprite.Sprite):
    """An ordinary alien. The Game moves all of them together as one formation."""

    def __init__(self, game, x, y):
        super().__init__()
        self.image = game.images[random.choice(ALIEN_IMAGES)]
        self.rect = self.image.get_rect(center=(x, y))
        self.x = float(self.rect.x)  # exact position, as speeds aren't whole pixels

    def move(self, dx, dy=0):
        self.x += dx
        self.rect.x = round(self.x)
        self.rect.y += dy


class AlienBullet(pygame.sprite.Sprite):
    """A bullet fired downwards by an alien."""

    def __init__(self, game, x, y):
        super().__init__()
        self.game = game
        self.image = game.images["alien_bullet.png"]
        self.rect = self.image.get_rect(center=(x, y))

    def update(self):
        """Move down, disappear off the bottom of the screen, and hurt the player on contact."""
        self.rect.y += ALIEN_BULLET_SPEED
        if self.rect.top > SCREEN_HEIGHT:
            self.kill()
        player = self.game.player
        if not player.invincible and pygame.sprite.spritecollide(self, self.game.player_group, False):
            self.kill()
            player.hit()


class MysteryAlien(pygame.sprite.Sprite):
    """The special alien that crosses the top of the screen and gives a random reward."""

    def __init__(self, game, x, y):
        super().__init__()
        self.game = game
        self.image = game.images["mysteryalien.png"]
        self.rect = self.image.get_rect(center=(x, y))
        self.move_counter = 0  # how far it has moved from where it started
        self.move_direction = 1

    def update(self):
        """Move 1 pixel, and if a bullet hits it, give the player a random reward."""
        self.rect.x += self.move_direction
        self.move_counter += self.move_direction
        if self.move_counter >= MYSTERY_MOVE_RANGE or self.move_counter <= 0:
            self.move_direction *= -1
        if pygame.sprite.spritecollide(self, self.game.bullet_group, True):
            self.game.explosion_sound.play()
            explosion = Explosion(self.game, self.rect.center, *ALIEN_EXPLOSION)
            self.game.alien_explosion_group.add(explosion)
            reward = random.choice(MYSTERY_REWARDS)
            if reward == EXTRA_LIFE:
                self.game.player.lives += 1
            else:
                self.game.player.score += reward
            self.kill()


class Explosion(pygame.sprite.Sprite):
    """An animated explosion that plays through its pictures once and then disappears."""

    def __init__(self, game, center, image_name, frame_size, hold):
        super().__init__()
        self.pictures = game.animations[image_name]
        self.hold = hold  # game frames each picture stays on screen
        self.age = 0
        self.image = self.pictures[0]
        self.rect = self.image.get_rect(center=center)

    def update(self):
        """Move on to the next picture when it's time, and disappear after the last one."""
        self.age += 1
        index = self.age // self.hold
        if index >= len(self.pictures):
            self.kill()
        else:
            self.image = self.pictures[index]


def split_strip(strip, frame_size):
    """Cut a horizontal strip of square pictures into a list of separate pictures."""
    return [strip.subsurface((x, 0, frame_size, frame_size))
            for x in range(0, strip.get_width(), frame_size)]


class Game:
    """One game of Space Invaders: the window, the loaded assets, every sprite and the timers."""

    def __init__(self, high_score=0, volume=1.0):
        pygame.init()
        pygame.mixer.init()

        os.environ.setdefault("SDL_VIDEO_CENTERED", "1")  # open the window in the middle of the screen
        self.screen = pygame.display.set_mode((SCREEN_WIDTH, SCREEN_HEIGHT))
        pygame.display.set_caption(WINDOW_TITLE)
        self.clock = pygame.time.Clock()

        # Load every image and sound once, rather than each time a sprite is made
        self.background = pygame.image.load(image_path("background.png")).convert()
        self.images = {name: pygame.image.load(image_path(name)).convert_alpha()
                       for name in SPRITE_IMAGES}
        self.animations = {name: split_strip(self.images[name], size)
                           for name, size, _ in (ALIEN_EXPLOSION, PLAYER_EXPLOSION)}
        self.life_icon = pygame.transform.smoothscale(self.images["spaceship.png"], LIFE_ICON_SIZE)
        self.small_font = pygame.font.SysFont(FONT_NAMES, SMALL_FONT_SIZE)
        self.font = pygame.font.SysFont(FONT_NAMES, FONT_SIZE, bold=True)
        self.big_font = pygame.font.SysFont(FONT_NAMES, BIG_FONT_SIZE, bold=True)
        self.explosion_sound = pygame.mixer.Sound(sound_path("explosion.ogg"))
        self.player_death_sound = pygame.mixer.Sound(sound_path("player_explosion.ogg"))
        self.laser_sound = pygame.mixer.Sound(sound_path("laser.ogg"))
        self.sounds = {"laser": self.laser_sound, "explosion": self.explosion_sound,
                       "player_explosion": self.player_death_sound}
        self.volume = volume  # 0.0 to 1.0, from the menu's volume slider
        self.muted = False
        self.apply_volume()

        self.player_group = pygame.sprite.Group()
        self.bullet_group = pygame.sprite.Group()
        self.alien_group = pygame.sprite.Group()
        self.alien_bullet_group = pygame.sprite.Group()
        self.mystery_alien_group = pygame.sprite.Group()
        self.alien_explosion_group = pygame.sprite.Group()
        self.player_explosion_group = pygame.sprite.Group()

        self.player = Player(self, *PLAYER_START_POS)
        self.player_group.add(self.player)

        self.high_score = high_score  # the player's best score before this game
        self.state = READY
        self.running = True
        self.time = 0.0  # game time in ms; only moves forward while playing
        self.wave = 0
        self.formation_direction = 1  # 1 = moving right, -1 = moving left
        self.last_alien_shot = 0.0
        self.last_mystery_spawn = 0.0
        self.died_at = None

    @property
    def new_high_score(self):
        return self.player.score > self.high_score

    def apply_volume(self):
        """Set each sound to its own level, scaled by the volume (silent when muted)."""
        master = 0.0 if self.muted else self.volume
        for name, sound in self.sounds.items():
            sound.set_volume(SOUND_LEVELS[name] * master)

    @property
    def alien_speed(self):
        """How fast the formation moves this wave (pixels per frame)."""
        return min(ALIEN_MAX_SPEED, ALIEN_START_SPEED * (1 + WAVE_SPEED_UP) ** (self.wave - 1))

    @property
    def alien_shot_cooldown(self):
        """Time between alien shots this wave (ms)."""
        cooldown = ALIEN_SHOT_COOLDOWN * (1 - WAVE_SHOT_SPEED_UP) ** (self.wave - 1)
        return max(ALIEN_MIN_SHOT_COOLDOWN, cooldown)

    def run(self):
        """Run the game loop until the player leaves, and return the final score."""
        while self.running:
            self.clock.tick(FPS)
            for event in pygame.event.get():
                self.handle_event(event)
            self.step(pygame.key.get_pressed())
            self.draw()
            pygame.display.flip()
        return self.player.score

    # --- Input -----------------------------------------------------------------------

    def handle_event(self, event):
        """React to the window being closed and to single key presses."""
        if event.type == QUIT:
            self.running = False
        elif event.type == KEYDOWN:
            self.handle_key(event.key)

    def handle_key(self, key):
        if key == K_ESCAPE:
            self.running = False
        elif key == K_SPACE and self.state == READY:
            self.state = PLAYING
        elif key == K_SPACE and self.state == GAME_OVER and self.can_leave():
            self.running = False
        elif key == K_p and self.state == PLAYING:
            self.state = PAUSED
        elif key == K_p and self.state == PAUSED:
            self.state = PLAYING
        elif key == K_m:
            self.muted = not self.muted
            self.apply_volume()

    def can_leave(self):
        """After dying, SPACE only works once the explosion has had time to play."""
        return self.died_at is not None and self.time - self.died_at >= GAME_OVER_DELAY

    # --- One frame of game logic ---------------------------------------------------------

    def step(self, pressed_keys):
        """Advance the game by one frame (nothing moves on the start screen or while paused)."""
        if self.state not in (PLAYING, GAME_OVER):
            return
        self.time += FRAME_MS
        self.spawn_enemies()
        self.update(pressed_keys)
        if self.state == PLAYING and self.player.lives <= 0:
            self.state = GAME_OVER
            self.died_at = self.time

    def spawn_enemies(self):
        """Bring in the mystery alien and new waves, and let a random alien shoot."""
        if not self.mystery_alien_group and self.time - self.last_mystery_spawn > MYSTERY_SPAWN_DELAY:
            self.mystery_alien_group.add(MysteryAlien(self, *MYSTERY_START_POS))
            self.last_mystery_spawn = self.time

        if not self.alien_group:
            if self.wave > 0:  # no bonus before the very first wave
                self.player.score += WAVE_BONUS
            self.wave += 1
            self.create_aliens()

        if self.player.lives > 0 and self.time - self.last_alien_shot > self.alien_shot_cooldown:
            shooter = random.choice(self.alien_group.sprites())
            self.alien_bullet_group.add(AlienBullet(self, shooter.rect.centerx, shooter.rect.bottom))
            self.laser_sound.play()
            self.last_alien_shot = self.time

    def create_aliens(self):
        """Fill the grid with a new wave of aliens."""
        self.formation_direction = 1
        for row in range(ALIEN_ROWS):
            for column in range(ALIEN_COLUMNS):
                x = ALIEN_GRID_LEFT + column * ALIEN_SPACING_X
                y = ALIEN_GRID_TOP + row * ALIEN_SPACING_Y
                self.alien_group.add(Alien(self, x, y))

    def update(self, pressed_keys):
        """Move every sprite one frame."""
        self.player.update(pressed_keys)
        self.bullet_group.update()
        self.move_formation()
        self.alien_bullet_group.update()
        self.alien_explosion_group.update()
        self.player_explosion_group.update()
        self.mystery_alien_group.update()

    def move_formation(self):
        """Slide the aliens sideways together; at the edge, drop down a step and turn round.

        If they get down to the player's ship, it's game over.
        """
        aliens = self.alien_group.sprites()
        if not aliens:
            return
        dx = self.formation_direction * self.alien_speed
        left = min(alien.x for alien in aliens) + dx
        right = max(alien.x + alien.rect.width for alien in aliens) + dx
        if left < FORMATION_EDGE or right > SCREEN_WIDTH - FORMATION_EDGE:
            self.formation_direction *= -1
            for alien in aliens:
                alien.move(0, ALIEN_STEP_DOWN)
        else:
            for alien in aliens:
                alien.move(dx)

        landing_line = PLAYER_START_POS[1] - self.player.rect.height // 2
        if self.player.lives > 0 and max(alien.rect.bottom for alien in aliens) >= landing_line:
            self.player.destroy()

    # --- Drawing -----------------------------------------------------------------------

    def draw(self):
        """Draw the current state: start screen, game, pause overlay or game over."""
        self.screen.blit(self.background, (0, 0))
        if self.state == READY:
            self.draw_start_screen()
            return
        if self.player_visible():
            self.player_group.draw(self.screen)
        for group in (self.bullet_group, self.alien_group, self.alien_bullet_group,
                      self.alien_explosion_group, self.player_explosion_group,
                      self.mystery_alien_group):
            group.draw(self.screen)
        self.draw_top_bar()
        if self.state == PAUSED:
            self.draw_overlay()
            self.draw_panel(height=170, centre_y=390)
            self.draw_text("PAUSED", self.big_font, TEXT, center=(SCREEN_WIDTH // 2, 370))
            self.draw_text("Press P to carry on  ·  ESC to quit", self.small_font, MUTED,
                           center=(SCREEN_WIDTH // 2, 430))
        elif self.state == GAME_OVER:
            self.draw_game_over()

    def player_visible(self):
        """The ship blinks while it's invincible after a hit."""
        return not self.player.invincible or int(self.time // BLINK_INTERVAL) % 2 == 0

    def draw_start_screen(self):
        middle = SCREEN_WIDTH // 2
        self.draw_text("SPACE INVADERS", self.big_font, ACCENT, center=(middle, 250))
        self.draw_text(f"Your high score: {self.high_score}", self.small_font, MUTED, center=(middle, 310))
        if (pygame.time.get_ticks() // 600) % 2 == 0:  # blink
            self.draw_text("Press SPACE to start", self.font, TEXT, center=(middle, 420))
        for row, line in enumerate(("LEFT / RIGHT  move", "SPACE  shoot (hold to keep firing)",
                                    "P  pause", "M  sound on / off", "ESC  quit to the menu")):
            self.draw_text(line, self.small_font, MUTED, center=(middle, 520 + row * 30))

    def draw_top_bar(self):
        """Score on the left, wave in the middle, lives on the right, on a dark strip."""
        bar = pygame.Surface((SCREEN_WIDTH, BAR_HEIGHT), pygame.SRCALPHA)
        bar.fill(BAR_COLOUR)
        self.screen.blit(bar, (0, 0))
        middle_y = BAR_HEIGHT // 2
        self.draw_text(f"SCORE  {self.player.score}", self.font, TEXT, midleft=(BAR_MARGIN, middle_y))
        self.draw_text(f"WAVE  {self.wave}", self.font, ACCENT, center=(SCREEN_WIDTH // 2, middle_y))

        if self.muted:
            self.draw_text("SOUND OFF", self.small_font, MUTED,
                           topright=(SCREEN_WIDTH - BAR_MARGIN, BAR_HEIGHT + 6))

        lives = self.player.lives
        right = SCREEN_WIDTH - BAR_MARGIN
        if lives > MAX_LIFE_ICONS:
            label = self.draw_text(f"× {lives}", self.font, TEXT, midright=(right, middle_y))
            self.screen.blit(self.life_icon, self.life_icon.get_rect(midright=(label.left - 6, middle_y)))
        else:
            for i in range(lives):
                icon_right = right - i * (LIFE_ICON_SIZE[0] + 6)
                self.screen.blit(self.life_icon, self.life_icon.get_rect(midright=(icon_right, middle_y)))

    def draw_overlay(self):
        overlay = pygame.Surface((SCREEN_WIDTH, SCREEN_HEIGHT), pygame.SRCALPHA)
        overlay.fill(OVERLAY_COLOUR)
        self.screen.blit(overlay, (0, 0))

    def draw_panel(self, height, centre_y, width=440):
        """A rounded box in the middle of the screen for text to sit on."""
        panel = pygame.Surface((width, height), pygame.SRCALPHA)
        pygame.draw.rect(panel, PANEL_COLOUR, panel.get_rect(), border_radius=PANEL_RADIUS)
        pygame.draw.rect(panel, PANEL_BORDER, panel.get_rect(), width=2, border_radius=PANEL_RADIUS)
        self.screen.blit(panel, panel.get_rect(center=(SCREEN_WIDTH // 2, centre_y)))

    def draw_game_over(self):
        """Once the explosion has played, show the score, high score and how to leave."""
        if not self.can_leave():
            return
        middle = SCREEN_WIDTH // 2
        self.draw_overlay()
        self.draw_panel(height=360, centre_y=420)
        self.draw_text("GAME OVER", self.big_font, WARNING, center=(middle, 300))
        self.draw_text(f"Score  {self.player.score}", self.font, TEXT, center=(middle, 380))
        best = max(self.high_score, self.player.score)
        self.draw_text(f"High score  {best}", self.font, MUTED, center=(middle, 420))
        if self.new_high_score:
            self.draw_text("NEW HIGH SCORE!", self.font, GOLD, center=(middle, 480))
        self.draw_text("Press SPACE to return to the menu", self.small_font, MUTED, center=(middle, 545))

    def draw_text(self, text, font, colour, **position):
        """Draw text placed by a rect position, e.g. center=(x, y). Returns where it was drawn."""
        image = font.render(text, True, colour)
        rect = image.get_rect(**position)
        self.screen.blit(image, rect)
        return rect


def main(high_score=0, volume=1.0):
    """Play one game in a new window, close the window, and return the final score.

    high_score is the player's best score so far, shown on the start and game over screens.
    volume (0.0 to 1.0) comes from the menu's volume slider.
    """
    try:
        return Game(high_score, volume).run()
    finally:
        pygame.quit()


if __name__ == "__main__":
    print("Score:", main())
