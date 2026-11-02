"""Full-screen overlays shown before and between rounds."""

import math

import pygame

from duck_attack import settings
from duck_attack.highscores import HighScore
from duck_attack.hud import render_text


def _dim(screen: pygame.Surface) -> None:
    overlay = pygame.Surface(screen.get_size(), pygame.SRCALPHA)
    overlay.fill(settings.OVERLAY_COLOR)
    screen.blit(overlay, (0, 0))


class NameEntryScreen:
    """Asks for the player name before a round, prefilled with the last one."""

    def __init__(self) -> None:
        self.title_font = pygame.font.Font(None, 80)
        self.name_font = pygame.font.Font(None, 96)
        self.hint_font = pygame.font.Font(None, 36)

    def draw(self, screen: pygame.Surface, name: str, show_cursor: bool) -> None:
        _dim(screen)
        cx, cy = screen.get_width() // 2, screen.get_height() // 2
        title = render_text(self.title_font, "Your name")
        screen.blit(title, title.get_rect(center=(cx, cy - 120)))
        text = render_text(
            self.name_font, name + ("_" if show_cursor else " "), settings.HIGHLIGHT_COLOR
        )
        screen.blit(text, text.get_rect(center=(cx, cy)))
        hint = "Press Enter or click to start" if name.strip() else "Type your name"
        hint_text = render_text(self.hint_font, hint)
        screen.blit(hint_text, hint_text.get_rect(center=(cx, cy + 120)))


class RoundOverScreen:
    """Shows the final score of the round that just ended."""

    def __init__(self) -> None:
        self.title_font = pygame.font.Font(None, 96)
        self.score_font = pygame.font.Font(None, 140)
        self.hint_font = pygame.font.Font(None, 36)

    def draw(self, screen: pygame.Surface, score: int, seconds_left: float) -> None:
        _dim(screen)
        cx, cy = screen.get_width() // 2, screen.get_height() // 2
        title = render_text(self.title_font, "Round over!")
        screen.blit(title, title.get_rect(center=(cx, cy - 120)))
        value = render_text(self.score_font, f"{score} points", settings.HIGHLIGHT_COLOR)
        screen.blit(value, value.get_rect(center=(cx, cy + 10)))
        hint = render_text(self.hint_font, f"High scores in {math.ceil(seconds_left)} ...")
        screen.blit(hint, hint.get_rect(center=(cx, cy + 130)))


class HighScoreScreen:
    """Shows the high-score list, highlighting the round that was just played."""

    def __init__(self) -> None:
        self.title_font = pygame.font.Font(None, 80)
        self.row_font = pygame.font.Font(None, 44)
        self.hint_font = pygame.font.Font(None, 36)

    def draw(
        self,
        screen: pygame.Surface,
        entries: list[HighScore],
        highlight: int | None,
        last_score: int,
    ) -> None:
        _dim(screen)
        cx = screen.get_width() // 2
        title = render_text(self.title_font, "High Scores")
        screen.blit(title, title.get_rect(center=(cx, 70)))

        # Fixed columns so the list lines up even with a proportional font.
        rank_right, name_left, date_left, score_right = cx - 380, cx - 360, cx + 20, cx + 400
        name_width = date_left - name_left - 20
        top, row_height = 130, 46
        for i, entry in enumerate(entries):
            color = settings.HIGHLIGHT_COLOR if i == highlight else settings.TEXT_COLOR
            y = top + i * row_height
            rank = render_text(self.row_font, f"{i + 1}.", color)
            name = render_text(self.row_font, entry.name or "-", color)
            date = render_text(self.row_font, entry.timestamp.strftime("%Y-%m-%d  %H:%M"), color)
            points = render_text(self.row_font, str(entry.score), color)
            screen.blit(rank, rank.get_rect(topright=(rank_right, y)))
            # Clip long names so they don't run into the date column.
            screen.blit(name, (name_left, y), pygame.Rect(0, 0, name_width, name.get_height()))
            screen.blit(date, (date_left, y))
            screen.blit(points, points.get_rect(topright=(score_right, y)))

        bottom = screen.get_height()
        if highlight is None:
            note = render_text(self.hint_font, f"Your score: {last_score} (not in the top list)")
            screen.blit(note, note.get_rect(center=(cx, bottom - 90)))
        hint = render_text(self.hint_font, "Click to play again")
        screen.blit(hint, hint.get_rect(center=(cx, bottom - 45)))
