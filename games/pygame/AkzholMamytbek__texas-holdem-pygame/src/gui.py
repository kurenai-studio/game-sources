"""pygame front end: draws the table and turns clicks into game.act() calls.

The rules live in game.py and the decisions in ai.py; this file only
draws the current state and reads the mouse and keyboard.
"""
import pygame

from ai import make_opponents, table_talk
from cards import RANKS, SUIT_SYMBOLS
from game import Game, Player
from sounds import Sounds

WIDTH, HEIGHT = 1180, 760
FONT_NAMES = "arialunicode,arial,dejavusans"

# colours
BG = (18, 24, 22)
FELT = (24, 110, 64)
FELT_EDGE = (92, 56, 30)
WHITE = (245, 245, 240)
BLACK = (20, 20, 20)
RED = (200, 30, 40)
GOLD = (240, 196, 60)
GREY = (120, 120, 120)
PANEL = (30, 36, 34)
CARD_BACK = (40, 70, 160)
BTN = (55, 65, 62)
BTN_HOVER = (75, 90, 85)
BTN_DISABLED = (40, 44, 43)
FOLD_C, CALL_C, RAISE_C = (150, 50, 50), (45, 110, 160), (190, 120, 30)

CARD_W, CARD_H = 60, 86
AI_DELAY_MS = 800           # pause before each AI move, so you can follow along
DEAL_MS = 260               # how long a card takes to slide from the deck
DEAL_STAGGER_MS = 90        # gap between cards when several are dealt at once
DECK_POS = (430, 150)       # where cards fly from
PAYOUT_MS = 700             # chips sliding from the pot to the winner
BUBBLE_MS = 2600            # how long a speech bubble stays up

# seat layout: (plate centre, where the cards go relative to the plate, bet position)
SEATS = {
    "You":    {"plate": (430, 548), "cards": (0, -100), "bet": (430, 385)},
    "Shark": {"plate": (150, 150), "cards": (0, 72),   "bet": (290, 235)},
    "Dealer": {"plate": (710, 150), "cards": (0, 72),   "bet": (570, 235)},
}
TABLE_RECT = pygame.Rect(40, 90, 780, 430)
BOARD_Y = 262
LOG_RECT = pygame.Rect(860, 20, 300, 720)


class Button:
    def __init__(self, rect, label, color=BTN):
        self.rect = pygame.Rect(rect)
        self.label = label
        self.color = color
        self.enabled = True
        self.visible = True

    def draw(self, surf, font, mouse):
        if not self.visible:
            return
        if not self.enabled:
            col = BTN_DISABLED
        elif self.rect.collidepoint(mouse):
            col = tuple(min(255, c + 30) for c in self.color)
        else:
            col = self.color
        pygame.draw.rect(surf, col, self.rect, border_radius=8)
        txt = font.render(self.label, True, WHITE if self.enabled else GREY)
        surf.blit(txt, txt.get_rect(center=self.rect.center))

    def clicked(self, pos):
        return self.visible and self.enabled and self.rect.collidepoint(pos)


class Slider:
    def __init__(self, rect):
        self.rect = pygame.Rect(rect)
        self.lo, self.hi, self.value, self.step = 0, 100, 0, 10
        self.dragging = False

    def set_range(self, lo, hi, step):
        self.lo, self.hi, self.step = lo, hi, step
        self.value = lo

    def set_value(self, v):
        v = max(self.lo, min(self.hi, v))
        if v not in (self.lo, self.hi):        # snap to the step, but keep exact min/max
            v = int(round(v / self.step) * self.step)
            v = max(self.lo, min(self.hi, v))
        self.value = int(v)

    def _value_at(self, x):
        t = (x - self.rect.left) / self.rect.width
        return self.lo + max(0.0, min(1.0, t)) * (self.hi - self.lo)

    def handle(self, event):
        if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1 \
                and self.rect.inflate(0, 20).collidepoint(event.pos):
            self.dragging = True
            self.set_value(self._value_at(event.pos[0]))
        elif event.type == pygame.MOUSEBUTTONUP and event.button == 1:
            self.dragging = False
        elif event.type == pygame.MOUSEMOTION and self.dragging:
            self.set_value(self._value_at(event.pos[0]))

    def draw(self, surf):
        pygame.draw.rect(surf, (70, 80, 76), self.rect, border_radius=4)
        span = max(1, self.hi - self.lo)
        x = self.rect.left + (self.value - self.lo) / span * self.rect.width
        filled = pygame.Rect(self.rect.left, self.rect.top, x - self.rect.left, self.rect.height)
        pygame.draw.rect(surf, RAISE_C, filled, border_radius=4)
        pygame.draw.circle(surf, WHITE, (int(x), self.rect.centery), 11)


class PokerApp:
    def __init__(self, screen):
        self.screen = screen
        self.font = pygame.font.SysFont(FONT_NAMES, 18)
        self.font_small = pygame.font.SysFont(FONT_NAMES, 14)
        self.font_big = pygame.font.SysFont(FONT_NAMES, 26, bold=True)
        self.font_card = pygame.font.SysFont(FONT_NAMES, 20, bold=True)
        self.font_suit = pygame.font.SysFont(FONT_NAMES, 34)

        y = 668
        self.btn_fold = Button((40, y, 150, 48), "Fold", FOLD_C)
        self.btn_call = Button((205, y, 190, 48), "Check", CALL_C)
        self.btn_raise = Button((410, y, 190, 48), "Raise", RAISE_C)
        self.btn_half = Button((620, y, 60, 48), "½ Pot")
        self.btn_pot = Button((688, y, 60, 48), "Pot")
        self.btn_allin = Button((756, y, 64, 48), "All-in")
        self.slider = Slider((410, 640, 410, 8))
        self.btn_next = Button((330, 668, 200, 48), "Next hand", CALL_C)
        self.action_buttons = [self.btn_fold, self.btn_call, self.btn_raise,
                               self.btn_half, self.btn_pot, self.btn_allin]
        self.sounds = Sounds()
        self.stats = {"played": 0, "won": 0, "biggest": 0}   # whole session, survives "Play again"
        self.new_game()

    # ---------- game flow ----------
    def new_game(self):
        self.you = Player("You", 1000, is_human=True)
        self.game = Game([self.you, Player("Shark", 1000), Player("Dealer", 1000)])
        self.bots = make_opponents()
        self.start_hand()

    def start_hand(self):
        self.anim = {}            # card slot -> time it starts sliding in
        self.anim_next = 0        # earliest start time for the next dealt card
        self.anim_sounded = set()
        self.bubbles = {}         # name -> (text, hide_at_ms)
        self.payout = []
        self.hand_recorded = False
        self.game.start_hand()
        self._turn_started()

    def _turn_started(self):
        """Called whenever the action moves to a new player."""
        self.next_ai_time = pygame.time.get_ticks() + AI_DELAY_MS
        g = self.game
        if not g.hand_over and g.current_player.is_human:
            legal = g.legal_actions()
            self.slider.set_range(legal["min_raise_to"], legal["max_raise_to"], g.bb // 2)

    def human_turn(self):
        g = self.game
        return not g.hand_over and g.current_player.is_human

    def human_act(self, action, amount=0):
        if self.human_turn():
            self.game.act(action, amount)
            if action in ("call", "raise"):
                self.sounds.play("chip")
            self._turn_started()

    def update(self):
        g = self.game
        if g.hand_over:
            if not self.hand_recorded:
                self._hand_finished()
            return
        if g.current_player.is_human:
            return
        if pygame.time.get_ticks() >= self.next_ai_time:
            p = g.current_player
            action, amount = self.bots[p.name].decide(g)
            g.act(action, amount)
            if action in ("call", "raise"):
                self.sounds.play("chip")
            self._say(p.name, table_talk(p.name, action))
            self._turn_started()

    def _hand_finished(self):
        """Runs once when a hand ends: stats, sounds, payout animation, reactions."""
        g = self.game
        self.hand_recorded = True
        self.stats["played"] += 1
        self.payout = [(p, amount) for p, amount, _ in g.results]
        self.payout_start = pygame.time.get_ticks()
        winners = {p for p, _, _ in g.results}
        if self.you in winners:
            self.stats["won"] += 1
            mine = sum(a for p, a, _ in g.results if p is self.you)
            self.stats["biggest"] = max(self.stats["biggest"], mine)
            self.sounds.play("win")
        else:
            self.sounds.play("chip")
        showdown = g.street == "showdown"
        for p in g.players:
            if p.is_human:
                continue
            if p in winners:
                self._say(p.name, table_talk(p.name, "win", always=showdown))
            elif showdown and p.contending:
                self._say(p.name, table_talk(p.name, "lose", always=True))

    def _say(self, name, text):
        if text:
            self.bubbles[name] = (text, pygame.time.get_ticks() + BUBBLE_MS)

    # ---------- input ----------
    def handle_event(self, event):
        g = self.game
        if event.type == pygame.KEYDOWN and event.key == pygame.K_m:
            self.sounds.toggle_mute()
            return
        if g.hand_over:
            if (event.type == pygame.MOUSEBUTTONDOWN and self.btn_next.clicked(event.pos)) or \
                    (event.type == pygame.KEYDOWN and event.key in (pygame.K_SPACE, pygame.K_RETURN)):
                if g.game_over:
                    self.new_game()
                else:
                    self.start_hand()
            return
        if not self.human_turn():
            return

        legal = g.legal_actions()
        self.slider.handle(event)
        if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            pos = event.pos
            if self.btn_fold.clicked(pos):
                self.human_act("fold")
            elif self.btn_call.clicked(pos):
                self.human_act("check" if legal["can_check"] else "call")
            elif self.btn_raise.clicked(pos):
                self.human_act("raise", self.slider.value)
            elif self.btn_half.clicked(pos):
                self.slider.set_value(self._pot_raise(0.5))
            elif self.btn_pot.clicked(pos):
                self.slider.set_value(self._pot_raise(1.0))
            elif self.btn_allin.clicked(pos):
                self.slider.set_value(legal["max_raise_to"])
        elif event.type == pygame.KEYDOWN:
            if event.key == pygame.K_f:
                self.human_act("fold")
            elif event.key == pygame.K_c:
                self.human_act("check" if legal["can_check"] else "call")
            elif event.key == pygame.K_r and legal["can_raise"]:
                self.human_act("raise", self.slider.value)
            elif event.key in (pygame.K_RIGHT, pygame.K_UP):
                self.slider.set_value(self.slider.value + self.slider.step)
            elif event.key in (pygame.K_LEFT, pygame.K_DOWN):
                self.slider.set_value(self.slider.value - self.slider.step)

    def _pot_raise(self, frac):
        g = self.game
        to_call = g.legal_actions()["to_call"]
        return g.current_bet + frac * (g.pot + to_call)

    # ---------- drawing ----------
    def draw(self):
        s = self.screen
        s.fill(BG)
        mouse = pygame.mouse.get_pos()
        g = self.game

        st = self.stats
        sound = "off" if self.sounds.muted or not self.sounds.enabled else "on"
        header = (f"Hand #{g.hand_no}   ·   Blinds {g.sb}/{g.bb}   ·   You won {st['won']}/{st['played']}"
                  f"   ·   Biggest pot: {st['biggest']}   ·   Sound {sound} (M)")
        s.blit(self.font.render(header, True, GREY), (40, 30))

        # table
        pygame.draw.ellipse(s, FELT_EDGE, TABLE_RECT.inflate(30, 30))
        pygame.draw.ellipse(s, FELT, TABLE_RECT)

        # pot and board
        if g.pot or not g.hand_over:
            self._text_center(f"Pot: {g.pot}", self.font_big, GOLD, (430, 225))
        board_w = 5 * CARD_W + 4 * 10
        x0 = 430 - board_w // 2
        for i in range(5):
            r = pygame.Rect(x0 + i * (CARD_W + 10), BOARD_Y, CARD_W, CARD_H)
            pygame.draw.rect(s, (20, 90, 52), r, 2, border_radius=6)
            if i < len(g.board):
                moving = self._anim_rect(f"board{i}", r)
                if moving:
                    self._draw_card(g.board[i], moving, highlight=self._in_winning_five(g.board[i]))

        winners = {p for p, _, _ in g.results}
        for idx, p in enumerate(g.players):
            self._draw_seat(idx, p, winners)

        self._draw_payout()
        self._draw_bubbles()
        self._draw_log()
        if g.hand_over:
            self._draw_results()
        else:
            self._draw_controls(mouse)

    # ---------- animation ----------
    def _anim_rect(self, key, target):
        """Where a dealt card should be drawn right now (None = not dealt yet).

        The first time a card slot is drawn it gets a start time; until then it
        sits in the deck, then slides to its spot with an ease-out curve.
        """
        now = pygame.time.get_ticks()
        start = self.anim.get(key)
        if start is None:
            start = max(now, self.anim_next)
            self.anim[key] = start
            self.anim_next = start + DEAL_STAGGER_MS
        t = (now - start) / DEAL_MS
        if t < 0:
            return None
        if key not in self.anim_sounded:
            self.anim_sounded.add(key)
            self.sounds.play("card")
        if t >= 1:
            return target
        e = 1 - (1 - t) ** 3                    # ease-out: fast start, gentle landing
        x = DECK_POS[0] - CARD_W // 2 + (target.x - DECK_POS[0] + CARD_W // 2) * e
        y = DECK_POS[1] - CARD_H // 2 + (target.y - DECK_POS[1] + CARD_H // 2) * e
        return pygame.Rect(int(x), int(y), CARD_W, CARD_H)

    def _draw_payout(self):
        if not self.payout:
            return
        t = (pygame.time.get_ticks() - self.payout_start) / PAYOUT_MS
        if t >= 1:
            return
        e = 1 - (1 - t) ** 3
        for p, _ in self.payout:
            tx, ty = SEATS[p.name]["plate"]
            x, y = 430 + (tx - 430) * e, 225 + (ty - 225) * e
            for k in range(3):                  # a little stack of chips
                pygame.draw.circle(self.screen, GOLD, (int(x), int(y) - k * 5), 12)
                pygame.draw.circle(self.screen, (150, 110, 20), (int(x), int(y) - k * 5), 12, 2)

    def _draw_bubbles(self):
        now = pygame.time.get_ticks()
        for name, (text, until) in self.bubbles.items():
            if now >= until:
                continue
            px, py = SEATS[name]["plate"]
            t = self.font.render(text, True, BLACK)
            box = t.get_rect().inflate(24, 14)
            box.midbottom = (px, py - 42)
            pygame.draw.polygon(self.screen, WHITE, [(px - 8, box.bottom - 1), (px + 8, box.bottom - 1),
                                                     (px, box.bottom + 9)])
            pygame.draw.rect(self.screen, WHITE, box, border_radius=12)
            self.screen.blit(t, t.get_rect(center=box.center))

    def _draw_seat(self, idx, p, winners):
        g, s = self.game, self.screen
        seat = SEATS[p.name]
        px, py = seat["plate"]
        plate = pygame.Rect(0, 0, 180, 64)
        plate.center = (px, py)

        is_turn = g.current == idx
        border = GOLD if (p in winners and g.hand_over) else (WHITE if is_turn else (60, 70, 66))
        pygame.draw.rect(s, PANEL, plate, border_radius=10)
        pygame.draw.rect(s, border, plate, 3 if is_turn or p in winners else 1, border_radius=10)

        name_col = GREY if (p.folded or not p.in_hand) else WHITE
        s.blit(self.font.render(p.name, True, name_col), (plate.x + 12, plate.y + 8))
        s.blit(self.font.render(f"{p.chips}", True, GOLD), (plate.x + 12, plate.y + 34))
        status = "Out" if not p.in_hand else ("ALL-IN" if p.all_in else p.last_action)
        if is_turn and not p.is_human:
            status = "thinking…"
        st = self.font_small.render(status, True, WHITE if is_turn else GREY)
        s.blit(st, st.get_rect(topright=(plate.right - 12, plate.y + 38)))

        # dealer button
        if idx == g.button:
            bx = plate.right + 18 if p.name != "Dealer" else plate.left - 18
            pygame.draw.circle(s, WHITE, (bx, plate.centery), 13)
            self._text_center("D", self.font_small, BLACK, (bx, plate.centery))

        # hole cards
        if p.in_hand and not p.folded:
            cx, cy = px + seat["cards"][0], py + seat["cards"][1]
            reveal = p.is_human or (g.street == "showdown" and p.contending)
            for k, card in enumerate(p.hole):
                r = pygame.Rect(cx - CARD_W - 4 + k * (CARD_W + 8), cy - CARD_H // 2 + 10,
                                CARD_W, CARD_H)
                r = self._anim_rect(f"{p.name}{k}", r)
                if r is None:
                    continue
                if reveal:
                    self._draw_card(card, r, highlight=self._in_winning_five(card))
                else:
                    self._draw_back(r)

        # chips in front of the player this street
        if p.bet:
            bx, by = seat["bet"]
            pygame.draw.circle(s, RED, (bx - 30, by), 10)
            pygame.draw.circle(s, WHITE, (bx - 30, by), 10, 2)
            s.blit(self.font.render(str(p.bet), True, WHITE), (bx - 14, by - 11))

    def _in_winning_five(self, card):
        g = self.game
        if g.street != "showdown":
            return False
        return any(p.best_five and card in p.best_five for p, _, _ in g.results)

    def _draw_card(self, card, rect, highlight=False):
        s = self.screen
        if highlight:
            pygame.draw.rect(s, GOLD, rect.inflate(6, 6), border_radius=8)
        pygame.draw.rect(s, WHITE, rect, border_radius=6)
        col = RED if card.is_red else BLACK
        rank = "10" if card.rank == 10 else RANKS[card.rank - 2]
        s.blit(self.font_card.render(rank, True, col), (rect.x + 6, rect.y + 3))
        s.blit(self.font_small.render(SUIT_SYMBOLS[card.suit], True, col), (rect.x + 7, rect.y + 25))
        suit = self.font_suit.render(SUIT_SYMBOLS[card.suit], True, col)
        s.blit(suit, suit.get_rect(center=(rect.centerx + 6, rect.centery + 14)))

    def _draw_back(self, rect):
        s = self.screen
        pygame.draw.rect(s, WHITE, rect, border_radius=6)
        inner = rect.inflate(-8, -8)
        pygame.draw.rect(s, CARD_BACK, inner, border_radius=4)
        s.set_clip(inner)                                     # keep stripes inside the card
        for k in range(0, inner.width + inner.height, 10):   # diagonal stripes
            a = (inner.left + k, inner.top)
            b = (inner.left + k - inner.height, inner.bottom)
            pygame.draw.line(s, (60, 95, 190), a, b, 2)
        s.set_clip(None)
        pygame.draw.rect(s, WHITE, rect, 2, border_radius=6)

    def _draw_controls(self, mouse):
        g = self.game
        human = self.human_turn()
        for b in self.action_buttons:
            b.visible = True
            b.enabled = human
        if human:
            legal = g.legal_actions()
            self.btn_call.label = "Check" if legal["can_check"] else f"Call {legal['to_call']}"
            for b in (self.btn_raise, self.btn_half, self.btn_pot, self.btn_allin):
                b.enabled = legal["can_raise"]
            word = "Bet" if legal["is_bet"] else "Raise to"
            all_in = self.slider.value == legal["max_raise_to"]
            self.btn_raise.label = f"All-in {self.slider.value}" if all_in else f"{word} {self.slider.value}"
            if legal["can_raise"]:
                self.slider.draw(self.screen)
            hint = "Keys: F fold · C check/call · R raise · ←/→ adjust"
            self.screen.blit(self.font_small.render(hint, True, GREY), (40, 735))
        else:
            self.btn_call.label = "Check"
            self.btn_raise.label = "Raise"
        for b in self.action_buttons:
            b.draw(self.screen, self.font, mouse)

    def _draw_results(self):
        g, s = self.game, self.screen
        lines = []
        for p, amount, hand in g.results:
            lines.append(f"{p.name} won {amount}" + (f" — {hand}" if hand else ""))
        if g.game_over:
            champ = max(g.players, key=lambda p: p.chips)
            lines.append("You won the game!" if champ.is_human else f"Game over — {champ.name} wins.")
            self.btn_next.label = "Play again"
        else:
            self.btn_next.label = "Next hand"
        for k, line in enumerate(lines):
            self._text_center(line, self.font_big if k == 0 else self.font, GOLD, (430, 612 + k * 26 - 8 * len(lines)))
        self.btn_next.rect.top = 690
        self.btn_next.draw(s, self.font, pygame.mouse.get_pos())

    def _draw_log(self):
        s = self.screen
        pygame.draw.rect(s, PANEL, LOG_RECT, border_radius=10)
        s.blit(self.font.render("Action log", True, WHITE), (LOG_RECT.x + 14, LOG_RECT.y + 10))
        line_h = 20
        max_lines = (LOG_RECT.height - 50) // line_h
        lines = []
        for msg in self.game.log:
            lines += self._wrap(msg, LOG_RECT.width - 28)
        for k, msg in enumerate(lines[-max_lines:]):
            col = GOLD if ("wins" in msg or "split" in msg) else \
                  (WHITE if msg.startswith(("---", "===")) else (190, 195, 190))
            s.blit(self.font_small.render(msg, True, col), (LOG_RECT.x + 14, LOG_RECT.y + 42 + k * line_h))

    def _wrap(self, text, width):
        words, lines, cur = text.split(), [], ""
        for w in words:
            trial = cur + " " + w if cur else w
            if self.font_small.size(trial)[0] > width and cur:
                lines.append(cur)
                cur = "  " + w
            else:
                cur = trial
        return lines + [cur]

    def _text_center(self, text, font, color, center):
        t = font.render(text, True, color)
        self.screen.blit(t, t.get_rect(center=center))
