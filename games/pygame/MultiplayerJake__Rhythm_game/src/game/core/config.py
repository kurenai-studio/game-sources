"""Player configuration: every rebindable shortcut.

Stored in ``settings.json`` (plain JSON - keybinds are not score data).
Keybinds are stored as pygame key *names* (e.g. "d", "space") so the file
stays readable and portable. ``None`` means unbound.

Older files that only contain ``{"lane_keys": [...], "editor_stop": ...}``
are migrated to the new ``{"keys": {...}}`` format on load.
"""

from __future__ import annotations

import json

import pygame

SETTINGS_PATH = "settings.json"

# action -> default pygame key name (None = unbound)
DEFAULT_KEYS = {
    # gameplay
    "lane_0": "d",
    "lane_1": "f",
    "lane_2": "j",
    "lane_3": "k",
    "boost": "space",
    # editor
    "editor_stop": "space",
    "editor_undo": "backspace",
    # menus / global
    "menu_up": "up",
    "menu_down": "down",
    "menu_left": "left",
    "menu_right": "right",
    "confirm": "return",
    "cancel": "escape",
}

# Settings screen layout: group title -> actions (in display order)
GROUPS: list[tuple[str, list[str]]] = [
    ("GAMEPLAY", ["lane_0", "lane_1", "lane_2", "lane_3", "boost"]),
    ("EDITOR", ["editor_stop", "editor_undo"]),
    ("MENU", ["menu_up", "menu_down", "menu_left", "menu_right",
              "confirm", "cancel"]),
]

LABELS = {
    "lane_0": "LANE 1",
    "lane_1": "LANE 2",
    "lane_2": "LANE 3",
    "lane_3": "LANE 4",
    "boost": "BOOST",
    "editor_stop": "EDITOR STOP",
    "editor_undo": "EDITOR UNDO",
    "menu_up": "MENU UP",
    "menu_down": "MENU DOWN",
    "menu_left": "MENU LEFT",
    "menu_right": "MENU RIGHT",
    "confirm": "CONFIRM",
    "cancel": "CANCEL",
}


class Config:
    def __init__(self, path: str = SETTINGS_PATH):
        self.path = path
        self.keys: dict[str, str | None] = dict(DEFAULT_KEYS)
        self.volume: float = 0.8          # music volume 0.0 - 1.0
        self.scanlines: bool = True       # CRT scanline overlay
        self.particles: bool = True       # backdrop motes + hit particles
        self.load()

    # ------------------------------------------------------------------ io
    def load(self) -> None:
        try:
            with open(self.path, "r", encoding="utf-8") as fh:
                data = json.load(fh)
        except (OSError, ValueError):
            self.keys = dict(DEFAULT_KEYS)
            return

        if not isinstance(data, dict):
            return

        audio = data.get("audio")
        if isinstance(audio, dict) and isinstance(audio.get("volume"), (int, float)):
            self.volume = max(0.0, min(1.0, float(audio["volume"])))
        fx = data.get("fx")
        if isinstance(fx, dict):
            if isinstance(fx.get("scanlines"), bool):
                self.scanlines = fx["scanlines"]
            if isinstance(fx.get("particles"), bool):
                self.particles = fx["particles"]

        raw = data.get("keys")
        if isinstance(raw, dict):
            self.keys = dict(DEFAULT_KEYS)
            for action in DEFAULT_KEYS:
                if action in raw:
                    self.keys[action] = self._valid(raw[action])
            return

        # legacy layout: {"lane_keys": [...], "editor_stop": "space"}
        self.keys = dict(DEFAULT_KEYS)
        lanes = data.get("lane_keys")
        if isinstance(lanes, list):
            for i, value in enumerate(lanes[:4]):
                self.keys[f"lane_{i}"] = self._valid(value)
        if "editor_stop" in data:
            self.keys["editor_stop"] = self._valid(data.get("editor_stop"))

    def save(self) -> None:
        payload = {
            "keys": self.keys,
            "audio": {"volume": round(self.volume, 3)},
            "fx": {"scanlines": self.scanlines, "particles": self.particles},
        }
        try:
            with open(self.path, "w", encoding="utf-8") as fh:
                json.dump(payload, fh, indent=2)
        except OSError as exc:
            print(f"[config] could not save settings: {exc}")

    @staticmethod
    def _valid(name):
        if name is None:
            return None
        if not isinstance(name, str) or not name:
            return None
        try:
            pygame.key.key_code(name)
        except (ValueError, KeyError):
            return None
        return name

    # ------------------------------------------------------------- access
    def key(self, action: str):
        """pygame key constant for ``action``, or None if unbound."""
        name = self.keys.get(action)
        if not name:
            return None
        try:
            return pygame.key.key_code(name)
        except (ValueError, KeyError):
            return None

    def label(self, action: str) -> str:
        """Display name of the bound key ('SPACE', 'UNBOUND', ...)."""
        name = self.keys.get(action)
        return name.upper() if name else "UNBOUND"

    @property
    def lane_keys(self) -> list:
        """Names of the four lane keys (used for the highway labels)."""
        return [self.keys.get(f"lane_{i}") for i in range(4)]

    def lane_key(self, index: int):
        return self.key(f"lane_{index}")

    def set_key(self, action: str, key) -> None:
        self.keys[action] = self.key_name(key)
        self.save()

    def clear_key(self, action: str) -> None:
        self.keys[action] = None
        self.save()

    def reset_all(self) -> None:
        self.keys = dict(DEFAULT_KEYS)
        self.save()

    @staticmethod
    def key_name(key) -> str:
        try:
            return pygame.key.name(key)
        except (ValueError, TypeError):
            return "?"

    # ---------------------------------------------- backwards-compatible
    @property
    def editor_stop_name(self) -> str:
        return self.label("editor_stop")

    def editor_stop_key(self):
        return self.key("editor_stop")
