"""Typography: every text style the game uses, by role.

Code asks for a role ("timer", "label", ...) instead of a raw size, so the
whole look can be retuned here.
"""

from dataclasses import dataclass

# Font stacks: the first installed font in each list is used.
FONT_DISPLAY = "bahnschrift,segoeuisemibold,segoeui,arial"     # numbers, headings
FONT_BODY = "segoeui,arial"                                     # sentences
FONT_MONO = "consolas,couriernew"                               # key labels


@dataclass(frozen=True)
class TextStyle:
    font: str
    size: int
    bold: bool = False


TEXT_STYLES: dict[str, TextStyle] = {
    "logo":     TextStyle(FONT_DISPLAY, 92, True),      # the first word of the game's name on the main menu
    "title":    TextStyle(FONT_DISPLAY, 64, True),
    "heading":  TextStyle(FONT_DISPLAY, 40, True),      # card headings: PAUSED, GAME OVER
    "stat":     TextStyle(FONT_DISPLAY, 34, True),      # a big number on a card
    "subtitle": TextStyle(FONT_BODY, 24),
    "button":   TextStyle(FONT_DISPLAY, 18, True),
    "float":    TextStyle(FONT_DISPLAY, 18, True),      # "+1", "BLOCKED" rising over the arena
    "banner":   TextStyle(FONT_DISPLAY, 56, True),      # "GET READY" / "GO!"
    "small":    TextStyle(FONT_BODY, 15),
    "body":     TextStyle(FONT_BODY, 17),               # paragraphs in the guide
    "timer":    TextStyle(FONT_DISPLAY, 28, True),
    "cooldown": TextStyle(FONT_DISPLAY, 22, True),
    "label":    TextStyle(FONT_DISPLAY, 13, True),
    "tiny":     TextStyle(FONT_BODY, 12, True),
    "key":      TextStyle(FONT_MONO, 13, True),
}
