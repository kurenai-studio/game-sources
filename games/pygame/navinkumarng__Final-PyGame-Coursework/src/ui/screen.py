import os
import time
import traceback

import pygame

from ui.buttons import Button
from ui.renderer import (
    Renderer,
    WINDOW_WIDTH,
    WINDOW_HEIGHT,
    CARD_WIDTH,
    CARD_HEIGHT,
    BOTTOM_MARGIN,
    DECK_X,
    DECK_Y_CENTER,
)
from ai.strat1 import strat1
from ai.strat2 import strat2



class Animation:
    def __init__(self, card, start_pos, end_pos, duration=0.5, face_down=False):
        self.card = card
        self.start_pos = start_pos
        self.end_pos = end_pos
        self.start_time = time.time()
        self.duration = duration
        self.finished = False
        self.face_down = face_down

    def get_current_pos(self):
        elapsed = time.time() - self.start_time
        t = min(elapsed / self.duration, 1.0)
        t = 1 - (1 - t) ** 3
        
        x = self.start_pos[0] + (self.end_pos[0] - self.start_pos[0]) * t
        y = self.start_pos[1] + (self.end_pos[1] - self.start_pos[1]) * t
        
        if elapsed >= self.duration:
            self.finished = True
            
        return (x, y)


class GameUI:
    def __init__(self, game):
        self.game = game
        pygame.init()
        self.screen = pygame.display.set_mode((WINDOW_WIDTH, WINDOW_HEIGHT))
        pygame.display.set_caption("Notty")
        self.clock = pygame.time.Clock()

        self.font_small = pygame.font.SysFont(None, 24)
        self.font_big = pygame.font.SysFont(None, 32)
        self.font_card = pygame.font.SysFont(None, 64, bold=True)

        self.card_front = None
        self.card_back = None
        self.load_assets()

        self.renderer = Renderer(
            self.screen,
            self.font_small,
            self.font_big,
            self.font_card,
            self.card_front,
            self.card_back,
        )

        self.buttons = []
        self.win_buttons = []
        self.mode = None
        self.initial_deal_done = False
        self.after_win_choice = None
        self.draw_amount_rects = []

        self.status_message = ""
        self.status_ticks = 0

        self.selected_cards = []
        self.animations = []
        self.hidden_cards = []
        self.pending_drawn = []
        self.steal_buttons = []
        self.ai_move_start_time = None
        self.confirm_quit_mode = False
        self.quit_confirm_buttons = []
        self.prev_mode = None

        self.create_buttons()
        self.create_win_buttons()
        self.create_drawing_rects()

    def load_assets(self):
        base_path = os.path.join(os.path.dirname(__file__), "assets")
        front_path = os.path.join(base_path, "card_front.png")
        back_path = os.path.join(base_path, "card_back.png")

        front_img = pygame.image.load(front_path).convert_alpha()
        back_img = pygame.image.load(back_path).convert_alpha()

        self.card_front = pygame.transform.smoothscale(front_img, (CARD_WIDTH, CARD_HEIGHT))
        self.card_back = pygame.transform.smoothscale(back_img, (CARD_WIDTH, CARD_HEIGHT))

    def set_status(self, msg):
        self.status_message = msg
        self.status_ticks = 180

    def animate_card_move(self, card, start_pos, end_pos, face_down=False):
        anim = Animation(card, start_pos, end_pos, duration=0.5, face_down=face_down)
        self.animations.append(anim)
        self.hidden_cards.append(card)

    def get_steal_start_pos(self, target_index):

        if target_index == 1:
            center_y = 60 + CARD_HEIGHT / 2 
        elif target_index == 2:
            center_y = WINDOW_HEIGHT / 2
        else:

            center_y = WINDOW_HEIGHT - 60 - CARD_HEIGHT / 2

        center_x = WINDOW_WIDTH / 2
        x = center_x - CARD_WIDTH / 2
        y = center_y - CARD_HEIGHT / 2
        return (x, y)

    def create_buttons(self):
        btn_width = 150
        btn_height = 40
        gap = 10
        
        num_buttons = 6
        total_width = num_buttons * btn_width + (num_buttons - 1) * gap
        start_x = (WINDOW_WIDTH - total_width) // 2
        y = WINDOW_HEIGHT - 50

        color_bg = (60, 70, 90)
        color_text = (240, 240, 240)
        color_hover = (80, 90, 110)

        draw_btn = Button(start_x, y, btn_width, btn_height, "Draw", self.font_small, color_bg, color_text, color_hover)
        steal_btn = Button(start_x + (btn_width + gap), y, btn_width, btn_height, "Steal", self.font_small, color_bg, color_text, color_hover)
        draw_discard_btn = Button(start_x + 2 * (btn_width + gap), y, btn_width, btn_height, "Draw & Discard", self.font_small, color_bg, color_text, color_hover)
        discard_group_btn = Button(start_x + 3 * (btn_width + gap), y, btn_width, btn_height, "Discard Group", self.font_small, color_bg, color_text, color_hover)
        pass_btn = Button(start_x + 4 * (btn_width + gap), y, btn_width, btn_height, "Pass", self.font_small, color_bg, color_text, color_hover)
        pay_me_btn = Button(start_x + 5 * (btn_width + gap), y, btn_width, btn_height, "Play For Me", self.font_small, color_bg, color_text, color_hover)

        quit_btn = Button(20, 20, 80, 30, "Quit", self.font_small, (200, 50, 50), (255, 255, 255), (220, 70, 70))

        def on_quit():
            if self.game.winner is None:
                self.confirm_quit_mode = True
                self.create_quit_confirm_buttons()
            else:
                self.after_win_choice = "menu"
                self.force_menu = True

        def on_draw():
            if self.game.winner is not None:
                return
            player = self.game.current_player()
            if not player.is_human:
                return
            if self.game.turn.used_draw_up_to_3 and len(self.pending_drawn) == 0:
                self.set_status("Sorry, you already used Draw this turn.")
                return
            if len(self.game.deck.cards) == 0:
                self.set_status("Sorry, the deck is empty.")
                return
            else:
                already_drawn = len(self.pending_drawn)
                remaining = 3 - already_drawn

                if remaining <= 0:
                    msg = "You have already drawn 3 cards this turn. Click 'Stop' to reveal them"
                elif remaining == 1:
                    msg = "You can draw 1 more card. Click 'Draw one' or 'Stop'."
                else:
                    msg = f"You can draw up to {remaining} more cards. Click 'Draw one' or 'Stop'."

            self.set_status(msg)
            self.mode = "drawing_cards"

        def on_pass():
            if self.game.winner is not None:
                return
            player = self.game.current_player()
            if not player.is_human:
                return
            if self.pending_drawn:
                self.game.draw_up_to_3_done()
            self.pending_drawn = []
            self.mode = None
            self.game.add_log(f"{player.name} passed")
            self.game.next_player()
            

        def on_steal():
            if self.game.winner is not None:
                return
            player = self.game.current_player()
            if not player.is_human:
                return

            if self.game.turn.used_steal:
                self.set_status("Sorry, you already used Steal this turn.")
                return

            opponents = []
            for i, p in enumerate(self.game.players):
                if i != self.game.turn.player_index and len(p.hand) > 0:
                    opponents.append(i)

            if len(opponents) == 0:
                self.set_status("Sorry, there is no player you can steal from.")
                return

            if len(opponents) == 1:
                target_index = opponents[0]
                res = self.game.steal_card(target_index)
                if isinstance(res, str):
                    self.set_status("Sorry, " + res)
                else:
                    card = res
                    player = self.game.current_player() 
                    start_pos = self.get_steal_start_pos(target_index)
                    end_pos = self.renderer.get_card_screen_pos(player, card)
                    self.animate_card_move(card, start_pos, end_pos)
            else:
                self.create_steal_buttons(opponents)
                self.mode = "select_steal_target"

        def on_draw_discard():
            if self.game.winner is not None:
                return
            player = self.game.current_player()
            if not player.is_human:
                return
            if self.game.turn.used_draw_discard:
                self.set_status("Sorry, you already used Draw & Discard this turn.")
                return
            if len(self.game.deck.cards) == 0:
                self.set_status("Sorry, the deck is empty.")
                return
            if len(player.hand) == 0:
                self.set_status("Sorry, you have no cards to discard.")
                return
            
            drawn = self.game.draw_for_discard()
            if isinstance(drawn, str):
                self.set_status("Sorry, " + drawn)
                return
            
            self.set_status(f"Drew a card. Select a card to discard.")

            start_pos = (DECK_X, DECK_Y_CENTER - CARD_HEIGHT // 2)
            end_pos = self.renderer.get_card_screen_pos(player, drawn)
            self.animate_card_move(drawn, start_pos, end_pos)

            self.mode = "select_discard"

        def on_discard_group():
            if self.game.winner is not None:
                return
            player = self.game.current_player()
            if not player.is_human:
                return
            
            if len(self.selected_cards) == 0:
                self.set_status("Select cards first.")
                return

            res = self.game.discard_group(self.selected_cards)
            if res in ["sequence", "set"]:
                self.selected_cards = []
                self.set_status(f"Discarded {res}!")
            else:
                msg = res if res else "Invalid group"
                self.set_status("Invalid group: " + msg)

        def on_pay_me():
            if self.game.winner is not None:
                return
            player = self.game.current_player()
            if not player.is_human:
                return
            
            try:
                strat1(self.game)
            except Exception:
                traceback.print_exc()
                self.set_status("Something went wrong running 'Play For Me'.")

        

        quit_btn.on_click = on_quit

        draw_btn.on_click = on_draw
        pass_btn.on_click = on_pass
        steal_btn.on_click = on_steal
        draw_discard_btn.on_click = on_draw_discard
        discard_group_btn.on_click = on_discard_group
        pay_me_btn.on_click = on_pay_me

        self.buttons = [draw_btn, steal_btn, draw_discard_btn, discard_group_btn, pass_btn, pay_me_btn, quit_btn]

    def create_win_buttons(self):
        w = 160
        h = 40
        gap = 20
        y = WINDOW_HEIGHT // 2 + 40
        x_center = WINDOW_WIDTH // 2

        color_bg = (60, 70, 90)
        color_text = (240, 240, 240)
        color_hover = (80, 90, 110)
        color_accent = (255, 190, 0)
        color_accent_hover = (255, 210, 50)
        color_accent_text = (20, 20, 20)

        play_again_btn = Button(x_center - w - gap // 2, y, w, h, "Play Again", self.font_small, color_accent, color_accent_text, color_accent_hover)
        home_btn = Button(x_center + gap // 2, y, w, h, "Main Menu", self.font_small, color_bg, color_text, color_hover)

        def on_play_again():
            self.after_win_choice = "restart"

        def on_home():
            self.after_win_choice = "menu"

        play_again_btn.on_click = on_play_again
        home_btn.on_click = on_home

        self.win_buttons = [play_again_btn, home_btn]

    def create_drawing_rects(self):
        amount_y = WINDOW_HEIGHT - 140
        amount_w = 100
        amount_h = 40
        gap = 10
        start_x = 100
        self.draw_one_rect = pygame.Rect(start_x , amount_y, amount_w, amount_h)
        self.stop_drawing_rect = pygame.Rect(start_x + amount_w + gap, amount_y, amount_w, amount_h)
        self.drawing_rects = [(self.draw_one_rect,"Draw one"), (self.stop_drawing_rect, "Stop")]

    def create_steal_buttons(self, opponents):
        self.steal_buttons = []
        btn_width = 160
        btn_height = 40
        gap = 20
        y = WINDOW_HEIGHT - 110
        
        total_width = len(opponents) * btn_width + (len(opponents) - 1) * gap
        start_x = (WINDOW_WIDTH - total_width) // 2
        
        color_bg = (60, 70, 90)
        color_text = (240, 240, 240)
        color_hover = (80, 90, 110)

        for i, opp_idx in enumerate(opponents):
            label = f"Steal from P{opp_idx+1}"
            
            btn = Button(start_x + i * (btn_width + gap), y, btn_width, btn_height, label, self.font_small, color_bg, color_text, color_hover)
            
            def make_on_click(target_idx):
                def on_click():
                    res = self.game.steal_card(target_idx)
                    if isinstance(res, str):
                        self.set_status("Sorry, " + res)
                    else:
                        card = res
                        player = self.game.current_player()
                        start_pos = self.get_steal_start_pos(target_idx)
                        end_pos = self.renderer.get_card_screen_pos(player, card)
                        self.animate_card_move(card, start_pos, end_pos)
                    
                    self.mode = self.prev_mode
                    self.prev_mode = None

                return on_click

            
            btn.on_click = make_on_click(opp_idx)
            self.steal_buttons.append(btn)

    def create_quit_confirm_buttons(self):
        w = 100
        h = 40
        gap = 20
        cx = WINDOW_WIDTH // 2
        cy = WINDOW_HEIGHT // 2 + 20
        
        yes_btn = Button(cx - w - gap//2, cy, w, h, "Yes", self.font_small, (200, 50, 50), (255, 255, 255), (220, 70, 70))
        no_btn = Button(cx + gap//2, cy, w, h, "No", self.font_small, (60, 70, 90), (255, 255, 255), (80, 90, 110))
        
        def on_yes():
            self.after_win_choice = "menu"
            self.force_menu = True
            
        def on_no():
            self.confirm_quit_mode = False
            
        yes_btn.on_click = on_yes
        no_btn.on_click = on_no
        
        self.quit_confirm_buttons = [yes_btn, no_btn]

    def draw_buttons(self):
        for b in self.buttons:
            b.draw(self.screen)

        if self.mode == "select_steal_target":
            for b in self.steal_buttons:
                b.draw(self.screen)

        if self.mode == "drawing_cards":
            for rect,action in self.drawing_rects:
                pygame.draw.rect(self.screen, (220, 220, 220), rect, border_radius=6)
                t = self.font_small.render(str(action), True, (0, 0, 0))
                tx = rect.x + (rect.width - t.get_width()) // 2
                ty = rect.y + (rect.height - t.get_height()) // 2
                self.screen.blit(t, (tx, ty))
                
        if self.confirm_quit_mode:
            s = pygame.Surface((WINDOW_WIDTH, WINDOW_HEIGHT), pygame.SRCALPHA)
            s.fill((0, 0, 0, 200))
            self.screen.blit(s, (0, 0))
        
            box_w = 300
            box_h = 150
            bx = (WINDOW_WIDTH - box_w) // 2
            by = (WINDOW_HEIGHT - box_h) // 2
            pygame.draw.rect(self.screen, (40, 45, 55), (bx, by, box_w, box_h), border_radius=10)
            pygame.draw.rect(self.screen, (255, 255, 255), (bx, by, box_w, box_h), 2, border_radius=10)
            
            text = self.font_big.render("Are you sure?", True, (255, 255, 255))
            self.screen.blit(text, (bx + (box_w - text.get_width())//2, by + 30))
            
            for b in self.quit_confirm_buttons:
                b.draw(self.screen)

    def draw_win_buttons(self):
        for b in self.win_buttons:
            b.draw(self.screen)

    def draw_status(self):
        if self.status_ticks > 0 and self.status_message:
            max_width = WINDOW_WIDTH - 40
            lines = self.renderer.wrap_text(self.status_message, self.font_small, max_width)
            
            line_height = 24
            total_text_height = len(lines) * line_height
            bar_height = max(40, total_text_height + 20)
            
            y = WINDOW_HEIGHT - 95 - (bar_height - 40)
            
            pygame.draw.rect(self.screen, (0, 0, 0), (0, y, WINDOW_WIDTH, bar_height))
            
            start_y = y + (bar_height - total_text_height) // 2
            
            for i, line in enumerate(lines):
                text = self.font_small.render(line, True, (255, 255, 0))
                x = WINDOW_WIDTH // 2 - text.get_width() // 2
                self.screen.blit(text, (x, start_y + i * line_height))
                
            self.status_ticks -= 1
            if self.status_ticks <= 0:
                self.status_message = ""

    def handle_events(self):
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                self.after_win_choice = "quit"
                return False

            if self.confirm_quit_mode:
                if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
                    mx, my = event.pos
                    for b in self.quit_confirm_buttons:
                        b.update((mx, my))
                        b.handle_event(event)
                else:
                    mx, my = pygame.mouse.get_pos()
                    for b in self.quit_confirm_buttons:
                        b.update((mx, my))
                return True 

            if self.game.winner is not None:
                mx, my = pygame.mouse.get_pos()
                for b in self.win_buttons:
                    b.handle_event(event)
                continue

            if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
                mx, my = event.pos
                player = self.game.current_player()

                if self.mode == "drawing_cards":
                    for rect,action in self.drawing_rects:
                        if rect.collidepoint(mx, my):

                            if action == "Stop":
                                self.game.draw_up_to_3_done()
                                self.pending_drawn = []
                                self.mode = None
                                return True
                            
                            if action == "Draw one":
                                res = self.game.draw_up_to_3_step()
                                if isinstance(res, str):
                                    self.set_status("Sorry, " + res)
                                else:
                                    self.pending_drawn.append(res)

                                    player = self.game.current_player()
                                    self.game.add_log(f"{player.name} drew 1 card")

                                    end_x = 900
                                    end_y =  WINDOW_HEIGHT - BOTTOM_MARGIN - CARD_HEIGHT / 2 - 70

                                    start_pos = (DECK_X, DECK_Y_CENTER - CARD_HEIGHT // 2)
                                    end_pos = (end_x, end_y)
                                    self.animate_card_move(res, start_pos, end_pos, face_down=True)
                                return True

                    for b in self.buttons:
                        b.update((mx, my))
                        b.handle_event(event)

                    card = self.renderer.get_card_at_pos(player, mx, my)
                    if card is not None:
                        if card in self.selected_cards:
                            self.selected_cards.remove(card)
                        else:
                            self.selected_cards.append(card)
                    return True

                elif self.mode == "select_discard":
                    player = self.game.current_player()
                    card = self.renderer.get_card_at_pos(player, mx, my)
                    if card is not None:
                        start_pos = self.renderer.get_card_screen_pos(player, card)

                        res = self.game.discard_card(card)

                        if isinstance(res, str) and res != "OK":
                            self.set_status("Sorry, " + res)
                        else:
                            end_pos = (DECK_X, DECK_Y_CENTER - CARD_HEIGHT // 2)
                            self.animate_card_move(card, start_pos, end_pos)

                        self.mode = None
                    return True

                elif self.mode == "select_steal_target":
                    mx, my = event.pos
                    for b in self.steal_buttons:
                            b.update((mx, my))
                            b.handle_event(event)
                    return True

                elif self.mode is None:
                    player = self.game.current_player()
                    if player.is_human and self.game.winner is None:
                        card = self.renderer.get_card_at_pos(player, mx, my)
                        if card is not None:
                            if card in self.selected_cards:
                                self.selected_cards.remove(card)
                            else:
                                self.selected_cards.append(card)
                            return True

                    for b in self.buttons:
                        b.update((mx, my))
                        b.handle_event(event)

            mx, my = pygame.mouse.get_pos()
            for b in self.buttons:
                b.update((mx,my))

        return True

    def maybe_run_ai_turn(self):
        if self.game.winner is not None:
            return
        player = self.game.current_player()
        
        if player.is_human:
            return

        if self.mode is not None:
            return

        if self.ai_move_start_time is None:
            self.ai_move_start_time = time.time()
            return
        
        if time.time() - self.ai_move_start_time < 1.0:
            return

        try:
            if player.ai_type == "hard":
                acted = strat1(self.game)
            else:
                acted = strat2(self.game)

            if not acted:
                self.set_status(f"{player.name} passed")
            else:
                self.set_status(f"{player.name} played")
        except Exception:
            traceback.print_exc()
            self.set_status(f"{player.name} hit an error and had to pass.")
            self.game.next_player()
        finally:
            self.ai_move_start_time = None

    def animate_initial_deal(self):
        players = self.game.players
        if len(players) == 0:
            self.initial_deal_done = True
            return

        max_cards = len(players[0].hand)
        visible = [0] * len(players)

        for c in range(max_cards):
            for i in range(len(players)):
                if visible[i] < len(players[i].hand):
                    visible[i] += 1
                    self.renderer.draw_background()
                    self.renderer.draw_deck(self.game.deck)
                    self.renderer.draw_all_players(players, visible)
                    self.renderer.draw_winner(self.game.winner)
                    self.draw_buttons()
            self.draw_win_buttons()
            self.renderer.draw_game_log(self.game.log)
            self.draw_status()
            pygame.display.flip()
            self.clock.tick(60)
            
            if hasattr(self, 'force_menu') and self.force_menu:
                return "menu"

        self.initial_deal_done = True

    def run(self):
        running = True
        if not self.initial_deal_done:
            self.animate_initial_deal()

        while running:
            running = self.handle_events()
            self.maybe_run_ai_turn()
            self.renderer.draw_background()
            self.renderer.draw_deck(self.game.deck)
            self.renderer.draw_all_players(self.game.players, selected_cards=self.selected_cards, hidden_cards=self.hidden_cards, pending_drawn=self.pending_drawn)
            self.renderer.draw_winner(self.game.winner)

            if self.game.winner is not None:
                self.draw_win_buttons()
            else:
                self.draw_buttons()

            self.draw_status()
            self.renderer.draw_game_log(self.game.log)
            
            active_anims = []
            for anim in self.animations:
                pos = anim.get_current_pos()
                if not anim.face_down:
                    self.renderer.draw_card_front(anim.card, pos[0], pos[1])
                else:
                    self.renderer.draw_card_back(pos[0], pos[1])
                if not anim.finished:
                    active_anims.append(anim)
                else:
                    if anim.card in self.hidden_cards:
                        self.hidden_cards.remove(anim.card)

            self.animations = active_anims

            pygame.display.flip()
            self.clock.tick(60)

            if self.after_win_choice is not None:
                pygame.quit()
                return self.after_win_choice

        pygame.quit()
        return "quit"
