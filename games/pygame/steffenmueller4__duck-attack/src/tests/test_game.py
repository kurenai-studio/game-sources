import pygame

from duck_attack import settings
from duck_attack.duck import Duck
from duck_attack.game import Game, State
from duck_attack.highscores import HighScore


def playing_game(name="Tester"):
    """A game that is past the name entry, in a running round."""
    game = Game()
    game.player_name = name
    game.start_round()
    return game


def test_game_runs_a_few_frames():
    game = playing_game()
    assert game.screen.get_size() == (settings.SCREEN_WIDTH, settings.SCREEN_HEIGHT)
    assert game.background.get_size() == game.screen.get_size()
    game.run(max_frames=3)
    assert len(game.ducks) == 1
    assert not pygame.get_init()


def test_escape_stops_game():
    game = playing_game()
    pygame.event.post(pygame.event.Event(pygame.KEYDOWN, key=pygame.K_ESCAPE))
    game.run(max_frames=100)
    assert not game.running


def test_left_click_shoots_duck_and_next_one_starts():
    game = playing_game()
    game.update(1.0)
    (duck,) = game.ducks
    x, y = duck.mask.outline()[0]
    pygame.event.post(
        pygame.event.Event(pygame.MOUSEBUTTONDOWN, button=1, pos=(duck.rect.x + x, duck.rect.y + y))
    )
    game.handle_events()
    assert duck.shot
    assert game.score == duck.points
    game.update(0.01)
    assert len(game.ducks) == 2  # the falling one plus a fresh one
    pygame.quit()


def test_missed_shot_hits_nothing_and_costs_points():
    game = playing_game()
    game.update(1.0)
    assert not game.shoot((settings.SCREEN_WIDTH - 1, settings.SCREEN_HEIGHT - 1))
    assert game.score == -settings.MISS_PENALTY
    pygame.quit()


def test_miss_penalty_applies_per_miss_after_hits():
    game = playing_game()
    game.update(1.0)
    (duck,) = game.ducks
    x, y = duck.mask.outline()[0]
    assert game.shoot((duck.rect.x + x, duck.rect.y + y))
    for _ in range(2):
        assert not game.shoot((settings.SCREEN_WIDTH - 1, settings.SCREEN_HEIGHT - 1))
    assert game.score == duck.points - 2 * settings.MISS_PENALTY
    pygame.quit()


def test_each_hit_adds_points():
    game = playing_game()
    expected = 0
    for _ in range(3):
        game.update(1.0)
        duck = next(d for d in game.ducks if not d.shot)
        x, y = duck.mask.outline()[0]
        assert game.shoot((duck.rect.x + x, duck.rect.y + y))
        expected += duck.points
    assert game.score == expected
    pygame.quit()


def test_closer_duck_in_front_is_hit_first():
    game = playing_game()
    far = Duck(game.duck_image, y=100, scale=0.5)
    near = Duck(game.duck_image, y=100, scale=1.0)
    game.ducks.add(near, far)
    near.rect.center = far.rect.center
    assert game.shoot(near.rect.center)
    assert near.shot and not far.shot
    pygame.quit()


def test_round_ends_after_duration_and_records_highscore(isolated_highscores):
    game = playing_game()
    game.score = 120
    game.update(settings.ROUND_DURATION - 0.5)
    assert game.state is State.PLAYING
    game.update(1.0)
    assert game.state is State.ROUND_OVER
    assert not game.ducks
    assert game.highscores.entries[0] == HighScore(120, game.round_started, "Tester")
    assert game.highscore_rank == 0
    assert isolated_highscores.exists()
    pygame.quit()


def test_score_screen_then_highscores_then_click_restarts():
    game = playing_game()
    game.score = 50
    game.update(settings.ROUND_DURATION)
    game.draw()
    game.update(settings.SCORE_SCREEN_DURATION - 0.5)
    assert game.state is State.ROUND_OVER
    game.update(1.0)
    assert game.state is State.HIGHSCORES
    game.draw()

    pygame.event.post(pygame.event.Event(pygame.MOUSEBUTTONDOWN, button=1, pos=(10, 10)))
    game.handle_events()
    assert game.state is State.NAME_ENTRY
    assert game.player_name == "Tester"  # remembered, no need to type it again
    game.draw()

    pygame.event.post(pygame.event.Event(pygame.MOUSEBUTTONDOWN, button=1, pos=(10, 10)))
    game.handle_events()
    assert game.state is State.PLAYING
    assert game.score == 0
    assert game.time_left == settings.ROUND_DURATION
    pygame.quit()


def test_clicks_do_not_shoot_after_round_is_over():
    game = playing_game()
    game.update(1.0)
    game.update(settings.ROUND_DURATION)
    pygame.event.post(pygame.event.Event(pygame.MOUSEBUTTONDOWN, button=1, pos=(10, 10)))
    game.handle_events()
    assert game.state is State.ROUND_OVER
    pygame.quit()


def test_every_shot_plays_a_sound_hit_or_miss():
    game = playing_game()
    played = []
    game.shot_sound.play = lambda: played.append(True)
    game.update(1.0)
    game.shoot((settings.SCREEN_WIDTH - 1, settings.SCREEN_HEIGHT - 1))  # miss
    (duck,) = game.ducks
    x, y = duck.mask.outline()[0]
    game.shoot((duck.rect.x + x, duck.rect.y + y))  # hit
    assert len(played) == 2
    pygame.quit()


def test_no_shot_sound_after_round_is_over():
    game = playing_game()
    played = []
    game.shot_sound.play = lambda: played.append(True)
    game.update(settings.ROUND_DURATION)
    pygame.event.post(pygame.event.Event(pygame.MOUSEBUTTONDOWN, button=1, pos=(10, 10)))
    game.handle_events()
    assert not played
    pygame.quit()


def _type(game, text):
    pygame.event.post(pygame.event.Event(pygame.TEXTINPUT, text=text))
    game.handle_events()


def _press(game, key):
    pygame.event.post(pygame.event.Event(pygame.KEYDOWN, key=key))
    game.handle_events()


def test_game_starts_with_name_entry_and_enter_starts_the_round(isolated_player_name):
    game = Game()
    assert game.state is State.NAME_ENTRY
    assert game.player_name == ""
    game.draw()
    _press(game, pygame.K_RETURN)
    assert game.state is State.NAME_ENTRY  # an empty name doesn't start a round
    _type(game, "Ann")
    _type(game, "a")
    _press(game, pygame.K_BACKSPACE)
    game.draw()
    _press(game, pygame.K_RETURN)
    assert game.state is State.PLAYING
    assert game.player_name == "Ann"
    assert isolated_player_name.read_text() == "Ann"
    pygame.quit()


def test_name_is_remembered_between_sessions(isolated_player_name):
    isolated_player_name.write_text("Bob")
    game = Game()
    assert game.player_name == "Bob"
    pygame.event.post(pygame.event.Event(pygame.MOUSEBUTTONDOWN, button=1, pos=(10, 10)))
    game.handle_events()
    assert game.state is State.PLAYING
    pygame.quit()


def test_name_is_trimmed_and_limited_in_length():
    game = Game()
    _type(game, "  ")
    assert game.player_name == ""
    _type(game, "x" * (settings.PLAYER_NAME_MAX_LENGTH + 5))
    assert len(game.player_name) == settings.PLAYER_NAME_MAX_LENGTH
    pygame.quit()


def test_no_shooting_during_name_entry():
    game = Game()
    game.update(1.0)
    assert not game.ducks
    pygame.event.post(pygame.event.Event(pygame.MOUSEBUTTONDOWN, button=1, pos=(10, 10)))
    game.handle_events()  # empty name: the click neither shoots nor starts
    assert game.state is State.NAME_ENTRY
    assert game.score == 0
    pygame.quit()
