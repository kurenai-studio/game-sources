"""The in-game guide: every threat, skill, power-up and upgrade, in one scrolling page."""

import pygame

from app import config
from app.meta import APP_NAME
from app.render.shapes import draw_panel
from app.render.text import draw_hint_row, draw_text
from app.scenes.base import Scene, dim, draw_card
from app.theme.palette import PALETTE
from app.ui.document import Document
from app.ui.guide_content import build_guide
from app.ui.scroll import ScrollView
from app.ui.widgets import Button, ButtonGroup, SectionTab

CARD = pygame.Rect(24, 18, config.SCREEN_WIDTH - 48, config.SCREEN_HEIGHT - 36)
PAD = 24                # px inside the card
SIDEBAR_W = 200
TAB_H, TAB_STEP = 36, 40
PANEL_TOP = CARD.y + 92
FOOTER_H = 68           # px at the bottom of the card for the key hints and the Close button
TEXT_PAD = 24           # px between the panel edge and the text
BAR_SPACE = 20          # px kept free on the right for the scrollbar


class GuideScene(Scene):
    """A sidebar of sections and the guide document in a scroll view.

    The sidebar highlights the section you are reading (it follows the
    scrolling) and jumps to a section when chosen; Up / Down jump to the
    previous or next section. ``back`` is the scene to return to.
    """

    def __init__(self, game, back: Scene) -> None:
        super().__init__(game)
        self.back = back
        left = CARD.x + PAD
        panel_x = left + SIDEBAR_W + 16
        self.panel = pygame.Rect(panel_x, PANEL_TOP, CARD.right - PAD - panel_x, CARD.bottom - FOOTER_H - PANEL_TOP)
        self.view = self.panel.inflate(0, -8)
        sections = build_guide(game.settings, game.profile.levels)
        self.document = Document(sections, self.panel.width - TEXT_PAD * 2 - BAR_SPACE)

        # Extra room at the bottom so even the last section can scroll up to the top.
        last_section = self.document.height - self.document.anchors[-1]
        padding = max(TEXT_PAD, self.view.height - last_section - TEXT_PAD)
        self.scroll = ScrollView(self.view, self.document.height + TEXT_PAD + padding)

        self.section_tabs: list[SectionTab] = []
        for i, section in enumerate(sections):
            tab = SectionTab(section.title, self._jump(i), self._is_current(i), (SIDEBAR_W, TAB_H), section.icon)
            tab.rect.topleft = (left, PANEL_TOP + i * TAB_STEP)
            self.section_tabs.append(tab)
        self.close_button = Button("Close", self.go_back, hotkey="escape", primary=True, sound="back",
                                   size=(180, 44))
        self.close_button.rect.bottomright = (CARD.right - PAD, CARD.bottom - 16)
        self.group = ButtonGroup([*self.section_tabs, self.close_button])

    def _jump(self, index: int):
        def jump() -> None:
            self.scroll.scroll_to(self.document.anchors[index])
        return jump

    def _is_current(self, index: int):
        return lambda: self.current_section == index

    @property
    def current_section(self) -> int:
        """The last section whose heading has reached the top of the view."""
        current = 0
        for i, anchor in enumerate(self.document.anchors):
            if anchor <= self.scroll.offset + 4:
                current = i
        return current

    def go_back(self) -> None:
        self.game.scene = self.back

    # --- Scene -------------------------------------------------------------------------------------
    def handle_event(self, event: pygame.event.Event) -> None:
        if event.type == pygame.KEYDOWN and event.key in (pygame.K_UP, pygame.K_DOWN):
            step = 1 if event.key == pygame.K_DOWN else -1
            index = max(0, min(len(self.section_tabs) - 1, self.current_section + step))
            self._jump(index)()
            self.group.set_focus(index, sound=True)
            return
        if not self.scroll.handle_event(event):
            self.group.handle_event(event)

    def update(self, dt: float) -> None:
        self.scroll.update(dt)
        self.group.update(dt)

    def draw(self, surface: pygame.Surface) -> None:
        surface.fill(PALETTE.background)
        surface.blit(self.game.background, (0, 0))
        dim(surface, 120)
        draw_card(surface, CARD)
        draw_text(surface, "HOW TO PLAY", "heading", PALETTE.text, shadow=True, topleft=(CARD.x + PAD, CARD.y + 16))
        draw_text(surface, f"Everything in {APP_NAME}, explained. Keys shown are your own bindings.", "small",
                  PALETTE.text_dim, topleft=(CARD.x + PAD + 2, CARD.y + 62))
        self.group.draw(surface)
        draw_panel(surface, self.panel, "slot")
        top = self.view.y + TEXT_PAD - self.scroll.offset
        self.document.draw(surface, self.panel.x + TEXT_PAD, top, self.view)
        self.scroll.draw_scrollbar(surface)
        draw_hint_row(surface, [(["WHEEL", "PGUP", "PGDN"], "Scroll"), (["UP", "DOWN"], "Section"),
                                (["ESC"], "Back")], CARD.x + PAD, self.close_button.rect.centery - 10)
