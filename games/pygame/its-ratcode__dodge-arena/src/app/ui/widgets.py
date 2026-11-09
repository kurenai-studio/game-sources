"""Interface widgets: buttons, settings rows, and groups that work with mouse and keyboard."""

from collections.abc import Callable
from dataclasses import dataclass

import pygame
from pygame.math import Vector2

from app.render.icons import draw_icon
from app.render.shapes import draw_accent_bar, draw_glow, draw_panel, draw_row
from app.render.text import draw_keycap, draw_spaced, draw_text, text_size
from app.theme.accessibility import A11Y
from app.theme.palette import PALETTE, SWATCHES
from app.theme.styles import BUTTON_GAP, BUTTON_HEIGHT, BUTTON_WIDTH, PANEL_STYLES, RADIUS_SM
from app.util.keys import key_label
from app.util.mathx import Color, lerp_color

# --- Menu sounds ---------------------------------------------------------------------------------
# Widgets don't know about audio. The Game plugs a player in once with set_ui_sound();
# until then (and in tests) sounds are silently skipped.
_ui_sound: Callable[[str], object] = lambda name: None


def set_ui_sound(play: Callable[[str], object]) -> None:
    global _ui_sound
    _ui_sound = play


def play_ui_sound(name: str) -> None:
    """"hover", "click", "back", "tick", "error", "buy", "sell"."""
    _ui_sound(name)


@dataclass(frozen=True)
class ButtonLook:
    """The colors of one button variant, at rest and focused."""

    fill: Color
    fill_focus: Color
    border: Color
    border_focus: Color
    text: Color
    glow: Color
    bar: Color | None           # the accent bar that grows on the left when focused (None = no bar)


def button_look(variant: str) -> ButtonLook:
    """Built from the palette at draw time, so color modes recolor buttons too.

    "primary"   filled with the accent color: the one main action of a screen
    "secondary" dark, with an accent bar when focused: everything else
    "danger"    dark red: actions that throw something away (quit, refund, reset)
    """
    p = PALETTE
    if variant == "primary":
        return ButtonLook(lerp_color(p.accent, p.panel_bottom, 0.3), p.accent, lerp_color(p.accent, p.text, 0.3),
                          lerp_color(p.accent, p.text, 0.7), p.panel_bottom, p.accent, None)
    if variant == "danger":
        return ButtonLook(lerp_color(p.danger, p.panel_bottom, 0.8), lerp_color(p.danger, p.panel_bottom, 0.62),
                          lerp_color(p.danger, p.panel_bottom, 0.55), p.danger, lerp_color(p.danger, p.text, 0.8),
                          p.danger, p.danger)
    return ButtonLook(p.row, p.row_hover, p.line, p.accent, p.text, p.accent, p.accent)


class Button:
    """A clickable box with a label, an optional icon and an optional hotkey keycap.

    ``variant`` is "primary", "secondary" or "danger" (see ``button_look``);
    ``primary=True`` is a shortcut for the first. ``align`` places the icon and
    label on the "left" (menus) or in the "center". A disabled button can still
    be focused but does nothing (it plays an error sound). ``highlight`` eases
    between 0 and 1 so focusing fades in instead of popping. ``sound`` is the
    menu sound it makes when used.
    """

    def __init__(self, label: str | Callable[[], str], action: Callable[[], None],
                 hotkey: str | Callable[[], str] | None = None,
                 primary: bool = False, icon: str | None = None, style: str = "button",
                 size: tuple[int, int] = (BUTTON_WIDTH, BUTTON_HEIGHT), sound: str = "click",
                 variant: str | None = None, align: str = "left") -> None:
        self._label = label                 # a string, or a function for labels that change (prices)
        self.action = action
        self._hotkey = hotkey               # a key name, or a function for keys the player can rebind
        self.variant = variant or ("primary" if primary else "secondary")
        self.align = align
        self.icon = icon
        self.style = style
        self.sound = sound
        self.enabled = True
        self.rect = pygame.Rect((0, 0), size)
        self.highlight = 0.0
        self.pressed = False

    @property
    def hotkey(self) -> str | None:
        return self._hotkey() if callable(self._hotkey) else self._hotkey

    @property
    def hotkey_code(self) -> int | None:
        hotkey = self.hotkey
        return pygame.key.key_code(hotkey) if hotkey else None

    @property
    def primary(self) -> bool:
        return self.variant == "primary"

    @property
    def label(self) -> str:
        return self._label() if callable(self._label) else self._label

    def activate(self) -> None:
        if self.enabled:
            play_ui_sound(self.sound)
            self.action()
        else:
            play_ui_sound("error")

    def click(self, pos) -> None:
        """A mouse click at ``pos``. Most widgets don't care where; some have parts (the shop's - and +)."""
        self.activate()

    def right_click(self, pos) -> None:
        """A right click: the opposite of a click where that means something (sell, step back)."""

    def update(self, dt: float, focused: bool) -> None:
        target = 1.0 if focused else 0.0
        step = dt * 10
        self.highlight += max(-step, min(step, target - self.highlight))

    # --- Drawing ---------------------------------------------------------------------------
    def draw_frame(self, surface: pygame.Surface) -> pygame.Rect:
        """Focus ring, fill, border and accent bar; returns the rect to draw the content in."""
        rect = self.rect.move(0, 2) if self.pressed else self.rect      # sinks while held down
        radius = PANEL_STYLES["button"].radius
        look = button_look(self.variant)
        h = self.highlight if self.enabled else 0.0
        if self.enabled:
            fill, border = lerp_color(look.fill, look.fill_focus, h), lerp_color(look.border, look.border_focus, h)
        else:
            fill, border = lerp_color(PALETTE.row, PALETTE.panel_bottom, 0.5), PALETTE.border
        draw_panel(surface, rect, "button")                            # the drop shadow and shape
        if h > 0.02:
            pygame.draw.rect(surface, lerp_color(PALETTE.background, look.glow, 0.4 * h), rect.inflate(6, 6), 2,
                             border_radius=radius + 3)
        pygame.draw.rect(surface, fill, rect, border_radius=radius)
        pygame.draw.line(surface, lerp_color(fill, PALETTE.text, 0.14),
                         (rect.x + radius, rect.y + 1), (rect.right - radius - 1, rect.y + 1))
        pygame.draw.rect(surface, border, rect, 1, border_radius=radius)
        if look.bar and h > 0:
            draw_accent_bar(surface, rect, h, look.bar)
        return rect

    def text_color(self) -> Color:
        return button_look(self.variant).text if self.enabled else PALETTE.text_faint

    def draw(self, surface: pygame.Surface) -> None:
        rect = self.draw_frame(surface)
        label, color = self.label, self.text_color()
        width = text_size(label, self.style)[0] + (30 if self.icon else 0)
        if self.align == "center":
            x = rect.centerx - width // 2
        else:
            x = rect.x + 22 + round(4 * self.highlight)      # the label slides a little when focused
        if self.icon:
            draw_icon(surface, self.icon, (x + 10, rect.centery), 20, color)
            x += 30
        draw_text(surface, label, self.style, color, shadow=not self.primary, midleft=(x, rect.centery))
        if self.hotkey:
            draw_keycap(surface, key_label(self.hotkey), midright=(rect.right - 12, rect.centery))


# --- Settings rows ---------------------------------------------------------------------------
class SettingRow(Button):
    """A full-width row: an optional icon, a label and a small tag on the left, the current value on the right.
    ``desc`` is a sentence the settings screen shows while the row is focused. ``icon_color`` is a
    palette field name, read at draw time."""

    def __init__(self, label: str, action: Callable[[], None], value: Callable[[], str],
                 size: tuple[int, int], desc: str = "", icon: str | None = None,
                 icon_color: str = "text_dim", tag: str = "") -> None:
        super().__init__(label, action, size=size, sound="tick", icon=icon)
        self.value = value
        self.desc = desc
        self.icon_color = icon_color
        self.tag = tag

    def emphasis(self) -> float:
        """How strongly the row is highlighted, 0..1."""
        return self.highlight

    def draw(self, surface: pygame.Surface) -> None:
        rect = self.rect
        draw_row(surface, rect, self.emphasis())
        x = rect.x + 20
        if self.icon:
            draw_icon(surface, self.icon, (x + 10, rect.centery), 20, getattr(PALETTE, self.icon_color))
            x += 34
        label = draw_text(surface, self.label, "body", PALETTE.text, midleft=(x, rect.centery))
        if self.tag:
            draw_spaced(surface, self.tag, "tiny", PALETTE.text_faint, 2, midleft=(label.right + 10, rect.centery + 1))
        self.draw_value(surface, rect)

    def draw_value(self, surface: pygame.Surface, rect: pygame.Rect) -> None:
        draw_text(surface, f"<  {self.value()}  >", "small", PALETTE.text, midright=(rect.right - 16, rect.centery))


class ChoiceRow(SettingRow):
    """Steps through a list of values: activating goes forward, Left / Right step either way.
    Clicking the left half of the value box steps back."""

    BOX = (190, 30)

    def __init__(self, label: str, change: Callable[[int], None], value: Callable[[], str],
                 size: tuple[int, int], desc: str = "") -> None:
        super().__init__(label, lambda: change(1), value, size, desc)
        self.change = change

    def box(self) -> pygame.Rect:
        box = pygame.Rect((0, 0), self.BOX)
        box.midright = (self.rect.right - 12, self.rect.centery)
        return box

    def click(self, pos) -> None:
        box = self.box()
        play_ui_sound(self.sound)
        self.change(-1 if box.collidepoint(pos) and pos[0] < box.centerx else 1)

    def right_click(self, pos) -> None:
        play_ui_sound(self.sound)
        self.change(-1)

    def draw_value(self, surface: pygame.Surface, rect: pygame.Rect) -> None:
        box, h = self.box(), self.highlight
        pygame.draw.rect(surface, PALETTE.panel_bottom, box, border_radius=RADIUS_SM)
        pygame.draw.rect(surface, lerp_color(PALETTE.border, PALETTE.accent, h * 0.7), box, 1, border_radius=RADIUS_SM)
        arrow = lerp_color(PALETTE.text_faint, PALETTE.accent, h)
        draw_text(surface, "<", "button", arrow, center=(box.x + 15, box.centery))
        draw_text(surface, ">", "button", arrow, center=(box.right - 15, box.centery))
        draw_text(surface, self.value(), "button", PALETTE.accent, center=box.center)


class VolumeRow(ChoiceRow):
    """A volume from 0 to 100%, shown as ten segments plus the number."""

    def __init__(self, label: str, change: Callable[[int], None], percent: Callable[[], int],
                 size: tuple[int, int], desc: str = "") -> None:
        super().__init__(label, change, lambda: f"{percent()}%", size, desc)
        self.percent = percent

    def draw_value(self, surface: pygame.Surface, rect: pygame.Rect) -> None:
        text = draw_text(surface, self.value(), "small", PALETTE.text, midright=(rect.right - 16, rect.centery))
        filled = self.percent() // 10
        for i in range(10):
            seg = pygame.Rect(0, 0, 8, 14)
            seg.midright = (text.left - 14 - (9 - i) * 11, rect.centery)
            pygame.draw.rect(surface, PALETTE.accent if i < filled else PALETTE.track, seg, border_radius=2)


class ColorRow(ChoiceRow):
    """A choice of color: every option as a swatch in a row, the chosen one ringed. ``choices`` maps
    names to colors (None = Auto); ``value`` returns the chosen name. Left / Right still step."""

    SWATCH, GAP = 22, 6

    def __init__(self, label: str, change: Callable[[int], None], value: Callable[[], str],
                 size: tuple[int, int], desc: str = "", choices: dict[str, Color | None] = SWATCHES) -> None:
        super().__init__(label, change, value, size, desc)
        self.choices = choices

    def swatch_rects(self) -> list[pygame.Rect]:
        """One square per choice, right-aligned in the row."""
        total = len(self.choices) * (self.SWATCH + self.GAP) - self.GAP
        x = self.rect.right - 16 - total
        return [pygame.Rect(x + i * (self.SWATCH + self.GAP), self.rect.centery - self.SWATCH // 2,
                            self.SWATCH, self.SWATCH) for i in range(len(self.choices))]

    def click(self, pos) -> None:
        """A click on a swatch picks it; anywhere else steps to the next one."""
        names = list(self.choices)
        for i, rect in enumerate(self.swatch_rects()):
            if rect.inflate(4, 4).collidepoint(pos):
                play_ui_sound(self.sound)
                self.change(i - names.index(self.value()))
                return
        super().click(pos)

    def draw_value(self, surface: pygame.Surface, rect: pygame.Rect) -> None:
        rects = self.swatch_rects()
        chosen = self.value()
        draw_text(surface, chosen, "small", PALETTE.text_dim, midright=(rects[0].x - 12, rect.centery))
        for (name, color), r in zip(self.choices.items(), rects):
            if color is None:                                   # Auto: follows the color mode
                pygame.draw.rect(surface, PALETTE.panel_bottom, r, border_radius=RADIUS_SM)
                draw_text(surface, "A", "tiny", PALETTE.text_dim, center=r.center)
            else:
                pygame.draw.rect(surface, color, r, border_radius=RADIUS_SM)
            if name == chosen:
                pygame.draw.rect(surface, PALETTE.accent, r.inflate(6, 6), 2, border_radius=RADIUS_SM + 2)
            else:
                pygame.draw.rect(surface, PALETTE.line, r, 1, border_radius=RADIUS_SM)


class KeyBindRow(SettingRow):
    """Shows the bound key as a keycap, or a prompt while waiting for a new key."""

    def __init__(self, label: str, action: Callable[[], None], key_name: Callable[[], str],
                 waiting: Callable[[], bool], size: tuple[int, int], desc: str = "", **looks) -> None:
        super().__init__(label, action, key_name, size, desc, **looks)
        self.waiting = waiting

    def emphasis(self) -> float:
        return 1.0 if self.waiting() else self.highlight

    def draw_value(self, surface: pygame.Surface, rect: pygame.Rect) -> None:
        if self.waiting():
            draw_text(surface, "Press a key...  (Esc cancels)", "small", PALETTE.warning,
                      midright=(rect.right - 16, rect.centery))
        else:
            draw_keycap(surface, key_label(self.value()), midright=(rect.right - 16, rect.centery))


class ToggleRow(SettingRow):
    """An on/off switch."""

    def __init__(self, label: str, action: Callable[[], None], is_on: Callable[[], bool],
                 size: tuple[int, int], desc: str = "") -> None:
        super().__init__(label, action, lambda: "On" if is_on() else "Off", size, desc)
        self.is_on = is_on
        self.knob = 1.0 if is_on() else 0.0         # 0 = off, 1 = on; slides between them

    def update(self, dt: float, focused: bool) -> None:
        super().update(dt, focused)
        target = 1.0 if self.is_on() else 0.0
        if A11Y.reduced_motion:
            self.knob = target
        else:
            self.knob += (target - self.knob) * min(1.0, dt * 18)

    def draw_value(self, surface: pygame.Surface, rect: pygame.Rect) -> None:
        track = pygame.Rect(0, 0, 46, 24)
        track.midright = (rect.right - 16, rect.centery)
        on, k = self.is_on(), self.knob
        pygame.draw.rect(surface, lerp_color(PALETTE.track, PALETTE.success, k), track, border_radius=12)
        knob_x = round(track.left + 12 + (track.width - 24) * k)
        pygame.draw.circle(surface, lerp_color(PALETTE.text_dim, PALETTE.text, k), (knob_x, track.centery), 9)
        draw_text(surface, "ON" if on else "OFF", "tiny", PALETTE.success if on else PALETTE.text_faint,
                  midright=(track.x - 10, track.centery))


class TabButton(Button):
    """A tab: plain text with an accent underline when it is the open tab."""

    def __init__(self, label: str, action: Callable[[], None], is_open: Callable[[], bool],
                 size: tuple[int, int]) -> None:
        super().__init__(label, action, size=size, sound="tick")
        self.is_open = is_open

    def draw(self, surface: pygame.Surface) -> None:
        open_ = self.is_open()
        if self.highlight > 0:
            draw_glow(surface, PALETTE.accent, self.rect.center, self.rect.width * 0.4, int(40 * self.highlight))
        color = PALETTE.text if open_ else lerp_color(PALETTE.text_dim, PALETTE.text, self.highlight)
        draw_text(surface, self.label, "button", color, shadow=True, center=self.rect.center)
        if open_:
            line = pygame.Rect(0, 0, self.rect.width - 24, 3)
            line.midbottom = self.rect.midbottom
            pygame.draw.rect(surface, PALETTE.accent, line, border_radius=2)


class SectionTab(Button):
    """A sidebar entry: icon and label on a flat row, filled with an accent bar while it is the open section."""

    def __init__(self, label: str, action: Callable[[], None], is_open: Callable[[], bool],
                 size: tuple[int, int], icon: str | None = None) -> None:
        super().__init__(label, action, size=size, sound="tick", icon=icon)
        self.is_open = is_open

    def draw(self, surface: pygame.Surface) -> None:
        open_, h = self.is_open(), self.highlight
        r = self.rect
        if open_ or h > 0.02:
            amount = 1.0 if open_ else h * 0.6
            pygame.draw.rect(surface, lerp_color(PALETTE.row, PALETTE.row_hover, amount), r,
                             border_radius=PANEL_STYLES["button"].radius)
            # Open: a full bar. Only focused (keyboard or mouse): a shorter, softer one.
            draw_accent_bar(surface, r, 1.0 if open_ else h * 0.55,
                            PALETTE.accent if open_ else lerp_color(PALETTE.accent, PALETTE.row, 0.4))
        color = PALETTE.text if open_ else lerp_color(PALETTE.text_dim, PALETTE.text, h)
        x = r.x + 20
        if self.icon:
            draw_icon(surface, self.icon, (x + 9, r.centery), 18, PALETTE.accent if open_ else color)
            x += 30
        draw_text(surface, self.label, "body", color, shadow=open_, midleft=(x, r.centery))


# --- Groups ---------------------------------------------------------------------------------
DIRECTIONS = {pygame.K_UP: Vector2(0, -1), pygame.K_DOWN: Vector2(0, 1),
              pygame.K_LEFT: Vector2(-1, 0), pygame.K_RIGHT: Vector2(1, 0)}


class ButtonGroup:
    """Widgets placed anywhere on screen, sharing one keyboard focus.

    Mouse: hover focuses, click (press and release on the same widget) activates.
    Keyboard: the arrow keys move the focus to the nearest widget in that
    direction (so grids work too), Tab cycles in order, Enter or Space
    activates, and a widget's hotkey activates it directly.
    """

    def __init__(self, buttons: list[Button]) -> None:
        self.buttons = buttons
        self.focus = 0
        self._sounded_focus = 0             # the focus the last hover sound was played for

    def set_focus(self, index: int, sound: bool = False) -> None:
        """Move the focus from code (not from the player), silently unless ``sound``."""
        self.focus = index
        if not sound:
            self._sounded_focus = index

    def _button_at(self, pos) -> int | None:
        for i, button in enumerate(self.buttons):
            if button.rect.collidepoint(pos):
                return i
        return None

    def _nearest(self, direction: Vector2) -> int | None:
        """The closest widget whose center lies in ``direction``; sideways distance counts double."""
        here = Vector2(self.buttons[self.focus].rect.center)
        best, best_score = None, float("inf")
        for i, button in enumerate(self.buttons):
            offset = Vector2(button.rect.center) - here
            ahead = offset.dot(direction)
            if i == self.focus or ahead <= 0:
                continue
            score = ahead + 2 * abs(offset.cross(direction))
            if score < best_score:
                best, best_score = i, score
        return best

    def handle_event(self, event: pygame.event.Event) -> bool:
        """Returns True if the event was used (so the screen can ignore it)."""
        if event.type == pygame.MOUSEMOTION:
            index = self._button_at(event.pos)
            if index is not None:
                self.focus = index
        elif event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            index = self._button_at(event.pos)
            if index is not None:
                self.focus = index
                self.buttons[index].pressed = True
                return True
        elif event.type == pygame.MOUSEBUTTONUP and event.button == 3:
            index = self._button_at(event.pos)
            if index is not None:
                self.focus = index
                self.buttons[index].right_click(event.pos)
                return True
        elif event.type == pygame.MOUSEBUTTONUP and event.button == 1:
            index = self._button_at(event.pos)
            was_pressed = index is not None and self.buttons[index].pressed
            for button in self.buttons:
                button.pressed = False
            if was_pressed:
                self.buttons[index].click(event.pos)
                return True
        elif event.type == pygame.KEYDOWN:
            for button in self.buttons:
                if button.hotkey_code is not None and event.key == button.hotkey_code:
                    button.activate()
                    return True
            if event.key in DIRECTIONS:
                index = self._nearest(DIRECTIONS[event.key])
                if index is not None:
                    self.focus = index
                return True
            if event.key == pygame.K_TAB:
                step = -1 if event.mod & pygame.KMOD_SHIFT else 1
                self.focus = (self.focus + step) % len(self.buttons)
                return True
            if event.key in (pygame.K_RETURN, pygame.K_KP_ENTER, pygame.K_SPACE):
                self.buttons[self.focus].activate()
                return True
        return False

    def update(self, dt: float) -> None:
        if self.focus != self._sounded_focus:              # focus moved (mouse or keys): a soft tick
            self._sounded_focus = self.focus
            play_ui_sound("hover")
        for i, button in enumerate(self.buttons):
            button.update(dt, i == self.focus)

    def draw(self, surface: pygame.Surface) -> None:
        for button in self.buttons:
            button.draw(surface)


class ButtonList(ButtonGroup):
    """Buttons stacked vertically and centered on ``center``. Up/Down wrap around at the ends."""

    def __init__(self, buttons: list[Button], center: tuple[int, int]) -> None:
        super().__init__(buttons)
        self.layout(center)

    def layout(self, center: tuple[int, int]) -> None:
        total = len(self.buttons) * BUTTON_HEIGHT + (len(self.buttons) - 1) * BUTTON_GAP
        y = center[1] - total // 2
        for button in self.buttons:
            button.rect.midtop = (center[0], y)
            y += BUTTON_HEIGHT + BUTTON_GAP

    def handle_event(self, event: pygame.event.Event) -> bool:
        if event.type == pygame.KEYDOWN and event.key in (pygame.K_UP, pygame.K_DOWN):
            step = 1 if event.key == pygame.K_DOWN else -1
            self.focus = (self.focus + step) % len(self.buttons)
            return True
        return super().handle_event(event)
