from python_game_suite.lucky9.gui import Lucky9Gui
from python_game_suite.lucky9.gui_engine import Lucky9Session, Phase

FILLER = [("5", "S")] * 30


def deck_with_top(*cards):
    return FILLER + list(reversed(cards))


def make_gui(tmp_path, *cards):
    session = Lucky9Session(
        player_name="Test",
        data_dir=tmp_path,
        deck_factory=lambda: deck_with_top(*cards),
    )
    return Lucky9Gui(session), session


def test_render_all_phases(pygame_display, tmp_path):
    gui, session = make_gui(tmp_path, ("9", "S"), ("7", "S"), ("1", "S"), ("2", "S"))
    surface = pygame_display.Surface((960, 600))
    for phase in Phase:
        session.phase = phase
        gui.render(surface)


def test_keyboard_flow(pygame_display, tmp_path):
    gui, session = make_gui(tmp_path, ("9", "S"), ("7", "S"), ("1", "S"), ("2", "S"))
    surface = pygame_display.Surface((960, 600))
    gui.render(surface)

    event = pygame_display.event.Event(pygame_display.KEYDOWN, key=pygame_display.K_1)
    assert gui.handle_event(event) is True
    assert session.phase is Phase.PLAYER_TURN

    event = pygame_display.event.Event(pygame_display.KEYDOWN, key=pygame_display.K_g)
    assert gui.handle_event(event) is True
    assert session.phase is Phase.ROUND_OVER

    event = pygame_display.event.Event(pygame_display.KEYDOWN, key=pygame_display.K_n)
    assert gui.handle_event(event) is True
    assert session.phase is Phase.BETTING

    event = pygame_display.event.Event(pygame_display.KEYDOWN, key=pygame_display.K_q)
    assert gui.handle_event(event) is False


def test_mouse_chip_places_bet(pygame_display, tmp_path):
    gui, session = make_gui(tmp_path, ("9", "S"), ("7", "S"), ("1", "S"), ("2", "S"))
    surface = pygame_display.Surface((960, 600))
    gui.render(surface)
    rect = gui.buttons["bet:1000"]
    event = pygame_display.event.Event(
        pygame_display.MOUSEBUTTONDOWN, button=1, pos=rect.center
    )
    assert gui.handle_event(event) is True
    assert session.phase is Phase.PLAYER_TURN


def test_mouse_action_stand(pygame_display, tmp_path):
    gui, session = make_gui(tmp_path, ("9", "S"), ("7", "S"), ("1", "S"), ("2", "S"))
    surface = pygame_display.Surface((960, 600))
    session.place_bet(1_000)
    gui.render(surface)
    rect = gui.buttons["stand"]
    event = pygame_display.event.Event(
        pygame_display.MOUSEBUTTONDOWN, button=1, pos=rect.center
    )
    assert gui.handle_event(event) is True
    assert session.phase is Phase.ROUND_OVER


def test_restart_from_game_over(pygame_display, tmp_path):
    gui, session = make_gui(tmp_path)
    surface = pygame_display.Surface((960, 600))
    session.phase = Phase.GAME_OVER
    gui.render(surface)
    event = pygame_display.event.Event(pygame_display.KEYDOWN, key=pygame_display.K_r)
    assert gui.handle_event(event) is True
    assert session.phase is Phase.BETTING


def test_quit_event(pygame_display, tmp_path):
    gui, _ = make_gui(tmp_path)
    event = pygame_display.event.Event(pygame_display.QUIT)
    assert gui.handle_event(event) is False


def test_dealer_cards_reveal_after_round(pygame_display, tmp_path):
    gui, session = make_gui(tmp_path, ("9", "S"), ("7", "S"), ("1", "S"), ("2", "S"))
    session.place_bet(1_000)
    assert gui.dealer_revealed is False
    session.stand()
    assert gui.dealer_revealed is True


def test_hit_key_resolves_round(pygame_display, tmp_path):
    gui, session = make_gui(
        tmp_path, ("2", "S"), ("9", "S"), ("3", "S"), ("2", "S"), ("2", "S")
    )
    surface = pygame_display.Surface((960, 600))
    session.place_bet(1_000)
    gui.render(surface)
    event = pygame_display.event.Event(pygame_display.KEYDOWN, key=pygame_display.K_h)
    assert gui.handle_event(event) is True
    assert session.phase is Phase.ROUND_OVER
    assert len(session.player.hand) == 3


def test_hit_button_resolves_round(pygame_display, tmp_path):
    gui, session = make_gui(
        tmp_path, ("2", "S"), ("9", "S"), ("3", "S"), ("2", "S"), ("2", "S")
    )
    surface = pygame_display.Surface((960, 600))
    session.place_bet(1_000)
    gui.render(surface)
    rect = gui.buttons["hit"]
    event = pygame_display.event.Event(
        pygame_display.MOUSEBUTTONDOWN, button=1, pos=rect.center
    )
    assert gui.handle_event(event) is True
    assert session.phase is Phase.ROUND_OVER
    assert len(session.player.hand) == 3
