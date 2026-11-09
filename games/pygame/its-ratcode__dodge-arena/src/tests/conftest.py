"""Shared test setup.

The tests run in a hidden window with silent audio, so they work anywhere,
including on a CI server without a screen or sound card. Every test that
needs a save file gets its own temporary one, so nothing touches your real
progress.
"""

import os

os.environ.setdefault("SDL_VIDEODRIVER", "dummy")
os.environ.setdefault("SDL_AUDIODRIVER", "dummy")

import pygame                                       # noqa: E402  (after the environment is set)
import pytest                                       # noqa: E402

import app.audio.player as audio_player             # noqa: E402
from app import config                              # noqa: E402
from app.core.game import Game                      # noqa: E402
from app.core.world import World                    # noqa: E402
from helpers import calm                            # noqa: E402

pygame.init()

# Every Game synthesizes all its sounds, which takes a few seconds. The game does it once per
# launch; the tests create many games, so they build the sounds once and share them.
_sounds: dict[int, dict] = {}
_build_sound_bank = audio_player.build_sound_bank


def _shared_sound_bank(synth):
    if synth.rate not in _sounds:
        _sounds[synth.rate] = _build_sound_bank(synth)
    return _sounds[synth.rate]


audio_player.build_sound_bank = _shared_sound_bank


@pytest.fixture
def save_path(tmp_path):
    return tmp_path / "save.json"


@pytest.fixture
def game(save_path, monkeypatch):
    """A whole game on the main menu: no music process, and no fades between screens."""
    monkeypatch.setattr(config, "SCENE_FADE_TIME", 0)
    return Game(save_path=save_path, music=False)


@pytest.fixture
def world():
    """A quiet run with no upgrades."""
    return calm(World())
