"""Player settings (currently just the volume), saved in settings.json in the project folder.

A missing or damaged settings file is never an error: the defaults are used instead.
"""
import json
import os

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SETTINGS_FILE = os.path.join(PROJECT_ROOT, "settings.json")

DEFAULT_VOLUME = 0.6  # 0.0 (silent) to 1.0 (full)


def clamp_volume(value):
    """Keep a volume between 0.0 and 1.0, using the default for anything that isn't a number."""
    try:
        return min(1.0, max(0.0, float(value)))
    except (TypeError, ValueError):
        return DEFAULT_VOLUME


def load_volume(path=None):
    """Return the saved volume, or the default if there isn't a usable one."""
    try:
        with open(path or SETTINGS_FILE, encoding="utf-8") as f:
            return clamp_volume(json.load(f).get("volume", DEFAULT_VOLUME))
    except (OSError, ValueError, AttributeError):
        return DEFAULT_VOLUME


def save_volume(volume, path=None):
    """Save the volume. Returns False (and keeps playing) if the file can't be written."""
    try:
        with open(path or SETTINGS_FILE, "w", encoding="utf-8") as f:
            json.dump({"volume": clamp_volume(volume)}, f)
        return True
    except OSError:
        return False
