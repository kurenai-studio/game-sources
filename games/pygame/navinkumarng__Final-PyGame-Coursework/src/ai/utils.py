from typing import List, Optional

from core.card import Card
from core.groups import is_valid_group


def find_first_group(hand: List[Card]) -> Optional[List[Card]]:
    """Return the first valid sequence/set in hand (checking 3-card combos, then 4-card combos), or None."""
    n = len(hand)
    for i in range(n):
        for j in range(i + 1, n):
            for k in range(j + 1, n):
                cards = [hand[i], hand[j], hand[k]]
                if is_valid_group(cards) is not None:
                    return cards

    for i in range(n):
        for j in range(i + 1, n):
            for k in range(j + 1, n):
                for l in range(k + 1, n):
                    cards = [hand[i], hand[j], hand[k], hand[l]]
                    if is_valid_group(cards) is not None:
                        return cards
    return None
