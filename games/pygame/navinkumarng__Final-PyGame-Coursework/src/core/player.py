import random
from typing import List, Optional, Union

from .card import Card


class Player:
    def __init__(self, name: str, is_human: bool = True, ai_type: Optional[str] = None) -> None:
        self.name = name
        self.is_human = is_human
        self.ai_type = ai_type
        self.hand: List[Card] = []

    def hand_size(self) -> int:
        return len(self.hand)

    def add_card(self, card: Card) -> None:
        self.hand.append(card)

    def add_cards(self, cards: List[Card]) -> None:
        for c in cards:
            self.hand.append(c)

    def remove_card(self, card: Card) -> None:
        if card in self.hand:
            self.hand.remove(card)

    def can_take_more_cards(self, amount: int) -> bool:
        return len(self.hand) + amount <= 20

    def steal_from(self, target_player: "Player") -> Union[Card, str]:
        """Take one random card from target_player's hand, or an error string if the steal isn't possible."""
        if len(target_player.hand) == 0:
            return "Target has no cards"
        if not self.can_take_more_cards(1):
            return "Hand limit exceeded"

        card = random.choice(target_player.hand)
        target_player.remove_card(card)
        self.add_card(card)
        return card
