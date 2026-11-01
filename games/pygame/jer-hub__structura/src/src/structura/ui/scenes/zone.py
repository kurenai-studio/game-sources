"""A Zone's page: its Lesson and its Puzzles, unlocked in order.

The Lesson comes first, then the Puzzles in unlock order, poured down a column
and on into the next when it is full, so the path reads top to bottom, left to
right. A Stage heading sits where each Stage starts. Two wide columns are used
when the cards fit, otherwise three narrower ones. Each card shows its number
in that order, its Stage and Puzzle Type, whether it is done or locked, and its
Stars; the card to play next is marked. Text too long for a card is shortened.
"""
from __future__ import annotations

from dataclasses import dataclass

import pygame

from ...persistence import progress
from .. import theme
from ..app import SIZE, Scene
from ..fx import mix
from ..widgets import Button

CARD_H = 62
CARD_GAP = 12
HEADING_H = 34
TOP = 178
MARGIN = 40
MAP_BUTTON = pygame.Rect(MARGIN, SIZE[1] - 72, 160, 44)
BOTTOM = MAP_BUTTON.top - CARD_GAP
COLUMN_GAPS = {2: 80, 3: 32}                 # columns -> gap between them
TEXT_X = 66                                  # card text starts right of the badge
BADGE_ROW = 45                               # stars, NEXT or the lock: beside the subtitle
LOCK_W = 44                                  # room the lock takes at the card's right
STARS_W = 92                                 # room the Stars take at the card's right


def _fit(text: str, font: pygame.font.Font, width: float) -> str:
    """`text`, shortened with "…" if it is wider than `width`."""
    if font.size(text)[0] <= width:
        return text
    while text and font.size(text + "…")[0] > width:
        text = text[:-1]
    return text.rstrip() + "…"


@dataclass
class ZoneCard(Button):
    """A Lesson or Puzzle on the Zone page."""

    number: int = 0               # the Puzzle's place in unlock order; 0 for the Lesson
    subtitle: str = ""            # e.g. "Guided · Trace", shown under the title
    stars: int | None = None      # None until played
    next_up: bool = False
    boss: bool = False

    def _draw(self, surf):
        r, accent = self.rect, self.accent
        if not self.enabled:
            bg, edge = theme.PANEL, theme.PANEL_EDGE
        elif self.next_up:
            bg, edge = mix(theme.PANEL, accent, 0.28 if self.hover else 0.2), accent
        else:
            bg, edge = mix(theme.PANEL, theme.PANEL_EDGE, 0.8 if self.hover else 0.4), mix(theme.PANEL_EDGE, accent, 0.5)
        if self.boss and self.enabled:
            edge = theme.BAD
        pygame.draw.rect(surf, bg, r, border_radius=10)
        pygame.draw.rect(surf, edge, r, 2 + self.next_up, border_radius=10)

        # The badge: a check once played, else the number (dimmed while locked).
        c = (r.x + 34, r.centery)
        if not self.enabled:
            pygame.draw.circle(surf, theme.PANEL_EDGE, c, 18)
            img = theme.font(18, bold=True).render(str(self.number), True, theme.DISABLED)
            surf.blit(img, img.get_rect(center=c))
        elif self.stars is not None:
            pygame.draw.circle(surf, theme.GOOD, c, 18)
            pygame.draw.lines(surf, theme.BG, False, [(c[0] - 8, c[1]), (c[0] - 2, c[1] + 6), (c[0] + 8, c[1] - 6)], 3)
        else:
            pygame.draw.circle(surf, accent if self.next_up else theme.PANEL_EDGE, c, 18)
            label = "i" if self.number == 0 else str(self.number)
            colour = theme.BG if self.next_up else theme.TEXT
            img = theme.font(18, bold=True).render(label, True, colour)
            surf.blit(img, img.get_rect(center=c))

        # The marker on the right of the subtitle row: NEXT, Stars, or a lock.
        row = r.y + BADGE_ROW
        if not self.enabled:
            _lock(surf, (r.right - 28, row), theme.MUTED)
        elif self.next_up:
            pill = self._pill()
            pygame.draw.rect(surf, accent, pill, border_radius=pill.h // 2)
            img = theme.font(15, bold=True).render("NEXT", True, theme.BG)
            surf.blit(img, img.get_rect(center=pill.center))
        elif self.stars is not None:
            theme.stars(surf, (r.right - 50, row), self.stars, size=16)

        title_colour = theme.TEXT if self.enabled else theme.DISABLED
        title_font = theme.font(21, bold=self.next_up)
        title = _fit(self.label, title_font, r.right - 12 - (r.x + TEXT_X))
        theme.draw_text(surf, title, (r.x + TEXT_X, r.y + 8), 21, title_colour, bold=self.next_up)
        sub_colour = (theme.BAD if self.boss else theme.MUTED) if self.enabled else theme.DISABLED
        theme.draw_text(surf, self.shown_subtitle(), (r.x + TEXT_X, r.y + 35), 15, sub_colour)

    def _pill(self) -> pygame.Rect:
        img = theme.font(15, bold=True).size("NEXT")
        return pygame.Rect((0, 0), img).inflate(16, 6).move_to(midright=(self.rect.right - 8, self.rect.y + BADGE_ROW))

    def shown_subtitle(self) -> str:
        """The subtitle as drawn: shortened to the room left of the marker."""
        r = self.rect
        if not self.enabled:
            marker_left = r.right - LOCK_W
        elif self.next_up:
            marker_left = self._pill().x - 8
        elif self.stars is not None:
            marker_left = r.right - STARS_W
        else:
            marker_left = r.right - 12
        return _fit(self.subtitle, theme.font(15), marker_left - (r.x + TEXT_X))


def _lock(surf, c, colour):
    body = pygame.Rect(0, 0, 14, 11)
    body.midtop = (c[0], c[1] - 2)
    pygame.draw.rect(surf, colour, body, border_radius=2)
    pygame.draw.arc(surf, colour, pygame.Rect(c[0] - 5, c[1] - 10, 10, 14), 0, 3.15, 2)


class ZoneScene(Scene):
    def __init__(self, app, zone):
        super().__init__(app)
        self.zone = zone
        self.results = results = app.results()
        self.next_up = self._next_up()
        self.headings: list[tuple[str, tuple[int, int]]] = []     # (Stage, where its heading goes)
        self.buttons = [Button("Zone Map", MAP_BUTTON.copy(), app.open_map)]

        blocks: list[tuple[str | None, list[ZoneCard]]] = []     # (Stage or None for the Lesson, its cards)
        if zone.lesson:
            blocks.append((None, [ZoneCard("Lesson", pygame.Rect(0, 0, 0, CARD_H), lambda: app.open_lesson(zone),
                                           accent=zone.color, subtitle="How it works",
                                           next_up=self.next_up is zone.lesson)]))
        for i, p in enumerate(zone.puzzles):
            r = results.get(p.id)
            unlocked = progress.puzzle_unlocked(zone, i, results)
            subtitle = f"{theme.STAGE_LABEL[p.stage]} · {p.type.title()}"
            if not unlocked:
                subtitle = f"Finish {zone.puzzles[i - 1].title} first  ·  {subtitle}"
            card = ZoneCard(
                p.title, pygame.Rect(0, 0, 0, CARD_H), lambda p=p: app.open_puzzle(zone, p),
                enabled=unlocked, accent=zone.color, number=i + 1, subtitle=subtitle,
                stars=r.stars if r else None, next_up=self.next_up is p, boss=p.stage == "boss")
            if blocks and blocks[-1][0] == p.stage:
                blocks[-1][1].append(card)
            else:
                blocks.append((p.stage, [card]))

        for n in COLUMN_GAPS:
            if self._pour(blocks, n) or n == max(COLUMN_GAPS):
                break
        self.buttons += [card for _, cards in blocks for card in cards]

    def _pour(self, blocks, n: int) -> bool:
        """Lay the cards down `n` columns; False if they run past the last one."""
        gap = COLUMN_GAPS[n]
        width = (SIZE[0] - 2 * MARGIN - (n - 1) * gap) // n
        self.headings = []
        col, y = 0, TOP
        for stage, cards in blocks:
            for k, card in enumerate(cards):
                need = CARD_H + (HEADING_H if k == 0 else 0)
                if y + need > BOTTOM and y > TOP:
                    col, y = col + 1, TOP
                x = MARGIN + col * (width + gap)
                if k == 0:
                    if stage:
                        self.headings.append((stage, (x, y)))
                    y += HEADING_H
                card.rect = pygame.Rect(x, y, width, CARD_H)
                y += CARD_H + CARD_GAP
            y += 8
        return col < n

    def _next_up(self):
        """The Lesson until a Puzzle is played, then the first unplayed Puzzle; None when cleared."""
        played = any(p.id in self.results for p in self.zone.puzzles)
        if not played and self.zone.lesson:
            return self.zone.lesson
        return next((p for p in self.zone.puzzles if p.id not in self.results), None)

    def draw(self, surf):
        z = self.zone
        theme.draw_text(surf, z.name, (40, 30), 40, z.color, bold=True)
        theme.draw_text(surf, z.intro, (40, 88), 19, theme.MUTED, width=SIZE[0] - 420)

        # Progress: Stars earned and Puzzles cleared, top right.
        got, total = progress.zone_stars(z, self.results)
        cleared = sum(p.id in self.results for p in z.puzzles)
        right = SIZE[0] - 40
        theme.star(surf, (right - 150, 56), 26, theme.STAR)
        theme.draw_text(surf, f"{got} / {total}", (right - 130, 42), 24, theme.TEXT, bold=True)
        bar = pygame.Rect(right - 300, 92, 300, 8)
        pygame.draw.rect(surf, theme.PANEL_EDGE, bar, border_radius=4)
        if cleared:
            pygame.draw.rect(surf, z.color, (bar.x, bar.y, bar.w * cleared / len(z.puzzles), bar.h), border_radius=4)
        theme.draw_text(surf, f"{cleared} of {len(z.puzzles)} Puzzles cleared", (right - 300, 106), 15, theme.MUTED)

        for stage, (x, y) in self.headings:
            colour = theme.BAD if stage == "boss" else theme.MUTED
            theme.draw_text(surf, theme.STAGE_LABEL[stage].upper(), (x + 2, y + 6), 15, colour, bold=True)
        super().draw(surf)
