from typing import List

from .card import Card


class TurnState:
    """Tracks which single-use actions the current player has already taken this turn."""

    def __init__(self, player_index: int) -> None:
        self.player_index = player_index
        self.used_draw_up_to_3 = False
        self.used_steal = False
        self.used_draw_discard = False
        self.draw_up_to_3: List[Card] = []

    def reset(self, next_player_index: int) -> None:
        self.player_index = next_player_index
        self.used_draw_up_to_3 = False
        self.used_steal = False
        self.used_draw_discard = False
        self.draw_up_to_3 = []
