import random
from typing import List, Optional

from .card import Card


class Deck:
    def __init__(self) -> None:
        self.cards: List[Card] = []
        self.create_full_deck()
        self.shuffle()

    def create_full_deck(self) -> None:
        """Build the 90-card deck: 5 colours x numbers 1-9, two of each."""
        colours = ["red", "green", "yellow", "blue", "black"]
        for colour in colours:
            for number in range(1, 10):
                self.cards.append(Card(colour, number))
                self.cards.append(Card(colour, number))

    def shuffle(self) -> None:
        random.shuffle(self.cards)

    def draw(self, n: int) -> List[Card]:
        drawn = []
        for _ in range(min(n, len(self.cards))):
            drawn.append(self.cards.pop())
        return drawn

    def draw_one(self) -> Optional[Card]:
        if len(self.cards) > 0:
            return self.cards.pop()
        return None

    def add_and_shuffle(self, cards: List[Card]) -> None:
        self.cards.extend(cards)
        self.shuffle()
