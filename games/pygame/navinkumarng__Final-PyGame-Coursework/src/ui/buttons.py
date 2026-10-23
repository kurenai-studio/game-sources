import pygame

class Button:
    def __init__(self, x, y, width, height, text, font, bg_color, text_color, hover_color=None):
        self.rect = pygame.Rect(x, y, width, height)
        self.text = text
        self.font = font
        self.bg_color = bg_color
        self.text_color = text_color
        self.hover_color = hover_color if hover_color else (min(bg_color[0] + 20, 255), min(bg_color[1] + 20, 255), min(bg_color[2] + 20, 255))
        self.on_click = None
        self.is_hovered = False
        self.shadow_rect = pygame.Rect(x + 2, y + 2, width, height)

    def update(self, mouse_pos):
        self.is_hovered = self.rect.collidepoint(mouse_pos)

    def draw(self, surface):
        pygame.draw.rect(surface, (0, 0, 0, 100), self.shadow_rect, border_radius=8)
        
        base_color = self.hover_color if self.is_hovered else self.bg_color    
        pygame.draw.rect(surface, base_color, self.rect, border_radius=8)
        
        s = pygame.Surface((self.rect.width, self.rect.height // 2), pygame.SRCALPHA)
        pygame.draw.rect(s, (255, 255, 255, 30), s.get_rect(), border_top_left_radius=8, border_top_right_radius=8)
        surface.blit(s, (self.rect.x, self.rect.y))
        
        pygame.draw.rect(surface, (255, 255, 255, 50), self.rect, width=1, border_radius=8)
        
        text_surf = self.font.render(self.text, True, self.text_color)
        tw, th = text_surf.get_size()
        tx = self.rect.x + (self.rect.width - tw) // 2
        ty = self.rect.y + (self.rect.height - th) // 2
        surface.blit(text_surf, (tx, ty))

    def handle_event(self, event):
        if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            if self.is_hovered:
                if self.on_click is not None:
                    self.on_click()

