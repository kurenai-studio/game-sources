import pygame
from ui.buttons import Button
from ui.renderer import WINDOW_WIDTH, WINDOW_HEIGHT

class MenuUI:
    def __init__(self):
        pygame.init()
        self.screen = pygame.display.set_mode((WINDOW_WIDTH, WINDOW_HEIGHT))
        pygame.display.set_caption("Notty - Setup")
        self.clock = pygame.time.Clock()

        self.font_small = pygame.font.SysFont(None, 24)
        self.font_big = pygame.font.SysFont(None, 32)

        self.buttons = []
        self.selected_players = 2
        self.cpu1_ai = "easy"
        self.cpu2_ai = "easy"
        self.done = False

        self.create_buttons()

    def create_buttons(self):
        btn_width = 160
        btn_height = 40
        gap = 20
        color_bg = (60, 70, 90)
        color_text = (240, 240, 240)
        color_hover = (80, 90, 110)
        total_row_width = 2 * btn_width + gap
        start_x = (WINDOW_WIDTH - total_row_width) // 2
        
        y_p = 120
        p2_btn = Button(start_x, y_p, btn_width, btn_height, "2 Players", self.font_small, color_bg, color_text, color_hover)
        p3_btn = Button(start_x + btn_width + gap, y_p, btn_width, btn_height, "3 Players", self.font_small, color_bg, color_text, color_hover)

        y_c1 = 240
        cpu1_rand_btn = Button(start_x, y_c1, btn_width, btn_height, "CPU1: Easy", self.font_small, color_bg, color_text, color_hover)
        cpu1_greedy_btn = Button(start_x + btn_width + gap, y_c1, btn_width, btn_height, "CPU1: Hard", self.font_small, color_bg, color_text, color_hover)

        y_c2 = 340
        cpu2_rand_btn = Button(start_x, y_c2, btn_width, btn_height, "CPU2: Easy", self.font_small, color_bg, color_text, color_hover)
        cpu2_greedy_btn = Button(start_x + btn_width + gap, y_c2, btn_width, btn_height, "CPU2: Hard", self.font_small, color_bg, color_text, color_hover)

        start_btn = Button((WINDOW_WIDTH - 160) // 2, WINDOW_HEIGHT - 120, 160, btn_height, "Start Game", self.font_small, (255, 190, 0), (20, 20, 20), (255, 210, 50))

        def on_p2():
            self.selected_players = 2

        def on_p3():
            self.selected_players = 3

        def on_cpu1_rand():
            self.cpu1_ai = "easy"

        def on_cpu1_greedy():
            self.cpu1_ai = "hard"

        def on_cpu2_rand():
            self.cpu2_ai = "easy"

        def on_cpu2_greedy():
            self.cpu2_ai = "hard"

        def on_start():
            self.done = True

        p2_btn.on_click = on_p2
        p3_btn.on_click = on_p3
        cpu1_rand_btn.on_click = on_cpu1_rand
        cpu1_greedy_btn.on_click = on_cpu1_greedy
        cpu2_rand_btn.on_click = on_cpu2_rand
        cpu2_greedy_btn.on_click = on_cpu2_greedy
        start_btn.on_click = on_start

        self.buttons = [
            p2_btn, p3_btn,
            cpu1_rand_btn, cpu1_greedy_btn,
            cpu2_rand_btn, cpu2_greedy_btn,
            start_btn
        ]

    def draw(self):
        
        self.screen.fill((30, 35, 45)) 

        title = self.font_big.render("Notty", True, (255, 255, 255))
        self.screen.blit(title, ((WINDOW_WIDTH - title.get_width()) // 2, 40))

        txt_players = "Number of players: " + str(self.selected_players)
        t1 = self.font_small.render(txt_players, True, (255, 255, 255))
        self.screen.blit(t1, ((WINDOW_WIDTH - t1.get_width()) // 2, 90))

        txt_cpu1 = "CPU1 strategy: " + self.cpu1_ai
        t2 = self.font_small.render(txt_cpu1, True, (255, 255, 255))
        self.screen.blit(t2, ((WINDOW_WIDTH - t2.get_width()) // 2, 210))

        txt_cpu2 = "CPU2 strategy: " + self.cpu2_ai + " (only used if 3 players choosen)"
        t3 = self.font_small.render(txt_cpu2, True, (255, 255, 255))
        self.screen.blit(t3, ((WINDOW_WIDTH - t3.get_width()) // 2, 310))

        for b in self.buttons:
            b.draw(self.screen)

    def handle_events(self):
        mx, my = pygame.mouse.get_pos()
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                return False
            for b in self.buttons:
                b.handle_event(event)
        
        for b in self.buttons:
            b.update((mx, my))
            
        return True

    def run(self):
        running = True
        while running:
            running = self.handle_events()
            if not running:
                break
            if self.done:
                pygame.quit()
                return {
                    "num_players": self.selected_players,
                    "cpu_ai": [self.cpu1_ai, self.cpu2_ai]
                }
            self.draw()
            pygame.display.flip()
            self.clock.tick(60)

        pygame.quit()
        return None
