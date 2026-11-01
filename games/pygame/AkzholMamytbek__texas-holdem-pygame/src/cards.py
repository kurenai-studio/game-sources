"""Cards and deck."""
import random

RANKS = "23456789TJQKA"          # index 0..12 -> rank value 2..14
SUITS = "shdc"                   # spades, hearts, diamonds, clubs
SUIT_SYMBOLS = {"s": "♠", "h": "♥", "d": "♦", "c": "♣"}
RANK_NAMES = {2: "Two", 3: "Three", 4: "Four", 5: "Five", 6: "Six", 7: "Seven",
              8: "Eight", 9: "Nine", 10: "Ten", 11: "Jack", 12: "Queen",
              13: "King", 14: "Ace"}


class Card:
    __slots__ = ("rank", "suit")

    def __init__(self, rank, suit):
        self.rank = rank   # int 2..14
        self.suit = suit   # one of "shdc"

    @classmethod
    def from_str(cls, text):
        """Card.from_str('Ah') -> Ace of hearts."""
        return cls(RANKS.index(text[0].upper()) + 2, text[1].lower())

    @property
    def is_red(self):
        return self.suit in "hd"

    def __str__(self):
        return RANKS[self.rank - 2] + SUIT_SYMBOLS[self.suit]

    __repr__ = __str__

    def __eq__(self, other):
        return isinstance(other, Card) and (self.rank, self.suit) == (other.rank, other.suit)

    def __hash__(self):
        return hash((self.rank, self.suit))


class Deck:
    def __init__(self):
        self.cards = [Card(r, s) for s in SUITS for r in range(2, 15)]
        random.shuffle(self.cards)

    def deal(self, n=1):
        dealt, self.cards = self.cards[:n], self.cards[n:]
        return dealt

    def __len__(self):
        return len(self.cards)


def cards(text):
    """Helper for tests: cards('Ah Kd') -> [A♥, K♦]."""
    return [Card.from_str(t) for t in text.split()]
