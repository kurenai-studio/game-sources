from typing import List, Optional

from .card import Card


def is_sequence(cards: List[Card]) -> bool:
    """3+ cards, same colour, numbers forming an unbroken consecutive run."""
    if len(cards) < 3:
        return False

    colour = cards[0].colour
    for c in cards:
        if c.colour != colour:
            return False


    nums = sorted([int(c.number) for c in cards])
    for i in range(len(nums) - 1):
        if nums[i+1] != nums[i] + 1:
            return False

    return True


def is_set(cards: List[Card]) -> bool:
    """4+ cards, all the same number, no two cards sharing a colour."""
    if len(cards) < 4:
        return False


    num = cards[0].number
    for c in cards:
        if c.number != num:
            return False


    colours = []
    for c in cards:
        if c.colour in colours:
            return False
        colours.append(c.colour)

    return True


def is_valid_group(cards: List[Card]) -> Optional[str]:
    """Return "sequence", "set", or None if cards don't form a valid discard group."""
    if is_sequence(cards):
        return "sequence"
    if is_set(cards):
        return "set"
    return None
