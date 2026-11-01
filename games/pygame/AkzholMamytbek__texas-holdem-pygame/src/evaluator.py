"""Hand evaluation: find the best 5-card hand out of 5-7 cards.

A hand's strength is a tuple (category, tiebreakers...). Python compares
tuples element by element, so a bigger tuple is simply a better hand.
"""
from collections import Counter
from itertools import combinations

from cards import RANK_NAMES

HIGH_CARD, PAIR, TWO_PAIR, TRIPS, STRAIGHT, FLUSH, FULL_HOUSE, QUADS, STRAIGHT_FLUSH = range(9)
CATEGORY_NAMES = ["High Card", "Pair", "Two Pair", "Three of a Kind", "Straight",
                  "Flush", "Full House", "Four of a Kind", "Straight Flush"]


def _straight_high(ranks):
    """Highest card of a straight in these 5 distinct ranks, or None. Handles A-2-3-4-5."""
    r = sorted(set(ranks), reverse=True)
    if len(r) != 5:
        return None
    if r[0] - r[4] == 4:
        return r[0]
    if r == [14, 5, 4, 3, 2]:   # the "wheel": ace plays low
        return 5
    return None


def score_five(hand):
    """Score exactly 5 cards."""
    ranks = [c.rank for c in hand]
    is_flush = len({c.suit for c in hand}) == 1
    straight = _straight_high(ranks)

    # Group by count, then rank: e.g. full house KKK22 -> [(13,3),(2,2)]
    groups = sorted(Counter(ranks).items(), key=lambda kv: (kv[1], kv[0]), reverse=True)
    counts = [g[1] for g in groups]
    ordered = [g[0] for g in groups]

    if straight and is_flush:
        return (STRAIGHT_FLUSH, straight)
    if counts[0] == 4:
        return (QUADS, *ordered)
    if counts == [3, 2]:
        return (FULL_HOUSE, *ordered)
    if is_flush:
        return (FLUSH, *sorted(ranks, reverse=True))
    if straight:
        return (STRAIGHT, straight)
    if counts[0] == 3:
        return (TRIPS, *ordered)
    if counts == [2, 2, 1]:
        return (TWO_PAIR, *ordered)
    if counts[0] == 2:
        return (PAIR, *ordered)
    return (HIGH_CARD, *ordered)


def best_hand(cards):
    """Return (score, best_five_cards) from 5-7 cards."""
    return max(((score_five(combo), combo) for combo in combinations(cards, 5)),
               key=lambda x: x[0])


def describe(score):
    """Human-readable name, e.g. 'Full House, Kings full of Twos'."""
    cat = score[0]
    name = CATEGORY_NAMES[cat]
    plural = lambda r: RANK_NAMES[r] + ("es" if r == 6 else "s")
    if cat in (STRAIGHT, STRAIGHT_FLUSH):
        if cat == STRAIGHT_FLUSH and score[1] == 14:
            return "Royal Flush"
        return f"{name}, {RANK_NAMES[score[1]]} high"
    if cat == QUADS:
        return f"Four {plural(score[1])}"
    if cat == FULL_HOUSE:
        return f"Full House, {plural(score[1])} full of {plural(score[2])}"
    if cat == FLUSH:
        return f"Flush, {RANK_NAMES[score[1]]} high"
    if cat == TRIPS:
        return f"Three {plural(score[1])}"
    if cat == TWO_PAIR:
        return f"Two Pair, {plural(score[1])} and {plural(score[2])}"
    if cat == PAIR:
        return f"Pair of {plural(score[1])}"
    return f"High Card, {RANK_NAMES[score[1]]}"
