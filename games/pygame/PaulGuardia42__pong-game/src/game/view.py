import pygame

from .model import WINDOW_HEIGHT, WINDOW_WIDTH, PADDLE_HEIGHT, PADDLE_WIDTH


WHITE = (255, 255, 255)
BLACK = (10, 10, 18)
DARK = (22, 22, 32)
ACCENT = (102, 214, 255)


class PongView:
    def __init__(self, screen: pygame.Surface):
        self.screen = screen
        self.font = pygame.font.Font(None, 72)
        self.small_font = pygame.font.Font(None, 36)
        self.tiny_font = pygame.font.Font(None, 24)

    def render(self, model) -> None:
        self.screen.fill(BLACK)

        for y in range(0, WINDOW_HEIGHT, 20):
            pygame.draw.rect(self.screen, DARK, (WINDOW_WIDTH // 2 - 2, y, 4, 12))

        self._draw_paddle(model.left_paddle)
        self._draw_paddle(model.right_paddle)
        self._draw_ball(model.ball)

        left_text = self.font.render(str(model.left_score), True, WHITE)
        right_text = self.font.render(str(model.right_score), True, WHITE)
        self.screen.blit(left_text, (WINDOW_WIDTH // 2 - 90, 18))
        self.screen.blit(right_text, (WINDOW_WIDTH // 2 + 50, 18))

        if model.state == "menu":
            self.draw_menu()
        elif model.state == "game_over":
            self.draw_game_over(model)

    def _draw_paddle(self, paddle) -> None:
        pygame.draw.rect(self.screen, paddle.color, paddle.rect)

    def _draw_ball(self, ball) -> None:
        pygame.draw.ellipse(self.screen, WHITE, ball.rect)

    def draw_menu(self) -> None:
        title = self.font.render("PONG", True, WHITE)
        self.screen.blit(title, (WINDOW_WIDTH // 2 - title.get_width() // 2, WINDOW_HEIGHT // 2 - 110))

        option1 = self.small_font.render("Press 1 for 1 Player (vs CPU)", True, ACCENT)
        option2 = self.small_font.render("Press 2 for 2 Players (same keyboard)", True, ACCENT)
        prompt = self.small_font.render("Esc to quit", True, WHITE)

        self.screen.blit(option1, (WINDOW_WIDTH // 2 - option1.get_width() // 2, WINDOW_HEIGHT // 2 - 10))
        self.screen.blit(option2, (WINDOW_WIDTH // 2 - option2.get_width() // 2, WINDOW_HEIGHT // 2 + 40))
        self.screen.blit(prompt, (WINDOW_WIDTH // 2 - prompt.get_width() // 2, WINDOW_HEIGHT // 2 + 90))

    def draw_game_over(self, model) -> None:
        if model.mode == "single":
            message = "CPU WINS" if model.winner == "CPU" else "YOU WIN"
        else:
            message = f"{model.winner} WINS"

        winner_text = self.font.render(message, True, WHITE)
        self.screen.blit(winner_text, (WINDOW_WIDTH // 2 - winner_text.get_width() // 2, WINDOW_HEIGHT // 2 - 60))

        prompt = self.small_font.render("Press Enter or Space to return to menu", True, ACCENT)
        self.screen.blit(prompt, (WINDOW_WIDTH // 2 - prompt.get_width() // 2, WINDOW_HEIGHT // 2 + 30))

        controls = self.tiny_font.render("1 = 1 Player, 2 = 2 Players", True, WHITE)
        self.screen.blit(controls, (WINDOW_WIDTH // 2 - controls.get_width() // 2, WINDOW_HEIGHT // 2 + 75))
