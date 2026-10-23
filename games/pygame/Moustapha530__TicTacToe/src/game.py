from pygame import init, quit, KEYDOWN, K_r, MOUSEBUTTONUP, QUIT
from pygame.display import set_mode, set_caption, update
from pygame.event import get
from pygame.font import SysFont
from pygame.mouse import get_pos

from grid import draw_grid, draw_markers


class Game:
    def __init__(self) -> None:
        self.markers = [[0, 0, 0], [0, 0, 0], [0, 0, 0]]
        self.current_player = 1
        self.game_over = False
        self.message = ""
        init()

        screen = set_mode((300, 300))
        set_caption("TicTacToe")

        self.current_player = 1
        self.running = True
        self.game_over = False
        self.message = ""

    def check_winner(self) -> int:
        for row in self.markers:
            s = sum(row)
            if s == 3:
                return 1
            if s == -3:
                return 2

        for col in range(3):
            s = self.markers[0][col] + self.markers[1][col] + self.markers[2][col]
            if s == 3:
                return 1
            if s == -3:
                return 2

        diag1 = self.markers[0][0] + self.markers[1][1] + self.markers[2][2]
        diag2 = self.markers[0][2] + self.markers[1][1] + self.markers[2][0]

        if diag1 == 3 or diag2 == 3:
            return 1
        if diag1 == -3 or diag2 == -3:
            return 2

        return 0
    
    def draw_end_screen(self, screen) -> None:
        font = SysFont(None, 45)
        screen.fill((255, 255, 200))
        text = font.render(self.message, True, (0, 0, 255))
        screen.blit(text, (20, 120))

    def is_draw(self) -> bool:
        for row in self.markers:
            if 0 in row:
                return False
        return self.check_winner() == 0
    

    def run(self) -> None:
        screen = set_mode((300, 300))
        set_caption("TicTacToe")

        running = True
        while running:
            draw_grid(screen)
            draw_markers(screen, self.markers)

            for event in get():
                if event.type == QUIT:
                    running = False

                if not self.game_over and event.type == MOUSEBUTTONUP:
                    x, y = get_pos()
                    row, col = y // 100, x // 100

                    if self.markers[row][col] == 0:
                        self.markers[row][col] = self.current_player

                        winner = self.check_winner()
                        if winner:
                            self.game_over = True
                            self.message = f"Player {winner} wins!"
                        elif self.is_draw():
                            self.game_over = True
                            self.message = "Draw!"

                        self.current_player *= -1

                elif self.game_over and event.type == KEYDOWN and event.key == K_r:
                    for r in range(3):
                        for c in range(3):
                            self.markers[r][c] = 0
                    self.game_over = False
                    self.current_player = 1

            if self.game_over:
                self.draw_end_screen(screen)

            update()

        quit()