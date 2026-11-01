import os
os.environ["PYGAME_HIDE_SUPPORT_PROMPT"] = "1"
import pygame
import random
import sys
from highscores import get_high_score, save_high_score

GAME_NAME = "hangman"
pygame.init()

WIDTH, HEIGHT = 800, 620
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Hangman")
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


BG         = (18, 20, 38)
WHITE      = (255, 255, 255)
BLACK      = (0, 0, 0)
GRAY       = (120, 120, 140)
LIGHT_GRAY = (180, 180, 200)
GOLD       = (255, 210, 50)
RED        = (220, 60, 60)
GREEN      = (60, 200, 100)
BLUE       = (80, 140, 255)
ORANGE     = (255, 150, 40)
PANEL      = (26, 30, 54)
GALLOWS    = (200, 190, 170)
ROPE       = (180, 160, 120)
BODY_COL   = (220, 180, 140)

title_font  = pygame.font.SysFont("Arial", 36, bold=True)
word_font   = pygame.font.SysFont("Arial", 38, bold=True)
letter_font = pygame.font.SysFont("Arial", 22, bold=True)
info_font   = pygame.font.SysFont("Arial", 18)
small_font  = pygame.font.SysFont("Arial", 15)
score_font  = pygame.font.SysFont("Arial", 26, bold=True)
clock       = pygame.time.Clock()

MAX_WRONG = 7

FALLBACK_WORD_LISTS = {
    "Easy": [
        "APPLE", "BEACH", "BREAD", "BRICK", "CABIN", "CANDY", "CHAIR", "CHEESE",
        "CLOCK", "CLOUD", "COAST", "DANCE", "DREAM", "EARTH", "FLAME", "FLOWER",
        "FOREST", "FRIEND", "GARDEN", "GIANT", "GRAPE", "GRASS", "HAPPY", "HOUSE",
        "JUICE", "KNIFE", "LEMON", "LIGHT", "MAGIC", "MAPLE", "MONEY", "MOUSE",
        "MUSIC", "NIGHT", "OCEAN", "PAINT", "PAPER", "PARTY", "PEACH", "PENCIL",
        "PIANO", "PILOT", "PIZZA", "PLANT", "QUEEN", "RABBIT", "RADIO", "RIVER",
        "ROBOT", "SALAD", "SCHOOL", "SHADOW", "SILVER", "SMILE", "SOCCER", "SPRING",
        "STAR", "STONE", "STREET", "SUMMER", "SUNSET", "TABLE", "TIGER", "TRAIN",
        "TRAVEL", "WATER", "WHALE", "WINDOW", "WINTER", "ZEBRA"
    ],
    "Medium": [
        "ADVENTURE", "AIRPORT", "ANCIENT", "BALANCE", "BATTERY", "BEDROOM",
        "BLOSSOM", "CAPTAIN", "CARNIVAL", "CHIMNEY", "COMPASS", "CRYSTAL",
        "DESERT", "DIAMOND", "DINNER", "DRAGON", "EMERALD", "FACTORY", "FEATHER",
        "FESTIVAL", "GALAXY", "GLACIER", "HAMMOCK", "HARBOR", "HORIZON", "ISLAND",
        "JOURNAL", "KINGDOM", "KITCHEN", "LIBRARY", "LIGHTER", "MARKET", "MEADOW",
        "MIRACLE", "MONSTER", "MOUNTAIN", "MUSEUM", "NOTEBOOK", "ORCHARD", "PACKAGE",
        "PAINTING", "PASSENGER", "PLANET", "POPCORN", "PRINTER", "PYRAMID", "RAILWAY",
        "RAINSTORM", "ROCKET", "SAPPHIRE", "SCULPTURE", "SEASHELL", "SHERIFF",
        "SKYLINE", "SPACESHIP", "STADIUM", "SUNFLOWER", "TELEGRAM", "TREASURE",
        "TRIANGLE", "UMBRELLA", "VACATION", "VOLCANO", "WATERFALL", "WILDLIFE"
    ],
    "Hard": [
        "ABRUPTLY", "ABSURDITY", "ALGORITHM", "APOCALYPSE", "ASTRONOMY", "AVALANCHE",
        "BARRICADE", "BLUEPRINT", "BUZZWORDS", "CROQUET", "CRYPTIC", "DIZZYING",
        "EQUINOX", "EXHAUSTION", "FLAPJACKS", "FRACTURE", "GALVANIZE", "HYPNOTIC",
        "ICEBOXES", "INJECTION", "JACKPOT", "JAWBREAKER", "JUKEBOX", "KNOWLEDGE",
        "LUXURIOUS", "MICROWAVE", "MNEMONIC", "MYSTIFYING", "NIGHTCLUB", "NOWADAYS",
        "OBFUSCATE", "OXYGENATE", "PAJAMAS", "PIXELATED", "PNEUMONIA", "QUICKSAND",
        "QUIZZICAL", "RHYTHMIC", "SCRABBLE", "STRENGTH", "TRANSCRIPT", "VAPORIZE",
        "VORTEXES", "WAVELENGTH", "WHIPLASH", "WITNESSING", "XYLOPHONE", "ZIGZAGGED"
    ],
}


def load_words(filename, fallback_words):
    words = []
    try:
        with open(filename, "r", encoding="utf-8") as f:
            for line in f:
                word = line.strip().upper()
                if word.isalpha():
                    words.append(word)
    except FileNotFoundError:
        pass
    return words if words else fallback_words[:]


WORD_LISTS = {
    "Easy": load_words("words_easy.txt", FALLBACK_WORD_LISTS["Easy"]),
    "Medium": load_words("words_medium.txt", FALLBACK_WORD_LISTS["Medium"]),
    "Hard": load_words("words_hard.txt", FALLBACK_WORD_LISTS["Hard"]),
}

DIFFICULTIES = ["Easy", "Medium", "Hard"]
DIFF_COLORS = {"Easy": GREEN, "Medium": ORANGE, "Hard": RED}


def draw_gallows(surface, wrong, gx, gy):
    lw = 5
    pygame.draw.line(surface, GALLOWS, (gx, gy + 260), (gx + 200, gy + 260), lw + 2)
    pygame.draw.line(surface, GALLOWS, (gx + 60, gy), (gx + 60, gy + 260), lw)
    pygame.draw.line(surface, GALLOWS, (gx + 60, gy), (gx + 160, gy), lw)
    pygame.draw.line(surface, GALLOWS, (gx + 60, gy + 60), (gx + 110, gy), lw - 1)

    if wrong >= 1:
        pygame.draw.line(surface, ROPE, (gx + 160, gy), (gx + 160, gy + 40), 3)

    hx, hy = gx + 160, gy + 40

    if wrong >= 1:
        pygame.draw.circle(surface, BODY_COL, (hx, hy + 22), 22, 3)

        if wrong >= 5:
            for ex, ey in [(hx - 8, hy + 16), (hx + 8, hy + 16)]:
                pygame.draw.line(surface, RED, (ex - 5, ey - 5), (ex + 5, ey + 5), 2)
                pygame.draw.line(surface, RED, (ex + 5, ey - 5), (ex - 5, ey + 5), 2)
        else:
            pygame.draw.circle(surface, BODY_COL, (hx - 8, hy + 16), 3)
            pygame.draw.circle(surface, BODY_COL, (hx + 8, hy + 16), 3)

        if wrong >= 6:
            pygame.draw.arc(surface, RED, pygame.Rect(hx - 8, hy + 26, 16, 10), 3.14, 2 * 3.14, 2)
        else:
            pygame.draw.arc(surface, BODY_COL, pygame.Rect(hx - 6, hy + 22, 12, 8), 0, 3.14, 2)

    if wrong >= 2:
        pygame.draw.line(surface, BODY_COL, (hx, hy + 44), (hx, hy + 110), 3)
    if wrong >= 3:
        pygame.draw.line(surface, BODY_COL, (hx, hy + 60), (hx - 30, hy + 90), 3)
    if wrong >= 4:
        pygame.draw.line(surface, BODY_COL, (hx, hy + 60), (hx + 30, hy + 90), 3)
    if wrong >= 5:
        pygame.draw.line(surface, BODY_COL, (hx, hy + 110), (hx - 28, hy + 155), 3)
    if wrong >= 6:
        pygame.draw.line(surface, BODY_COL, (hx, hy + 110), (hx + 28, hy + 155), 3)
    if wrong >= 7:
        pygame.draw.line(surface, RED, (hx - 35, hy + 170), (hx + 35, hy + 170), 3)


def draw_keyboard(surface, guessed, word):
    rows = ["QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"]
    start_y = 430

    for ri, row in enumerate(rows):
        total_w = len(row) * 42
        start_x = (WIDTH - total_w) // 2 + ri * 20

        for ci, ch in enumerate(row):
            kx = start_x + ci * 42
            ky = start_y + ri * 46
            kr = pygame.Rect(kx, ky, 36, 38)

            if ch in guessed:
                if ch in word:
                    color = GREEN
                    text_col = WHITE
                else:
                    color = (50, 50, 65)
                    text_col = (80, 80, 100)
            else:
                color = (60, 65, 100)
                text_col = WHITE

            pygame.draw.rect(surface, color, kr, border_radius=6)
            pygame.draw.rect(surface, (80, 85, 130), kr, 1, border_radius=6)

            ls = letter_font.render(ch, True, text_col)
            surface.blit(ls, ls.get_rect(center=kr.center))


class Game:
    def __init__(self, difficulty="Medium"):
        self.difficulty = difficulty
        self.streak = 0
        self.high_score = get_high_score(GAME_NAME)
        self.last_word = None
        self.round_score = 0
        self.reset()

    def choose_word(self):
        pool = WORD_LISTS.get(self.difficulty, [])
        if not pool:
            pool = FALLBACK_WORD_LISTS["Medium"]

        if len(pool) == 1:
            return pool[0]

        choices = [w for w in pool if w != self.last_word]
        if not choices:
            choices = pool[:]

        return random.choice(choices)

    def reset(self):
        self.word = self.choose_word()
        self.last_word = self.word
        self.guessed = set()
        self.wrong = 0
        self.won = False
        self.lost = False
        self.new_high = False
        self.hint_used = False
        self.hint_letter = None
        self.round_score = 0
        self.high_score = get_high_score(GAME_NAME)

    def guess(self, letter):
        if self.won or self.lost:
            return

        if letter in self.guessed:
            return

        self.guessed.add(letter)

        if letter not in self.word:
            self.wrong += 1
            if self.wrong >= MAX_WRONG:
                self.lost = True
                self.streak = 0
            return

        if all(c in self.guessed for c in self.word):
            self.won = True
            diff_bonus = {"Easy": 1, "Medium": 2, "Hard": 3}[self.difficulty]
            score = (MAX_WRONG - self.wrong) * 10 * diff_bonus

            if not self.hint_used:
                score += 10

            self.streak += 1
            score += self.streak * 5
            self.round_score = score

            if save_high_score(GAME_NAME, score):
                self.new_high = True

            self.high_score = get_high_score(GAME_NAME)

    def use_hint(self):
        if self.hint_used or self.won or self.lost:
            return

        remaining = [c for c in set(self.word) if c not in self.guessed]
        if remaining:
            self.hint_letter = random.choice(remaining)
            self.guessed.add(self.hint_letter)
            self.hint_used = True

            if all(c in self.guessed for c in self.word):
                self.won = True
                diff_bonus = {"Easy": 1, "Medium": 2, "Hard": 3}[self.difficulty]
                score = (MAX_WRONG - self.wrong) * 10 * diff_bonus
                self.streak += 1
                score += self.streak * 5
                self.round_score = score

                if save_high_score(GAME_NAME, score):
                    self.new_high = True

                self.high_score = get_high_score(GAME_NAME)

    def change_difficulty(self, new_difficulty):
        self.difficulty = new_difficulty
        self.streak = 0
        self.reset()

    def next_round(self):
        streak = self.streak if self.won else 0
        self.reset()
        self.streak = streak

    def draw(self):
        screen.fill(BG)

        pygame.draw.rect(screen, PANEL, (0, 0, WIDTH, 75))
        pygame.draw.line(screen, BLUE, (0, 75), (WIDTH, 75), 1)

        title_s = title_font.render("Hangman", True, WHITE)
        screen.blit(title_s, (30, 18))

        for i, diff in enumerate(DIFFICULTIES):
            dr = pygame.Rect(WIDTH - 290 + i * 90, 18, 80, 38)
            active = diff == self.difficulty
            col = DIFF_COLORS[diff]

            pygame.draw.rect(screen, col if active else PANEL, dr, border_radius=8)
            pygame.draw.rect(screen, col, dr, 2, border_radius=8)

            dt = small_font.render(diff, True, WHITE)
            screen.blit(dt, dt.get_rect(center=dr.center))

        draw_gallows(screen, self.wrong, 40, 80)

        wc = info_font.render(
            f"Wrong: {self.wrong} / {MAX_WRONG}",
            True,
            RED if self.wrong >= MAX_WRONG - 2 else LIGHT_GRAY
        )
        screen.blit(wc, (40, 360))

        hi_s = small_font.render(f"Best: {self.high_score}", True, GOLD)
        screen.blit(hi_s, (40, 385))

        new_btn = pygame.Rect(40, 448, 100, 32)
        pygame.draw.rect(screen, (70, 90, 130), new_btn, border_radius=7)
        pygame.draw.rect(screen, BLUE, new_btn, 1, border_radius=7)
        nt = small_font.render("New Word", True, WHITE)
        screen.blit(nt, nt.get_rect(center=new_btn.center))

        if not self.hint_used and not self.won and not self.lost:
            hr = pygame.Rect(40, 408, 100, 32)
            pygame.draw.rect(screen, (60, 80, 140), hr, border_radius=7)
            pygame.draw.rect(screen, BLUE, hr, 1, border_radius=7)
            ht = small_font.render("Hint (-pts)", True, WHITE)
            screen.blit(ht, ht.get_rect(center=hr.center))
        elif self.hint_used:
            ht = small_font.render(f"Hint used: {self.hint_letter}", True, ORANGE)
            screen.blit(ht, (40, 415))

        word_y = 110
        letter_spacing = min(54, (WIDTH - 310) // max(len(self.word), 1))
        total_word_w = len(self.word) * letter_spacing
        word_x = 310 + (WIDTH - 310 - total_word_w) // 2

        for i, ch in enumerate(self.word):
            lx = word_x + i * letter_spacing
            pygame.draw.line(screen, LIGHT_GRAY, (lx, word_y + 52), (lx + 38, word_y + 52), 2)

            if ch in self.guessed or self.lost:
                col = ORANGE if ch == self.hint_letter else WHITE
                ls = word_font.render(ch, True, col)
                screen.blit(ls, ls.get_rect(centerx=lx + 19, y=word_y + 12))

        cat_s = info_font.render(f"Difficulty: {self.difficulty}", True, DIFF_COLORS[self.difficulty])
        screen.blit(cat_s, (310, 175))

        if self.streak > 1:
            streak_s = info_font.render(f"Streak: {self.streak}", True, ORANGE)
            screen.blit(streak_s, (310, 200))

        ctrl_1 = small_font.render(
            "Type letters to guess  |  Space = new word  |  1 = Easy  2 = Medium  3 = Hard",
            True,
            GRAY
        )
        screen.blit(ctrl_1, ctrl_1.get_rect(centerx=WIDTH // 2, y=390))

        ctrl_2 = small_font.render(
            "Click difficulty buttons above, use Hint, or click New Word on the left",
            True,
            GRAY
        )
        screen.blit(ctrl_2, ctrl_2.get_rect(centerx=WIDTH // 2, y=410))

        draw_keyboard(screen, self.guessed, self.word)

        if self.won or self.lost:
            overlay = pygame.Surface((WIDTH, HEIGHT), pygame.SRCALPHA)
            overlay.fill((0, 0, 0, 160))
            screen.blit(overlay, (0, 0))

            if self.won:
                msg = title_font.render("You got it!", True, GREEN)
                sub = info_font.render("Press Space for a new word", True, WHITE)
                score_msg = score_font.render(f"+{self.round_score} points", True, GOLD)

                screen.blit(msg, msg.get_rect(center=(WIDTH // 2, HEIGHT // 2 - 55)))
                screen.blit(score_msg, score_msg.get_rect(center=(WIDTH // 2, HEIGHT // 2 - 10)))
                screen.blit(sub, sub.get_rect(center=(WIDTH // 2, HEIGHT // 2 + 28)))

                if self.new_high:
                    nb = info_font.render("NEW HIGH SCORE!", True, GOLD)
                    screen.blit(nb, nb.get_rect(center=(WIDTH // 2, HEIGHT // 2 + 58)))
            else:
                msg = title_font.render(f"The word was: {self.word}", True, RED)
                sub = info_font.render("Press Space for a new word", True, WHITE)
                sub2 = info_font.render("Or press 1, 2, or 3 to change difficulty", True, LIGHT_GRAY)

                screen.blit(msg, msg.get_rect(center=(WIDTH // 2, HEIGHT // 2 - 45)))
                screen.blit(sub, sub.get_rect(center=(WIDTH // 2, HEIGHT // 2 + 5)))
                screen.blit(sub2, sub2.get_rect(center=(WIDTH // 2, HEIGHT // 2 + 35)))


game = Game("Medium")

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
            if event.key == pygame.K_SPACE:
                game.next_round()

            elif event.key == pygame.K_1:
                game.change_difficulty("Easy")

            elif event.key == pygame.K_2:
                game.change_difficulty("Medium")

            elif event.key == pygame.K_3:
                game.change_difficulty("Hard")

            else:
                key = pygame.key.name(event.key).upper()
                if len(key) == 1 and key.isalpha():
                    game.guess(key)

        if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            mx, my = event.pos

            for i, diff in enumerate(DIFFICULTIES):
                dr = pygame.Rect(WIDTH - 290 + i * 90, 18, 80, 38)
                if dr.collidepoint(mx, my):
                    game.change_difficulty(diff)

            hr = pygame.Rect(40, 408, 100, 32)
            if hr.collidepoint(mx, my):
                game.use_hint()

            nr = pygame.Rect(40, 448, 100, 32)
            if nr.collidepoint(mx, my):
                game.next_round()

            if not game.won and not game.lost:
                rows = ["QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"]
                for ri, row in enumerate(rows):
                    total_w = len(row) * 42
                    start_x = (WIDTH - total_w) // 2 + ri * 20

                    for ci, ch in enumerate(row):
                        kx = start_x + ci * 42
                        ky = 430 + ri * 46
                        if pygame.Rect(kx, ky, 36, 38).collidepoint(mx, my):
                            game.guess(ch)

    game.draw()
    pygame.display.flip()

pygame.quit()
sys.exit()
