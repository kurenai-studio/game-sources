import sys
import webbrowser

import pygame

from .configs import Color, Configs, Font


def set_cursor(cursor):
    # The cursor is cosmetic; some video drivers can't create system cursors
    try:
        pygame.mouse.set_cursor(cursor)
    except pygame.error:
        pass


#####################
### Splash screen ###
#####################
def show_splash_screen(score=None):
    text_data = [
        # Format (name, font_settings, color, y_position)
        ("Coatl.", Font.HEADER, Color.PRIMARY, 100),
        ("A game by", Font.SUBHEADER, Color.SECONDARY, 170),
        ("Lando Icaza C.", Font.SUBHEADER, Color.SECONDARY, 190),
    ]
    if score is None:
        prompt = "Press any key to start"
    else:
        text_data.append((f"Game over! Score: {score}", Font.GAME, Color.PRIMARY, 350))
        prompt = "Press any key to play again"
    text_data.append((prompt, Font.GAME, Color.SECONDARY, 500))

    # Render text once, horizontally centered
    center_x = Configs.screen.get_width() // 2
    rendered = []
    for text, font, color, y in text_data:
        surf = font.render(text, True, color)
        rendered.append((surf, surf.get_rect(midtop=(center_x, y))))

    # Portfolio link, shown without the scheme; highlighted and underlined on hover
    link_text = Configs.portfolio_url.removeprefix("https://")
    link_surf = Font.SUBHEADER.render(link_text, True, Color.PRIMARY)
    link_hover_surf = Font.SUBHEADER.render(link_text, True, Color.SECONDARY)
    link_rect = link_surf.get_rect(midtop=(center_x, 215))

    # Drop keys pressed before the splash appeared so they don't dismiss it instantly
    pygame.event.clear(pygame.KEYDOWN)

    hovering = False
    waiting = True
    while waiting:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()
            # Any key press exits this loop and starts the game
            if event.type == pygame.KEYDOWN:
                waiting = False
            # Clicking the link opens it in the browser without starting the game
            if (
                event.type == pygame.MOUSEBUTTONDOWN
                and event.button == 1
                and link_rect.collidepoint(event.pos)
            ):
                webbrowser.open(Configs.portfolio_url)

        was_hovering = hovering
        hovering = link_rect.collidepoint(pygame.mouse.get_pos())
        if hovering != was_hovering:
            set_cursor(
                pygame.SYSTEM_CURSOR_HAND if hovering else pygame.SYSTEM_CURSOR_ARROW
            )

        Configs.screen.fill(Color.BACKGROUND)
        for surf, rect in rendered:
            Configs.screen.blit(surf, rect)

        if hovering:
            Configs.screen.blit(link_hover_surf, link_rect)
            underline_y = link_rect.bottom - 1
            pygame.draw.line(
                Configs.screen,
                Color.SECONDARY,
                (link_rect.left, underline_y),
                (link_rect.right - 1, underline_y),
            )
        else:
            Configs.screen.blit(link_surf, link_rect)

        pygame.display.flip()
        Configs.clock.tick(60)

    # Restore the default cursor if the game starts while hovering the link
    if hovering:
        set_cursor(pygame.SYSTEM_CURSOR_ARROW)
