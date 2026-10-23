import pygame

CARD_WIDTH = 90
CARD_HEIGHT = 140
WINDOW_WIDTH = 1200
WINDOW_HEIGHT = 800
CARD_SPACING = 20
TOP_MARGIN = 60
BOTTOM_MARGIN = 60

DECK_X = 40
DECK_Y_CENTER = WINDOW_HEIGHT // 2

class Renderer:
    def __init__(self, screen, font_small, font_big, font_card, card_front, card_back):
        self.screen = screen
        self.font_small = font_small
        self.font_big = font_big
        self.font_card = font_card if font_card else font_big
        self.card_front = card_front
        self.card_back = card_back

    def wrap_text(self, text, font, max_width):
        words = text.split(' ')
        lines = []
        current_line = []
        
        for word in words:
            test_line = ' '.join(current_line + [word])
            w, h = font.size(test_line)
            if w <= max_width:
                current_line.append(word)
            else:
                if current_line:
                    lines.append(' '.join(current_line))
                    current_line = [word]
                else:
                    lines.append(word)
                    current_line = []
        
        if current_line:
            lines.append(' '.join(current_line))
            
        return lines

    def draw_background(self):

        top_color = (40, 45, 70)
        bottom_color = (15, 15, 25)

        self.screen.fill(bottom_color)

        if not hasattr(self, 'bg_surface'):
            self.bg_surface = pygame.Surface((WINDOW_WIDTH, WINDOW_HEIGHT), pygame.SRCALPHA)
            
            center = (WINDOW_WIDTH // 2, WINDOW_HEIGHT // 2)
            max_radius = min(WINDOW_WIDTH, WINDOW_HEIGHT)
            for r in range(max_radius, 0, -2):
                alpha = int(100 * (1 - r / max_radius)) 
                color = (*top_color, alpha) 
                pass
            for y in range(WINDOW_HEIGHT):
                t = y / WINDOW_HEIGHT
                r = int(top_color[0] * (1-t) + bottom_color[0] * t)
                g = int(top_color[1] * (1-t) + bottom_color[1] * t)
                b = int(top_color[2] * (1-t) + bottom_color[2] * t)
                pygame.draw.line(self.bg_surface, (r, g, b), (0, y), (WINDOW_WIDTH, y))
        
        self.screen.blit(self.bg_surface, (0, 0))

    def draw_deck(self, deck):
        y = DECK_Y_CENTER - CARD_HEIGHT // 2
        
        shadow_rect = pygame.Rect(DECK_X + 4, y + 4, CARD_WIDTH, CARD_HEIGHT)
        pygame.draw.rect(self.screen, (0, 0, 0, 100), shadow_rect, border_radius=8)
        
        self.screen.blit(self.card_back, (DECK_X, y))
        
        
        count_text = self.font_small.render(str(len(deck.cards)), True, (255, 255, 255))
         
        cx = DECK_X + CARD_WIDTH
        cy = y
        pygame.draw.circle(self.screen, (200, 50, 50), (cx, cy), 15)
        pygame.draw.circle(self.screen, (255, 255, 255), (cx, cy), 15, 2)
        
        tx = cx - count_text.get_width() // 2
        ty = cy - count_text.get_height() // 2
        self.screen.blit(count_text, (tx, ty))

    def draw_card_front(self, card, x, y, width=None, height=None):
        if width is None:
            width = CARD_WIDTH
        if height is None:
            height = CARD_HEIGHT

        shadow_rect = pygame.Rect(x + 3, y + 3, width, height)
        pygame.draw.rect(self.screen, (0, 0, 0, 80), shadow_rect, border_radius=8)

        
        card_rect = pygame.Rect(x, y, width, height)
        pygame.draw.rect(self.screen, (245, 245, 245), card_rect, border_radius=8)
        
        
        pygame.draw.rect(self.screen, (200, 200, 200), card_rect, width=1, border_radius=8)

        colour_map = {
            "red": (220, 60, 60),
            "green": (46, 204, 113),
            "yellow": (241, 196, 15),
            "blue": (52, 152, 219),
            "black": (50, 50, 50),
        }

        color = colour_map.get(card.colour, (0, 0, 0))
 
        inner_margin = 4
        inner_rect = pygame.Rect(x + inner_margin, y + inner_margin, width - 2*inner_margin, height - 2*inner_margin)
        pygame.draw.rect(self.screen, color, inner_rect, width=2, border_radius=6)
        
        
        label = str(card.number)
        text_surface = self.font_card.render(label, True, color)
        tw, th = text_surface.get_size()
        tx = int(x + (width - tw) / 2)
        ty = int(y + (height - th) / 2)
        self.screen.blit(text_surface, (tx, ty))
        
        
        small_font = self.font_small
        small_text = small_font.render(label, True, color)
        self.screen.blit(small_text, (x + 6, y + 4))
        
        self.screen.blit(small_text, (x + width - small_text.get_width() - 6, y + height - small_text.get_height() - 4))

    def draw_card_back(self, x, y, width=None, height=None):
        if width is None:
            width = CARD_WIDTH
        if height is None:
            height = CARD_HEIGHT

        self.screen.blit(self.card_back, (x, y))
        

    def draw_game_log(self, log):

        box_w = 250
        box_h = 150
        x = 20
        y = 70
        
        s = pygame.Surface((box_w, box_h), pygame.SRCALPHA)
        s.fill((200, 50, 50, 200)) 
        self.screen.blit(s, (x, y))
    
        pygame.draw.rect(self.screen, (255, 200, 200), (x, y, box_w, box_h), 1)
        title = self.font_small.render("Game Log", True, (255, 255, 255)) 
        self.screen.blit(title, (x + 10, y + 5))
        
        lines_to_show = []
        max_text_width = box_w - 20
        
        for msg in reversed(log):
            wrapped = self.wrap_text(msg, self.font_small, max_text_width)
            for line in wrapped:
                lines_to_show.append(line)
            if len(lines_to_show) > 10:
                break
                
        start_y = y + 30

        
        current_y = start_y
        for line in lines_to_show:
            if current_y + 20 > y + box_h:
                break
            text = self.font_small.render(line, True, (255, 255, 255))
            self.screen.blit(text, (x + 10, current_y))
            current_y += 20

    def draw_player_hand(self, player, center_y, label, max_cards=None, selected_cards=None, hidden_cards=None):
        if selected_cards is None:
            selected_cards = []
        if hidden_cards is None:
            hidden_cards = []
        if max_cards is None:
            cards_to_draw = player.hand
        else:
            cards_to_draw = player.hand[:max_cards]

        n = len(cards_to_draw)

        label_y = int(center_y - CARD_HEIGHT / 2 - 30)
        text = self.font_big.render(label, True, (255, 255, 255))
        self.screen.blit(text, (200, label_y))

        if n == 0:
            return

        margin_x = 300
        available_width = WINDOW_WIDTH - 2 * margin_x

        base_w = CARD_WIDTH
        base_h = CARD_HEIGHT
        base_step = CARD_WIDTH * 0.6

        span = base_w + (n - 1) * base_step
        if span > available_width:
            scale = available_width / span
            if scale > 1.0:
                scale = 1.0
        else:
            scale = 1.0

        width = base_w * scale
        height = base_h * scale
        step = base_step * scale
        total_width = width + (n - 1) * step

        start_x = margin_x + (available_width - total_width) / 2
        y_top = center_y - height / 2

        x = start_x
        for card in cards_to_draw:
            if card in hidden_cards:
                x += step
                continue
                
            draw_y = y_top
            if card in selected_cards:
                draw_y -= 20

            self.draw_card_front(card, x, draw_y, width, height)
            x += step

    def draw_all_players(self, players, visible_counts=None, selected_cards=None, hidden_cards=None, pending_drawn=None):
        if len(players) == 0:
            return

        if visible_counts is None:
            visible_counts = [None] * len(players)

        center_bottom = WINDOW_HEIGHT - BOTTOM_MARGIN - CARD_HEIGHT / 2
        bottom_label = players[0].name + " (bottom)"
        bottom_max = visible_counts[0] if len(visible_counts) > 0 else None
        self.draw_player_hand(players[0], center_bottom, bottom_label, bottom_max, selected_cards=selected_cards, hidden_cards=hidden_cards)

        if len(players) >= 2:
            center_top = TOP_MARGIN + CARD_HEIGHT / 2
            top_label = players[1].name + " (top)"
            top_max = visible_counts[1] if len(visible_counts) > 1 else None
            self.draw_player_hand(players[1], center_top, top_label, top_max)

        if len(players) == 3:
            center_mid = WINDOW_HEIGHT / 2
            mid_label = players[2].name + " (middle)"
            mid_max = visible_counts[2] if len(visible_counts) > 2 else None
            self.draw_player_hand(players[2], center_mid, mid_label, mid_max)
        
        if pending_drawn:
            y = WINDOW_HEIGHT - BOTTOM_MARGIN - CARD_HEIGHT / 2 - 70
            self.draw_card_back(900, y)

    def draw_winner(self, winner):
        if winner is None:
            return
        if winner.name == "You":
            msg = "You win!"
        else:
            msg = f"{winner.name} wins!"
        text = self.font_big.render(msg, True, (255, 215, 0))
        tw, th = text.get_size()
        x = (WINDOW_WIDTH - tw) // 2
        y = (WINDOW_HEIGHT - th) // 2
        self.screen.blit(text, (x, y))
        self.screen.blit(text, (x, y))

    def get_card_at_pos(self, player, mx, my):
        cards = player.hand
        n = len(cards)
        if n == 0:
            return None

        center_y = WINDOW_HEIGHT - BOTTOM_MARGIN - CARD_HEIGHT / 2
        
        margin_x = 300
        available_width = WINDOW_WIDTH - 2 * margin_x

        base_w = CARD_WIDTH
        base_h = CARD_HEIGHT
        base_step = CARD_WIDTH * 0.6

        span = base_w + (n - 1) * base_step
        if span > available_width:
            scale = available_width / span
            if scale > 1.0:
                scale = 1.0
        else:
            scale = 1.0

        width = base_w * scale
        height = base_h * scale
        step = base_step * scale
        total_width = width + (n - 1) * step

        start_x = margin_x + (available_width - total_width) / 2
        y_top = center_y - height / 2
        rects = []
        x = start_x
        for card in cards:
            r = pygame.Rect(x, y_top, width, height)
            rects.append((r, card))
            x += step

        for r, card in reversed(rects):
            if r.collidepoint(mx, my):
                return card
        
        return None
    

    def get_card_screen_pos(self, player, card):
        cards = player.hand
        if card not in cards:
            return (0, 0)
            
        n = len(cards)
        
        center_y = WINDOW_HEIGHT - BOTTOM_MARGIN - CARD_HEIGHT / 2
        
        margin_x = 300
        available_width = WINDOW_WIDTH - 2 * margin_x

        base_w = CARD_WIDTH
        base_h = CARD_HEIGHT
        base_step = CARD_WIDTH * 0.6

        span = base_w + (n - 1) * base_step
        if span > available_width:
            scale = available_width / span
            if scale > 1.0:
                scale = 1.0
        else:
            scale = 1.0

        width = base_w * scale
        height = base_h * scale
        step = base_step * scale
        total_width = width + (n - 1) * step

        start_x = margin_x + (available_width - total_width) / 2
        y_top = center_y - height / 2

        x = start_x
        for c in cards:
            if c == card:
                return (x, y_top)
            x += step
            
        return (0, 0)
