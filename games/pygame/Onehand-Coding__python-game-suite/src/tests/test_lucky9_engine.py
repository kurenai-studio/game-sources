import pytest

from python_game_suite.lucky9.terminal_engine import Lucky9, Player


def make_game(tmp_path):
    return Lucky9(Player("Test"), data_dir=tmp_path)


def test_create_deck_has_40_unique_cards():
    deck = Lucky9.createDeck()
    assert len(deck) == 40
    assert len(set(deck)) == 40
    assert {suit for _, suit in deck} == {
        chr(9830),
        chr(9829),
        chr(9824),
        chr(9827),
    }
    assert {rank for rank, _ in deck} == {
        "A",
        "2",
        "3",
        "4",
        "5",
        "6",
        "7",
        "8",
        "9",
        "10",
    }


def test_hand_values():
    player = Player("Test")
    player.hand = [("A", "s")]
    assert player.getHandValue() == 1
    player.hand = [("9", "s")]
    assert player.getHandValue() == 9
    player.hand = [("7", "s"), ("8", "h")]
    assert player.getHandValue() == 5
    player.hand = [("A", "s"), ("A", "h")]
    assert player.getHandValue() == 9
    player.hand = [("3", "s"), ("3", "h"), ("3", "d")]
    assert player.getHandValue() == 9
    player.hand = [("A", "s")]
    assert player.getHandValue(revealHandValue=False) == "??"


def test_invite_dealer_levels(tmp_path):
    game = make_game(tmp_path)
    game.level = 1
    assert game.inviteDealer().name == "Ace"
    game.level = 5
    dealer = game.inviteDealer()
    assert dealer.name == "Robin"
    assert dealer.money == 1_000_000
    game.level = 6
    with pytest.raises(ValueError):
        game.inviteDealer()


def test_advance_level(tmp_path):
    game = make_game(tmp_path)
    assert game.level == 1
    dealer = game.advance_level()
    assert game.level == 2
    assert dealer.name == "Joko"
    game.level = 5
    assert game.advance_level() is None
    assert game.level == 5


def test_settle_round_player_win(tmp_path):
    game = make_game(tmp_path)
    game.player.hand = [("9", "s")]
    game.dealer.hand = [("5", "s")]
    game.player.money = 10_000
    game.dealer.money = 100_000
    assert game.settle_round(1_000) == "player"
    assert game.player.money == 11_000
    assert game.dealer.money == 99_000


def test_settle_round_dealer_win(tmp_path):
    game = make_game(tmp_path)
    game.player.hand = [("5", "s")]
    game.dealer.hand = [("9", "s")]
    game.player.money = 10_000
    game.dealer.money = 100_000
    assert game.settle_round(1_000) == "dealer"
    assert game.player.money == 9_000
    assert game.dealer.money == 101_000


def test_settle_round_tie(tmp_path):
    game = make_game(tmp_path)
    game.player.hand = [("5", "s")]
    game.dealer.hand = [("5", "h")]
    game.player.money = 10_000
    game.dealer.money = 100_000
    assert game.settle_round(1_000) == "tie"
    assert game.player.money == 10_000
    assert game.dealer.money == 100_000


def test_debt_offer_available():
    player = Player("Test")
    player.money = 20_000
    player.debt = 10_000
    game = Lucky9.__new__(Lucky9)
    game.player = player
    assert game.debt_offer_available() is True
    player.debt = 9_999
    assert game.debt_offer_available() is False
    player.money = 10_000
    player.debt = 10_000
    assert game.debt_offer_available() is False


def test_settle_debt_paid():
    game = Lucky9.__new__(Lucky9)
    game.player = Player("Test")
    game.player.money = 50_000
    game.player.debt = 10_000
    assert game.settle_debt(True) == "paid"
    assert game.player.money == 40_000
    assert game.player.debt == 0


def test_settle_debt_refused():
    game = Lucky9.__new__(Lucky9)
    game.player = Player("Test")
    game.player.money = 50_000
    game.player.debt = 10_000
    assert game.settle_debt(False) == "refused"
    assert game.player.money == 50_000
    assert game.player.debt == 10_000
    assert game.player.timesRefusedToPay == 1


def test_settle_debt_penalty():
    game = Lucky9.__new__(Lucky9)
    game.player = Player("Test")
    game.player.money = 50_000
    game.player.debt = 10_000
    game.player.timesRefusedToPay = 3
    assert game.settle_debt(False) == "penalty"
    assert game.player.money == 30_000
    assert game.player.debt == 0
    assert game.player.timesRefusedToPay == 0


def test_save_load_list_delete_and_clear(tmp_path):
    game = make_game(tmp_path)
    game.player.name = "Alice"
    game.player.money = 12_345
    game.player.debt = 1_000
    game.level = 2
    game.saveData()
    assert "Alice" in game.getPlayerNames()

    loaded = make_game(tmp_path)
    loaded.player.name = "Alice"
    loaded.loadGameData("Alice")
    assert loaded.player.money == 12_345
    assert loaded.player.debt == 1_000
    assert loaded.level == 2

    loaded.deletePlayerData("Alice")
    assert "Alice" not in loaded.getPlayerNames()

    game.saveData()
    game.clearData()
    assert game.getPlayerNames() == []


def test_data_dir_override(tmp_path):
    game = make_game(tmp_path)
    assert game.dataFolder == tmp_path
    game.player.name = "Alice"
    game.saveData()
    assert list(tmp_path.glob("lucky_data*"))


def test_clear_data_keeps_unrelated_files(tmp_path):
    game = make_game(tmp_path)
    game.player.name = "Alice"
    game.saveData()
    keep = tmp_path / "keep.txt"
    keep.write_text("keep")

    game.clearData()

    assert keep.exists()
    assert not list(tmp_path.glob("lucky_data*"))
