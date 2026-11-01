"""Stage 1 checks. Run: python3 test_stage1.py"""
from cards import Deck, cards
from evaluator import best_hand, describe

# 1. Deck has 52 unique cards
deck = Deck()
assert len(deck) == 52 and len(set(deck.cards)) == 52
hand = deck.deal(2)
assert len(hand) == 2 and len(deck) == 50
print("Deck OK. Dealt:", hand)

# 2. Every hand category is recognized (7 cards each, like Hold'em)
examples = {
    "Royal Flush":                        "Ah Kh Qh Jh Th 2c 3d",
    "Straight Flush, Five high":          "Ah 2h 3h 4h 5h Kc Kd",
    "Four Queens":                        "Qs Qh Qd Qc 2s 3h 9d",
    "Full House, Kings full of Twos":     "Ks Kh Kd 2c 2s 7h 8d",
    "Flush, Ace high":                    "As 9s 7s 4s 2s Kh Kd",
    "Straight, Five high":                "Ah 2d 3c 4s 5h 9c Kd",
    "Three Sevens":                       "7s 7h 7d Ac 2s 9h Jd",
    "Two Pair, Jacks and Fours":          "Js Jh 4d 4c As 9h 2d",
    "Pair of Sixes":                      "6s 6h Ad Kc 9s 3h 2d",
    "High Card, Ace":                     "As Jh 9d 7c 4s 3h 2d",
}
for expected, text in examples.items():
    score, five = best_hand(cards(text))
    got = describe(score)
    assert got == expected, f"{text}: expected {expected!r}, got {got!r}"
    print(f"  {text:22} -> {got:32} best five: {five}")

# 3. Tiebreakers: kickers and ranking order
a, _ = best_hand(cards("As Ad Kc 9h 4s 3d 2c"))   # pair of aces, K kicker
b, _ = best_hand(cards("Ah Ac Qc 9d 4h 3s 2h"))   # pair of aces, Q kicker
assert a > b, "King kicker should beat Queen kicker"
wheel, _ = best_hand(cards("Ah 2d 3c 4s 5h 9c Kd"))
six_high, _ = best_hand(cards("6h 2d 3c 4s 5h 9c Kd"))
assert six_high > wheel, "6-high straight beats A-5 wheel"
print("Tiebreakers OK.")
print("\nStage 1 passed!")
