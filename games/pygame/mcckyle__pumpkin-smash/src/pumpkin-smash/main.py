##########################################################################################
##Filename: main.py
##Author: Kyle McColgan
##Date: 31 October 2026
##Description: This file contains the main game file for the pumpkin smash game.
##########################################################################################

import math
import random
import sys

import pygame

##########################################################################################

SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600
FPS = 60

INITIAL_PUMPKIN_SPEED = 5.0
SPEED_INCREMENT = 0.1
SECOND_PUMPKIN_SCORE = 20
THIRD_PUMPKIN_SCORE = 30

GHOST_SPEED = 4.0
GHOST_SIZE = (100, 120)
GHOST_FLOAT_AMPLITUDE = 45
GHOST_FLOAT_FREQUENCY = 0.0025

PUMPKIN_BOB_AMPLITUDE = 4
PUMPKIN_BOB_FREQUENCY = 0.004

GHOST_BOB_AMPLITUDE = 5
GHOST_BOB_FREQUENCY = 0.004

MESSAGE_DURATION = 900
MESSAGE_FADE_DURATION = 300

EXPLOSION_FRAME_DURATION = 90
EXPLOSION_DURATION = 180

SKY_TOP = (45, 68, 92)
SKY_BOTTOM = (218, 126, 66)

GROUND_TOP = (55, 67, 47)
GROUND_BOTTOM = (28, 37, 29)

WHITE = (255, 255, 255)
MUTED_WHITE = (232, 235, 231)
SHADOW = (12, 16, 14)
DANGER = (255, 104, 91)
HUD_BACKGROUND = (16, 23, 27, 175)
GAME_OVER_BACKGROUND = (10, 14, 17, 190)

GROUND_Y = SCREEN_HEIGHT // 2
HORIZON_HEIGHT = 90

#Speeds are expressed in pixels per frame at 60 FPS.
#Covert them to pixels per second during gameplay.
INITIAL_PUMPKIN_SPEED *= FPS
SPEED_INCREMENT *= FPS
GHOST_SPEED *= FPS

##########################################################################################

def quit_game():
    """Shut down Pygame and exit the application."""
    pygame.quit()
    sys.exit()

def spawn_entity(image):
    """Create an entity rectangle above the screen."""
    rect = image.get_rect()

    rect.x = random.randint(0, SCREEN_WIDTH - rect.width)
    rect.y = random.randint(-rect.height * 2, -10)

    return rect

def reset_entity(rect):
    """Reposition an existing entity above the screen."""
    rect.x = random.randint(0, SCREEN_WIDTH - rect.width)
    rect.y = random.randint(-rect.height * 2, -rect.height)

def create_gradient(size, top_color, bottom_color):
    """Create a reusable vertical gradient."""
    width, height = size
    surface = pygame.Surface(size)

    for y in range(height):
        blend = y / max(1, height - 1)
        color = tuple(round(top_color[channel] * (1 - blend) + bottom_color[channel] * blend) for channel in range(3))
        pygame.draw.line(surface, color, (0, y), (width, y))

    return surface

def create_horizon():
    """Create a reusable translucent horizon glow."""
    surface = pygame.Surface((SCREEN_WIDTH, HORIZON_HEIGHT), pygame.SRCALPHA)

    for y in range(HORIZON_HEIGHT):
        alpha = round(38 * (1 - y / HORIZON_HEIGHT))

        pygame.draw.line(surface, (255, 188, 102, alpha), (0, y), (SCREEN_WIDTH, y))

    return surface

def create_ellipse_surface(size, color):
    """Create a reusable translucent ellipse."""
    surface = pygame.Surface(size, pygame.SRCALPHA)
    pygame.draw.ellipse(surface, color, surface.get_rect())

    return surface

def render_text_with_shadow(surface, font, text, position, color=WHITE, shadow_color=SHADOW, shadow_offset=(2,2), alpha=255):
    """Render readable text with a subtle shadow."""
    shadow = font.render(text, True, shadow_color)
    foreground = font.render(text, True, color)

    shadow.set_alpha(max(0, alpha - 40))
    foreground.set_alpha(alpha)

    surface.blit(shadow, (position[0] + shadow_offset[0], position[1] + shadow_offset[1]))
    surface.blit(foreground, position)

def get_pumpkin_rect(rect, position_y, current_time):
    """Calculate the visible pumpkin position."""
    bob = round(math.sin((current_time + rect.x * 8) * PUMPKIN_BOB_FREQUENCY) * PUMPKIN_BOB_AMPLITUDE)
    return rect.copy().move(0, round(position_y) + bob - rect.y)

def get_ghost_rect(rect, position_y, current_time):
    """Calculate the visible ghost position."""
    bob = round(math.sin(current_time * PUMPKIN_BOB_FREQUENCY) * GHOST_BOB_AMPLITUDE)
    return rect.copy().move(0, round(position_y) + bob - rect.y)

def main():
    #Initalize Pygame.
    pygame.init()
    screen = pygame.display.set_mode((SCREEN_WIDTH, SCREEN_HEIGHT))
    #pygame.display.set_caption("🎃 Pumpkin Smash")
    clock = pygame.time.Clock()

    #Load assets.
    try:
        pumpkin_img = pygame.image.load("pumpkin-03.png").convert_alpha()
        explosion_imgs = [pygame.image.load(f"explosion-{index}.png").convert_alpha() for index in range (1,3)]
        ghost_img = pygame.image.load("ghost.webp").convert_alpha()
        ghost_img = pygame.transform.scale(ghost_img, GHOST_SIZE)
    except (pygame.error, OSError) as error:
        print(f"Error loading game assets: {error}", file=sys.stderr)
        quit_game()

    #Fonts.
    score_font = pygame.font.Font(None, 42)
    message_font = pygame.font.Font(None, 48)
    game_over_font = pygame.font.Font(None, 48)
    subtitle_font = pygame.font.Font(None, 30)

    #Pre-rendered scenery.
    background = create_gradient((SCREEN_WIDTH, SCREEN_HEIGHT), SKY_TOP, SKY_BOTTOM)
    ground = create_gradient((SCREEN_WIDTH, SCREEN_HEIGHT - GROUND_Y), GROUND_TOP, GROUND_BOTTOM)
    horizon = create_horizon()

    #Pre-rendered visual elements.
    pumpkin_shadow = create_ellipse_surface((max(20, round(pumpkin_img.get_width() * 0.55)), max(8, round(pumpkin_img.get_height() * 0.12))), (0, 0, 0, 85))
    hud_panel = pygame.Surface((190, 60), pygame.SRCALPHA)
    pygame.draw.rect(hud_panel, HUD_BACKGROUND, hud_panel.get_rect(), border_radius=12)
    game_over_overlay = pygame.Surface((SCREEN_WIDTH, SCREEN_HEIGHT), pygame.SRCALPHA)
    game_over_overlay.fill(GAME_OVER_BACKGROUND)

    #Game State.
    score = 0
    pumpkin_speed = INITIAL_PUMPKIN_SPEED
    pumpkins = [spawn_entity(pumpkin_img)]
    pumpkin_positions = [float(pumpkins[0].y)]
    explosions = []

    ghost_rect = spawn_entity(ghost_img)
    ghost_position_y = float(ghost_rect.y)
    ghost_base_x = ghost_rect.x

    game_over = False
    message_text = None
    message_color = WHITE
    message_elapsed = 0

    running = True
    #Main game loop.
    while running:
        delta_ms = min(clock.tick(FPS), 100)
        delta_seconds = delta_ms / 1000
        current_time = pygame.time.get_ticks()

        #Events...
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
                break

            if (event.type == pygame.MOUSEBUTTONDOWN and event.button == 1 and not game_over):
                """The ghost always takes collision priority."""
                ghost_draw_rect = get_ghost_rect(ghost_rect, ghost_position_y, current_time)

                if ghost_draw_rect.collidepoint(event.pos):
                    game_over = True
                    message_text = "👻 You clicked the ghost! Game over!"
                    message_color = DANGER
                    message_elapsed = 0
                    continue

                #Check visible pumpkin positions.
                for index, pumpkin_rect in enumerate(pumpkins):
                    pumpkin_draw_rect = get_pumpkin_rect(pumpkin_rect, pumpkin_positions[index], current_time)

                    if not pumpkin_draw_rect.collidepoint(event.pos):
                        continue

                    score += 1

                    explosions.append({"rect": pumpkin_draw_rect.copy(), "started_at": current_time})
                    reset_entity(pumpkin_rect)
                    pumpkin_positions[index] = float(pumpkin_rect.y)
                    pumpkin_speed += SPEED_INCREMENT

                    message_text = "Nice!"
                    message_color = WHITE
                    message_elapsed = 0

                    break

        if not running:
            break

        #Update gameplay.
        if not game_over:
            """Determine the number of active pumpkins."""
            if score >= THIRD_PUMPKIN_SCORE:
                target_pumpkins = 3
            elif score >= SECOND_PUMPKIN_SCORE:
                target_pumpkins = 2
            else:
                target_pumpkins = 1

            while len(pumpkins) < target_pumpkins:
                pumpkin_rect = spawn_entity(pumpkin_img)
                pumpkins.append(pumpkin_rect)
                pumpkin_positions.append(float(pumpkin_rect.y))

            #Update pumpkin movement.
            for index, pumpkin_rect in enumerate(pumpkins):
                pumpkin_positions[index] += (pumpkin_speed * delta_seconds)
                pumpkin_rect.y += round(pumpkin_positions[index])

                if pumpkin_rect.top > SCREEN_HEIGHT:
                    reset_entity(pumpkin_rect)
                    pumpkin_positions[index] = float(pumpkin_rect.y)
                    pumpkin_speed += SPEED_INCREMENT
                    #score = 0

                    message_text = "Miss!"
                    message_color = DANGER
                    message_elapsed = 0

            """Update ghost movement."""
            ghost_position_y += (GHOST_SPEED * delta_seconds)
            ghost_rect.y += round(ghost_position_y)
            ghost_rect.x = round(ghost_base_x + math.sin(current_time * GHOST_FLOAT_FREQUENCY) * GHOST_FLOAT_AMPLITUDE)
            ghost_rect.x = max(0, min(SCREEN_WIDTH - ghost_rect.width, ghost_rect.x))

            """Respawn the ghost after it leaves the screen."""
            if ghost_rect.top > SCREEN_HEIGHT:
                ghost_rect = spawn_entity(ghost_img)
                ghost_position_y = float(ghost_rect.y)
                ghost_base_x = ghost_rect.x

        """Render scenery."""
        screen.blit(background, (0, 0))
        screen.blit(ground, (0, GROUND_Y))
        screen.blit(horizon, (0, GROUND_Y - HORIZON_HEIGHT // 2))

        #Render the pumpkins...
        for index, pumpkin_rect in enumerate(pumpkins):
            draw_rect = get_pumpkin_rect(pumpkin_rect, pumpkin_positions[index], current_time)

            #Ground shadow.
            if draw_rect.bottom > GROUND_Y:
                shadow_rect = pumpkin_shadow.get_rect(center=(draw_rect.centerx, GROUND_Y))
                screen.blit(pumpkin_shadow, shadow_rect)

            screen.blit(pumpkin_img, draw_rect)

        #Render the ghost.
        if not game_over:
            ghost_alpha = 190 + round(25 * math.sin(current_time * 0.003))
            ghost_draw_rect = get_ghost_rect(ghost_rect, ghost_position_y, current_time)
            ghost_img.set_alpha(ghost_alpha)
            screen.blit(ghost_img, ghost_draw_rect)
            ghost_img.set_alpha(None)

        #Render explosions.
        active_explostions = []

        for explosion in explosions:
            elapsed = (current_time - explosion["started_at"])
            if elapsed >= EXPLOSION_DURATION:
                continue
            frame = min(elapsed // EXPLOSION_FRAME_DURATION, len(explosion_imgs) - 1)
            alpha = round(255 * (1 - elapsed / EXPLOSION_DURATION))
            image = explosion_imgs[frame]
            image.set_alpha(alpha)
            screen.blit(image, explosion["rect"])

        explosions = active_explostions

        #Render the score.
        score_surface = score_font.render(f"SCORE {score:02d}", True, WHITE)
        screen.blit(hud_panel, (16, 16))
        screen.blit(score_surface, (32, 25))

        #Render temporary messages...
        if message_text is not None:
            message_elapsed += delta_ms

            if message_elapsed >= MESSAGE_DURATION:
                message_text = None
            else:
                fade_start = (MESSAGE_DURATION - MESSAGE_FADE_DURATION)

                if message_elapsed > fade_start:
                    alpha = round(255 * (MESSAGE_DURATION - message_elapsed) / MESSAGE_FADE_DURATION)
                else:
                    alpha = 255

                message_surface = message_font.render(message_text, True, message_color)
                message_x = (SCREEN_WIDTH - message_surface.get_width()) // 2
                render_text_with_shadow(screen, message_font, message_text, (message_x, 120), color=message_color, alpha=alpha)

        #Render game-over overlay...
        if game_over:
            screen.blit(game_over_overlay, (0, 0))
            title = game_over_font.render("👻 Game Over!", True, WHITE)
            subtitle = subtitle_font.render(f"Final score {score:02d}", True, MUTED_WHITE)
            instruction = subtitle_font.render("Close the window to exit", True, (190, 198, 194))
            screen.blit(title, title.get_rect(center=(SCREEN_WIDTH // 2, SCREEN_HEIGHT // 2 - 50)))
            screen.blit(subtitle, subtitle.get_rect(center=(SCREEN_WIDTH // 2, SCREEN_HEIGHT // 2 + 5)))
            screen.blit(instruction, instruction.get_rect(center=(SCREEN_WIDTH // 2, SCREEN_HEIGHT // 2 + 42)))

        #Update the display...
        pygame.display.flip()

    quit_game()

if __name__ == "__main__":
    main()