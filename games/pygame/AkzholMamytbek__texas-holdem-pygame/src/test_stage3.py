"""Stage 3 checks. Run: python3 test_stage3.py  (takes ~30 seconds)"""
import random
import time

from ai import estimate_equity, make_opponents
from cards import cards
from game import Game, Player
from play_cli import random_bot

random.seed(7)

# 1. Equity estimates match known poker math (within simulation noise)
checks = [
    ("As Ad", "", 1, 0.85),    # pocket aces vs one random hand: ~85%
    ("7c 2d", "", 1, 0.35),    # the worst starting hand: ~35%
    ("As Ad", "", 2, 0.73),    # aces vs two players: ~73%
    ("Ah Kh", "Qh Jh Th", 2, 1.0),  # flopped royal flush: can't lose
]
for hole, board, opps, expected in checks:
    eq = estimate_equity(cards(hole), cards(board), opps, sims=2000)
    print(f"  {hole} on [{board or '-'}] vs {opps}: {eq:.0%} (expected ~{expected:.0%})")
    assert abs(eq - expected) < 0.04
print("Equity OK")

# 2. Speed: one decision should feel instant
bots = make_opponents()
g = Game([Player("You", 1000, True), Player("Shark", 1000), Player("Dealer", 1000)])
g.start_hand()
g.act("call")
start = time.time()
bots["Shark"].decide(g)
print(f"Decision time: {time.time() - start:.2f}s")


# 3. Personalities: how often does each bot voluntarily play a hand preflop (VPIP)?
#    And how often does each one bet/raise when it gets the chance (aggression)?
def play_games(n_hands, sims=120):
    bots = make_opponents(sims)
    stats = {name: {"hands": 0, "vpip": 0, "raises": 0, "actions": 0, "chips": 0}
             for name in ("You", "Shark", "Dealer")}
    hands = 0
    while hands < n_hands:
        g = Game([Player("You", 1000, True), Player("Shark", 1000), Player("Dealer", 1000)])
        while not g.game_over and hands < n_hands:
            g.start_hand()
            hands += 1
            played = set()
            for p in g.players:
                if p.in_hand:
                    stats[p.name]["hands"] += 1
            while not g.hand_over:
                p = g.current_player
                action, amount = random_bot(g) if p.is_human else bots[p.name].decide(g)
                if g.street == "preflop" and action in ("call", "raise"):
                    played.add(p.name)
                stats[p.name]["actions"] += 1
                stats[p.name]["raises"] += action == "raise"
                g.act(action, amount)
            for name in played:
                stats[name]["vpip"] += 1
        for p in g.players:
            stats[p.name]["chips"] += p.chips - 1000
    return stats


start = time.time()
stats = play_games(600)
print(f"\n600 hands vs a random bot ({time.time() - start:.0f}s):")
print(f"  {'':8}{'plays hands':>12}{'raises':>9}{'net chips':>11}")
for name, s in stats.items():
    print(f"  {name:8}{s['vpip'] / s['hands']:>12.0%}{s['raises'] / s['actions']:>9.0%}{s['chips']:>11}")

c, d, r = stats["Shark"], stats["Dealer"], stats["You"]
assert d["vpip"] / d["hands"] > c["vpip"] / c["hands"], "Dealer should play more hands than Shark"
assert d["raises"] / d["actions"] > c["raises"] / c["actions"], "Dealer should raise more than Shark"
assert c["chips"] + d["chips"] > 0, "the AIs should beat a random player"
print("Personalities OK: Dealer is looser and more aggressive, both beat random play")

print("\nStage 3 passed!")
