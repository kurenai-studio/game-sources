"""Stage 2 checks. Run: python3 test_stage2.py"""
import random

from cards import cards
from game import Game, Player
from play_cli import random_bot


def new_game(chips=(1000, 1000, 1000)):
    return Game([Player("You", chips[0], is_human=True),
                 Player("Shark", chips[1]), Player("Dealer", chips[2])])


def rig(game, holes, board):
    """Replace the random cards with known ones (call right after start_hand)."""
    for p, h in zip(game.players, holes):
        p.hole = cards(h)
    game.deck.cards = cards(board)


# 1. Blinds and turn order (3 players): You=button, Shark=SB, Dealer=BB, You act first
g = new_game()
g.start_hand()
you, shark, dealer = g.players
assert (shark.bet, dealer.bet, g.pot) == (10, 20, 30)
assert g.current_player is you
print("Blinds and first action OK")

# 2. Everyone folds to the big blind
g.act("fold")
g.act("fold")
assert g.hand_over and dealer.chips == 1010 and shark.chips == 990
print("Fold-to-big-blind OK")

# 3. Big blind gets the option to raise when everyone just calls
g = new_game()
g.start_hand()
g.act("call")          # You
g.act("call")          # Shark completes SB
assert g.current_player is g.players[2], "BB should get the option"
g.act("check")
assert g.street == "flop" and len(g.board) == 3
assert g.current_player is g.players[1], "SB acts first after the flop"
print("Big blind option and post-flop order OK")

# 4. Side pots: You all-in 100, Shark all-in 500, Dealer calls
g = new_game((100, 500, 1000))
g.start_hand()
rig(g, ["As Ad", "Ks Kd", "Qs Qd"], "2c 7d 9h Js 3s")
g.act("raise", 100)    # You all-in
g.act("raise", 500)    # Shark all-in
g.act("call")          # Dealer calls 500, board runs out automatically
you, shark, dealer = g.players
assert g.hand_over and len(g.board) == 5
assert (you.chips, shark.chips, dealer.chips) == (300, 800, 500), [p.chips for p in g.players]
print("Side pots OK: You win main pot 300, Shark wins side pot 800")

# 5. Uncalled bet is returned
g = new_game((100, 1000, 1000))
g.start_hand()
rig(g, ["2s 7d", "Ks Kd", "As Ad"], "2c 7c 9h Js 3s")   # You make two pair
g.act("call")              # You call 20
g.act("fold")              # Shark folds SB
g.act("raise", 1000)       # Dealer shoves
g.act("call")              # You call all-in for 80 more
you, shark, dealer = g.players
assert you.chips == 210 and dealer.chips == 900, [p.chips for p in g.players]
print("Uncalled bet returned OK")

# 6. Split pot with odd chip
g = new_game()
g.start_hand()
rig(g, ["2s 3d", "4s 5d", "6c 8c"], "Ah Kh Qh Jh Th")    # board is a royal flush
g.act("call"); g.act("call"); g.act("check")
for _ in range(3):
    g.act("check"); g.act("check"); g.act("check")
assert sorted(p.chips for p in g.players) == [1000, 1000, 1000]
print("Split pot OK")

# 7. Heads-up: button posts the small blind and acts first preflop
g = new_game((1000, 1000, 0))
g.start_hand()
btn = g.players[g.button]
assert btn.bet == 10 and g.current_player is btn
print("Heads-up blinds OK")

# 8. Stress test: thousands of random hands, chips must never appear or vanish
random.seed(1)
for game_no in range(300):
    g = new_game()
    while not g.game_over and g.hand_no < 200:
        g.start_hand()
        while not g.hand_over:
            g.act(*random_bot(g))
        total = sum(p.chips for p in g.players)
        assert total == 3000, f"chips leaked: {total} in game {game_no} hand {g.hand_no}"
        assert all(p.chips >= 0 for p in g.players)
print("Stress test OK: 300 random games, chips always add up to 3000")

print("\nStage 2 passed!")
