from __future__ import annotations

from collections.abc import Callable
from enum import Enum
from pathlib import Path

from .terminal_engine import Dealer, Lucky9, Player

BET_OPTIONS = (1_000, 2_000, 5_000)


class Phase(str, Enum):
    BETTING = "betting"
    PLAYER_TURN = "player_turn"
    ROUND_OVER = "round_over"
    GAME_OVER = "game_over"


class Lucky9Session:
    def __init__(
        self,
        player_name: str = "Player",
        data_dir: Path | None = None,
        deck_factory: Callable[[], list] | None = None,
    ):
        self._deck_factory = deck_factory or Lucky9.createDeck
        self._data_dir = data_dir
        self._player_name = player_name
        self.game = self._new_game()
        self.phase = Phase.BETTING
        self.message = "Choose a bet to start."
        self.winner: str | None = None
        self.bet = 0

    def _new_game(self) -> Lucky9:
        game = Lucky9(Player(self._player_name), data_dir=self._data_dir)
        game.deck = list(self._deck_factory())
        return game

    @property
    def player(self) -> Player:
        return self.game.player

    @property
    def dealer(self) -> Dealer:
        return self.game.dealer

    @property
    def level(self) -> int:
        return self.game.level

    @property
    def can_bet(self) -> bool:
        return self.phase is Phase.BETTING and any(
            amount <= self.player.money for amount in BET_OPTIONS
        )

    @property
    def can_hit(self) -> bool:
        return self.phase is Phase.PLAYER_TURN and len(self.player.hand) == 2

    @property
    def can_stand(self) -> bool:
        return self.phase is Phase.PLAYER_TURN

    @property
    def can_next(self) -> bool:
        return self.phase is Phase.ROUND_OVER

    def place_bet(self, amount: int) -> bool:
        if self.phase is not Phase.BETTING:
            return False
        if amount not in BET_OPTIONS or amount > self.player.money:
            self.message = "That bet is not available."
            return False
        self._ensure_deck()
        self.bet = amount
        self.player.hand = []
        self.dealer.hand = []
        self.winner = None
        for _ in range(2):
            self.player.hand.append(self.game.deck.pop())
            self.dealer.hand.append(self.game.deck.pop())
        self.phase = Phase.PLAYER_TURN
        self.message = "Hit or stand?"
        return True

    def _ensure_deck(self) -> None:
        if len(self.game.deck) < 10:
            self.game.deck = list(self._deck_factory())

    def hit(self) -> None:
        if not self.can_hit:
            return
        self._ensure_deck()
        self.player.hand.append(self.game.deck.pop())
        self.player.drewCard = True
        self._resolve_round()

    def stand(self) -> None:
        if not self.can_stand:
            return
        self.player.drewCard = False
        self._resolve_round()

    def _resolve_round(self) -> None:
        self._ensure_deck()
        while int(self.dealer.getHandValue()) < 7 and len(self.dealer.hand) < 3:
            self.dealer.hand.append(self.game.deck.pop())
        self.winner = self.game.settle_round(self.bet)
        if self.winner == "player":
            self.message = f"You win {self.bet:,} pesos."
        elif self.winner == "dealer":
            self.message = f"The dealer wins {self.bet:,} pesos."
        else:
            self.message = "It's a tie."
        self.phase = Phase.ROUND_OVER

    def next_round(self) -> None:
        if self.phase is not Phase.ROUND_OVER:
            return
        self.player.hand = []
        self.dealer.hand = []
        self.bet = 0
        self.winner = None
        self.message = "Choose a bet to start."
        if self.dealer.money <= 0:
            new_dealer = self.game.advance_level()
            if new_dealer is None:
                self.phase = Phase.GAME_OVER
                self.message = "You beat every dealer. You win the game!"
                return
            self.message = f"Level {self.level}: {new_dealer.name} sits down."
        if self.player.money < min(BET_OPTIONS):
            self.phase = Phase.GAME_OVER
            self.message = "You are out of money. Restart to play again."
            return
        self.phase = Phase.BETTING

    def restart(self) -> None:
        self.game = self._new_game()
        self.phase = Phase.BETTING
        self.bet = 0
        self.winner = None
        self.message = "Choose a bet to start."
