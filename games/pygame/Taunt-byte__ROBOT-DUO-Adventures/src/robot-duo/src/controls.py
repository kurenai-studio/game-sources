"""Keyboard bindings. Kept apart from settings.py because it needs pygame key constants."""
import pygame

# Per-robot movement keys
BINDINGS = {
    "x": {"left": pygame.K_a, "right": pygame.K_d, "jump": pygame.K_w},
    "b": {"left": pygame.K_LEFT, "right": pygame.K_RIGHT, "jump": pygame.K_UP},
}
KEY_SWITCH = pygame.K_TAB
KEY_SELECT = {pygame.K_1: 0, pygame.K_2: 1}
KEY_RESTART = pygame.K_r
KEY_PAUSE = pygame.K_ESCAPE
KEY_CONFIRM = (pygame.K_RETURN, pygame.K_KP_ENTER)
