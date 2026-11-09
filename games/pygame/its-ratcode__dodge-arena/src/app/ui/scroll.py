"""A scrolling viewport: content taller than its box, moved with wheel, keys or scrollbar."""

import pygame

from app.theme.accessibility import A11Y
from app.theme.palette import PALETTE
from app.util.mathx import clamp, lerp_color

WHEEL_STEP = 60         # px per wheel notch
SCROLL_EASE = 14.0      # how fast the view glides to its target (higher = snappier)
BAR_WIDTH = 8
BAR_MARGIN = 6
MIN_THUMB = 36          # px; the thumb never gets too small to grab


class ScrollView:
    """Keeps ``offset`` (how far the content is scrolled, in px) between 0 and ``max_offset``.

    Scrolling sets a *target*; ``update`` glides ``offset`` toward it, so the
    wheel feels smooth. Content is drawn by the owner at ``y - offset`` with
    the surface clipped to ``rect``.

    Mouse: wheel scrolls, dragging the thumb scrolls, clicking the track jumps
    a page. Keys: Page Up / Page Down, Home / End.
    """

    def __init__(self, rect: pygame.Rect, content_height: int = 0) -> None:
        self.rect = pygame.Rect(rect)
        self.content_height = content_height
        self.offset = 0.0
        self.target = 0.0
        self.drag_from: tuple[float, float] | None = None     # (mouse y, offset) when a drag started

    @property
    def max_offset(self) -> float:
        return max(0.0, self.content_height - self.rect.height)

    @property
    def scrollable(self) -> bool:
        return self.max_offset > 0

    def scroll_to(self, y: float, instant: bool = False) -> None:
        self.target = clamp(y, 0.0, self.max_offset)
        if instant:
            self.offset = self.target

    def scroll_by(self, dy: float) -> None:
        self.scroll_to(self.target + dy)

    # --- Scrollbar geometry -----------------------------------------------------------------
    @property
    def track(self) -> pygame.Rect:
        return pygame.Rect(self.rect.right - BAR_WIDTH - BAR_MARGIN, self.rect.y + BAR_MARGIN,
                           BAR_WIDTH, self.rect.height - BAR_MARGIN * 2)

    @property
    def thumb(self) -> pygame.Rect:
        track = self.track
        visible = self.rect.height / max(1, self.content_height)
        height = max(MIN_THUMB, round(track.height * min(1.0, visible)))
        travel = track.height - height
        y = track.y + (round(travel * self.offset / self.max_offset) if self.scrollable else 0)
        return pygame.Rect(track.x, y, BAR_WIDTH, height)

    # --- Input --------------------------------------------------------------------------------
    def handle_event(self, event: pygame.event.Event) -> bool:
        """Returns True if the event was used."""
        if not self.scrollable:
            return False
        if event.type == pygame.MOUSEWHEEL:
            self.scroll_by(-event.y * WHEEL_STEP)
            return True
        if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            if self.thumb.collidepoint(event.pos):
                self.drag_from = (event.pos[1], self.offset)
                return True
            if self.track.inflate(8, 0).collidepoint(event.pos):     # click the track: one page that way
                page = self.rect.height * 0.9
                self.scroll_by(-page if event.pos[1] < self.thumb.y else page)
                return True
        elif event.type == pygame.MOUSEBUTTONUP and event.button == 1 and self.drag_from:
            self.drag_from = None
            return True
        elif event.type == pygame.MOUSEMOTION and self.drag_from:
            start_y, start_offset = self.drag_from
            travel = self.track.height - self.thumb.height
            if travel > 0:
                # Moving the thumb by its whole travel scrolls the whole content.
                self.scroll_to(start_offset + (event.pos[1] - start_y) * self.max_offset / travel, instant=True)
            return True
        elif event.type == pygame.KEYDOWN:
            page = self.rect.height * 0.9
            moves = {pygame.K_PAGEDOWN: page, pygame.K_PAGEUP: -page}
            if event.key in moves:
                self.scroll_by(moves[event.key])
                return True
            if event.key == pygame.K_HOME:
                self.scroll_to(0)
                return True
            if event.key == pygame.K_END:
                self.scroll_to(self.max_offset)
                return True
        return False

    def update(self, dt: float) -> None:
        self.offset += (self.target - self.offset) * min(1.0, dt * SCROLL_EASE)
        if abs(self.target - self.offset) < 0.5 or A11Y.reduced_motion:     # jump instead of gliding
            self.offset = self.target

    def draw_scrollbar(self, surface: pygame.Surface) -> None:
        if not self.scrollable:
            return
        pygame.draw.rect(surface, PALETTE.track, self.track, border_radius=BAR_WIDTH // 2)
        hot = self.drag_from is not None or self.thumb.collidepoint(pygame.mouse.get_pos())
        color = lerp_color(PALETTE.text_faint, PALETTE.text, 0.6 if hot else 0.0)
        pygame.draw.rect(surface, color, self.thumb, border_radius=BAR_WIDTH // 2)
