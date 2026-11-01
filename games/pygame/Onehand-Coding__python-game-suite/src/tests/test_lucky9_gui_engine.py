from python_game_suite.lucky9.gui_engine import (
    Lucky9Session,
    Phase,
)

FILLER = [("5", "S")] * 30


def deck_with_top(*cards):
    return FILLER + list(reversed(cards))


def make_session(tmp_path, *cards):
    return Lucky9Session(
        player_name="Test",
        data_dir=tmp_path,
        deck_factory=lambda: deck_with_top(*cards),
    )


def test_initial_phase_and_money(tmp_path):
    session = make_session(tmp_path)
    assert session.phase is Phase.BETTING
    assert session.player.money == 10_000
    assert session.bet == 0
    assert session.can_bet is True


def test_invalid_bets_are_rejected(tmp_path):
    session = make_session(tmp_path)
    assert session.place_bet(999) is False
    assert session.place_bet(50_000) is False
    assert session.phase is Phase.BETTING


def test_place_bet_deals_two_cards_each(tmp_path):
    session = make_session(tmp_path, ("A", "S"), ("9", "S"), ("5", "S"), ("2", "S"))
    assert session.place_bet(1_000) is True
    assert session.phase is Phase.PLAYER_TURN
    assert session.player.hand == [("A", "S"), ("5", "S")]
    assert session.dealer.hand == [("9", "S"), ("2", "S")]
    assert session.bet == 1_000


def test_hit_adds_one_card_and_resolves(tmp_path):
    session = make_session(
        tmp_path,
        ("2", "S"),
        ("7", "S"),
        ("3", "S"),
        ("2", "S"),
        ("2", "S"),
    )
    session.place_bet(1_000)
    session.hit()
    assert len(session.player.hand) == 3
    assert session.phase is Phase.ROUND_OVER
    assert session.winner == "dealer"
    assert session.player.money == 9_000
    assert session.can_hit is False


def test_stand_draws_for_dealer_below_seven(tmp_path):
    session = make_session(
        tmp_path,
        ("8", "S"),
        ("2", "S"),
        ("1", "S"),
        ("2", "S"),
        ("3", "S"),
    )
    session.place_bet(1_000)
    session.stand()
    assert len(session.dealer.hand) == 3
    assert session.winner == "player"
    assert session.player.money == 11_000


def test_dealer_draw_is_capped_at_three_cards(tmp_path):
    session = make_session(
        tmp_path,
        ("5", "S"),
        ("2", "S"),
        ("5", "S"),
        ("2", "S"),
        ("2", "S"),
        ("2", "S"),
        ("2", "S"),
    )
    session.place_bet(1_000)
    session.stand()
    assert len(session.dealer.hand) == 3


def test_next_round_resets_table(tmp_path):
    session = make_session(tmp_path, ("9", "S"), ("7", "S"), ("1", "S"), ("2", "S"))
    session.place_bet(1_000)
    session.stand()
    session.next_round()
    assert session.phase is Phase.BETTING
    assert session.bet == 0
    assert session.player.hand == []
    assert session.dealer.hand == []


def test_dealer_broke_advances_level(tmp_path):
    session = make_session(tmp_path, ("9", "S"), ("5", "S"), ("9", "S"), ("2", "S"))
    session.place_bet(1_000)
    session.stand()
    session.dealer.money = 0
    session.next_round()
    assert session.level == 2
    assert session.dealer.name == "Joko"
    assert session.phase is Phase.BETTING


def test_level_five_dealer_broke_ends_game(tmp_path):
    session = make_session(tmp_path)
    session.game.level = 5
    session.dealer.money = 0
    session.phase = Phase.ROUND_OVER
    session.next_round()
    assert session.phase is Phase.GAME_OVER


def test_player_broke_ends_game(tmp_path):
    session = make_session(tmp_path)
    session.player.money = 500
    session.phase = Phase.ROUND_OVER
    session.next_round()
    assert session.phase is Phase.GAME_OVER


def test_restart_resets_progress(tmp_path):
    session = make_session(tmp_path)
    session.game.level = 4
    session.player.money = 1
    session.restart()
    assert session.level == 1
    assert session.player.money == 10_000
    assert session.phase is Phase.BETTING


def test_session_reshuffles_low_deck(tmp_path):
    session = make_session(tmp_path, ("A", "S"), ("9", "S"), ("5", "S"), ("2", "S"))
    session.game.deck = session.game.deck[-5:]
    session.place_bet(1_000)
    assert len(session.game.deck) >= 30


def test_hit_and_stand_are_ignored_in_betting_phase(tmp_path):
    session = make_session(tmp_path)
    session.hit()
    session.stand()
    assert session.phase is Phase.BETTING
    assert session.player.hand == []


def test_second_hit_is_ignored(tmp_path):
    session = make_session(
        tmp_path,
        ("2", "S"),
        ("9", "S"),
        ("3", "S"),
        ("2", "S"),
        ("2", "S"),
    )
    session.place_bet(1_000)
    session.hit()
    hand = list(session.player.hand)
    session.hit()
    assert session.player.hand == hand


def test_place_bet_is_ignored_outside_betting_phase(tmp_path):
    session = make_session(tmp_path, ("9", "S"), ("7", "S"), ("1", "S"), ("2", "S"))
    session.place_bet(1_000)
    assert session.place_bet(2_000) is False
    assert session.bet == 1_000
