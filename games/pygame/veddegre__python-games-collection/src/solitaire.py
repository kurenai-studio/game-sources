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

GAME_NAME = "solitaire"
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





WIDTH, HEIGHT = 1000, 780
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Klondike Solitaire")
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


# Colors
BG          = (0, 100, 0)
WHITE       = (255, 255, 255)
BLACK       = (15,  15,  15)
RED         = (210, 30,  30)
DARK_RED    = (140, 0, 0)
GRAY        = (160, 160, 160)
DARK_GRAY   = (140, 140, 160)
GOLD        = (255, 215, 0)
CARD_BG     = (255, 255, 255)
CARD_BACK   = (30, 60, 180)
SLOT_COLOR  = (0, 80, 0)
SLOT_BORDER = (0, 120, 0)
HIGHLIGHT   = (255, 255, 100)

font       = _make_font(20, bold=True)
small_font = _make_font(14, bold=True)
big_font   = _make_font(32, bold=True)
rank_font  = _make_font(24, bold=True)
clock      = pygame.time.Clock()

CARD_W, CARD_H = 80, 110
CARD_RADIUS    = 6
SUITS = ["\u2660", "\u2665", "\u2666", "\u2663"]
RANKS = ["A","2","3","4","5","6","7","8","9","10","J","Q","K"]
RED_SUITS   = {"\u2665", "\u2666"}
BLACK_SUITS = {"\u2660", "\u2663"}

# Layout
STOCK_X, STOCK_Y   = 30, 30
WASTE_X, WASTE_Y   = 130, 30
FOUND_X             = [380 + i * 100 for i in range(4)]
FOUND_Y             = 30
TAB_X               = [30 + i * 138 for i in range(7)]
TAB_Y               = 180
TAB_OVERLAP         = 28   # face-down overlap
TAB_FACE_OVERLAP    = 22   # face-up overlap


def make_deck():
    deck = [{"suit": s, "rank": r, "face_up": False}
            for s in SUITS for r in RANKS]
    random.shuffle(deck)
    return deck

def card_color(card):
    return RED if card["suit"] in RED_SUITS else BLACK

def rank_value(card):
    return RANKS.index(card["rank"])

def draw_card(surf, card, x, y, selected=False, small=False):
    r = pygame.Rect(x, y, CARD_W, CARD_H)
    if selected:
        pygame.draw.rect(surf, HIGHLIGHT, (x-3, y-3, CARD_W+6, CARD_H+6), border_radius=CARD_RADIUS+2)
    if not card["face_up"]:
        pygame.draw.rect(surf, CARD_BACK, r, border_radius=CARD_RADIUS)
        pygame.draw.rect(surf, (60, 100, 220), r, 2, border_radius=CARD_RADIUS)
        # Pattern
        for row in range(3):
            for col in range(3):
                pygame.draw.rect(surf, (50, 90, 200),
                    (x+8+col*22, y+10+row*30, 16, 22), border_radius=2)
        return
    pygame.draw.rect(surf, CARD_BG, r, border_radius=CARD_RADIUS)
    pygame.draw.rect(surf, DARK_GRAY, r, 1, border_radius=CARD_RADIUS)
    color = card_color(card)
    # Top-left: rank and suit on same line
    label = card["rank"] + card["suit"]
    tl = _render_suit(rank_font, label, color)
    surf.blit(tl, (x+4, y+3))
    # Big center suit
    center_s = _render_suit(big_font, card["suit"], color)
    surf.blit(center_s, (x + CARD_W//2 - center_s.get_width()//2,
                          y + CARD_H//2 - center_s.get_height()//2))
    # Bottom-right (flipped)
    br = _render_suit(rank_font, label, color)
    surf.blit(br, (x + CARD_W - br.get_width() - 4, y + CARD_H - br.get_height() - 4))

def draw_slot(surf, x, y, label=""):
    r = pygame.Rect(x, y, CARD_W, CARD_H)
    pygame.draw.rect(surf, SLOT_COLOR, r, border_radius=CARD_RADIUS)
    pygame.draw.rect(surf, SLOT_BORDER, r, 2, border_radius=CARD_RADIUS)
    if label:
        t = font.render(label, True, SLOT_BORDER)
        surf.blit(t, (x + CARD_W//2 - t.get_width()//2,
                      y + CARD_H//2 - t.get_height()//2))

class Game:
    def __init__(self):
        self.reset()

    def reset(self):
        deck = make_deck()
        self.tableau  = [[] for _ in range(7)]
        self.foundations = [[] for _ in range(4)]  # \u2660\u2665\u2666\u2663
        self.stock    = []
        self.waste    = []
        self.selected = None   # (source, index) where index = card index in pile
        self.score    = 0
        self.moves    = 0
        self.won      = False
        self.high_score = get_high_score(GAME_NAME)
        self.new_high   = False
        self.auto_complete_available = False
        self.history  = []   # list of snapshots for undo
        self.stock_cycles = 0  # how many times stock has been recycled

        # Deal tableau
        idx = 0
        for col in range(7):
            for row in range(col + 1):
                card = deck[idx]; idx += 1
                card["face_up"] = (row == col)
                self.tableau[col].append(card)
        self.stock = deck[idx:]

    def get_foundation_idx(self, suit):
        return SUITS.index(suit)

    def can_place_on_foundation(self, card, foundation):
        if not foundation:
            return card["rank"] == "A"
        top = foundation[-1]
        return (top["suit"] == card["suit"] and
                rank_value(card) == rank_value(top) + 1)

    def can_place_on_tableau(self, card, col):
        tab = self.tableau[col]
        if not tab:
            return card["rank"] == "K"
        top = tab[-1]
        if not top["face_up"]:
            return False
        return (card_color(card) != card_color(top) and
                rank_value(card) == rank_value(top) - 1)

    def try_auto_to_foundation(self, card, source_pile, source_idx=None):
        fi = self.get_foundation_idx(card["suit"])
        if self.can_place_on_foundation(card, self.foundations[fi]):
            self.save_state()
            self.foundations[fi].append(card)
            if source_idx is not None:
                source_pile.pop(source_idx)
            else:
                source_pile.remove(card)
            self.score += 10
            self.moves += 1
            if source_pile and not source_pile[-1]["face_up"]:
                source_pile[-1]["face_up"] = True
                self.score += 5
            self.check_win()
            return True
        return False

    def save_state(self):
        """Push a deep-copyable snapshot onto the undo stack (max 20)."""
        snap = {
            "tableau":     [[c.copy() for c in col] for col in self.tableau],
            "foundations": [[c.copy() for c in f]   for f   in self.foundations],
            "stock":       [c.copy() for c in self.stock],
            "waste":       [c.copy() for c in self.waste],
            "score":       self.score,
            "moves":       self.moves,
            "stock_cycles": self.stock_cycles,
        }
        self.history.append(snap)
        if len(self.history) > 20:
            self.history.pop(0)

    def undo(self):
        if not self.history:
            return
        snap = self.history.pop()
        self.tableau     = [[c.copy() for c in col] for col in snap["tableau"]]
        self.foundations = [[c.copy() for c in f]   for f   in snap["foundations"]]
        self.stock       = [c.copy() for c in snap["stock"]]
        self.waste       = [c.copy() for c in snap["waste"]]
        self.score       = snap["score"]
        self.moves       = snap["moves"]
        self.stock_cycles = snap["stock_cycles"]
        self.selected    = None
        self.won         = False

    def click_stock(self):
        if self.stock:
            self.save_state()
            card = self.stock.pop()
            card["face_up"] = True
            self.waste.append(card)
            self.moves += 1
        else:
            # Reset stock from waste - score resets to 0 each cycle
            self.save_state()
            self.waste.reverse()
            for c in self.waste:
                c["face_up"] = False
            self.stock = self.waste
            self.waste = []
            self.stock_cycles += 1
            self.score = 0
            self.moves += 1

    def check_win(self):
        if all(len(f) == 13 for f in self.foundations):
            self.won = True
            if save_high_score(GAME_NAME, self.score):
                self.new_high = True
            self.high_score = get_high_score(GAME_NAME)

    def check_auto_complete(self):
        # Can auto-complete if all tableau cards are face-up and stock/waste empty
        if self.stock or self.waste:
            return False
        for col in self.tableau:
            for card in col:
                if not card["face_up"]:
                    return False
        return True

    def auto_complete_step(self):
        """Move one card to foundation. Returns True if moved."""
        # Try waste first
        if self.waste:
            card = self.waste[-1]
            fi = self.get_foundation_idx(card["suit"])
            if self.can_place_on_foundation(card, self.foundations[fi]):
                self.foundations[fi].append(self.waste.pop())
                self.score += 10
                self.check_win()
                return True
        # Try tableau columns - pick lowest rank available to play (ensures correct order)
        best_col = None
        best_rank = 999
        for col in range(7):
            if self.tableau[col]:
                card = self.tableau[col][-1]
                fi = self.get_foundation_idx(card["suit"])
                if self.can_place_on_foundation(card, self.foundations[fi]):
                    rv = rank_value(card)
                    if rv < best_rank:
                        best_rank = rv
                        best_col = col
        if best_col is not None:
            card = self.tableau[best_col].pop()
            self.foundations[self.get_foundation_idx(card["suit"])].append(card)
            self.score += 10
            self.check_win()
            return True
        return False

    def get_card_pos(self, source):
        """Return (pile, card_index, x, y) for a click source string."""
        pass

    def handle_click(self, mx, my):
        # Stock click
        if pygame.Rect(STOCK_X, STOCK_Y, CARD_W, CARD_H).collidepoint(mx, my):
            self.selected = None
            self.click_stock()
            return

        # Double-click waste top to foundation
        if (self.waste and
                pygame.Rect(WASTE_X, WASTE_Y, CARD_W, CARD_H).collidepoint(mx, my)):
            if self.selected and self.selected[0] == "waste":
                self.try_auto_to_foundation(self.waste[-1], self.waste)
                self.selected = None
                return
            self.selected = ("waste", len(self.waste)-1)
            return

        # Foundation clicks
        for i, fx in enumerate(FOUND_X):
            if pygame.Rect(fx, FOUND_Y, CARD_W, CARD_H).collidepoint(mx, my):
                if self.selected:
                    self.move_selected_to_foundation(i)
                self.selected = None
                return

        # Tableau clicks
        for col in range(7):
            tx = TAB_X[col]
            tab = self.tableau[col]
            if not tab:
                slot_r = pygame.Rect(tx, TAB_Y, CARD_W, CARD_H)
                if slot_r.collidepoint(mx, my):
                    if self.selected:
                        self.move_selected_to_tableau(col)
                        self.selected = None
                    return
                continue

            # Find which card was clicked - iterate top to bottom so topmost wins
            clicked_i = None
            for i in range(len(tab) - 1, -1, -1):
                cy = self.card_y(col, i)
                if pygame.Rect(tx, cy, CARD_W, CARD_H).collidepoint(mx, my):
                    clicked_i = i
                    break

            if clicked_i is not None:
                card = tab[clicked_i]
                if not card["face_up"]:
                    if clicked_i == len(tab) - 1:
                        card["face_up"] = True
                        self.moves += 1
                    self.selected = None
                    return
                # If something is already selected, try to move it here
                if self.selected:
                    self.move_selected_to_tableau(col)
                    self.selected = None
                    return
                # Otherwise select from this card downward
                self.selected = ("tab", col, clicked_i)
                return

    def card_y(self, col, idx):
        tab = self.tableau[col]
        y = TAB_Y
        for i in range(min(idx, len(tab))):
            y += TAB_FACE_OVERLAP if tab[i]["face_up"] else TAB_OVERLAP
        return y

    def move_selected_to_foundation(self, fi):
        if not self.selected:
            return
        src = self.selected[0]
        if src == "waste":
            card = self.waste[-1]
            if self.can_place_on_foundation(card, self.foundations[fi]):
                self.save_state()
                self.foundations[fi].append(self.waste.pop())
                self.score += 10; self.moves += 1
                self.check_win()
        elif src == "tab":
            col, idx = self.selected[1], self.selected[2]
            if idx == len(self.tableau[col])-1:  # Only top card to foundation
                card = self.tableau[col][-1]
                if self.can_place_on_foundation(card, self.foundations[fi]):
                    self.save_state()
                    self.foundations[fi].append(self.tableau[col].pop())
                    self.score += 10; self.moves += 1
                    if self.tableau[col] and not self.tableau[col][-1]["face_up"]:
                        self.tableau[col][-1]["face_up"] = True
                        self.score += 5
                    self.check_win()

    def move_selected_to_tableau(self, dest_col):
        if not self.selected:
            return
        src = self.selected[0]
        if src == "waste":
            card = self.waste[-1]
            if self.can_place_on_tableau(card, dest_col):
                self.save_state()
                self.tableau[dest_col].append(self.waste.pop())
                self.score += 5; self.moves += 1
        elif src == "tab":
            src_col, src_idx = self.selected[1], self.selected[2]
            if src_col == dest_col:
                return
            cards = self.tableau[src_col][src_idx:]
            if cards and self.can_place_on_tableau(cards[0], dest_col):
                self.save_state()
                self.tableau[dest_col].extend(cards)
                del self.tableau[src_col][src_idx:]
                self.moves += 1; self.score += 5
                if self.tableau[src_col] and not self.tableau[src_col][-1]["face_up"]:
                    self.tableau[src_col][-1]["face_up"] = True
                    self.score += 5

    def draw(self):
        screen.fill(BG)

        # HUD
        pygame.draw.rect(screen, (0, 70, 0), (0, 0, WIDTH, 160))
        score_t = font.render(f"Score: {self.score}", True, WHITE)
        moves_t = font.render(f"Moves: {self.moves}", True, WHITE)
        hi_t    = font.render(f"Best: {self.high_score}", True, GOLD)
        cycle_t = font.render(f"Cycle: {self.stock_cycles + 1}", True, (200, 200, 150))
        screen.blit(score_t, (10, 148))
        screen.blit(moves_t, (150, 148))
        screen.blit(hi_t,    (300, 148))
        screen.blit(cycle_t, (450, 148))

        hint_t = small_font.render("D-click card to send to foundation  |  U / Ctrl+Z = undo  |  R = new game", True, (150, 220, 150))
        screen.blit(hint_t, (WIDTH - hint_t.get_width() - 10, 150))

        # Undo button
        undo_col = (60, 100, 60) if self.history else (60, 60, 60)
        undo_r = pygame.Rect(WIDTH - 100, HEIGHT - 50, 90, 36)
        pygame.draw.rect(screen, undo_col, undo_r, border_radius=8)
        pygame.draw.rect(screen, WHITE, undo_r, 1, border_radius=8)
        ut = font.render("Undo", True, WHITE)
        screen.blit(ut, ut.get_rect(center=undo_r.center))

        # Stock
        if self.stock:
            draw_card(screen, self.stock[-1], STOCK_X, STOCK_Y)
        else:
            draw_slot(screen, STOCK_X, STOCK_Y, "↺")

        # Waste
        if self.waste:
            draw_card(screen, self.waste[-1], WASTE_X, WASTE_Y,
                      selected=(self.selected and self.selected[0]=="waste"))
        else:
            draw_slot(screen, WASTE_X, WASTE_Y, "")

        # Foundations
        for i, fx in enumerate(FOUND_X):
            if self.foundations[i]:
                draw_card(screen, self.foundations[i][-1], fx, FOUND_Y)
            else:
                draw_slot(screen, fx, FOUND_Y, SUITS[i])

        # Tableau
        for col in range(7):
            tx = TAB_X[col]
            tab = self.tableau[col]
            draw_slot(screen, tx, TAB_Y)
            for i, card in enumerate(tab):
                cy = self.card_y(col, i)
                sel = (self.selected and self.selected[0]=="tab" and
                       self.selected[1]==col and self.selected[2]<=i)
                draw_card(screen, card, tx, cy, selected=sel)

        # Auto-complete button
        if self.check_auto_complete() and not self.won:
            btn_r = pygame.Rect(WIDTH//2 - 80, HEIGHT - 50, 160, 36)
            pygame.draw.rect(screen, GOLD, btn_r, border_radius=8)
            at = font.render("Auto Complete", True, BLACK)
            screen.blit(at, at.get_rect(center=btn_r.center))

        if self.won:
            overlay = pygame.Surface((WIDTH, HEIGHT), pygame.SRCALPHA)
            overlay.fill((0, 0, 0, 160))
            screen.blit(overlay, (0, 0))
            wt = big_font.render("You Win!", True, GOLD)
            st = font.render(f"Score: {self.score}  |  Moves: {self.moves}", True, WHITE)
            rt = font.render("Press R for a new game", True, WHITE)
            screen.blit(wt, wt.get_rect(center=(WIDTH//2, HEIGHT//2 - 50)))
            screen.blit(st, st.get_rect(center=(WIDTH//2, HEIGHT//2)))
            screen.blit(rt, rt.get_rect(center=(WIDTH//2, HEIGHT//2 + 40)))
            if self.new_high:
                nb = font.render("NEW HIGH SCORE!", True, GOLD)
                screen.blit(nb, nb.get_rect(center=(WIDTH//2, HEIGHT//2 + 70)))


game = Game()
auto_complete_mode = False
auto_timer = 0
last_click_time = 0
last_click_pos  = None
DOUBLE_CLICK_MS = 400

running = True
while running:
    dt = clock.tick(60)

    # Auto-complete stepping
    if auto_complete_mode and not game.won:
        auto_timer += dt
        if auto_timer > 80:
            auto_timer = 0
            if not game.auto_complete_step():
                auto_complete_mode = False

    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False
        if event.type == pygame.KEYDOWN:
            if event.key == pygame.K_ESCAPE:
                running = False
        if event.type == pygame.KEYDOWN:
            if event.key == pygame.K_r:
                game.reset()
                auto_complete_mode = False
            elif event.key == pygame.K_u:
                game.undo()
            elif event.key == pygame.K_z and (pygame.key.get_mods() & pygame.KMOD_META or pygame.key.get_mods() & pygame.KMOD_CTRL):
                game.undo()

        if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1 and not game.won:
            mx, my = event.pos

            # Undo button
            undo_r = pygame.Rect(WIDTH - 100, HEIGHT - 50, 90, 36)
            if undo_r.collidepoint(mx, my):
                game.undo()
                continue

            # Auto-complete button
            btn_r = pygame.Rect(WIDTH//2 - 80, HEIGHT - 50, 160, 36)
            if game.check_auto_complete() and btn_r.collidepoint(mx, my):
                auto_complete_mode = True
                continue

            now = pygame.time.get_ticks()
            double = (last_click_pos and
                      abs(mx - last_click_pos[0]) < 10 and
                      abs(my - last_click_pos[1]) < 10 and
                      now - last_click_time < DOUBLE_CLICK_MS)

            if double:
                # Double-click: try to send top card of clicked pile to foundation
                # Waste
                if pygame.Rect(WASTE_X, WASTE_Y, CARD_W, CARD_H).collidepoint(mx, my) and game.waste:
                    game.try_auto_to_foundation(game.waste[-1], game.waste)
                    game.selected = None
                else:
                    # Tableau top card
                    for col in range(7):
                        tab = game.tableau[col]
                        if tab:
                            cy = game.card_y(col, len(tab)-1)
                            if pygame.Rect(TAB_X[col], cy, CARD_W, CARD_H).collidepoint(mx, my):
                                game.try_auto_to_foundation(tab[-1], tab)
                                game.selected = None
                                break
                last_click_time = 0
                last_click_pos  = None
            else:
                game.handle_click(mx, my)
                last_click_time = now
                last_click_pos  = (mx, my)

    game.draw()
    pygame.display.flip()

pygame.quit()
sys.exit()
