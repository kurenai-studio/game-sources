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

GAME_NAME = "tripeaks"
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





WIDTH, HEIGHT = 900, 680
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("TriPeaks Solitaire")
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


BG        = (0, 100, 40)
WHITE     = (255, 255, 255)
BLACK     = (0, 0, 0)
RED         = (210,  30,  30)
DARK_GRAY = (70, 70, 70)
GOLD      = (255, 215, 0)
CARD_BG     = (255, 255, 255)
CARD_BACK = (30, 60, 180)
SLOT_COL  = (0, 80, 30)
SLOT_BDR  = (0, 130, 60)
HIGHLIGHT = (255, 255, 80)
GRAY_OUT  = (100, 120, 100)

font       = _make_font(19, bold=True)
small_font = _make_font(14, bold=True)
big_font   = _make_font(32, bold=True)
clock      = pygame.time.Clock()

CARD_W, CARD_H = 72, 95
SUITS  = ["\u2660","\u2665","\u2666","\u2663"]
RANKS  = ["A","2","3","4","5","6","7","8","9","10","J","Q","K"]
RED_SUITS = {"\u2665","\u2666"}

def rank_value(card):
    return RANKS.index(card["rank"])

def card_color(card):
    return RED if card["suit"] in RED_SUITS else BLACK

def draw_card(surf, card, x, y, selected=False, grayed=False):
    r = pygame.Rect(x, y, CARD_W, CARD_H)
    if selected:
        pygame.draw.rect(surf, HIGHLIGHT, (x-3, y-3, CARD_W+6, CARD_H+6), border_radius=7)
    if not card["face_up"]:
        pygame.draw.rect(surf, CARD_BACK, r, border_radius=6)
        pygame.draw.rect(surf, (60,100,220), r, 2, border_radius=6)
        return
    bg = (180, 190, 180) if grayed else CARD_BG
    pygame.draw.rect(surf, bg, r, border_radius=6)
    pygame.draw.rect(surf, DARK_GRAY, r, 1, border_radius=6)
    color = card_color(card)
    if grayed:
        color = (120, 120, 120)
    label = card["rank"] + card["suit"]
    tl = _render_suit(font, label, color)
    surf.blit(tl, (x+3, y+2))
    cs = _render_suit(big_font, card["suit"], color)
    surf.blit(cs, (x+CARD_W//2-cs.get_width()//2, y+CARD_H//2-cs.get_height()//2))

def make_deck():
    deck = [{"suit":s, "rank":r, "face_up":False} for s in SUITS for r in RANKS]
    random.shuffle(deck)
    return deck

# TriPeaks layout: 3 peaks, each 4 rows
# Row 0 (top): positions 0, 9, 18  (peak tips)
# Row 1:       1,2, 10,11, 19,20
# Row 2:       3,4,5, 12,13,14, 21,22,23
# Row 3 (base):6,7,8, 9(shared),... actually standard layout:
# 28 tableau cards in 3 pyramids sharing bottom row
# We use: 3 peaks × rows 0-2, then shared bottom row of 10 cards
# Standard TriPeaks: 28 cards in pyramid, 24 in stock

# Layout positions for 28 tableau cards
# Peak 1: cols centred at x=180, Peak 2 at x=450, Peak 3 at x=720
# Each peak:  row0 = tip, row1 = 2 cards, row2 = 3 cards
# Bottom row: 10 cards spanning all three peaks

PEAK_CENTERS = [180, 450, 720]
ROW_Y = [60, 120, 180, 250]  # y positions for rows 0-3
HORIZ_GAP = CARD_W + 8

def build_layout():
    """Returns list of (x, y, covers) for each of 28 tableau positions."""
    positions = []  # (x, y, list_of_indices_this_card_covers)
    
    # For each peak: row 0 = 1 card, row 1 = 2 cards, row 2 = 3 cards
    peak_cards = []
    for peak_idx, cx in enumerate(PEAK_CENTERS):
        base = peak_idx * 3  # offset into peak_cards
        # Row 0: 1 card at center
        peak_cards.append((cx - CARD_W//2, ROW_Y[0]))
        # Row 1: 2 cards
        peak_cards.append((cx - CARD_W - 4, ROW_Y[1]))
        peak_cards.append((cx + 4, ROW_Y[1]))
        # Row 2: 3 cards
        peak_cards.append((cx - CARD_W*3//2 - 8, ROW_Y[2]))
        peak_cards.append((cx - CARD_W//2, ROW_Y[2]))
        peak_cards.append((cx + CARD_W//2 + 8, ROW_Y[2]))

    # Bottom row: 10 cards evenly spaced
    bottom_x_start = 45
    bottom_cards = [(bottom_x_start + i * (CARD_W + 6), ROW_Y[3]) for i in range(10)]

    # Coverage: a card is covered by the cards above it
    # Peak rows cover the bottom row cards
    # Row 2 cards cover bottom row cards
    # Row 1 cards cover row 2 cards
    # Row 0 covers row 1 cards
    # Coverage map (which tableau idx covers which):
    # idx 0 (peak tip) covers idx 1,2
    # idx 1 covers idx 3,4; idx 2 covers idx 4,5
    # idx 3 covers bottom[0],bottom[1]; idx4 covers bottom[1],bottom[2]; idx5 covers bottom[2],bottom[3]
    # Similarly for peaks 2 and 3

    all_pos = peak_cards + bottom_cards  # 18 + 10 = 28 total

    # covered_by[i] = list of card indices that sit ON TOP of card i
    # A card is free when all cards covering it have been removed
    # Row 0 (tip) is free immediately - nothing sits on top of it
    # Row 1 is covered by row 0 (tip must be removed first)
    # Row 2 is covered by row 1
    # Bottom row is covered by row 2
    covered_by = [[] for _ in range(28)]

    for p in range(3):
        base = p * 6
        bot_base = p * 3 + 18  # first bottom card for this peak
        # Tip (row 0) covers nothing - it is free
        # Row 1 cards are covered by the tip
        covered_by[base + 1].append(base + 0)
        covered_by[base + 2].append(base + 0)
        # Row 2 cards are covered by row 1
        covered_by[base + 3].append(base + 1)
        covered_by[base + 4].append(base + 1)
        covered_by[base + 4].append(base + 2)
        covered_by[base + 5].append(base + 2)
        # Bottom row covered by row 2
        covered_by[bot_base + 0].append(base + 3)
        covered_by[bot_base + 1].append(base + 3)
        covered_by[bot_base + 1].append(base + 4)
        covered_by[bot_base + 2].append(base + 4)
        covered_by[bot_base + 2].append(base + 5)
        covered_by[bot_base + 3].append(base + 5)

    return all_pos, covered_by

POSITIONS, COVERS = build_layout()

class Game:
    def __init__(self):
        self.reset()

    def reset(self):
        deck = make_deck()
        self.cards   = []  # tableau: list of card dicts with pos info
        self.stock   = deck[28:]
        self.waste   = []
        self.removed = 0
        self.score   = 0
        self.streak  = 0
        self.moves   = 0
        self.won     = False
        self.lost    = False
        self.high_score = get_high_score(GAME_NAME)
        self.new_high   = False

        for i, (x, y) in enumerate(POSITIONS):
            card = deck[i].copy()
            # Only tip cards (row 0 of each peak, indices 0/6/12) start face-up
            # All other cards start face-down until uncovered
            card["face_up"] = (len(COVERS[i]) == 0)  # free from start = face up
            card["idx"]     = i
            card["x"]       = x
            card["y"]       = y
            card["removed"] = False
            self.cards.append(card)

        # Flip top waste card
        if self.stock:
            c = self.stock.pop()
            c["face_up"] = True
            self.waste.append(c)

    def is_free(self, idx):
        """Card is free if all cards sitting on top of it have been removed."""
        if self.cards[idx]["removed"]:
            return False
        for covering_idx in COVERS[idx]:
            if not self.cards[covering_idx]["removed"]:
                return False
        return True

    def can_play(self, card):
        """Card can be played on waste top if rank is ±1 (wrapping K-A)."""
        if not self.waste:
            return True
        top = self.waste[-1]
        tv = rank_value(top)
        cv = rank_value(card)
        return cv == (tv + 1) % 13 or cv == (tv - 1) % 13

    def handle_click(self, mx, my):
        # Stock click
        stock_r = pygame.Rect(WIDTH//2 - CARD_W//2, HEIGHT - CARD_H - 10, CARD_W, CARD_H)
        if stock_r.collidepoint(mx, my):
            if self.stock:
                c = self.stock.pop()
                c["face_up"] = True
                self.waste.append(c)
                self.streak = 0
                self.score -= 5
                self.moves += 1
            else:
                self.lost = True
            return

        # Tableau card click
        # Check in reverse order (top cards first)
        for i in range(len(self.cards)-1, -1, -1):
            card = self.cards[i]
            if card["removed"]:
                continue
            if not self.is_free(i):
                continue
            if pygame.Rect(card["x"], card["y"], CARD_W, CARD_H).collidepoint(mx, my):
                if self.can_play(card):
                    card["removed"] = True
                    self.waste.append(card)
                    self.removed += 1
                    self.streak += 1
                    pts = 10 + (self.streak - 1) * 5
                    self.score += pts
                    self.moves += 1
                    # Flip any newly freed cards face-up
                    for j in range(28):
                        if not self.cards[j]["removed"] and not self.cards[j]["face_up"]:
                            if self.is_free(j):
                                self.cards[j]["face_up"] = True
                    if self.removed == 28:
                        self.won = True
                        if save_high_score(GAME_NAME, self.score):
                            self.new_high = True
                        self.high_score = get_high_score(GAME_NAME)
                    elif not self.stock and not any(
                            self.is_free(j) and self.can_play(self.cards[j])
                            for j in range(28) if not self.cards[j]["removed"]):
                        self.lost = True
                return

    def draw(self):
        screen.fill(BG)

        # HUD
        pygame.draw.rect(screen, (0,70,20), (0,0,WIDTH,50))
        screen.blit(font.render(f"Score: {self.score}", True, WHITE), (10, 15))
        screen.blit(font.render(f"Streak: {self.streak}x", True, GOLD), (160, 15))
        screen.blit(font.render(f"Best: {self.high_score}", True, GOLD), (310, 15))
        screen.blit(font.render(f"Cards left: {28 - self.removed}", True, WHITE), (460, 15))
        hint = small_font.render("Click free card (rank ±1 from waste) to play  |  R = new game", True, (150,220,150))
        screen.blit(hint, (WIDTH - hint.get_width() - 10, 17))

        # Tableau cards
        for i, card in enumerate(self.cards):
            if card["removed"]:
                continue
            free = self.is_free(i)
            playable = free and self.can_play(card)
            draw_card(screen, card, card["x"], card["y"], grayed=not free)
            if playable:
                pygame.draw.rect(screen, GOLD,
                    (card["x"]-2, card["y"]-2, CARD_W+4, CARD_H+4), 2, border_radius=7)

        # Waste pile
        wx = WIDTH//2 + CARD_W//2 + 15
        wy = HEIGHT - CARD_H - 10
        if self.waste:
            # Show up to 3 waste cards fanned
            show = self.waste[-3:]
            for j, c in enumerate(show):
                ox = wx - (len(show)-1-j)*18
                draw_card(screen, c, ox, wy)

        # Stock
        sx = WIDTH//2 - CARD_W//2
        sy = HEIGHT - CARD_H - 10
        if self.stock:
            for i in range(min(3, len(self.stock))):
                pygame.draw.rect(screen, CARD_BACK,
                    (sx-i*3, sy-i*3, CARD_W, CARD_H), border_radius=6)
                pygame.draw.rect(screen, (60,100,220),
                    (sx-i*3, sy-i*3, CARD_W, CARD_H), 2, border_radius=6)
            cnt = font.render(f"{len(self.stock)}", True, WHITE)
            screen.blit(cnt, (sx + CARD_W//2 - cnt.get_width()//2, sy + CARD_H + 2))
        else:
            pygame.draw.rect(screen, SLOT_COL, (sx, sy, CARD_W, CARD_H), border_radius=6)
            pygame.draw.rect(screen, SLOT_BDR, (sx, sy, CARD_W, CARD_H), 2, border_radius=6)
            et = font.render("Empty", True, SLOT_BDR)
            screen.blit(et, (sx+CARD_W//2-et.get_width()//2, sy+CARD_H//2-et.get_height()//2))

        # Labels
        screen.blit(small_font.render("STOCK", True, WHITE), (sx+20, sy-18))
        screen.blit(small_font.render("WASTE", True, WHITE), (wx+16, wy-18))

        # Win / lose overlay
        if self.won or self.lost:
            overlay = pygame.Surface((WIDTH,HEIGHT), pygame.SRCALPHA)
            overlay.fill((0,0,0,160))
            screen.blit(overlay, (0,0))
            if self.won:
                msg = big_font.render("You Win!", True, GOLD)
            else:
                msg = big_font.render("No more moves!", True, RED)
            sc  = font.render(f"Score: {self.score}", True, WHITE)
            rst = font.render("Press R to play again", True, WHITE)
            screen.blit(msg, msg.get_rect(center=(WIDTH//2, HEIGHT//2-50)))
            screen.blit(sc,  sc.get_rect(center=(WIDTH//2, HEIGHT//2)))
            screen.blit(rst, rst.get_rect(center=(WIDTH//2, HEIGHT//2+40)))
            if self.new_high:
                nb = font.render("NEW HIGH SCORE!", True, GOLD)
                screen.blit(nb, nb.get_rect(center=(WIDTH//2, HEIGHT//2+70)))


game = Game()
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
                game.reset()
        if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            if not game.won and not game.lost:
                game.handle_click(*event.pos)
    game.draw()
    pygame.display.flip()

pygame.quit()
sys.exit()
