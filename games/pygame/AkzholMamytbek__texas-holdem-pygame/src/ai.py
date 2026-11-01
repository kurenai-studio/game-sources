"""AI opponents.

Every decision has two steps:
  1. How good is my hand?  -> estimate_equity(): Monte Carlo simulation
  2. What do I do about it? -> Personality settings turn equity into an action

The AI only sees what a human would: its own two cards and the board.
"""
import random
from dataclasses import dataclass
from itertools import combinations

from cards import Card, SUITS
from evaluator import score_five

FULL_DECK = [Card(r, s) for s in SUITS for r in range(2, 15)]


def _best_score(cards):
    return max(score_five(c) for c in combinations(cards, 5))


def estimate_equity(hole, board, n_opponents, sims=300):
    """Chance of winning (ties count partially) against n random hands.

    Deal the opponents random cards and finish the board randomly, see who
    wins, repeat `sims` times. Win share ~= equity.
    """
    known = set(hole) | set(board)
    remaining = [c for c in FULL_DECK if c not in known]
    need_board = 5 - len(board)
    won = 0.0
    for _ in range(sims):
        draw = random.sample(remaining, need_board + 2 * n_opponents)
        full_board = board + draw[:need_board]
        mine = _best_score(hole + full_board)
        ties, beaten = 0, False
        for k in range(n_opponents):
            opp = draw[need_board + 2 * k: need_board + 2 * k + 2]
            s = _best_score(opp + full_board)
            if s > mine:
                beaten = True
                break
            if s == mine:
                ties += 1
        if not beaten:
            won += 1.0 / (ties + 1)
    return won / sims


@dataclass
class Personality:
    name: str
    # Strength is "relative equity": equity x number of players in the hand.
    # 1.0 means an average hand for this many opponents, 2.0 means twice the average.
    value_raise: float     # raise for value when strength is at least this
    aggression: float      # chance of actually raising when strong (else just call/check)
    call_margin: float     # extra equity needed above pot odds to call (negative = calls light)
    bluff: float           # chance to bet/raise with a weak hand
    bet_size: float        # typical bet as a fraction of the pot
    preflop_min: float     # weakest starting-hand strength it will pay to play
    style: str


SHARK = Personality("Shark", value_raise=1.45, aggression=0.75, call_margin=0.04,
                     bluff=0.06, bet_size=0.65, preflop_min=1.1,
                     style="tight, patient, rarely bluffs")
DEALER = Personality("Dealer", value_raise=1.2, aggression=0.85, call_margin=-0.06,
                     bluff=0.22, bet_size=0.8, preflop_min=0.85,
                     style="loose, aggressive, bluffs a lot")


def _round_chips(x, step=5):
    return int(round(x / step) * step)


class AIPlayer:
    def __init__(self, personality, sims=300):
        self.p = personality
        self.sims = sims
        self.last_equity = None   # handy for debugging / a "show AI thinking" option

    def decide(self, game):
        me = game.current_player
        legal = game.legal_actions()
        n_opp = sum(1 for q in game.players if q.contending and q is not me)
        equity = estimate_equity(me.hole, game.board, n_opp, self.sims)
        self.last_equity = equity
        strength = equity * (n_opp + 1)

        to_call = legal["to_call"]
        pot = game.pot
        pot_odds = to_call / (pot + to_call) if to_call else 0.0
        roll = random.random()

        # 1. Strong hand -> raise for value (sometimes slow-play by just calling)
        if strength >= self.p.value_raise and legal["can_raise"] and roll < self.p.aggression:
            return "raise", self._raise_size(game, legal, strength)

        # 2. Nothing to call -> check, or bluff now and then
        if legal["can_check"]:
            if legal["can_raise"] and random.random() < self.p.bluff:
                return "raise", self._raise_size(game, legal, 1.0)
            return "check", 0

        # 3. Facing a bet -> call if the hand is playable and the price is right
        playable = game.street != "preflop" or strength >= self.p.preflop_min
        if playable and equity >= pot_odds + self.p.call_margin:
            return "call", 0

        # 4. Bad price -> occasionally bluff-raise, otherwise fold
        if legal["can_raise"] and random.random() < self.p.bluff / 2:
            return "raise", self._raise_size(game, legal, 1.0)
        return "fold", 0

    def _raise_size(self, game, legal, strength):
        me = game.current_player
        if game.street == "preflop":
            # standard open: 3 big blinds, plus one per caller; re-raise ~3x the bet
            callers = sum(1 for q in game.players if q.bet == game.current_bet and q is not me)
            if game.current_bet <= game.bb:
                target = 3 * game.bb + max(0, callers - 1) * game.bb
            else:
                target = 3 * game.current_bet
        else:
            frac = self.p.bet_size * random.uniform(0.75, 1.25)
            if strength > 2.0:
                frac *= 1.3            # very strong: build a bigger pot
            target = game.current_bet + frac * (game.pot + legal["to_call"])
        target = _round_chips(target)
        # if the raise would commit most of our stack, just go all-in
        if target >= 0.6 * (me.chips + me.bet):
            target = legal["max_raise_to"]
        return max(legal["min_raise_to"], min(target, legal["max_raise_to"]))


def make_opponents(sims=300):
    """Seat name -> AIPlayer."""
    return {"Shark": AIPlayer(SHARK, sims), "Dealer": AIPlayer(DEALER, sims)}


# ---------- table talk ----------
# Lines depend only on the action, never on hand strength, so they don't give hands away.
CHAT = {
    "Shark": {
        "chance": 0.25,
        "raise": ["I'll raise.", "Let's make it interesting.", "Raise."],
        "call": ["I'll call.", "Call."],
        "check": ["Check."],
        "fold": ["Not this one.", "I'll let it go."],
        "win": ["Good hand.", "Thanks for the chips.", "The math worked out."],
        "lose": ["Well played.", "Nice hand."],
    },
    "Dealer": {
        "chance": 0.5,
        "raise": ["Pump it up!", "You scared?", "Raise! Obviously.", "Let's gamble!"],
        "call": ["I'm not going anywhere.", "Call. Whatcha got?"],
        "check": ["Check... for now."],
        "fold": ["Ugh. Fine.", "Folding... this time."],
        "win": ["Ka-ching!", "Read 'em and weep!", "The house always wins!"],
        "lose": ["Lucky river...", "Rigged deck!", "I let you have that one."],
    },
}


def table_talk(name, event, always=False):
    """A random line for this event, or None (most actions are silent)."""
    lines = CHAT.get(name, {})
    if event not in lines or (not always and random.random() > lines["chance"]):
        return None
    return random.choice(lines[event])
