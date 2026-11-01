# -*- coding: utf-8 -*-
import os
os.environ["PYGAME_HIDE_SUPPORT_PROMPT"] = "1"
import sys
if sys.platform == "win32":
    import os
    os.environ["PYTHONUTF8"] = "1"
    try:
        import ctypes
        ctypes.windll.kernel32.SetConsoleOutputCP(65001)
        ctypes.windll.kernel32.SetConsoleCP(65001)
    except Exception:
        pass

import pygame
import random
import sys
from highscores import get_high_score, save_high_score

GAME_NAME = "spider_solitaire"
pygame.init()

def _make_font(size, bold=False):
    """Return a font that works on this platform. Simple and safe."""
    import platform
    system = platform.system()
    if system == "Windows":
        # Segoe UI Symbol ships with Windows 7+ and has full Unicode suit glyphs
        for name in ["segoeuisymbol", "segoeui", "arial"]:
            try:
                f = pygame.font.SysFont(name, size, bold=bold)
                if f is not None:
                    return f
            except Exception:
                pass
    elif system == "Darwin":
        for name in ["applesymbols", "helvetica", "arial"]:
            try:
                f = pygame.font.SysFont(name, size, bold=bold)
                if f is not None:
                    return f
            except Exception:
                pass
    # Linux or final fallback
    try:
        return pygame.font.SysFont("arial", size, bold=bold)
    except Exception:
        return pygame.font.Font(None, size)


_SUIT_FALLBACK = {"\u2660": "S", "\u2665": "H", "\u2666": "D", "\u2663": "C"}


def _render_suit(font, text, color):
    """Render text, substituting suit symbols with letters if glyphs are missing."""
    try:
        s = font.render(text, True, color)
        # Check if glyphs rendered — missing glyphs produce very narrow surfaces
        ref = font.render("A", True, color)
        if len(text) > 0 and s.get_width() < ref.get_width() * 0.4 * len(text):
            # Substitute each suit character with its letter fallback
            safe = ""
            for ch in text:
                safe += _SUIT_FALLBACK.get(ch, ch)
            s = font.render(safe, True, color)
        return s
    except Exception:
        try:
            safe = ""
            for ch in text:
                safe += _SUIT_FALLBACK.get(ch, ch)
            return font.render(safe, True, color)
        except Exception:
            return font.render("?", True, color)





WIDTH, HEIGHT = 1100, 820
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Spider Solitaire")
def _set_window_icon():
    base = os.path.dirname(os.path.abspath(__file__))
    for _icon_name in ("icon.bmp", "icon.png"):
        _icon_path = os.path.join(base, _icon_name)
        if os.path.isfile(_icon_path):
            try:
                pygame.display.set_icon(pygame.image.load(_icon_path))
                break
            except pygame.error:
                pass

_set_window_icon()


BG         = (0, 90, 0)
WHITE      = (255, 255, 255)
BLACK      = (0, 0, 0)
RED         = (210,  30,  30)
GRAY       = (140, 140, 140)
DARK_GRAY  = (70, 70, 70)
GOLD       = (255, 215, 0)
CARD_BG     = (255, 255, 255)
CARD_BACK  = (30, 60, 180)
SLOT_COLOR = (0, 70, 0)
SLOT_BDR   = (0, 110, 0)
HIGHLIGHT  = (255, 255, 80)

font       = _make_font(22, bold=True)
small_font = _make_font(17, bold=True)
big_font   = _make_font(38, bold=True)
clock      = pygame.time.Clock()

CARD_W, CARD_H = 85, 115
SUITS     = ["\u2660", "\u2665", "\u2666", "\u2663"]
RANKS     = ["A","2","3","4","5","6","7","8","9","10","J","Q","K"]
RED_SUITS = {"\u2665","\u2666"}
COLS      = 10
TAB_X     = [10 + i * 108 for i in range(COLS)]
TAB_Y     = 140
OVERLAP   = 20   # face-down
F_OVERLAP = 24   # face-up
STOCK_X, STOCK_Y = WIDTH - 110, HEIGHT - 130
COMPLETED_Y = 20

def rank_value(card):
    return RANKS.index(card["rank"])

def card_color(card):
    return RED if card["suit"] in RED_SUITS else BLACK

def make_spider_deck():
    # 1-suit spider: all spades (8 decks of spades = 104 cards)
    deck = []
    for _ in range(8):
        for r in RANKS:
            deck.append({"suit": "\u2660", "rank": r, "face_up": False})
    random.shuffle(deck)
    return deck

def draw_card(surf, card, x, y, selected=False):
    if selected:
        pygame.draw.rect(surf, HIGHLIGHT, (x-3, y-3, CARD_W+6, CARD_H+6), border_radius=6)
    r = pygame.Rect(x, y, CARD_W, CARD_H)
    if not card["face_up"]:
        pygame.draw.rect(surf, CARD_BACK, r, border_radius=6)
        pygame.draw.rect(surf, (60,100,220), r, 2, border_radius=6)
        for row in range(3):
            for col in range(3):
                pygame.draw.rect(surf, (50,90,200), (x+7+col*22, y+10+row*32, 16,24), border_radius=2)
        return
    pygame.draw.rect(surf, CARD_BG, r, border_radius=6)
    pygame.draw.rect(surf, DARK_GRAY, r, 1, border_radius=6)
    color = card_color(card)
    rank_tl = font.render(card["rank"], True, color)
    surf.blit(rank_tl, (x + 4, y + 3))
    surf.blit(_render_suit(small_font, card["suit"], color), (x + 4, y + 24))
    cs = _render_suit(big_font, card["suit"], color)
    surf.blit(cs, (x + CARD_W // 2 - cs.get_width() // 2, y + CARD_H // 2 - cs.get_height() // 2))
    rank_br = font.render(card["rank"], True, color)
    surf.blit(rank_br, rank_br.get_rect(bottomright=(x + CARD_W - 4, y + CARD_H - 4)))

def draw_slot(surf, x, y):
    r = pygame.Rect(x, y, CARD_W, CARD_H)
    pygame.draw.rect(surf, SLOT_COLOR, r, border_radius=6)
    pygame.draw.rect(surf, SLOT_BDR, r, 2, border_radius=6)

class Game:
    def __init__(self, difficulty=1):
        # difficulty: 1=1suit, 2=2suit, 4=4suit
        self.difficulty = difficulty
        self.reset()

    def reset(self):
        self.tableau   = [[] for _ in range(COLS)]
        self.completed = []   # completed sequences
        self.stock     = []
        self.selected  = None  # (col, row_idx)
        self.score     = 500
        self.moves     = 0
        self.won       = False
        self.high_score = get_high_score(GAME_NAME)
        self.new_high   = False
        self.message    = ""
        self.msg_timer  = 0

        deck = self._make_deck()

        # Deal: cols 0-3 get 6 cards, cols 4-9 get 5 cards
        idx = 0
        for col in range(COLS):
            count = 6 if col < 4 else 5
            for i in range(count):
                card = deck[idx]; idx += 1
                card["face_up"] = (i == count - 1)
                self.tableau[col].append(card)
        self.stock = [deck[i:i+10] for i in range(idx, len(deck), 10)]

    def _make_deck(self):
        deck = []
        suits = ["\u2660"] * 8 if self.difficulty == 1 else \
                ["\u2660","\u2665"] * 4 if self.difficulty == 2 else SUITS * 2
        for s in suits:
            for r in RANKS:
                deck.append({"suit": s, "rank": r, "face_up": False})
        random.shuffle(deck)
        return deck

    def card_y(self, col, idx):
        y = TAB_Y
        tab = self.tableau[col]
        for i in range(min(idx, len(tab))):
            y += F_OVERLAP if tab[i]["face_up"] else OVERLAP
        return y

    def is_valid_sequence(self, cards):
        """Check if cards form a descending same-suit sequence."""
        for i in range(len(cards)-1):
            if (cards[i]["suit"] != cards[i+1]["suit"] or
                    rank_value(cards[i]) != rank_value(cards[i+1]) + 1):
                return False
        return True

    def can_move(self, cards, dest_col):
        tab = self.tableau[dest_col]
        if not tab:
            return True
        top = tab[-1]
        if not top["face_up"]:
            return False
        return rank_value(cards[0]) == rank_value(top) - 1

    def check_complete_sequence(self, col):
        tab = self.tableau[col]
        if len(tab) < 13:
            return False
        seq = tab[-13:]
        if (seq[0]["rank"] == "K" and seq[-1]["rank"] == "A" and
                self.is_valid_sequence(seq)):
            self.completed.append(seq[0]["suit"])
            del tab[-13:]
            self.score += 100
            self.moves += 1
            if tab and not tab[-1]["face_up"]:
                tab[-1]["face_up"] = True
            if len(self.completed) == 8:
                self.won = True
                if save_high_score(GAME_NAME, self.score):
                    self.new_high = True
                self.high_score = get_high_score(GAME_NAME)
            return True
        return False

    def deal_stock(self):
        if not self.stock:
            return
        # All columns must be non-empty
        if any(not col for col in self.tableau):
            self.message = "Fill empty columns first!"
            self.msg_timer = 120
            return
        row = self.stock.pop(0)
        for col, card in enumerate(row):
            card["face_up"] = True
            self.tableau[col].append(card)
        self.score -= 1
        self.moves += 1
        for col in range(COLS):
            self.check_complete_sequence(col)

    def handle_click(self, mx, my):
        # Stock
        if pygame.Rect(STOCK_X, STOCK_Y, CARD_W, CARD_H).collidepoint(mx, my):
            self.selected = None
            self.deal_stock()
            return

        # Tableau
        for col in range(COLS):
            tx = TAB_X[col]
            tab = self.tableau[col]

            # Empty column slot
            if not tab:
                slot_r = pygame.Rect(tx, TAB_Y, CARD_W, CARD_H)
                if slot_r.collidepoint(mx, my) and self.selected:
                    self.move_selected(col)
                    self.selected = None
                continue

            for i in range(len(tab)-1, -1, -1):
                cy = self.card_y(col, i)
                next_cy = self.card_y(col, i+1) if i+1 < len(tab) else cy + CARD_H
                h = min(CARD_H, next_cy - cy) if i < len(tab)-1 else CARD_H
                if pygame.Rect(tx, cy, CARD_W, h).collidepoint(mx, my):
                    card = tab[i]
                    if not card["face_up"]:
                        if i == len(tab)-1:
                            card["face_up"] = True
                        self.selected = None
                        return
                    # Check if cards from i to end form a moveable sequence
                    cards = tab[i:]
                    if self.is_valid_sequence(cards):
                        if self.selected and self.selected[0] == col and self.selected[1] == i:
                            self.selected = None  # deselect
                        elif self.selected:
                            self.move_selected(col)
                            self.selected = None
                        else:
                            self.selected = (col, i)
                    else:
                        # Can't move non-sequence, deselect
                        if self.selected:
                            self.move_selected(col)
                            self.selected = None
                        else:
                            self.selected = None
                    return

    def move_selected(self, dest_col):
        if not self.selected:
            return
        src_col, src_idx = self.selected
        cards = self.tableau[src_col][src_idx:]
        if not cards:
            return
        if self.can_move(cards, dest_col):
            self.tableau[dest_col].extend(cards)
            del self.tableau[src_col][src_idx:]
            self.moves += 1
            self.score -= 1
            if self.tableau[src_col] and not self.tableau[src_col][-1]["face_up"]:
                self.tableau[src_col][-1]["face_up"] = True
                self.score += 2
            self.check_complete_sequence(dest_col)

    def draw(self):
        screen.fill(BG)

        # HUD
        pygame.draw.rect(screen, (0,60,0), (0,0,WIDTH,130))
        title = big_font.render("Spider Solitaire", True, WHITE)
        screen.blit(title, (10, 8))
        diff_names = {1:"1 Suit", 2:"2 Suits", 4:"4 Suits"}
        diff_t = font.render(f"[{diff_names[self.difficulty]}]", True, GOLD)
        screen.blit(diff_t, (10, 50))
        screen.blit(font.render(f"Score: {self.score}", True, WHITE), (10, 72))
        screen.blit(font.render(f"Moves: {self.moves}", True, WHITE), (140, 72))
        screen.blit(font.render(f"Best: {self.high_score}", True, GOLD), (270, 72))
        screen.blit(font.render(f"Completed: {len(self.completed)}/8", True, WHITE), (10, 95))
        hint = small_font.render("Click sequence to select, click dest to move  |  R=new  |  1/2/4=difficulty", True, (150,220,150))
        screen.blit(hint, (WIDTH - hint.get_width() - 10, 110))

        # Completed suits
        for i, suit in enumerate(self.completed):
            sx = 400 + i * 50
            pygame.draw.rect(screen, GOLD, (sx, 20, 36, 50), border_radius=4)
            st = big_font.render(suit, True, BLACK)
            screen.blit(st, (sx+2, 12))

        # Stock piles remaining
        for i, pile in enumerate(self.stock):
            ox = STOCK_X - i * 3
            oy = STOCK_Y - i * 3
            pygame.draw.rect(screen, CARD_BACK, (ox, oy, CARD_W, CARD_H), border_radius=6)
            pygame.draw.rect(screen, (60,100,220), (ox, oy, CARD_W, CARD_H), 2, border_radius=6)
        if not self.stock:
            draw_slot(screen, STOCK_X, STOCK_Y)
        cnt_t = font.render(f"{len(self.stock)} deals left", True, WHITE)
        screen.blit(cnt_t, (STOCK_X, STOCK_Y + CARD_H + 5))

        # Tableau
        for col in range(COLS):
            draw_slot(screen, TAB_X[col], TAB_Y)
            for i, card in enumerate(self.tableau[col]):
                cy = self.card_y(col, i)
                sel = (self.selected and self.selected[0]==col and self.selected[1]<=i)
                draw_card(screen, card, TAB_X[col], cy, selected=sel)

        # Message
        if self.msg_timer > 0:
            self.msg_timer -= 1
            msg_s = font.render(self.message, True, (255,80,80))
            screen.blit(msg_s, (WIDTH//2 - msg_s.get_width()//2, HEIGHT - 30))

        if self.won:
            overlay = pygame.Surface((WIDTH,HEIGHT), pygame.SRCALPHA)
            overlay.fill((0,0,0,160))
            screen.blit(overlay, (0,0))
            wt = big_font.render("You Win!", True, GOLD)
            st = font.render(f"Score: {self.score}  |  Moves: {self.moves}", True, WHITE)
            rt = font.render("Press R for a new game", True, WHITE)
            screen.blit(wt, wt.get_rect(center=(WIDTH//2, HEIGHT//2-50)))
            screen.blit(st, st.get_rect(center=(WIDTH//2, HEIGHT//2)))
            screen.blit(rt, rt.get_rect(center=(WIDTH//2, HEIGHT//2+40)))
            if self.new_high:
                screen.blit(font.render("NEW HIGH SCORE!", True, GOLD),
                    font.render("NEW HIGH SCORE!", True, GOLD).get_rect(center=(WIDTH//2, HEIGHT//2+70)))


game = Game(difficulty=1)
running = True
while running:
    clock.tick(60)
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False
        if event.type == pygame.KEYDOWN:
            if event.key == pygame.K_ESCAPE:
                running = False
        if event.type == pygame.KEYDOWN:
            if event.key == pygame.K_r:
                game = Game(game.difficulty)
            elif event.key == pygame.K_1:
                game = Game(1)
            elif event.key == pygame.K_2:
                game = Game(2)
            elif event.key == pygame.K_4:
                game = Game(4)
        if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1 and not game.won:
            game.handle_click(*event.pos)
    game.draw()
    pygame.display.flip()

pygame.quit()
sys.exit()
