"""Key names: checking them and showing them on keycaps.

Bindings are stored as pygame key *names* ("q", "space", "left shift") rather
than numbers, so the save file stays readable and survives pygame updates.
"""

import pygame

SHORT_LABELS = {"escape": "ESC", "return": "ENTER", "backspace": "BKSP", "left shift": "LSHIFT",
                "right shift": "RSHIFT", "left ctrl": "LCTRL", "right ctrl": "RCTRL",
                "left alt": "LALT", "right alt": "RALT"}


def key_label(key_name: str) -> str:
    """How a key name is shown on a keycap: "escape" -> "ESC", "q" -> "Q"."""
    return SHORT_LABELS.get(key_name, key_name.upper())


def is_valid_key_name(key_name) -> bool:
    """True if pygame knows this key name (used to validate the save file)."""
    if not isinstance(key_name, str) or not key_name:
        return False
    try:
        pygame.key.key_code(key_name)
    except ValueError:
        return False
    return True
