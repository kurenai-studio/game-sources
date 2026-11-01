"""A simple space shooter.

Controls: arrows or WASD to move, Space to shoot, P to pause, Esc to quit.
"""

import random
import sys

import pygame

WIDTH, HEIGHT = 480, 640
FPS = 60

BLACK = (5, 5, 20)
WHITE = (240, 240, 240)
CYAN = (80, 220, 255)
RED = (240, 80, 80)
ORANGE = (255, 170, 60)
YELLOW = (255, 230, 100)
GREEN = (100, 230, 120)

PLAYER_SPEED = 320  # pixels per second
PLAYER_LIVES = 3
FIRE_COOLDOWN = 0.2  # seconds
INVULNERABLE_TIME = 2.0  # seconds after being hit
BULLET_SPEED = 600
ENEMY_BULLET_SPEED = 260


class Player(pygame.sprite.Sprite):
    def __init__(self):
        super().__init__()
        self.image = pygame.Surface((40, 36), pygame.SRCALPHA)
        pygame.draw.polygon(self.image, CYAN, [(20, 0), (40, 36), (20, 27), (0, 36)])
        pygame.draw.circle(self.image, WHITE, (20, 18), 4)
        self.rect = self.image.get_rect(midbottom=(WIDTH // 2, HEIGHT - 20))
        self.pos = pygame.Vector2(self.rect.center)
        self.cooldown = 0.0
        self.invulnerable = 0.0

    def update(self, dt):
        keys = pygame.key.get_pressed()
        direction = pygame.Vector2(
            (keys[pygame.K_RIGHT] or keys[pygame.K_d])
            - (keys[pygame.K_LEFT] or keys[pygame.K_a]),
            (keys[pygame.K_DOWN] or keys[pygame.K_s])
            - (keys[pygame.K_UP] or keys[pygame.K_w]),
        )
        if direction.length_squared() > 0:
            direction.normalize_ip()  # diagonal moves aren't faster

        self.pos += direction * PLAYER_SPEED * dt
        self.rect.center = self.pos
        self.rect.clamp_ip(pygame.Rect(0, 0, WIDTH, HEIGHT))
        self.pos.update(self.rect.center)

        self.cooldown = max(0.0, self.cooldown - dt)
        self.invulnerable = max(0.0, self.invulnerable - dt)

        # Blink while invulnerable.
        visible = self.invulnerable == 0 or int(self.invulnerable * 10) % 2 == 0
        self.image.set_alpha(255 if visible else 60)


class Bullet(pygame.sprite.Sprite):
    def __init__(self, x, y, velocity_y, color):
        super().__init__()
        self.image = pygame.Surface((4, 14))
        self.image.fill(color)
        self.rect = self.image.get_rect(center=(x, y))
        self.y = float(y)
        self.velocity_y = velocity_y

    def update(self, dt):
        self.y += self.velocity_y * dt
        self.rect.centery = round(self.y)
        if self.rect.bottom < 0 or self.rect.top > HEIGHT:
            self.kill()


class Enemy(pygame.sprite.Sprite):
    def __init__(self, level):
        super().__init__()
        size = random.randint(28, 44)
        self.image = pygame.Surface((size, size), pygame.SRCALPHA)
        pygame.draw.polygon(
            self.image,
            RED,
            [(0, 0), (size, 0), (size * 3 // 4, size * 2 // 3), (size // 2, size),
             (size // 4, size * 2 // 3)],
        )
        pygame.draw.circle(self.image, YELLOW, (size // 2, size // 3), size // 8)
        self.rect = self.image.get_rect(
            midbottom=(random.randint(size, WIDTH - size), 0)
        )
        self.pos = pygame.Vector2(self.rect.center)
        self.velocity = pygame.Vector2(
            random.uniform(-60, 60), random.uniform(80, 130) + level * 12
        )
        self.shoot_timer = random.uniform(1.0, 3.5)

    def update(self, dt):
        self.pos += self.velocity * dt
        half_width = self.rect.width / 2
        if self.pos.x < half_width or self.pos.x > WIDTH - half_width:
            self.velocity.x *= -1
            self.pos.x = max(half_width, min(WIDTH - half_width, self.pos.x))
        self.rect.center = self.pos
        self.shoot_timer -= dt
        if self.rect.top > HEIGHT:
            self.kill()


class Particle(pygame.sprite.Sprite):
    """A spark from an explosion."""

    def __init__(self, center):
        super().__init__()
        size = random.randint(2, 5)
        self.image = pygame.Surface((size, size))
        self.image.fill(random.choice((ORANGE, YELLOW, RED)))
        self.rect = self.image.get_rect(center=center)
        self.pos = pygame.Vector2(center)
        self.velocity = pygame.Vector2(random.uniform(40, 220), 0).rotate(
            random.uniform(0, 360)
        )
        self.life = random.uniform(0.25, 0.6)

    def update(self, dt):
        self.life -= dt
        if self.life <= 0:
            self.kill()
            return
        self.pos += self.velocity * dt
        self.rect.center = self.pos


class Starfield:
    """Three layers of scrolling stars; nearer ones are brighter and faster."""

    def __init__(self):
        self.stars = [
            [random.uniform(0, WIDTH), random.uniform(0, HEIGHT), random.choice((1, 2, 3))]
            for _ in range(90)
        ]

    def update(self, dt):
        for star in self.stars:
            star[1] += star[2] * 40 * dt
            if star[1] > HEIGHT:
                star[0] = random.uniform(0, WIDTH)
                star[1] = 0

    def draw(self, surface):
        for x, y, depth in self.stars:
            shade = 70 + depth * 55
            surface.fill((shade, shade, shade), (int(x), int(y), depth, depth))


class Game:
    def __init__(self):
        pygame.init()
        pygame.display.set_caption("Space Shooter")
        self.screen = pygame.display.set_mode((WIDTH, HEIGHT))
        self.clock = pygame.time.Clock()
        self.font = pygame.font.Font(None, 28)
        self.big_font = pygame.font.Font(None, 64)
        self.starfield = Starfield()
        self.high_score = 0
        self.state = "title"  # title, playing, paused or game_over
        self.reset()

    def reset(self):
        self.player = Player()
        self.bullets = pygame.sprite.Group()
        self.enemy_bullets = pygame.sprite.Group()
        self.enemies = pygame.sprite.Group()
        self.particles = pygame.sprite.Group()
        self.score = 0
        self.lives = PLAYER_LIVES
        self.spawn_timer = 1.0

    @property
    def level(self):
        return 1 + self.score // 200

    def run(self):
        while True:
            dt = min(self.clock.tick(FPS) / 1000, 0.05)
            self.handle_events()
            self.starfield.update(dt)
            if self.state == "playing":
                self.update(dt)
            elif self.state == "game_over":
                self.particles.update(dt)
            self.draw()

    def handle_events(self):
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                self.quit()
            if event.type != pygame.KEYDOWN:
                continue
            if event.key == pygame.K_ESCAPE:
                self.quit()
            elif self.state in ("title", "game_over") and event.key == pygame.K_RETURN:
                self.reset()
                self.state = "playing"
            elif event.key == pygame.K_p and self.state in ("playing", "paused"):
                self.state = "paused" if self.state == "playing" else "playing"

    def quit(self):
        pygame.quit()
        sys.exit()

    def update(self, dt):
        self.player.update(dt)
        self.bullets.update(dt)
        self.enemy_bullets.update(dt)
        self.enemies.update(dt)
        self.particles.update(dt)

        if pygame.key.get_pressed()[pygame.K_SPACE] and self.player.cooldown == 0:
            self.player.cooldown = FIRE_COOLDOWN
            self.bullets.add(
                Bullet(self.player.rect.centerx, self.player.rect.top, -BULLET_SPEED, CYAN)
            )

        self.spawn_timer -= dt
        if self.spawn_timer <= 0:
            self.enemies.add(Enemy(self.level))
            self.spawn_timer = max(0.3, 1.1 - self.level * 0.08) * random.uniform(0.7, 1.3)

        for enemy in self.enemies:
            if enemy.shoot_timer <= 0:
                enemy.shoot_timer = random.uniform(1.5, 4.0)
                if enemy.rect.bottom < self.player.rect.top:
                    self.enemy_bullets.add(
                        Bullet(enemy.rect.centerx, enemy.rect.bottom,
                               ENEMY_BULLET_SPEED, ORANGE)
                    )

        self.handle_collisions()

    def handle_collisions(self):
        hits = pygame.sprite.groupcollide(self.enemies, self.bullets, True, True)
        for enemy in hits:
            self.score += 10
            self.explode(enemy.rect.center)

        if self.player.invulnerable > 0:
            return
        hit_by_enemy = pygame.sprite.spritecollide(
            self.player, self.enemies, True, pygame.sprite.collide_mask
        )
        hit_by_bullet = pygame.sprite.spritecollide(
            self.player, self.enemy_bullets, True, pygame.sprite.collide_mask
        )
        if hit_by_enemy or hit_by_bullet:
            self.lives -= 1
            self.player.invulnerable = INVULNERABLE_TIME
            self.explode(self.player.rect.center)
            if self.lives <= 0:
                self.high_score = max(self.high_score, self.score)
                self.state = "game_over"

    def explode(self, center):
        self.particles.add(Particle(center) for _ in range(24))

    def draw_text(self, text, font, color, center):
        image = font.render(text, True, color)
        self.screen.blit(image, image.get_rect(center=center))

    def draw(self):
        self.screen.fill(BLACK)
        self.starfield.draw(self.screen)

        if self.state == "title":
            self.draw_text("SPACE SHOOTER", self.big_font, CYAN, (WIDTH / 2, HEIGHT / 3))
            self.draw_text("Move: arrows / WASD", self.font, WHITE, (WIDTH / 2, HEIGHT / 2))
            self.draw_text("Shoot: Space    Pause: P", self.font, WHITE,
                           (WIDTH / 2, HEIGHT / 2 + 30))
            self.draw_text("Press Enter to start", self.font, GREEN,
                           (WIDTH / 2, HEIGHT / 2 + 90))
        else:
            self.enemies.draw(self.screen)
            self.bullets.draw(self.screen)
            self.enemy_bullets.draw(self.screen)
            self.particles.draw(self.screen)
            if self.state != "game_over":
                self.screen.blit(self.player.image, self.player.rect)
            self.draw_hud()

        if self.state == "paused":
            self.draw_text("PAUSED", self.big_font, WHITE, (WIDTH / 2, HEIGHT / 2))
        elif self.state == "game_over":
            self.draw_text("GAME OVER", self.big_font, RED, (WIDTH / 2, HEIGHT / 3))
            self.draw_text(f"Score: {self.score}", self.font, WHITE, (WIDTH / 2, HEIGHT / 2))
            self.draw_text(f"Best: {self.high_score}", self.font, WHITE,
                           (WIDTH / 2, HEIGHT / 2 + 30))
            self.draw_text("Press Enter to play again", self.font, GREEN,
                           (WIDTH / 2, HEIGHT / 2 + 90))

        pygame.display.flip()

    def draw_hud(self):
        self.screen.blit(self.font.render(f"Score: {self.score}", True, WHITE), (10, 10))
        level = self.font.render(f"Level {self.level}", True, YELLOW)
        self.screen.blit(level, level.get_rect(midtop=(WIDTH / 2, 10)))
        lives = self.font.render(f"Lives: {max(self.lives, 0)}", True, GREEN)
        self.screen.blit(lives, lives.get_rect(topright=(WIDTH - 10, 10)))


if __name__ == "__main__":
    Game().run()
