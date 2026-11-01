#player.py
import pygame
import terrain
import constans

class Player:
      def __init__(self):
            self.ongraoung = True
            self.gravity = 0.5
            self.velocity_x = 0
            self.velocity_y = 0
            self.x = 50.0
            self.y = 630.0

            self.accel = 0.35
            self.friction = 0.97
            self.bounce = 0.65
            self.max_speed = 12.0

            self.speed_jump_factor = 1.2
            self.base_jump = -9

            self.highest_y = self.y
            self.score = 0
            self.player_rect = pygame.Rect(self.x,self.y,50,50)

      def moves(self , terrain):
            self.keys = pygame.key.get_pressed()
            
            moving = False
            if self.keys[pygame.K_RIGHT] or self.keys[pygame.K_d]:
                  self.velocity_x += self.accel
                  moving = True
            if self.keys[pygame.K_LEFT] or self.keys[pygame.K_a]:
                  self.velocity_x -= self.accel
                  moving = True

            if not moving:
                  self.velocity_x *= self.friction
                  if abs(self.velocity_x) < 0.05:
                        self.velocity_x =0

            self.velocity_x = max(-self.max_speed, min(self.velocity_x, self.max_speed))
            self.x += self.velocity_x

            if self.x < constans.WALLS_WIDTH:
                  self.x = constans.WALLS_WIDTH
                  self.velocity_x = -self.velocity_x * self.bounce
            elif self.x + self.player_rect.width > constans.SCREEN_WIDTH - constans.WALLS_WIDTH:
                  self.x = constans.SCREEN_WIDTH - constans.WALLS_WIDTH - self.player_rect.width
                  self.velocity_x = -self.velocity_x *self.bounce 

            self.velocity_y += self.gravity
            if self.velocity_y > 15:
                  self.velocity_y = 15

            prev_bottom = self.y + self.player_rect.height
            self.y += self.velocity_y
            self.player_rect.x = int(self.x)
            self.player_rect.y = int(self.y)
            
            self.ongraoung = False

            if self.velocity_y >= 0:
                  for plat in terrain.platforms:
                        if self.player_rect.right > plat.left and self.player_rect.left < plat.right:
                              if prev_bottom <= plat.top and self.player_rect.bottom >= plat.top:
                                    self.y = plat.top - self.player_rect.height
                                    self.player_rect.y = int(self.y)
                                    self.velocity_y = 0
                                    self.ongraoung = True
                                    break
                  
            if self.keys[pygame.K_SPACE] or self.keys[pygame.K_UP] or self.keys[pygame.K_w]:
                  if self.ongraoung == True:
                        speed_boost = abs(self.velocity_x) * self.speed_jump_factor
                        self.velocity_y = self.base_jump - speed_boost
                        self.ongraoung = False

            if self.y < self.highest_y:
                  self.highest_y = self.y
            self.score = max(0, int((630-self.highest_y)//10))

            self.is_dead = self.y > self.highest_y + 600

      def draw(self,page,camera):
            pygame.draw.rect(page,(255,0,0),camera.apply(self.player_rect))

