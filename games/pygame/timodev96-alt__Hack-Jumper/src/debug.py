#debug.py
import pygame
import constans

import camera

pygame.font.init()
font = pygame.font.SysFont("Arial", 24)

starting_camera_y = 280

def draw_debugger(surface, camera_y):
    if constans.DEBUG_MODE == True:
        text_surf = font.render(f"Y: {int(camera_y)}",True, (255,255,255))
        surface.blit(text_surf, (10,10))

def handel_debug_input(camera):
    if constans.DEBUG_MODE == True:
        keys = pygame.key.get_pressed()

def draw_debug_info(surface,camera):
    if constans.DEBUG_MODE == True:
        height = starting_camera_y - camera.y
        debug_text = f"Y:{int(height)}"
        text_surface = font.render(debug_text,True,(255,255,255))
        surface.blit(text_surface, (10,10))