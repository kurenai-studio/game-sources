import pygame
from settings import *
from game_field import GameField

pygame.init()
screen = pygame.display.set_mode((SCREEN_WIDTH, SCREEN_HEIGHT))
playfield = GameField()

last_x_index = len(playfield.map[0]) - 1
last_y_index = len(playfield.map) - 1

s_a = []
s_b = []

# Incres diaf
# Move diagonal to the right
for k in range(len(playfield.map[0])):
    s = ''
    for i in range(len(playfield.map)):
        x = i + k
        y = i
        if 0 <= x <= last_x_index and 0 <= y <= last_y_index:
            s += str(playfield.map[-y][x])
    if '11111' in s or '22222' in s:
        pass
    s_a.append(s)

# Move diagonal up
for k in range(1, len(playfield.map)):
    s = ''
    for i in range(len(playfield.map)):
        x = i
        y = i + k
        if 0 <= x <= last_x_index and 0 <= y <= last_y_index:
            s += str(playfield.map[-y][x])
    if '11111' in s or '22222' in s:
        pass
    s_a.append(s)

# Deced diag
# Move diagonal to the right
for k in range(len(playfield.map[0])):
    s = ''
    for i in range(len(playfield.map)):
        x = i + k
        y = i
        if 0 <= x <= last_x_index and 0 <= y <= last_y_index:
            s += str(playfield.map[y][x])
    if '11111' in s or '22222' in s:
        pass
    s_b.append(s)

# Move diagonal down
for k in range(1, len(playfield.map)):
    s = ''
    for i in range(len(playfield.map)):
        x = i
        y = i + k
        if 0 <= x <= last_x_index and 0 <= y <= last_y_index:
            s += str(playfield.map[y][x])
    if '11111' in s or '22222' in s:
        pass
    s_b.append(s)



print(s_a)
print(s_b)