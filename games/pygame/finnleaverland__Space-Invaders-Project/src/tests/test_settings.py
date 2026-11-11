"""Tests for saving and loading the player's settings."""
import pytest

from space_invaders import settings


@pytest.fixture
def settings_file(tmp_path):
    return str(tmp_path / "settings.json")


def test_default_volume_when_there_is_no_file(settings_file):
    assert settings.load_volume(settings_file) == settings.DEFAULT_VOLUME


def test_volume_is_saved_and_loaded(settings_file):
    assert settings.save_volume(0.25, settings_file)
    assert settings.load_volume(settings_file) == 0.25


@pytest.mark.parametrize("contents", ["not json", "[1, 2]", '{"volume": "loud"}', ""])
def test_damaged_files_fall_back_to_the_default(settings_file, contents):
    with open(settings_file, "w") as f:
        f.write(contents)
    assert settings.load_volume(settings_file) == settings.DEFAULT_VOLUME


@pytest.mark.parametrize("value, expected", [(-1, 0.0), (0, 0.0), (0.5, 0.5), (1, 1.0), (7, 1.0)])
def test_volume_is_kept_between_0_and_1(settings_file, value, expected):
    settings.save_volume(value, settings_file)
    assert settings.load_volume(settings_file) == expected


def test_a_file_that_cant_be_written_is_not_an_error(tmp_path):
    assert not settings.save_volume(0.5, str(tmp_path / "missing-folder" / "settings.json"))
