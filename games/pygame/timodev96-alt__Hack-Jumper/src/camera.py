#camera.py
import pygame

class Camera:
    def __init__(self):
        self.y = 0

    def apply(self,rect):
        return rect.move(0, -self.y)

    def follow(self, target_y , offset):
        upper_dead_zone = offset - 80
        lower_dead_zone = offset + 80
        player_screen_y = target_y - self.y
        if player_screen_y < upper_dead_zone:
            self.y = target_y - upper_dead_zone
        elif player_screen_y > lower_dead_zone:
            self.y = target_y - lower_dead_zone