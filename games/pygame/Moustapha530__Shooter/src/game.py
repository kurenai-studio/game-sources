import pygame
from player import Player
from monster import Monster
from comet_event import CometFallEvent

class Game:
    def __init__(self):
        self.is_playing = False
        self.player = Player(self)
        self.all_players = pygame.sprite.Group()
        self.all_players.add(self.player)
        self.pressed = {}
        self.all_monsters = pygame.sprite.Group()
        self.comet_event = CometFallEvent(self)
        self.spawn_monster()

    def game_over(self):
        self.all_monsters = pygame.sprite.Group()
        self.player.health = self.player.max_health
        self.is_playing = False
        self.comet_event.all_comets = pygame.sprite.Group()
        self.comet_event.reset_percent()

    def start(self):
        self.is_playing = True
        self.spawn_monster()
        self.spawn_monster()


    def update(self, screen):
        screen.blit(self.player.image, self.player.rect)

        self.player.all_projectiles.draw(screen)
        self.all_monsters.draw(screen)
        self.comet_event.all_comets.draw(screen)

        self.player.update_health_bar(screen)
        self.comet_event.update_bar(screen)

        for projectile in self.player.all_projectiles:
            projectile.move()

        for monster in self.all_monsters:
            monster.forward()
            monster.update_health_bar(screen)

        for comet in self.comet_event.all_comets:
            comet.fall()

        if self.pressed.get(pygame.K_RIGHT):
            self.player.move_right()

        elif self.pressed.get(pygame.K_LEFT):
            self.player.move_left()

    def spawn_monster(self):
        monster = Monster(self)
        self.all_monsters.add(monster)

    def check_collision(self, sprite, group):
        return pygame.sprite.spritecollide(sprite, group, False, pygame.sprite.collide_mask)
