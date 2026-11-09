"""Shared shapes and layout metrics of the interface."""

from dataclasses import dataclass

# Corner radii
RADIUS_SM = 5
RADIUS_MD = 8
RADIUS_LG = 14


@dataclass(frozen=True)
class PanelStyle:
    """How a panel looks. Colors are palette field names, looked up at draw time
    so recoloring the palette also recolors every panel."""

    radius: int
    shadow: int                     # drop-shadow spread in px (0 = none)
    top: str = "panel_top"
    bottom: str = "panel_bottom"
    border: str = "line"
    finish: bool = False            # a lit accent top edge and a fine inner line (the big containers)


PANEL_STYLES: dict[str, PanelStyle] = {
    "frame": PanelStyle(radius=RADIUS_LG, shadow=22, finish=True),     # big containers (the ability bar)
    "chip": PanelStyle(radius=RADIUS_MD, shadow=8, border="border"),   # small pills (the timer)
    "slot": PanelStyle(radius=RADIUS_MD, shadow=0, border="border"),   # one ability box
    "card": PanelStyle(radius=RADIUS_LG, shadow=30, finish=True),      # the centered box of a menu screen
    "button": PanelStyle(radius=RADIUS_MD, shadow=6),
}

# Menus (px)
BUTTON_WIDTH = 280
BUTTON_HEIGHT = 48
BUTTON_GAP = 12
CARD_PAD = 28               # padding inside a menu card

# HUD layout (px)
HUD_MARGIN = 12             # gap between the HUD and the window edges
HUD_SLOT = 56               # ability box size
HUD_SLOT_GAP = 8
HUD_GROUP_GAP = 20          # extra gap between abilities and utility spells
HUD_BAR_PAD = 12            # padding inside the ability bar frame
HUD_KEYCAP_SPACE = 20       # room under the boxes for the key labels
HUD_BUFF_RADIUS = 20        # active-effect circles left of the bar
