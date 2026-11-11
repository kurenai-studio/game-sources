"""Tests for the game logic, run frame by frame without opening a real window."""
import os

os.environ["SDL_VIDEODRIVER"] = "dummy"  # no window
os.environ["SDL_AUDIODRIVER"] = "dummy"  # no sound

import pygame  # noqa: E402
import pytest  # noqa: E402

from space_invaders import game as game_module  # noqa: E402
from space_invaders.game import GAME_OVER, PAUSED, PLAYING, READY, Game  # noqa: E402


class Keys(set):
    """Stands in for pygame.key.get_pressed(): Keys({pygame.K_LEFT}) means LEFT is held."""

    def __getitem__(self, key):
        return key in self


NO_KEYS = Keys()


@pytest.fixture
def game():
    test_game = Game(high_score=100)
    yield test_game
    pygame.quit()


def run_frames(game, frames, keys=NO_KEYS):
    for _ in range(frames):
        game.step(keys)


def start(game):
    game.handle_key(pygame.K_SPACE)
    game.step(NO_KEYS)


def hold_fire(game):
    """Stop the aliens shooting, so a stray bullet can't change the result of a test."""
    game.last_alien_shot = float("inf")


def kill_player(game):
    game.player.lives = 1
    game.player.hit()
    game.step(NO_KEYS)


# --- Start screen -------------------------------------------------------------------

def test_game_waits_on_the_start_screen(game):
    run_frames(game, 120)
    assert game.state == READY
    assert game.time == 0
    assert not game.alien_group


def test_space_starts_the_first_wave(game):
    start(game)
    assert game.state == PLAYING
    assert game.wave == 1
    assert len(game.alien_group) == game_module.ALIEN_ROWS * game_module.ALIEN_COLUMNS


# --- Pausing ------------------------------------------------------------------------

def test_p_pauses_and_nothing_moves(game):
    start(game)
    run_frames(game, 30)
    game.handle_key(pygame.K_p)
    assert game.state == PAUSED
    positions = sorted(tuple(alien.rect) for alien in game.alien_group)
    time = game.time
    run_frames(game, 300, Keys({pygame.K_LEFT, pygame.K_SPACE}))
    assert game.time == time
    assert sorted(tuple(alien.rect) for alien in game.alien_group) == positions
    assert not game.bullet_group


def test_p_again_carries_on(game):
    start(game)
    game.handle_key(pygame.K_p)
    game.handle_key(pygame.K_p)
    assert game.state == PLAYING
    time = game.time
    run_frames(game, 10)
    assert game.time > time


def test_aliens_do_not_fire_straight_after_a_long_pause(game):
    start(game)
    run_frames(game, 30)
    game.handle_key(pygame.K_p)
    run_frames(game, 600)
    game.handle_key(pygame.K_p)
    shots_before = len(game.alien_bullet_group)
    game.step(NO_KEYS)
    assert len(game.alien_bullet_group) == shots_before


def test_pause_does_nothing_on_the_start_screen(game):
    game.handle_key(pygame.K_p)
    assert game.state == READY


# --- Game over ----------------------------------------------------------------------

def test_losing_the_last_life_ends_the_game(game):
    start(game)
    kill_player(game)
    assert game.state == GAME_OVER


def test_space_is_ignored_until_the_explosion_has_played(game):
    start(game)
    kill_player(game)
    game.handle_key(pygame.K_SPACE)
    assert game.running
    run_frames(game, int(game_module.GAME_OVER_DELAY / game_module.FRAME_MS) + 1)
    game.handle_key(pygame.K_SPACE)
    assert not game.running


def test_new_high_score(game):
    start(game)
    game.player.score = 100
    assert not game.new_high_score  # equalling it isn't beating it
    game.player.score = 110
    assert game.new_high_score


def test_escape_leaves_from_any_state(game):
    game.handle_key(pygame.K_ESCAPE)
    assert not game.running


def test_main_returns_the_score(monkeypatch):
    def play(self):
        self.player.score = 340
        return self.player.score
    monkeypatch.setattr(Game, "run", play)
    assert game_module.main(high_score=50) == 340


# --- Drawing ------------------------------------------------------------------------

@pytest.mark.parametrize("state", [READY, PLAYING, PAUSED, GAME_OVER])
def test_every_state_draws(game, state):
    start(game)
    if state == GAME_OVER:
        kill_player(game)
        run_frames(game, 200)
    else:
        game.state = state
    game.draw()


def test_lives_above_five_are_shown_as_a_number(game):
    start(game)
    game.player.lives = 8
    game.draw()  # must not draw eight icons over the wave number


# --- Waves and the alien formation -----------------------------------------------------

def alien_positions(game):
    return sorted((alien.x, alien.rect.y) for alien in game.alien_group)


def test_the_aliens_move_together(game):
    start(game)
    before = alien_positions(game)
    game.move_formation()
    after = alien_positions(game)
    moves = {round(a[0] - b[0], 6) for a, b in zip(after, before)}
    assert moves == {game.alien_speed}
    assert [a[1] for a in after] == [b[1] for b in before]


def test_at_the_edge_the_formation_steps_down_and_turns_round(game):
    start(game)
    rightmost = max(alien.rect.right for alien in game.alien_group)
    for alien in game.alien_group:  # push the formation right up to the edge
        alien.move(game_module.SCREEN_WIDTH - game_module.FORMATION_EDGE - rightmost)
    before = alien_positions(game)
    game.move_formation()
    after = alien_positions(game)
    assert game.formation_direction == -1
    assert [a[1] - b[1] for a, b in zip(after, before)] == [game_module.ALIEN_STEP_DOWN] * len(before)
    assert [a[0] for a in after] == [b[0] for b in before]


def test_aliens_reaching_the_player_end_the_game(game):
    start(game)
    lowest = max(alien.rect.bottom for alien in game.alien_group)
    for alien in game.alien_group:
        alien.move(0, game.player.rect.top - lowest)
    game.step(NO_KEYS)
    assert game.player.lives == 0
    assert game.state == GAME_OVER


def test_clearing_a_wave_brings_a_faster_one(game):
    start(game)
    speed, cooldown = game.alien_speed, game.alien_shot_cooldown
    score = game.player.score
    game.alien_group.empty()
    game.step(NO_KEYS)
    assert game.wave == 2
    assert game.player.score == score + game_module.WAVE_BONUS
    assert game.alien_speed == pytest.approx(speed * 1.15)
    assert game.alien_shot_cooldown == pytest.approx(cooldown * 0.9)
    assert len(game.alien_group) == game_module.ALIEN_ROWS * game_module.ALIEN_COLUMNS


def test_wave_speed_ups_are_capped(game):
    game.wave = 100
    assert game.alien_speed == game_module.ALIEN_MAX_SPEED
    assert game.alien_shot_cooldown == game_module.ALIEN_MIN_SHOT_COOLDOWN


def test_new_waves_start_at_the_top(game):
    def row_centres():
        # centres, not top edges: each alien picks a random picture, and they differ in height
        return sorted({alien.rect.centery for alien in game.alien_group})

    start(game)
    first_wave = row_centres()
    assert first_wave == [game_module.ALIEN_GRID_TOP + row * game_module.ALIEN_SPACING_Y
                          for row in range(game_module.ALIEN_ROWS)]
    run_frames(game, 400)  # long enough to step down a few times
    assert min(row_centres()) > min(first_wave)
    game.alien_group.empty()
    game.step(NO_KEYS)
    assert row_centres() == first_wave


# --- Explosions and invincibility --------------------------------------------------------

def test_explosions_play_through_their_pictures_then_disappear(game):
    name, size, hold = game_module.ALIEN_EXPLOSION
    explosion = game_module.Explosion(game, (100, 100), name, size, hold)
    pictures = game.animations[name]
    assert len(pictures) == 8
    assert all(picture.get_size() == (size, size) for picture in pictures)
    seen = [explosion.image]
    group = pygame.sprite.Group(explosion)
    for _ in range(len(pictures) * hold - 1):
        group.update()
        if explosion.image is not seen[-1]:
            seen.append(explosion.image)
    assert seen == pictures  # every picture, in order
    assert explosion.alive()
    group.update()
    assert not explosion.alive()


def test_player_explosion_lasts_longer_than_an_alien_explosion(game):
    def length(animation):
        name, _, hold = animation
        return len(game.animations[name]) * hold
    assert length(game_module.PLAYER_EXPLOSION) > length(game_module.ALIEN_EXPLOSION)


def test_a_hit_makes_the_ship_invincible_for_a_moment(game):
    start(game)
    hold_fire(game)
    game.player.hit()
    assert game.player.lives == game_module.PLAYER_LIVES - 1
    assert game.player.invincible
    game.player.hit()  # a second bullet straight away does nothing
    assert game.player.lives == game_module.PLAYER_LIVES - 1
    run_frames(game, int(game_module.INVINCIBLE_TIME / game_module.FRAME_MS) + 1)
    assert not game.player.invincible
    game.player.hit()
    assert game.player.lives == game_module.PLAYER_LIVES - 2


def test_alien_bullets_pass_through_an_invincible_ship(game):
    start(game)
    game.player.hit()
    bullet = game_module.AlienBullet(game, *game.player.rect.center)
    game.alien_bullet_group.add(bullet)
    game.alien_bullet_group.update()
    assert bullet.alive()
    assert game.player.lives == game_module.PLAYER_LIVES - 1


def test_the_ship_blinks_while_invincible(game):
    start(game)
    hold_fire(game)
    assert game.player_visible()
    game.player.hit()
    visibility = set()
    for _ in range(30):
        game.step(NO_KEYS)
        visibility.add(game.player_visible())
    assert visibility == {True, False}
    run_frames(game, 120)
    assert game.player_visible()


def test_alien_explosions_are_centred_on_the_alien(game):
    start(game)
    alien = game.alien_group.sprites()[0]
    bullet = game_module.Bullet(game, alien.rect.centerx, alien.rect.bottom + 2)
    game.bullet_group.add(bullet)
    game.bullet_group.update()
    explosion = game.alien_explosion_group.sprites()[0]
    assert explosion.rect.center == alien.rect.center


# --- Sound ----------------------------------------------------------------------------

def test_each_sound_is_set_to_its_level_times_the_volume():
    game = Game(volume=0.5)
    try:
        for name, sound in game.sounds.items():
            assert sound.get_volume() == pytest.approx(game_module.SOUND_LEVELS[name] * 0.5, abs=0.01)
        assert game.laser_sound.get_volume() < game.explosion_sound.get_volume()
    finally:
        pygame.quit()


def test_m_mutes_and_unmutes(game):
    game.handle_key(pygame.K_m)
    assert game.muted
    assert all(sound.get_volume() == 0 for sound in game.sounds.values())
    game.handle_key(pygame.K_m)
    assert not game.muted
    assert all(sound.get_volume() > 0 for sound in game.sounds.values())
