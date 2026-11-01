"""Texas Hold'em game engine. No graphics, no AI: just the rules.

How it's driven (the terminal script and the pygame GUI both do this):
    game.start_hand()
    while not game.hand_over:
        player = game.current_player
        action, amount = <ask the human or the AI>
        game.act(action, amount)
    # game.results now says who won what

Actions: "fold", "check", "call", "raise" (amount = total to raise TO this street).
A bet into an unopened pot is also a "raise" (from 0).
"""
from cards import Deck
from evaluator import best_hand, describe

STREETS = ["preflop", "flop", "turn", "river"]


class Player:
    def __init__(self, name, chips, is_human=False):
        self.name = name
        self.chips = chips
        self.is_human = is_human
        self.reset_for_hand()

    def reset_for_hand(self):
        self.hole = []
        self.in_hand = False      # dealt into this hand (had chips at the start)
        self.folded = False
        self.all_in = False
        self.bet = 0              # chips put in during the current street
        self.total_bet = 0        # chips put in during the whole hand
        self.score = None         # filled in at showdown
        self.best_five = None
        self.last_action = ""

    @property
    def contending(self):
        """Still has a claim on the pot."""
        return self.in_hand and not self.folded

    @property
    def can_act(self):
        """Still able to make betting decisions."""
        return self.contending and not self.all_in

    def verb(self, third_person):
        """'raises' -> 'raise' for You, so the log reads 'You raise' / 'Shark raises'."""
        if not self.is_human:
            return third_person
        return {"has": "have"}.get(third_person, third_person[:-1])

    def put_in(self, amount):
        amount = min(amount, self.chips)
        self.chips -= amount
        self.bet += amount
        self.total_bet += amount
        if self.chips == 0:
            self.all_in = True
        return amount


class Game:
    def __init__(self, players, small_blind=10, big_blind=20):
        self.players = players
        self.sb = small_blind
        self.bb = big_blind
        self.button = -1          # first hand moves it to seat 0
        self.hand_no = 0
        self.log = []             # every message ever, GUI/terminal read new ones
        self.board = []
        self.street = None
        self.current = None       # index of the player whose turn it is
        self.hand_over = True
        self.results = []         # [(player, amount_won, hand_description_or_None)]

    # ---------- helpers ----------
    def say(self, msg):
        self.log.append(msg)

    def _next(self, i, pred):
        """Next seat index after i (clockwise) where pred(index) is true."""
        n = len(self.players)
        for k in range(1, n + 1):
            j = (i + k) % n
            if pred(j):
                return j
        return None

    @property
    def pot(self):
        return sum(p.total_bet for p in self.players)

    @property
    def current_player(self):
        return None if self.current is None else self.players[self.current]

    @property
    def game_over(self):
        human_broke = any(p.is_human and p.chips == 0 for p in self.players)
        return human_broke or sum(p.chips > 0 for p in self.players) <= 1

    # ---------- starting a hand ----------
    def start_hand(self):
        assert self.hand_over and not self.game_over
        self.hand_no += 1
        self.deck = Deck()
        self.board = []
        self.results = []
        self.hand_over = False
        self.street = "preflop"
        for p in self.players:
            p.reset_for_hand()
            p.in_hand = p.chips > 0

        seated = lambda j: self.players[j].in_hand
        self.button = self._next(self.button, seated)
        if sum(p.in_hand for p in self.players) == 2:
            sb_i = self.button                 # heads-up: button is the small blind
        else:
            sb_i = self._next(self.button, seated)
        bb_i = self._next(sb_i, seated)

        self.say(f"=== Hand #{self.hand_no} — {self.players[self.button].name} {self.players[self.button].verb('has')} the button ===")
        for i, blind, label in ((sb_i, self.sb, "small"), (bb_i, self.bb, "big")):
            p = self.players[i]
            paid = p.put_in(blind)
            p.last_action = f"{label[0].upper()}B {paid}"
            self.say(f"{p.name} {p.verb('posts')} {label} blind {paid}" + (" (all-in)" if p.all_in else ""))

        for _ in range(2):
            for p in self.players:
                if p.in_hand:
                    p.hole += self.deck.deal(1)

        self.current_bet = max(p.bet for p in self.players)
        self.min_raise = self.bb
        self.to_act = {j for j, p in enumerate(self.players) if p.can_act}
        self.current = bb_i                     # action starts left of the big blind
        self._advance()

    # ---------- what can the current player do? ----------
    def legal_actions(self):
        p = self.current_player
        to_call = min(self.current_bet - p.bet, p.chips)
        max_to = p.bet + p.chips                # everything = all-in
        min_to = min(self.current_bet + self.min_raise, max_to)
        return {
            "to_call": to_call,
            "can_check": to_call == 0,
            "can_raise": max_to > self.current_bet,
            "min_raise_to": min_to,
            "max_raise_to": max_to,
            "is_bet": self.current_bet == 0,    # label "Bet" instead of "Raise"
        }

    # ---------- taking an action ----------
    def act(self, action, amount=0):
        assert not self.hand_over
        i, p = self.current, self.current_player
        legal = self.legal_actions()

        if action == "check" and not legal["can_check"]:
            action = "call"                     # be forgiving: treat as call
        if action == "raise" and not legal["can_raise"]:
            action = "call"
        if action == "call" and legal["can_check"]:
            action = "check"                    # "calling" nothing is a check

        if action == "fold":
            p.folded = True
            p.last_action = "Fold"
            self.say(f"{p.name} {p.verb('folds')}")
        elif action == "check":
            p.last_action = "Check"
            self.say(f"{p.name} {p.verb('checks')}")
        elif action == "call":
            paid = p.put_in(legal["to_call"])
            p.last_action = f"Call {paid}"
            self.say(f"{p.name} {p.verb('calls')} {paid}" + (" (all-in)" if p.all_in else ""))
        elif action == "raise":
            to = max(legal["min_raise_to"], min(int(amount), legal["max_raise_to"]))
            raise_size = to - self.current_bet
            p.put_in(to - p.bet)
            if raise_size >= self.min_raise:    # a short all-in doesn't change the min raise
                self.min_raise = raise_size
            word = p.verb("bets") if legal["is_bet"] else p.verb("raises") + " to"
            p.last_action = f"{'Bet' if legal['is_bet'] else 'Raise'} {to}"
            self.say(f"{p.name} {word} {to}" + (" (all-in)" if p.all_in else ""))
            self.current_bet = to
            # everyone else still able to act must respond to the raise
            self.to_act = {j for j, q in enumerate(self.players) if q.can_act and j != i}
        else:
            raise ValueError(f"unknown action {action!r}")

        self.to_act.discard(i)
        self._advance()

    # ---------- moving the hand forward ----------
    def _advance(self):
        contenders = [p for p in self.players if p.contending]
        if len(contenders) == 1:
            self._win_uncontested(contenders[0])
            return
        # If at most one player can still act and they've matched the bet,
        # there's nobody left to bet against: betting is over.
        actors = [j for j, p in enumerate(self.players) if p.can_act]
        if len(actors) <= 1 and all(self.players[j].bet >= self.current_bet for j in actors):
            self.to_act.clear()

        if self.to_act:
            self.current = self._next(self.current, lambda j: j in self.to_act)
        else:
            self._next_street()

    def _next_street(self):
        for p in self.players:
            p.bet = 0
        self.current_bet = 0
        self.min_raise = self.bb
        if self.street == "river":
            self._showdown()
            return
        self.street = STREETS[STREETS.index(self.street) + 1]
        self.board += self.deck.deal(3 if self.street == "flop" else 1)
        self.say(f"--- {self.street.title()}: {' '.join(map(str, self.board))} ---")
        for p in self.players:
            if p.can_act:
                p.last_action = ""
        self.to_act = {j for j, p in enumerate(self.players) if p.can_act}
        self.current = self.button              # first to act is left of the button
        self._advance()

    # ---------- ending a hand ----------
    def _finish(self):
        self.hand_over = True
        self.current = None

    def _win_uncontested(self, winner):
        amount = self.pot
        winner.chips += amount
        for p in self.players:
            p.total_bet = 0
        self.results = [(winner, amount, None)]
        self.say(f"{winner.name} {winner.verb('wins')} {amount} (everyone else folded)")
        self._finish()

    def _return_uncalled(self):
        """If the biggest bettor put in more than anyone else, give the excess back."""
        ranked = sorted(self.players, key=lambda p: p.total_bet, reverse=True)
        top, second = ranked[0], ranked[1]
        extra = top.total_bet - second.total_bet
        if extra > 0:
            top.total_bet -= extra
            top.chips += extra
            self.say(f"Uncalled {extra} returned to {top.name}")

    def side_pots(self):
        """Split the pot into [(amount, [eligible players])], main pot first.

        Each distinct all-in level of a contender creates a new layer. Every player
        (folded or not) contributes up to that level; only contenders who put in at
        least that much can win the layer.
        """
        levels = sorted({p.total_bet for p in self.players if p.contending and p.total_bet > 0})
        pots, prev = [], 0
        for lvl in levels:
            amount = sum(min(p.total_bet, lvl) - min(p.total_bet, prev) for p in self.players)
            eligible = [p for p in self.players if p.contending and p.total_bet >= lvl]
            pots.append((amount, eligible))
            prev = lvl
        # chips a folded player put in above every contender's level go to the last pot
        leftover = sum(max(0, p.total_bet - prev) for p in self.players)
        if leftover and pots:
            pots[-1] = (pots[-1][0] + leftover, pots[-1][1])
        return pots

    def _showdown(self):
        self.street = "showdown"
        self._return_uncalled()
        self.say("--- Showdown ---")
        contenders = [p for p in self.players if p.contending]
        for p in contenders:
            p.score, p.best_five = best_hand(p.hole + self.board)
            self.say(f"{p.name} {p.verb('shows')} {' '.join(map(str, p.hole))} — {describe(p.score)}")

        # odd chips go to the first winner left of the button
        seat_order = [self.players[(self.button + k) % len(self.players)]
                      for k in range(1, len(self.players) + 1)]
        winnings = {}
        pots = self.side_pots()
        for n, (amount, eligible) in enumerate(pots):
            best = max(p.score for p in eligible)
            winners = [p for p in seat_order if p in eligible and p.score == best]
            share, odd = divmod(amount, len(winners))
            for k, w in enumerate(winners):
                won = share + (1 if k < odd else 0)
                w.chips += won
                winnings[w] = winnings.get(w, 0) + won
            pot_name = "main pot" if n == 0 else f"side pot {n}"
            if len(pots) == 1:
                pot_name = "the pot"
            names = " and ".join(w.name for w in winners)
            verb = "split" if len(winners) > 1 else winners[0].verb("wins")
            self.say(f"{names} {verb} {pot_name} ({amount}) with {describe(best)}")

        for p in self.players:
            p.total_bet = 0
        self.results = [(p, amt, describe(p.score)) for p, amt in winnings.items()]
        self._finish()
