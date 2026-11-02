import pygame
import pytest

from duck_attack import settings
from duck_attack.sounds import AmbientSounds, RandomSound


@pytest.fixture
def mixer():
    pygame.mixer.init()
    yield
    pygame.mixer.quit()


def test_all_sounds_load(mixer):
    assert len(RandomSound(settings.AMBIENT_SOUNDS, 1.0).sounds) == 3
    assert len(RandomSound([settings.SHOT_SOUND], 1.0).sounds) == 1


def test_plays_after_delay_and_reschedules(mixer):
    ambience = AmbientSounds()
    first_delay = ambience.next_in
    assert settings.AMBIENT_MIN_DELAY <= first_delay <= settings.AMBIENT_MAX_DELAY
    ambience.update(first_delay - 0.1)
    assert ambience.random_sound.last_played is None
    ambience.update(0.2)
    assert ambience.random_sound.last_played is not None
    assert settings.AMBIENT_MIN_DELAY <= ambience.next_in <= settings.AMBIENT_MAX_DELAY


def test_never_repeats_the_same_sound_twice_in_a_row(mixer):
    sound = RandomSound(settings.AMBIENT_SOUNDS, 1.0)
    previous = None
    for _ in range(30):
        sound.play()
        assert sound.last_played != previous
        previous = sound.last_played


def test_silent_without_audio_device():
    pygame.mixer.quit()
    ambience = AmbientSounds()
    assert ambience.random_sound.sounds == []
    ambience.update(settings.AMBIENT_MAX_DELAY)  # must not raise
    shot = RandomSound([settings.SHOT_SOUND], 1.0)
    shot.play()  # must not raise
    assert shot.last_played is None
