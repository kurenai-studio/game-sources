import os
import random
import sys

import pygame

# Constants
ASSETS_DIR = os.path.join(os.path.dirname(__file__), "assets")
WIDTH, HEIGHT = 800, 600
WHITE = (255, 255, 255)
BLACK = (0, 0, 0)
RED = (255, 0, 0)
GREEN = (0, 255, 0)
GRAY = (105, 105, 105)
WELCOME_SCREEN = "welcome"
EXPLORE = "explore"
FIGHT = "fight"
FORTRESS_BOSS = "fortress_boss"
CASTLE_TASKS = "castle_tasks"
GAME_OVER = "game_over"
GAME_WON = "game_won"
PLAYER_SPEED = 5
FIREBALL_SPEED = 10

# Initialize Pygame
pygame.init()
pygame.mixer.init(44100, -16, 2, 2048)


class SoundManager:
    def __init__(self):
        self.explore_music = self.load_sound("music/explore.wav", 0.1)
        self.footsteps_sound = self.load_sound("music/player/footsteps.mp3", 0.6)
        self.hit_sound = self.load_sound("music/hit.wav", 0.3)
        self.sword_sound = self.load_sound("music/sword.wav", 0.4)
        self.footsteps_channel = (
            pygame.mixer.Channel(1) if self.footsteps_sound else None
        )

    def load_sound(self, path, volume):
        try:
            sound = pygame.mixer.Sound(os.path.join(ASSETS_DIR, path))
            sound.set_volume(volume)
            return sound
        except pygame.error as e:
            print(f"Couldn't load sound {path}: {e}")
            return None

    def play_sound(self, sound):
        if sound:
            sound.play()

    def stop_sound(self, sound):
        if sound:
            sound.stop()


class Player:
    def __init__(self, image):
        self.image = pygame.transform.scale(image, (100, 100))
        self.original_image = self.image  # Store the original image for rotation
        self.rect = self.image.get_rect(center=(100, HEIGHT // 2))
        self.health = 20
        self.damage = 5
        self.lives = 3
        self.facing_left = False
        self.is_moving = False
        self.footsteps_timer = 0
        self.angle = 0  # Initialize rotation angle
        self.angle_reset_time = None  # Timer for resetting angle
        self.grass_top = 140  # Define the top boundary of the grass
        self.grass_bottom = 450  # Define the bottom boundary of the grass

    def draw(self, screen):
        rotated_image = pygame.transform.rotate(self.original_image, self.angle)
        new_rect = rotated_image.get_rect(center=self.rect.center)
        if self.facing_left:
            screen.blit(pygame.transform.flip(rotated_image, True, False), new_rect)
        else:
            screen.blit(rotated_image, new_rect)

    def update(self):
        # Reset angle if the timer has expired
        if self.angle_reset_time and pygame.time.get_ticks() > self.angle_reset_time:
            self.angle = 0
            self.angle_reset_time = None

    def move(self, keys, game_phase):
        if game_phase == GAME_OVER:
            self.is_moving = False
            return

        old_pos = self.rect.copy()
        self.is_moving = False

        if keys[pygame.K_LEFT]:
            self.rect.x -= PLAYER_SPEED
            self.facing_left = True
            self.is_moving = True
        if keys[pygame.K_RIGHT]:
            self.rect.x += PLAYER_SPEED
            self.facing_left = False
            self.is_moving = True
        if keys[pygame.K_UP]:
            self.rect.y -= PLAYER_SPEED
            self.is_moving = True
        if keys[pygame.K_DOWN]:
            self.rect.y += PLAYER_SPEED
            self.is_moving = True

        # Restrict vertical movement to the grass area
        if self.rect.top < self.grass_top:
            self.rect.top = self.grass_top
        if self.rect.bottom > self.grass_bottom:
            self.rect.bottom = self.grass_bottom

        self.rect.clamp_ip(pygame.Rect(0, 0, WIDTH, HEIGHT))


class Fireball:
    def __init__(self, x, y, speed, image, vertical_speed=0):
        self.rect = pygame.Rect(x, y, 30, 30)
        self.speed = speed
        self.vertical_speed = vertical_speed
        self.image = image
        self.angle = 0  # Initialize rotation angle

    def move(self):
        self.rect.x -= self.speed
        self.rect.y += self.vertical_speed
        self.angle += 10  # Increase the angle increment for faster rotation

    def draw(self, screen):
        rotated_image = pygame.transform.rotate(self.image, self.angle)
        screen.blit(rotated_image, self.rect)


class Dragon:
    def __init__(self, image, heart_image, fireball_img):
        self.image = pygame.transform.scale(image, (200, 200))
        self.rect = self.image.get_rect(x=WIDTH - 200, y=100)
        self.speed = 3
        self.direction = 1
        self.health = 5
        self.heart_image = pygame.transform.scale(heart_image, (30, 30))
        self.fireballs = []
        self.last_fireball_time = 0
        self.fireball_delay = random.randint(800, 2200)
        self.fireball_img = fireball_img
        self.vertical_speed = 0

    def move(self, game_phase):
        if game_phase == GAME_OVER:
            return  # Stop moving if the game is over

        self.rect.y += self.speed * self.direction
        self.vertical_speed = self.speed * self.direction
        if self.rect.bottom >= HEIGHT or self.rect.top <= 0:
            self.direction *= -1

    def shoot_fireball(self):
        fireball = Fireball(
            self.rect.left,
            self.rect.centery,
            FIREBALL_SPEED,
            self.fireball_img,
            self.vertical_speed,
        )
        self.fireballs.append(fireball)

    def update_fireballs(self):
        for fireball in self.fireballs[:]:
            fireball.move()
            if fireball.rect.right < 0:
                self.fireballs.remove(fireball)

    def draw(self, screen):
        screen.blit(self.image, self.rect)
        for fireball in self.fireballs:
            fireball.draw(screen)

    def draw_hearts(self, screen):
        heart_spacing = 35
        start_x = WIDTH - (heart_spacing * self.health) - 10
        start_y = 10
        for i in range(self.health):
            screen.blit(self.heart_image, (start_x + (i * heart_spacing), start_y))


class WelcomeScreen:
    def __init__(self, screen, fonts, images):
        self.screen = screen
        self.font = fonts["font"]
        self.title_font = fonts["title_font"]
        self.castle_img = images["castle_img"]

    def draw(self):
        self.screen.blit(
            pygame.transform.scale(self.castle_img, (WIDTH, HEIGHT)), (0, 0)
        )
        overlay = pygame.Surface((WIDTH, HEIGHT))
        overlay.fill(BLACK)
        overlay.set_alpha(128)
        self.screen.blit(overlay, (0, 0))
        title_text = self.title_font.render("Bobik fights the dragon", True, WHITE)
        title_rect = title_text.get_rect(center=(WIDTH // 2, HEIGHT // 3))
        self.screen.blit(title_text, title_rect)
        start_text = self.font.render("Click to start", True, WHITE)
        start_rect = start_text.get_rect(center=(WIDTH // 2, HEIGHT * 2 // 3))
        pygame.draw.rect(self.screen, WHITE, start_rect.inflate(10, 10), 2)
        self.screen.blit(start_text, start_rect)
        if start_rect.collidepoint(pygame.mouse.get_pos()):
            pygame.mouse.set_cursor(pygame.SYSTEM_CURSOR_HAND)
        else:
            pygame.mouse.set_cursor(pygame.SYSTEM_CURSOR_ARROW)
        return start_rect


class GameOverScreen:
    def __init__(self, screen, fonts, images):
        self.screen = screen
        self.font = fonts["font"]
        self.title_font = fonts["title_font"]
        self.castle_img = images["castle_img"]

    def draw(self):
        self.screen.blit(
            pygame.transform.scale(self.castle_img, (WIDTH, HEIGHT)), (0, 0)
        )
        overlay = pygame.Surface((WIDTH, HEIGHT))
        overlay.fill(BLACK)
        overlay.set_alpha(192)
        self.screen.blit(overlay, (0, 0))
        game_over_text = self.title_font.render("GAME OVER", True, RED)
        game_over_rect = game_over_text.get_rect(center=(WIDTH // 2, HEIGHT // 3))
        self.screen.blit(game_over_text, game_over_rect)
        restart_text = self.font.render("Click to Play Again", True, WHITE)
        restart_rect = restart_text.get_rect(center=(WIDTH // 2, HEIGHT * 2 // 3))
        pygame.draw.rect(self.screen, WHITE, restart_rect.inflate(10, 10), 2)
        self.screen.blit(restart_text, restart_rect)
        if restart_rect.collidepoint(pygame.mouse.get_pos()):
            pygame.mouse.set_cursor(pygame.SYSTEM_CURSOR_HAND)
        else:
            pygame.mouse.set_cursor(pygame.SYSTEM_CURSOR_ARROW)
        return restart_rect


class VictoryScreen:
    def __init__(self, screen, fonts, images):
        self.screen = screen
        self.font = fonts["font"]
        self.title_font = fonts["title_font"]
        self.castle_img = images["castle_img"]

    def draw(self):
        self.screen.blit(
            pygame.transform.scale(self.castle_img, (WIDTH, HEIGHT)), (0, 0)
        )
        overlay = pygame.Surface((WIDTH, HEIGHT))
        overlay.fill(BLACK)
        overlay.set_alpha(192)
        self.screen.blit(overlay, (0, 0))
        victory_text = self.title_font.render("YOU WON!", True, GREEN)
        victory_rect = victory_text.get_rect(center=(WIDTH // 2, HEIGHT // 3))
        self.screen.blit(victory_text, victory_rect)
        restart_text = self.font.render("Click to Play Again", True, WHITE)
        restart_rect = restart_text.get_rect(center=(WIDTH // 2, HEIGHT * 2 // 3))
        self.screen.blit(restart_text, restart_rect)
        if restart_rect.collidepoint(pygame.mouse.get_pos()):
            pygame.mouse.set_cursor(pygame.SYSTEM_CURSOR_HAND)
        else:
            pygame.mouse.set_cursor(pygame.SYSTEM_CURSOR_ARROW)
        return restart_rect


class ScreenManager:
    def __init__(self, screen, fonts, images):
        self.screen = screen
        self.welcome_screen = WelcomeScreen(screen, fonts, images)
        self.game_over_screen = GameOverScreen(screen, fonts, images)
        self.victory_screen = VictoryScreen(screen, fonts, images)
        self.font = fonts["font"]
        self.heart_img = images["heart_img"]

    def draw_text(self, text, x, y, color=WHITE, with_frame=False):
        rendered_text = self.font.render(text, True, color)
        text_rect = rendered_text.get_rect(topleft=(x, y))
        if with_frame:
            pygame.draw.rect(self.screen, WHITE, text_rect.inflate(10, 10), 2)
        self.screen.blit(rendered_text, text_rect)

    def draw_player_lives(self, player_lives):
        heart_spacing = 35
        start_x = 10
        start_y = 10
        for i in range(player_lives):
            self.screen.blit(self.heart_img, (start_x + (i * heart_spacing), start_y))


class Game:
    def __init__(self):
        self.screen = pygame.display.set_mode((WIDTH, HEIGHT))
        pygame.display.set_caption("Bobiki: Zamek i Fortece")
        self.clock = pygame.time.Clock()
        self.font = pygame.font.Font(None, 36)
        self.title_font = pygame.font.Font(None, 74)
        self.background_img = pygame.transform.scale(
            pygame.image.load(os.path.join(ASSETS_DIR, "images/background.png")),
            (WIDTH, HEIGHT),
        )
        self.castle_img = pygame.image.load(
            os.path.join(ASSETS_DIR, "images/castle.png")
        )
        self.fortress_img = pygame.image.load(
            os.path.join(ASSETS_DIR, "images/fortress.png")
        )
        self.zombie_img = pygame.image.load(
            os.path.join(ASSETS_DIR, "images/zombie.png")
        )
        self.orc_img = pygame.image.load(os.path.join(ASSETS_DIR, "images/orc.png"))
        self.boss_img = pygame.image.load(os.path.join(ASSETS_DIR, "images/boss.png"))
        self.coin_img = pygame.image.load(os.path.join(ASSETS_DIR, "images/coin.png"))
        self.sword_img = pygame.image.load(os.path.join(ASSETS_DIR, "images/sword.png"))

        self.heart_img = pygame.image.load(os.path.join(ASSETS_DIR, "images/heart.png"))
        self.heart_img = pygame.transform.scale(self.heart_img, (30, 30))

        self.dragon_img = pygame.image.load(
            os.path.join(ASSETS_DIR, "images/dragon.png")
        )
        self.fireball_img = pygame.image.load(
            os.path.join(ASSETS_DIR, "images/fireball.png")
        )
        self.fireball_img = pygame.transform.scale(self.fireball_img, (30, 30))
        self.dragon_heart_img = pygame.image.load(
            os.path.join(ASSETS_DIR, "images/dragon-heart.png")
        )
        self.sound_manager = SoundManager()
        self.player = Player(
            pygame.image.load(os.path.join(ASSETS_DIR, "images/player3.png"))
        )
        self.dragon = Dragon(self.dragon_img, self.dragon_heart_img, self.fireball_img)
        self.enemies = [
            {"type": "zombie", "health": 10, "damage": 3, "position": (250, 350)},
            {"type": "orc", "health": 20, "damage": 5, "position": (500, 450)},
        ]
        self.boss = {
            "type": "mag",
            "health": 50,
            "damage": 10,
            "position": (WIDTH // 2 - 50, 100),
        }
        self.game_phase = WELCOME_SCREEN
        self.screen_manager = ScreenManager(
            self.screen,
            {"font": self.font, "title_font": self.title_font},
            {"castle_img": self.castle_img, "heart_img": self.heart_img},
        )

    def draw_enemies(self):
        for enemy in self.enemies:
            if enemy["type"] == "zombie":
                self.screen.blit(self.zombie_img, enemy["position"])
            elif enemy["type"] == "orc":
                self.screen.blit(self.orc_img, enemy["position"])
        if self.game_phase == "fortress_boss":
            self.screen.blit(self.boss_img, self.boss["position"])

    def handle_fight(self):
        for enemy in self.enemies:
            if random.random() < 0.5:
                self.player.health -= enemy["damage"]
            enemy["health"] -= self.player.damage
            if enemy["health"] <= 0:
                self.enemies.remove(enemy)
        if self.player.health <= 0:
            self.player.lives -= 1

            if self.player.lives <= 0:
                self.game_phase = GAME_OVER
            else:
                self.player.health = 20
        if not self.enemies:
            self.game_phase = "fortress_boss"

    def fight_boss(self):
        self.player.health -= self.boss["damage"]
        self.boss["health"] -= self.player.damage
        if self.boss["health"] <= 0:
            self.screen_manager.draw_text(
                "Pokonałeś bossa! Gratulacje!", WIDTH // 2 - 100, HEIGHT // 2 - 50
            )
            self.game_phase = "explore"

    def reset_game(self):
        self.player.health = 20
        self.player.damage = 5
        self.player.lives = 3
        self.dragon.health = 5
        self.player.rect.center = (WIDTH // 2, HEIGHT // 2)
        self.enemies = [
            {"type": "zombie", "health": 10, "damage": 3, "position": (250, 350)},
            {"type": "orc", "health": 20, "damage": 5, "position": (500, 450)},
        ]
        self.boss = {
            "type": "mag",
            "health": 50,
            "damage": 10,
            "position": (WIDTH // 2 - 50, 100),
        }
        self.dragon.fireballs.clear()
        self.game_phase = EXPLORE
        self.sound_manager.stop_sound(self.sound_manager.explore_music)
        self.sound_manager.play_sound(self.sound_manager.explore_music)

    def run(self):
        running = True
        while running:
            self.screen.fill(BLACK)
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    running = False
                if event.type == pygame.MOUSEBUTTONDOWN:
                    x, y = event.pos
                    if self.game_phase == WELCOME_SCREEN:
                        start_rect = self.screen_manager.welcome_screen.draw()
                        if start_rect.collidepoint(x, y):
                            self.game_phase = EXPLORE
                            self.sound_manager.play_sound(
                                self.sound_manager.explore_music
                            )
                    if self.game_phase == GAME_OVER:
                        restart_rect = self.screen_manager.game_over_screen.draw()
                        if restart_rect.collidepoint(x, y):
                            self.reset_game()
                    if self.game_phase == GAME_WON:
                        restart_rect = self.screen_manager.victory_screen.draw()
                        if restart_rect.collidepoint(x, y):
                            self.reset_game()
                if event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_SPACE:
                        self.sound_manager.play_sound(self.sound_manager.sword_sound)
                        self.player.angle += 15  # Rotate the player by 15 degrees
                        if self.player.rect.colliderect(self.dragon.rect):
                            self.dragon.health -= 1
                            if self.dragon.health <= 0:
                                self.game_phase = GAME_WON
                if event.type == pygame.KEYUP:
                    if event.key == pygame.K_SPACE:
                        self.player.angle = (
                            0  # Reset the player's angle when space is released
                        )
                if event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_u:
                        message = self.upgrade_weapon()
                        print(message)

            if self.game_phase == EXPLORE:
                keys = pygame.key.get_pressed()
                self.player.move(keys, self.game_phase)
                current_time = pygame.time.get_ticks()
                if (
                    current_time - self.dragon.last_fireball_time
                    > self.dragon.fireball_delay
                ):
                    self.dragon.shoot_fireball()
                    self.dragon.last_fireball_time = current_time
                    self.dragon.fireball_delay = random.randint(1000, 2000)
                if self.player.is_moving and self.sound_manager.footsteps_sound:
                    if current_time - self.player.footsteps_timer >= 300:
                        if (
                            self.sound_manager.footsteps_channel
                            and not self.sound_manager.footsteps_channel.get_busy()
                        ):
                            self.sound_manager.footsteps_channel.play(
                                self.sound_manager.footsteps_sound
                            )
                            self.player.footsteps_timer = current_time
                elif not self.player.is_moving and self.sound_manager.footsteps_channel:
                    self.sound_manager.footsteps_channel.stop()
                self.screen_manager.draw_player_lives(self.player.lives)

            if self.game_phase == WELCOME_SCREEN:
                self.screen_manager.welcome_screen.draw()
            elif self.game_phase == EXPLORE:
                self.screen.blit(self.background_img, (0, 0))
                self.player.draw(self.screen)
                self.dragon.move(self.game_phase)
                self.dragon.update_fireballs()
                self.dragon.draw(self.screen)
                self.dragon.draw_hearts(self.screen)
                self.screen_manager.draw_player_lives(self.player.lives)
                for fireball in self.dragon.fireballs[:]:
                    if self.player.rect.colliderect(fireball.rect):
                        self.dragon.fireballs.remove(fireball)
                        self.player.lives -= 1
                        self.player.rect.center = (50, HEIGHT // 2)
                        self.sound_manager.play_sound(self.sound_manager.hit_sound)
                        flash_surface = pygame.Surface((WIDTH, HEIGHT))
                        flash_surface.fill((255, 0, 0))
                        flash_surface.set_alpha(128)
                        self.screen.blit(flash_surface, (0, 0))
                        pygame.display.flip()
                        pygame.time.wait(1000)
                        if self.player.lives <= 0:
                            self.game_phase = GAME_OVER
                        else:
                            self.player.rect.center = (50, HEIGHT // 2)
            elif self.game_phase == FIGHT:
                self.draw_enemies()
                self.handle_fight()
                self.screen_manager.draw_player_lives(self.player.lives)
            elif self.game_phase == FORTRESS_BOSS:
                self.draw_enemies()
                self.fight_boss()
                self.screen_manager.draw_player_lives(self.player.lives)
            elif self.game_phase == CASTLE_TASKS:
                self.screen_manager.draw_text(
                    "W zamku: Naciśnij U, aby ulepszyć broń", 10, 10
                )
            elif self.game_phase == GAME_OVER:
                self.screen_manager.game_over_screen.draw()
                self.sound_manager.stop_sound(self.sound_manager.footsteps_sound)
                self.sound_manager.stop_sound(self.sound_manager.explore_music)
            elif self.game_phase == GAME_WON:
                self.screen_manager.victory_screen.draw()
                self.sound_manager.stop_sound(self.sound_manager.footsteps_sound)

            pygame.display.flip()
            self.clock.tick(30)

        self.sound_manager.stop_sound(self.sound_manager.footsteps_sound)
        self.sound_manager.stop_sound(self.sound_manager.explore_music)
        pygame.mixer.quit()
        pygame.quit()
        sys.exit()


def main():
    game = Game()
    game.run()


if __name__ == "__main__":
    main()
