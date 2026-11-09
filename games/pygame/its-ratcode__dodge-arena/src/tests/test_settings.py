"""Settings: defaults, saving, validation of hand-edited files, and key rebinding."""

import json

import pytest

from app import config
from app.core.settings import ACTION_LABELS, OPTIONS, Settings
from app.core.storage import SaveFile


@pytest.fixture
def settings(save_path):
    return Settings(SaveFile(save_path))


def test_defaults(settings):
    assert settings.keybinds == config.DEFAULT_KEYBINDS
    assert set(ACTION_LABELS) == set(config.DEFAULT_KEYBINDS), "every action has a label in Settings"
    assert all(settings.options[name] == default for name, (default, _) in OPTIONS.items())
    assert not settings.assists_on


def test_changes_are_saved_and_reload(save_path, settings):
    settings.toggle("show_fps")
    settings.cycle("game_speed", -1)
    settings.bind("shield", "z")
    reloaded = Settings(SaveFile(save_path))
    assert reloaded.options["show_fps"] is True
    assert reloaded.options["game_speed"] == 90
    assert reloaded.keybinds["shield"] == "z"


def test_binding_a_used_key_swaps_the_two(settings):
    settings.bind("shield", "w")
    assert settings.keybinds["shield"] == "w" and settings.keybinds["wall"] == "q"
    assert len(set(settings.keybinds.values())) == len(settings.keybinds), "no key does two things"


def test_cycling_wraps_around(settings):
    settings.cycle("game_speed", 1)                 # 100 is the last value
    assert settings.options["game_speed"] == 50


def test_a_hand_edited_file_is_cleaned_up(save_path):
    save_path.write_text(json.dumps({"settings": {
        "keybinds": {"shield": "w", "wall": "w", "dash": "not a key"},      # a duplicate and a bad name
        "move_button": 7,
        "options": {"show_fps": 1, "game_speed": 33, "accent": "Gold"},     # 1 is not a bool; 33 not allowed
    }}), encoding="utf-8")
    settings = Settings(SaveFile(save_path))
    assert len(set(settings.keybinds.values())) == len(settings.keybinds)
    assert settings.keybinds["dash"] == "e"
    assert settings.move_button == config.DEFAULT_MOVE_BUTTON
    assert settings.options["show_fps"] is False and settings.options["game_speed"] == 100
    assert settings.options["accent"] == "Gold", "valid values are kept"


def test_an_older_save_gets_new_keys_with_their_defaults(save_path):
    old = {key: name for key, name in config.DEFAULT_KEYBINDS.items() if key != "restart"}
    save_path.write_text(json.dumps({"settings": {"keybinds": old}}), encoding="utf-8")
    assert Settings(SaveFile(save_path)).keybinds["restart"] == "r"


@pytest.mark.parametrize("option, value", [("game_speed", 90), ("laser_warning", 150), ("lasers", False)])
def test_assists(settings, option, value):
    settings.options[option] = value
    assert settings.assists_on


def test_reset_keeps_the_same_keybinds_dict(settings):
    keybinds = settings.keybinds                    # the run's loadout holds on to this dict
    settings.bind("shield", "z")
    settings.reset()
    assert settings.keybinds is keybinds and keybinds == config.DEFAULT_KEYBINDS
